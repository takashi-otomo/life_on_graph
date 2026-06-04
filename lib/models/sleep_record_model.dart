import 'package:hive/hive.dart';

part 'sleep_record_model.g.dart';

/// 睡眠ステージ 1 セグメントを表すローカル永続化モデル。
///
/// ヘルスコネクトの `SleepSessionRecord` はセッションとステージ配列の 2 階層だが、
/// 本アプリではステージ単位に正規化して保存する。`uuid` を Hive のキーとして用い、
/// 同一データの重複書き込みを上書きで排除する (Deduplication)。
@HiveType(typeId: 0)
class SleepRecordModel extends HiveObject {
  SleepRecordModel({
    required this.uuid,
    required this.startTime,
    required this.endTime,
    required this.stageType,
    required this.sourcePackage,
  });

  /// ヘルスコネクトが発行した一意な識別子 (Hive キーにも使用)。
  @HiveField(0)
  final String uuid;

  /// セグメント開始日時。
  @HiveField(1)
  final DateTime startTime;

  /// セグメント終了日時。
  @HiveField(2)
  final DateTime endTime;

  /// 睡眠ステージ種別 (例: `deep` / `light` / `rem` / `awake` /
  /// `out_of_bed` / `awake_in_bed` / `unknown`)。
  @HiveField(3)
  final String stageType;

  /// 書き込み元アプリのパッケージ名 (データ競合の優先順位判定に使用)。
  @HiveField(4)
  final String sourcePackage;
}
