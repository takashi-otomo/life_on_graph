import '../../models/steps_record_model.dart';

/// 歩数の時間帯別集計 (#36, 純粋計算)。
class StepsHourly {
  const StepsHourly({required this.hourly, required this.total});

  /// 0時〜23時の各時間帯の歩数 (長さ 24)。
  final List<int> hourly;

  /// 合計歩数。
  final int total;

  /// 指定日 [day] のレコードを時間帯別に集計する。
  ///
  /// レコードの開始時刻が属する時間帯に加算する (当日 0:00〜24:00 のみ対象)。
  factory StepsHourly.forDay(List<StepsRecordModel> records, DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    final List<int> hourly = List<int>.filled(24, 0);
    int total = 0;
    for (final StepsRecordModel r in records) {
      if (r.startTime.isBefore(start) || !r.startTime.isBefore(end)) continue;
      hourly[r.startTime.hour] += r.count;
      total += r.count;
    }
    return StepsHourly(hourly: hourly, total: total);
  }

  /// 最大時間帯の歩数 (バー高さ正規化用、0 のとき 1 を返す)。
  int get peak {
    final int m = hourly.fold(0, (a, b) => a > b ? a : b);
    return m == 0 ? 1 : m;
  }

  /// データが無いか。
  bool get isEmpty => total == 0;
}
