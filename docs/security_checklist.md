# セキュリティチェックリスト (品質チェック用)

本書は Life On Graph (LOG) の **品質チェック時に毎回参照する** セキュリティ確認ルールである。
ヘルスケアデータ (睡眠・歩数・心拍) を最高機密として扱うローカルファースト設計を、機能追加や
リファクタで劣化させないことを目的とする。

## 使い方

- **適用タイミング**: PR 作成前、および `develop` / `main` へのマージ前の品質チェック。
- **判定**: 各項目を `✓ OK` / `✗ NG` / `N/A` で評価する。`✗ NG` が 1 つでもあればマージ前に解消するか、
  正当な理由を PR に記載してレビュアの承認を得る。
- **差分基準のレビュー**: 全項目を毎回精査するのが理想だが、最低限 **変更されたファイルに関係する項目**
  (下表の「関連パス」で判定) は必ず確認する。
- **背景・過去の指摘**: 各項目の "なぜ" は `docs/security_findings.md` (初回監査レポート, 2026-06-09) を参照。
  ID (例 `F1`) はそのレポートの Finding 番号に対応する。

---

## A. ヘルスデータの機密性 (端末内保護)

| ID | チェック項目 | 関連パス |
|----|-------------|---------|
| A1 | **画面流出対策**: ヘルスデータを表示する Activity に `FLAG_SECURE` が設定されている (スクリーンショット・Recents サムネイル・画面録画を遮断)。E2E 用に debug ビルドで無効化する場合は `BuildConfig.DEBUG` 分岐で限定する。(F1) | `android/.../MainActivity.kt` |
| A2 | **ログ非出力**: ヘルスデータ・その値・件数の詳細・例外メッセージを `print` / `debugPrint` / logger へ出力していない。`catch` で握った同期例外を本文ごとログしていない。(データ最小化原則) | `lib/**` |
| A3 | **外部送信なし**: ヘルスデータを HTTP/Firebase/Analytics/Crashlytics 等へ送信するコードがない。新規 SDK 追加時はテレメトリ送信の有無を確認した。 | `lib/**`, `pubspec.yaml` |
| A4 | **タップジャッキング**: destructive 操作 (全データ削除) やロック解除のタップが、オーバーレイ越しに誘導されない (`filterTouchesWhenObscured` 等)。(F8) | `MainActivity.kt`, `settings_view.dart` |

## B. 保存データの暗号化と鍵管理

| ID | チェック項目 | 関連パス |
|----|-------------|---------|
| B1 | **暗号化ボックス**: 睡眠・歩数・心拍の各 Hive ボックスは `HiveAesCipher` 付きで開いている。新規にヘルスデータ系ボックスを追加した場合も暗号化必須。平文 `app_sync_metadata` には**非機密のメタデータのみ**を置いている。 | `core/database_manager.dart` |
| B2 | **鍵の取り扱い**: 暗号鍵は `flutter_secure_storage` (Keystore) 経由のみで read/write し、ファイル・ログ・SharedPreferences・定数へ平文で書き出していない。鍵生成は `Hive.generateSecureKey()` (CSPRNG)。 | `core/encryption_key_provider.dart`, `core/secure_key_store.dart` |
| B3 | **破壊的復旧の限定**: 鍵不整合からの復旧 (全ボックス削除) を発火させる `catch` が、Keystore の一時障害 (`PlatformException` 等) まで巻き込んでいない。広い `catch (_)` で無条件にデータ破棄していない。(F3) | `core/database_manager.dart` |
| B4 | **機密フラグの保護**: アプリロック有効フラグなどセキュリティに関わる設定値が、改ざんで防御を無効化できない場所 (暗号化ボックス / secure storage、または「欠落時は安全側」の既定) に保存されている。(F5) | `providers/app_lock_provider.dart` |

## C. 認証 / アプリロック

| ID | チェック項目 | 関連パス |
|----|-------------|---------|
| C1 | **フェイルセーフ**: 認証プラグインの例外を「認証不要 (解錠)」へ変換していない。例外時は再試行可能なロック画面に留まる。フェイルオープンする場合 (端末ロック無効など) はユーザーへ明示する。(F4) | `features/lock/app_lock_gate.dart`, `repositories/biometric_auth.dart` |
| C2 | **施錠タイミング**: バックグラウンド移行 (`onHide`) で施錠し、復帰時に再認証する経路が壊れていない。pushed ルートを含む全画面を覆う。 | `features/lock/app_lock_gate.dart`, `main.dart` |

## D. Android マニフェスト / 権限

| ID | チェック項目 | 関連パス |
|----|-------------|---------|
| D1 | **ヘルス権限の最小化**: 申請権限は READ_SLEEP / READ_STEPS / READ_HEART_RATE / READ_HEALTH_DATA_HISTORY + ACTIVITY_RECOGNITION + USE_BIOMETRIC に限定。WRITE_* やバックグラウンド読み取りを追加していない (審査却下要因)。 | `AndroidManifest.xml` |
| D2 | **エクスポートコンポーネント**: `exported="true"` の Activity / alias は launcher・HC rationale・`START_VIEW_PERMISSION_USAGE` で保護された alias のみ。新規追加した exported コンポーネントは intent-filter とパーミッションを精査した。 | `AndroidManifest.xml` |
| D3 | **バックアップ除外**: `allowBackup="false"` を維持し、`data_extraction_rules.xml` が file/database/sharedpref/external を cloud-backup・device-transfer の両方から除外している。 | `AndroidManifest.xml`, `res/xml/data_extraction_rules.xml` |
| D4 | **平文通信**: `usesCleartextTraffic` を true にしていない (targetSdk 既定の false を維持)。新規ドメイン通信は https のみ。 | `AndroidManifest.xml` |
| D5 | **queries の最小化**: `<queries>` のパッケージ可視性宣言が必要なもの (Health Connect・https・mailto・PROCESS_TEXT) に限定されている。 | `AndroidManifest.xml` |

## E. CI/CD・シークレット・サプライチェーン

| ID | チェック項目 | 関連パス |
|----|-------------|---------|
| E1 | **Action のピン止め**: サードパーティ GitHub Action はフルコミット SHA でピン止めされている (可変タグ `@v1`/`@v2` のまま署名鍵・サービスアカウントを渡さない)。(F2) | `.github/workflows/*.yml` |
| E2 | **最小権限トークン**: 各ワークフローに `permissions: contents: read` (必要に応じ最小限) を明示している。(F6) | `.github/workflows/*.yml` |
| E3 | **シークレット取り扱い**: Secrets を `run:` のコマンド行へ直接展開せず env 経由で参照している。署名鍵を使うジョブは保護ブランチ (main/develop) 限定。外部入力 (build_number 等) は検証してからシェルへ渡す。 | `.github/workflows/*.yml` |
| E4 | **署名フォールバック**: release ビルドがデバッグ署名へサイレントにフォールバックしない (CI ではエラー、ローカルでは警告)。(F7) | `android/app/build.gradle.kts` |
| E5 | **鍵・機密のコミット禁止**: keystore (`*.jks`)、`key.properties`、サービスアカウント JSON、トークンをコミットしていない (`.gitignore` で除外)。Firebase の `google-services.json` の API キーはコンソールでアプリ制限 (パッケージ名 + SHA-1) を設定済み。(F11) | リポジトリ全体 |

## F. 依存パッケージ

| ID | チェック項目 |
|----|-------------|
| F-DEP1 | 新規/更新した依存に既知の重大 CVE がないか確認した (`flutter pub outdated`、必要に応じ脆弱性 DB 参照)。 |
| F-DEP2 | セキュリティ関連パッケージ (flutter_secure_storage / local_auth / hive_ce / health / firebase_core) を更新した際、破壊的変更が鍵管理・暗号化・認証の挙動を変えていないか確認した。 |
| F-DEP3 | 追加した依存がネットワーク送信・解析 (analytics) ・広告 SDK を含まないか確認した (ローカルファースト方針)。 |

## G. データ削除 / ライフサイクル

| ID | チェック項目 | 関連パス |
|----|-------------|---------|
| G1 | 「全データ削除」が暗号化ボックスと同期メタデータ (`last_sync_time` 等) を確実に消去する。削除と同期の競合 (同期中削除) が抑止されている。 | `repositories/health_sync_repository.dart`, `settings_view.dart` |
| G2 | リモート削除のローカル反映 (changes token) が、データを過剰削除したり例外で同期全体を止めたりしない。 | `repositories/health_sync_repository.dart` |

---

## 補足: 機械的チェックの推奨 (任意)

手動チェックの補助として、以下の自動化を推奨する (導入は別タスク)。

- **シークレット検出**: `gitleaks` 等を pre-commit / CI に追加し、鍵・トークンの混入を機械的に検出。
- **Action ピン止め検査**: CI で `.github/workflows/` に `@v[0-9]` 形式のタグ参照が無いことを grep で検査。
- **ログ出力検査**: `lib/` 配下の `print(` / `debugPrint(` を grep し、許可リスト外の出力をレビュー対象に。
- **依存監査**: `flutter pub outdated` を CI で定期実行し、古い依存を可視化。

これらはあくまで補助であり、本チェックリストの手動レビューを代替しない。
