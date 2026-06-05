/// アプリ全体で共有する定数。
class AppConstants {
  AppConstants._();

  /// アプリの正式表示名。
  static const String appName = 'Life On Graph';

  /// アプリの略称。
  static const String appShortName = 'LOG';

  /// 初回同期で遡るバックフィル日数 (設計doc 8 章)。
  ///
  /// Health Connect は既定で権限付与時点から 30 日以内の読み取りに制限される。
  static const int backfillDays = 30;

  /// 履歴権限 (`READ_HEALTH_DATA_HISTORY`) 付与時の初回バックフィル日数。
  ///
  /// 履歴許可があれば 30 日以前も読めるため、初回オンボーディングで遡る範囲を
  /// 拡張する。無制限取得による初回同期の重さを避けるため上限を設ける。
  static const int historyBackfillDays = 365;

  /// 差分同期のクエリスキップ閾値 (設計doc 8 章)。
  ///
  /// 前回同期からの経過がこの値未満なら `getHealthDataFromTypes` を呼ばずに
  /// 早期リターンし、短時間の連続起動での無駄な I/O・電力消費を抑える。
  static const Duration syncSkipThreshold = Duration(minutes: 5);
}
