#!/bin/bash
# Build Linux binaries with MUSL (static linking) for x86_64 architecture
set -e

if [ -z "$CRATE" ]; then
  echo "Error: CRATE environment variable not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

TARGET="x86_64-unknown-linux-musl"
ARCH_NAME="x86_64-musl"
BINARY_NAME="${CRATE}-${VERSION}-${ARCH_NAME}"

echo "🐧 Building Linux MUSL binary :: $BINARY_NAME"

# Install MUSL tools if not available
if ! command -v musl-gcc &>/dev/null; then
  echo "📦 Installing MUSL tools..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y musl-tools
  elif command -v yum &>/dev/null; then
    sudo yum install -y musl-gcc musl-libc-static
  else
    echo "⚠️  Warning: Could not install MUSL tools automatically"
  fi
fi

# Build binary
echo "🔨 Building with MUSL target..."
if [ -n "$FEATURES" ]; then
  cargo build --release -p "${CRATE}" --target "${TARGET}" --features "${FEATURES}"
else
  cargo build --release -p "${CRATE}" --target "${TARGET}"
fi

# Move binary to output location
mv "target/${TARGET}/release/${CRATE}" "${BINARY_NAME}"
chmod +x "${BINARY_NAME}"

echo "✅ Binary built: ${BINARY_NAME}"
echo "binary-name=${BINARY_NAME}" >>$GITHUB_OUTPUT

# Verify it's statically linked
echo "📊 Binary info:"
file "${BINARY_NAME}"
ldd "${BINARY_NAME}" 2>&1 || echo "✅ Statically linked (no dynamic dependencies)"

echo "🎉 Linux MUSL build complete"
