#!/bin/bash
# Build Flatpak packages for Linux
set -e

if [ -z "$CRATE" ]; then
  echo "Error: CRATE environment variable not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

if [ -z "$APP_ID" ]; then
  APP_ID="com.42bytelabs.${CRATE}"
  echo "ℹ️  Using default APP_ID: $APP_ID"
fi

ARCH_NAME="x86_64"
FLATPAK_NAME="${CRATE}-${VERSION}-${ARCH_NAME}.flatpak"

echo "📦 Building Flatpak package :: $FLATPAK_NAME"

# Install flatpak-builder if not available
if ! command -v flatpak-builder &>/dev/null; then
  echo "📦 Installing flatpak-builder..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y flatpak flatpak-builder
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y flatpak flatpak-builder
  else
    echo "Error: Could not install flatpak-builder automatically"
    exit 1
  fi
fi

# Add Flathub repository if not already added
if ! flatpak remote-list | grep -q flathub; then
  echo "Adding Flathub repository..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Install SDK if not available
SDK_VERSION="${SDK_VERSION:-23.08}"
if ! flatpak list --runtime | grep -q "org.freedesktop.Sdk/$SDK_VERSION"; then
  echo "📦 Installing Flatpak SDK..."
  flatpak install -y flathub org.freedesktop.Platform//${SDK_VERSION}
  flatpak install -y flathub org.freedesktop.Sdk//${SDK_VERSION}
fi

# Create manifest directory
MANIFEST_DIR="flatpak-build"
mkdir -p "$MANIFEST_DIR"

# Create Flatpak manifest
cat > "${MANIFEST_DIR}/${APP_ID}.yml" << EOF
app-id: ${APP_ID}
runtime: org.freedesktop.Platform
runtime-version: '${SDK_VERSION}'
sdk: org.freedesktop.Sdk
command: ${CRATE}
finish-args:
  - --share=network
  - --share=ipc
  - --socket=x11
  - --socket=wayland
  - --device=dri
  - --filesystem=host
modules:
  - name: ${CRATE}
    buildsystem: simple
    build-commands:
      - cargo build --release
      - install -Dm755 target/release/${CRATE} /app/bin/${CRATE}
    sources:
      - type: dir
        path: ../..
EOF

echo "✅ Flatpak manifest created"

# Build Flatpak
echo "🔨 Building Flatpak..."
flatpak-builder --force-clean --repo=repo "${MANIFEST_DIR}/build-dir" "${MANIFEST_DIR}/${APP_ID}.yml"

# Export as .flatpak bundle
echo "📦 Creating Flatpak bundle..."
flatpak build-bundle repo "${FLATPAK_NAME}" "${APP_ID}"

if [ -f "${FLATPAK_NAME}" ]; then
  echo "✅ Flatpak created: ${FLATPAK_NAME}"
  echo "flatpak-name=${FLATPAK_NAME}" >>"$GITHUB_OUTPUT"
else
  echo "Error: Flatpak build failed"
  exit 1
fi

echo "🎉 Flatpak build complete"
