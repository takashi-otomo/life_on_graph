import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/dashboard/dashboard_view.dart';
import 'package:life_on_graph/features/sleep/widgets/sleep_stage_timeline.dart';
import 'package:life_on_graph/features/sleep/widgets/sleep_summary_card.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

SleepSegment deepSeg() => SleepSegment(
  startTime: DateTime(2026, 6, 6, 23),
  endTime: DateTime(2026, 6, 7, 0),
  stageType: 'deep',
  sourcePackage: 'pkg',
);

Widget app(FakeHealthSyncRepository repo) => ProviderScope(
  overrides: [healthSyncRepositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: DashboardView()),
);

void main() {
  testWidgets('ローカルファースト: 睡眠サマリーとタイムラインを即時描画する', (tester) async {
    final repo = FakeHealthSyncRepository(sleep: [deepSeg()]);

    await tester.pumpWidget(app(repo));
    // 最初のフレームで (同期完了を待たず) サマリーとタイムラインが描画される。
    expect(find.byType(SleepSummaryCard), findsOneWidget);
    expect(find.byType(SleepStageTimeline), findsOneWidget);
    expect(find.text('1時間 0分'), findsWidgets);

    await tester.pumpAndSettle();
  });

  testWidgets('同期完了 (done) で睡眠データがリアクティブ更新される', (tester) async {
    final repo = FakeHealthSyncRepository(sleep: <SleepSegment>[]);
    repo.onSync = () => repo.sleep = [deepSeg()];

    await tester.pumpWidget(app(repo));
    // 同期前は空メッセージ。
    expect(find.text('この日の睡眠データはありません'), findsOneWidget);

    await tester.pumpAndSettle();

    // 同期完了で再評価され、サマリー合計が表示される。
    expect(find.text('1時間 0分'), findsWidgets);
  });

  testWidgets('error 時はフォールバックバナーへ分岐する', (tester) async {
    final repo = FakeHealthSyncRepository(throwOnSync: true);

    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    expect(find.text('同期に失敗しました'), findsOneWidget);
    expect(find.text('表示中のデータはローカル保存分です。'), findsOneWidget);
  });

  testWidgets('#40 同期中 (syncing) もブロックせずローカルデータを即時描画する', (tester) async {
    // syncGate で同期を保留し SyncInProgress を維持する。
    final repo = FakeHealthSyncRepository(sleep: [deepSeg()])
      ..syncGate = Completer<void>();

    await tester.pumpWidget(app(repo));
    // pump 1 回のみ (pumpAndSettle に依存しない)。同期未完了でも描画される。
    await tester.pump();

    expect(find.byType(SleepSummaryCard), findsOneWidget);
    expect(find.text('1時間 0分'), findsWidgets);

    // 後始末: 同期を完了させる。
    repo.syncGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('一部種別失敗 (SyncPartial) でもフォールバックバナーを表示する', (tester) async {
    final repo = FakeHealthSyncRepository(
      sleep: [deepSeg()],
      failedTypesOnSync: {'steps'},
    );

    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    expect(find.text('同期に失敗しました'), findsOneWidget);
    expect(find.text('表示中のデータはローカル保存分です。'), findsOneWidget);
    expect(find.byType(SleepSummaryCard), findsOneWidget);
  });
}
