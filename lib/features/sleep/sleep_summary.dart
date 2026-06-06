import '../../models/sleep_segment.dart';

/// 睡眠サマリー: 合計時間とステージ別内訳 (#35, 純粋計算)。
class SleepSummary {
  const SleepSummary({required this.total, required this.byStage});

  /// 全セグメントの合計時間 (記録された睡眠期間)。
  final Duration total;

  /// ステージ種別 → 合計時間。
  final Map<String, Duration> byStage;

  /// クレンジング済みセグメント列から集計する。
  factory SleepSummary.fromSegments(List<SleepSegment> segments) {
    final Map<String, Duration> byStage = <String, Duration>{};
    Duration total = Duration.zero;
    for (final SleepSegment s in segments) {
      final Duration d = s.duration;
      total += d;
      byStage[s.stageType] = (byStage[s.stageType] ?? Duration.zero) + d;
    }
    return SleepSummary(total: total, byStage: byStage);
  }

  /// データが無いか。
  bool get isEmpty => total == Duration.zero;

  /// 指定ステージの合計時間 (無ければ 0)。
  Duration stage(String key) => byStage[key] ?? Duration.zero;

  /// 指定ステージが全体に占める比率 (0.0〜1.0)。
  double ratio(String key) {
    if (total.inSeconds == 0) return 0;
    return stage(key).inSeconds / total.inSeconds;
  }
}

/// [Duration] を「7時間12分」形式へ整形する (#35)。
String formatHm(Duration d) {
  final int h = d.inHours;
  final int m = d.inMinutes % 60;
  if (h == 0) return '$m分';
  return '$h時間 $m分';
}
