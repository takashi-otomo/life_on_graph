# 03. 開発タスク (暫定) — Life On Graph (LOG)

本リストは **GitHub Issue 登録の元データ** である。各タスクは 1 Issue を想定し、
`[ ]` を 1 単位として粒度を保つ。ラベル / マイルストーンは登録時に付与する。

凡例: 優先度 P0 (必須) / P1 (重要) / P2 (任意)、見積は相対サイズ (S/M/L)。

---

## マイルストーン M0: プロジェクト基盤

- [ ] **T-001** Flutter プロジェクト生成 (パッケージ名 / アプリ名 LOG 設定) — P0 / S
- [ ] **T-002** 依存パッケージ追加 (`health`, `flutter_riverpod`, `hive`, `hive_flutter`, `flutter_secure_storage`, `fl_chart`, `build_runner`, `hive_generator`) — P0 / S
- [ ] **T-003** Lint / フォーマット設定 (`analysis_options.yaml`) と CI 雛形 — P1 / S
- [ ] **T-004** ディレクトリ構成スキャフォールド (core/models/repositories/providers/features) — P0 / S

## マイルストーン M1: Android ネイティブ設定

- [ ] **T-101** `build.gradle` の minSdk 26 / compileSdk 34 設定 — P0 / S
- [ ] **T-102** `gradle.properties` で AndroidX / Jetifier 有効化 — P0 / S
- [ ] **T-103** `MainActivity` を `FlutterFragmentActivity` に変更 — P0 / S
- [ ] **T-104** AndroidManifest に `<queries>` と健康パーミッション (睡眠/歩数/心拍 READ + 履歴) 宣言 — P0 / M
- [ ] **T-105** 権限根拠 (Rationale) Activity / intent-filter 設定 — P1 / S
- [ ] **T-106** 実機でヘルスコネクト導入検出・権限ダイアログ表示を確認 — P0 / M

## マイルストーン M2: ローカル永続化 (フェーズ1)

- [ ] **T-201** `SleepRecordModel` (Hive アノテーション) 実装 — P0 / S
- [ ] **T-202** `StepsRecordModel` / `HeartRateRecordModel` 実装 — P0 / S
- [ ] **T-203** `build_runner` で `*.g.dart` アダプタ生成 — P0 / S
- [ ] **T-204** `flutter_secure_storage` による暗号鍵生成・取得ロジック — P0 / M
- [ ] **T-205** `DatabaseManager` (暗号化 Hive ボックス開閉 / シングルトン) 実装 — P0 / M
- [ ] **T-206** `main.dart` で初期化 (ensureInitialized → DatabaseManager.initialize) — P0 / S
- [ ] **T-207** DB 開通・暗号化ボックス読み書きのユニットテスト — P0 / M

## マイルストーン M3: 同期エンジン (フェーズ2)

- [ ] **T-301** `HealthSyncRepository` 雛形 + パーミッション要求 (`configure` / `requestAuthorization`) — P0 / M
- [ ] **T-302** `last_sync_time` 管理と初回 30 日バックフィルロジック — P0 / M
- [ ] **T-303** 差分取得 (`getHealthDataFromTypes`) と UUID 主キーによる Hive バッチ保存 — P0 / L
- [ ] **T-304** 履歴権限 (READ_HEALTH_DATA_HISTORY) の追加許可フローとフォールバック — P1 / M
- [ ] **T-305** 差分極小時 (5 分未満) のクエリスキップ最適化 — P2 / S
- [ ] **T-306** 重複排除 (UUID 上書き) のユニットテスト — P0 / M

## マイルストーン M4: クレンジング (フェーズ2)

- [ ] **T-401** ソース優先順位 (`sourcePackage`) によるアロケーション実装 — P1 / M
- [ ] **T-402** 境界クリッピング (`clipSegmentsToDay`) 実装 — P0 / M
- [ ] **T-403** オーバーラップ解消 (`mergeOverlaps`) 実装 — P0 / M
- [ ] **T-404** 隣接同一ステージ結合 (`mergeAdjacentSameStage`, tolerance 30s) 実装 — P1 / M
- [ ] **T-405** クレンジングパイプライン一括のユニットテスト (境界 / 重複 / 結合) — P0 / L

## マイルストーン M5: 状態管理 (Riverpod)

- [ ] **T-501** `databaseManagerProvider` / `healthSyncRepositoryProvider` 定義 — P0 / S
- [ ] **T-502** `syncNotifierProvider` (idle/syncing/done/error) 実装 — P0 / M
- [ ] **T-503** `sleepSegmentsProvider(date)` 等の派生プロバイダ実装 — P0 / M
- [ ] **T-504** 同期完了 → UI リアクティブ更新の結線 — P0 / M

## マイルストーン M6: 可視化 UI (フェーズ3)

- [ ] **T-601** 睡眠ステージ積層タイムラインチャート — P0 / L
- [ ] **T-602** 睡眠サマリー (合計時間 / ステージ比率) 表示 — P0 / M
- [ ] **T-603** 歩数グラフ (日 / 週切替の棒グラフ) — P0 / M
- [ ] **T-604** 心拍折れ線グラフ (時系列) — P0 / M
- [ ] **T-605** 睡眠中心拍フィルタ表示 (時間境界フィルタ) — P1 / M
- [ ] **T-606** クロスデータ統合ビュー (睡眠 × 心拍 × 歩数 時間軸マッピング) — P1 / L
- [ ] **T-607** ローカルファースト即時描画 (待ち無し) のウィジェットテスト — P0 / M
- [ ] **T-608** 日付ナビゲーション (前日 / 翌日 / カレンダー) — P1 / M
- [ ] **T-609** 空データ / 未許可 / 未導入時の状態別 UI — P1 / M

## マイルストーン M7: コンプライアンス / リリース準備

- [ ] **T-701** プライバシーポリシー作成・掲載 — P0 / M
- [ ] **T-702** Google Play「ヘルスの申告」記入 (Sleep / Activity & fitness + 権限説明) — P0 / M
- [ ] **T-703** データ最小化レビュー (不要権限ゼロの確認) — P0 / S
- [ ] **T-704** CASA Tier 1 セルフアセスメント (DAST/SAST + チェックリスト) — P1 / M
- [ ] **T-705** アプリアイコン / ストア掲載素材 — P2 / M

## マイルストーン M8 (将来): 拡張

- [ ] **T-801** WorkManager によるバックグラウンド差分同期 — P2 / L
- [ ] **T-802** バックグラウンド同期の Prominent Disclosure / 権限追加 — P2 / M
- [ ] **T-803** iOS (HealthKit) 対応 — P2 / L
- [ ] **T-804** クラウドバックエンド連携・同期 — P2 / L

---

### GitHub Issue 登録について
- 各 `T-xxx` を 1 Issue として登録する。
- マイルストーン名 (M0〜M8) を GitHub Milestone に対応させる。
- ラベル例: `area:android`, `area:db`, `area:sync`, `area:ui`, `priority:P0`, `compliance`。
- 登録は本ファイル確定後に一括実施する (未確定タスクは追記・調整可)。
