# CASA Tier 1 セルフアセスメント (#46 / T-704)

Google Play で機微な健康データを扱うアプリに求められる CASA (Cloud Application Security Assessment)。LOG は**クラウド送信のないローカル完結アプリ**のため、最も軽量な **Tier 1(セルフアセスメント)** を適用範囲とする。

## 1. Tier 1 適用範囲の妥当性

| 観点 | LOG の状況 | 判定 |
| --- | --- | --- |
| サーバーサイド | 無し(バックエンド・API を持たない) | Tier 1 妥当 |
| データ送信 | 無し(健康データを外部送信しない) | Tier 1 妥当 |
| 攻撃対象領域 (DAST) | ネットワークエンドポイント無し → 動的攻撃面が極小 | Tier 1 妥当 |

将来クラウド連携 (#51) を追加する場合は Tier 2/3 を再検討する。SOC 2 / ISO 27001 認証は現時点で非保有のため、通常の Tier 1 フローで進める。

## 2. セキュリティチェックリスト回答(根拠付き)

| 項目 | 回答 | 根拠 |
| --- | --- | --- |
| 保存データの暗号化 | ✅ 対応 | 睡眠/歩数/心拍ボックスを **AES-256**(`HiveAesCipher`)で暗号化 (`lib/core/database_manager.dart`, NFR-1) |
| 暗号鍵の安全な管理 | ✅ 対応 | 鍵は `flutter_secure_storage`(Android Keystore 連携)で隔離保存。コード・設定にハードコードしない (`lib/core/secure_key_store.dart` / `encryption_key_provider.dart`, T-204) |
| 機微データの送信回避 | ✅ 対応 | HTTP/Dio/Socket/Firebase 等の送信処理ゼロ。健康データは端末内に留まる (NFR-2) |
| 機微データのログ出力回避 | ✅ 対応 | 健康データの平文ログ出力なし(`print`/`debugPrint`/`log` 呼び出しゼロ) |
| 権限最小化 | ✅ 対応 | READ 4種 + 歩数用 ACTIVITY_RECOGNITION のみ。WRITE はデバッグ限定([データ最小化レビュー](data_minimization_review.md)) |
| バックアップからの漏洩防止 | ✅ 対応 | `android:allowBackup="false"` + `dataExtractionRules` で端末バックアップ/移行から健康データを除外 (#43/#56) |
| データ削除手段の提供 | ✅ 対応 | 設定画面「すべてのデータを削除」でローカルデータを消去 (#69) |
| 依存関係の脆弱性管理 | ⚠ 確認・記録 | 後述 §3 |

## 3. SAST / DAST / 依存スキャン結果

- **静的解析 (SAST 相当)**: `flutter analyze` → **0 issues**(lints 準拠)。CI で各 PR ごとに実行・ゼロを維持。
- **動的解析 (DAST)**: ネットワークエンドポイント・サーバーサイドを持たないため、DAST の対象となる動的攻撃面は実質存在しない(ローカル完結)。
- **依存スキャン**: `flutter pub outdated` を実施。主要依存(health / hive_ce / flutter_secure_storage / fl_chart / riverpod / url_launcher)は制約内の最新を解決。
  - 参考: `flutter_secure_storage_darwin`(0.3.2→0.4.0)、`flutter_secure_storage_windows`(4.1.0→4.2.2)に新版があるが、いずれも上位 `flutter_secure_storage` の制約により固定。**本アプリの対象は Android** であり当該プラットフォーム実装は不使用、既知の重大脆弱性 (CVE) は確認されていない。今後の更新サイクルで追従する。

検出された重大指摘は無し。指摘が出た場合はリリース前に対応し本書へ追記する。

## 4. 提出物・有効期限

- 提出物: 本セルフアセスメント文書 + チェックリスト回答 + `flutter analyze` 結果。
- CASA 認証には有効期限(更新サイクル)があるため、公開審査時の提出日と次回更新時期を記録すること(実提出は開発者が公開作業時に実施)。

## 受け入れ基準の対応

- [x] Tier 1 が適用範囲として妥当(ローカル完結・非送信)と判断・記録(§1)
- [x] セキュリティチェックリストの全項目に回答(§2)
- [x] SAST/DAST/依存スキャンを実行し結果を記録(§3)
- [x] 検出指摘の対応方針を記録(重大指摘なし。依存の新版は追従方針)(§3)
- [x] 暗号化・鍵管理・非送信の根拠 (NFR-1/NFR-2) を回答に反映(§2)
