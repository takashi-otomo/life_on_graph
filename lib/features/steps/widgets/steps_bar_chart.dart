import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_card.dart';
import '../steps_hourly.dart';

/// 歩数 時間帯別棒グラフ (#36)。日/週/月の比較はサマリー画面 (#67/#68) に分離。
class StepsBarChart extends StatelessWidget {
  const StepsBarChart({super.key, required this.steps});

  final StepsHourly steps;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.directions_walk,
                size: 20,
                color: AppColors.steps,
              ),
              const SizedBox(width: 8),
              Text(
                l.steps,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                l.stepsValue(_formatNum(steps.total)),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.steps,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (steps.isEmpty)
            SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  l.noStepsDataForDay,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 130, child: _buildChart()),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final int peak = steps.peak;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: peak.toDouble(),
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
              interval: 1,
              getTitlesWidget: _bottomLabel,
            ),
          ),
        ),
        barGroups: <BarChartGroupData>[
          for (int h = 0; h < 24; h++)
            BarChartGroupData(
              x: h,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: steps.hourly[h].toDouble(),
                  width: 6,
                  color: steps.hourly[h] == peak
                      ? AppColors.steps
                      : AppColors.stepsSoft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bottomLabel(double value, TitleMeta meta) {
    // 時刻は言語非依存の 24 時間表記 (0:00 / 6:00 …) で表示する。
    const Map<int, String> labels = <int, String>{
      0: '0:00',
      6: '6:00',
      12: '12:00',
      18: '18:00',
    };
    final String? text = labels[value.toInt()];
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  static String _formatNum(int n) {
    final String s = n.toString();
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
