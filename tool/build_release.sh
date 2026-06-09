#!/usr/bin/env bash
# リリースビルド。ビルドのたびに pubspec.yaml のビルド番号 (versionCode) を +1 する。
#
# 使い方:
#   tool/build_release.sh            # AAB をビルド (既定)
#   tool/build_release.sh apk        # APK をビルド
#   tool/build_release.sh aab --keep # ビルド番号を上げずに現在値でビルド
#
# Google Play は versionCode の重複を許さないため、アップロードのたびに増やす必要がある。
# 本スクリプトは pubspec.yaml の `version: <name>+<code>` の <code> を加算して記録する
# (変更はコミットしてリポジトリで履歴管理する)。
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="aab"
KEEP=false
for arg in "$@"; do
  case "$arg" in
    aab|apk) TARGET="$arg" ;;
    --keep) KEEP=true ;;
    *) echo "usage: $0 [aab|apk] [--keep]"; exit 1 ;;
  esac
done

PUBSPEC="pubspec.yaml"
line="$(grep -E '^version:[[:space:]]' "$PUBSPEC")" # 例: version: 1.0.0+1
ver="${line#version:}"
ver="$(printf '%s' "$ver" | tr -d '[:space:]')" # 1.0.0+1
name="${ver%%+*}"                                # 1.0.0
code="${ver##*+}"                                # 1
if ! printf '%s' "$code" | grep -Eq '^[0-9]+$'; then
  echo "error: pubspec の version からビルド番号を解析できません: '$ver'"
  exit 1
fi

if [ "$KEEP" = true ]; then
  next="$code"
else
  next=$((code + 1))
  perl -pi -e "s/^version:.*/version: ${name}+${next}/" "$PUBSPEC"
  echo "versionCode: ${code} -> ${next} (versionName ${name})"
fi

case "$TARGET" in
  aab)
    flutter build appbundle --release
    echo "✓ build/app/outputs/bundle/release/app-release.aab (versionCode ${next})"
    ;;
  apk)
    flutter build apk --release
    echo "✓ build/app/outputs/flutter-apk/app-release.apk (versionCode ${next})"
    ;;
esac
