import 'package:hive_ce/hive.dart';

part 'steps_record_model.g.dart';

/// 歩数レコードのローカル永続化モデル。
///
/// ヘルスコネクトの `StepsRecord` に対応し、ある時間区間における歩数の合計を表す。
/// `uuid` を Hive キーとして重複を排除する。
@HiveType(typeId: 1)
class StepsRecordModel extends HiveObject {
  StepsRecordModel({
    required this.uuid,
    required this.startTime,
    required this.endTime,
    required this.count,
    required this.sourcePackage,
  });

  /// ヘルスコネクトが発行した一意な識別子 (Hive キーにも使用)。
  @HiveField(0)
  final String uuid;

  /// 区間開始日時。
  @HiveField(1)
  final DateTime startTime;

  /// 区間終了日時。
  @HiveField(2)
  final DateTime endTime;

  /// 当該区間の歩数。
  @HiveField(3)
  final int count;

  /// 書き込み元アプリのパッケージ名。
  @HiveField(4)
  final String sourcePackage;

  /// Hive 上の一意キー。
  ///
  /// 歩数レコードは通常一意な UUID を持つが、集計区間の異なる同一 UUID 由来データの
  /// 取りこぼしを防ぐため、UUID に区間 (開始・終了ミリ秒) を組み合わせた複合キーを用いる。
  /// 同一区間の再取得は同じキーとなり重複排除が成立する。
  String get hiveKey =>
      '$uuid:${startTime.millisecondsSinceEpoch}:${endTime.millisecondsSinceEpoch}';
}
