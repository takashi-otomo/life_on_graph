import 'package:health/health.dart';
import 'package:life_on_graph/repositories/health_client.dart';

/// テスト用の [HealthClient] フェイク。
///
/// プラットフォームチャネルを呼ばずに、同期ロジックへ任意のデータ点・権限結果・
/// 例外を注入できる。
class FakeHealthClient implements HealthClient {
  FakeHealthClient({
    this.authorized = true,
    Map<HealthDataType, List<HealthDataPoint>>? dataByType,
    Set<HealthDataType>? throwOnTypes,
    this.historyAlreadyAuthorized = false,
    this.historyRequestResult = false,
    this.throwOnHistory = false,
  }) : _dataByType = dataByType ?? <HealthDataType, List<HealthDataPoint>>{},
       _throwOnTypes = throwOnTypes ?? <HealthDataType>{};

  /// [requestAuthorization] が返す許可結果。
  bool authorized;

  /// 履歴権限が既に付与済みか ([isHealthDataHistoryAuthorized] の戻り値)。
  bool historyAlreadyAuthorized;

  /// [requestHealthDataHistoryAuthorization] が返す許可結果。
  bool historyRequestResult;

  /// 履歴権限 API で例外を投げるか。
  bool throwOnHistory;

  /// [requestHealthDataHistoryAuthorization] の呼び出し回数。
  int historyRequestCount = 0;

  final Map<HealthDataType, List<HealthDataPoint>> _dataByType;
  final Set<HealthDataType> _throwOnTypes;

  bool configureCalled = false;
  int configureCallCount = 0;

  /// 直近の [requestAuthorization] に渡されたタイプ。
  List<HealthDataType>? lastRequestedTypes;

  /// 直近の [requestAuthorization] に渡された権限。
  List<HealthDataAccess>? lastRequestedPermissions;

  /// 取得要求の `[start, end]` 履歴。
  final List<({DateTime start, DateTime end})> queriedWindows =
      <({DateTime start, DateTime end})>[];

  @override
  Future<void> configure() async {
    configureCalled = true;
    configureCallCount++;
  }

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async {
    lastRequestedTypes = types;
    lastRequestedPermissions = permissions;
    return authorized;
  }

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    queriedWindows.add((start: startTime, end: endTime));
    final List<HealthDataPoint> result = <HealthDataPoint>[];
    for (final HealthDataType type in types) {
      if (_throwOnTypes.contains(type)) {
        throw StateError('fake fetch failure: $type');
      }
      result.addAll(_dataByType[type] ?? const <HealthDataPoint>[]);
    }
    return result;
  }

  @override
  Future<bool> isHealthDataHistoryAuthorized() async {
    if (throwOnHistory) throw StateError('fake history check failure');
    return historyAlreadyAuthorized;
  }

  @override
  Future<bool> requestHealthDataHistoryAuthorization() async {
    historyRequestCount++;
    if (throwOnHistory) throw StateError('fake history request failure');
    return historyRequestResult;
  }

  /// Health Connect 導入状態 ([isHealthConnectAvailable] の戻り値)。
  bool healthConnectAvailable = true;

  /// [installHealthConnect] の呼び出し回数。
  int installCount = 0;

  @override
  Future<bool> isHealthConnectAvailable() async => healthConnectAvailable;

  @override
  Future<void> installHealthConnect() async => installCount++;
}

/// テスト用に [HealthDataPoint] を簡潔に生成するヘルパ。
HealthDataPoint fakePoint({
  required String uuid,
  required HealthDataType type,
  required DateTime from,
  required DateTime to,
  num value = 0,
  String sourceName = 'pkg.test',
}) {
  return HealthDataPoint(
    uuid: uuid,
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: 'device',
    sourceId: 'source-id',
    sourceName: sourceName,
  );
}
