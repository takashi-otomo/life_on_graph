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
3. **セキュリティチェックリスト (`docs/security_checklist.md`) で、変更に関係する項目を確認する**
4. 必要に応じて README / docs を更新する
5. Git にコミットする (意味のある単位)

### 開発完了後
1. 作業ブランチは **`develop` から切り**、PR は **`develop` 向け**に作成する
2. `develop` マージ → テスト版が Firebase App Distribution (`testers`) へ自動配信
3. テスト OK 後に `develop` → **`main`** へ PR。`main` マージ → 製品候補配信 + Google Play 提出用 AAB 生成
4. 機密データのハードコードや鍵の混入がないことを確認する
5. ブランチ戦略・配信の詳細は `docs/release.md` を参照

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

### セキュリティチェックの運用
- **品質チェック (PR 作成前 / マージ前) では `docs/security_checklist.md` を参照する**。これがセキュリティ確認の正となるルールである。
- チェックリストは機密性・暗号化/鍵管理・認証・マニフェスト/権限・CI/サプライチェーン・依存パッケージ・データ削除の各カテゴリを網羅する。各項目の背景は初回監査レポート `docs/security_findings.md` を参照。
- 新しい脆弱性や対策を見つけたら、`docs/security_checklist.md` に項目を追記して継続的に更新する。
