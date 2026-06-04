import 'package:hive/hive.dart';

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
}
