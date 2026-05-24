#!/bin/bash
set -e

# Check if tomlq is already installed
if ! command -v tomlq &>/dev/null; then
    echo "📦 Installing yq / tomlq"
    pip install --break-system-packages yq
else
    echo "✅ yq / tomlq already installed"
fi

if [ ! -f $CARGO_LOCATION ]; then
    CARGO_LOCATION="./Cargo.toml"
fi

echo "🚀 Checking for examples in $CARGO_LOCATION"

present=$(cat $CARGO_LOCATION | tomlq -r '.example')
if [ "$present" == "null" ]; then
    echo "❌ No examples found in Cargo.toml, skipping and exiting..."
    exit 0
fi

examples=$(cat $CARGO_LOCATION | tomlq -r '.example[].name')
for example in $examples; do
    echo "🏃 Running example: '$example'"

    features=$(cat $CARGO_LOCATION | tomlq -r ".example[] | select(.name == \"$example\") | .\"required-features\" | join(\",\")")
    echo "⚡ Features: '$features'"

    if [ -n "$features" ] && [ "$features" != "null" ]; then
        cargo run --example "$example" --features "$features"
    else
        cargo run --example "$example"
    fi

    echo "🎉 Completed running example: $example"
    echo ""
done

echo "🚀 Completed running all examples"
