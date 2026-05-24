# Cargo Examples Scripts

Script for running Cargo examples from Cargo.toml.

## Script

### examples.sh

Run all Cargo examples defined in Cargo.toml with their required features.

**Usage:**
```bash
export CARGO_LOCATION="./Cargo.toml"  # Optional, defaults to "./Cargo.toml"
./examples.sh
```

**Environment Variables:**
- `CARGO_LOCATION` (optional) - Path to Cargo.toml, defaults to "./Cargo.toml"

**Requirements:**
- `yq` Python package (will be installed if not present)

**What it does:**
1. Installs yq/tomlq for TOML parsing
2. Checks if examples exist in Cargo.toml
3. Extracts example names and their required features
4. Runs each example with its required features (if specified)
5. Reports completion status for each example

**Example Output:**
```
🚀 Installing yq / tomlq
🚀 Checking for examples in ./Cargo.toml
🏃 Running example: 'basic'
⚡ Features: ''
🎉 Completed running example: basic

🏃 Running example: 'advanced'
⚡ Features: 'feature1,feature2'
🎉 Completed running example: advanced

🚀 Completed running all examples
```

## Testing

Test the script independently:

```bash
cd cargo/examples

# Test with default Cargo.toml
./examples.sh

# Test with specific Cargo.toml location
CARGO_LOCATION="../../path/to/Cargo.toml" ./examples.sh
```

## Integration

This script is used by both:
- The `cargo/examples` action
- The `cargo/build` action (when `examples: "true"`)
