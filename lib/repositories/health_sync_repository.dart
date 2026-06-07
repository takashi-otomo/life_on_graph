import 'package:health/health.dart';

import '../core/app_constants.dart';
import '../core/database_manager.dart';
import '../models/heart_rate_record_model.dart';
import '../models/sleep_record_model.dart';
import '../models/sleep_segment.dart';
import '../models/steps_record_model.dart';
import 'activity_recognition_permission.dart';
import 'cleansing.dart';
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
    this.skipped = false,
  });

  /// 差分極小によりクエリをスキップした no-op 結果 (T-305)。
  const SyncOutcome.skipped(SyncWindow window)
    : this(
        window: window,
        savedCounts: const <String, int>{},
        failedTypes: const <String>{},
        skipped: true,
      );

  /// 実行した同期ウィンドウ。
  final SyncWindow window;

  /// 種別ごとの保存件数 (`'sleep'` / `'steps'` / `'heart_rate'`)。
  final Map<String, int> savedCounts;

  /// 取得に失敗した種別キーの集合。
  final Set<String> failedTypes;

  /// 差分極小でクエリをスキップしたか (no-op)。
  final bool skipped;

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

  /// 履歴権限 (`READ_HEALTH_DATA_HISTORY`) を確認・追加要求する (T-304)。
  ///
  /// 既に許可済みなら再ダイアログを出さず `true` を返す。拒否・例外時は `false` を
  /// 返し、以降のバックフィルは過去 30 日に制限される (フォールバック)。
  Future<bool> ensureHistoryPermission();

  /// 歩数取得に必要な ACTIVITY_RECOGNITION ランタイム権限を確認・要求する (#58)。
  ///
  /// 既に許可済みなら再ダイアログを出さず `true` を返す。拒否・例外時は `false` を
  /// 返すが、歩数のみが影響し睡眠・心拍の同期は継続する (種別独立実行)。
  Future<bool> ensureActivityRecognitionPermission();

  /// [now] を終端とする同期ウィンドウを算出する。
  SyncWindow computeSyncWindow(DateTime now);

  /// 差分を取得してローカル DB へバッチ保存する。
  ///
  /// [force] が `true` の場合、差分極小スキップ (T-305) を無視して強制同期する。
  Future<SyncOutcome> sync({DateTime? now, bool force = false});

  /// [day] (正午〜翌正午の表示枠) のクレンジング済み睡眠セグメントを返す (M4)。
  ///
  /// ローカル DB の保存レコードに ①ソース優先順位 →②境界クリップ →③オーバーラップ
  /// 解消 →④隣接結合 のパイプライン (設計doc 9 章) を適用した結果を返す。
  List<SleepSegment> getCleanedSleepSegmentsForDay(DateTime day);

  /// `[start, end]` と交差する歩数レコードを開始昇順で返す (M5 派生Provider 用)。
  List<StepsRecordModel> getStepsForRange(DateTime start, DateTime end);

  /// `[start, end]` と交差する心拍レコードを開始昇順で返す (M5 派生Provider 用)。
  List<HeartRateRecordModel> getHeartRateForRange(DateTime start, DateTime end);

  /// 最終同期時刻 (未同期なら `null`)。設定画面で表示する (#69)。
  DateTime? get lastSyncTime;

  /// ローカルに保存した全ヘルスデータと同期メタデータを消去する (#69 / #64)。
  ///
  /// 暗号化ボックス (睡眠・歩数・心拍) を空にし `last_sync_time` を削除する。
  /// 次回同期は初回バックフィルとして再取得される。
  Future<void> clearAllData();

  /// Health Connect が利用可能 (導入済み) か (#42 状態別UI 判定用)。
  Future<bool> isHealthConnectAvailable();

  /// Health Connect の導入 (Google Play) へ誘導する (#42 未導入導線)。
  Future<void> installHealthConnect();
}

/// [HealthSyncRepository] の本番実装。
class HealthSyncRepositoryImpl implements HealthSyncRepository {
  /// [healthClient] と [databaseManager] を注入する (テスト時はフェイク化)。
  HealthSyncRepositoryImpl({
    required HealthClient healthClient,
    required DatabaseManager databaseManager,
    ActivityRecognitionPermission? activityPermission,
  }) : _health = healthClient,
       _db = databaseManager,
       _activity =
           activityPermission ?? const PermissionHandlerActivityRecognition();

  final HealthClient _health;
  final DatabaseManager _db;
  final ActivityRecognitionPermission _activity;

  /// 履歴権限 (`READ_HEALTH_DATA_HISTORY`) の付与状態。
  ///
  /// `true` のときのみ 30 日以前のバックフィルを許容する (T-304)。
  bool _historyAuthorized = false;

  /// 履歴権限が付与済みか (バックフィル範囲算出に反映される)。
  bool get isHistoryAuthorized => _historyAuthorized;

  /// 初回バックフィル日数 (設計doc 8 章)。
  static const int backfillDays = AppConstants.backfillDays;

  /// 履歴権限付与時の初回バックフィル日数。
  static const int historyBackfillDays = AppConstants.historyBackfillDays;

  /// `app_sync_metadata` 上の最終同期時刻キー (ミリ秒エポック)。
  static const String lastSyncTimeKey = 'last_sync_time';

  /// Health Connect の変更追跡トークンのキー (#64 削除のローカル反映用)。
  static const String changesTokenKey = 'changes_token';

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
  Future<bool> ensureHistoryPermission() async {
    try {
      // 既に許可済みなら再ダイアログを出さない。
      if (await _health.isHealthDataHistoryAuthorized()) {
        return _historyAuthorized = true;
      }
      return _historyAuthorized = await _health
          .requestHealthDataHistoryAuthorization();
    } catch (_) {
      // 拒否・キャンセル・例外時は 30 日フォールバックで同期を継続する。
      return _historyAuthorized = false;
    }
  }

  @override
  Future<bool> ensureActivityRecognitionPermission() async {
    try {
      // 既に許可済みなら再ダイアログを出さない (#58)。
      if (await _activity.isGranted()) return true;
      return await _activity.request();
    } catch (_) {
      // 拒否・例外でも歩数のみ影響し、睡眠・心拍の同期は継続する。
      return false;
    }
  }

  @override
  SyncWindow computeSyncWindow(DateTime now) {
    final int lastSyncMs = _lastSyncMs();
    final DateTime start;
    if (lastSyncMs <= 0) {
      // 初回バックフィル。履歴権限ありなら遡及範囲を拡張する (T-304)。
      // Health Connect の 30 日制限は権限付与時点が起点のため、フォールバック
      // (30 日クランプ) を適用するのはこの初回境界のみとする。
      final int days = _historyAuthorized ? historyBackfillDays : backfillDays;
      start = now.subtract(Duration(days: days));
    } else {
      // 付与後の差分は保存済み last_sync_time をそのまま開始に用いる。
      // 付与後に書かれたデータは 30 日を超えても読めるため、移動する 30 日床へ
      // クランプすると長期間未起動・部分失敗後の再開で恒久的な欠損を生む。
      // よって差分ではクランプしない (P1-1)。
      start = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }
    return SyncWindow(start: start, end: now);
  }

  /// `app_sync_metadata` から最終同期時刻 (ミリ秒) を読み出す (未設定は 0)。
  int _lastSyncMs() =>
      (_db.metadataBox.get(lastSyncTimeKey, defaultValue: 0) as int?) ?? 0;

  @override
  DateTime? get lastSyncTime {
    final int ms = _lastSyncMs();
    return ms <= 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> clearAllData() async {
    await _db.sleepBox.clear();
    await _db.stepsBox.clear();
    await _db.heartRateBox.clear();
    await _db.metadataBox.delete(lastSyncTimeKey);
  }

  @override
  Future<bool> isHealthConnectAvailable() => _health.isHealthConnectAvailable();

  @override
  Future<void> installHealthConnect() => _health.installHealthConnect();

  @override
  Future<SyncOutcome> sync({DateTime? now, bool force = false}) async {
    final DateTime end = now ?? DateTime.now();

    // #64: 先にリモート削除をローカルへ反映する。トークン期限切れ時はローカルを消去し
    // last_sync をリセットするため、ウィンドウ算出はこの後に行う。
    await _applyRemoteDeletions();

    final SyncWindow window = computeSyncWindow(end);

    // T-305: 前回同期からの差分が極小ならクエリをスキップ (初回・強制時は対象外)。
    final int lastSyncMs = _lastSyncMs();
    if (!force && lastSyncMs > 0) {
      final Duration elapsed = end.difference(
        DateTime.fromMillisecondsSinceEpoch(lastSyncMs),
      );
      if (elapsed < AppConstants.syncSkipThreshold) {
        return SyncOutcome.skipped(window);
      }
    }

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

    // #64: 以降の削除検出のため、トークン未確立なら確立する (初回 / 期限切れ後)。
    await _ensureChangesToken();

    return SyncOutcome(window: window, savedCounts: saved, failedTypes: failed);
  }

  String? _changesToken() => _db.metadataBox.get(changesTokenKey) as String?;

  /// Health Connect 側で削除されたレコードをローカル DB へ反映する (#64)。
  ///
  /// 変更トークンが未確立なら何もしない (次回 [_ensureChangesToken] が確立)。トークン
  /// 期限切れ時はローカルを消去し `last_sync_time` / トークンをリセットして、同一同期内の
  /// フル再取得で整合させる。失敗は同期全体を止めない (best-effort)。
  Future<void> _applyRemoteDeletions() async {
    try {
      final String? token = _changesToken();
      if (token == null || token.isEmpty) return;

      final Set<String> deleted = <String>{};
      String current = token;
      for (int page = 0; page < 50; page++) {
        final HealthChangesResult? res = await _health.getChanges(current);
        if (res == null) return; // 取得失敗時はトークンを据え置き次回再試行。
        if (res.expired) {
          await _db.sleepBox.clear();
          await _db.stepsBox.clear();
          await _db.heartRateBox.clear();
          await _db.metadataBox.delete(lastSyncTimeKey);
          await _db.metadataBox.delete(changesTokenKey);
          return;
        }
        deleted.addAll(res.deletedUuids);
        current = res.nextToken;
        if (!res.hasMore) break;
      }
      if (deleted.isNotEmpty) await _deleteByUuids(deleted);
      await _db.metadataBox.put(changesTokenKey, current);
    } catch (_) {
      // 削除反映の失敗は同期(取得・保存)を阻害しない。
    }
  }

  /// 変更トークンが未確立なら取得して保存する (#64)。
  Future<void> _ensureChangesToken() async {
    try {
      if (_changesToken() != null) return;
      final String? token = await _health.getChangesToken(targetTypes);
      if (token != null && token.isNotEmpty) {
        await _db.metadataBox.put(changesTokenKey, token);
      }
    } catch (_) {
      // トークン取得失敗時は次回同期で再試行する。
    }
  }

  /// 指定 UUID のレコードを全ボックスから削除する (#64)。
  ///
  /// 各ボックスのキーは `"<uuid>:..."` 形式のため、UUID プレフィックスで一致削除する。
  Future<void> _deleteByUuids(Set<String> uuids) async {
    if (uuids.isEmpty) return;
    for (final dynamic box in <dynamic>[
      _db.sleepBox,
      _db.stepsBox,
      _db.heartRateBox,
    ]) {
      final List<dynamic> toDelete = (box.keys as Iterable)
          .where(
            (k) => k is String && uuids.any((String u) => k.startsWith('$u:')),
          )
          .toList();
      if (toDelete.isNotEmpty) await box.deleteAll(toDelete);
    }
  }

  @override
  List<SleepSegment> getCleanedSleepSegmentsForDay(DateTime day) {
    // 表示枠は正午〜翌正午の 24 時間 (設計doc 9 章)。
    final DateTime start = DateTime(day.year, day.month, day.day, 12);
    final DateTime end = start.add(const Duration(days: 1));
    // ソース優先順位が別日のレコードに影響されないよう、表示枠と交差するレコードに
    // 事前フィルタしてからパイプラインへ渡す (cross-day のデータ消失を防止)。
    final List<SleepSegment> segments = _db.sleepBox.values
        .where((r) => r.endTime.isAfter(start) && r.startTime.isBefore(end))
        .map(SleepSegment.fromRecord)
        .toList();
    return runSleepCleansingPipeline(segments, start: start, end: end);
  }

  @override
  List<StepsRecordModel> getStepsForRange(DateTime start, DateTime end) {
    return _db.stepsBox.values
        .where((r) => r.endTime.isAfter(start) && r.startTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  List<HeartRateRecordModel> getHeartRateForRange(
    DateTime start,
    DateTime end,
  ) {
    return _db.heartRateBox.values
        .where((r) => r.endTime.isAfter(start) && r.startTime.isBefore(end))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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
