import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../widgets/app_card.dart';
import '../steps_hourly.dart';

/// 歩数 時間帯別棒グラフ (#36)。日/週/月の比較はサマリー画面 (#67/#68) に分離。
class StepsBarChart extends StatelessWidget {
  const StepsBarChart({super.key, required this.steps});

  final StepsHourly steps;

  @override
  Widget build(BuildContext context) {
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
              const Text(
                '歩数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatNum(steps.total)} 歩',
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
            const SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  'この日の歩数データはありません',
                  style: TextStyle(
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
    const Map<int, String> labels = <int, String>{
      0: '0時',
      6: '6時',
      12: '12時',
      18: '18時',
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
