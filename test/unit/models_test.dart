import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
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
