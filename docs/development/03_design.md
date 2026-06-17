# 03. 設計 (Design)

一次情報は [`docs/02_design.md`](../02_design.md)。本章は図を中心に設計判断を解説する。

## 3.1 レイヤ構成

依存方向は上位 → 下位の一方向。Repository をインタフェース化し、将来のクラウド同期や
iOS 対応でデータソースを差し替えられるようにした。

```mermaid
flowchart TD
    subgraph P["Presentation"]
        W["Widgets (features/*)"]
        C["Riverpod Consumer"]
    end
    subgraph A["Application"]
        N["SyncNotifier"]
        DP["派生 Provider<br/>sleepSegments / steps / heartRate"]
    end
    subgraph R["Repository"]
        HSR["HealthSyncRepository<br/>(interface)"]
        IMPL["HealthSyncRepositoryImpl"]
    end
    subgraph DS["Data Source"]
        HC["HealthClient (health pkg)"]
        DBM["DatabaseManager (Hive)"]
    end
    W --> C --> N --> HSR
    C --> DP --> HSR
    HSR --- IMPL
    IMPL --> HC
    IMPL --> DBM
```

| レイヤ | 責務 | 主なクラス |
| --- | --- | --- |
| Presentation | UI 描画・操作 | `DashboardView`, `SummaryView`, 各 `*Chart` |
| Application | 状態保持・調整 | `SyncNotifier`, 派生 Provider 群 |
| Repository | 同期・クレンジング・変換 | `HealthSyncRepository` |
| Data Source | 外部 I/O | `HealthClient`(health), `DatabaseManager`(Hive) |

## 3.2 ディレクトリ構成 (実際)

```
lib/
  main.dart            # Hive/SecureStorage 初期化 → runApp、セマンティクス常時 ON
  core/                # DatabaseManager, 暗号鍵, 定数 (AppConstants), 配色
  models/              # Hive モデル (+ *.g.dart 生成物)
  repositories/        # health_sync_repository / cleansing / health_client
  providers/           # Riverpod プロバイダ群
  features/
    splash/ onboarding/ rationale/ tutorial/ lock/   # 導入・権限・チュートリアル・ロック
    dashboard/ sleep/ steps/ heart_rate/ cross_data/  # 可視化
    summary/ calendar/ settings/                      # 期間集計・日付移動・設定
  l10n/                # 6言語 ARB + 生成物
  widgets/             # 共通 UI (capsule_tab_bar 等)
```

## 3.3 データモデル

ヘルスコネクトの `SleepSessionRecord` は「全体セッション」と「ステージ配列」の 2 階層だが、
本アプリは **ステージ単位に正規化**して保存する (二重計上を避けるため `SLEEP_SESSION`
エンベロープは保存対象外)。

```mermaid
erDiagram
    SLEEP_RECORD {
        string uuid PK "Health Connect 発行 ID"
        datetime startTime
        datetime endTime
        string stageType "deep/light/rem/awake/..."
        string sourcePackage "競合判定用"
    }
    STEPS_RECORD {
        string uuid PK
        datetime startTime
        datetime endTime
        int count
        string sourcePackage
    }
    HEART_RATE_RECORD {
        string uuid PK
        datetime startTime
        datetime endTime
        int beatsPerMinute
        string sourcePackage
    }
```

- `uuid` を **Hive のキー**にすることで、`Box.put(uuid, record)` の上書きが
  そのまま**重複排除**になる (再同期しても増殖しない)。
- `*.g.dart` アダプタは `build_runner` で生成。

## 3.4 ローカル永続化 (Hive CE)

- 本家 Hive のメンテ停滞を受け、API/オンディスク互換の後継 **Hive CE** を採用
  (新しい analyzer・Flutter 3.44.1 対応)。
- ボックス: `encrypted_sleep_records` / `encrypted_steps_records` /
  `encrypted_heart_rate_records` (いずれも `HiveAesCipher` で **AES-256 暗号化**) +
  `app_sync_metadata` (`last_sync_time` 等の軽量メタ)。
- 暗号鍵は `flutter_secure_storage` (Android Keystore 連携) に base64 保存。未生成時のみ
  `Hive.generateSecureKey()` で生成。鍵はコードにもログにも出さない。
- `DatabaseManager` をシングルトン化し、`main()` の `await initialize()` で開通。

## 3.5 インクリメンタル同期

```mermaid
sequenceDiagram
    autonumber
    participant UI as Dashboard
    participant N as SyncNotifier
    participant R as HealthSyncRepository
    participant HC as Health Connect
    participant DB as Hive

    UI->>UI: 起動直後ローカルから即描画 (待たない)
    UI->>N: sync() (postFrame)
    N->>R: configure / requestPermissions / ensureHistoryPermission
    R->>R: computeSyncWindow(now)
    Note over R: 初回=過去90日(履歴) / 30日(無)<br/>2回目以降=max(last_sync, now-7日)
    loop 種別ごと・時間チャンクごと
        R->>HC: getHealthData(type, chunk)
        HC-->>R: data points
        R->>R: 心拍は1分1サンプルに間引き
        R->>DB: putAll(uuid → record)
        R-->>N: onProgress(種別/件数/割合)
    end
    R->>DB: last_sync_time = now
    R-->>N: SyncOutcome
    N-->>UI: dataRevision++ → 派生Provider 再評価 → 自動再描画
```

**設計上の要点**

- **差分の極小スキップ**: 前回同期から 5 分未満ならクエリせず即リターン (省電力)。
- **2 回目以降は過去 7 日上限**: 長期間未起動でも起動時前景同期が重くならないよう、
  差分開始を `max(last_sync, now-7日)` にクランプ。取りこぼした古い履歴は設定の
  「全データ再読み込み」で回収できる退避路を残す。
- **チャンク分割**: 全期間一括取得はメモリを圧迫するため、種別ごとに日数でチャンク化し
  「取得 → 保存 → 解放」を反復。特に**心拍は 1 日チャンク + 1 分間引き**で OOM を回避
  ([09](09_topics_and_learnings.md) のクラッシュ調査参照)。

## 3.6 クレンジングパイプライン

複数ソースが同じ時間帯を二重に書く前提で、読み出し時に整形する。

```mermaid
flowchart LR
    RAW["生レコード<br/>(複数ソース混在)"] --> S1["① ソース優先順位<br/>信頼ソースを採用"]
    S1 --> S2["② 境界クリッピング<br/>表示枠(正午〜翌正午)に切出し"]
    S2 --> S3["③ オーバーラップ解消<br/>重複は長いセグメント優先"]
    S3 --> S4["④ 隣接結合<br/>30秒未満の同一ステージを統合"]
    S4 --> CLEAN["クレンジング済み<br/>1本の睡眠タイムライン"]
```

「唯一のソースしか無い」場合はフェイルオープン (採用) し、データ消失を避ける。

## 3.7 クロスデータ統合 (FR-7)

睡眠・心拍・歩数は関連 ID を持たないため、**睡眠終点を右端とした 24 時間**の共通軸に
3 種をマッピングして 1 画面に重ねる (日中の活動〜夜間の睡眠を俯瞰)。

```mermaid
flowchart TD
    SL["睡眠セグメント"] --> WIN["共通時間窓<br/>(睡眠終点-24h 〜 睡眠終点)"]
    HR["心拍"] --> WIN
    ST["歩数"] --> WIN
    WIN --> LANE["縦割りレーン描画<br/>心拍 / 睡眠 / 歩数"]
    Note["睡眠が無くても心拍/歩数の<br/>最新時刻基準で描画。<br/>3種とも空のときだけ非表示"]:::n -.-> WIN
    classDef n fill:#f6f8fa,stroke:#999,color:#333;
```

- 心拍ラインは**データ欠落区間 (10 分超のギャップ) で線を分断**し、空白を直線補間で
  繋がない (孤立点はドット)。誤読を防ぐための UX 配慮 ([04](04_uiux_and_ai.md))。

## 3.8 状態管理 (Riverpod)

```mermaid
flowchart TD
    DBP["databaseManagerProvider"] --> RP["healthSyncRepositoryProvider"]
    RP --> SN["syncNotifierProvider<br/>(idle/syncing/done/partial/error)"]
    SN --> REV["dataRevisionProvider<br/>(同期完了世代カウンタ)"]
    REV --> D1["sleepSegmentsProvider(date)"]
    REV --> D2["stepsProvider(range)"]
    REV --> D3["heartRateProvider(range)"]
    D1 & D2 & D3 --> UI["Widgets が watch → 自動再描画"]
```

- **ローカルファースト**: 派生 Provider はローカル DB から即時取得。同期が**終了した時のみ**
  `dataRevision` をインクリメントし、syncing 中の不要な再走査を避ける。
- `StateProvider` は使わず `Notifier` / `NotifierProvider` に統一 (Riverpod 3)。

## 3.9 エラーハンドリング / フォールバック

| 状況 | 対応 |
| --- | --- |
| ヘルスコネクト未導入 | Play ストアへの導入導線を提示 |
| 権限未許可 | Rationale (機能説明) を表示し再申請導線 |
| 履歴権限なし | バックフィルを過去 30 日に制限 |
| 一部種別の取得失敗 | 成功分は保存・`last_sync_time` は前進させず次回再取得。UI はフォールバック表示 |
