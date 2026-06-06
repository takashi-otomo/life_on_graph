import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/settings/settings_view.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

void main() {
  Widget app(FakeHealthSyncRepository repo) => ProviderScope(
    overrides: [healthSyncRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: SettingsView()),
  );

  testWidgets('#69 各セクションと主要項目を表示する', (tester) async {
    final repo = FakeHealthSyncRepository()
      ..lastSync = DateTime(2026, 6, 6, 7, 5);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    expect(find.text('データ同期'), findsOneWidget);
    expect(find.text('プライバシーとセキュリティ'), findsOneWidget);
    expect(find.text('情報'), findsOneWidget);

    expect(find.text('今すぐ同期'), findsOneWidget);
    expect(find.text('最終同期: 6/6 07:05'), findsOneWidget);
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    expect(find.text('すべてのデータを削除'), findsOneWidget);
    expect(find.text('バージョン'), findsOneWidget);
    expect(find.text('お問い合わせ'), findsOneWidget);
  });

  testWidgets('#69 未同期時は「未同期」を表示する', (tester) async {
    await tester.pumpWidget(app(FakeHealthSyncRepository()));
    await tester.pumpAndSettle();
    expect(find.text('未同期'), findsOneWidget);
  });

  testWidgets('#69 今すぐ同期タップで同期が起動する', (tester) async {
    final repo = FakeHealthSyncRepository();
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('今すぐ同期'));
    await tester.pumpAndSettle();

    expect(repo.syncCalls, 1);
  });

  testWidgets('#69 データ削除は確認後に clearAllData を呼ぶ', (tester) async {
    final repo = FakeHealthSyncRepository()..lastSync = DateTime(2026, 6, 6);
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();

    // 確認ダイアログを開く。
    await tester.tap(find.text('すべてのデータを削除'));
    await tester.pumpAndSettle();
    expect(find.text('削除する'), findsOneWidget);

    // キャンセルでは削除しない。
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(repo.clearAllCalls, 0);

    // 再度開いて削除を確定。
    await tester.tap(find.text('すべてのデータを削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repo.clearAllCalls, 1);
    expect(find.text('ローカルデータを削除しました'), findsOneWidget);
  });
}
