#!/bin/bash

# Build script for MouseEyes macOS app

set -e

# Change to script directory
cd "$(dirname "$0")"

echo "Building MouseEyes..."

# Build the executable
swift build -c release

# Create app bundle structure
APP_NAME="MouseEyes"
APP_DIR="build/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

# Clean and create directories
rm -rf build
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy executable
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/"

# Copy Info.plist
cp Info.plist "${CONTENTS_DIR}/"

# Create PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

echo "✅ Build complete! App bundle created at: ${APP_DIR}"
echo ""
echo "To run the app:"
echo "  open ${APP_DIR}"
echo ""
echo "To install to Applications folder:"
echo "  cp -r ${APP_DIR} /Applications/"
echo ""
echo "⚠️  Note: On first launch, you may need to grant accessibility permissions:"
echo "   System Settings > Privacy & Security > Accessibility"
