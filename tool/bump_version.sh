#!/usr/bin/env bash
# pubspec.yaml の versionName (SemVer: MAJOR.MINOR.PATCH) をブランチに応じて更新する。
# https://semver.org/lang/ja/
#
#   develop … パッチを +1        (例 1.2.3 -> 1.2.4)  ※ develop ビルドごとの増分
#   main    … マイナーを +1, パッチ 0 (例 1.2.3 -> 1.3.0)  ※ リリースで minor up
#
# versionCode (Play 用整数) は build.gradle.kts が git コミット数から別途自動採番する。
# 標準出力に新しい versionName を出力する。
set -euo pipefail
cd "$(dirname "$0")/.."

BRANCH="${1:?usage: bump_version.sh <develop|main>}"

ver="$(grep -E '^version:' pubspec.yaml | sed 's/^version:[[:space:]]*//')" # X.Y.Z(+C)
name="${ver%%+*}"
suffix=""
case "$ver" in
  *+*) suffix="+${ver#*+}" ;;
esac

IFS=. read -r major minor patch <<EOF
$name
EOF
: "${major:?invalid version: $ver}" "${minor:?}" "${patch:?}"

case "$BRANCH" in
  main) newname="${major}.$((minor + 1)).0" ;;
  develop) newname="${major}.${minor}.$((patch + 1))" ;;
  *)
    echo "unknown branch: $BRANCH (expected develop|main)" >&2
    exit 1
    ;;
esac

perl -pi -e "s/^version:.*/version: ${newname}${suffix}/" pubspec.yaml
echo "$newname"
