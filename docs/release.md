# リリース運用 / ブランチ戦略

## ブランチ戦略

| ブランチ | 用途 | 配信先 |
|---|---|---|
| `feature/*`, `fix/*` 等 | 開発作業 | (なし。PR で `develop` へ) |
| `develop` | **テスト版** の統合先 | Firebase App Distribution → `testers` グループ |
| `main` | **製品版** (リリース候補) | Firebase App Distribution → `production` グループ → Google Play |

### フロー
1. 作業ブランチを `develop` から切る。
2. PR を **`develop`** 向けに作成 → CI (analyze/test) 緑 + レビュー後マージ。
3. `develop` への push で **テスト版 APK** が App Distribution の `testers` へ自動配信される。
4. テスト OK なら `develop` → **`main`** へ PR してマージ。
5. `main` への push では**署名が設定済みの場合のみ** production 配信を行う(デバッグ署名の製品配布を避けるため)。**署名済み APK** を `production` へ配信し、さらに Play サービスアカウントが設定済みなら **署名済み AAB** を **Google Play (production トラック) へ自動公開**する。versionCode は実行ごとに一意化される。
6. リリースノートは **App Distribution は `tool/release_notes.sh` が git 履歴から自動生成**、**Google Play は `distribution/whatsnew/whatsnew-<locale>` を言語ごとに手動管理**して反映する(詳細は後述「リリースノート」)。

> 配信ジョブはビルド前に `dart format` / `flutter analyze` / `flutter test` を実行し、**テストが通った場合のみ配信**する。

> 初回のみ Google Play Console で対象パッケージ (`dev.otomo.life_on_graph`) のアプリを作成し、最初の AAB を手動アップロード + 内部テスト等で審査を通す必要がある (Play の制約)。以降は main マージで自動公開される。

> 旧運用 (作業ブランチを `main` から切る) から変更。今後の起点は `develop`。

> **二重配信の防止**: `develop` → `main` 昇格後に同じコミットが `develop` へ戻っても、
> その commit が既に `main` 上にある場合は testers 配信をスキップする (`distribute.yml` の
> `testers-gate`)。`main` 公開 (production) と重複しない。

## Firebase App Distribution

CI: [`.github/workflows/distribute.yml`](../.github/workflows/distribute.yml)

`develop` / `main` への push で APK をビルドし、[wzieba/Firebase-Distribution-Github-Action](https://github.com/wzieba/Firebase-Distribution-Github-Action) で配信する。

### 必要な GitHub Secrets
| Secret | 用途 | 内容 |
|---|---|---|
| `FIREBASE_ANDROID_APP_ID` | App Distribution | Firebase アプリ ID: `1:563091576174:android:37f82d768fadf1cbbadd7f` |
| `FIREBASE_SERVICE_ACCOUNT` | App Distribution | **Firebase App Distribution Admin** ロールのサービスアカウント JSON 鍵 (全文) |
| `ANDROID_KEYSTORE_BASE64` | 署名 / Play | アップロード鍵 (keystore) を Base64 化した文字列 |
| `ANDROID_KEYSTORE_PASSWORD` | 署名 / Play | keystore のパスワード |
| `ANDROID_KEY_ALIAS` | 署名 / Play | 鍵エイリアス |
| `ANDROID_KEY_PASSWORD` | 署名 / Play | 鍵のパスワード |
| `PLAY_SERVICE_ACCOUNT` | Play 公開 | Google Play Developer API 権限を持つサービスアカウント JSON (全文) |

> `firebase` 系のみ設定 → App Distribution 配信のみ稼働。`signing` + `play` も揃うと main で Google Play 自動公開が稼働 (いずれも未設定の段階では該当ジョブをスキップして緑のまま)。

### サービスアカウントの作成手順
1. [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts?project=lifeongraph) でサービスアカウントを作成。
2. ロール **Firebase App Distribution Admin** (`roles/firebaseappdistro.admin`) を付与。
3. 鍵 (JSON) を作成しダウンロード。
4. GitHub の **Settings → Secrets and variables → Actions** に `FIREBASE_SERVICE_ACCOUNT` として JSON 全文を登録。
5. `FIREBASE_ANDROID_APP_ID` も同様に登録。

### テスターグループ
[Firebase Console → App Distribution](https://console.firebase.google.com/project/lifeongraph/appdistribution) で以下のグループを作成し、テスターを追加する。
- `testers` — develop (テスト版) の受信者
- `production` — main (製品候補) の確認者

### 手動配信 (ローカル / 初回確認)
```sh
flutter build apk --release
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app 1:563091576174:android:37f82d768fadf1cbbadd7f \
  --groups testers \
  --release-notes "manual build"
```

## リリースノート

### Firebase App Distribution (自動生成)
[`tool/release_notes.sh`](../tool/release_notes.sh) が直近タグ以降 (タグが無ければ直近 30 コミット) の
`feat:` / `fix:` コミットを集計して `release_notes.txt` を生成する。
コミットメッセージ規約 (`feat: ...` / `fix: ...`) に沿って書くと自動反映される。

### Google Play (言語ごとに手動管理)
[`distribution/whatsnew/whatsnew-<locale>`](../distribution/whatsnew/) に**言語ごと**に記述する
(プレーンテキスト・500 字以内)。`main` 公開時に Play の「最新情報」へ反映される。
記述ルールは [`distribution/whatsnew/README.md`](../distribution/whatsnew/README.md) を参照。

## アップロード鍵 (署名) のセットアップ

```sh
# 1. アップロード鍵を生成 (一度だけ。安全に保管)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
# 2. Base64 化して ANDROID_KEYSTORE_BASE64 Secret に登録
base64 -i upload-keystore.jks | pbcopy
```
`ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` も Secrets に登録する。
CI はこれらから `android/app/upload-keystore.jks` + `android/key.properties` を復元し、`release` ビルドを署名する
(ローカルに `key.properties` が無ければデバッグ署名にフォールバック)。

## バージョン番号の運用

### versionName ([SemVer](https://semver.org/lang/ja/): MAJOR.MINOR.PATCH)
CI が `pubspec.yaml` の versionName をブランチに応じて自動更新する ([`tool/bump_version.sh`](../tool/bump_version.sh))。

| 契機 | 更新 | 例 |
|---|---|---|
| `develop` への push (ビルドごと) | **PATCH +1** | `1.2.3` → `1.2.4` |
| `main` への push (リリース) | **MINOR +1 / PATCH 0** | `1.2.4` → `1.3.0` |
| リリース後 | main の版を **develop へ引き継ぎ** | develop も `1.3.0` に |

- 各更新コミットは `[skip ci]` 付きで該当ブランチへ書き戻され、無限ループしない。
- `main` リリース後は `carry-back-version` ジョブが develop の versionName を main に揃える。
- ローカルビルド (`tool/build_release.sh`) は SemVer を増分しない (CI のみ)。検証用途のため現行 pubspec の版を使う。

### versionCode (Play 用の整数)
- **`git rev-list --count HEAD`(git コミット数)+ ベース 100000** から自動採番する
  (`android/app/build.gradle.kts`)。コミットを重ねるごとに**単調増加**し、ローカル/CI 共通・
  手動バンプ不要・Play の重複も回避する。git が使えない環境では `pubspec.yaml` 値にフォールバック。
- versionName の自動更新コミット自体もコミット数を増やすため、versionCode も連動して増える。

## 初回 AAB をローカルでビルドする

Play は最初の 1 本を手動アップロードする必要がある。署名済み AAB をローカルで生成する手順:

```sh
# 1. アップロード鍵をプロジェクトに配置 (android/app/ 配下。git 管理対象外)
cp upload-keystore.jks android/app/upload-keystore.jks

# 2. android/key.properties を作成 (パスワード等は keystore 生成時の値)
cat > android/key.properties <<'EOF'
storeFile=upload-keystore.jks
storePassword=<キーストアのパスワード>
keyAlias=upload
keyPassword=<鍵のパスワード>
EOF

# 3. 署名済み AAB をビルド (versionCode は git コミット数から自動採番)
tool/build_release.sh
# 出力: build/app/outputs/bundle/release/app-release.aab
```

生成された `app-release.aab` を Play Console にアップロードする。
`android/key.properties` と `*.jks` は `.gitignore` 済みでコミットされない。

## Google Play 公開のセットアップ (main マージ → 自動公開)

`main` マージで自動公開を稼働させるための **完全な手順**。前提①②は Play / GCP 側の手作業
(コードからは実行不可)。③以降を満たすと CI が自動公開する。

### 前提: Play Console でのアプリ初期設定 (初回のみ・手作業)
Play API は **既存アプリの新リリース**しか作れない。最初の 1 本と各種申告は手動で行う。
1. Play Console で対象アプリ (`dev.otomo.life_on_graph`) を作成。
2. **最初の AAB を手動アップロード**する。ローカル生成 (「初回 AAB をローカルでビルドする」節) か、
   手動ワークフロー **`Build signed AAB (manual)`** (`build-aab.yml`) の成果物を使う。
   最低 1 リリースを作る (内部テスト等のトラックでよい)。
3. 公開に必須の申告を完了する (未完だと公開が弾かれる):
   - ストア掲載情報 (6言語: `distribution/` のアセット)、プライバシーポリシー URL
   - **データセーフティ**フォーム、**コンテンツのレーティング**、対象年齢、広告の有無
   - アプリのアクセス権 (健康データ権限の用途説明 / Health Apps Declaration)

### ① サービスアカウントの作成と権限付与 (手作業)
1. [Play Console → 設定 → API アクセス](https://play.google.com/console) で Google Cloud
   プロジェクト (`lifeongraph`) をリンクする。
2. 「サービスアカウントを作成」リンクから [GCP のサービスアカウント](https://console.cloud.google.com/iam-admin/serviceaccounts?project=lifeongraph)
   を作成 (例: `play-publisher`)。**JSON 鍵**を発行・ダウンロード。
3. Play Console の API アクセス画面で、当該サービスアカウントに **アプリ権限を付与**:
   - 対象アプリ `dev.otomo.life_on_graph` を選択
   - 権限: **「製品版へのリリース」「テスト版へのリリース」「アプリ情報の管理」**
4. 反映まで数分かかることがある。

### ② Secret 登録 (手作業)
- GitHub → Settings → Secrets and variables → Actions に **`PLAY_SERVICE_ACCOUNT`** を作成し、
  ①の **JSON 全文**を貼り付ける。これで `distribute.yml` の `guard` が `play=true` になり
  main 公開ステップが有効化される。

### ③ 設定の検証 (任意・推奨)
- 手動ワークフロー **`Validate Google Play credentials (manual)`** (`play-validate.yml`) を
  `main` / `develop` で実行する。変更を加えずに API アクセスを検証し利用可能トラックを表示する。
  失敗時はメッセージに従い ①②、または初回アップロードを見直す。

### ④ 自動公開 (main マージ時)
`main` マージで `release-production` ジョブが署名済み AAB をビルドし
[r0adkll/upload-google-play](https://github.com/r0adkll/upload-google-play) で公開する。
公開前に `tool/check_whatsnew.sh` が言語別リリースノートを検証 (上限500字/必須6言語/空) する。

### 公開トラック / 段階公開の切り替え (コード変更不要)
Settings → Secrets and variables → Actions → **Variables** に設定すると `distribute.yml` が追従:

| 変数 | 既定 | 説明 |
|---|---|---|
| `PLAY_TRACK` | `production` | `internal` / `alpha` / `beta` / `production` |
| `PLAY_STATUS` | `completed` | `completed` (即時100%) / `inProgress` (段階) / `draft` (下書き=手動公開) / `halted` |
| `PLAY_USER_FRACTION` | (なし) | `inProgress` 時の公開割合 (例 `0.1` = 10%) |

> 例: 内部テストだけ自動化 → `PLAY_TRACK=internal`。段階公開 → `PLAY_STATUS=inProgress` +
> `PLAY_USER_FRACTION=0.1`。アップロードのみ自動・公開は手動 → `PLAY_STATUS=draft`。

> production 公開でも Play の審査状況により反映に時間がかかる場合がある。
