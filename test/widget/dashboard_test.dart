import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/dashboard/dashboard_view.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

SleepSegment seg() => SleepSegment(
  startTime: DateTime(2026, 6, 6, 0),
  endTime: DateTime(2026, 6, 6, 1),
  stageType: 'deep',
  sourcePackage: 'pkg',
);

Widget app(FakeHealthSyncRepository repo) => ProviderScope(
  overrides: [healthSyncRepositoryProvider.overrideWithValue(repo)],
  child: const MaterialApp(home: DashboardView()),
);

void main() {
  testWidgets('ローカルファースト: 同期完了を待たずローカル DB のデータを即時描画する', (tester) async {
    final repo = FakeHealthSyncRepository(sleep: [seg()]);

    await tester.pumpWidget(app(repo));
    // 最初のフレーム時点 (背後の同期は未完了) で既にローカルデータが描画される。
    expect(find.text('1 件'), findsWidgets);
    expect(find.text('睡眠セグメント'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('同期完了 (done) で購読ウィジェットが自動再描画される', (tester) async {
    final repo = FakeHealthSyncRepository(sleep: <SleepSegment>[]);
    // 同期成功で新データが到着する状況を再現。
    repo.onSync = () => repo.sleep = [seg()];

    await tester.pumpWidget(app(repo));
    // 同期前は 0 件。
    expect(find.widgetWithText(Card, '0 件'), findsWidgets);

    await tester.pumpAndSettle();

    // 同期完了でリアクティブ更新され 1 件になる。
    expect(repo.syncCalls, greaterThanOrEqualTo(1));
    expect(find.text('1 件'), findsOneWidget);
  });

  testWidgets('error 時はフォールバックバナーへ分岐する', (tester) async {
    final repo = FakeHealthSyncRepository(throwOnSync: true);

    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    expect(find.text('同期に失敗しました。表示中のデータはローカル保存分です。'), findsOneWidget);
  });

  testWidgets('同期中 (syncing) でも既存データ表示はブロックされない', (tester) async {
    final repo = FakeHealthSyncRepository(sleep: [seg()]);

    await tester.pumpWidget(app(repo));
    // 同期実行中でもメトリクスは表示され続ける。
    expect(find.text('睡眠セグメント'), findsOneWidget);
    expect(find.text('1 件'), findsWidgets);

    await tester.pumpAndSettle();
  });
}
