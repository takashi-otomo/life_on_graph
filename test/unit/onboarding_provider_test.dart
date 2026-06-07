import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/providers/onboarding_provider.dart';
import 'package:life_on_graph/providers/repository_providers.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

import '../helpers/fake_secure_key_store.dart';

void main() {
  late Directory tempDir;
  late DatabaseManager db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_onb_test');
    db = DatabaseManager();
    await db.initialize(path: tempDir.path, keyStore: FakeSecureKeyStore());
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  ProviderContainer container() => ProviderContainer(
    overrides: [databaseManagerProvider.overrideWithValue(db)],
  );

  test('#108 新規インストールは未設定 (false)', () {
    final c = container();
    addTearDown(c.dispose);
    expect(c.read(onboardingCompletedProvider), isFalse);
  });

  test('#108 complete() で設定済みになり永続化される', () async {
    final c1 = container();
    await c1.read(onboardingCompletedProvider.notifier).complete();
    expect(c1.read(onboardingCompletedProvider), isTrue);
    c1.dispose();
    final c2 = container();
    addTearDown(c2.dispose);
    expect(c2.read(onboardingCompletedProvider), isTrue);
  });

  test('#108 既存インストール (last_sync あり) は設定済み扱い', () async {
    // 本機能導入前に同期済みのユーザーを模擬。
    await db.metadataBox.put(
      HealthSyncRepositoryImpl.lastSyncTimeKey,
      DateTime(2026, 6, 1).millisecondsSinceEpoch,
    );
    final c = container();
    addTearDown(c.dispose);
    expect(c.read(onboardingCompletedProvider), isTrue);
  });
}
