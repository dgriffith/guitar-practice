#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/GuitarPractice" && pwd)"
APP_NAME="GuitarPractice"
DEST="/Applications/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
xcodebuild -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -configuration Debug \
    build 2>&1 | tail -3

# Find the built app in DerivedData
BUILD_DIR=$(xcodebuild -project "${PROJECT_DIR}/${APP_NAME}.xcodeproj" \
    -scheme "${APP_NAME}" \
    -showBuildSettings 2>/dev/null | grep -m1 '^\s*BUILT_PRODUCTS_DIR' | awk '{print $3}')
BUILT_APP="${BUILD_DIR}/${APP_NAME}.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "Error: Built app not found at ${BUILT_APP}"
    exit 1
fi

# Kill running instance if any
pkill -x "$APP_NAME" 2>/dev/null && sleep 0.5 || true

# Copy to /Applications
echo "Installing to ${DEST}..."
rm -rf "$DEST"
cp -R "$BUILT_APP" "$DEST"

# Launch
echo "Launching ${APP_NAME}..."
open "$DEST"
echo "Done."
