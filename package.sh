#!/bin/bash
set -e
cd "$(dirname "$0")"

# Build first
bash build.sh

APP_NAME="DeskPin"
PRODUCT_NAME="macDeskpin"
VERSION="1.0.0"
DMG_NAME="${PRODUCT_NAME}-${VERSION}.dmg"
DMG_DIR="dist"
STAGING_DIR="$DMG_DIR/staging"

echo ""
echo "Packaging $DMG_NAME..."

# Clean
rm -rf "$DMG_DIR"
mkdir -p "$STAGING_DIR"

# Copy .app to staging
cp -r "build/$APP_NAME.app" "$STAGING_DIR/"

# Ad-hoc codesign the .app (free, no Apple Developer account needed).
# Without this, Gatekeeper marks the downloaded app as "damaged" and refuses
# to launch. With ad-hoc signature it falls back to the milder
# "unidentified developer" prompt that the user can bypass via right-click → Open.
echo "Ad-hoc codesigning $APP_NAME.app..."
codesign --force --deep --sign - "$STAGING_DIR/$APP_NAME.app"
codesign --verify --verbose "$STAGING_DIR/$APP_NAME.app" || true

# Create a symlink to /Applications for drag-install
ln -s /Applications "$STAGING_DIR/Applications"

# Create DMG
hdiutil create \
    -volname "$PRODUCT_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_DIR/$DMG_NAME"

# Ad-hoc sign the DMG itself as well
codesign --force --sign - "$DMG_DIR/$DMG_NAME" || true

# Clean staging
rm -rf "$STAGING_DIR"

echo ""
echo "DMG created: $DMG_DIR/$DMG_NAME"
echo ""
echo "To install:"
echo "  1. Double-click $DMG_NAME"
echo "  2. Drag DeskPin.app to Applications"
echo "  3. Launch from Applications or Spotlight"
