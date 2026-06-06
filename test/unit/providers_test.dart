import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';
import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/models/steps_record_model.dart';
import 'package:life_on_graph/providers/data_providers.dart';
import 'package:life_on_graph/providers/repository_providers.dart';
import 'package:life_on_graph/providers/sync_notifier.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

import '../helpers/fake_health_sync_repository.dart';

ProviderContainer makeContainer(FakeHealthSyncRepository repo) {
  final container = ProviderContainer(
    overrides: [healthSyncRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

SleepSegment sampleSegment() => SleepSegment(
  startTime: DateTime(2026, 6, 6, 0),
  endTime: DateTime(2026, 6, 6, 1),
  stageType: 'deep',
  sourcePackage: 'pkg',
);

void main() {
  group('T-501 repository / databaseManager provider', () {
    test('healthSyncRepositoryProvider を watch すると Repository が取得できる', () {
      final repo = FakeHealthSyncRepository();
      final container = makeContainer(repo);

      expect(
        container.read(healthSyncRepositoryProvider),
        isA<HealthSyncRepository>(),
      );
      expect(container.read(healthSyncRepositoryProvider), same(repo));
    });

    test('databaseManagerProvider は override で初期化済みインスタンスを供給できる', () {
      final dm = DatabaseManager();
      final container = ProviderContainer(
        overrides: [databaseManagerProvider.overrideWithValue(dm)],
      );
      addTearDown(container.dispose);

      expect(container.read(databaseManagerProvider), same(dm));
    });

    test('databaseManagerProvider は未注入だと利用できない (要 override)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // override 無しでは build が UnimplementedError を投げ error state になる。
      expect(
        () => container.read(databaseManagerProvider),
        throwsA(predicate((e) => e.toString().contains('error state'))),
      );
    });
  });

  group('T-502 syncNotifierProvider', () {
    test('初期状態は idle', () {
      final container = makeContainer(FakeHealthSyncRepository());
      expect(container.read(syncNotifierProvider), isA<SyncIdle>());
    });

    test('同期開始で syncing、正常完了で done に遷移する', () async {
      final container = makeContainer(FakeHealthSyncRepository());
      final states = <SyncState>[];
      container.listen(syncNotifierProvider, (_, next) => states.add(next));

      final future = container.read(syncNotifierProvider.notifier).sync();
      // sync() 開始直後は syncing。
      expect(container.read(syncNotifierProvider), isA<SyncInProgress>());
      await future;
      expect(container.read(syncNotifierProvider), isA<SyncDone>());
      expect(states.any((s) => s is SyncInProgress), isTrue);
      expect(states.last, isA<SyncDone>());
    });

    test('例外発生時は error へ遷移しエラー情報を保持する', () async {
      final repo = FakeHealthSyncRepository(throwOnSync: true);
      final container = makeContainer(repo);

      await container.read(syncNotifierProvider.notifier).sync();

      final state = container.read(syncNotifierProvider);
      expect(state, isA<SyncError>());
      expect((state as SyncError).error, isA<StateError>());
    });

    test('同期は healthSyncRepositoryProvider 経由で呼ばれる', () async {
      final repo = FakeHealthSyncRepository();
      final container = makeContainer(repo);

      await container.read(syncNotifierProvider.notifier).sync();

      expect(repo.syncCalls, 1);
    });

    test(
      'sync は configure / requestPermissions / ensureHistory を前置する (P1-b)',
      () async {
        final repo = FakeHealthSyncRepository();
        final container = makeContainer(repo);

        await container.read(syncNotifierProvider.notifier).sync();

        expect(repo.configureCalled, isTrue);
        expect(repo.requestPermissionsCalled, isTrue);
        expect(repo.ensureHistoryCalled, isTrue);
      },
    );

    test('権限拒否時は SyncError(権限例外) となり sync は呼ばれない (P1-b)', () async {
      final repo = FakeHealthSyncRepository(permissionsGranted: false);
      final container = makeContainer(repo);

      await container.read(syncNotifierProvider.notifier).sync();

      final state = container.read(syncNotifierProvider);
      expect(state, isA<SyncError>());
      expect((state as SyncError).error, isA<SyncPermissionDeniedException>());
      expect(repo.syncCalls, 0);
    });

    test('一部種別失敗時は SyncPartial に遷移し失敗種別を保持する (P1-a)', () async {
      final repo = FakeHealthSyncRepository(failedTypesOnSync: {'steps'});
      final container = makeContainer(repo);

      await container.read(syncNotifierProvider.notifier).sync();

      final state = container.read(syncNotifierProvider);
      expect(state, isA<SyncPartial>());
      expect((state as SyncPartial).failedTypes, contains('steps'));
    });

    test('syncing 中は dataRevision が増えず、完了後に一度だけ増える (P1-c)', () async {
      final container = makeContainer(FakeHealthSyncRepository());
      expect(container.read(dataRevisionProvider), 0);

      final future = container.read(syncNotifierProvider.notifier).sync();
      // syncing 中は再評価トリガが増えない (ローカル再走査を起こさない)。
      expect(container.read(syncNotifierProvider), isA<SyncInProgress>());
      expect(container.read(dataRevisionProvider), 0);

      await future;
      expect(container.read(dataRevisionProvider), 1);
    });
  });

  group('T-503 派生プロバイダ', () {
    test('sleepSegmentsProvider はローカル DB から即時に値を返す', () {
      final repo = FakeHealthSyncRepository(sleep: [sampleSegment()]);
      final container = makeContainer(repo);

      final result = container.read(
        sleepSegmentsProvider(DateTime(2026, 6, 6)),
      );
      expect(result, hasLength(1));
    });

    test('stepsProvider / heartRateProvider が期間データを返す', () {
      final repo = FakeHealthSyncRepository(
        steps: [
          StepsRecordModel(
            uuid: 's1',
            startTime: DateTime(2026, 6, 6, 8),
            endTime: DateTime(2026, 6, 6, 9),
            count: 1000,
            sourcePackage: 'pkg',
          ),
        ],
        heartRate: [
          HeartRateRecordModel(
            uuid: 'h1',
            startTime: DateTime(2026, 6, 6, 3),
            endTime: DateTime(2026, 6, 6, 3),
            beatsPerMinute: 55,
            sourcePackage: 'pkg',
          ),
        ],
      );
      final container = makeContainer(repo);
      final range = DateRange(DateTime(2026, 6, 6), DateTime(2026, 6, 7));

      expect(container.read(stepsProvider(range)).single.count, 1000);
      expect(
        container.read(heartRateProvider(range)).single.beatsPerMinute,
        55,
      );
    });

    test('同期完了 (done) で派生プロバイダが再評価され値が更新される', () async {
      final repo = FakeHealthSyncRepository(sleep: <SleepSegment>[]);
      // 同期成功時に新データが到着する状況を再現。
      repo.onSync = () => repo.sleep = [sampleSegment()];
      final container = makeContainer(repo);
      final date = DateTime(2026, 6, 6);

      // 初期 (同期前) は空。
      expect(container.read(sleepSegmentsProvider(date)), isEmpty);

      await container.read(syncNotifierProvider.notifier).sync();

      // done 遷移後に再評価され、新データが反映される。
      expect(container.read(sleepSegmentsProvider(date)), hasLength(1));
    });
  });
}
