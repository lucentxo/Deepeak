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

chmod +x "${APP_PATH}/Contents/MacOS/DeepSeekStatus"

echo "✅ App bundle created successfully: ${APP_PATH}"
echo "🚀 You can launch it with: open \"${APP_PATH}\""
