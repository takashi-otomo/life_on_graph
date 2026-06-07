import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/features/app_shell.dart';
import 'package:life_on_graph/features/settings/settings_view.dart';
import 'package:life_on_graph/features/summary/summary_view.dart';
import 'package:life_on_graph/features/dashboard/dashboard_view.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

void main() {
  Widget app() => ProviderScope(
    overrides: [
      healthSyncRepositoryProvider.overrideWithValue(
        FakeHealthSyncRepository(),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('ja'),
      home: AppShell(),
    ),
  );

  IndexedStack stackOf(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack));

  testWidgets('初期表示はホーム (index 0, ダッシュボード)', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(stackOf(tester).index, 0);
    expect(find.byType(DashboardView), findsOneWidget);
  });

  testWidgets('サマリー/設定タブへ切り替わる', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // タブバーのアイコン (rounded) は各画面のアイコンと重複しないため一意。
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(stackOf(tester).index, 1);
    expect(find.byType(SummaryView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(stackOf(tester).index, 2);
    expect(find.byType(SettingsView), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    expect(stackOf(tester).index, 0);
  });
}
