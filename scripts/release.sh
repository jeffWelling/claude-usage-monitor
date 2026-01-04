#!/bin/bash
set -e

cd "$(dirname "$0")/.."

# Get version from argument or prompt
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    # Try to get latest git tag
    LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "Latest tag: $LATEST_TAG"
    read -p "Enter version (e.g., 1.0.0): " VERSION
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

# Validate version format
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.0.0)"
    exit 1
fi

BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo "1")
APP_NAME="ClaudeUsageMonitor"
BUNDLE_ID="com.local.ClaudeUsageMonitor"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"
ZIP_NAME="$APP_NAME-$VERSION.zip"

echo "========================================"
echo "Building $APP_NAME v$VERSION (build $BUILD_NUMBER)"
echo "========================================"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build release binary
echo "Compiling..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Generate Info.plist with version
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Claude Usage Monitor</string>
    <key>CFBundleDisplayName</key>
    <string>Claude Usage Monitor</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. MIT License.</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy icon if exists
if [ -f "resources/AppIcon.icns" ]; then
    cp "resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
    # Add icon reference to Info.plist
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true
fi

echo "App bundle created: $APP_BUNDLE"

# Create ZIP archive
echo "Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r -q "$ZIP_NAME" "$APP_NAME.app"
cd ..
echo "Created: $BUILD_DIR/$ZIP_NAME"

# Create DMG (optional, if create-dmg is available or use hdiutil)
if command -v create-dmg &> /dev/null; then
    echo "Creating DMG with create-dmg..."
    create-dmg \
        --volname "$APP_NAME" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 190 \
        --app-drop-link 450 190 \
        "$BUILD_DIR/$DMG_NAME" \
        "$APP_BUNDLE"
elif command -v hdiutil &> /dev/null; then
    echo "Creating DMG with hdiutil..."
    # Create temporary DMG directory
    DMG_TEMP="$BUILD_DIR/dmg_temp"
    mkdir -p "$DMG_TEMP"
    cp -R "$APP_BUNDLE" "$DMG_TEMP/"

    # Create symlink to Applications
    ln -s /Applications "$DMG_TEMP/Applications"

    # Create DMG
    hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

    # Cleanup
    rm -rf "$DMG_TEMP"
    echo "Created: $BUILD_DIR/$DMG_NAME"
fi

echo ""
echo "========================================"
echo "Release v$VERSION complete!"
echo "========================================"
echo ""
echo "Artifacts:"
ls -lh "$BUILD_DIR"/*.{zip,dmg} 2>/dev/null || ls -lh "$BUILD_DIR"/*.zip
echo ""
echo "To create a git tag:"
echo "  git tag -a v$VERSION -m 'Release v$VERSION'"
echo "  git push origin v$VERSION"
