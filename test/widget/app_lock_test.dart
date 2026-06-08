import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/features/lock/app_lock_gate.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';
import 'package:life_on_graph/providers/app_lock_provider.dart';
import 'package:life_on_graph/providers/repository_providers.dart';
import 'package:life_on_graph/repositories/biometric_auth.dart';

import '../helpers/fake_biometric_auth.dart';
import '../helpers/fake_secure_key_store.dart';

class _LockedNotifier extends AppLockEnabledNotifier {
  @override
  bool build() => true;
}

void main() {
  Widget gate({required bool authResult}) => ProviderScope(
    overrides: [
      appLockEnabledProvider.overrideWith(_LockedNotifier.new),
      biometricAuthProvider.overrideWithValue(
        FakeBiometricAuth(authResult: authResult),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppLockGate(child: Scaffold(body: Text('SECRET'))),
    ),
  );

  testWidgets('#79 認証成功で中身を表示する', (tester) async {
    await tester.pumpWidget(gate(authResult: true));
    await tester.pumpAndSettle();
    expect(find.text('SECRET'), findsOneWidget);
  });

  testWidgets('#79 認証失敗ならロック画面 (ロック解除ボタン) を表示する', (tester) async {
    await tester.pumpWidget(gate(authResult: false));
    await tester.pumpAndSettle();
    expect(find.text('SECRET'), findsNothing);
    expect(find.text('ロック解除'), findsOneWidget);
  });

  group('#79 appLockEnabledProvider 永続化', () {
    late Directory tempDir;
    late DatabaseManager db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('log_lock_test');
      db = DatabaseManager();
      await db.initialize(path: tempDir.path, keyStore: FakeSecureKeyStore());
    });
    tearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });

    test('既定は無効。set(true) で有効化され永続化される', () async {
      final c1 = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(db)],
      );
      expect(c1.read(appLockEnabledProvider), isFalse);
      await c1.read(appLockEnabledProvider.notifier).set(true);
      expect(c1.read(appLockEnabledProvider), isTrue);
      c1.dispose();

      final c2 = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(db)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(appLockEnabledProvider), isTrue);
    });
  });
}
