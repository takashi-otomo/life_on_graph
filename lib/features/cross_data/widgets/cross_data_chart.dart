import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/heart_rate_record_model.dart';
import '../../../models/sleep_segment.dart';
import '../../../models/steps_record_model.dart';
import '../../../widgets/app_card.dart';
import '../cross_data_window.dart';

// レーン縦割りの共有定数 (左ラベル列と painter で一致させる)。
const double _kChartHeight = 200;
const double _kAxisH = 22;
const double _kHrFrac = 0.45;
const double _kSleepFrac = 0.20;
const double _kStepsFrac = 0.35;
const double _kLabelW = 36;
// 1 時間あたりの横幅 (横スクロールの密度)。
const double _kPxPerHour = 54;

/// クロスデータ統合ビュー (#39): 睡眠・心拍・歩数を **睡眠終点を右端とした24時間**の
/// 共通時間軸で表示する。
///
/// 睡眠だけを軸にすると日中の歩数が窓外になるため、起床時刻 (睡眠終点) を最大とした
/// 24 時間で日中の活動〜夜間の睡眠までを俯瞰させる。3 種は **縦に分離したレーン**
/// (心拍 / 睡眠 / 歩数) に描き、共通の時刻軸 (X) で整列させる (歩行が睡眠中に
/// 重なって誤読されるのを防ぐ)。横スクロールで時間帯の詳細を確認できる。
///
/// いずれか1種が欠損しても残データで描画する。睡眠が無ければ時間軸の基準を作れない
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
    final CrossDataWindow? window = CrossDataWindow.trailing24h(segments);
    final AppLocalizations l = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.insights, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.crossTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.crossSubtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          if (window == null)
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  l.crossEmpty,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else ...<Widget>[
            _Chart(
              window: window,
              segments: segments,
              heartRate: heartRate,
              steps: steps,
            ),
            const SizedBox(height: 12),
            const _Legend(),
          ],
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.window,
    required this.segments,
    required this.heartRate,
    required this.steps,
  });

  final CrossDataWindow window;
  final List<SleepSegment> segments;
  final List<HeartRateRecordModel> heartRate;
  final List<StepsRecordModel> steps;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final double hours = window.duration.inMinutes / 60.0;
    final double contentW = (hours * _kPxPerHour).clamp(320.0, 4000.0);
    const double usable = _kChartHeight - _kAxisH;

    return SizedBox(
      height: _kChartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 固定の左ラベル列 (スクロールしない)。
          SizedBox(
            width: _kLabelW,
            height: _kChartHeight,
            child: Column(
              children: <Widget>[
                _laneLabel(l.heartRate, AppColors.heart, usable * _kHrFrac),
                _laneLabel(l.sleep, AppColors.sleepDeep, usable * _kSleepFrac),
                _laneLabel(l.steps, AppColors.steps, usable * _kStepsFrac),
                const SizedBox(height: _kAxisH),
              ],
            ),
          ),
          // スクロールするプロット領域。
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: contentW,
                height: _kChartHeight,
                child: CustomPaint(
                  painter: _CrossDataPainter(
                    window: window,
                    segments: segments,
                    heartRate: heartRate,
                    steps: steps,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _laneLabel(String text, Color color, double height) => SizedBox(
    height: height,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ),
  );
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

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double usable = size.height - _kAxisH;
    double x(DateTime t) => w * window.fractionOf(t);

    final double hrTop = 0;
    final double hrH = usable * _kHrFrac;
    final double sleepTop = hrH;
    final double sleepH = usable * _kSleepFrac;
    final double stepsTop = sleepTop + sleepH;
    final double stepsBottom = usable;

    _paintSeparators(canvas, w, sleepTop, stepsTop, usable);
    _paintSleepRibbon(canvas, x, sleepTop, sleepH);
    _paintSteps(canvas, x, stepsTop, stepsBottom);
    _paintHeartRate(canvas, x, hrTop, hrH);
    _paintTimeAxis(canvas, x, usable);
  }

  void _paintSeparators(
    Canvas canvas,
    double w,
    double sleepTop,
    double stepsTop,
    double usable,
  ) {
    final Paint sep = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, sleepTop), Offset(w, sleepTop), sep);
    canvas.drawLine(Offset(0, stepsTop), Offset(w, stepsTop), sep);
    canvas.drawLine(Offset(0, usable), Offset(w, usable), sep);
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
    double usable,
  ) {
    String hm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    // 3 時間ごとの目盛り (最初の3の倍数時から窓終端まで)。
    final Paint tick = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    DateTime t = DateTime(
      window.start.year,
      window.start.month,
      window.start.day,
      window.start.hour - (window.start.hour % 3) + 3,
    );
    final double yLabel = usable + 4;
    while (!t.isAfter(window.end)) {
      if (!t.isBefore(window.start)) {
        final double px = x(t);
        canvas.drawLine(Offset(px, 0), Offset(px, usable), tick);
        _text(canvas, hm(t), Offset(px - 14, yLabel), AppColors.textMuted);
      }
      t = t.add(const Duration(hours: 3));
    }
    // 右端 (起床時刻) を強調。
    _text(
      canvas,
      hm(window.end),
      Offset(x(window.end) - 30, yLabel),
      AppColors.accent,
    );
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
    final AppLocalizations l = AppLocalizations.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: <Widget>[
        _LegendItem(color: AppColors.sleepDeep, label: l.stageDeep),
        _LegendItem(color: AppColors.sleepLight, label: l.stageLight),
        _LegendItem(color: AppColors.sleepRem, label: l.stageRem),
        _LegendItem(color: AppColors.sleepAwake, label: l.stageAwake),
        _LegendItem(color: AppColors.heart, label: l.heartRate, line: true),
        _LegendItem(color: AppColors.steps, label: l.steps),
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
