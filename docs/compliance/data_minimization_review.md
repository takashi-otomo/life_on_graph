# データ最小化レビュー (#45 / T-703)

リリース前に AndroidManifest の宣言権限を実ファイルで確認し、**不要権限ゼロ**であることを記録する。Google Play ヘルス申告 (#44) およびプライバシーポリシー (#43) と一致させる最終チェックポイント。

- レビュー対象: `android/app/src/main/AndroidManifest.xml`(リリースに反映される宣言)
- レビュー日時点のバージョン: `1.0.0+1`

## 1. リリース(main)で宣言している権限

| 権限 | 種別 | 対応する機能要件 | 用途・正当性 |
| --- | --- | --- | --- |
| `android.permission.health.READ_SLEEP` | Health Connect READ | FR-2 / FR-4(睡眠) | 睡眠ステージのタイムライン・サマリー表示 |
| `android.permission.health.READ_STEPS` | Health Connect READ | FR-3(歩数) | 時間帯別歩数グラフ・合計表示 |
| `android.permission.health.READ_HEART_RATE` | Health Connect READ | FR-5 / FR-6(心拍) | 心拍折れ線・安静/最高、睡眠中心拍 |
| `android.permission.health.READ_HEALTH_DATA_HISTORY` | Health Connect READ | FR-1(初回バックフィル) | 初回同期で 30 日以前を遡るための一時利用(無ければ過去30日に制限) |
| `android.permission.ACTIVITY_RECOGNITION` | Android ランタイム権限 | FR-3(歩数) | 歩数(身体活動)へのアクセスに用いる標準ランタイム権限(#58 で追加・実行時要求)。Health Connect 権限ではない |

> **補足**: `ACTIVITY_RECOGNITION` は Issue #45 起票時(健康READ4件想定)より後の #58 で追加した標準ランタイム権限。Health Connect からの歩数 READ 自体は `READ_STEPS` で宣言されるため、本権限は **Health Connect が必須とするもの**ではない(身体活動アクセスの一般的要件として実行時要求している)。Play ヘルス申告 (#44) では Health Connect 権限(上記4件)を申告し、本権限は通常のアプリ権限として扱う。
>
> ⚠ **再確認事項(さらなる最小化)**: Health Connect 経由の歩数 READ のみで `ACTIVITY_RECOGNITION` が実際に不要であれば、データ最小化の観点から削除を検討する(実機での歩数取得検証 #11 と併せて確認し、不要なら除去)。

## 2. 不要権限が無いことの確認

- ✅ **WRITE 系の健康権限はリリースに無い**。`WRITE_SLEEP` / `WRITE_STEPS` / `WRITE_HEART_RATE` は **デバッグビルド専用** (`android/app/src/debug/AndroidManifest.xml`) に限定され、テストデータ投入ツール (`tool/health_seeder.dart`, #76) のためにのみ存在する。release マニフェストにはマージされない(製品は READ のみ)。
- ✅ **バックグラウンド読み取り権限が無い**。`READ_HEALTH_DATA_IN_BACKGROUND` は宣言していない(後続 #48 / #49 で初めて検討)。
- ✅ **スコープ外データ種別の権限が無い**。体重 (`READ_WEIGHT`)・血糖値 (`READ_BLOOD_GLUCOSE`)・呼吸数 (`READ_RESPIRATORY_RATE`) 等、睡眠/歩数/心拍以外の健康権限は宣言していない(要件 2.2 スコープ外)。
- ✅ **`INTERNET` はリリースに無い**。デバッグビルドのみ(Flutter ツールのホットリロード用、`src/debug`)。製品はネットワーク送信を行わない(ローカルファースト)。

## 3. `<queries>` の限定確認

- `com.google.android.apps.healthdata`(Health Connect 本体の可視性)
- `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE`(権限根拠インテント)
- `android.intent.action.VIEW` + `https`(プライバシーポリシーを外部ブラウザで開く, #69)
- `android.intent.action.SENDTO` + `mailto`(お問い合わせ, #69)
- `android.intent.action.PROCESS_TEXT` + `text/plain`(Flutter テンプレート既定)

いずれもアプリ機能に直結する用途であり、不要な可視性宣言は無い。

## 4. データ送信なし(ローカル完結)の確認

- コードベースに HTTP / Dio / Socket / Firebase / googleapis 等の外部送信は存在しない(`lib/` 全文検索で送信処理ゼロ)。
- 取得した健康データは AES-256 暗号化 Hive (`HiveAesCipher`) にのみ保存し、鍵は `flutter_secure_storage`(Android Keystore)で隔離管理する。
- 健康データの平文ログ出力は行わない(`print` / `debugPrint` / `log` 呼び出しなし)。

## 5. 結論

リリースマニフェストの健康権限は **睡眠・歩数・心拍・履歴の4件**(+歩数に必須の標準権限 `ACTIVITY_RECOGNITION`)のみで、WRITE・バックグラウンド・スコープ外データ種別の権限は存在しない。データ最小化原則 (FR-1 / NFR-2) を満たしており、Play ヘルス申告 (#44) の申告権限と一致する。

## 受け入れ基準の対応

- [x] `<uses-permission>` が READ_SLEEP / READ_STEPS / READ_HEART_RATE / READ_HEALTH_DATA_HISTORY のみ(+ ACTIVITY_RECOGNITION は歩数用標準権限として明記)
- [x] WRITE 系・バックグラウンド権限がリリースに無い(WRITE はデバッグ限定)
- [x] スコープ外データ種別(体重・血糖値・呼吸数等)の権限が無い
- [x] 各権限と機能要件の用途対応を記録(本表)
- [x] 確認結果が Play ヘルス申告 (#44) と矛盾しない
