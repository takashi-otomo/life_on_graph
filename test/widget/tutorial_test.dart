import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/app_shell.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/providers/repository_providers.dart';
import 'package:life_on_graph/providers/tutorial_provider.dart';

import '../helpers/fake_health_sync_repository.dart';

/// build()=false (表示する) + complete() を DB なしで処理。
class _ActiveTutorial extends TutorialCompletedNotifier {
  @override
  bool build() => false;
  @override
  Future<void> complete() async => state = true;
}

void main() {
  Widget app() => ProviderScope(
    overrides: [
      healthSyncRepositoryProvider.overrideWithValue(
        FakeHealthSyncRepository(),
      ),
      tutorialCompletedProvider.overrideWith(_ActiveTutorial.new),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ja'),
      home: AppShell(),
    ),
  );

  testWidgets('#109 初回はチュートリアルを表示し、次へで進む', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // ステップ1: 日付
    expect(find.text('日付をタップ'), findsOneWidget);
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    // ステップ2: データカード
    expect(find.text('その日のデータ'), findsOneWidget);
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    // ステップ3: タブ (最終 → 完了)
    expect(find.text('画面を切り替え'), findsOneWidget);
    expect(find.text('完了'), findsOneWidget);
    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();
    // オーバーレイが消える
    expect(find.text('画面を切り替え'), findsNothing);
  });

  testWidgets('#109 スキップでチュートリアルを閉じる', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('日付をタップ'), findsOneWidget);
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();
    expect(find.text('日付をタップ'), findsNothing);
  });
}
