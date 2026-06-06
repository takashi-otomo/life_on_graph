import '../../models/heart_rate_record_model.dart';

/// 心拍の代表統計 (#37)。
class HeartRateStats {
  const HeartRateStats({this.current, this.resting, this.max});

  /// 直近 (最新時刻) の bpm。
  final int? current;

  /// 安静時 (最小) bpm。
  final int? resting;

  /// 最高 bpm。
  final int? max;

  bool get isEmpty => current == null;

  /// レコード列から統計を算出する。
  factory HeartRateStats.from(List<HeartRateRecordModel> points) {
    if (points.isEmpty) return const HeartRateStats();
    final List<HeartRateRecordModel> sorted = <HeartRateRecordModel>[...points]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    int lo = sorted.first.beatsPerMinute;
    int hi = sorted.first.beatsPerMinute;
    for (final HeartRateRecordModel p in sorted) {
      if (p.beatsPerMinute < lo) lo = p.beatsPerMinute;
      if (p.beatsPerMinute > hi) hi = p.beatsPerMinute;
    }
    return HeartRateStats(
      current: sorted.last.beatsPerMinute,
      resting: lo,
      max: hi,
    );
  }
}

/// `[start, end)` の範囲に入る心拍レコードのみ抽出する (#38 睡眠中フィルタ等)。
List<HeartRateRecordModel> filterHeartRateToWindow(
  List<HeartRateRecordModel> points,
  DateTime start,
  DateTime end,
) {
  return points
      .where((p) => !p.startTime.isBefore(start) && p.startTime.isBefore(end))
      .toList();
}
