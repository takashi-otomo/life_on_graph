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
  /// 初回同期は負荷とメモリを抑えるため **過去 3 か月 (約 90 日)** に限定する。
  /// それ以前のデータは設定の「全データを再読み込み」で遡って取得できる。
  static const int historyBackfillDays = 90;

  /// 「全データを再読み込み」で遡る最大日数 (履歴権限あり時)。
  ///
  /// 設定からの手動操作でのみ用いる。Health Connect への範囲指定が必要なため上限を設ける。
  /// 実運用のデータ保持期間を十分にカバーするよう広めに取るが、これより古いデータは
  /// 取得対象外となる (「全期間」を保証するものではない)。
  static const int fullReloadDays = 3650; // 約 10 年

  /// 同期時に時間ウィンドウを分割するチャンク日数 (#sync-progress)。
  ///
  /// 全期間を一括取得するとメモリを圧迫し大量データで停止し得るため、この日数ごとに
  /// 取得 → 保存 → 解放を繰り返してメモリ使用量を一定に抑える。
  static const int syncChunkDays = 14;

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
