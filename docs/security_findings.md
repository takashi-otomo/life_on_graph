# セキュリティ脆弱性調査レポート

調査日: 2026-06-09
対象: `main` ブランチ (commit `1f73257`)
調査範囲: Dart アプリコード (`lib/`)、Android ネイティブ設定 (`android/`)、CI/CD (`.github/workflows/`)、依存パッケージ (`pubspec.lock`)

各 Finding は GitHub issue にそのまま転記できるよう、自己完結した形式で記載しています。

## サマリ

| # | タイトル | リスク | 修正難易度 | 複雑性 |
|---|---------|--------|-----------|--------|
| 1 | FLAG_SECURE 未設定によるヘルスデータの画面流出 | **High** | 低 (数行) | 低 |
| 2 | CI/CD: サードパーティ Action のタグ参照による署名鍵・配信認証情報のサプライチェーンリスク | **Medium** (影響は High) | 低 | 低 |
| 3 | 鍵復旧ロジックの広すぎる例外捕捉による全ヘルスデータの無断破棄 | **Medium** | 中 | 中 |
| 4 | アプリロックのフェイルオープン設計 (認証不能時に自動解錠) | **Medium-Low** | 低〜中 | 中 |
| 5 | アプリロック有効フラグが平文ボックスに保存され改ざん可能 | **Low** | 低 | 低 |
| 6 | GitHub Actions ワークフローに `permissions:` 最小化がない | **Low** | 低 | 低 |
| 7 | release ビルドのデバッグ署名への暗黙フォールバック | **Low** | 低 | 低 |
| 8 | タップジャッキング (オーバーレイ) 対策の欠如 | **Low** | 中 | 中 |
| 9 | HiveAesCipher (AES-CBC) は完全性検証を持たない | **Info** | 中 | 中 |
| 10 | ルート化検出 / Play Integrity 未導入 | **Info** | 中 | 中 |
| 11 | Firebase API キーのリポジトリコミット | **Info** | 低 (コンソール設定) | 低 |

**総評**: ローカルファースト設計の根幹 (Hive AES-256 暗号化、Keystore 連携の鍵管理、`allowBackup=false` + 全データのバックアップ除外、READ 専用のヘルス権限、ヘルスデータの非ログ出力) は適切に実装されており、重大なデータ漏えい経路は確認されませんでした。最優先は #1 (FLAG_SECURE) と #2 (CI サプライチェーン) です。

---

## Finding 1: FLAG_SECURE 未設定によるヘルスデータの画面流出

- **リスクレベル**: High (ヘルスデータの機密性 / CASA・Play ヘルスアプリ審査観点)
- **修正難易度**: 低 (MainActivity への数行追加)
- **複雑性**: 低
- **対象**: `android/app/src/main/kotlin/dev/otomo/life_on_graph/MainActivity.kt`

### 内容

ウィンドウに `WindowManager.LayoutParams.FLAG_SECURE` が設定されていないため、睡眠・歩数・心拍データを表示する全画面が以下の経路で流出し得る:

1. **最近のタスク (Recents) のサムネイル**: アプリをバックグラウンドに送るとシステムが直前のフレームをキャプチャする。アプリロック (#79) は `onHide` で施錠するが、サムネイル取得とのレースがあり、ロック有効時でもダッシュボードの内容がサムネイルに残り得る。
2. **スクリーンショット / 画面録画**: ユーザー本人以外 (端末を手にした第三者、画面共有中の事故) によるキャプチャを防げない。
3. **メディアプロジェクション**: 画面キャストや他アプリの録画 API から内容が見える。

CLAUDE.md の「ヘルスケアデータは最高機密として扱う」方針に対し、画面経由の流出経路が未対処。

### 再現手順

1. アプリを起動しダッシュボード (睡眠/歩数/心拍) を表示する。
2. ホームボタンでバックグラウンドへ → タスク一覧を開く → サムネイルにヘルスデータが表示される。
3. アプリ表示中にスクリーンショットを撮る → 成功する (ブロックされない)。

### 推奨対策

`MainActivity.onCreate` (または `configureFlutterEngine`) で:

```kotlin
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
)
```

注: E2E (Maestro) のスクリーンショット取得に影響するため、debug ビルドでは無効化する分岐 (`BuildConfig.DEBUG`) を検討する。

---

## Finding 2: CI/CD サードパーティ Action のタグ参照によるサプライチェーンリスク

- **リスクレベル**: Medium (発生可能性は低いが、影響は High: アプリ署名鍵・Play 公開権限の窃取)
- **修正難易度**: 低 (SHA ピン止め + Dependabot 設定)
- **複雑性**: 低
- **対象**: `.github/workflows/distribute.yml`, `.github/workflows/build-aab.yml`, `.github/workflows/ci.yml`

### 内容

リリースワークフローが以下の Secrets をサードパーティ Action に渡している:

- `ANDROID_KEYSTORE_BASE64` / 各パスワード (アップロード署名鍵)
- `FIREBASE_SERVICE_ACCOUNT` (Firebase サービスアカウント JSON)
- `PLAY_SERVICE_ACCOUNT` (**Google Play へ任意のリリースを公開できる** サービスアカウント JSON)

これらの Action が **可変なタグ参照** でピン止めされている:

- `wzieba/Firebase-Distribution-Github-Action@v1` (distribute.yml:81, 142)
- `r0adkll/upload-google-play@v1` (distribute.yml:157)
- `subosito/flutter-action@v2` (全ワークフロー)
- `actions/checkout@v4` ほか公式 Action

タグはリポジトリ所有者がいつでも別コミットへ付け替え可能なため、Action リポジトリの侵害 (2025 年の `tj-actions/changed-files` 事件と同型) で署名鍵と Play 公開認証情報が流出し、**ユーザーへ悪性アップデートを配信できる** 事態につながる。ヘルスデータを扱うアプリとして影響が大きい。

### 再現手順 (リスクの確認)

1. `.github/workflows/distribute.yml` の 81/142/157 行目を確認 → コミット SHA ではなくタグ `@v1` で参照されている。
2. `gh api repos/wzieba/Firebase-Distribution-Github-Action/git/refs/tags/v1` 等でタグが mutable であることを確認できる。

### 推奨対策

1. 全 Action をフルコミット SHA でピン止めする (例: `uses: wzieba/Firebase-Distribution-Github-Action@<40桁SHA> # v1`)。
2. `.github/dependabot.yml` に `package-ecosystem: github-actions` を追加し、SHA 更新を自動 PR 化する。
3. 可能なら Play 公開はサービスアカウント JSON ではなく Workload Identity 連携へ移行する (長期的改善)。

---

## Finding 3: 鍵復旧ロジックの広すぎる例外捕捉による全ヘルスデータの無断破棄

- **リスクレベル**: Medium (可用性・完全性: ユーザーデータの不可逆な破壊)
- **修正難易度**: 中
- **複雑性**: 中
- **対象**: `lib/core/database_manager.dart:106-116`, `_recoverKey` (138-145)

### 内容

```dart
try {
  cipher = HiveAesCipher(await provider.getOrCreateKey());
} catch (_) {
  cipher = await _recoverKey(provider);   // 全暗号化ボックス削除 + メタデータ全消去
  recoveredFromKeyFailure = true;
}
```

コメントでは「復旧対象は鍵の取得/復号失敗のみに限定」とあるが、実際の `catch (_)` は `getOrCreateKey()` 内で起きる **あらゆる例外** を破壊的復旧へルーティングする。Android Keystore は以下のような **一時的な** 失敗を起こすことが知られている:

- 端末起動直後・ロック中の `KeyStoreException` / `UserNotAuthenticatedException`
- OS アップデート直後や Keymaster デーモンの一時不調
- `flutter_secure_storage` のプラグイン例外 (`PlatformException`)

これらの一過性エラーで、睡眠・歩数・心拍の全履歴と同期メタデータが **確認なしに削除** される。Health Connect から再同期可能なのは履歴権限があっても最大 365 日のバックフィル分のみで、Health Connect 側で既に消えた古いデータは恒久に失われる。攻撃者なしでも発生し得る点で再現性のあるデータ破壊バグであり、悪意ある常駐アプリが Keystore 障害を誘発できる環境では意図的なデータワイプにもなり得る。

### 再現手順

1. テストで `SecureKeyStore.read` が一度だけ `PlatformException` を投げるフェイクを注入して `DatabaseManager.initialize()` を呼ぶ。
2. 既存の暗号化ボックスが `deleteBoxFromDisk` で破棄され、`recoveredFromKeyFailure == true` になることを確認する (`test/unit/database_manager_recovery_test.dart` の枠組みで再現可能)。
3. 実機では「端末再起動直後の Direct Boot 状態でアプリが起動された場合」が該当パス。

### 推奨対策

1. 破壊的復旧の対象を「鍵が確かに破損している」と判定できる例外 (例: 保存値はあるが base64 復号に失敗 / Keystore が `unwrap` に恒久失敗) に限定し、`PlatformException` 等は **リトライ + 起動失敗 (既存の `_BootErrorView`)** へ倒す。
2. 少なくとも 1 回の再試行 (短い backoff) を挟む。
3. 破壊的復旧を行う前にユーザーへ通知し、明示的な同意を得るフローを検討する。

---

## Finding 4: アプリロックのフェイルオープン設計 (認証不能時に自動解錠)

- **リスクレベル**: Medium-Low (物理アクセス攻撃者に対する防御の弱体化)
- **修正難易度**: 低〜中
- **複雑性**: 中 (締め出し回避とのトレードオフ)
- **対象**: `lib/features/lock/app_lock_gate.dart:64-74`, `lib/repositories/biometric_auth.dart:21-27`

### 内容

```dart
// app_lock_gate.dart
if (!await auth.isAvailable()) {
  ... _unlocked = true;   // 認証不能なら解錠
}
```

```dart
// biometric_auth.dart
Future<bool> isAvailable() async {
  try {
    return await _auth.isDeviceSupported();
  } catch (_) {
    return false;   // 例外 → 「利用不可」→ 上記で解錠
  }
}
```

`isDeviceSupported()` が `false` を返すか **例外を投げただけ** でロックが解除される。意図的な締め出し回避 (コメント記載) だが、次の問題がある:

1. `local_auth` プラグインの一時的なエラー (`PlatformException`) がそのまま「認証不要」に変換される。
2. 端末側の画面ロックを解除 (None に設定) するとアプリロックが事実上無効化される。端末 PIN を知る同居者・近親者など「端末は触れるがアプリロックで守りたい」という、まさにこの機能の想定脅威に対して防御にならないケースがある。
3. フェイルオープンへ倒れたことがユーザーへ通知されない。

### 再現手順

1. アプリロックを有効化する。
2. 端末設定で画面ロックを「なし」に変更する (生体情報も削除される)。
3. アプリを起動 → 認証なしでヘルスデータが表示される (`isDeviceSupported()` が false のため)。

### 推奨対策

1. 例外時は「利用不可 → 解錠」ではなく「再試行ボタン付きのロック画面に留める」へ変更する (例外と「真に非対応」を区別)。
2. 端末ロック解除によるフェイルオープン時は、ロック画面に「端末の画面ロックが無効のためアプリロックを一時解除しました」と明示し、再有効化を促す。
3. 締め出し回避が必要なら「全データ削除して開く」を逃げ道として提供する選択肢もある (データはHealth Connect から再同期可能なため)。

---

## Finding 5: アプリロック有効フラグが平文ボックスに保存され改ざん可能

- **リスクレベル**: Low (前提: 端末のファイルシステムへの書き込みアクセス)
- **修正難易度**: 低
- **複雑性**: 低
- **対象**: `lib/providers/app_lock_provider.dart` (`app_sync_metadata` ボックスの `app_lock_enabled` キー)

### 内容

アプリロックの有効フラグが **平文の** Hive ボックス `app_sync_metadata` に保存されている。ルート化端末やフォレンジックアクセスが可能な環境では、このファイルの 1 値を `false` に書き換えるだけでロック UI を恒久的に無効化できる。暗号化ボックス自体は Keystore の鍵がないと読めないため直接のデータ流出にはならないが、ロック迂回後はアプリが正規に復号して表示してくれる。

また `changes_token` / `last_sync_time` も平文だが、これらの機密性は低い (許容範囲)。

### 再現手順

1. ルート化端末またはエミュレータでアプリロックを有効化する。
2. `run-as` / root で `app_flutter/app_sync_metadata.hive` 内の `app_lock_enabled` を削除または false に書き換える。
3. アプリ再起動 → ロック画面が表示されずヘルスデータが閲覧できる。

### 推奨対策

ロックフラグを暗号化ボックスまたは `flutter_secure_storage` に保存する。もしくは「フラグが読めない/欠落している場合はロック有効として扱う」既定値の反転でも改善する。

---

## Finding 6: GitHub Actions ワークフローに `permissions:` 最小化がない

- **リスクレベル**: Low
- **修正難易度**: 低
- **複雑性**: 低
- **対象**: `.github/workflows/ci.yml`, `distribute.yml`, `build-aab.yml`

### 内容

全ワークフローで `permissions:` ブロックが未指定のため、`GITHUB_TOKEN` はリポジトリ既定 (多くの場合 read/write) の権限で発行される。Finding 2 のサードパーティ Action や依存ツールチェーン (pub パッケージの build_runner 等、ビルド時にコード実行する) が侵害された場合、トークンでリポジトリへの書き込み (コード改ざん・リリース作成) まで可能になる。

### 推奨対策

各ワークフローのトップレベルに `permissions: contents: read` を明示する (現状のジョブはどれも書き込みを必要としていない)。

---

## Finding 7: release ビルドのデバッグ署名への暗黙フォールバック

- **リスクレベル**: Low
- **修正難易度**: 低
- **複雑性**: 低
- **対象**: `android/app/build.gradle.kts:65-75`

### 内容

`key.properties` が無い場合、`flutter build apk --release` が **警告なくデバッグ鍵で署名** される。デバッグ鍵は公開された周知の鍵であり、この APK を誤って配布 (手渡し・サイドロード等) すると、同じ鍵で署名した悪性 APK による「正規アップデート」偽装が可能になる。Play 経由の配信は Play 側の署名検証で守られるため、リスクは限定的だが、`#121` の利便性とのトレードオフとして「サイレント」である点が問題。

### 推奨対策

フォールバック時にビルドログへ `logger.warn` で明示的な警告を出す。CI (`CI=true` 環境変数) では `key.properties` 欠落をエラーにする。

---

## Finding 8: タップジャッキング (オーバーレイ) 対策の欠如

- **リスクレベル**: Low (Android 12+ はシステム緩和あり)
- **修正難易度**: 中
- **複雑性**: 中
- **対象**: `MainActivity.kt` / ロック画面・データ削除ダイアログ

### 内容

`View#setFilterTouchesWhenObscured` 相当の対策がなく、`SYSTEM_ALERT_WINDOW` を持つ悪性アプリがオーバーレイ越しに「全データを削除」確認ダイアログ (`settings_view.dart:285`) やロック解除ボタンへのタップを誘導できる可能性がある。minSdk 26 のため Android 8〜11 の端末では緩和が弱い。

### 推奨対策

ルートビューに `filterTouchesWhenObscured=true` を設定する (Flutter では `MainActivity` の `FlutterView` に対して設定)。destructive 操作 (全データ削除) の確認に生体認証を要求するのも有効。

---

## Finding 9 (Info): HiveAesCipher (AES-CBC) は完全性検証を持たない

`HiveAesCipher` は AES-256-CBC で機密性は確保するが、MAC/AEAD による完全性検証がない。ファイル改ざんが検知されず、不正なデータがアプリにロードされ得る (ローカル攻撃者前提のため実害は限定的)。将来的に AES-GCM ベースの cipher 実装への差し替えを検討。修正は独自 `HiveCipher` 実装が必要で難易度は中。

## Finding 10 (Info): ルート化検出 / Play Integrity 未導入

CASA (Cloud Application Security Assessment) や Play のヘルスアプリ要件のレベルによっては、ルート化端末での動作警告や Play Integrity API によるアプリ完全性確認が求められる場合がある。現状は未導入。申請する CASA Tier の要件を確認のうえ判断する。

## Finding 11 (Info): Firebase API キーのリポジトリコミット

`android/app/google-services.json` と `lib/firebase_options.dart` に Firebase API キー (`AIzaSy...`) がコミットされている。**Firebase の Android API キーは設計上シークレットではなく**、これ自体は脆弱性ではない。ただし以下を推奨:

1. Google Cloud Console で API キーに **Android アプリ制限** (パッケージ名 + SHA-1) を設定する。
2. Firebase プロジェクトで使用しないサービス (Firestore 等) のルールが閉じていることを確認する。

---

## 問題なしと確認した項目 (参考)

- **バックアップ除外**: `allowBackup=false` + `dataExtractionRules` で file/database/sharedpref/external を cloud-backup・device-transfer の両方から全除外 ✓
- **ヘルス権限の最小化**: READ_SLEEP / READ_STEPS / READ_HEART_RATE / READ_HEALTH_DATA_HISTORY のみ。WRITE・バックグラウンド読み取りなし ✓
- **ヘルスデータの非ログ出力**: `lib/` 内の log/print は `main.dart:67` の Firebase 初期化エラーのみ。同期例外も意図的に非出力 (`health_sync_repository.dart:475`) ✓
- **暗号鍵管理**: `Hive.generateSecureKey()` (CSPRNG) + `flutter_secure_storage` v10 (Keystore 連携)。鍵のハードコードなし ✓
- **エクスポートコンポーネント**: `MainActivity` (launcher + HC rationale、必須) と `ViewPermissionUsageActivity` (システム権限 `START_VIEW_PERMISSION_USAGE` で保護) のみ ✓
- **ネットワーク**: ヘルスデータの外部送信なし。`usesCleartextTraffic` 未設定 (targetSdk 36 で既定 false) ✓
- **URL 起動**: `url_launcher` は定数 URL (https/mailto) のみ。外部入力の URL 起動なし ✓
- **依存パッケージ**: 主要パッケージ (flutter_secure_storage 10.3.1, local_auth 3.0.1, health 13.3.1, hive_ce 2.19.3, firebase_core 4.10.0) はいずれも現行メジャーで、既知の重大 CVE 該当なし ✓
- **CI のシークレット取り扱い**: Secrets は `run` への直接展開を避け env 経由で参照、`build-aab` は main/develop に実行制限、`build_number` 入力は数値検証あり ✓
