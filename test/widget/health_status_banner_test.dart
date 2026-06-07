import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/providers/repository_providers.dart';
import 'package:life_on_graph/providers/sync_notifier.dart';
import 'package:life_on_graph/widgets/health_status_banner.dart';

import '../helpers/fake_health_sync_repository.dart';

void main() {
  // バナー + ref キャプチャ (sync を起動して状態を作るため)。
  Future<WidgetRef> pumpBanner(
    WidgetTester tester,
    FakeHealthSyncRepository repo,
  ) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthSyncRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                captured = ref;
                return const HealthStatusBanner();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return captured;
  }

  testWidgets('#42 未導入時はインストール導線を表示しタップで誘導する', (tester) async {
    final repo = FakeHealthSyncRepository()..healthConnectAvailable = false;
    await pumpBanner(tester, repo);

    expect(find.text('Health Connect が必要です'), findsOneWidget);
    await tester.tap(find.text('インストール'));
    await tester.pump();
    expect(repo.installCount, 1);
  });

  testWidgets('#42 未許可時は Rationale と許可導線を表示する', (tester) async {
    final repo = FakeHealthSyncRepository()..permissionsGranted = false;
    final ref = await pumpBanner(tester, repo);

    // 同期を起動 → 権限拒否で SyncError(SyncPermissionDeniedException)。
    await ref.read(syncNotifierProvider.notifier).sync();
    await tester.pumpAndSettle();

    expect(find.text('ヘルスデータへのアクセスが必要です'), findsOneWidget);
    expect(find.text('許可する'), findsOneWidget);
  });

  testWidgets('#42 未導入 > 未許可 の優先順位で出し分ける', (tester) async {
    final repo = FakeHealthSyncRepository()
      ..healthConnectAvailable = false
      ..permissionsGranted = false;
    final ref = await pumpBanner(tester, repo);

    await ref.read(syncNotifierProvider.notifier).sync();
    await tester.pumpAndSettle();

    // 未導入が優先され、未許可メッセージは出さない。
    expect(find.text('Health Connect が必要です'), findsOneWidget);
    expect(find.text('ヘルスデータへのアクセスが必要です'), findsNothing);
  });

  testWidgets('#42 同期失敗時は再試行導線を表示する', (tester) async {
    final repo = FakeHealthSyncRepository(throwOnSync: true);
    final ref = await pumpBanner(tester, repo);

    await ref.read(syncNotifierProvider.notifier).sync();
    await tester.pumpAndSettle();

    expect(find.text('同期に失敗しました'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
  });

  testWidgets('#42 導入状態の解決前 (loading) はエラーでもバナーを出さない (P1)', (tester) async {
    // 導入チェックを保留したまま、同期は失敗させる。
    final repo = FakeHealthSyncRepository(throwOnSync: true)
      ..availabilityGate = Completer<void>();
    late WidgetRef ref;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [healthSyncRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: Consumer(
              builder: (context, r, _) {
                ref = r;
                return const HealthStatusBanner();
              },
            ),
          ),
        ),
      ),
    );
    await ref.read(syncNotifierProvider.notifier).sync();
    await tester.pump(); // 導入チェック未解決のまま

    // loading 中はローカルファースト契約によりバナーを出さない。
    expect(find.text('同期に失敗しました'), findsNothing);

    // 後始末: 導入チェックを解決。
    repo.availabilityGate!.complete();
    await tester.pumpAndSettle();
    // 解決後は同期失敗バナーが出る。
    expect(find.text('同期に失敗しました'), findsOneWidget);
  });

  testWidgets('#42 正常時はバナーを表示しない', (tester) async {
    final repo = FakeHealthSyncRepository();
    await pumpBanner(tester, repo);

    expect(find.text('Health Connect が必要です'), findsNothing);
    expect(find.text('ヘルスデータへのアクセスが必要です'), findsNothing);
    expect(find.text('同期に失敗しました'), findsNothing);
  });
}
