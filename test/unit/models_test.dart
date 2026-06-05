import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/sleep_record_model.dart';
import 'package:life_on_graph/models/steps_record_model.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('log_models_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SleepRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StepsRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HeartRateRecordModelAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('SleepRecordModel が Hive に保存・復元できる', () async {
    final box = await Hive.openBox<SleepRecordModel>('sleep_test');
    final record = SleepRecordModel(
      uuid: 'sleep-1',
      startTime: DateTime(2026, 6, 1, 23, 30),
      endTime: DateTime(2026, 6, 2, 0, 15),
      stageType: 'deep',
      sourcePackage: 'com.example.watch',
    );

    await box.put(record.uuid, record);
    final restored = box.get('sleep-1');

    expect(restored, isNotNull);
    expect(restored!.uuid, 'sleep-1');
    expect(restored.stageType, 'deep');
    expect(restored.startTime, DateTime(2026, 6, 1, 23, 30));
    expect(restored.endTime, DateTime(2026, 6, 2, 0, 15));
    expect(restored.sourcePackage, 'com.example.watch');
  });

  test('StepsRecordModel が Hive に保存・復元できる', () async {
    final box = await Hive.openBox<StepsRecordModel>('steps_test');
    final record = StepsRecordModel(
      uuid: 'steps-1',
      startTime: DateTime(2026, 6, 1, 8),
      endTime: DateTime(2026, 6, 1, 9),
      count: 1234,
      sourcePackage: 'com.example.phone',
    );

    await box.put(record.uuid, record);
    final restored = box.get('steps-1');

    expect(restored!.count, 1234);
    expect(restored.sourcePackage, 'com.example.phone');
  });

  group('hiveKey 複合キー (Health Connect の親 UUID 共有対策)', () {
    test('同一セッション(同一uuid)の異なる睡眠ステージは別キーになる', () {
      final session = 'session-1';
      final deep = SleepRecordModel(
        uuid: session,
        startTime: DateTime(2026, 6, 1, 23),
        endTime: DateTime(2026, 6, 1, 23, 40),
        stageType: 'deep',
        sourcePackage: 'pkg',
      );
      final rem = SleepRecordModel(
        uuid: session,
        startTime: DateTime(2026, 6, 1, 23, 40),
        endTime: DateTime(2026, 6, 2, 0, 20),
        stageType: 'rem',
        sourcePackage: 'pkg',
      );

      // 親 UUID が同じでもステージ・時刻が異なれば別キー → 1件に潰れない。
      expect(deep.hiveKey, isNot(rem.hiveKey));
    });

    test('同一の睡眠セグメントを再生成すると同じキー (重複排除が成立)', () {
      SleepRecordModel seg() => SleepRecordModel(
        uuid: 'session-1',
        startTime: DateTime(2026, 6, 1, 23),
        endTime: DateTime(2026, 6, 1, 23, 40),
        stageType: 'deep',
        sourcePackage: 'pkg',
      );
      expect(seg().hiveKey, seg().hiveKey);
    });

    test('同一シリーズ(同一uuid)の異なる心拍サンプルは別キーになる', () {
      final s1 = HeartRateRecordModel(
        uuid: 'series-1',
        startTime: DateTime(2026, 6, 1, 3, 0, 0),
        endTime: DateTime(2026, 6, 1, 3, 0, 0),
        beatsPerMinute: 58,
        sourcePackage: 'pkg',
      );
      final s2 = HeartRateRecordModel(
        uuid: 'series-1',
        startTime: DateTime(2026, 6, 1, 3, 0, 30),
        endTime: DateTime(2026, 6, 1, 3, 0, 30),
        beatsPerMinute: 61,
        sourcePackage: 'pkg',
      );
      expect(s1.hiveKey, isNot(s2.hiveKey));
    });
  });

  test('HeartRateRecordModel が Hive に保存・復元できる (瞬時値)', () async {
    final box = await Hive.openBox<HeartRateRecordModel>('hr_test');
    final ts = DateTime(2026, 6, 1, 3, 15, 30);
    final record = HeartRateRecordModel(
      uuid: 'hr-1',
      startTime: ts,
      endTime: ts,
      beatsPerMinute: 58,
      sourcePackage: 'com.example.watch',
    );

    await box.put(record.uuid, record);
    final restored = box.get('hr-1');

    expect(restored!.beatsPerMinute, 58);
    expect(restored.startTime, restored.endTime);
  });
}
