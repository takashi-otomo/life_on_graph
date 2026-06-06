import '../../models/sleep_segment.dart';

/// クロスデータ統合ビューの共通時間軸 (#39, 設計doc 10)。
///
/// 睡眠セッションの境界 `[start, end]` を共通 X 軸とし、心拍・歩数をこの時刻軸へ
/// 整列させる。3 レイヤの時刻原点・スケールを一致させるための単一の真実源。
class CrossDataWindow {
  const CrossDataWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// 睡眠セグメント群の最小開始〜最大終了を窓とする。空・無効なら `null`。
  static CrossDataWindow? fromSegments(List<SleepSegment> segments) {
    if (segments.isEmpty) return null;
    DateTime start = segments.first.startTime;
    DateTime end = segments.first.endTime;
    for (final SleepSegment s in segments) {
      if (s.startTime.isBefore(start)) start = s.startTime;
      if (s.endTime.isAfter(end)) end = s.endTime;
    }
    if (!end.isAfter(start)) return null; // ゼロ幅は不可。
    return CrossDataWindow(start: start, end: end);
  }

  /// 睡眠の最終地点を右端とし、そこから遡る 24 時間を窓とする (#39)。
  ///
  /// 睡眠だけを軸にすると日中の歩数が窓外になり表示されないため、起床時刻
  /// (睡眠終点) を最大とした 24 時間で日中の活動〜夜間の睡眠までを俯瞰させる。
  static CrossDataWindow? trailing24h(List<SleepSegment> segments) {
    final CrossDataWindow? base = fromSegments(segments);
    if (base == null) return null;
    return CrossDataWindow(
      start: base.end.subtract(const Duration(hours: 24)),
      end: base.end,
    );
  }

  /// 窓の長さ。
  Duration get duration => end.difference(start);

  /// 時刻 [t] の窓内における位置 (0.0〜1.0, 範囲外はクランプ)。
  double fractionOf(DateTime t) {
    final double f =
        t.difference(start).inMilliseconds / duration.inMilliseconds;
    if (f.isNaN) return 0;
    return f.clamp(0.0, 1.0);
  }
}
