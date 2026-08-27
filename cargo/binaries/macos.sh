#!/bin/bash
# Build macOS binaries (ARM64 and x86_64) and create DMG packages
set -e

if [ -z "$CRATE" ]; then
  echo "Error: CRATE environment variable not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

ARCH="${ARCH:-$(uname -m)}"

# Determine target based on architecture
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  TARGET="aarch64-apple-darwin"
  ARCH_NAME="arm64"
elif [ "$ARCH" = "x86_64" ]; then
  TARGET="x86_64-apple-darwin"
  ARCH_NAME="x86_64"
else
  echo "Error: Unsupported architecture: $ARCH"
  exit 1
fi

BINARY_NAME="${CRATE}-${VERSION}-${ARCH_NAME}"
echo "🍎 Building macOS binary :: $BINARY_NAME"

# Build binary
if [ -n "$FEATURES" ]; then
  cargo build --release -p "${CRATE}" --target "${TARGET}" --features "${FEATURES}"
else
  cargo build --release -p "${CRATE}" --target "${TARGET}"
fi

# Move binary to output location
mv "target/${TARGET}/release/${CRATE}" "${BINARY_NAME}"
chmod +x "${BINARY_NAME}"

echo "✅ Binary built: ${BINARY_NAME}"
echo "binary-name=${BINARY_NAME}" >>"$GITHUB_OUTPUT"

# Create DMG if requested
if [ "${CREATE_DMG:-false}" = "true" ]; then
  echo "📦 Creating DMG package..."
  
  DMG_NAME="${CRATE}-${VERSION}-${ARCH_NAME}.dmg"
  APP_DIR="${CRATE}.app"
  
  # Create .app bundle structure
  mkdir -p "${APP_DIR}/Contents/MacOS"
  mkdir -p "${APP_DIR}/Contents/Resources"
  
  # Copy binary
  cp "${BINARY_NAME}" "${APP_DIR}/Contents/MacOS/${CRATE}"
  
  # Create Info.plist
  cat > "${APP_DIR}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${CRATE}</string>
    <key>CFBundleIdentifier</key>
    <string>com.42bytelabs.${CRATE}</string>
    <key>CFBundleName</key>
    <string>${CRATE}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF
  
  # Create DMG
  hdiutil create -volname "${CRATE}" -srcfolder "${APP_DIR}" -ov -format UDZO "${DMG_NAME}"
  
  echo "✅ DMG created: ${DMG_NAME}"
  echo "dmg-name=${DMG_NAME}" >>"$GITHUB_OUTPUT"
fi

echo "🎉 macOS build complete"
