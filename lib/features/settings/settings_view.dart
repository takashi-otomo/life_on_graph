import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_lock_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/sync_notifier.dart';
import '../../repositories/biometric_auth.dart';

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
    final AppLocalizations l = AppLocalizations.of(context);
    final Locale? locale = ref.watch(localeProvider);

    final String syncSubtitle = switch (sync) {
      SyncInProgress() => l.syncing,
      _ =>
        lastSync == null ? l.notSynced : l.lastSynced(_fmtDateTime(lastSync)),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            Text(
              l.settingsTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _SectionHeader(l.sectionDataSync),
            _SettingsCard(
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.sync,
                  iconColor: AppColors.accent,
                  title: l.syncNow,
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
                _SettingsTile(
                  icon: Icons.health_and_safety,
                  iconColor: AppColors.positive,
                  title: l.healthConnectLink,
                  subtitle: l.healthConnectLinkSubtitle,
                ),
              ],
            ),

            _SectionHeader(l.sectionPrivacy),
            _SettingsCard(
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.lock_outline,
                  iconColor: AppColors.accent,
                  title: l.appLock,
                  subtitle: l.appLockSubtitle,
                  trailing: Switch(
                    value: ref.watch(appLockEnabledProvider),
                    onChanged: (v) => _toggleLock(context, ref, v),
                  ),
                  onTap: () => _toggleLock(
                    context,
                    ref,
                    !ref.read(appLockEnabledProvider),
                  ),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.privacy_tip,
                  iconColor: AppColors.accent,
                  title: l.privacyPolicy,
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
                  title: l.deleteAllData,
                  subtitle: sync is SyncInProgress
                      ? l.cannotDeleteWhileSyncing
                      : l.deleteAllDataSubtitle,
                  titleColor: AppColors.danger,
                  // 同期中の削除は実行中の sync が直後に再保存しうるため抑止する。
                  onTap: sync is SyncInProgress
                      ? null
                      : () => _confirmDelete(context, ref),
                ),
              ],
            ),

            _SectionHeader(l.sectionInfo),
            _SettingsCard(
              children: <Widget>[
                _SettingsTile(
                  icon: Icons.translate,
                  iconColor: AppColors.accent,
                  title: l.language,
                  subtitle: _languageLabel(locale, l),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.divider,
                  ),
                  onTap: () => _pickLanguage(context, ref, l, locale),
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.textSecondary,
                  title: l.version,
                  trailing: const Text(
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
                  title: l.openSourceLicenses,
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
                  title: l.contact,
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

  /// 選択中の言語名 (自言語表記)。`null` は端末設定に従う。
  static String _languageLabel(Locale? locale, AppLocalizations l) {
    if (locale == null) return l.languageSystem;
    return _autonym(locale.languageCode);
  }

  /// 言語コード → 自言語表記 (翻訳しない)。
  static String _autonym(String code) => switch (code) {
    'ja' => '日本語',
    'en' => 'English',
    'fr' => 'Français',
    'de' => 'Deutsch',
    'pt' => 'Português',
    'es' => 'Español',
    _ => code,
  };

  /// 言語選択シートを表示し、選択結果を [localeProvider] へ反映する (#94)。
  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    Locale? current,
  ) async {
    // null = 端末設定に従う + 対応言語。
    final List<Locale?> options = <Locale?>[
      null,
      ...AppLocalizations.supportedLocales,
    ];
    // '__system__' = 端末設定に従う / それ以外は言語コード。null = シートを閉じただけ。
    const String systemSentinel = '__system__';
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final Locale? opt in options)
              ListTile(
                title: Text(_languageLabel(opt, l)),
                trailing: opt?.languageCode == current?.languageCode
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.pop(
                  ctx,
                  opt == null ? systemSentinel : opt.languageCode,
                ),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return; // シートを閉じただけ。
    final Locale? next = selected == systemSentinel ? null : Locale(selected);
    await ref.read(localeProvider.notifier).setLocale(next);
  }

  /// アプリロックの有効/無効を切り替える (#79)。
  ///
  /// 有効化時は端末の認証可否を確認し、認証成功時のみ有効にする (誤設定で締め出されない
  /// ようにする)。無効化は解錠済み画面からの操作のため確認のみ。
  Future<void> _toggleLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final BiometricAuth auth = ref.read(biometricAuthProvider);
    if (enable) {
      if (!await auth.isAvailable()) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.lockUnavailable)));
        }
        return;
      }
      final bool ok = await auth.authenticate(l.lockReason);
      if (!ok) return;
    }
    await ref.read(appLockEnabledProvider.notifier).set(enable);
  }

  static Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteDialogTitle),
        content: Text(l.deleteDialogContent),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // ダイアログ表示中に同期が始まっていたら、再保存との競合を避けて中止する。
    if (ref.read(syncNotifierProvider) is SyncInProgress) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.deleteAbortedSyncing)));
      }
      return;
    }

    await ref.read(healthSyncRepositoryProvider).clearAllData();
    // 派生プロバイダを再評価させ、各画面を空状態に更新する。
    ref.read(dataRevisionProvider.notifier).bump();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.deletedSnack)));
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
