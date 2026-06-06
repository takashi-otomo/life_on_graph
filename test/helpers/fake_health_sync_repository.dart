import 'package:life_on_graph/models/heart_rate_record_model.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/models/steps_record_model.dart';
import 'package:life_on_graph/repositories/health_sync_repository.dart';

/// テスト用の [HealthSyncRepository] フェイク (DB / health 非依存)。
///
/// 派生プロバイダや UI の結線を、ローカル DB を立てずに検証するために用いる。
class FakeHealthSyncRepository implements HealthSyncRepository {
  FakeHealthSyncRepository({
    List<SleepSegment>? sleep,
    List<StepsRecordModel>? steps,
    List<HeartRateRecordModel>? heartRate,
    this.throwOnSync = false,
    this.onSync,
  }) : sleep = sleep ?? <SleepSegment>[],
       steps = steps ?? <StepsRecordModel>[],
       heartRate = heartRate ?? <HeartRateRecordModel>[];

  /// 読み出しで返す睡眠セグメント (同期後に差し替えてリアクティブ更新を再現)。
  List<SleepSegment> sleep;
  List<StepsRecordModel> steps;
  List<HeartRateRecordModel> heartRate;

  /// `sync()` で例外を投げるか。
  bool throwOnSync;

  /// `sync()` 成功直前に呼ばれるフック (新データ到着のシミュレーションに使う)。
  void Function()? onSync;

  int syncCalls = 0;
  bool configureCalled = false;

  @override
  Future<void> configure() async {
    configureCalled = true;
  }

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<bool> ensureHistoryPermission() async => true;

  @override
  SyncWindow computeSyncWindow(DateTime now) =>
      SyncWindow(start: now.subtract(const Duration(days: 30)), end: now);

  @override
  Future<SyncOutcome> sync({DateTime? now, bool force = false}) async {
    syncCalls++;
    if (throwOnSync) {
      throw StateError('fake sync failure');
    }
    onSync?.call();
    final DateTime end = now ?? DateTime(2026, 6, 6, 12);
    return SyncOutcome(
      window: SyncWindow(
        start: end.subtract(const Duration(days: 30)),
        end: end,
      ),
      savedCounts: const <String, int>{},
      failedTypes: const <String>{},
    );
  }

  @override
  List<SleepSegment> getCleanedSleepSegmentsForDay(DateTime day) => sleep;

  @override
  List<StepsRecordModel> getStepsForRange(DateTime start, DateTime end) =>
      steps;

  @override
  List<HeartRateRecordModel> getHeartRateForRange(
    DateTime start,
    DateTime end,
  ) => heartRate;
}
