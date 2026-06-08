/// アプリ全体で共有する定数。
class AppConstants {
  AppConstants._();

  /// アプリの正式表示名。
  static const String appName = 'Life On Graph';

  /// アプリの略称。
  static const String appShortName = 'LOG';

  /// アプリの表示バージョン (pubspec の version と一致させる)。
  static const String appVersion = '1.0.0';

  /// プライバシーポリシーの公開 URL (#115, ホームページと同一ドメイン / Firebase Hosting)。
  static const String privacyPolicyUrl = 'https://lifeongraph.web.app/privacy';

  /// アプリ公式ホームページ (#114, Firebase Hosting)。
  static const String homepageUrl = 'https://lifeongraph.web.app';

  /// お問い合わせ先 (Google フォーム)。
  static const String contactUrl = 'https://forms.gle/TQSUCq7ERuMLn6jB8';

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

  /// 信頼ソースの優先順位リスト (先頭ほど高優先, 設計doc 9 章)。
  ///
  /// 複数アプリが同一時間帯に重複データを書き込む場合、このリストの上位ソースを
  /// 採用して単一ソース化する (クレンジング第1段)。リストに無いソースのみが存在
  /// する場合は、唯一のソースとして採用する (データ消失を避けるフェイルオープン)。
  static const List<String> trustedSleepSources = <String>[
    'com.google.android.apps.healthdata', // Health Connect 本体
    'com.sec.android.app.shealth', // Samsung Health
    'com.fitbit.FitbitMobile', // Fitbit
    'com.google.android.apps.fitness', // Google Fit
    'com.ouraring.oura', // Oura
    'com.garmin.android.apps.connectmobile', // Garmin Connect
  ];

  /// 隣接同一ステージ結合の既定ギャップ許容値 (設計doc 9 章)。
  static const Duration adjacentMergeTolerance = Duration(seconds: 30);
}
