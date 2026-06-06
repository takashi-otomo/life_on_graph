# ストア掲載素材 (#47 / T-705)

Google Play 公開用の掲載素材。実際のアップロードは公開作業時に開発者が Play Console で行う。

## 素材一覧

| 素材 | ファイル | 仕様 | 状態 |
| --- | --- | --- | --- |
| アプリアイコン | [app_icon.png](app_icon.png) | 512×512(マスターは 1024) | ✅ 完了(#86) |
| フィーチャーグラフィック | [feature_graphic.png](feature_graphic.png) | 1024×500 | ✅ 完了 |
| スクリーンショット | [screenshots/](screenshots/) | 1080×2400(携帯) | ✅ 4点(実データ) |
| 掲載テキスト | [listing.md](listing.md) | 名称/説明/カテゴリ等 | ✅ 完了 |

### スクリーンショット
1. `01_dashboard.png` — ダッシュボード(睡眠/歩数/心拍)
2. `02_summary.png` — 週別サマリー(KPI・前期間比・トレンド)
3. `03_cross_data.png` — 統合ビュー(睡眠×心拍×歩数, 24時間)
4. `04_settings.png` — 設定(同期/プライバシー/情報)

> シードデータ投入済みエミュレータで取得。公開時は最新ビルドで撮り直すことを推奨。

## 素材の再生成

- **アイコン**: `assets/branding/app_icon.svg` を編集 → `qlmanage` で PNG 化 → `dart run flutter_launcher_icons`
- **フィーチャーグラフィック**: `assets/branding/feature_graphic.svg` を編集 → `qlmanage -t -s 1024 -o . feature_graphic.svg` → `dart run tool/crop_feature_graphic.dart`(1024×500 に整形)
- マスター(SVG)は `assets/branding/` に同梱。

## 関連
- #86 アプリアイコン / #87 起動画面 / #44 ヘルス申告 / #43 プライバシーポリシー
