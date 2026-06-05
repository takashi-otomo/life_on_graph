import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

import '../helpers/fake_health_client.dart';
import '../helpers/fake_secure_key_store.dart';

void main() {
  late Directory tempDir;
  late DatabaseManager db;
  late FakeSecureKeyStore keyStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_sync_test');
    keyStore = FakeSecureKeyStore();
    db = DatabaseManager();
    await db.initialize(path: tempDir.path, keyStore: keyStore);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  HealthSyncRepositoryImpl repo(FakeHealthClient client) =>
      HealthSyncRepositoryImpl(healthClient: client, databaseManager: db);

  group('T-301 configure / 権限要求', () {
    test('configure はヘルスクライアントの configure を呼ぶ', () async {
      final client = FakeHealthClient();
      await repo(client).configure();
      expect(client.configureCalled, isTrue);
    });

    test('requestPermissions は睡眠・歩数・心拍の READ のみを要求する', () async {
      final client = FakeHealthClient(authorized: true);
      final granted = await repo(client).requestPermissions();

      expect(granted, isTrue);
      final types = client.lastRequestedTypes!;
      // 対象は睡眠ステージ + 歩数 + 心拍に限定。
      expect(types, contains(HealthDataType.STEPS));
      expect(types, contains(HealthDataType.HEART_RATE));
      expect(types, contains(HealthDataType.SLEEP_DEEP));
      // 全権限が READ であり WRITE を一切含まない。
      expect(client.lastRequestedPermissions!.length, types.length);
      expect(
        client.lastRequestedPermissions!.every(
          (p) => p == HealthDataAccess.READ,
        ),
        isTrue,
      );
      // 対象外タイプ・SLEEP_SESSION エンベロープを含まない。
      expect(types.contains(HealthDataType.SLEEP_SESSION), isFalse);
      expect(types.contains(HealthDataType.WEIGHT), isFalse);
    });

    test('権限拒否でも例外を出さず false を返す', () async {
      final client = FakeHealthClient(authorized: false);
      expect(await repo(client).requestPermissions(), isFalse);
    });
  });

  group('T-302 同期ウィンドウ算出', () {
    test('初回 (last_sync_time == 0) は開始が now - 30 日', () {
      final now = DateTime(2026, 6, 5, 12);
      final window = repo(FakeHealthClient()).computeSyncWindow(now);

      expect(window.end, now);
      expect(window.start, now.subtract(const Duration(days: 30)));
    });

    test('2 回目以降は保存済み last_sync_time を開始に用いる', () async {
      final last = DateTime(2026, 6, 4, 9);
      await db.metadataBox.put(
        HealthSyncRepositoryImpl.lastSyncTimeKey,
        last.millisecondsSinceEpoch,
      );
      final now = DateTime(2026, 6, 5, 12);
      final window = repo(FakeHealthClient()).computeSyncWindow(now);

      expect(window.start, last);
      expect(window.end, now);
    });

    test('履歴権限なしではバックフィルが 30 日を超えない', () async {
      // 60 日前の last_sync_time でも 30 日にクランプされる。
      final now = DateTime(2026, 6, 5, 12);
      final old = now.subtract(const Duration(days: 60));
      await db.metadataBox.put(
        HealthSyncRepositoryImpl.lastSyncTimeKey,
        old.millisecondsSinceEpoch,
      );
      final window = repo(FakeHealthClient()).computeSyncWindow(now);

      expect(window.start, now.subtract(const Duration(days: 30)));
    });
  });

  group('T-303 差分取得・UUID バッチ保存', () {
    test('睡眠ステージを正規化し sourcePackage を保持して保存する', () async {
      final start = DateTime(2026, 6, 4, 23);
      final client = FakeHealthClient(
        dataByType: {
          HealthDataType.SLEEP_DEEP: [
            fakePoint(
              uuid: 'sess-1',
              type: HealthDataType.SLEEP_DEEP,
              from: start,
              to: start.add(const Duration(minutes: 40)),
              sourceName: 'com.example.health',
            ),
          ],
          HealthDataType.SLEEP_REM: [
            fakePoint(
              uuid: 'sess-1',
              type: HealthDataType.SLEEP_REM,
              from: start.add(const Duration(minutes: 40)),
              to: start.add(const Duration(minutes: 80)),
              sourceName: 'com.example.health',
            ),
          ],
        },
      );

      final outcome = await repo(client).sync(now: DateTime(2026, 6, 5, 12));

      // 同一 UUID でも 2 ステージとも保持される。
      expect(db.sleepBox.length, 2);
      expect(outcome.savedCounts['sleep'], 2);
      final deep = db.sleepBox.values.firstWhere((r) => r.stageType == 'deep');
      expect(deep.sourcePackage, 'com.example.health');
    });

    test('歩数・心拍を value からマッピングして保存する', () async {
      final t = DateTime(2026, 6, 5, 8);
      final client = FakeHealthClient(
        dataByType: {
          HealthDataType.STEPS: [
            fakePoint(
              uuid: 'step-1',
              type: HealthDataType.STEPS,
              from: t,
              to: t.add(const Duration(hours: 1)),
              value: 512,
            ),
          ],
          HealthDataType.HEART_RATE: [
            fakePoint(
              uuid: 'hr-1',
              type: HealthDataType.HEART_RATE,
              from: t,
              to: t,
              value: 62,
            ),
          ],
        },
      );

      await repo(client).sync(now: DateTime(2026, 6, 5, 12));

      expect(db.stepsBox.values.single.count, 512);
      expect(db.heartRateBox.values.single.beatsPerMinute, 62);
    });

    test('getHealthDataFromTypes へ算出ウィンドウの start/end を渡す', () async {
      final client = FakeHealthClient();
      final now = DateTime(2026, 6, 5, 12);
      await repo(client).sync(now: now);

      expect(client.queriedWindows, isNotEmpty);
      for (final w in client.queriedWindows) {
        expect(w.end, now);
        expect(w.start, now.subtract(const Duration(days: 30)));
      }
    });

    test('同一 uuid セグメントの再同期は重複せず上書きされる', () async {
      final start = DateTime(2026, 6, 4, 23);
      HealthDataPoint deep() => fakePoint(
        uuid: 'sess-dup',
        type: HealthDataType.SLEEP_DEEP,
        from: start,
        to: start.add(const Duration(minutes: 40)),
      );
      final client = FakeHealthClient(
        dataByType: {
          HealthDataType.SLEEP_DEEP: [deep()],
        },
      );
      final r = repo(client);

      await r.sync(now: DateTime(2026, 6, 5, 12));
      await r.sync(now: DateTime(2026, 6, 5, 13));

      expect(db.sleepBox.length, 1);
    });

    test('成功時は last_sync_time が now に更新される', () async {
      final now = DateTime(2026, 6, 5, 12);
      await repo(FakeHealthClient()).sync(now: now);

      expect(
        db.metadataBox.get(HealthSyncRepositoryImpl.lastSyncTimeKey),
        now.millisecondsSinceEpoch,
      );
    });

    test('異なる uuid のレコードは別々に共存して保存される', () async {
      final t = DateTime(2026, 6, 5, 8);
      final client = FakeHealthClient(
        dataByType: {
          HealthDataType.STEPS: [
            fakePoint(
              uuid: 'step-a',
              type: HealthDataType.STEPS,
              from: t,
              to: t.add(const Duration(hours: 1)),
              value: 100,
            ),
            fakePoint(
              uuid: 'step-b',
              type: HealthDataType.STEPS,
              from: t.add(const Duration(hours: 1)),
              to: t.add(const Duration(hours: 2)),
              value: 200,
            ),
          ],
        },
      );

      await repo(client).sync(now: DateTime(2026, 6, 5, 12));

      expect(db.stepsBox.length, 2);
    });

    test('1 種別の取得失敗が他種別の保存を阻害しない', () async {
      final t = DateTime(2026, 6, 5, 8);
      final client = FakeHealthClient(
        throwOnTypes: {HealthDataType.STEPS},
        dataByType: {
          HealthDataType.HEART_RATE: [
            fakePoint(
              uuid: 'hr-x',
              type: HealthDataType.HEART_RATE,
              from: t,
              to: t,
              value: 70,
            ),
          ],
        },
      );

      final outcome = await repo(client).sync(now: DateTime(2026, 6, 5, 12));

      // 歩数は失敗するが心拍は保存される。
      expect(outcome.failedTypes, contains('steps'));
      expect(db.heartRateBox.length, 1);
      expect(outcome.savedCounts['heart_rate'], 1);
      // 失敗を含むため last_sync_time は前進しない (再取得に委ねる)。
      expect(
        db.metadataBox.get(
          HealthSyncRepositoryImpl.lastSyncTimeKey,
          defaultValue: 0,
        ),
        0,
      );
    });
  });

  group('T-304 履歴権限フローとフォールバック', () {
    Future<void> setLastSync(DateTime t) => db.metadataBox.put(
      HealthSyncRepositoryImpl.lastSyncTimeKey,
      t.millisecondsSinceEpoch,
    );

    test('未付与時は requestHealthDataHistoryAuthorization が呼ばれる', () async {
      final client = FakeHealthClient(
        historyAlreadyAuthorized: false,
        historyRequestResult: true,
      );
      final r = repo(client);

      expect(await r.ensureHistoryPermission(), isTrue);
      expect(client.historyRequestCount, 1);
      expect(r.isHistoryAuthorized, isTrue);
    });

    test('既に許可済みなら権限ダイアログを再表示しない', () async {
      final client = FakeHealthClient(historyAlreadyAuthorized: true);
      final r = repo(client);

      expect(await r.ensureHistoryPermission(), isTrue);
      // 追加要求は呼ばれない。
      expect(client.historyRequestCount, 0);
    });

    test('履歴権限ありではバックフィルが 30 日以前へ拡張される', () async {
      final now = DateTime(2026, 6, 5, 12);
      final old = now.subtract(const Duration(days: 60));
      await setLastSync(old);
      final client = FakeHealthClient(historyAlreadyAuthorized: true);
      final r = repo(client);

      await r.ensureHistoryPermission();
      final window = r.computeSyncWindow(now);

      // クランプされず 60 日前の last_sync_time から取得する。
      expect(window.start, old);
    });

    test('履歴権限拒否時は 30 日に制限され例外が出ない', () async {
      final now = DateTime(2026, 6, 5, 12);
      final old = now.subtract(const Duration(days: 60));
      await setLastSync(old);
      final client = FakeHealthClient(
        historyAlreadyAuthorized: false,
        historyRequestResult: false,
      );
      final r = repo(client);

      expect(await r.ensureHistoryPermission(), isFalse);
      final window = r.computeSyncWindow(now);
      expect(window.start, now.subtract(const Duration(days: 30)));
    });

    test('履歴権限 API が例外でも 30 日フォールバックする', () async {
      final client = FakeHealthClient(throwOnHistory: true);
      final r = repo(client);

      expect(await r.ensureHistoryPermission(), isFalse);
      expect(r.isHistoryAuthorized, isFalse);
    });
  });

  group('T-305 差分極小時のクエリスキップ', () {
    Future<void> setLastSync(DateTime t) => db.metadataBox.put(
      HealthSyncRepositoryImpl.lastSyncTimeKey,
      t.millisecondsSinceEpoch,
    );

    test('5 分未満の経過では getHealthDataFromTypes が呼ばれずスキップする', () async {
      final now = DateTime(2026, 6, 5, 12);
      await setLastSync(now.subtract(const Duration(minutes: 4)));
      final client = FakeHealthClient();

      final outcome = await repo(client).sync(now: now);

      expect(outcome.skipped, isTrue);
      expect(client.queriedWindows, isEmpty);
    });

    test('スキップ時は last_sync_time が更新されない', () async {
      final now = DateTime(2026, 6, 5, 12);
      final last = now.subtract(const Duration(minutes: 4));
      await setLastSync(last);

      await repo(FakeHealthClient()).sync(now: now);

      expect(
        db.metadataBox.get(HealthSyncRepositoryImpl.lastSyncTimeKey),
        last.millisecondsSinceEpoch,
      );
    });

    test('境界 5 分ちょうどは通常通り差分取得が走る', () async {
      final now = DateTime(2026, 6, 5, 12);
      await setLastSync(now.subtract(const Duration(minutes: 5)));
      final client = FakeHealthClient();

      final outcome = await repo(client).sync(now: now);

      expect(outcome.skipped, isFalse);
      expect(client.queriedWindows, isNotEmpty);
    });

    test('初回 (last_sync_time == 0) はスキップされずバックフィルする', () async {
      final client = FakeHealthClient();
      final outcome = await repo(client).sync(now: DateTime(2026, 6, 5, 12));

      expect(outcome.skipped, isFalse);
      expect(client.queriedWindows, isNotEmpty);
    });

    test('force 指定時は閾値未満でも強制同期する', () async {
      final now = DateTime(2026, 6, 5, 12);
      await setLastSync(now.subtract(const Duration(minutes: 1)));
      final client = FakeHealthClient();

      final outcome = await repo(client).sync(now: now, force: true);

      expect(outcome.skipped, isFalse);
      expect(client.queriedWindows, isNotEmpty);
    });
  });

  group('T-306 重複排除 (UUID 上書き) 各ボックス', () {
    HealthDataPoint sleepDeep(DateTime from, DateTime to, {String s = 'pkg'}) =>
        fakePoint(
          uuid: 'sleep-dup',
          type: HealthDataType.SLEEP_DEEP,
          from: from,
          to: to,
          sourceName: s,
        );

    test('睡眠: 同一 uuid・同一区間の更新は最新 sourcePackage で上書きされる', () async {
      final from = DateTime(2026, 6, 4, 23);
      final to = from.add(const Duration(minutes: 40));
      final r1 = repo(
        FakeHealthClient(
          dataByType: {
            HealthDataType.SLEEP_DEEP: [sleepDeep(from, to, s: 'old.pkg')],
          },
        ),
      );
      await r1.sync(now: DateTime(2026, 6, 5, 12));

      // 同一 hiveKey (uuid:stage:start:end) で sourcePackage のみ更新。
      final r2 = repo(
        FakeHealthClient(
          dataByType: {
            HealthDataType.SLEEP_DEEP: [sleepDeep(from, to, s: 'new.pkg')],
          },
        ),
      );
      await r2.sync(now: DateTime(2026, 6, 5, 13));

      expect(db.sleepBox.length, 1);
      expect(db.sleepBox.values.single.sourcePackage, 'new.pkg');
    });

    test('歩数: 同一 uuid・同一区間の更新は最新 count に上書きされる', () async {
      final t = DateTime(2026, 6, 5, 8);
      final end = t.add(const Duration(hours: 1));
      HealthDataPoint step(num v) => fakePoint(
        uuid: 'steps-dup',
        type: HealthDataType.STEPS,
        from: t,
        to: end,
        value: v,
      );

      await repo(
        FakeHealthClient(
          dataByType: {
            HealthDataType.STEPS: [step(100)],
          },
        ),
      ).sync(now: DateTime(2026, 6, 5, 12));
      await repo(
        FakeHealthClient(
          dataByType: {
            HealthDataType.STEPS: [step(250)],
          },
        ),
      ).sync(now: DateTime(2026, 6, 5, 13));

      expect(db.stepsBox.length, 1);
      expect(db.stepsBox.values.single.count, 250);
    });

    test('心拍: 同一 uuid・同一時刻の更新は最新 bpm に上書きされる', () async {
      final t = DateTime(2026, 6, 5, 3);
      HealthDataPoint hr(num v) => fakePoint(
        uuid: 'hr-dup',
        type: HealthDataType.HEART_RATE,
        from: t,
        to: t,
        value: v,
      );

      await repo(
        FakeHealthClient(
          dataByType: {
            HealthDataType.HEART_RATE: [hr(58)],
          },
        ),
      ).sync(now: DateTime(2026, 6, 5, 12));
      await repo(
        FakeHealthClient(
          dataByType: {
            HealthDataType.HEART_RATE: [hr(64)],
          },
        ),
      ).sync(now: DateTime(2026, 6, 5, 13));

      expect(db.heartRateBox.length, 1);
      expect(db.heartRateBox.values.single.beatsPerMinute, 64);
    });
  });
}
