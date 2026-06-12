import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/models/sleep_record_model.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

import '../helpers/fake_activity_recognition_permission.dart';
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

  HealthSyncRepositoryImpl repo(
    FakeHealthClient client, {
    FakeActivityRecognitionPermission? activity,
  }) => HealthSyncRepositoryImpl(
    healthClient: client,
    databaseManager: db,
    activityPermission: activity ?? FakeActivityRecognitionPermission(),
  );

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

    test('差分は last_sync_time を維持し移動 30 日床にクランプしない (P1-1)', () async {
      // 付与後に書かれたデータは 30 日超でも読めるため、60 日前の last_sync_time でも
      // クランプせずそのまま開始に用いる (恒久的なデータ欠損を防ぐ)。
      final now = DateTime(2026, 6, 5, 12);
      final old = now.subtract(const Duration(days: 60));
      await db.metadataBox.put(
        HealthSyncRepositoryImpl.lastSyncTimeKey,
        old.millisecondsSinceEpoch,
      );
      final window = repo(FakeHealthClient()).computeSyncWindow(now);

      expect(window.start, old);
    });

    test('初回・履歴権限なしのバックフィルは 30 日に制限される', () {
      final now = DateTime(2026, 6, 5, 12);
      // last_sync_time 未設定 (== 0) の初回。
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

    test('取得は算出ウィンドウをチャンク分割して全期間を被覆する', () async {
      final client = FakeHealthClient();
      final now = DateTime(2026, 6, 5, 12);
      await repo(client).sync(now: now);

      expect(client.queriedWindows, isNotEmpty);
      final DateTime windowStart = now.subtract(const Duration(days: 30));
      // 先頭チャンクは window 開始から、末尾チャンクは now まで。
      expect(client.queriedWindows.first.start, windowStart);
      expect(client.queriedWindows.last.end, now);
      for (final w in client.queriedWindows) {
        // 各チャンクは window 内に収まり、最大 syncChunkDays 日。
        expect(w.start.isBefore(windowStart), isFalse);
        expect(w.end.isAfter(now), isFalse);
        expect(
          w.end.difference(w.start).inDays,
          lessThanOrEqualTo(HealthSyncRepositoryImpl.syncChunkDays),
        );
      }
    });

    test('同期ウィンドウは syncChunkDays ごとに分割して取得する (メモリ抑制)', () async {
      final now = DateTime(2026, 6, 5, 12);
      final client = FakeHealthClient(historyAlreadyAuthorized: true);
      final r = repo(client);
      await r.ensureHistoryPermission(); // 365 日バックフィルにする
      await r.sync(now: now);

      // 365 日 / 14 日 = 27 チャンク × 3 種別。
      final int chunks = (365 / HealthSyncRepositoryImpl.syncChunkDays).ceil();
      expect(client.queriedWindows.length, chunks * 3);
    });

    test('onProgress が種別ごとに進捗 (件数・チャンク) を通知する', () async {
      final now = DateTime(2026, 6, 5, 12);
      final client = FakeHealthClient(
        dataByType: {
          HealthDataType.SLEEP_DEEP: [
            fakePoint(
              uuid: 's1',
              type: HealthDataType.SLEEP_DEEP,
              from: now.subtract(const Duration(days: 1)),
              to: now.subtract(const Duration(days: 1, hours: -1)),
            ),
          ],
          HealthDataType.STEPS: [
            fakePoint(
              uuid: 'st1',
              type: HealthDataType.STEPS,
              from: now.subtract(const Duration(days: 1)),
              to: now.subtract(const Duration(days: 1, minutes: -10)),
              value: 100,
            ),
          ],
          HealthDataType.HEART_RATE: [
            fakePoint(
              uuid: 'h1',
              type: HealthDataType.HEART_RATE,
              from: now.subtract(const Duration(days: 1)),
              to: now.subtract(const Duration(days: 1)),
              value: 60,
            ),
          ],
        },
      );
      final List<SyncProgress> events = <SyncProgress>[];
      await repo(client).sync(now: now, onProgress: events.add);

      expect(events, isNotEmpty);
      // 3 種別すべてが通知される。
      expect(events.map((e) => e.phase).toSet(), <SyncPhase>{
        SyncPhase.sleep,
        SyncPhase.steps,
        SyncPhase.heartRate,
      });
      // 進捗率は 0..1、チャンク数は正、件数は非負。
      for (final SyncProgress e in events) {
        expect(e.fraction, inInclusiveRange(0.0, 1.0));
        expect(e.chunkCount, greaterThan(0));
        expect(e.savedInPhase, greaterThanOrEqualTo(0));
        expect(e.phaseCount, 3);
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

    test('初回・履歴権限ありでバックフィルが 365 日へ拡張される (P1-2)', () async {
      // 新規ユーザーが初回同期前に履歴権限を許可したケース (last_sync_time == 0)。
      final now = DateTime(2026, 6, 5, 12);
      final client = FakeHealthClient(historyAlreadyAuthorized: true);
      final r = repo(client);

      await r.ensureHistoryPermission();
      final window = r.computeSyncWindow(now);

      expect(window.start, now.subtract(const Duration(days: 365)));
    });

    test('初回・履歴権限拒否時は 30 日に制限され例外が出ない', () async {
      final now = DateTime(2026, 6, 5, 12);
      final client = FakeHealthClient(
        historyAlreadyAuthorized: false,
        historyRequestResult: false,
      );
      final r = repo(client);

      expect(await r.ensureHistoryPermission(), isFalse);
      final window = r.computeSyncWindow(now);
      expect(window.start, now.subtract(const Duration(days: 30)));
    });

    test('履歴権限ありでも差分 (last_sync_time>0) は保存済み値をそのまま使う', () async {
      final now = DateTime(2026, 6, 5, 12);
      final last = now.subtract(const Duration(days: 60));
      await setLastSync(last);
      final client = FakeHealthClient(historyAlreadyAuthorized: true);
      final r = repo(client);

      await r.ensureHistoryPermission();
      final window = r.computeSyncWindow(now);

      expect(window.start, last);
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
      // 差分窓は過去を再取得しないため、再バックフィル相当として last_sync をクリアし
      // 同一 uuid の再取得・上書きを検証する。
      db.metadataBox.delete(HealthSyncRepositoryImpl.lastSyncTimeKey);
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
      db.metadataBox.delete(HealthSyncRepositoryImpl.lastSyncTimeKey);
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
      db.metadataBox.delete(HealthSyncRepositoryImpl.lastSyncTimeKey);
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

  group('M4 getCleanedSleepSegmentsForDay (読み出し経路統合)', () {
    const String shealth = 'com.sec.android.app.shealth';

    test('保存レコードにクレンジングパイプラインを適用して返す', () async {
      final day = DateTime(2026, 6, 5);
      final noon = DateTime(2026, 6, 5, 12);
      // 正午枠を前方にまたぐ deep (11:30→12:40)
      final crossing = SleepRecordModel(
        uuid: 'r1',
        startTime: noon.subtract(const Duration(minutes: 30)),
        endTime: noon.add(const Duration(minutes: 40)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      // 隣接 deep (12:40→12:50, ギャップ0) → 結合対象
      final adjacent = SleepRecordModel(
        uuid: 'r2',
        startTime: noon.add(const Duration(minutes: 40)),
        endTime: noon.add(const Duration(minutes: 50)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      await db.sleepBox.put(crossing.hiveKey, crossing);
      await db.sleepBox.put(adjacent.hiveKey, adjacent);

      final result = repo(
        FakeHealthClient(),
      ).getCleanedSleepSegmentsForDay(day);

      expect(result.length, 1);
      // 前方クリップで開始は正午、隣接 deep は結合され 12:50 まで。
      expect(result.single.startTime, noon);
      expect(result.single.endTime, noon.add(const Duration(minutes: 50)));
      expect(result.single.stageType, 'deep');
    });

    test('表示枠外のレコードは結果に含まれない', () async {
      final day = DateTime(2026, 6, 5);
      // 前日 10:00 (正午枠外)
      final outside = SleepRecordModel(
        uuid: 'r3',
        startTime: DateTime(2026, 6, 5, 10),
        endTime: DateTime(2026, 6, 5, 11),
        stageType: 'light',
        sourcePackage: shealth,
      );
      await db.sleepBox.put(outside.hiveKey, outside);

      expect(
        repo(FakeHealthClient()).getCleanedSleepSegmentsForDay(day),
        isEmpty,
      );
    });

    test('別日の上位ソースが当日窓の下位ソースデータを消さない (cross-day prefilter)', () async {
      final day = DateTime(2026, 6, 5);
      final noon = DateTime(2026, 6, 5, 12);
      // 別日 (6/4 深夜) の Samsung レコード — 当日窓と交差しない
      final otherDay = SleepRecordModel(
        uuid: 'o1',
        startTime: DateTime(2026, 6, 4, 2),
        endTime: DateTime(2026, 6, 4, 3),
        stageType: 'deep',
        sourcePackage: shealth, // 上位
      );
      // 当日窓内の Fitbit (下位) レコード — 別日の Samsung に消されてはならない
      final fitbit = SleepRecordModel(
        uuid: 'f1',
        startTime: noon.add(const Duration(hours: 10)),
        endTime: noon.add(const Duration(hours: 11)),
        stageType: 'light',
        sourcePackage: 'com.fitbit.FitbitMobile',
      );
      await db.sleepBox.put(otherDay.hiveKey, otherDay);
      await db.sleepBox.put(fitbit.hiveKey, fitbit);

      final result = repo(
        FakeHealthClient(),
      ).getCleanedSleepSegmentsForDay(day);

      expect(result.length, 1);
      expect(result.single.sourcePackage, 'com.fitbit.FitbitMobile');
    });
  });

  group('#58 ensureActivityRecognitionPermission', () {
    test('未許可なら request を呼び結果を返す', () async {
      final activity = FakeActivityRecognitionPermission(
        alreadyGranted: false,
        requestResult: true,
      );
      final granted = await repo(
        FakeHealthClient(),
        activity: activity,
      ).ensureActivityRecognitionPermission();

      expect(granted, isTrue);
      expect(activity.requestCount, 1);
    });

    test('既に許可済みなら再要求しない', () async {
      final activity = FakeActivityRecognitionPermission(alreadyGranted: true);
      final granted = await repo(
        FakeHealthClient(),
        activity: activity,
      ).ensureActivityRecognitionPermission();

      expect(granted, isTrue);
      expect(activity.requestCount, 0);
    });

    test('拒否されても例外を出さず false を返す', () async {
      final activity = FakeActivityRecognitionPermission(
        alreadyGranted: false,
        requestResult: false,
      );
      expect(
        await repo(
          FakeHealthClient(),
          activity: activity,
        ).ensureActivityRecognitionPermission(),
        isFalse,
      );
    });

    test('権限 API が例外でも false にフォールバックする', () async {
      final activity = FakeActivityRecognitionPermission(throwOnAccess: true);
      expect(
        await repo(
          FakeHealthClient(),
          activity: activity,
        ).ensureActivityRecognitionPermission(),
        isFalse,
      );
    });
  });
}
