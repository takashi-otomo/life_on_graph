import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// トレンド方向 (前期間比の上下)。
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
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final MetricTrend? trend;
  final String? trendLabel;

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
            _TrendRow(trend: trend!, label: trendLabel!),
          ],
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend, required this.label});

  final MetricTrend trend;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (trend) {
      MetricTrend.up => (Icons.trending_up, AppColors.positive),
      MetricTrend.down => (Icons.trending_down, AppColors.positive),
      MetricTrend.flat => (Icons.trending_flat, AppColors.textMuted),
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
