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
5. `main` への push で **製品候補 APK** が `production` へ配信される。アップロード鍵 (keystore) Secret が設定済みなら **署名済み AAB** も成果物として生成される (未設定時はスキップ。#121)。
6. その署名済み AAB を **Google Play** (内部テスト→製品トラック) に提出してリリースする。

> 配信ジョブはビルド前に `dart format` / `flutter analyze` / `flutter test` を実行し、**テストが通った場合のみ配信**する。

> 旧運用 (作業ブランチを `main` から切る) から変更。今後の起点は `develop`。

## Firebase App Distribution

CI: [`.github/workflows/distribute.yml`](../.github/workflows/distribute.yml)

`develop` / `main` への push で APK をビルドし、[wzieba/Firebase-Distribution-Github-Action](https://github.com/wzieba/Firebase-Distribution-Github-Action) で配信する。

### 必要な GitHub Secrets
| Secret | 内容 |
|---|---|
| `FIREBASE_ANDROID_APP_ID` | Firebase アプリ ID: `1:563091576174:android:37f82d768fadf1cbbadd7f` |
| `FIREBASE_SERVICE_ACCOUNT` | **Firebase App Distribution 管理者** ロールを持つサービスアカウントの JSON 鍵 (全文) |

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

## Google Play リリース (main)

- `main` への push で生成される **AAB** (`app-release-aab` 成果物) を Google Play Console に提出する。
- **注意**: 現状 `release` ビルドはデバッグ署名を流用している。Play 提出には **アップロード鍵 (keystore) による署名** が必要。
  keystore を用意し `android/app/build.gradle.kts` に署名設定を追加 + GitHub Secrets (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_*`) を登録する作業を別 Issue で対応する。
- 署名 + Play Developer API のサービスアカウントを用意すれば、`r0adkll/upload-google-play` 等で Play 内部トラックへの自動アップロードも可能 (将来拡張)。
