# 08. デリバリー (Delivery) — リリース手順

一次情報は [`docs/release.md`](../release.md)。本章は全体フローを図で俯瞰する。

## 8.1 ブランチ戦略

```mermaid
flowchart LR
    F["feature/*<br/>fix/*"] -->|PR| DEV["develop<br/>(テスト版)"]
    DEV -->|"自動"| AD1["Firebase App Distribution<br/>→ testers"]
    DEV -->|"PR + 人間承認"| MAIN["main<br/>(製品版)"]
    MAIN -->|"自動"| AD2["App Distribution<br/>→ production"]
    MAIN -->|"自動 (署名AAB)"| PLAY["Google Play<br/>(production)"]
    MAIN -.->|"version 引き継ぎ"| DEV
```

- 作業ブランチは **`develop` から切り**、PR は **`develop` 向け**。
- `develop` マージ → テスト版 APK を `testers` へ自動配信。
- テスト OK 後に `develop` → **`main`** へ PR。`main` マージ → 製品配信 + Play 公開。
- **`main` マージは人間の明示承認が必須** (後述 §保護)。

## 8.2 CI/CD パイプライン

```mermaid
flowchart TD
    PUSH["push / PR"] --> GUARD["guard<br/>(必要 Secret の有無を判定)"]
    GUARD --> CI["dart format / analyze / test"]
    CI --> BR{"ブランチ?"}
    BR -->|develop| BUMP1["patch +1 を書き戻し"]
    BUMP1 --> APK1["APK ビルド"] --> T1["App Distribution: testers"]
    BR -->|main| BUMP2["minor +1 / patch 0"]
    BUMP2 --> SIGN["署名鍵を Secrets から復元"]
    SIGN --> WN["whatsnew プレフライト検証"]
    WN --> APK2["署名 APK → production"]
    APK2 --> AAB["署名 AAB ビルド"]
    AAB --> PUB["Google Play publish<br/>(track/段階公開は変数で可変)"]
    PUB --> CARRY["main の版を develop へ引き継ぎ"]
```

- **guard ジョブ**: 必要な Secret が未登録の間は該当ジョブをスキップ (設定前の push を
  赤くしない)。`firebase` / `signing` / `play` の 3 段階で有効化される。
- **テスト通過が配信の門**: `dart format` / `flutter analyze` / `flutter test` 緑のときのみ配信。
- **whatsnew プレフライト**: Play 公開前に言語別リリースノートを検証 (上限 500 字 / 必須 6
  ロケール / 空) し fail-fast。

## 8.3 バージョニング (SemVer + 自動採番)

| 契機 | versionName | 例 |
| --- | --- | --- |
| `develop` への push | **PATCH +1** | 1.2.3 → 1.2.4 |
| `main` への push (リリース) | **MINOR +1 / PATCH 0** | 1.2.4 → 1.3.0 |
| リリース後 | main の版を develop へ引き継ぎ | develop も 1.3.0 |

- `versionCode` は **git コミット数 + 100000** から自動採番 (単調増加・手動バンプ不要・
  Play 重複回避)。
- バージョン更新コミットは `[skip ci]` 付きで書き戻し、無限ループを防ぐ。

## 8.4 リリースノート

- **App Distribution**: `tool/release_notes.sh` が git 履歴 (`feat:`/`fix:`) から自動生成。
- **Google Play**: `distribution/whatsnew/whatsnew-<locale>` を言語ごとに管理 (6 言語)。
  `tool/play_release_notes.sh` で言語タグ付き結合テキストも生成できる。

## 8.5 Google Play 自動公開のセットアップ

```mermaid
flowchart LR
    A["① アプリ作成 +<br/>初回 AAB 手動アップロード<br/>+ 申告(データ安全性等)"] --> B["② SA 作成 + 権限付与"]
    B --> C["③ PLAY_SERVICE_ACCOUNT<br/>を Secret 登録"]
    C --> D["④ 認証検証WF<br/>(play-validate.yml)"]
    D --> E["⑤ main マージで自動公開"]
```

- Play API は**既存アプリの新リリース**しか作れないため、最初の 1 本と各種申告は手動。
- 公開トラック/段階公開は **Repository variables** (`PLAY_TRACK` / `PLAY_STATUS` /
  `PLAY_USER_FRACTION`) でコード変更なしに切替可能 (internal / 段階 / draft)。
- `play-validate.yml` で SA の API アクセスを**変更を加えずに**検証してから本番に進める。

## 8.6 main 保護 (人間の承認を経たマージのみ)

製品公開に直結する `main` は二層で守る。

```mermaid
flowchart TD
    subgraph L1["① 行動ルール (CLAUDE.md)"]
        A["AI は main 向けは<br/>PR 作成までで停止"]
        B["『マージして』は develop のみ"]
        C["main は当該 PR を指定した<br/>明示承認時のみマージ (毎回)"]
    end
    subgraph L2["② GitHub ブランチ保護 (ruleset)"]
        D["PR 必須"]
        E["CI 必須 (Analyze & Test)"]
        F["force push / 削除 禁止"]
    end
```

> AI は所有者の認証情報で動くため GitHub からは所有者と区別できない。よって**実効的な
> 抑止は①の行動ルール**で、②は「全変更を PR + CI 緑」に強制するガードレールとして併用する。

## 8.7 その他の配信物

- **公式サイト + プライバシーポリシー**: Firebase Hosting に `website/` を main マージで
  自動デプロイ (`deploy-website.yml`)。
- **ストア掲載アセット**: 6 言語のスクリーンショット・説明・フィーチャーグラフィック
  (`docs/store/`)。
