#!/bin/bash
# Build AppImage packages for Linux
set -e

if [ -z "$CRATE" ]; then
  echo "Error: CRATE environment variable not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

TARGET="${TARGET:-x86_64-unknown-linux-gnu}"
ARCH_NAME="x86_64"
APPIMAGE_NAME="${CRATE}-${VERSION}-${ARCH_NAME}.AppImage"

echo "📦 Building AppImage :: $APPIMAGE_NAME"

# Build binary first
if [ -n "$FEATURES" ]; then
  cargo build --release -p "${CRATE}" --target "${TARGET}" --features "${FEATURES}"
else
  cargo build --release -p "${CRATE}" --target "${TARGET}"
fi

# Download appimagetool if not available
APPIMAGETOOL="appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
  echo "📥 Downloading appimagetool..."
  wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/${APPIMAGETOOL}"
  chmod +x "$APPIMAGETOOL"
fi

# Create AppDir structure
APPDIR="${CRATE}.AppDir"
rm -rf "$APPDIR"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"

# Copy binary
cp "target/${TARGET}/release/${CRATE}" "${APPDIR}/usr/bin/${CRATE}"
chmod +x "${APPDIR}/usr/bin/${CRATE}"

# Create desktop file
cat > "${APPDIR}/usr/share/applications/${CRATE}.desktop" << EOF
[Desktop Entry]
Type=Application
Name=${CRATE}
Exec=${CRATE}
Icon=${CRATE}
Categories=Utility;
Terminal=false
EOF

# Create AppRun script
cat > "${APPDIR}/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
exec "${HERE}/usr/bin/${CRATE}" "$@"
EOF

# Replace ${CRATE} in AppRun
sed -i "s/\${CRATE}/${CRATE}/g" "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# Create icon (placeholder - should be replaced with actual icon)
if [ -f "assets/${CRATE}.png" ]; then
  cp "assets/${CRATE}.png" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${CRATE}.png"
  cp "assets/${CRATE}.png" "${APPDIR}/${CRATE}.png"
elif [ -f "icon.png" ]; then
  cp "icon.png" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/${CRATE}.png"
  cp "icon.png" "${APPDIR}/${CRATE}.png"
else
  echo "⚠️  Warning: No icon found at assets/${CRATE}.png or icon.png"
  # Create a placeholder icon
  echo "Creating placeholder icon..."
  convert -size 256x256 xc:blue "${APPDIR}/${CRATE}.png" 2>/dev/null || echo "ImageMagick not available, skipping icon"
fi

# Copy desktop file to AppDir root
cp "${APPDIR}/usr/share/applications/${CRATE}.desktop" "${APPDIR}/${CRATE}.desktop"

# Build AppImage
echo "🔨 Building AppImage..."
ARCH=x86_64 ./"$APPIMAGETOOL" "$APPDIR" "$APPIMAGE_NAME"

if [ -f "$APPIMAGE_NAME" ]; then
  chmod +x "$APPIMAGE_NAME"
  echo "✅ AppImage created: ${APPIMAGE_NAME}"
  echo "appimage-name=${APPIMAGE_NAME}" >>"$GITHUB_OUTPUT"
else
  echo "Error: AppImage build failed"
  exit 1
fi

echo "🎉 AppImage build complete"
