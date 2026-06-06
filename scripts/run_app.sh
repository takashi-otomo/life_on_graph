#!/usr/bin/env bash
#
# Life On Graph (LOG) を Android エミュレータでビルド・インストール・起動する。
#
# 使い方:
#   scripts/run_app.sh [emulator-serial]
#
# 事前にエミュレータを起動しておくこと:
#   flutter emulators                       # 利用可能な AVD を一覧
#   flutter emulators --launch <avd-id>     # 例: Medium_Phone_API_36.1
#
# 備考:
#   - fat デバッグ APK (全 ABI, ~150MB) はエミュレータのストレージ低下時に
#     インストール失敗するため、本スクリプトは arm64 限定 (~80MB) でビルドする。
#   - エミュレータの空きが極端に少ない場合は別 AVD を使うか data を wipe する。
set -euo pipefail

APP_ID="dev.otomo.life_on_graph"
ADB="${ADB:-$HOME/Library/Android/sdk/platform-tools/adb}"

SERIAL="${1:-}"
if [ -z "$SERIAL" ]; then
  SERIAL="$("$ADB" devices | awk '$2=="device" && $1 ~ /^emulator-/ {print $1; exit}')"
fi
if [ -z "$SERIAL" ]; then
  echo "エラー: 起動中の Android エミュレータが見つかりません。" >&2
  echo "  flutter emulators --launch <avd-id> で先に起動してください。" >&2
  exit 1
fi

echo "==> 対象エミュレータ: $SERIAL"
echo "==> arm64 デバッグ APK をビルド中..."
flutter build apk --debug --target-platform android-arm64 --split-per-abi

APK="build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk"
echo "==> インストール: $APK"
"$ADB" -s "$SERIAL" install -r "$APK"

echo "==> 起動: $APP_ID"
"$ADB" -s "$SERIAL" shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1 >/dev/null
echo "==> 起動しました ($APP_ID on $SERIAL)"
