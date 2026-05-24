# Cargo Build Action

Build and test Rust/Cargo projects with formatting, linting, and clippy checks.

## Features

- **Rust Toolchain Setup**: Configurable Rust version (stable, beta, nightly)
- **Cargo Caching**: Smart caching of Cargo dependencies and build artifacts
- **Code Formatting**: Automatic `cargo fmt` checks
- **Building**: Build with optional features and minimal feature validation
- **Testing**: Run workspace, example, and binary tests
- **Clippy Analysis**: Static analysis with SARIF output for GitHub Code Scanning
- **Example Running**: Optional execution of Cargo examples
- **Security Checks**: Optional cargo security tooling

## Usage

### Basic Build

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
```

### Build with Features

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    features: "feature1,feature2"
```

### Build with All Checks

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    features: "all"
    format: "true"
    clippy: "true"
    tests: "true"
    examples: "true"
```

### Build with Nightly Rust

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    version: "nightly"
    clippy: "false"  # Clippy only runs on stable
```

### Build without Caching

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    cache: "false"
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `package` | Cargo package name | No | - |
| `features` | Comma-separated list of features to enable | No | - |
| `cargo` | Path to Cargo.toml | No | `./Cargo.toml` |
| `version` | Rust version to use (stable, beta, nightly) | No | `stable` |
| `cache` | Use GitHub Actions cache for Cargo | No | `true` |
| `format` | Run cargo fmt checks | No | `true` |
| `clippy` | Run Clippy checks (stable only) | No | `true` |
| `tests` | Run cargo tests | No | `true` |
| `security` | Run cargo security tooling | No | `true` |
| `examples` | Run cargo examples | No | `false` |

## Permissions

### For Clippy SARIF Upload

```yaml
permissions:
  security-events: write  # For uploading SARIF results
  contents: read
```

## Complete Example

```yaml
name: Build and Test

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  security-events: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: 42ByteLabs/actions/cargo/build@main
        with:
          features: "all"
          version: "stable"
          format: "true"
          clippy: "true"
          tests: "true"
          examples: "true"
```

## Workflow

1. **Setup Rust Toolchain**:
   - Installs specified Rust version (stable/beta/nightly)
   - Installs clippy and rustfmt components

2. **Restore Cache** (if enabled):
   - Restores Cargo binaries, registry, and build artifacts
   - Cache key: `${{ runner.os }}-${{ inputs.rust-version }}-cargo`

3. **Format Check** (if enabled):
   - Runs `cargo fmt --check`
   - Fails if code is not formatted

4. **Build**:
   - Builds with specified features (or default)
   - Validates minimal build (no default features)

5. **Tests** (if enabled):
   - Runs workspace tests
   - Runs example tests
   - Runs binary tests

6. **Examples** (if enabled):
   - Runs all Cargo examples defined in Cargo.toml
   - Uses the [examples action](../examples/) script

7. **Clippy** (if enabled, stable only):
   - Runs Clippy analysis
   - Generates SARIF output: `rust-clippy-results.sarif`
   - Uploads SARIF to GitHub Code Scanning

8. **Save Cache** (if enabled):
   - Saves cache on push to main branch
   - Caches Cargo binaries, registry, and build artifacts

## Scripts

This action uses the following bash scripts:

### build.sh

Build the Rust/Cargo project with optional features.

**Environment Variables:**
- `CARGO_FEATURES` (optional) - Comma-separated list of features to enable

**What it does:**
1. Builds the workspace with specified features (or default)
2. Builds with no default features (to verify minimal build)

### test.sh

Run all Cargo tests including workspace, examples, and bins.

**Environment Variables:**
- `CARGO_FEATURES` (optional) - Comma-separated list of features to enable

**What it does:**
1. Runs workspace tests with features
2. Runs example tests
3. Runs binary tests

### clippy.sh

Run Clippy analysis and generate SARIF output for GitHub Code Scanning.

**Requirements:**
- `clippy-sarif` and `sarif-fmt` will be installed if not present

**What it does:**
1. Installs required tools if needed
2. Runs Clippy on all features and targets
3. Generates SARIF output file: `rust-clippy-results.sarif`

## External Dependencies

### Running Examples

When `examples: "true"` is set, the build action uses the [examples action](../examples/) script to run Cargo examples. See [examples/README.md](../examples/README.md) for details.

## Testing Scripts

All scripts can be tested independently:

```bash
cd cargo/build

# Test build
CARGO_FEATURES="all" ./build.sh

# Test with specific features
CARGO_FEATURES="feature1,feature2" ./build.sh

# Test without features
./build.sh

# Test tests
CARGO_FEATURES="all" ./test.sh

# Test clippy
./clippy.sh
```

**Note:** To test examples, see [examples/README.md](../examples/README.md).

## Caching Strategy

The action uses GitHub Actions cache to speed up builds:

- **Cache Key**: `${{ runner.os }}-${{ inputs.rust-version }}-cargo`
- **Cached Paths**:
  - `~/.cargo/bin/` - Cargo binaries
  - `~/.cargo/registry/index/` - Registry index
  - `~/.cargo/registry/cache/` - Downloaded crates
  - `~/.cargo/git/db/` - Git dependencies
  - `target/` - Build artifacts

- **Cache Behavior**:
  - Restored at the beginning of every run
  - Saved only on push to main branch
  - Separate cache per OS and Rust version

## Clippy SARIF Output

When Clippy is enabled on stable Rust:

1. Clippy runs with all features and targets
2. Output is converted to SARIF format
3. SARIF file is uploaded to GitHub Code Scanning
4. Results appear in the Security tab

**Requirements for SARIF upload:**
- Must run on `stable` Rust version
- Requires `security-events: write` permission
- SARIF file: `rust-clippy-results.sarif`

## Feature Validation

The build action validates that your crate works in multiple configurations:

1. **With Features**: `cargo build --features "your,features"`
2. **Minimal Build**: `cargo build --no-default-features`

This ensures your crate is usable both with and without optional features.
