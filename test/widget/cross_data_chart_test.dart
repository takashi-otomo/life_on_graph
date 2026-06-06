import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/cross_data/widgets/cross_data_chart.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/models/steps_record_model.dart';

SleepSegment seg(String stage, DateTime s, DateTime e) => SleepSegment(
  startTime: s,
  endTime: e,
  stageType: stage,
  sourcePackage: 'p',
);

HeartRateRecordModel hr(DateTime t, int bpm) => HeartRateRecordModel(
  uuid: 'h${t.millisecondsSinceEpoch}',
  startTime: t,
  endTime: t,
  beatsPerMinute: bpm,
  sourcePackage: 'p',
);

StepsRecordModel step(DateTime s, DateTime e, int c) => StepsRecordModel(
  uuid: 's${s.millisecondsSinceEpoch}',
  startTime: s,
  endTime: e,
  count: c,
  sourcePackage: 'p',
);

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  final base = DateTime(2026, 6, 6, 23);

  testWidgets('#39 3種データを共通軸で重畳描画する', (tester) async {
    await tester.pumpWidget(
      host(
        CrossDataChart(
          segments: [
            seg('light', base, base.add(const Duration(hours: 1))),
            seg(
              'deep',
              base.add(const Duration(hours: 1)),
              base.add(const Duration(hours: 4)),
            ),
          ],
          heartRate: [
            hr(base.add(const Duration(minutes: 30)), 58),
            hr(base.add(const Duration(hours: 2)), 52),
            hr(base.add(const Duration(hours: 3)), 60),
          ],
          steps: [
            step(
              base.add(const Duration(hours: 2)),
              base.add(const Duration(hours: 2, minutes: 5)),
              40,
            ),
          ],
        ),
      ),
    );

    expect(find.text('統合ビュー (睡眠×心拍×歩数)'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    // 凡例。
    expect(find.text('心拍'), findsOneWidget);
    expect(find.text('歩数'), findsOneWidget);
  });

  testWidgets('#39 睡眠なしは空状態を表示する', (tester) async {
    await tester.pumpWidget(
      host(const CrossDataChart(segments: [], heartRate: [], steps: [])),
    );
    expect(find.text('睡眠データがないため統合表示できません'), findsOneWidget);
  });

  testWidgets('#39 心拍・歩数が欠損しても睡眠だけで描画される', (tester) async {
    await tester.pumpWidget(
      host(
        CrossDataChart(
          segments: [seg('deep', base, base.add(const Duration(hours: 5)))],
          heartRate: const [],
          steps: const [],
        ),
      ),
    );
    // 例外なく描画され、空状態にはならない。
    expect(find.text('睡眠データがないため統合表示できません'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
