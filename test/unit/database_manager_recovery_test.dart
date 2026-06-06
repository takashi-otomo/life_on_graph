import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/core/encryption_key_provider.dart';
import 'package:life_on_graph/models/sleep_record_model.dart';

import '../helpers/fake_secure_key_store.dart';

/// #56: 暗号鍵不整合 (Auto Backup 復元で Keystore 材料が欠落) からの復旧を検証する。
void main() {
  late Directory tempDir;
  late DatabaseManager db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_recovery_test');
    db = DatabaseManager();
  });

  tearDown(() async {
    if (db.isInitialized) await db.close();
    await tempDir.delete(recursive: true);
  });

  test('鍵が利用不能 (read 例外) でもクラッシュせず起動を継続する', () async {
    final keyStore = FakeSecureKeyStore();
    // 破損した鍵エントリが復元された状況を再現 (read で例外)。
    keyStore.seedCorrupt(
      EncryptionKeyProvider.keyAlias,
      'restored-but-unusable',
    );

    // 例外を投げず初期化が完了する。
    await db.initialize(path: tempDir.path, keyStore: keyStore);

    expect(db.isInitialized, isTrue);
    expect(db.recoveredFromKeyFailure, isTrue);
    // 復旧後のボックスは開通し読み書きできる。
    expect(db.sleepBox.isOpen, isTrue);
    await db.sleepBox.put(
      'k',
      SleepRecordModel(
        uuid: 'k',
        startTime: DateTime(2026, 6, 6, 1),
        endTime: DateTime(2026, 6, 6, 2),
        stageType: 'deep',
        sourcePackage: 'pkg',
      ),
    );
    expect(db.sleepBox.length, 1);
  });

  test('復旧時に鍵が再生成される (破損エントリ削除 + 新規生成)', () async {
    final keyStore = FakeSecureKeyStore();
    keyStore.seedCorrupt(EncryptionKeyProvider.keyAlias, 'bad');

    await db.initialize(path: tempDir.path, keyStore: keyStore);

    // 破損エントリは削除され、新しい鍵が書き込まれている。
    expect(keyStore.deleteCount, greaterThanOrEqualTo(1));
    expect(keyStore.writeCount, 1);
  });

  test('復旧で同期メタデータがクリアされ再バックフィルに備える', () async {
    // 事前に正常初期化して last_sync_time を書き込む。
    final goodStore = FakeSecureKeyStore();
    await db.initialize(path: tempDir.path, keyStore: goodStore);
    await db.metadataBox.put('last_sync_time', 1234567890);
    await db.close();

    // 鍵が破損した状態で再初期化 → 復旧でメタデータがクリアされる。
    final corruptStore = FakeSecureKeyStore();
    corruptStore.seedCorrupt(EncryptionKeyProvider.keyAlias, 'bad');
    final db2 = DatabaseManager();
    await db2.initialize(path: tempDir.path, keyStore: corruptStore);

    expect(db2.recoveredFromKeyFailure, isTrue);
    expect(db2.metadataBox.get('last_sync_time', defaultValue: 0), 0);
    await db2.close();
  });

  test('正常な鍵では復旧は走らない (recoveredFromKeyFailure=false)', () async {
    final keyStore = FakeSecureKeyStore();
    await db.initialize(path: tempDir.path, keyStore: keyStore);

    expect(db.isInitialized, isTrue);
    expect(db.recoveredFromKeyFailure, isFalse);
  });
}
