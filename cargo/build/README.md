# Cargo Build Action

Build and test Rust projects with formatting, linting, and security checks.

## Usage

```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    features: "my-feature"
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `crate` | - | Crate name (optional) |
| `features` | `""` | Comma-separated features |
| `cargo` | `./Cargo.toml` | Path to Cargo.toml |
| `rust-toolchain` | `stable` | stable, beta, or nightly |
| `cache` | `true` | Use GitHub Actions cache |
| `format` | `true` | Run cargo fmt --check |
| `clippy` | `true` | Run Clippy (stable only) |
| `tests` | `true` | Run cargo test |
| `docs` | `true` | Run cargo doc --no-deps |
| `security` | `true` | Run cargo-audit and cargo-deny |
| `examples` | `false` | Run cargo examples |

## Outputs

| Output | Description |
|--------|-------------|
| `name` | Package name |
| `version` | Package version |
| `rust-version` | MSRV |
| `workspace` | `true` if workspace |
| `workspace-members` | Comma-separated member names |

## Permissions

```yaml
permissions:
  contents: read
  security-events: write  # For Clippy SARIF upload
```

## What It Does

1. **Load project metadata** using cargo/project action
2. **Setup Rust toolchain** with clippy and rustfmt components
3. **Restore cache** (if enabled)
4. **cargo fmt --check** (if enabled)
5. **cargo build** with features
6. **cargo build --no-default-features** (validates minimal build)
7. **cargo test** on workspace, examples, and binaries (if enabled)
8. **cargo doc --no-deps** with features (if enabled)
9. **Run examples** using cargo/examples (if enabled)
10. **Clippy** with SARIF output (stable only, if enabled)
11. **Security audit** using cargo/security (if enabled)
12. **Save cache** on push to main (if enabled)

## Build Scope Logic

Scripts use `PROJECT_WORKSPACE` and `PROJECT_CRATE` env vars:
- Workspace: `cargo build --workspace`
- Specific crate: `cargo build -p $PROJECT_CRATE`
- Single crate: `cargo build`

## Scripts

### build.sh
Builds with features, then builds with `--no-default-features`.

**Env vars:**
- `PROJECT_WORKSPACE` - "true" for workspace builds
- `PROJECT_CRATE` - Crate name for `-p` flag
- `CARGO_FEATURES` - Features to enable

### test.sh
Runs tests on workspace, examples, and binaries.

**Env vars:** Same as build.sh

### docs.sh
Builds documentation with `cargo doc --no-deps`.

**Env vars:** Same as build.sh

### clippy.sh
Runs clippy and generates `rust-clippy-results.sarif`.

Installs `clippy-sarif` and `sarif-fmt` if needed.

## Cache Strategy

**Key:** `${{ runner.os }}-${{ inputs.rust-toolchain }}-cargo`

**Paths:**
- `~/.cargo/bin/`
- `~/.cargo/registry/index/`
- `~/.cargo/registry/cache/`
- `~/.cargo/git/db/`
- `target/`

**Behavior:**
- Restored on every run
- Saved only on push to main

## Clippy SARIF

- Only runs on `stable` Rust
- Uploads to GitHub Code Scanning
- Requires `security-events: write` permission
- Output file: `rust-clippy-results.sarif`

## Examples

### Minimal
```yaml
- uses: 42ByteLabs/actions/cargo/build@main
```

### With features
```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    features: "feature1,feature2"
```

### Nightly without clippy
```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    rust-toolchain: "nightly"
    clippy: "false"  # Clippy only runs on stable anyway
```

### No cache
```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    cache: "false"
```

### All features enabled
```yaml
- uses: 42ByteLabs/actions/cargo/build@main
  with:
    format: "true"
    clippy: "true"
    tests: "true"
    docs: "true"
    security: "true"
    examples: "true"
```

## Testing Scripts Locally

```bash
cd cargo/build

# Build
export PROJECT_WORKSPACE="true"
export CARGO_FEATURES="my-feature"
./build.sh

# Test
./test.sh

# Docs
./docs.sh

# Clippy
./clippy.sh
```
