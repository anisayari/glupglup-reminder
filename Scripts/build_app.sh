#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="GlupGlup Reminder"
EXECUTABLE_NAME="GlupGlupReminder"
BUILD_DIR="$ROOT_DIR/Build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

swift "$ROOT_DIR/Scripts/generate_sound.swift" "$ROOT_DIR/Resources/water-drop.wav"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
find "$ROOT_DIR/Resources" -type f ! -name "Info.plist" -exec cp {} "$RESOURCES_DIR/" \;

SWIFT_SOURCES=("$ROOT_DIR"/Sources/Glouglou/*.swift)

xcrun swiftc \
  -framework AppKit \
  -framework Charts \
  -framework SwiftUI \
  -framework UserNotifications \
  -o "$MACOS_DIR/$EXECUTABLE_NAME" \
  "${SWIFT_SOURCES[@]}"

codesign --force --deep -s - "$APP_DIR" >/dev/null 2>&1 || true

echo "Built $APP_DIR"
