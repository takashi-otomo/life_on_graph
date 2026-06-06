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
  /// 当日 0:00〜24:00 と交差する区間の **当日にかかった分** を、区間長に対する
  /// 重なり割合で按分して加算する。これにより日跨ぎレコード (例 23:30→00:30) も
  /// 当日分が欠落しない (#36)。瞬間値 (start==end) は開始時刻が当日内なら全量加算。
  factory StepsHourly.forDay(List<StepsRecordModel> records, DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    final List<int> hourly = List<int>.filled(24, 0);
    for (final StepsRecordModel r in records) {
      final int durMs = r.endTime.difference(r.startTime).inMilliseconds;
      if (durMs <= 0) {
        // 瞬間値: 開始時刻が当日内なら全量。
        if (!r.startTime.isBefore(start) && r.startTime.isBefore(end)) {
          hourly[r.startTime.hour] += r.count;
        }
        continue;
      }
      final DateTime os = r.startTime.isBefore(start) ? start : r.startTime;
      final DateTime oe = r.endTime.isAfter(end) ? end : r.endTime;
      final int overlapMs = oe.difference(os).inMilliseconds;
      if (overlapMs <= 0) continue; // 当日と重ならない
      final int inDay = (r.count * overlapMs / durMs).round();
      // 当日にかかった分は、クリップ後の開始時刻が属する時間帯へ加算する。
      hourly[os.hour] += inDay;
    }
    final int total = hourly.fold(0, (a, b) => a + b);
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
