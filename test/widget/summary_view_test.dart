import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/summary/summary_view.dart';
import 'package:life_on_graph/features/summary/widgets/trend_bar_chart.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/models/steps_record_model.dart';
import 'package:life_on_graph/providers/nav_provider.dart';
import 'package:life_on_graph/providers/repository_providers.dart';
import 'package:life_on_graph/widgets/segmented_toggle.dart';

import '../helpers/fake_health_sync_repository.dart';

/// セグメントトグル内の指定ラベル (軸ラベル等との衝突を避ける)。
Finder toggleSeg(String label) => find.descendant(
  of: find.byType(SegmentedToggle),
  matching: find.text(label),
);

FakeHealthSyncRepository buildRepo() => FakeHealthSyncRepository(
  sleep: [
    SleepSegment(
      startTime: DateTime(2026, 6, 6, 0),
      endTime: DateTime(2026, 6, 6, 7),
      stageType: 'deep',
      sourcePackage: 'pkg',
    ),
  ],
  steps: [
    StepsRecordModel(
      uuid: 's',
      startTime: DateTime(2026, 6, 6, 9),
      endTime: DateTime(2026, 6, 6, 10),
      count: 8000,
      sourcePackage: 'pkg',
    ),
  ],
  heartRate: [
    HeartRateRecordModel(
      uuid: 'h',
      startTime: DateTime(2026, 6, 6, 3),
      endTime: DateTime(2026, 6, 6, 3),
      beatsPerMinute: 60,
      sourcePackage: 'pkg',
    ),
  ],
);

Widget app() => ProviderScope(
  overrides: [healthSyncRepositoryProvider.overrideWithValue(buildRepo())],
  child: const MaterialApp(home: SummaryView()),
);

void main() {
  testWidgets('期間トグル・KPI・トレンドチャートを表示する', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(toggleSeg('日'), findsOneWidget);
    expect(toggleSeg('週'), findsOneWidget);
    expect(toggleSeg('月'), findsOneWidget);
    expect(find.text('平均睡眠'), findsOneWidget);
    expect(find.text('平均歩数'), findsOneWidget);
    expect(find.text('平均心拍'), findsOneWidget);
    expect(find.text('安静時心拍'), findsOneWidget);
    // トレンドチャート(睡眠/歩数)。2本目は ListView のフォールド外のため
    // 少なくとも1本の描画を確認 (フルレンダリングは目視/実機で検証)。
    expect(find.byType(TrendBarChart), findsWidgets);
  });

  testWidgets('日トグルで「今日の詳細を見る」CTA が表示される', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 既定 (週) では CTA 非表示。
    expect(find.text('今日の詳細を見る'), findsNothing);

    await tester.tap(toggleSeg('日'));
    await tester.pumpAndSettle();
    expect(find.text('今日の詳細を見る'), findsOneWidget);
  });

  testWidgets('日CTAタップでホームタブ (index 0) へ遷移する', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthSyncRepositoryProvider.overrideWithValue(buildRepo()),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SummaryView();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 事前にタブを設定 (2) にしておく。
    capturedRef.read(navTabProvider.notifier).select(2);
    await tester.pumpAndSettle();
    expect(capturedRef.read(navTabProvider), 2);

    await tester.tap(toggleSeg('日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('今日の詳細を見る'));
    await tester.pumpAndSettle();

    expect(capturedRef.read(navTabProvider), 0);
  });
}
