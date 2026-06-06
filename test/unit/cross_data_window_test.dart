import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/cross_data/cross_data_window.dart';
import 'package:life_on_graph/models/sleep_segment.dart';

SleepSegment seg(String stage, DateTime s, DateTime e) => SleepSegment(
  startTime: s,
  endTime: e,
  stageType: stage,
  sourcePackage: 'p',
);

void main() {
  group('#39 CrossDataWindow', () {
    test('最小開始〜最大終了を窓とする', () {
      final w = CrossDataWindow.fromSegments([
        seg('light', DateTime(2026, 6, 6, 23), DateTime(2026, 6, 7, 1)),
        seg('deep', DateTime(2026, 6, 7, 0), DateTime(2026, 6, 7, 6)),
      ]);
      expect(w, isNotNull);
      expect(w!.start, DateTime(2026, 6, 6, 23));
      expect(w.end, DateTime(2026, 6, 7, 6));
    });

    test('空なら null', () {
      expect(CrossDataWindow.fromSegments([]), isNull);
    });

    test('fractionOf は 0..1 にクランプされ中点は0.5', () {
      final w = CrossDataWindow(
        start: DateTime(2026, 6, 6, 0),
        end: DateTime(2026, 6, 6, 10),
      );
      expect(w.fractionOf(DateTime(2026, 6, 6, 5)), closeTo(0.5, 1e-9));
      expect(w.fractionOf(DateTime(2026, 6, 5)), 0.0); // 範囲前
      expect(w.fractionOf(DateTime(2026, 6, 7)), 1.0); // 範囲後
    });
  });
}
