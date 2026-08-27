#!/bin/bash
# Build Rust/Cargo project with optional features
set -e

MANIFEST_ARGS=()
if [ -n "${CARGO_LOCATION:-}" ]; then
    MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")
fi

# Determine build scope based on project type
BUILD_SCOPE=()
if [ "$PROJECT_WORKSPACE" = "true" ]; then
    BUILD_SCOPE=(--workspace)
    echo "🏢 Building workspace project"
elif [ -n "$PROJECT_CRATE" ]; then
    BUILD_SCOPE=(-p "$PROJECT_CRATE")
    echo "📦 Building specific crate: ${PROJECT_CRATE}"
else
    echo "📦 Building single crate project"
fi

# Build with features if specified
if [ -n "$CARGO_FEATURES" ]; then
    echo "📦 Standard build with features: '${CARGO_FEATURES}'"
    cargo build "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --features "${CARGO_FEATURES}"
else
    echo "📦 Standard build (default)"
    cargo build "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}"
fi

# Build with no default features
echo "📦 Build with no default features"
if [ -n "$CARGO_FEATURES" ]; then
    cargo build "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --no-default-features --features "${CARGO_FEATURES}"
else
    cargo build "${MANIFEST_ARGS[@]}" "${BUILD_SCOPE[@]}" --no-default-features
fi

echo "✅ Build completed successfully"
