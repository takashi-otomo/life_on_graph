#!/usr/bin/env bash
# リリースビルド (署名済み)。
#
# versionCode は build.gradle.kts が **git のコミット数** から自動採番する
# (コミットを重ねるごとに単調増加)。手動でのバージョン番号バンプは不要。
# versionName (例: 1.0.0) はマーケティング上の版なので、変えたいときだけ pubspec.yaml を編集する。
#
# 使い方:
#   tool/build_release.sh        # AAB をビルド (既定)
#   tool/build_release.sh apk    # APK をビルド
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:-aab}"
case "$TARGET" in
  aab)
    flutter build appbundle --release
    echo "✓ build/app/outputs/bundle/release/app-release.aab"
    ;;
  apk)
    flutter build apk --release
    echo "✓ build/app/outputs/flutter-apk/app-release.apk"
    ;;
  *)
    echo "usage: $0 [aab|apk]"
    exit 1
    ;;
esac

if code="$(git rev-list --count HEAD 2>/dev/null)"; then
  echo "versionCode = ${code} (git コミット数)"
fi
