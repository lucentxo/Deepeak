#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Deepeak"
BUNDLE_NAME="${APP_NAME}.app"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${PROJECT_DIR}/${BUNDLE_NAME}"

CLEAN=false
RUN_TESTS=false
BUILD_DMG=false
BUILD_CONFIG="release"
RUN_APP=false

usage() {
    echo "Usage: ./build.sh [options]"
    echo ""
    echo "Options:"
    echo "  --clean       Clean previous build artifacts (.build, Deepeak.app, DMG, ZIP)"
    echo "  --test, -t    Run the test suite ('swift test') before bundling"
    echo "  --dmg         Package the app bundle into a distributable DMG and ZIP"
    echo "  --debug       Build with debug configuration (default is release)"
    echo "  --release     Build with release configuration"
    echo "  --run         Launch Deepeak.app immediately after successful build"
    echo "  --help, -h    Display this help message"
}

for arg in "$@"; do
    case "$arg" in
        --clean)
            CLEAN=true
            ;;
        --test|-t)
            RUN_TESTS=true
            ;;
        --dmg)
            BUILD_DMG=true
            ;;
        --debug)
            BUILD_CONFIG="debug"
            ;;
        --release)
            BUILD_CONFIG="release"
            ;;
        --run)
            RUN_APP=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $arg"
            echo "Run './build.sh --help' for available options."
            exit 1
            ;;
    esac
done

if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning build artifacts..."
    swift package clean 2>/dev/null || true
    rm -rf "${APP_PATH}" "${PROJECT_DIR}/${APP_NAME}.dmg" "${PROJECT_DIR}/${APP_NAME}.zip" "${PROJECT_DIR}/build"
    echo "✅ Clean completed."
fi

if [ "$RUN_TESTS" = true ]; then
    echo "🧪 Running unit tests (swift test)..."
    swift test
    echo "✅ All tests passed successfully."
fi

echo "🔨 Compiling DeepSeekStatus (${BUILD_CONFIG})..."
swift build -c "${BUILD_CONFIG}"

# Find the binary path for the selected configuration
BIN_PATH="$(swift build -c "${BUILD_CONFIG}" --show-bin-path)/DeepSeekStatus"

if [ ! -f "${BIN_PATH}" ]; then
    echo "❌ Error: Build output executable not found at ${BIN_PATH}"
    exit 1
fi

echo "📦 Creating macOS App Bundle at ${APP_PATH}..."
rm -rf "${APP_PATH}"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

# Copy binary, plist, and assets
cp "${BIN_PATH}" "${APP_PATH}/Contents/MacOS/DeepSeekStatus"
if [ -f "${PROJECT_DIR}/Resources/Info.plist" ]; then
    cp "${PROJECT_DIR}/Resources/Info.plist" "${APP_PATH}/Contents/Info.plist"
fi
if [ -f "${PROJECT_DIR}/Resources/deepseek_logo.png" ]; then
    cp "${PROJECT_DIR}/Resources/deepseek_logo.png" "${APP_PATH}/Contents/Resources/deepseek_logo.png"
fi
if [ -f "${PROJECT_DIR}/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${APP_PATH}/Contents/Resources/AppIcon.icns"
fi

# Ensure executable permissions inside bundle
chmod +x "${APP_PATH}/Contents/MacOS/DeepSeekStatus"

# Apply ad-hoc code signature for modern macOS security compliance
if command -v codesign >/dev/null 2>&1; then
    echo "🔏 Applying ad-hoc code signature..."
    codesign --force --deep --sign - "${APP_PATH}" 2>/dev/null || true
fi

echo "✅ App bundle created successfully: ${APP_PATH}"

if [ "$BUILD_DMG" = true ]; then
    echo "💿 Packaging ${APP_NAME}.dmg..."
    STAGE_DIR=$(mktemp -d /tmp/deepeak-dmg.XXXXXX)
    cleanup_stage() {
        rm -rf "${STAGE_DIR}"
    }
    trap cleanup_stage EXIT INT TERM

    cp -R "${APP_PATH}" "${STAGE_DIR}/"
    if command -v create-dmg >/dev/null 2>&1; then
        create-dmg \
            --volname "${APP_NAME}" \
            --window-pos 200 120 \
            --window-size 540 360 \
            --icon-size 110 \
            --icon "${BUNDLE_NAME}" 140 180 \
            --hide-extension "${BUNDLE_NAME}" \
            --app-drop-link 400 180 \
            --format UDZO \
            --overwrite \
            "${PROJECT_DIR}/${APP_NAME}.dmg" \
            "${STAGE_DIR}"
    else
        ln -s /Applications "${STAGE_DIR}/Applications"
        rm -f "${PROJECT_DIR}/${APP_NAME}.dmg"
        hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGE_DIR}" -ov -format UDZO "${PROJECT_DIR}/${APP_NAME}.dmg"
    fi

    cleanup_stage
    trap - EXIT INT TERM
    echo "✅ DMG created at ${PROJECT_DIR}/${APP_NAME}.dmg"

    echo "🗜 Packaging ZIP archive..."
    rm -f "${PROJECT_DIR}/${APP_NAME}.zip"
    zip -9 -j "${PROJECT_DIR}/${APP_NAME}.zip" "${PROJECT_DIR}/${APP_NAME}.dmg"
    echo "✅ ZIP created at ${PROJECT_DIR}/${APP_NAME}.zip"
fi

if [ "$RUN_APP" = true ]; then
    echo "🚀 Launching ${BUNDLE_NAME}..."
    open "${APP_PATH}"
else
    echo "🚀 You can launch it with: open \"${APP_PATH}\""
fi
