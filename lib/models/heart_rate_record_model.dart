import 'package:hive_ce/hive.dart';

part 'heart_rate_record_model.g.dart';

/// 脈拍 (心拍) サンプルのローカル永続化モデル。
///
/// ヘルスコネクトの `HeartRateRecord` のサンプルに対応する。心拍は瞬時値のため
/// `startTime == endTime` となる場合がある。`uuid` を Hive キーとして重複を排除する。
@HiveType(typeId: 2)
class HeartRateRecordModel extends HiveObject {
  HeartRateRecordModel({
    required this.uuid,
    required this.startTime,
    required this.endTime,
    required this.beatsPerMinute,
    required this.sourcePackage,
  });

  /// ヘルスコネクトが発行した一意な識別子 (Hive キーにも使用)。
  @HiveField(0)
  final String uuid;

  /// サンプル開始日時。
  @HiveField(1)
  final DateTime startTime;

  /// サンプル終了日時 (瞬時値の場合は startTime と同一)。
  @HiveField(2)
  final DateTime endTime;

  /// 心拍数 (bpm)。
  @HiveField(3)
  final int beatsPerMinute;

  /// 書き込み元アプリのパッケージ名。
  @HiveField(4)
  final String sourcePackage;

  /// Hive 上の一意キー。
  ///
  /// Health Connect の `HeartRateRecord` はシリーズであり、配下の各サンプルは
  /// 個別の ID を持たず親レコードの UUID を共有する。`uuid` 単独をキーにすると
  /// 同一シリーズの複数サンプルが 1 点に潰れるため、親 UUID にサンプル時刻 (ミリ秒) を
  /// 組み合わせた複合キーを用いる。
  String get hiveKey => '$uuid:${startTime.millisecondsSinceEpoch}';
}
