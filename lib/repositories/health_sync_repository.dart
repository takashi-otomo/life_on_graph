import 'package:health/health.dart';

import '../core/database_manager.dart';
import '../models/heart_rate_record_model.dart';
import '../models/sleep_record_model.dart';
import '../models/steps_record_model.dart';
import 'health_client.dart';

/// 同期ウィンドウ (`[start, end]`) を表す値オブジェクト。
class SyncWindow {
  const SyncWindow({required this.start, required this.end});

  /// 取得開始時刻 (含む)。
  final DateTime start;

  /// 取得終了時刻 (含む)。
  final DateTime end;
}

/// 1 回の同期実行結果。
class SyncOutcome {
  const SyncOutcome({
    required this.window,
    required this.savedCounts,
    required this.failedTypes,
  });

  /// 実行した同期ウィンドウ。
  final SyncWindow window;

  /// 種別ごとの保存件数 (`'sleep'` / `'steps'` / `'heart_rate'`)。
  final Map<String, int> savedCounts;

  /// 取得に失敗した種別キーの集合。
  final Set<String> failedTypes;

  /// 全種別が成功したか。
  bool get isFullSuccess => failedTypes.isEmpty;

  /// 保存件数の合計。
  int get totalSaved => savedCounts.values.fold(0, (a, b) => a + b);
}

/// ヘルスコネクト ⇄ ローカル DB を仲介する同期リポジトリ (設計doc 2 / 8 章)。
///
/// 将来のクラウド / iOS 差し替えに備えインタフェースとして公開する。
abstract interface class HealthSyncRepository {
  /// ヘルスプラットフォーム接続を初期化する。
  Future<void> configure();

  /// 睡眠・歩数・心拍の READ 権限を要求し、許可結果を返す。
  Future<bool> requestPermissions();

  /// [now] を終端とする同期ウィンドウを算出する。
  SyncWindow computeSyncWindow(DateTime now);

  /// 差分を取得してローカル DB へバッチ保存する。
  Future<SyncOutcome> sync({DateTime? now});
}

/// [HealthSyncRepository] の本番実装。
class HealthSyncRepositoryImpl implements HealthSyncRepository {
  /// [healthClient] と [databaseManager] を注入する (テスト時はフェイク化)。
  HealthSyncRepositoryImpl({
    required HealthClient healthClient,
    required DatabaseManager databaseManager,
  }) : _health = healthClient,
       _db = databaseManager;

  final HealthClient _health;
  final DatabaseManager _db;

  /// 初回バックフィル日数 (設計doc 8 章)。
  static const int backfillDays = 30;

  /// `app_sync_metadata` 上の最終同期時刻キー (ミリ秒エポック)。
  static const String lastSyncTimeKey = 'last_sync_time';

  /// 保存対象とする睡眠ステージタイプ。
  ///
  /// `SLEEP_SESSION` は全体エンベロープであり、ステージ単位に正規化する本設計では
  /// 二重計上を避けるため取得・保存対象から除外する (設計doc 6.1)。
  static const List<HealthDataType> sleepStageTypes = <HealthDataType>[
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_UNKNOWN,
  ];

  /// 申請・取得対象タイプ (睡眠ステージ + 歩数 + 心拍)。WRITE は一切要求しない。
  static const List<HealthDataType> targetTypes = <HealthDataType>[
    ...sleepStageTypes,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  /// [HealthDataType] からモデル用ステージ文字列への対応 (設計doc 6.1)。
  static const Map<HealthDataType, String> _stageTypeNames =
      <HealthDataType, String>{
        HealthDataType.SLEEP_DEEP: 'deep',
        HealthDataType.SLEEP_LIGHT: 'light',
        HealthDataType.SLEEP_REM: 'rem',
        HealthDataType.SLEEP_AWAKE: 'awake',
        HealthDataType.SLEEP_AWAKE_IN_BED: 'awake_in_bed',
        HealthDataType.SLEEP_OUT_OF_BED: 'out_of_bed',
        HealthDataType.SLEEP_UNKNOWN: 'unknown',
      };

  @override
  Future<void> configure() => _health.configure();

  @override
  Future<bool> requestPermissions() => _health.requestAuthorization(
    targetTypes,
    permissions: List<HealthDataAccess>.filled(
      targetTypes.length,
      HealthDataAccess.READ,
    ),
  );

  @override
  SyncWindow computeSyncWindow(DateTime now) {
    final int lastSyncMs =
        (_db.metadataBox.get(lastSyncTimeKey, defaultValue: 0) as int?) ?? 0;
    // 履歴権限 (T-304) 未対応のため、バックフィルは過去 30 日を下限としてクランプする。
    final DateTime floor = now.subtract(const Duration(days: backfillDays));
    final DateTime start;
    if (lastSyncMs <= 0) {
      start = floor;
    } else {
      final DateTime last = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      start = last.isBefore(floor) ? floor : last;
    }
    return SyncWindow(start: start, end: now);
  }

  @override
  Future<SyncOutcome> sync({DateTime? now}) async {
    final DateTime end = now ?? DateTime.now();
    final SyncWindow window = computeSyncWindow(end);
    final Map<String, int> saved = <String, int>{};
    final Set<String> failed = <String>{};

    // 1 種別の取得失敗が他種別の保存を阻害しないよう、種別ごとに独立実行する。
    saved['sleep'] = await _runCategory(
      key: 'sleep',
      failed: failed,
      types: sleepStageTypes,
      window: window,
      save: _saveSleep,
    );
    saved['steps'] = await _runCategory(
      key: 'steps',
      failed: failed,
      types: const <HealthDataType>[HealthDataType.STEPS],
      window: window,
      save: _saveSteps,
    );
    saved['heart_rate'] = await _runCategory(
      key: 'heart_rate',
      failed: failed,
      types: const <HealthDataType>[HealthDataType.HEART_RATE],
      window: window,
      save: _saveHeartRate,
    );

    // 全種別成功時のみ last_sync_time を前進させる。失敗を含む場合は据え置き、
    // 次回同期で同ウィンドウを再取得する (UUID 上書きで重複は発生しない)。
    if (failed.isEmpty) {
      await _db.metadataBox.put(lastSyncTimeKey, end.millisecondsSinceEpoch);
    }

    return SyncOutcome(window: window, savedCounts: saved, failedTypes: failed);
  }

  Future<int> _runCategory({
    required String key,
    required Set<String> failed,
    required List<HealthDataType> types,
    required SyncWindow window,
    required Future<int> Function(List<HealthDataPoint>) save,
  }) async {
    try {
      final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: window.start,
        endTime: window.end,
      );
      return await save(points);
    } catch (_) {
      // 例外内容は機密データを含み得るためログ出力しない (データ最小化)。
      failed.add(key);
      return 0;
    }
  }

  Future<int> _saveSleep(List<HealthDataPoint> points) async {
    final Map<String, SleepRecordModel> batch = <String, SleepRecordModel>{};
    for (final HealthDataPoint p in points) {
      final String? stage = _stageTypeNames[p.type];
      if (stage == null) continue;
      final SleepRecordModel record = SleepRecordModel(
        uuid: p.uuid,
        startTime: p.dateFrom,
        endTime: p.dateTo,
        stageType: stage,
        sourcePackage: p.sourceName,
      );
      batch[record.hiveKey] = record;
    }
    if (batch.isNotEmpty) await _db.sleepBox.putAll(batch);
    return batch.length;
  }

  Future<int> _saveSteps(List<HealthDataPoint> points) async {
    final Map<String, StepsRecordModel> batch = <String, StepsRecordModel>{};
    for (final HealthDataPoint p in points) {
      final StepsRecordModel record = StepsRecordModel(
        uuid: p.uuid,
        startTime: p.dateFrom,
        endTime: p.dateTo,
        count: _numericValue(p).round(),
        sourcePackage: p.sourceName,
      );
      batch[record.hiveKey] = record;
    }
    if (batch.isNotEmpty) await _db.stepsBox.putAll(batch);
    return batch.length;
  }

  Future<int> _saveHeartRate(List<HealthDataPoint> points) async {
    final Map<String, HeartRateRecordModel> batch =
        <String, HeartRateRecordModel>{};
    for (final HealthDataPoint p in points) {
      final HeartRateRecordModel record = HeartRateRecordModel(
        uuid: p.uuid,
        startTime: p.dateFrom,
        endTime: p.dateTo,
        beatsPerMinute: _numericValue(p).round(),
        sourcePackage: p.sourceName,
      );
      batch[record.hiveKey] = record;
    }
    if (batch.isNotEmpty) await _db.heartRateBox.putAll(batch);
    return batch.length;
  }

  /// 数値型 [HealthValue] から数値を取り出す (非数値型は 0)。
  num _numericValue(HealthDataPoint p) {
    final HealthValue v = p.value;
    return v is NumericHealthValue ? v.numericValue : 0;
  }
}
