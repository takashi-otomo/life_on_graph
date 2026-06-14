# Life On Graph (LOG) — 開発ガイド

このファイルは本プロジェクト固有の開発ルールおよび AI 開発支援 (Claude Code) 向けの指針です。
**親ディレクトリ `/Users/takashi/claude/CLAUDE.md` は別プロジェクトのものであり、本プロジェクトには適用しません。**

## プロジェクト概要

Android ヘルスコネクトから睡眠・歩数・脈拍 (心拍) データを取得し可視化する Flutter アプリ。
データはクラウドに送信せず、端末内の暗号化ローカル DB (Hive) に永続化する **ローカルファースト** 設計。

## 開発ルール

### 基本方針
- git を使ったバージョン管理を行う
- 1 タスクごとにコミットし、コミットメッセージは簡潔に書く
- ヘルスケアデータは最高機密として扱い、ログ出力や外部送信を行わない (データ最小化原則)

### コーディング前
1. 仕様を満たすテストを作成する
2. テストが通る最小限の実装を行う (TDD)

### コーディング後
1. コードをフォーマットにかけ、リントエラーをゼロにする (`dart format` / `flutter analyze`)
2. テストを実行しすべてグリーンであることを確認する
3. 必要に応じて README / docs を更新する
4. Git にコミットする (意味のある単位)

### 開発完了後
1. 作業ブランチは **`develop` から切り**、PR は **`develop` 向け**に作成する
2. `develop` マージ → テスト版が Firebase App Distribution (`testers`) へ自動配信
3. テスト OK 後に `develop` → **`main`** へ PR。`main` マージ → 製品候補配信 + Google Play 提出用 AAB 生成
4. 機密データのハードコードや鍵の混入がないことを確認する
5. ブランチ戦略・配信の詳細は `docs/release.md` を参照

### 🔒 `main` へのマージ規則 (最重要・例外なし)
**`main` への PR マージは、本人 (リポジトリ所有者) が「その PR をマージしてよい」と本会話内で
明示的に許可するまで、AI/自動化を含め誰も実行してはならない。** `main` マージは製品版の
公開 (Google Play / production 配信) に直結するため、必ず人間の最終承認を要する。

AI 開発支援 (Claude Code 等) は以下を厳守する:
1. `main` 向けの作業は **PR の作成までで停止**し、PR URL を報告して**指示を待つ**。
   `gh pr merge` 等のマージ操作を**勝手に実行しない**。
2. 「マージして」等の一般的な依頼は **`develop` 向けにのみ**適用する。`main` は対象外。
3. `main` をマージしてよいのは、ユーザーが**当該 PR を特定して**「`main` にマージしてよい」と
   明示した場合**のみ**。曖昧なときは必ず確認する。過去の許可は次回に引き継がれない (毎回必要)。
4. `main` への直接 push・force push・`--admin` 等での保護回避マージも禁止。
5. 技術的ガードレールとして GitHub のブランチ保護 (ルールセット) を併用する
   (PR 必須 + CI 必須)。詳細は `docs/release.md`「main 保護ルール」。

> `develop` への通常のマージは従来どおり (CI 緑を確認のうえ可)。本規則は `main` 限定。

## 技術スタック

- **フレームワーク**: Flutter (Dart)
- **対象 OS**: Android (Health Connect)。iOS は将来拡張余地を残す
- **ヘルス連携**: `health` パッケージ
- **状態管理**: Riverpod
- **ローカル永続化**: Hive CE (`hive_ce` / 本家 Hive の後継・API 互換) + `HiveAesCipher` (AES-256)
- **鍵管理**: `flutter_secure_storage` (Android Keystore 連携)
- **可視化**: `fl_chart` / 睡眠ステージ用チャート
- **コード生成**: `build_runner`

## アーキテクチャ (レイヤ構成)

```
Presentation (Widgets / Riverpod Providers)
   ↓
Application (UseCase / Notifier)
   ↓
Repository (HealthSyncRepository)  ← ヘルスコネクト ⇄ ローカル DB を仲介
   ↓
Data Source
   ├─ HealthConnect (health パッケージ)
   └─ LocalDB (Hive: DatabaseManager)
```

- UI は常にローカル DB から即時描画し、背後で差分同期を非同期実行する。
- ヘルスコネクトの `uuid` を Hive のキーにして重複を排除する。

## ディレクトリ構成 (予定)

```
lib/
  main.dart
  core/            # DB マネージャ、暗号鍵、定数
  models/          # Hive モデル (+ .g.dart 生成物)
  repositories/    # 同期・クレンジングロジック
  providers/       # Riverpod プロバイダ
  features/
    sleep/         # 睡眠可視化
    steps/         # 歩数可視化
    heart_rate/    # 脈拍可視化
  widgets/         # 共通 UI
docs/              # 要件・設計・タスク
test/              # ユニット / ウィジェットテスト
```

## テスト戦略
- ロジック層 (同期・クレンジング) を中心に TDD で実装
- Jest ではなく Flutter 標準の `test` / `flutter_test` を使用
- ヘルスコネクト・Hive はモック / フェイクで差し替えてテスト

## コーディング規約
- `dart format` + `flutter analyze` (lints) でスタイルを統一
- 公開 API には Dart Doc コメントを付与
- 機密データはログに出力しない

## セキュリティ / コンプライアンス指針
- Hive は必ず `HiveAesCipher` で暗号化する
- 暗号鍵は `flutter_secure_storage` 経由でのみ取り扱う
- 申請するヘルスパーミッションは睡眠・歩数・心拍に**限定**する (不要権限の申請は審査却下要因)
- Google Play「ヘルスの申告 (Health Apps Declaration)」、プライバシーポリシー、CASA 監査要件を考慮する (詳細は docs/02_design.md)
