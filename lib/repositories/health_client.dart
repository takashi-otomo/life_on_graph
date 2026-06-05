import 'package:health/health.dart';

/// `health` パッケージ ([Health]) への薄い抽象境界。
///
/// プラットフォームチャネルに依存する [Health] を直接参照すると、
/// ユニットテストで同期ロジックを検証できない。本インタフェースを介すことで
/// テスト時はフェイク実装に差し替え、将来 iOS (HealthKit) やクラウド同期へ
/// 切り替える際の差し込み口とする (設計doc 2 章)。
abstract interface class HealthClient {
  /// ヘルスプラットフォーム接続を初期化する ([Health.configure])。
  Future<void> configure();

  /// 指定タイプへのアクセス権限を要求する。
  ///
  /// データ最小化方針により呼び出し側は READ 権限のみを渡す (設計doc 4.4 / 13 章)。
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  });

  /// `[startTime, endTime]` の範囲で指定タイプのデータ点を取得する。
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  });

  /// 履歴権限 (`READ_HEALTH_DATA_HISTORY`) が既に付与済みか確認する。
  Future<bool> isHealthDataHistoryAuthorized();

  /// 履歴権限を実行時に追加要求し、許可結果を返す。
  Future<bool> requestHealthDataHistoryAuthorization();
}

/// [Health] シングルトンに委譲する本番用 [HealthClient] 実装。
class HealthPackageClient implements HealthClient {
  /// テストや DI のため任意の [Health] を注入できる。省略時は共有シングルトン。
  HealthPackageClient([Health? health]) : _health = health ?? Health();

  final Health _health;

  @override
  Future<void> configure() => _health.configure();

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) => _health.requestAuthorization(types, permissions: permissions);

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) => _health.getHealthDataFromTypes(
    types: types,
    startTime: startTime,
    endTime: endTime,
  );

  @override
  Future<bool> isHealthDataHistoryAuthorized() =>
      _health.isHealthDataHistoryAuthorized();

  @override
  Future<bool> requestHealthDataHistoryAuthorization() =>
      _health.requestHealthDataHistoryAuthorization();
}
