import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/features/heart_rate/widgets/heart_rate_chart.dart';
import 'package:life_on_graph/features/steps/steps_hourly.dart';
import 'package:life_on_graph/features/steps/widgets/steps_bar_chart.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/steps_record_model.dart';

Widget wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ja'),
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
    testWidgets('全日は暦日に絞り、睡眠中トグルで日跨ぎ睡眠もフィルタする (P1-1)', (tester) async {
      final points = <HeartRateRecordModel>[
        hr(DateTime(2026, 6, 6, 12), 90), // 当日 日中
        hr(DateTime(2026, 6, 7, 2), 54), // 翌朝(日跨ぎ睡眠中)
      ];
      await tester.pumpWidget(
        wrap(
          HeartRateChart(
            points: points,
            dayStart: DateTime(2026, 6, 6),
            dayEnd: DateTime(2026, 6, 7),
            sleepStart: DateTime(2026, 6, 6, 23),
            sleepEnd: DateTime(2026, 6, 7, 7),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 全日(暦日): 当日 日中の 90 のみ。直近 bpm も主表示される (F1)。
      expect(find.text('90 bpm'), findsOneWidget);
      expect(find.text('安静 90 · 最高 90'), findsOneWidget);

      // 睡眠中: 翌朝 2時の 54 (日跨ぎでも欠落しない)。
      await tester.tap(find.text('睡眠中'));
      await tester.pumpAndSettle();
      expect(find.text('安静 54 · 最高 54'), findsOneWidget);
    });

    testWidgets('睡眠期間が無ければトグルは出ない', (tester) async {
      await tester.pumpWidget(
        wrap(
          HeartRateChart(
            points: [hr(DateTime(2026, 6, 6, 12), 70)],
            dayStart: DateTime(2026, 6, 6),
            dayEnd: DateTime(2026, 6, 7),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('睡眠中'), findsNothing);
    });
  });

  group('#hr-gap buildHeartRateSpots (欠落区間で線を分断)', () {
    test('10分超のギャップに nullSpot を挟む', () {
      final points = <HeartRateRecordModel>[
        hr(DateTime(2026, 6, 6, 8), 60),
        hr(DateTime(2026, 6, 6, 8, 1), 61), // 連続 (1分)
        hr(DateTime(2026, 6, 6, 9), 70), // 59分ギャップ → 分断
        hr(DateTime(2026, 6, 6, 9, 1), 71),
      ];
      final spots = buildHeartRateSpots(points);

      // 4 点 + 1 区切り = 5 要素。区切りは null スポット 1 つ。
      expect(spots.length, 5);
      expect(spots.where((s) => s.x.isNaN).length, 1);
      // 区切りは 8:01 と 9:00 の間 (index 2)。
      expect(spots[2].x.isNaN, isTrue);
    });

    test('連続データには nullSpot を挟まない', () {
      final points = <HeartRateRecordModel>[
        hr(DateTime(2026, 6, 6, 8), 60),
        hr(DateTime(2026, 6, 6, 8, 5), 62), // 5分 (閾値内)
        hr(DateTime(2026, 6, 6, 8, 10), 64),
      ];
      final spots = buildHeartRateSpots(points);

      expect(spots.length, 3);
      expect(spots.any((s) => s.x.isNaN), isFalse);
    });

    test('前後とも欠落の孤立点を isolatedX に収集する', () {
      final isolated = <double>{};
      final lone = DateTime(2026, 6, 6, 12);
      final points = <HeartRateRecordModel>[
        // 連続ペア (線になる)。
        hr(DateTime(2026, 6, 6, 8), 60),
        hr(DateTime(2026, 6, 6, 8, 1), 61),
        // 前後とも > 10分 → 孤立点 (ドットで描く)。
        hr(lone, 99),
        // 連続ペア (線になる)。
        hr(DateTime(2026, 6, 6, 18), 70),
        hr(DateTime(2026, 6, 6, 18, 1), 71),
      ];
      buildHeartRateSpots(points, isolatedX: isolated);

      expect(isolated, contains(lone.millisecondsSinceEpoch.toDouble()));
      expect(isolated.length, 1);
    });
  });
}
