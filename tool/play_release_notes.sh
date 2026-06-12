#!/usr/bin/env bash
# Google Play Console の「リリースノート」欄に貼り付けるための、言語タグ付き結合
# テキストを生成する。
#
#   <ja-JP>…</ja-JP>
#   <en-US>…</en-US>  …
#
# 各言語の本文は distribution/whatsnew/whatsnew-<locale> から取り込む。
# 使い方: tool/play_release_notes.sh [出力先]   (既定: distribution/release-notes-combined.txt)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="${1:-distribution/release-notes-combined.txt}"
ORDER=(ja-JP en-US fr-FR de-DE pt-BR es-ES)

: > "$OUT"
first=true
for loc in "${ORDER[@]}"; do
  f="distribution/whatsnew/whatsnew-${loc}"
  if [ ! -f "$f" ]; then
    echo "::warning:: ${f} が無いためスキップ"
    continue
  fi
  [ "$first" = true ] || printf '\n\n' >> "$OUT"
  first=false
  # $(cat) が末尾改行を除去するので、本文をタグで囲んで出力する。
  body="$(cat "$f")"
  printf '<%s>\n%s\n</%s>' "$loc" "$body" "$loc" >> "$OUT"
done
printf '\n' >> "$OUT"

echo "生成: ${OUT}"
