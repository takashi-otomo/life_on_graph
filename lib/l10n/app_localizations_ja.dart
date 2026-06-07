// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabSummary => 'サマリー';

  @override
  String get tabSettings => '設定';

  @override
  String get today => '今日';

  @override
  String get sleep => '睡眠';

  @override
  String get steps => '歩数';

  @override
  String get heartRate => '心拍';

  @override
  String get sleepStages => '睡眠ステージ';

  @override
  String get noSleepDataForDay => 'この日の睡眠データはありません';

  @override
  String get noSleepData => '睡眠データがありません';

  @override
  String get noStepsDataForDay => 'この日の歩数データはありません';

  @override
  String get noHeartRateData => '心拍データがありません';

  @override
  String stepsValue(String count) {
    return '$count 歩';
  }

  @override
  String bpmValue(int value) {
    return '$value bpm';
  }

  @override
  String get resting => '安静';

  @override
  String get max => '最高';

  @override
  String get allDay => '全日';

  @override
  String get duringSleep => '睡眠中';

  @override
  String get stageDeep => '深い';

  @override
  String get stageLight => '浅い';

  @override
  String get stageRem => 'レム';

  @override
  String get stageAwake => '覚醒';

  @override
  String get stageUnknown => '不明';

  @override
  String get summaryTitle => 'サマリー';

  @override
  String get periodDay => '日';

  @override
  String get periodWeek => '週';

  @override
  String get periodMonth => '月';

  @override
  String get avgSleep => '平均睡眠';

  @override
  String get avgSteps => '平均歩数';

  @override
  String get avgHeartRate => '平均心拍';

  @override
  String get restingHeartRate => '安静時心拍';

  @override
  String get deltaDay => '前日比';

  @override
  String get deltaWeek => '先週比';

  @override
  String get deltaMonth => '先月比';

  @override
  String get viewTodayDetail => '今日の詳細を見る';

  @override
  String get sleepDuration => '睡眠時間';

  @override
  String get summaryHint => '同じ時間軸で各データを別レーンに表示します';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionDataSync => 'データ同期';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get syncing => '同期中…';

  @override
  String get notSynced => '未同期';

  @override
  String lastSynced(String time) {
    return '最終同期: $time';
  }

  @override
  String get healthConnectLink => 'Health Connect 連携';

  @override
  String get healthConnectLinkSubtitle => '睡眠・歩数・心拍を読み取り (READ のみ)';

  @override
  String get sectionPrivacy => 'プライバシーとセキュリティ';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get deleteAllData => 'すべてのデータを削除';

  @override
  String get deleteAllDataSubtitle => '端末内の睡眠・歩数・心拍データを消去';

  @override
  String get cannotDeleteWhileSyncing => '同期中は削除できません';

  @override
  String get sectionInfo => '情報';

  @override
  String get version => 'バージョン';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get contact => 'お問い合わせ';

  @override
  String get deleteDialogTitle => 'すべてのデータを削除';

  @override
  String get deleteDialogContent =>
      '端末内に保存した睡眠・歩数・心拍データをすべて削除します。この操作は取り消せません。\n\n(Health Connect 側のデータは削除されません。次回同期で再取得されます。)';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除する';

  @override
  String get deletedSnack => 'ローカルデータを削除しました';

  @override
  String get deleteAbortedSyncing => '同期中のため削除を中止しました';

  @override
  String get statusUnavailableTitle => 'Health Connect が必要です';

  @override
  String get statusUnavailableMessage =>
      '睡眠・歩数・心拍を取得するには Health Connect の導入が必要です。';

  @override
  String get install => 'インストール';

  @override
  String get statusPermissionTitle => 'ヘルスデータへのアクセスが必要です';

  @override
  String get statusPermissionMessage =>
      '睡眠・歩数・心拍を表示するには Health Connect の読み取り許可が必要です。';

  @override
  String get allow => '許可する';

  @override
  String get statusSyncFailedTitle => '同期に失敗しました';

  @override
  String get statusSyncFailedMessage => '表示中のデータはローカル保存分です。';

  @override
  String get retry => '再試行';

  @override
  String durationHm(int h, int m) {
    return '$h時間 $m分';
  }

  @override
  String durationMin(int m) {
    return '$m分';
  }

  @override
  String get prevDay => '前日';

  @override
  String get nextDay => '翌日';

  @override
  String get crossTitle => '統合ビュー (睡眠×心拍×歩数)';

  @override
  String get crossSubtitle => '起床時刻までの24時間。横スクロールで確認できます';

  @override
  String get crossEmpty => '睡眠データがないため統合表示できません';

  @override
  String get language => '言語';

  @override
  String get languageSystem => '端末の設定に従う';

  @override
  String get rationaleTitle => 'ヘルスデータの利用について';

  @override
  String rationaleIntro(String app) {
    return '$app は、以下のデータを Health Connect から読み取り、端末内でのグラフ表示にのみ使用します。データを外部へ送信することはありません。';
  }

  @override
  String get rationaleSleepDesc => '睡眠ステージ(深い/浅い/レム/覚醒)を可視化するために読み取ります。';

  @override
  String get rationaleStepsDesc => '時間帯別・日次/週次/月次の歩数を可視化するために読み取ります。';

  @override
  String get rationaleHeartDesc => '心拍数・安静時/最高値・睡眠中心拍を可視化するために読み取ります。';

  @override
  String get rationaleHistoryTitle => '過去データ(履歴)';

  @override
  String get rationaleHistoryDesc =>
      '初回起動時に過去30日より前のデータを遡って取得し、過去のトレンドを表示するための一時的な利用です。継続的なバックグラウンド取得は行いません。';

  @override
  String get rationaleSecurity =>
      '取得したデータは AES-256 で暗号化し端末内にのみ保存します。クラウド送信・第三者提供は行いません。';

  @override
  String get readPolicy => 'プライバシーポリシーを読む';

  @override
  String get openPolicyBrowser => 'ブラウザで公開版を開く';

  @override
  String get openApp => 'アプリを開く';

  @override
  String weekShort(int n) {
    return '$n週';
  }

  @override
  String get jumpToday => '今日へ';

  @override
  String get jumpThisMonth => '今月へ';

  @override
  String onbWelcomeTitle(String app) {
    return '$app へようこそ';
  }

  @override
  String get onbWelcomeBody => '睡眠・歩数・心拍を、端末内だけで可視化します。データを外部に送信することはありません。';

  @override
  String get onbStart => '始める';

  @override
  String get onbNext => '次へ';

  @override
  String get onbLangBody => '端末の言語設定に従います。いつでも設定から変更できます。';

  @override
  String get onbPermTitle => 'Health Connect と連携';

  @override
  String get onbConnect => '連携して同期';

  @override
  String get onbSkipSetup => 'あとで設定する';

  @override
  String get onbSyncing => 'データを同期しています…';

  @override
  String get onbDoneTitle => '準備完了';

  @override
  String get onbDoneBody => 'データの準備ができました。ホーム画面でトレンドを確認しましょう。';

  @override
  String get onbFinish => 'はじめる';
}
