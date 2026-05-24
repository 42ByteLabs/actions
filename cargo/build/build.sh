#!/bin/bash
# Build Rust/Cargo project with optional features
set -e

if [ -n "$CARGO_FEATURES" ]; then
    echo "📦 Standard build with features: '${CARGO_FEATURES}'"
    cargo build --workspace --features "${CARGO_FEATURES}"
else
    echo "📦 Standard build (default)"
    cargo build --workspace
fi

echo "📦 Disable all features"
cargo build --no-default-features

echo "✅ Build completed successfully"
