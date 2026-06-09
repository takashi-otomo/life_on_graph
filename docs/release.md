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

## バージョン番号 (versionCode) の運用

Google Play は **versionCode の重複を許さない**ため、アップロードのたびに増やす必要がある。

- **ローカルビルド**: [`tool/build_release.sh`](../tool/build_release.sh) がビルドのたびに
  `pubspec.yaml` の `version: <name>+<code>` の `<code>` を +1 してからビルドする(変更はコミット)。
  ```sh
  tool/build_release.sh            # versionCode を +1 して AAB をビルド
  tool/build_release.sh apk        # 同上で APK
  tool/build_release.sh aab --keep # 増分せず現在値でビルド
  ```
- **CI**: `distribute.yml` / `build-aab.yml` は `--build-number=$((10000 + run number))` で実行ごとに
  一意・増加する versionCode を自動付与する(手動バンプ不要)。
- **番号帯の分離**: ローカル手動アップロードは **10000 未満**(`build_release.sh` の小さい番号)、
  CI は **10000 以上**を用いるため、両者の versionCode が衝突しない。初回手動アップロードを
  versionCode 1 で行っても、CI の初回公開 (10001〜) が必ずそれを上回る。
- Play へ実アップロードする versionCode は常に増加させること。

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

# 3. 署名済み AAB をビルド (build-number は Play の versionCode。重複不可)
flutter build appbundle --release --build-number=1
# 出力: build/app/outputs/bundle/release/app-release.aab
```

生成された `app-release.aab` を Play Console にアップロードする。
`android/key.properties` と `*.jks` は `.gitignore` 済みでコミットされない。

## Google Play 公開のセットアップ

1. Google Play Console で対象アプリ (`dev.otomo.life_on_graph`) を作成し、**最初の AAB を手動アップロード**して内部テスト等で審査を通す (Play の初回制約)。
2. [Play Console → API アクセス](https://play.google.com/console) で Google Cloud のサービスアカウントを連携し、リリース権限を付与。
3. そのサービスアカウント JSON を `PLAY_SERVICE_ACCOUNT` Secret に登録。
4. 以降 `main` マージで [r0adkll/upload-google-play](https://github.com/r0adkll/upload-google-play) が **production トラックへ自動公開**する。

> 段階公開したい場合は `distribute.yml` の `status: completed` を `inProgress` + `userFraction` に変更する。
