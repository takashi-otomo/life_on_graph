import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../l10n/app_localizations.dart';
import 'policy_view.dart';

/// 権限根拠 / プライバシーポリシー画面 (#54)。
///
/// Health Connect 設定の「権限の根拠」リンクや権限使用状況から起動された際に表示し、
/// どのデータをどの目的で利用するか (端末内可視化・非送信) を説明する。
/// プライバシーポリシー (#43) への導線も提供する。
class RationaleView extends StatelessWidget {
  const RationaleView({super.key, this.onContinue});

  /// 「アプリを開く」導線。null の場合はボタンを表示しない。
  final VoidCallback? onContinue;

  static List<({IconData icon, Color color, String title, String desc})> _items(
    AppLocalizations l,
  ) => <({IconData icon, Color color, String title, String desc})>[
    (
      icon: Icons.bedtime,
      color: AppColors.sleepDeep,
      title: l.sleep,
      desc: l.rationaleSleepDesc,
    ),
    (
      icon: Icons.directions_walk,
      color: AppColors.steps,
      title: l.steps,
      desc: l.rationaleStepsDesc,
    ),
    (
      icon: Icons.favorite,
      color: AppColors.heart,
      title: l.heartRate,
      desc: l.rationaleHeartDesc,
    ),
    (
      icon: Icons.history,
      color: AppColors.accent,
      title: l.rationaleHistoryTitle,
      desc: l.rationaleHistoryDesc,
    ),
  ];

  Future<void> _openPolicy() async {
    final Uri uri = Uri.parse(AppConstants.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 8),
            const Icon(Icons.privacy_tip, size: 44, color: AppColors.accent),
            const SizedBox(height: 12),
            Text(
              l.rationaleTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.rationaleIntro(AppConstants.appName),
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            for (final item in _items(l)) ...<Widget>[
              _RationaleItem(
                icon: item.icon,
                color: item.color,
                title: item.title,
                desc: item.desc,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.positive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.lock, size: 18, color: AppColors.positive),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.rationaleSecurity,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Health Connect のポリシーリンクからの遷移先として、アプリ内で
            // 同一のプライバシーポリシー全文を表示する (ガイドライン準拠)。
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PolicyView()),
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(l.readPolicy),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _openPolicy,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(l.openPolicyBrowser),
            ),
            if (onContinue != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onContinue, child: Text(l.openApp)),
            ],
          ],
        ),
      ),
    );
  }
}

class _RationaleItem extends StatelessWidget {
  const _RationaleItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
