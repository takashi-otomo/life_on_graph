import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/onboarding/onboarding_wizard.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/providers/onboarding_provider.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

/// DB なしで complete() を記録するノーティファイア。
class _FakeOnboarding extends OnboardingNotifier {
  @override
  bool build() => false;
  @override
  Future<void> complete() async => state = true;
}

void main() {
  Widget host(WidgetTester tester, {required VoidCallback onFinish}) {
    return ProviderScope(
      overrides: [
        healthSyncRepositoryProvider.overrideWithValue(
          FakeHealthSyncRepository(),
        ),
        onboardingCompletedProvider.overrideWith(_FakeOnboarding.new),
      ],
      child: MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingWizard(onFinish: onFinish),
      ),
    );
  }

  testWidgets('#108 ようこそ→言語→権限 と進める', (tester) async {
    await tester.pumpWidget(host(tester, onFinish: () {}));
    // ようこそ
    expect(find.text('始める'), findsOneWidget);
    await tester.tap(find.text('始める'));
    await tester.pumpAndSettle();
    // 言語
    expect(find.text('次へ'), findsOneWidget);
    expect(find.text('端末の設定に従う'), findsOneWidget);
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    // 権限
    expect(find.text('連携して同期'), findsOneWidget);
    expect(find.text('あとで設定する'), findsOneWidget);
  });

  testWidgets('#108 あとで設定する で完了コールバックが呼ばれる', (tester) async {
    int finished = 0;
    await tester.pumpWidget(host(tester, onFinish: () => finished++));
    await tester.tap(find.text('始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで設定する'));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });

  testWidgets('#108 連携して同期 で同期し完了画面→はじめる', (tester) async {
    int finished = 0;
    await tester.pumpWidget(host(tester, onFinish: () => finished++));
    await tester.tap(find.text('始める'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('連携して同期'));
    await tester.pumpAndSettle();
    // 完了画面
    expect(find.text('準備完了'), findsOneWidget);
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });
}
