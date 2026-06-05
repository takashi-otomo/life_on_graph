/// アプリ全体で共有する定数。
class AppConstants {
  AppConstants._();

  /// アプリの正式表示名。
  static const String appName = 'Life On Graph';

  /// アプリの略称。
  static const String appShortName = 'LOG';

  /// 初回同期で遡るバックフィル日数 (設計doc 8 章)。
  static const int backfillDays = 30;

  /// 差分同期のクエリスキップ閾値 (設計doc 8 章)。
  ///
  /// 前回同期からの経過がこの値未満なら `getHealthDataFromTypes` を呼ばずに
  /// 早期リターンし、短時間の連続起動での無駄な I/O・電力消費を抑える。
  static const Duration syncSkipThreshold = Duration(minutes: 5);
}
