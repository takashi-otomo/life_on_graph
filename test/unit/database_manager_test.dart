import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/sleep_record_model.dart';
import 'package:life_on_graph/models/steps_record_model.dart';

import '../helpers/fake_secure_key_store.dart';

void main() {
  late Directory tempDir;
  late DatabaseManager db;
  late FakeSecureKeyStore keyStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_db_test');
    keyStore = FakeSecureKeyStore();
    db = DatabaseManager();
    await db.initialize(path: tempDir.path, keyStore: keyStore);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('暗号化ボックスとメタデータボックスが開通する', () {
    expect(db.isInitialized, isTrue);
    expect(db.sleepBox.isOpen, isTrue);
    expect(db.stepsBox.isOpen, isTrue);
    expect(db.heartRateBox.isOpen, isTrue);
    expect(db.metadataBox.isOpen, isTrue);
  });

  test('3 モデルを暗号化ボックスへ put/get できる', () async {
    await db.sleepBox.put(
      's1',
      SleepRecordModel(
        uuid: 's1',
        startTime: DateTime(2026, 6, 1, 23),
        endTime: DateTime(2026, 6, 2, 6),
        stageType: 'rem',
        sourcePackage: 'pkg.a',
      ),
    );
    await db.stepsBox.put(
      'st1',
      StepsRecordModel(
        uuid: 'st1',
        startTime: DateTime(2026, 6, 1, 8),
        endTime: DateTime(2026, 6, 1, 9),
        count: 500,
        sourcePackage: 'pkg.b',
      ),
    );
    final ts = DateTime(2026, 6, 1, 3);
    await db.heartRateBox.put(
      'h1',
      HeartRateRecordModel(
        uuid: 'h1',
        startTime: ts,
        endTime: ts,
        beatsPerMinute: 60,
        sourcePackage: 'pkg.a',
      ),
    );

    expect(db.sleepBox.get('s1')!.stageType, 'rem');
    expect(db.stepsBox.get('st1')!.count, 500);
    expect(db.heartRateBox.get('h1')!.beatsPerMinute, 60);
  });

  test('同一セグメントの再取得は hiveKey 上書きで重複が増えない (Deduplication)', () async {
    SleepRecordModel sleep() => SleepRecordModel(
      uuid: 'dup',
      startTime: DateTime(2026, 6, 1, 23),
      endTime: DateTime(2026, 6, 2, 6),
      stageType: 'deep',
      sourcePackage: 'pkg.a',
    );

    final a = sleep();
    final b = sleep();
    await db.sleepBox.put(a.hiveKey, a);
    await db.sleepBox.put(b.hiveKey, b);

    expect(db.sleepBox.length, 1);
  });

  test('同一セッションの複数ステージは hiveKey で別管理され潰れない', () async {
    final deep = SleepRecordModel(
      uuid: 'session-x',
      startTime: DateTime(2026, 6, 1, 23),
      endTime: DateTime(2026, 6, 1, 23, 40),
      stageType: 'deep',
      sourcePackage: 'pkg.a',
    );
    final rem = SleepRecordModel(
      uuid: 'session-x',
      startTime: DateTime(2026, 6, 1, 23, 40),
      endTime: DateTime(2026, 6, 2, 0, 20),
      stageType: 'rem',
      sourcePackage: 'pkg.a',
    );

    await db.sleepBox.put(deep.hiveKey, deep);
    await db.sleepBox.put(rem.hiveKey, rem);

    // 親 UUID は同じだが 2 ステージとも保持される。
    expect(db.sleepBox.length, 2);
  });

  test('メタデータボックスに同期タイムスタンプを保存・取得できる', () async {
    const key = 'last_sync_time';
    final now = DateTime(2026, 6, 4, 12).millisecondsSinceEpoch;

    expect(db.metadataBox.get(key, defaultValue: 0), 0);
    await db.metadataBox.put(key, now);
    expect(db.metadataBox.get(key), now);
  });

  test('再初期化後も暗号鍵が同一で既存データを復号できる', () async {
    await db.sleepBox.put(
      'persist',
      SleepRecordModel(
        uuid: 'persist',
        startTime: DateTime(2026, 6, 1, 22),
        endTime: DateTime(2026, 6, 2, 5),
        stageType: 'deep',
        sourcePackage: 'pkg.a',
      ),
    );
    await db.close();

    // 同じ鍵ストア・同じパスで再初期化 → 復号して読めること。
    await db.initialize(path: tempDir.path, keyStore: keyStore);

    expect(db.sleepBox.get('persist')!.stageType, 'deep');
    // 鍵は初回生成の 1 回のみ書き込まれている。
    expect(keyStore.writeCount, 1);
  });
}
