import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/heart_rate_record_model.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/segmented_toggle.dart';
import '../heart_rate_series.dart';

/// 心拍折れ線グラフ + 全日/睡眠中フィルタ (#37 / #38)。
class HeartRateChart extends StatefulWidget {
  const HeartRateChart({
    super.key,
    required this.points,
    required this.dayStart,
    required this.dayEnd,
    this.sleepStart,
    this.sleepEnd,
  });

  /// 心拍レコード。睡眠期間が暦日をまたぐ場合に備え、暦日より広い範囲を渡すこと。
  final List<HeartRateRecordModel> points;

  /// 「全日」表示の対象暦日ウィンドウ `[dayStart, dayEnd)`。
  final DateTime dayStart;
  final DateTime dayEnd;

  /// 睡眠期間 (#38 フィルタ用)。null の場合「睡眠中」トグルは無効化。
  final DateTime? sleepStart;
  final DateTime? sleepEnd;

  @override
  State<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends State<HeartRateChart> {
  int _filterIndex = 0; // 0=全日, 1=睡眠中

  bool get _canFilterSleep =>
      widget.sleepStart != null && widget.sleepEnd != null;

  List<HeartRateRecordModel> get _visiblePoints {
    // 睡眠中: 睡眠期間でフィルタ (暦日をまたいでも全期間を表示)。
    if (_filterIndex == 1 && _canFilterSleep) {
      return filterHeartRateToWindow(
        widget.points,
        widget.sleepStart!,
        widget.sleepEnd!,
      );
    }
    // 全日: 対象暦日のみ (広めに渡された範囲から当日分へ絞る)。
    return filterHeartRateToWindow(
      widget.points,
      widget.dayStart,
      widget.dayEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<HeartRateRecordModel> points = _visiblePoints;
    final HeartRateStats stats = HeartRateStats.from(points);
    final AppLocalizations l = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.favorite, size: 20, color: AppColors.heart),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l.heartRate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!stats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            // 直近の心拍を主表示 (デザイン準拠)。
                            Text(
                              l.bpmValue(stats.current!),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.heart,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${l.resting} ${stats.resting} · ${l.max} ${stats.max}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (_canFilterSleep)
                SegmentedToggle(
                  segments: <String>[l.allDay, l.duringSleep],
                  selectedIndex: _filterIndex,
                  onChanged: (i) => setState(() => _filterIndex = i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (points.isEmpty)
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  l.noHeartRateData,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            SizedBox(height: 100, child: _buildChart(points)),
        ],
      ),
    );
  }

  Widget _buildChart(List<HeartRateRecordModel> points) {
    final List<HeartRateRecordModel> sorted = <HeartRateRecordModel>[...points]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final List<FlSpot> spots = <FlSpot>[
      for (final p in sorted)
        FlSpot(
          p.startTime.millisecondsSinceEpoch.toDouble(),
          p.beatsPerMinute.toDouble(),
        ),
    ];

    return LineChart(
      LineChartData(
        lineTouchData: const LineTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.heart,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            // フィードバック反映: エリア塗りは付けず単線で表示 (2本に見える紛らわしさを回避)。
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
