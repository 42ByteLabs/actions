#!/bin/bash
set -e

# Check if tomlq is already installed
if ! command -v tomlq &>/dev/null; then
    echo "📦 Installing yq / tomlq"
    pip install --break-system-packages yq
else
    echo "✅ yq / tomlq already installed"
fi

if [ ! -f "$CARGO_LOCATION" ]; then
    CARGO_LOCATION="./Cargo.toml"
fi

MANIFEST_ARGS=(--manifest-path "$CARGO_LOCATION")

echo "🚀 Checking for examples in $CARGO_LOCATION"

present=$(tomlq -r '.example' "$CARGO_LOCATION")
if [ "$present" == "null" ]; then
    echo "❌ No examples found in Cargo.toml, skipping and exiting..."
    exit 0
fi

examples=$(tomlq -r '.example[].name' "$CARGO_LOCATION")
for example in $examples; do
    echo "🏃 Running example: '$example'"

    features=$(tomlq -r ".example[] | select(.name == \"$example\") | .\"required-features\" | join(\",\")" "$CARGO_LOCATION")
    echo "⚡ Features: '$features'"

    if [ -n "$features" ] && [ "$features" != "null" ]; then
        cargo run "${MANIFEST_ARGS[@]}" --example "$example" --features "$features"
    else
        cargo run "${MANIFEST_ARGS[@]}" --example "$example"
    fi

    echo "🎉 Completed running example: $example"
    echo ""
done

echo "🚀 Completed running all examples"
