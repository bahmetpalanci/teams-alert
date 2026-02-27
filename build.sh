#!/bin/bash
set -euo pipefail

APP_NAME="TeamsAlert"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Building ${APP_NAME}..."
swift build -c release 2>&1

echo "==> Creating .app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp "Sources/TeamsAlert/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Copy app icon
if [ -f "TeamsAlert.icns" ]; then
    cp "TeamsAlert.icns" "${RESOURCES_DIR}/TeamsAlert.icns"
fi

# Ad-hoc codesign
echo "==> Signing..."
codesign --force --sign - "${APP_BUNDLE}"

echo "==> Done! Run with: open ${APP_BUNDLE}"
echo "    Bundle location: $(pwd)/${APP_BUNDLE}"
