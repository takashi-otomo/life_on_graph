# Life On Graph (LOG)

Android の **ヘルスコネクト (Health Connect)** に接続し、**睡眠・歩数・脈拍 (心拍)** データを取得・可視化する Flutter アプリケーションです。

すべてのデータ処理は端末内で完結する **ローカルファースト (Local-First)** アーキテクチャを採用し、取得したデータは AES-256 で暗号化したローカル DB (Hive) に永続化します。クラウドへのデータ送信は行いません。

---

## 主な特徴

- 📊 **3 種のヘルスデータ可視化**: 睡眠ステージ・歩数・脈拍 (心拍)
- 🔒 **ローカル完結 / 暗号化永続化**: Hive (AES-256) + `flutter_secure_storage` による鍵管理
- ⚡ **ローカルファースト**: 端末 DB から即時描画し、背後で差分同期
- 🔁 **インクリメンタル同期**: ヘルスコネクトの UUID をキーに重複を排除した増分取得
- 🧹 **データクレンジング**: 複数ソース間の重複・はみ出し・隣接セグメントを前処理

## 技術スタック

| 領域 | 採用技術 |
| --- | --- |
| フレームワーク | Flutter (Dart) |
| 対象プラットフォーム | Android (Health Connect) ※ iOS は将来拡張余地を残す |
| ヘルス連携 | [`health`](https://pub.dev/packages/health) |
| 状態管理 | Riverpod |
| ローカル永続化 | Hive + `HiveAesCipher` (AES-256) |
| 鍵管理 | `flutter_secure_storage` (Android Keystore 連携) |
| 可視化 | `fl_chart` / 睡眠ステージ用チャート |
| コード生成 | `build_runner` (Hive アダプタ生成) |

## 動作要件

- Android 9.0 (API 28) 以上 (ヘルスコネクト動作要件)
- minSdkVersion 26 / compileSdkVersion 34
- Android 13 (API 33) 以下では Google Play からの「ヘルスコネクト」アプリ手動インストールが必要
- Android 14 (API 34) 以上では OS にネイティブ統合済み

## セットアップ

> ⚠️ 本リポジトリは現在ドキュメント整備フェーズです。Flutter プロジェクト本体は未生成です。

```bash
# 1. 依存解決
flutter pub get

# 2. Hive アダプタ等のコード生成
flutter pub run build_runner build --delete-conflicting-outputs

# 3. 実機 (Android) で起動
flutter run
```

## ドキュメント

| ドキュメント | 内容 |
| --- | --- |
| [docs/01_requirements.md](docs/01_requirements.md) | 要件定義 |
| [docs/02_design.md](docs/02_design.md) | アーキテクチャ・設計 |
| [docs/03_tasks.md](docs/03_tasks.md) | 開発タスク (暫定 / GitHub Issue 登録元) |
| [CLAUDE.md](CLAUDE.md) | 開発ルール・AI 開発支援向け指針 |

## ライセンス

未定 (TBD)
