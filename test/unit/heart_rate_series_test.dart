import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/heart_rate/heart_rate_series.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';

HeartRateRecordModel hr(DateTime t, int bpm) => HeartRateRecordModel(
  uuid: '$t',
  startTime: t,
  endTime: t,
  beatsPerMinute: bpm,
  sourcePackage: 'pkg',
);

void main() {
  group('#37 HeartRateStats', () {
    test('current=最新, resting=最小, max=最大', () {
      final stats = HeartRateStats.from([
        hr(DateTime(2026, 6, 6, 1), 60),
        hr(DateTime(2026, 6, 6, 3), 120),
        hr(DateTime(2026, 6, 6, 2), 54),
        hr(DateTime(2026, 6, 6, 8), 72),
      ]);
      expect(stats.current, 72); // 最新時刻 (8時)
      expect(stats.resting, 54);
      expect(stats.max, 120);
    });

    test('空は isEmpty', () {
      expect(HeartRateStats.from(const []).isEmpty, isTrue);
    });
  });

  group('#38 filterHeartRateToWindow', () {
    test('睡眠ウィンドウ内のレコードのみ抽出する', () {
      final all = [
        hr(DateTime(2026, 6, 6, 22), 70), // 範囲外(前)
        hr(DateTime(2026, 6, 6, 23, 30), 58), // 範囲内
        hr(DateTime(2026, 6, 7, 3), 55), // 範囲内
        hr(DateTime(2026, 6, 7, 8), 80), // 範囲外(後)
      ];
      final filtered = filterHeartRateToWindow(
        all,
        DateTime(2026, 6, 6, 23),
        DateTime(2026, 6, 7, 7),
      );
      expect(filtered.length, 2);
      expect(filtered.map((p) => p.beatsPerMinute).toSet(), {58, 55});
    });
  });
}
