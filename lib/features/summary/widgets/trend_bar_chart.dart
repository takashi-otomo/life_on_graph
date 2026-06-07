import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_card.dart';
import '../period_summary.dart';

/// 期間別トレンド棒グラフ (#68)。睡眠時間 or 歩数を期間バーで表示する。
class TrendBarChart extends StatelessWidget {
  const TrendBarChart({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.bars,
    required this.value,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<TrendBar> bars;

  /// 各バーの数値を取り出す (睡眠=時間, 歩数=歩)。
  final double Function(TrendBar) value;

  /// バーの x 軸ラベルをロケールに応じて整形する (#97)。
  static String _barLabel(TrendBar b, AppLocalizations l, String locale) {
    if (b.weekIndex != null) return l.weekShort(b.weekIndex! + 1);
    if (b.isToday) return l.today;
    if (b.date != null) return DateFormat.E(locale).format(b.date!);
    return b.label;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final double maxV = bars.isEmpty
        ? 1
        : bars.map(value).fold(0.0, (a, b) => a > b ? a : b);

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxV <= 0 ? 1 : maxV,
                barTouchData: const BarTouchData(enabled: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, meta) {
                        final int i = v.toInt();
                        if (i < 0 || i >= bars.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _barLabel(bars[i], l, locale),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: bars[i].highlighted
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: bars[i].highlighted
                                  ? color
                                  : AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  for (int i = 0; i < bars.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: value(bars[i]),
                          width: 14,
                          color: bars[i].highlighted
                              ? color
                              : color.withValues(alpha: 0.35),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
