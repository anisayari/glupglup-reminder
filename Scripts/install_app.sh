#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="GlupGlup Reminder"
EXECUTABLE_NAME="GlupGlupReminder"
BUILD_APP="$ROOT_DIR/Build/$APP_NAME.app"
INSTALL_DIR="${HOME}/Applications"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

"$ROOT_DIR/Scripts/build_app.sh"

mkdir -p "$INSTALL_DIR"
pkill -f "$TARGET_APP/Contents/MacOS/$EXECUTABLE_NAME" >/dev/null 2>&1 || true
rm -rf "$TARGET_APP"
ditto "$BUILD_APP" "$TARGET_APP"
xattr -dr com.apple.quarantine "$TARGET_APP" >/dev/null 2>&1 || true

"$TARGET_APP/Contents/MacOS/$EXECUTABLE_NAME" >/dev/null 2>&1 &!

echo
echo "GlupGlup Reminder installed in:"
echo "$TARGET_APP"
