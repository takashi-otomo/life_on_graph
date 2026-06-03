# 02. 設計 — Life On Graph (LOG)

本書は [01_requirements.md](01_requirements.md) を満たすためのアーキテクチャ・設計を定義する。

## 1. システム全体像

ヘルスコネクトにはサーバー API が存在せず、すべての読み書きが端末内で完結する。
本アプリは **ローカルファースト** を採用し、ローカル DB (Hive) を一次データソースとして即時描画、
背後でヘルスコネクトとの差分同期を非同期実行する。

```
┌────────────────────────────────────────────┐
│ Presentation (Flutter Widgets)             │
│  - 睡眠 / 歩数 / 心拍ダッシュボード        │
│  - Riverpod Consumer による宣言的描画      │
└───────────────┬────────────────────────────┘
                │ watch / read
┌───────────────▼────────────────────────────┐
│ Application (Riverpod Notifier / UseCase)   │
└───────────────┬────────────────────────────┘
                │
┌───────────────▼────────────────────────────┐
│ Repository: HealthSyncRepository            │
│  - インクリメンタル同期                     │
│  - クレンジングパイプライン                 │
└───────┬──────────────────────┬──────────────┘
        │                      │
┌───────▼────────┐    ┌────────▼─────────────┐
│ HealthConnect  │    │ LocalDB (Hive)        │
│ (health pkg)   │    │ DatabaseManager       │
│  読み取り専用  │    │  AES-256 暗号化        │
└────────────────┘    └───────────────────────┘
```

## 2. レイヤ構成と責務

| レイヤ | 責務 | 主なクラス |
| --- | --- | --- |
| Presentation | UI 描画・ユーザー操作 | `SleepDashboardView`, `StepsView`, `HeartRateView` |
| Application | 状態保持・ユースケース調整 | `SyncNotifier`, `SleepNotifier` (Riverpod) |
| Repository | 同期・クレンジング・変換 | `HealthSyncRepository` |
| Data Source | 外部 I/O | `Health` (health pkg), `DatabaseManager` (Hive) |

依存方向は上位 → 下位の一方向。Repository をインタフェース化し、将来のクラウド同期や
iOS 対応時にデータソースを差し替え可能にする。

## 3. ディレクトリ構成 (予定)

```
lib/
  main.dart                  # 初期化 (Hive / SecureStorage) → runApp
  core/
    database_manager.dart    # 暗号化 Hive ボックス管理 (シングルトン)
    constants.dart
  models/
    sleep_record_model.dart  # Hive モデル (+ sleep_record_model.g.dart)
    steps_record_model.dart
    heart_rate_record_model.dart
  repositories/
    health_sync_repository.dart
    cleansing.dart           # clip / mergeOverlaps / mergeAdjacent
  providers/
    sync_providers.dart      # Riverpod プロバイダ
  features/
    sleep/
    steps/
    heart_rate/
    dashboard/
  widgets/
docs/
test/
```

## 4. Android ネイティブ設定

### 4.1 build.gradle (`android/app/build.gradle`)
```groovy
android {
  defaultConfig {
    minSdkVersion 26      // ヘルスコネクト SDK 要件
    compileSdkVersion 34
  }
}
```

### 4.2 gradle.properties
```properties
android.useAndroidX=true
android.enableJetifier=true
```

### 4.3 MainActivity
`FlutterActivity` → `FlutterFragmentActivity` に変更
(registerForActivityResult ベースの権限要求を正しく動作させるため)。

### 4.4 AndroidManifest.xml
- `<queries>` に `com.google.android.apps.healthdata` と権限根拠 (Rationale) インテントを宣言。
- パーミッションは**睡眠・歩数・心拍の読み取りに限定** (データ最小化)。

```xml
<queries>
  <package android:name="com.google.android.apps.healthdata" />
  <intent>
    <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
  </intent>
</queries>

<uses-permission android:name="android.permission.health.READ_SLEEP" />
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_HEALTH_DATA_HISTORY" />
```

> 注: 要件上は読み取り専用のため WRITE 権限は申請しない。バックグラウンド同期を導入する
> 後続フェーズでのみ `READ_HEALTH_DATA_IN_BACKGROUND` を追加する。

## 5. パッケージ選定

| 候補 | 判定 | 理由 |
| --- | --- | --- |
| **health** | ✅ 採用 | デファクト・高メンテ頻度・将来 iOS 拡張余地。本プロジェクトのコア |
| health_connector | 候補 | 型安全・増分同期トークンが強力。大規模クラウド同期時に再検討 |
| flutter_health_connect | 不採用 | Android 特化だがメンテ頻度が低く iOS 非対応 |

当面は Android 専用スコープだが、`health` を採用し将来のマルチプラットフォーム化を阻害しない。

## 6. データモデル設計

### 6.1 睡眠 (SleepRecordModel)
ヘルスコネクトの `SleepSessionRecord` は「全体セッション」と「ステージ配列」の 2 階層。
本アプリはステージ単位で正規化して保存する。

| フィールド | 型 | 説明 |
| --- | --- | --- |
| uuid | String | ヘルスコネクト発行の一意 ID (Hive キー) |
| startTime | DateTime | 開始日時 |
| endTime | DateTime | 終了日時 |
| stageType | String | deep / light / rem / awake / out_of_bed / awake_in_bed / unknown |
| sourcePackage | String | 書き込み元パッケージ (競合判定用) |

睡眠ステージ定義:

| ステージ | 意味 | 可視化 |
| --- | --- | --- |
| DEEP | 深いノンレム | 最下層 |
| LIGHT | 浅いノンレム | 中間層 |
| REM | レム睡眠 | 中〜上層 (目立つ色) |
| AWAKE | 中途覚醒 | 最上層 |
| OUT_OF_BED | 離床 | 歩数と照合 |
| AWAKE_IN_BED | 覚醒 (在床) | 微細覚醒 |
| UNKNOWN | 判定不能 | グレーアウト |

### 6.2 歩数 (StepsRecordModel) / 6.3 心拍 (HeartRateRecordModel)
同様に `uuid` を主キーに `startTime` / `endTime` / `value` / `sourcePackage` を保持。

> モデル定義後は `flutter pub run build_runner build --delete-conflicting-outputs` で
> `*.g.dart` アダプタを生成する。

## 7. ローカル永続化 (Hive)

- Pure Dart の軽量 KVS。`HiveAesCipher` で AES-256 暗号化。
- ボックス構成:
  - `encrypted_sleep_records` (暗号化)
  - `encrypted_steps_records` (暗号化)
  - `encrypted_heart_rate_records` (暗号化)
  - `app_sync_metadata` (`last_sync_time` 等の軽量メタ。平文可)
- 暗号鍵は `flutter_secure_storage` に base64 で保存し、未生成時は `Hive.generateSecureKey()` で生成。
- `DatabaseManager` をシングルトンとし `main()` の `await initialize()` で初期化。

## 8. インクリメンタル同期設計

```
[アプリ起動 / 手動同期]
   ├─① metadata から last_sync_time をロード (初期値: 30 日前)
   ├─② start = last_sync_time, end = now でヘルスコネクトにリクエスト
   ├─③ 新規 / 更新データ (睡眠・歩数・心拍) のみ取得
   ├─④ uuid をキーに Hive へバッチ保存 (重複は自動上書き)
   └─⑤ last_sync_time を now に更新し UI を再描画
```

- 初回 (`last_sync_time == 0`): 過去 30 日をバックフィル。履歴権限があればそれ以前も。
- 差分 < 5 分: クエリをスキップ。
- 重複防止は `Box.put(uuid, record)` の上書きで担保 (Deduplication)。

## 9. クレンジングパイプライン

Repository の読み出し時 (`getCleanedSleepSegmentsForDay`) に以下を順に適用:

1. **ソース優先順位適用**: `sourcePackage` と信頼ソースリストでふるい落とす。
2. **境界クリッピング**: 表示枠 (例 正午〜翌正午) にミリ秒単位で切り出す。
3. **オーバーラップ解消**: 重複区間は長いセグメントを優先。
4. **隣接結合**: 30 秒未満の同一ステージ連続を 1 セグメントに統合。

## 10. クロスデータ統合

睡眠・心拍・歩数は関連 ID を持たないため、睡眠セッションの時間境界
`t_sleep_start ≤ t_biometric ≤ t_sleep_end` でフィルタし時間軸マッピングする。
これにより睡眠の質・心拍変動・覚醒行動の相関を 1 画面で可視化する。

## 11. 状態管理 (Riverpod)

- `databaseManagerProvider`: 初期化済み `DatabaseManager` を供給。
- `healthSyncRepositoryProvider`: Repository を供給。
- `syncNotifierProvider`: 同期の進行状態 (idle / syncing / done / error)。
- `sleepSegmentsProvider(date)` / `stepsProvider(range)` / `heartRateProvider(range)`:
  ローカル DB から即時取得し、同期完了で再評価される派生プロバイダ。

## 12. エラーハンドリング / フォールバック

| 状況 | 対応 |
| --- | --- |
| ヘルスコネクト未導入 | 導入導線 (Play ストア) を提示 |
| 権限未許可 | 機能説明 (Rationale) を表示し再申請導線 |
| 履歴権限なし | バックフィルを過去 30 日に制限 |
| バックグラウンドクエリ制限 | エラーを捕捉しリトライ / 次回同期に委譲 |

## 13. セキュリティ / コンプライアンス

- **Google Play ヘルスの申告**: Sleep management / Activity and fitness を選択し、全権限の合理的説明を登録。
- **データ最小化**: 睡眠・歩数・心拍以外の権限は申請しない。
- **Prominent Disclosure**: バックグラウンド同期導入時は深夜同期挙動・電力影響・データ用途を明示。
- **CASA**: 当面ローカル完結 (外部送信なし) のため Tier 1 (セルフアセスメント) 想定。
  将来クラウド連携時は Tier 2/3 を検討。SOC 2 / ISO 27001 保有時は CASA Accelerator を利用。

## 14. テスト方針

- クレンジング (clip / overlap / adjacency) と同期ロジックをユニットテストで TDD。
- `health` / Hive をモック / フェイク化して Repository を検証。
- ウィジェットテストでローカルファースト描画 (待ち無し) を確認。

## 15. 実装ロードマップ (フェーズ)

1. **フェーズ 1**: Hive + SecureStorage 結合、`DatabaseManager` 初期化、アダプタ生成、DB 開通確認。
2. **フェーズ 2**: `HealthSyncRepository` 実装、UUID 主キーによる重複排除、30 日バックフィル検証。
3. **フェーズ 3**: UI 描画層結合 (待ち無し描画)、3 種グラフ + クロス統合。
4. **フェーズ 4 (将来)**: WorkManager によるバックグラウンド差分同期、iOS 対応、クラウド同期。
