#!/bin/bash
# Build Arch Linux packages (.pkg.tar.zst) for x86_64 architecture
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

echo "🏛️  Building Arch Linux package :: ${CRATE}-${VERSION}-${ARCH_NAME}.pkg.tar.zst"

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
echo "binary-name=${BINARY_NAME}" >>"$GITHUB_OUTPUT"

# Create PKGBUILD package if requested
if [ "${CREATE_PKG:-false}" = "true" ]; then
  echo "📦 Creating Arch Linux package..."
  
  # Install base-devel if needed (for makepkg)
  if ! command -v makepkg &>/dev/null; then
    echo "⚠️  makepkg not found. Installing base-devel..."
    if command -v pacman &>/dev/null; then
      sudo pacman -Sy --noconfirm base-devel
    else
      echo "Error: Not running on Arch Linux. Cannot install makepkg."
      exit 1
    fi
  fi
  
  # Create build directory
  PKG_DIR="pkg-build"
  rm -rf "$PKG_DIR"
  mkdir -p "$PKG_DIR"
  
  # Copy binary to build directory
  cp "${BINARY_NAME}" "$PKG_DIR/"
  
  # Get maintainer info (use git if available, otherwise use defaults)
  if command -v git &>/dev/null; then
    MAINTAINER_NAME=$(git config user.name 2>/dev/null || echo "Unknown")
    MAINTAINER_EMAIL=$(git config user.email 2>/dev/null || echo "unknown@example.com")
  else
    MAINTAINER_NAME="${MAINTAINER_NAME:-Unknown}"
    MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-unknown@example.com}"
  fi
  
  # Get description from Cargo.toml if available
  if [ -f "Cargo.toml" ] && command -v tomlq &>/dev/null; then
    DESCRIPTION=$(tomlq -r '.package.description // "A Rust application"' Cargo.toml)
    LICENSE=$(tomlq -r '.package.license // "custom"' Cargo.toml)
  else
    DESCRIPTION="${DESCRIPTION:-A Rust application}"
    LICENSE="${LICENSE:-custom}"
  fi
  
  # Create PKGBUILD
  cat > "$PKG_DIR/PKGBUILD" << EOF
# Maintainer: ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>
pkgname=${CRATE}
pkgver=${VERSION}
pkgrel=1
pkgdesc="${DESCRIPTION}"
arch=('x86_64')
url="https://github.com/42ByteLabs/${CRATE}"
license=('${LICENSE}')
depends=()
makedepends=()
source=("${BINARY_NAME}")
sha256sums=('SKIP')

package() {
    install -Dm755 "\${srcdir}/${BINARY_NAME}" "\${pkgdir}/usr/bin/${CRATE}"
}
EOF
  
  echo "✅ PKGBUILD created"
  cat "$PKG_DIR/PKGBUILD"
  
  # Build package
  echo "🔨 Building Arch package..."
  cd "$PKG_DIR"
  
  # Run makepkg (skip integrity checks for local build)
  if makepkg --skipinteg --nodeps 2>&1; then
    # Find the generated package file
    PKG_FILE=$(find . -name "${CRATE}-${VERSION}-*.pkg.tar.zst" -type f | head -n 1)
    
    if [ -n "$PKG_FILE" ]; then
      PKG_NAME="${CRATE}-${VERSION}-${ARCH_NAME}.pkg.tar.zst"
      cp "$PKG_FILE" "../${PKG_NAME}"
      cd ..
      echo "✅ Arch package created: ${PKG_NAME}"
      echo "pkg-name=${PKG_NAME}" >>"$GITHUB_OUTPUT"
      
      # Show package info
      echo "📊 Package info:"
      if command -v pacman &>/dev/null; then
        pacman -Qip "$PKG_NAME" 2>/dev/null || echo "Package info not available"
      fi
    else
      cd ..
      echo "⚠️  Warning: .pkg.tar.zst file not found"
    fi
  else
    cd ..
    echo "Error: makepkg failed"
    exit 1
  fi
fi

echo "🎉 Arch Linux build complete"
