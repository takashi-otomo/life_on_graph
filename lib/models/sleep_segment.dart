import 'sleep_record_model.dart';

/// クレンジング・可視化で扱う睡眠ステージ 1 区間の不変ドメインモデル。
///
/// 永続化用の [SleepRecordModel] (Hive) と異なり `uuid` を持たず、境界クリップや
/// オーバーラップ解消で区間を加工した派生セグメントを表現する。純粋関数で扱える
/// よう破壊的変更を許さず、[copyWith] で新インスタンスを生成する。
class SleepSegment {
  const SleepSegment({
    required this.startTime,
    required this.endTime,
    required this.stageType,
    required this.sourcePackage,
  });

  /// 永続化レコードから表示用セグメントへ変換する。
  factory SleepSegment.fromRecord(SleepRecordModel record) => SleepSegment(
    startTime: record.startTime,
    endTime: record.endTime,
    stageType: record.stageType,
    sourcePackage: record.sourcePackage,
  );

  /// 区間開始日時。
  final DateTime startTime;

  /// 区間終了日時。
  final DateTime endTime;

  /// 睡眠ステージ種別 (`deep` / `light` / `rem` / `awake` 等)。
  final String stageType;

  /// 書き込み元アプリのパッケージ名 (ソース優先順位判定に使用)。
  final String sourcePackage;

  /// 区間長。
  Duration get duration => endTime.difference(startTime);

  /// 一部のフィールドを差し替えた新インスタンスを返す (元を破壊しない)。
  SleepSegment copyWith({
    DateTime? startTime,
    DateTime? endTime,
    String? stageType,
    String? sourcePackage,
  }) => SleepSegment(
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    stageType: stageType ?? this.stageType,
    sourcePackage: sourcePackage ?? this.sourcePackage,
  );

  @override
  bool operator ==(Object other) =>
      other is SleepSegment &&
      other.startTime == startTime &&
      other.endTime == endTime &&
      other.stageType == stageType &&
      other.sourcePackage == sourcePackage;

  @override
  int get hashCode => Object.hash(startTime, endTime, stageType, sourcePackage);

  @override
  String toString() =>
      'SleepSegment($stageType, $startTime→$endTime, $sourcePackage)';
}
