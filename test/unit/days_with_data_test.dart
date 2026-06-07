import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/models/sleep_record_model.dart';
import 'package:life_on_graph/models/steps_record_model.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

import '../helpers/fake_activity_recognition_permission.dart';
import '../helpers/fake_health_client.dart';
import '../helpers/fake_secure_key_store.dart';

void main() {
  late Directory tempDir;
  late DatabaseManager db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('log_days_test');
    db = DatabaseManager();
    await db.initialize(path: tempDir.path, keyStore: FakeSecureKeyStore());
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  StepsRecordModel steps(String uuid, DateTime start) => StepsRecordModel(
    uuid: uuid,
    startTime: start,
    endTime: start.add(const Duration(minutes: 30)),
    count: 100,
    sourcePackage: 'test',
  );

  test('#104 範囲内のデータがある日のみ返す', () async {
    final repo = HealthSyncRepositoryImpl(
      healthClient: FakeHealthClient(),
      databaseManager: db,
      activityPermission: FakeActivityRecognitionPermission(),
    );
    final s1 = steps('a', DateTime(2026, 6, 3, 8));
    final s2 = steps('b', DateTime(2026, 6, 3, 20)); // 同じ日 (重複しない)
    final s3 = steps('c', DateTime(2026, 6, 10, 9));
    final s4 = steps('d', DateTime(2026, 7, 1, 9)); // 範囲外
    for (final r in <StepsRecordModel>[s1, s2, s3, s4]) {
      await db.stepsBox.put(r.hiveKey, r);
    }

    final Set<DateTime> days = repo.daysWithData(
      DateTime(2026, 6, 1),
      DateTime(2026, 7, 1),
    );

    expect(days, contains(DateTime(2026, 6, 3)));
    expect(days, contains(DateTime(2026, 6, 10)));
    expect(days, isNot(contains(DateTime(2026, 7, 1))));
    expect(days.length, 2); // 6/3 は 2 レコードでも 1 日。
  });

  test('#104 睡眠は表示枠(正午〜翌正午)で日に帰属する', () async {
    final repo = HealthSyncRepositoryImpl(
      healthClient: FakeHealthClient(),
      databaseManager: db,
      activityPermission: FakeActivityRecognitionPermission(),
    );
    // 6/6 00:30〜06:00 の睡眠は枠 [6/5 12:00, 6/6 12:00) に属する → 6/5 に出る。
    final sleep = SleepRecordModel(
      uuid: 's1',
      startTime: DateTime(2026, 6, 6, 0, 30),
      endTime: DateTime(2026, 6, 6, 6),
      stageType: 'deep',
      sourcePackage: 'test',
    );
    await db.sleepBox.put(sleep.hiveKey, sleep);

    final Set<DateTime> days = repo.daysWithData(
      DateTime(2026, 6, 1),
      DateTime(2026, 7, 1),
    );

    expect(days, contains(DateTime(2026, 6, 5)));
    expect(days, isNot(contains(DateTime(2026, 6, 6))));
  });
}
