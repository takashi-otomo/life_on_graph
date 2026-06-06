import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../providers/health_availability_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_notifier.dart';

/// データ・権限・導入状態に応じた状態別 UI バナー (#42)。
///
/// 優先順位は **未導入 > 未許可 > 同期失敗** で出し分ける。いずれにも該当しない
/// (正常 / 同期中 / 同期成功) ときは何も描画しない。空データ (該当日にレコード無し)
/// は各カードの空状態に委ねるため、本バナーはアプリ全体の状態のみを扱う。
///
/// ローカルファースト方針のため、導入状態の解決前 (loading) は「利用可能」とみなし
/// バナーを出さない (既存ローカルデータの描画をブロックしない)。
class HealthStatusBanner extends ConsumerWidget {
  const HealthStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool available =
        ref.watch(healthConnectAvailableProvider).asData?.value ?? true;
    final SyncState sync = ref.watch(syncNotifierProvider);

    // 優先順位1: Health Connect 未導入。
    if (!available) {
      return _StateCard(
        icon: Icons.download_for_offline,
        color: AppColors.accent,
        title: 'Health Connect が必要です',
        message: '睡眠・歩数・心拍を取得するには Health Connect の導入が必要です。',
        actionLabel: 'インストール',
        onAction: () =>
            ref.read(healthSyncRepositoryProvider).installHealthConnect(),
      );
    }

    // 優先順位2: 権限未許可。
    if (sync is SyncError && sync.error is SyncPermissionDeniedException) {
      return _StateCard(
        icon: Icons.lock_outline,
        color: AppColors.accent,
        title: 'ヘルスデータへのアクセスが必要です',
        message: '睡眠・歩数・心拍を表示するには Health Connect の読み取り許可が必要です。',
        actionLabel: '許可する',
        onAction: () => ref.read(syncNotifierProvider.notifier).sync(),
      );
    }

    // 優先順位3: 同期失敗・部分失敗 (ローカル保存分は表示継続)。
    if (sync is SyncError || sync is SyncPartial) {
      return _StateCard(
        icon: Icons.cloud_off,
        color: AppColors.danger,
        title: '同期に失敗しました',
        message: '表示中のデータはローカル保存分です。',
        actionLabel: '再試行',
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
