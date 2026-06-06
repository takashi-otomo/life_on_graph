import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/steps/steps_hourly.dart';
import 'package:life_on_graph/models/steps_record_model.dart';

StepsRecordModel rec(DateTime start, int count) => StepsRecordModel(
  uuid: '$start-$count',
  startTime: start,
  endTime: start.add(const Duration(minutes: 30)),
  count: count,
  sourcePackage: 'pkg',
);

void main() {
  final DateTime day = DateTime(2026, 6, 6);

  group('#36 StepsHourly', () {
    test('時間帯別に集計し合計を算出する', () {
      final h = StepsHourly.forDay([
        rec(DateTime(2026, 6, 6, 8, 10), 300),
        rec(DateTime(2026, 6, 6, 8, 40), 200),
        rec(DateTime(2026, 6, 6, 18), 1000),
      ], day);

      expect(h.hourly[8], 500);
      expect(h.hourly[18], 1000);
      expect(h.total, 1500);
      expect(h.hourly.length, 24);
    });

    test('当日 0:00〜24:00 外のレコードは除外する', () {
      final h = StepsHourly.forDay([
        rec(DateTime(2026, 6, 5, 23, 30), 999), // 前日
        rec(DateTime(2026, 6, 6, 0, 1), 100), // 当日
        rec(DateTime(2026, 6, 7, 0, 1), 888), // 翌日
      ], day);

      expect(h.total, 100);
      expect(h.hourly[0], 100);
    });

    test('peak は最大時間帯、空は isEmpty', () {
      expect(StepsHourly.forDay(const [], day).isEmpty, isTrue);
      expect(StepsHourly.forDay(const [], day).peak, 1);
      final h = StepsHourly.forDay([rec(DateTime(2026, 6, 6, 9), 700)], day);
      expect(h.peak, 700);
    });
  });
}
