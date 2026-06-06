import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/heart_rate_record_model.dart';
import '../../../models/steps_record_model.dart';
import '../../../models/sleep_segment.dart';
import '../../../widgets/app_card.dart';
import '../cross_data_window.dart';

/// クロスデータ統合ビュー (#39): 睡眠ステージ(背景)×心拍(折れ線)×歩数(棒)を
/// 睡眠セッションの共通時間軸で重畳表示する。
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
              height: 150,
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

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    double x(DateTime t) => w * window.fractionOf(t);

    // 1) 背景: 睡眠ステージ帯 (時間範囲を色で塗る)。
    for (final SleepSegment s in segments) {
      final double left = x(s.startTime);
      final double right = x(s.endTime);
      if (right <= left) continue;
      // 元のステージ種別で着色する (out_of_bed / awake_in_bed の固有色を保持し、
      // 離床期間と歩数レイヤの相関を読み取れるようにする)。
      final Paint bg = Paint()
        ..color = AppColors.sleepStage(s.stageType).withValues(alpha: 0.16);
      canvas.drawRect(Rect.fromLTRB(left, 0, right, h), bg);
    }

    // 2) 歩数: 下端の棒 (覚醒・離床中の活動を示す)。最大25%の高さ。
    //    窓境界をまたぐレコードは重なり時間で按分し、窓外の歩数を窓内として
    //    過大表示しない (境界レコードが maxCount を支配して他を潰すのも防ぐ)。
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
    if (inWindow.isNotEmpty) {
      final double maxCount = inWindow
          .map((e) => e.count)
          .reduce((a, b) => a > b ? a : b);
      final double stepsMaxH = h * 0.25;
      final Paint stepPaint = Paint()..color = AppColors.steps;
      for (final e in inWindow) {
        if (maxCount <= 0) continue;
        final double cx = x(e.at);
        final double barH = stepsMaxH * (e.count / maxCount);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 2, h - barH, 4, barH),
            const Radius.circular(2),
          ),
          stepPaint,
        );
      }
    }

    // 3) 心拍: 折れ線 (全高にマッピング、上下パディング)。
    final List<HeartRateRecordModel> hr =
        heartRate
            .where(
              (p) =>
                  !p.startTime.isBefore(window.start) &&
                  !p.startTime.isAfter(window.end),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (hr.isNotEmpty) {
      int minBpm = hr.first.beatsPerMinute;
      int maxBpm = hr.first.beatsPerMinute;
      for (final HeartRateRecordModel p in hr) {
        if (p.beatsPerMinute < minBpm) minBpm = p.beatsPerMinute;
        if (p.beatsPerMinute > maxBpm) maxBpm = p.beatsPerMinute;
      }
      final int range = (maxBpm - minBpm) == 0 ? 1 : (maxBpm - minBpm);
      const double pad = 14;
      // 単一サンプル (min==max) は中央へ配置する。
      double y(int bpm) => (maxBpm == minBpm)
          ? h / 2
          : h - pad - (bpm - minBpm) / range * (h - 2 * pad);

      if (hr.length == 1) {
        // 折れ線にできない単一サンプルはマーカーで描画する (欠損耐性)。
        canvas.drawCircle(
          Offset(x(hr.first.startTime), y(hr.first.beatsPerMinute)),
          3.5,
          Paint()..color = AppColors.heart,
        );
      } else {
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
        final Paint linePaint = Paint()
          ..color = AppColors.heart
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(path, linePaint);
      }
    }
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
            color: line ? color : color.withValues(alpha: 0.5),
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
