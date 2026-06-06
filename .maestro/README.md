# Maestro E2E テスト基盤 (#75)

LOG の主要フローをエミュレータ/実機で自動検証する [Maestro](https://maestro.mobile.dev/) の設定。

## 構成
- `config.yaml` — フロー探索設定(`flows/*.yaml`)
- `flows/01_smoke.yaml` — 起動 → ボトムタブ [ホーム/サマリー/設定] 表示
- `flows/02_navigation.yaml` — タブ遷移(識別子 `tab_home`/`tab_summary`/`tab_settings`)
- `flows/03_empty_state.yaml` — 当日(データ無し)の空状態表示

## 安定識別子
ボトムタブに `Semantics(identifier:)` を付与済み(`tab_home` / `tab_summary` / `tab_settings`,
`lib/widgets/capsule_tab_bar.dart`)。テキスト依存を避け安定して指定できる。

## 実行
```bash
flutter emulators --launch <avd-id>
scripts/run_app.sh <serial>          # アプリをインストール・起動
maestro --device <serial> test .maestro/flows/
```

## 注意 (Flutter × Maestro)
- Flutter のセマンティクスツリーは a11y クライアント接続時に Android アクセシビリティ
  ツリーへ露出される。本アプリは `main()` で `SemanticsBinding.ensureSemantics()` を
  呼び常時セマンティクスを有効化している(`lib/main.dart`)。
- デバッグビルドはコールドスタートが遅いため、各フロー先頭は `extendedWaitUntil`
  (60s)で初期描画を待つ。
- 環境によっては Maestro が Flutter の a11y ツリーを取得できない場合がある(描画は
  されるがノードが空)。その際は Maestro のアクセシビリティサービス有効化・端末再起動・
  ビルド種別(debug 推奨)を確認する。smoke フローの成功実績あり。

## CI 連携 (後続)
ローカル/エミュレータ前提で整備。CI 実行(エミュレータ起動 or Maestro Cloud)は別途検討。
