#!/usr/bin/env bash
# リリースノートを git 履歴から自動生成する (#release-pipeline)。
#
# 生成物:
#   - release_notes.txt                     … Firebase App Distribution 用 (全文)
#   - distribution/whatsnew/whatsnew-en-US  … Google Play 用 (英語, 500字以内)
#   - distribution/whatsnew/whatsnew-ja-JP  … Google Play 用 (日本語, 500字以内)
#
# 直近のタグ以降 (タグが無ければ直近 30 コミット) の feat/fix を要約する。
set -euo pipefail

# 直近のタグ (無ければ空)。
PREV_TAG="$(git tag --sort=-creatordate | head -n1 || true)"
if [ -n "${PREV_TAG}" ]; then
  RANGE="${PREV_TAG}..HEAD"
else
  # タグが無い初回はコミット数に応じてレンジを決める。
  COUNT="$(git rev-list --count HEAD)"
  if [ "${COUNT}" -gt 30 ]; then RANGE="HEAD~30..HEAD"; else RANGE="HEAD"; fi
fi

# マージコミットを除外し、feat/fix を優先抽出。空ならメンテナンス扱い。
FEATURES=()
FIXES=()
while IFS= read -r s; do
  [ -z "${s}" ] && continue
  case "${s}" in
    feat:*|feat\(*) FEATURES+=("- ${s#feat}") ;;
    fix:*|fix\(*)   FIXES+=("- ${s#fix}") ;;
  esac
done < <(git log "${RANGE}" --no-merges --pretty='%s' || true)

{
  if [ "${#FEATURES[@]}" -gt 0 ]; then
    echo "✨ 新機能 / New"
    printf '%s\n' "${FEATURES[@]}" | sed 's/^- [: ]*/- /' | head -n 12
    echo ""
  fi
  if [ "${#FIXES[@]}" -gt 0 ]; then
    echo "🛠 改善・修正 / Fixes"
    printf '%s\n' "${FIXES[@]}" | sed 's/^- [: ]*/- /' | head -n 12
  fi
  if [ "${#FEATURES[@]}" -eq 0 ] && [ "${#FIXES[@]}" -eq 0 ]; then
    echo "メンテナンスアップデート / Maintenance update"
  fi
} > release_notes.txt

echo "=== release_notes.txt ==="
cat release_notes.txt

# Google Play 用 whatsnew (500 字以内に丸める)。日本語を含むためバイトではなく
# 文字単位で切り詰める (head -c だとマルチバイトが壊れる)。
mkdir -p distribution/whatsnew
perl -CS -e 'local $/; my $t=<STDIN>; print substr($t, 0, 480)' \
  < release_notes.txt > distribution/whatsnew/whatsnew-en-US
cp distribution/whatsnew/whatsnew-en-US distribution/whatsnew/whatsnew-ja-JP
