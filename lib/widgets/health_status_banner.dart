import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/health_availability_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_notifier.dart';

/// データ・権限・導入状態に応じた状態別 UI バナー (#42)。
///
/// 優先順位は **未導入 > 未許可 > 同期失敗** で出し分ける。いずれにも該当しない
/// (正常 / 同期中 / 同期成功) ときは何も描画しない。空データ (該当日にレコード無し)
/// は各カードの空状態に委ねるため、本バナーはアプリ全体の状態のみを扱う。
///
/// ローカルファースト方針のため、導入状態の解決前 (初回 loading) はバナーを一切
/// 出さない (既存ローカルデータの描画をブロックしない / 失敗バナーの誤表示も防ぐ)。
/// インストール導線後・アプリ復帰時に導入状態を再チェックする。
class HealthStatusBanner extends ConsumerStatefulWidget {
  const HealthStatusBanner({super.key});

  @override
  ConsumerState<HealthStatusBanner> createState() => _HealthStatusBannerState();
}

class _HealthStatusBannerState extends ConsumerState<HealthStatusBanner> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Play ストアから復帰した際などに導入状態を再評価する。
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(healthConnectAvailableProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<bool> availability = ref.watch(
      healthConnectAvailableProvider,
    );
    // 初回解決前 (値未取得の loading) はローカルファースト契約によりバナーを
    // 出さない。再評価中 (前値あり) は前値で判定を続ける。
    if (availability.isLoading && !availability.hasValue) {
      return const SizedBox.shrink();
    }
    final bool available = availability.asData?.value ?? true;
    final SyncState sync = ref.watch(syncNotifierProvider);
    final AppLocalizations l = AppLocalizations.of(context);

    // 優先順位1: Health Connect 未導入。
    if (!available) {
      return _StateCard(
        icon: Icons.download_for_offline,
        color: AppColors.accent,
        title: l.statusUnavailableTitle,
        message: l.statusUnavailableMessage,
        actionLabel: l.install,
        onAction: () async {
          await ref.read(healthSyncRepositoryProvider).installHealthConnect();
          // 導線後に再チェック (復帰時にも onResume で再評価される)。
          ref.invalidate(healthConnectAvailableProvider);
        },
      );
    }

    // 優先順位2: 権限未許可。
    if (sync is SyncError && sync.error is SyncPermissionDeniedException) {
      return _StateCard(
        icon: Icons.lock_outline,
        color: AppColors.accent,
        title: l.statusPermissionTitle,
        message: l.statusPermissionMessage,
        actionLabel: l.allow,
        onAction: () => ref.read(syncNotifierProvider.notifier).sync(),
      );
    }

    // 優先順位3: 同期失敗・部分失敗 (ローカル保存分は表示継続)。
    if (sync is SyncError || sync is SyncPartial) {
      return _StateCard(
        icon: Icons.cloud_off,
        color: AppColors.danger,
        title: l.statusSyncFailedTitle,
        message: l.statusSyncFailedMessage,
        actionLabel: l.retry,
        onAction: () =>
            ref.read(syncNotifierProvider.notifier).sync(force: true),
      );
    }

    return const SizedBox.shrink();
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
