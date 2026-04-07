#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="DeskPin"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

SDK_PATH=$(xcrun --show-sdk-path)
VFS_OVERLAY="$(pwd)/vfs_overlay.yaml"

echo "Building $APP_NAME..."

# Clean
rm -rf "$BUILD_DIR"

# Create .app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile all Swift sources
swiftc \
    -target arm64-apple-macosx14.0 \
    -sdk "$SDK_PATH" \
    -O \
    -parse-as-library \
    -framework SwiftUI \
    -framework AppKit \
    -Xfrontend -vfsoverlay -Xfrontend "$VFS_OVERLAY" \
    -Xcc -ivfsoverlay -Xcc "$VFS_OVERLAY" \
    -o "$MACOS_DIR/$APP_NAME" \
    $(find Sources -name "*.swift" | sort)

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS/Info.plist"

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
