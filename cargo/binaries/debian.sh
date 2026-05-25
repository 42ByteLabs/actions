#!/bin/bash
# Build Debian packages (.deb) for x86_64 architecture
set -e

if [ -z "$CRATE" ]; then
  echo "Error: CRATE environment variable not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

TARGET="x86_64-unknown-linux-gnu"
ARCH_NAME="x86_64"
BINARY_NAME="${CRATE}-${VERSION}-${ARCH_NAME}"

echo "🐧 Building Debian package :: ${CRATE}-${VERSION}-${ARCH_NAME}.deb"

# Install cargo-deb if not available
if ! command -v cargo-deb &>/dev/null; then
  echo "📦 Installing cargo-deb..."
  cargo install cargo-deb
fi

# Build binary first
if [ -n "$FEATURES" ]; then
  cargo build --release -p "${CRATE}" --target "${TARGET}" --features "${FEATURES}"
else
  cargo build --release -p "${CRATE}" --target "${TARGET}"
fi

# Copy binary
cp "target/${TARGET}/release/${CRATE}" "${BINARY_NAME}"
chmod +x "${BINARY_NAME}"

echo "✅ Binary built: ${BINARY_NAME}"
echo "binary-name=${BINARY_NAME}" >>$GITHUB_OUTPUT

# Create .deb package if requested
if [ "${CREATE_DEB:-false}" = "true" ]; then
  echo "📦 Creating .deb package..."
  
  # Build .deb package
  if [ -n "$FEATURES" ]; then
    cargo deb -p "${CRATE}" --target "${TARGET}" --features "${FEATURES}" --no-build
  else
    cargo deb -p "${CRATE}" --target "${TARGET}" --no-build
  fi
  
  # Find the generated .deb file
  DEB_FILE=$(find target/${TARGET}/debian -name "*.deb" -type f | head -n 1)
  
  if [ -n "$DEB_FILE" ]; then
    DEB_NAME="${CRATE}-${VERSION}-${ARCH_NAME}.deb"
    cp "$DEB_FILE" "$DEB_NAME"
    echo "✅ Debian package created: ${DEB_NAME}"
    echo "deb-name=${DEB_NAME}" >>$GITHUB_OUTPUT
  else
    echo "⚠️  Warning: .deb file not found"
  fi
fi

echo "🎉 Debian build complete"
