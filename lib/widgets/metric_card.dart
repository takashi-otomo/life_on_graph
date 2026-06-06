import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// トレンドの矢印方向 (前期間比の上下)。良し悪し (色) とは独立。
enum MetricTrend { up, down, flat }

/// サマリー画面の KPI メトリックカード (#65, #67)。
///
/// アイコン + ラベル + 値 + 前期間比トレンドを表示する。
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trend,
    this.trendLabel,
    this.trendPositive,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  /// トレンドの矢印方向 (up/down/flat)。
  final MetricTrend? trend;
  final String? trendLabel;

  /// トレンドの良し悪し (色)。`true`=改善(緑)/`false`=悪化(赤)/`null`=中立(グレー)。
  /// 矢印方向 ([trend]) と独立。歩数の減少など「下向き=悪化」を赤で表せる。
  final bool? trendPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (trend != null && trendLabel != null) ...<Widget>[
            const SizedBox(height: 8),
            _TrendRow(
              trend: trend!,
              label: trendLabel!,
              positive: trendPositive,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.trend,
    required this.label,
    required this.positive,
  });

  final MetricTrend trend;
  final String label;
  final bool? positive;

  @override
  Widget build(BuildContext context) {
    // 矢印は方向 (trend)、色は良し悪し (positive) で決める (方向と独立)。
    final IconData icon = switch (trend) {
      MetricTrend.up => Icons.trending_up,
      MetricTrend.down => Icons.trending_down,
      MetricTrend.flat => Icons.trending_flat,
    };
    final Color color = switch (positive) {
      true => AppColors.positive,
      false => AppColors.danger,
      null => AppColors.textMuted,
    };
    return Row(
      children: <Widget>[
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
