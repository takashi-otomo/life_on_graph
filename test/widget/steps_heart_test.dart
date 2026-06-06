import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/heart_rate/widgets/heart_rate_chart.dart';
import 'package:life_on_graph/features/steps/steps_hourly.dart';
import 'package:life_on_graph/features/steps/widgets/steps_bar_chart.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/steps_record_model.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

HeartRateRecordModel hr(DateTime t, int bpm) => HeartRateRecordModel(
  uuid: '$t',
  startTime: t,
  endTime: t,
  beatsPerMinute: bpm,
  sourcePackage: 'pkg',
);

void main() {
  final DateTime day = DateTime(2026, 6, 6);

  group('#36 StepsBarChart', () {
    testWidgets('合計歩数と棒グラフを表示する', (tester) async {
      final steps = StepsHourly.forDay([
        StepsRecordModel(
          uuid: 's1',
          startTime: DateTime(2026, 6, 6, 9),
          endTime: DateTime(2026, 6, 6, 10),
          count: 1234,
          sourcePackage: 'pkg',
        ),
      ], day);

      await tester.pumpWidget(wrap(StepsBarChart(steps: steps)));
      await tester.pumpAndSettle();

      expect(find.text('歩数'), findsOneWidget);
      expect(find.text('1,234 歩'), findsOneWidget);
    });

    testWidgets('データ無しは空メッセージ', (tester) async {
      await tester.pumpWidget(
        wrap(StepsBarChart(steps: StepsHourly.forDay(const [], day))),
      );
      await tester.pumpAndSettle();
      expect(find.text('この日の歩数データはありません'), findsOneWidget);
    });
  });

  group('#37/#38 HeartRateChart', () {
    testWidgets('安静/最高を表示し、睡眠中トグルでフィルタする', (tester) async {
      final points = <HeartRateRecordModel>[
        hr(DateTime(2026, 6, 6, 12), 90), // 日中(睡眠外)
        hr(DateTime(2026, 6, 7, 2), 54), // 睡眠中
      ];
      await tester.pumpWidget(
        wrap(
          HeartRateChart(
            points: points,
            sleepStart: DateTime(2026, 6, 6, 23),
            sleepEnd: DateTime(2026, 6, 7, 7),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 全日: 安静 54 ・ 最高 90。
      expect(find.text('安静 54 ・ 最高 90'), findsOneWidget);

      // 睡眠中トグル → 睡眠中(54)のみ。
      await tester.tap(find.text('睡眠中'));
      await tester.pumpAndSettle();
      expect(find.text('安静 54 ・ 最高 54'), findsOneWidget);
    });

    testWidgets('睡眠期間が無ければトグルは出ない', (tester) async {
      await tester.pumpWidget(
        wrap(HeartRateChart(points: [hr(DateTime(2026, 6, 6, 12), 70)])),
      );
      await tester.pumpAndSettle();
      expect(find.text('睡眠中'), findsNothing);
    });
  });
}
