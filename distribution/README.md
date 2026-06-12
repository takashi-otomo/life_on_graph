# Google Play リリースノート (What's new)

各言語ごとの **Google Play 用リリースノート**。`main` への push 時に
[`r0adkll/upload-google-play`](https://github.com/r0adkll/upload-google-play) が
このディレクトリを `whatsNewDirectory` として読み込み、Play の「最新情報」に反映する。

## 記述ルール (Google Play の仕様)
- ファイル名は `whatsnew-<locale>` 形式。`<locale>` は Play の言語コード (BCP-47)。
  - `ja-JP` 日本語 / `en-US` 英語 / `fr-FR` フランス語 / `de-DE` ドイツ語 / `pt-BR` ポルトガル語 / `es-ES` スペイン語
- **プレーンテキスト**。HTML/Markdown 記法は使えない (箇条書きは `•` や `-` を直書きする)。
- **1 言語あたり最大 500 文字**。改行・絵文字は使用可。
- リリースごとに内容を更新する (ユーザー向けに「何が変わったか」を簡潔に)。

## 初回リリース時 (手動アップロード) の貼り付け用

CI を使わず Play Console の「リリースノート」欄へ**手動で貼り付ける**場合は、言語タグ付きで
全言語を 1 つにまとめた形式が便利:

```
<ja-JP>
…
</ja-JP>
<en-US>
…
</en-US>
…
```

この結合ファイルは [`tool/play_release_notes.sh`](../tool/play_release_notes.sh) が
`whatsnew-<locale>` から生成する:

```sh
tool/play_release_notes.sh distribution/release-notes-v1.0.0.txt
```

初回リリース (v1.0.0) 用は **[`distribution/release-notes-v1.0.0.txt`](release-notes-v1.0.0.txt)** に生成済み。
内容をそのまま Play Console のリリースノート欄へ貼り付ける。

## 補足
- ここは **Google Play 専用**。Firebase App Distribution のリリースノートは
  `tool/release_notes.sh` が git 履歴から自動生成する (`release_notes.txt`)。
- 対応言語を増やす場合は `whatsnew-<locale>` を追加する。
