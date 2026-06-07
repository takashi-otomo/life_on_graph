import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/repositories/health_client.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

import '../helpers/fake_activity_recognition_permission.dart';
import '../helpers/fake_health_client.dart';
import '../helpers/fake_secure_key_store.dart';

void main() {
  late Directory tempDir;
  late DatabaseManager db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_del_test');
    db = DatabaseManager();
    await db.initialize(path: tempDir.path, keyStore: FakeSecureKeyStore());
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  HealthSyncRepositoryImpl repo(FakeHealthClient client) =>
      HealthSyncRepositoryImpl(
        healthClient: client,
        databaseManager: db,
        activityPermission: FakeActivityRecognitionPermission(),
      );

  HealthDataPoint sleepPt(String uuid) => fakePoint(
    uuid: uuid,
    type: HealthDataType.SLEEP_DEEP,
    from: DateTime(2026, 6, 6, 23),
    to: DateTime(2026, 6, 7, 1),
  );

  group('#64 削除のローカル反映 (Changes API)', () {
    test('初回同期で変更トークンを確立する', () async {
      final client = FakeHealthClient(authorized: true)..changesToken = 'tok-1';
      await repo(client).sync(force: true);
      expect(client.getChangesTokenCalls, greaterThan(0));
      expect(
        db.metadataBox.get(HealthSyncRepositoryImpl.changesTokenKey),
        'tok-1',
      );
    });

    test('既存インストール(last_sync有・トークン無)でもトークンを確立する', () async {
      final client = FakeHealthClient(authorized: true)..changesToken = 'tok-x';
      // アップグレードを模擬: last_sync は有るがトークンが無い。
      await db.metadataBox.put(
        HealthSyncRepositoryImpl.lastSyncTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      // force なし → 差分極小でフェッチはスキップされ得るが、トークンは確立される。
      await repo(client).sync();
      expect(
        db.metadataBox.get(HealthSyncRepositoryImpl.changesTokenKey),
        'tok-x',
      );
    });

    test('リモート削除されたレコードをローカルから除去する', () async {
      final client = FakeHealthClient(
        authorized: true,
        dataByType: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.SLEEP_DEEP: <HealthDataPoint>[
            sleepPt('u-del'),
            sleepPt('u-keep'),
          ],
        },
      )..changesToken = 'tok-1';
      final r = repo(client);

      await r.sync(force: true); // 取得・保存 + トークン確立。
      expect(db.sleepBox.values.length, 2);

      // u-del が HC で削除された変更を返す。
      client.changesQueue.add(
        const HealthChangesResult(
          deletedUuids: <String>['u-del'],
          nextToken: 'tok-2',
          hasMore: false,
          expired: false,
        ),
      );
      // 通常の増分同期(差分極小でフェッチはスキップ)でも削除は反映される。
      await r.sync();

      final List<String> remaining = db.sleepBox.values
          .map((r) => r.uuid)
          .toList();
      expect(remaining, contains('u-keep'));
      expect(remaining, isNot(contains('u-del')));
      expect(
        db.metadataBox.get(HealthSyncRepositoryImpl.changesTokenKey),
        'tok-2',
      );
    });

    test('トークン期限切れでローカルを消去しフル再取得で整合する', () async {
      final client = FakeHealthClient(
        authorized: true,
        dataByType: <HealthDataType, List<HealthDataPoint>>{
          HealthDataType.SLEEP_DEEP: <HealthDataPoint>[
            sleepPt('u1'),
            sleepPt('u2'),
          ],
        },
      )..changesToken = 'tok-1';
      final r = repo(client);

      await r.sync(force: true);
      expect(db.sleepBox.values.length, 2);

      // HC 側で u2 を削除し、トークンは期限切れを返す。
      client.setData(HealthDataType.SLEEP_DEEP, <HealthDataPoint>[
        sleepPt('u1'),
      ]);
      client.changesQueue.add(
        const HealthChangesResult(
          deletedUuids: <String>[],
          nextToken: '',
          hasMore: false,
          expired: true,
        ),
      );
      await r.sync(force: true);

      // 期限切れ → ローカル消去 → 同期内フル再取得で u1 のみ残る。
      final List<String> remaining = db.sleepBox.values
          .map((r) => r.uuid)
          .toList();
      expect(remaining, <String>['u1']);
      // トークンは再確立される。
      expect(
        db.metadataBox.get(HealthSyncRepositoryImpl.changesTokenKey),
        isNotNull,
      );
    });
  });
}
