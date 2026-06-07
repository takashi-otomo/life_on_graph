import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/features/app_shell.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/providers/locale_provider.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';
import '../helpers/fake_secure_key_store.dart';

void main() {
  Widget app(Locale locale) => ProviderScope(
    overrides: [
      healthSyncRepositoryProvider.overrideWithValue(
        FakeHealthSyncRepository(),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: const AppShell(),
    ),
  );

  group('#94 ロケールに応じてタブ文言が切り替わる', () {
    testWidgets('日本語', (tester) async {
      await tester.pumpWidget(app(const Locale('ja')));
      await tester.pumpAndSettle();
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('サマリー'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('英語', (tester) async {
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('フランス語', (tester) async {
      await tester.pumpWidget(app(const Locale('fr')));
      await tester.pumpAndSettle();
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
    });
  });

  group('#94 localeProvider の永続化', () {
    late Directory tempDir;
    late DatabaseManager db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('log_locale_test');
      db = DatabaseManager();
      await db.initialize(path: tempDir.path, keyStore: FakeSecureKeyStore());
    });
    tearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });

    test('既定は端末設定に従う (null)', () {
      final container = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      expect(container.read(localeProvider), isNull);
    });

    test('setLocale で保存され、再読込でも維持される', () async {
      final c1 = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(db)],
      );
      await c1.read(localeProvider.notifier).setLocale(const Locale('de'));
      expect(c1.read(localeProvider)?.languageCode, 'de');
      c1.dispose();

      // 別コンテナ (再起動相当) でも永続値を読む。
      final c2 = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(db)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(localeProvider)?.languageCode, 'de');
    });

    test('setLocale(null) で端末設定に戻る', () async {
      final container = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await container
          .read(localeProvider.notifier)
          .setLocale(const Locale('fr'));
      await container.read(localeProvider.notifier).setLocale(null);
      expect(container.read(localeProvider), isNull);
    });
  });
}
