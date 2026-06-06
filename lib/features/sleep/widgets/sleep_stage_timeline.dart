import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/sleep_segment.dart';
import '../../../widgets/app_card.dart';

/// 睡眠ステージ積層タイムライン (ヒプノグラム) (#34)。
///
/// 横軸=時刻、縦軸=ステージ層 (覚醒→レム→浅い→深い) で各セグメントを描画する。
/// 表示範囲はセグメントの最小開始〜最大終了に自動ズームする。
class SleepStageTimeline extends StatelessWidget {
  const SleepStageTimeline({super.key, required this.segments});

  final List<SleepSegment> segments;

  static const List<String> _rowLabels = <String>['覚醒', 'レム', '浅い', '深い'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '睡眠ステージ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (segments.isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  '睡眠データがありません',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            _buildChart(),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final DateTime start = segments
        .map((s) => s.startTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final DateTime end = segments
        .map((s) => s.endTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 30,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final l in _rowLabels)
                      Text(
                        l,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: CustomPaint(
                  painter: HypnogramPainter(
                    segments: segments,
                    windowStart: start,
                    windowEnd: end,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: _TimeAxis(start: start, end: end),
        ),
      ],
    );
  }
}

/// ヒプノグラムを描画する [CustomPainter] (#34)。
class HypnogramPainter extends CustomPainter {
  HypnogramPainter({
    required this.segments,
    required this.windowStart,
    required this.windowEnd,
  });

  final List<SleepSegment> segments;
  final DateTime windowStart;
  final DateTime windowEnd;

  static const int _rows = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double rowH = size.height / _rows;
    final double blockH = rowH * 0.62;
    final int totalMs =
        windowEnd.millisecondsSinceEpoch - windowStart.millisecondsSinceEpoch;
    if (totalMs <= 0) return;

    // 各層のガイドライン。
    final Paint grid = Paint()..color = const Color(0xFFF1F5F9);
    for (int i = 0; i < _rows; i++) {
      final double y = i * rowH + rowH / 2;
      canvas.drawRect(Rect.fromLTWH(0, y - 0.5, size.width, 1), grid);
    }

    for (final SleepSegment s in segments) {
      final int level = _levelOf(s.stageType).clamp(0, _rows - 1);
      final double x =
          (s.startTime.millisecondsSinceEpoch -
              windowStart.millisecondsSinceEpoch) /
          totalMs *
          size.width;
      final double w =
          (s.endTime.millisecondsSinceEpoch -
              s.startTime.millisecondsSinceEpoch) /
          totalMs *
          size.width;
      final double y = level * rowH + (rowH - blockH) / 2;
      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w.clamp(1.0, size.width), blockH),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = AppColors.sleepStage(s.stageType),
      );
    }
  }

  /// ステージ → 層レベル (0=覚醒 〜 3=深い)。
  int _levelOf(String stage) => switch (stage) {
    'awake' || 'awake_in_bed' || 'out_of_bed' => 0,
    'rem' => 1,
    'light' => 2,
    'deep' => 3,
    _ => 1,
  };

  @override
  bool shouldRepaint(HypnogramPainter old) =>
      old.segments != segments ||
      old.windowStart != windowStart ||
      old.windowEnd != windowEnd;
}

class _TimeAxis extends StatelessWidget {
  const _TimeAxis({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    const int ticks = 5;
    final int spanMs =
        end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    final List<DateTime> labels = <DateTime>[
      for (int i = 0; i < ticks; i++)
        DateTime.fromMillisecondsSinceEpoch(
          start.millisecondsSinceEpoch + (spanMs * i ~/ (ticks - 1)),
        ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final t in labels)
          Text(
            _hm(t),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}
