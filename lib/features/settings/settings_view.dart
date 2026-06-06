import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../providers/repository_providers.dart';
import '../../providers/sync_notifier.dart';

/// 設定画面 (データ同期 / プライバシー・セキュリティ / 情報) (#69)。
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SyncState sync = ref.watch(syncNotifierProvider);
    ref.watch(dataRevisionProvider); // 同期/削除後に最終同期時刻を更新。
    final DateTime? lastSync = ref
        .watch(healthSyncRepositoryProvider)
        .lastSyncTime;

    final String syncSubtitle = switch (sync) {
      SyncInProgress() => '同期中…',
      _ => lastSync == null ? '未同期' : '最終同期: ${_fmtDateTime(lastSync)}',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            const Text(
              '設定',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            const _SectionHeader('データ同期'),
            _SettingsCard(
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.sync,
                  iconColor: AppColors.accent,
                  title: '今すぐ同期',
                  subtitle: syncSubtitle,
                  trailing: sync is SyncInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: AppColors.divider,
                        ),
                  onTap: sync is SyncInProgress
                      ? null
                      : () => ref
                            .read(syncNotifierProvider.notifier)
                            .sync(force: true),
                ),
                const _Divider(),
                const _SettingsTile(
                  icon: Icons.health_and_safety,
                  iconColor: AppColors.positive,
                  title: 'Health Connect 連携',
                  subtitle: '睡眠・歩数・心拍を読み取り (READ のみ)',
                ),
              ],
            ),

            const _SectionHeader('プライバシーとセキュリティ'),
            _SettingsCard(
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.privacy_tip,
                  iconColor: AppColors.accent,
                  title: 'プライバシーポリシー',
                  trailing: const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: AppColors.divider,
                  ),
                  onTap: () => _openUrl(AppConstants.privacyPolicyUrl),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.delete_forever,
                  iconColor: AppColors.danger,
                  title: 'すべてのデータを削除',
                  subtitle: '端末内の睡眠・歩数・心拍データを消去',
                  titleColor: AppColors.danger,
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),

            const _SectionHeader('情報'),
            _SettingsCard(
              children: <Widget>[
                const _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.textSecondary,
                  title: 'バージョン',
                  trailing: Text(
                    AppConstants.appVersion,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.textSecondary,
                  title: 'オープンソースライセンス',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.divider,
                  ),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                  ),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.mail_outline,
                  iconColor: AppColors.textSecondary,
                  title: 'お問い合わせ',
                  subtitle: AppConstants.contactEmail,
                  onTap: () => _openUrl('mailto:${AppConstants.contactEmail}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('すべてのデータを削除'),
        content: const Text(
          '端末内に保存した睡眠・歩数・心拍データをすべて削除します。'
          'この操作は取り消せません。\n\n'
          '(Health Connect 側のデータは削除されません。次回同期で再取得されます。)',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.read(healthSyncRepositoryProvider).clearAllData();
    // 派生プロバイダを再評価させ、各画面を空状態に更新する。
    ref.read(dataRevisionProvider.notifier).bump();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ローカルデータを削除しました')));
    }
  }

  static String _fmtDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.month}/${d.day} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    indent: 48,
    color: AppColors.divider,
  );
}
