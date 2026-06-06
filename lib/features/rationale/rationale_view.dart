import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';

/// 権限根拠 / プライバシーポリシー画面 (#54)。
///
/// Health Connect 設定の「権限の根拠」リンクや権限使用状況から起動された際に表示し、
/// どのデータをどの目的で利用するか (端末内可視化・非送信) を説明する。
/// プライバシーポリシー (#43) への導線も提供する。
class RationaleView extends StatelessWidget {
  const RationaleView({super.key, this.onContinue});

  /// 「アプリを開く」導線。null の場合はボタンを表示しない。
  final VoidCallback? onContinue;

  static const List<({IconData icon, Color color, String title, String desc})>
  _items = <({IconData icon, Color color, String title, String desc})>[
    (
      icon: Icons.bedtime,
      color: AppColors.sleepDeep,
      title: '睡眠',
      desc: '睡眠ステージ(深い/浅い/レム/覚醒)を可視化するために読み取ります。',
    ),
    (
      icon: Icons.directions_walk,
      color: AppColors.steps,
      title: '歩数',
      desc: '時間帯別・日次/週次/月次の歩数を可視化するために読み取ります。',
    ),
    (
      icon: Icons.favorite,
      color: AppColors.heart,
      title: '心拍',
      desc: '心拍数・安静時/最高値・睡眠中心拍を可視化するために読み取ります。',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 8),
            const Icon(Icons.privacy_tip, size: 44, color: AppColors.accent),
            const SizedBox(height: 12),
            const Text(
              'ヘルスデータの利用について',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '${AppConstants.appName} は、以下のデータを Health Connect から読み取り、'
              '端末内でのグラフ表示にのみ使用します。データを外部へ送信することはありません。',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            for (final item in _items) ...<Widget>[
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
              child: const Row(
                children: <Widget>[
                  Icon(Icons.lock, size: 18, color: AppColors.positive),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '取得したデータは AES-256 で暗号化し端末内にのみ保存します。'
                      'クラウド送信・第三者提供は行いません。',
                      style: TextStyle(
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
            OutlinedButton.icon(
              onPressed: _openPolicy,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('プライバシーポリシーを開く'),
            ),
            if (onContinue != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton(onPressed: onContinue, child: const Text('アプリを開く')),
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
