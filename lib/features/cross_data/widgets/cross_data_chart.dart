import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/heart_rate_record_model.dart';
import '../../../models/sleep_segment.dart';
import '../../../models/steps_record_model.dart';
import '../../../widgets/app_card.dart';
import '../cross_data_window.dart';

/// クロスデータ統合ビュー (#39): 睡眠ステージ・心拍・歩数を睡眠セッションの
/// 共通時間軸で表示する。
///
/// 3 種を **縦に分離したレーン** (心拍 / 睡眠 / 歩数) に描き、共通の時刻軸 (X) で
/// 整列させる。背景に睡眠ステージを敷いて他レイヤを重ねると「歩行中なのに睡眠中」の
/// ように誤読されるため、各データを独立トラックに分けて時間軸だけを共有する。
///
/// いずれか1種が欠損しても残データで描画する。睡眠が無ければ統合の時間軸を作れない
/// ため空状態を表示する。
class CrossDataChart extends StatelessWidget {
  const CrossDataChart({
    super.key,
    required this.segments,
    required this.heartRate,
    required this.steps,
  });

  final List<SleepSegment> segments;
  final List<HeartRateRecordModel> heartRate;
  final List<StepsRecordModel> steps;

  @override
  Widget build(BuildContext context) {
    final CrossDataWindow? window = CrossDataWindow.fromSegments(segments);

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.insights, size: 18, color: AppColors.accent),
              SizedBox(width: 8),
              Text(
                '統合ビュー (睡眠×心拍×歩数)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '同じ時間軸で各データを別レーンに表示します',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          if (window == null)
            const SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  '睡眠データがないため統合表示できません',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else ...<Widget>[
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _CrossDataPainter(
                  window: window,
                  segments: segments,
                  heartRate: heartRate,
                  steps: steps,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _Legend(),
          ],
        ],
      ),
    );
  }
}

class _CrossDataPainter extends CustomPainter {
  _CrossDataPainter({
    required this.window,
    required this.segments,
    required this.heartRate,
    required this.steps,
  });

  final CrossDataWindow window;
  final List<SleepSegment> segments;
  final List<HeartRateRecordModel> heartRate;
  final List<StepsRecordModel> steps;

  // レーン名ラベル用の左ガター幅。
  static const double _leftPad = 32;
  // 時刻軸ラベル用の下マージン。
  static const double _bottomAxis = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double chartLeft = _leftPad;
    final double chartW = w - _leftPad;
    final double usable = h - _bottomAxis;
    double x(DateTime t) => chartLeft + chartW * window.fractionOf(t);

    // 3 レーンの縦割り (心拍 45% / 睡眠 20% / 歩数 35%)。
    final double hrTop = 0;
    final double hrH = usable * 0.45;
    final double sleepTop = hrH;
    final double sleepH = usable * 0.20;
    final double stepsTop = sleepTop + sleepH;
    final double stepsBottom = usable;

    _paintLaneLabels(canvas, hrTop, sleepTop, stepsTop, hrH, sleepH);
    _paintSeparators(canvas, w, sleepTop, stepsTop);
    _paintSleepRibbon(canvas, x, sleepTop, sleepH);
    _paintSteps(canvas, x, stepsTop, stepsBottom);
    _paintHeartRate(canvas, x, hrTop, hrH);
    _paintTimeAxis(canvas, x, w, usable);
  }

  void _paintSeparators(
    Canvas canvas,
    double w,
    double sleepTop,
    double stepsTop,
  ) {
    final Paint sep = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(_leftPad, sleepTop), Offset(w, sleepTop), sep);
    canvas.drawLine(Offset(_leftPad, stepsTop), Offset(w, stepsTop), sep);
  }

  void _paintLaneLabels(
    Canvas canvas,
    double hrTop,
    double sleepTop,
    double stepsTop,
    double hrH,
    double sleepH,
  ) {
    _text(canvas, '心拍', Offset(0, hrTop + hrH / 2 - 6), AppColors.heart);
    _text(
      canvas,
      '睡眠',
      Offset(0, sleepTop + sleepH / 2 - 6),
      AppColors.sleepDeep,
    );
    _text(canvas, '歩数', Offset(0, stepsTop + 4), AppColors.steps);
  }

  void _paintSleepRibbon(
    Canvas canvas,
    double Function(DateTime) x,
    double top,
    double height,
  ) {
    for (final SleepSegment s in segments) {
      final double left = x(s.startTime);
      final double right = x(s.endTime);
      if (right <= left) continue;
      // 元のステージ種別で着色 (out_of_bed / awake_in_bed の固有色を保持)。
      final Paint band = Paint()
        ..color = AppColors.sleepStage(s.stageType).withValues(alpha: 0.85);
      canvas.drawRect(
        Rect.fromLTRB(left, top + 2, right, top + height - 2),
        band,
      );
    }
  }

  void _paintSteps(
    Canvas canvas,
    double Function(DateTime) x,
    double top,
    double bottom,
  ) {
    // 窓境界をまたぐレコードは重なり時間で按分し、窓外の歩数を窓内として
    // 過大表示しない (境界レコードが maxCount を支配して他を潰すのも防ぐ)。
    final List<({DateTime at, double count})> inWindow =
        <({DateTime at, double count})>[];
    for (final StepsRecordModel r in steps) {
      if (!r.endTime.isAfter(window.start) ||
          !r.startTime.isBefore(window.end)) {
        continue;
      }
      final DateTime ostart = r.startTime.isBefore(window.start)
          ? window.start
          : r.startTime;
      final DateTime oend = r.endTime.isAfter(window.end)
          ? window.end
          : r.endTime;
      final int overlapMs = oend.difference(ostart).inMilliseconds;
      final int totalMs = r.endTime.difference(r.startTime).inMilliseconds;
      final double prorated = (overlapMs <= 0)
          ? 0
          : (totalMs <= 0
                ? r.count.toDouble()
                : r.count * (overlapMs / totalMs));
      if (prorated > 0) inWindow.add((at: ostart, count: prorated));
    }
    if (inWindow.isEmpty) return;
    final double maxCount = inWindow
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b);
    if (maxCount <= 0) return;
    final double laneH = bottom - top - 4;
    final Paint stepPaint = Paint()..color = AppColors.steps;
    for (final e in inWindow) {
      final double cx = x(e.at);
      final double barH = laneH * (e.count / maxCount);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 2, bottom - barH, 4, barH),
          const Radius.circular(2),
        ),
        stepPaint,
      );
    }
  }

  void _paintHeartRate(
    Canvas canvas,
    double Function(DateTime) x,
    double top,
    double height,
  ) {
    final List<HeartRateRecordModel> hr =
        heartRate
            .where(
              (p) =>
                  !p.startTime.isBefore(window.start) &&
                  !p.startTime.isAfter(window.end),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (hr.isEmpty) return;

    int minBpm = hr.first.beatsPerMinute;
    int maxBpm = hr.first.beatsPerMinute;
    for (final HeartRateRecordModel p in hr) {
      if (p.beatsPerMinute < minBpm) minBpm = p.beatsPerMinute;
      if (p.beatsPerMinute > maxBpm) maxBpm = p.beatsPerMinute;
    }
    final int range = (maxBpm - minBpm) == 0 ? 1 : (maxBpm - minBpm);
    const double pad = 8;
    double y(int bpm) => (maxBpm == minBpm)
        ? top + height / 2
        : top + height - pad - (bpm - minBpm) / range * (height - 2 * pad);

    if (hr.length == 1) {
      // 折れ線にできない単一サンプルはマーカーで描画する (欠損耐性)。
      canvas.drawCircle(
        Offset(x(hr.first.startTime), y(hr.first.beatsPerMinute)),
        3.5,
        Paint()..color = AppColors.heart,
      );
      return;
    }
    final Path path = Path();
    for (int i = 0; i < hr.length; i++) {
      final double px = x(hr[i].startTime);
      final double py = y(hr[i].beatsPerMinute);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.heart
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintTimeAxis(
    Canvas canvas,
    double Function(DateTime) x,
    double w,
    double usable,
  ) {
    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final DateTime mid = window.start.add(
      Duration(milliseconds: window.duration.inMilliseconds ~/ 2),
    );
    final double y = usable + 3;
    _text(canvas, hm(window.start), Offset(_leftPad, y), AppColors.textMuted);
    _text(canvas, hm(mid), Offset(w / 2 - 16, y), AppColors.textMuted);
    _text(canvas, hm(window.end), Offset(w - 34, y), AppColors.textMuted);
  }

  void _text(Canvas canvas, String s, Offset at, Color color) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_CrossDataPainter old) =>
      old.window.start != window.start ||
      old.window.end != window.end ||
      old.segments != segments ||
      old.heartRate != heartRate ||
      old.steps != steps;
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 6,
      children: <Widget>[
        _LegendItem(color: AppColors.sleepDeep, label: '深い'),
        _LegendItem(color: AppColors.sleepLight, label: '浅い'),
        _LegendItem(color: AppColors.sleepRem, label: 'レム'),
        _LegendItem(color: AppColors.sleepAwake, label: '覚醒'),
        _LegendItem(color: AppColors.heart, label: '心拍', line: true),
        _LegendItem(color: AppColors.steps, label: '歩数'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.line = false,
  });

  final Color color;
  final String label;
  final bool line;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: line ? 14 : 10,
          height: line ? 3 : 10,
          decoration: BoxDecoration(
            color: line ? color : color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(line ? 2 : 3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
