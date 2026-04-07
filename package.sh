#!/bin/bash
set -e
cd "$(dirname "$0")"

# Build first
bash build.sh

APP_NAME="DeskPin"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_DIR="dist"
STAGING_DIR="$DMG_DIR/staging"

echo ""
echo "Packaging $DMG_NAME..."

# Clean
rm -rf "$DMG_DIR"
mkdir -p "$STAGING_DIR"

# Copy .app to staging
cp -r "build/$APP_NAME.app" "$STAGING_DIR/"

# Create a symlink to /Applications for drag-install
ln -s /Applications "$STAGING_DIR/Applications"

# Create DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_DIR/$DMG_NAME"

# Clean staging
rm -rf "$STAGING_DIR"

echo ""
echo "DMG created: $DMG_DIR/$DMG_NAME"
echo ""
echo "To install:"
echo "  1. Double-click $DMG_NAME"
echo "  2. Drag DeskPin.app to Applications"
echo "  3. Launch from Applications or Spotlight"
