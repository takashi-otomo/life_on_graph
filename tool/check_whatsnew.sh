#!/usr/bin/env bash
# Google Play 公開前のリリースノート (whatsnew) プレフライト検証。
#
# Play へ AAB を公開する前に、言語ごとの「最新情報」が
#   - 必須ロケール分そろっているか
#   - Play の上限 (500 文字) を超えていないか
#   - 空でないか
# を確認し、問題があれば非ゼロ終了する (CI で公開前に fail-fast させる)。
#
# 使い方: tool/check_whatsnew.sh
set -euo pipefail
cd "$(dirname "$0")/.."

DIR="distribution/whatsnew"
# Play の listing 言語と一致させる (6言語)。
REQUIRED=(ja-JP en-US fr-FR de-DE pt-BR es-ES)
LIMIT=500

fail=0
for loc in "${REQUIRED[@]}"; do
  f="${DIR}/whatsnew-${loc}"
  if [ ! -f "$f" ]; then
    echo "::error::${f} が存在しません (必須ロケール)。"
    fail=1
    continue
  fi
  # 文字数 (マルチバイトを 1 文字として数える)。
  chars="$(wc -m < "$f" | tr -d ' ')"
  # 末尾改行のみ等の実質空チェック。
  if [ -z "$(tr -d '[:space:]' < "$f")" ]; then
    echo "::error::${f} が空です。"
    fail=1
    continue
  fi
  if [ "$chars" -gt "$LIMIT" ]; then
    echo "::error::${f} が ${chars} 文字で上限 ${LIMIT} を超えています。"
    fail=1
    continue
  fi
  echo "ok: whatsnew-${loc} (${chars} 文字)"
done

if [ "$fail" -ne 0 ]; then
  echo "::error::whatsnew 検証に失敗しました。distribution/whatsnew/ を修正してください。"
  exit 1
fi
echo "✓ whatsnew 検証 OK (${#REQUIRED[@]} ロケール)"
