# 10. 実際に試す → クローズドテストに参加する

読んで終わりにせず、**手を動かして試せる**ようにまとめた。最後に、実機で動く版を
**Google Play クローズドテスト**で触ってもらうための導線を置く。

---

## 10.1 まずはアプリを触ってみる (ユーザー向け)

> 🧪 **クローズドテスター募集中**
> Life On Graph を実機で試せます。**Android + ヘルスコネクト**があればすぐ始められます。
>
> 1. テスター登録(下記のいずれか)
>    - 公式サイト: <https://lifeongraph.web.app>
>    - お問い合わせ/参加フォーム: <https://forms.gle/TQSUCq7ERuMLn6jB8>
> 2. 参加用オプトインリンクを開く(登録後に案内)
>    - `https://play.google.com/apps/testing/dev.otomo.life_on_graph`
> 3. Google Play からインストール
>    - `https://play.google.com/store/apps/details?id=dev.otomo.life_on_graph`
>
> ※ クローズドテストの公開状況により、リンクが有効化されるまで時間差があります。
> 睡眠・歩数・心拍がヘルスコネクトに入っているほど、統合ビューが映えます。

### 触ってほしいポイント
- 起動した瞬間に**待たされず**データが出る (ローカルファースト)。
- 上部の進捗バーで「今どの種別を何件取り込んだか」が見える。
- 「統合ビュー」で**睡眠×心拍×歩数**を同じ時間軸で俯瞰。
- 心拍グラフは**データの無い時間帯に線が引かれない**(誤読防止)。
- データは**端末から出ない**(機内モードでも過去分は見られる)。

---

## 10.2 コードを動かしてみる (開発者向け)

### セットアップ

```bash
# 1. 取得
git clone https://github.com/takashi-otomo/life_on_graph.git
cd life_on_graph

# 2. Flutter 3.44.1 を用意 (fvm 等でバージョン固定推奨)
flutter --version    # 3.44.1

# 3. 依存解決 + コード生成 (Hive アダプタ / l10n)
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 4. 実機 or エミュレータで起動
flutter run
```

> Health Connect が必要です。実機 (API 34+) はネイティブ統合済み。エミュレータでは
> Health Connect アプリの導入が要る場合があります。

### データが無い? シーダーで投入する

実機/エミュレータに睡眠・歩数・心拍が無いと画面が空になる。テスト用データ投入の
仕組みを用意している (`tool/health_seeder.dart` / 詳細は
[`docs/health_seed_data.md`](../health_seed_data.md))。

### 「いじると面白い」ファイル

| 試したいこと | ファイル | 触る場所 |
| --- | --- | --- |
| 同期窓を変える | `lib/core/app_constants.dart` | `recentSyncDays`(7) / `historyBackfillDays`(90) |
| 心拍の間引き粒度 | `lib/repositories/health_sync_repository.dart` | `_saveHeartRate` の分バケット |
| 欠落分断の閾値 | `lib/features/heart_rate/widgets/heart_rate_chart.dart` | `kHeartRateGapThreshold`(10分) |
| 統合ビューの見せ方 | `lib/features/cross_data/widgets/cross_data_chart.dart` | レーン比率・配色 |
| 暗号化まわり | `lib/core/database_manager.dart` | `_openEncryptedBoxes` |

### テストを回す

```bash
flutter analyze          # lint ゼロが基準
flutter test             # ユニット + ウィジェット (200+ ケース)

# E2E (Maestro) — 実機/エミュレータ接続後
maestro --device <serial> test .maestro/flows/
```

例えば `recentSyncDays` を変えると、`test/unit/health_sync_repository_test.dart` の
7 日上限テストが**赤くなる**。「仕様＝テスト」を体感できる ([06](06_testing.md))。

---

## 10.3 フィードバックの返し先

- 不具合・要望: お問い合わせフォーム <https://forms.gle/TQSUCq7ERuMLn6jB8>
  (アプリ内「設定 → お問い合わせ」からも開ける)。
- 開発者なら GitHub Issues / PR も歓迎(`develop` 向けに PR、CI 緑が条件)。

> クローズドテストのフィードバックは、そのまま製品版 (Google Play production) の品質に
> 直結します。「実際に試す → 気づきを返す」までが、このプロジェクトのループです。
