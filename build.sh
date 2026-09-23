#!/usr/bin/env bash
set -e

APP_NAME="Deepeak"
BUNDLE_NAME="${APP_NAME}.app"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_PATH="${PROJECT_DIR}/${BUNDLE_NAME}"

echo "🔨 Compiling DeepSeekStatus..."
swift build -c release

# Find the release executable
BIN_PATH="$(swift build -c release --show-bin-path)/DeepSeekStatus"

echo "📦 Creating macOS App Bundle at ${APP_PATH}..."
rm -rf "${APP_PATH}"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

# Copy binary, plist, and logo
cp "${BIN_PATH}" "${APP_PATH}/Contents/MacOS/DeepSeekStatus"
cp "${PROJECT_DIR}/Resources/Info.plist" "${APP_PATH}/Contents/Info.plist"
cp "${PROJECT_DIR}/Resources/deepseek_logo.png" "${APP_PATH}/Contents/Resources/deepseek_logo.png"
if [ -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${APP_PATH}/Contents/Resources/AppIcon.icns"
fi

chmod +x "${APP_PATH}/Contents/MacOS/DeepSeekStatus"

echo "✅ App bundle created successfully: ${APP_PATH}"
echo "🚀 You can launch it with: open \"${APP_PATH}\""

if [[ "$*" == *"--dmg"* ]]; then
    echo "💿 Packaging ${APP_NAME}.dmg..."
    STAGE_DIR=$(mktemp -d /tmp/deepeak-dmg.XXXXXX)
    cp -R "${APP_PATH}" "${STAGE_DIR}/"
    if command -v create-dmg >/dev/null 2>&1; then
        create-dmg \
            --volname "${APP_NAME}" \
            --volicon "${PROJECT_DIR}/Resources/AppIcon.icns" \
            --window-pos 200 120 \
            --window-size 560 360 \
            --icon-size 110 \
            --icon "${BUNDLE_NAME}" 140 180 \
            --hide-extension "${BUNDLE_NAME}" \
            --app-drop-link 420 180 \
            --format UDZO \
            --overwrite \
            "${PROJECT_DIR}/${APP_NAME}.dmg" \
            "${STAGE_DIR}"
    else
        ln -s /Applications "${STAGE_DIR}/Applications"
        hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGE_DIR}" -ov -format UDZO "${PROJECT_DIR}/${APP_NAME}.dmg"
    fi
    rm -rf "${STAGE_DIR}"
    echo "✅ DMG created at ${PROJECT_DIR}/${APP_NAME}.dmg"
fi
