#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="GlupGlup Reminder"
VERSION="${1:-1.0.1}"
BUILD_DIR="$ROOT_DIR/Build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_STAGING="$BUILD_DIR/dmg-root"
DMG_NAME="GlupGlup-Reminder-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

"$ROOT_DIR/Scripts/build_app.sh"

rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"

ditto "$APP_BUNDLE" "$DMG_STAGING/$APP_NAME.app"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "Created $DMG_PATH"
