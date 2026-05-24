# Cargo Publish Action

Publish crates to crates.io with version checking and GitHub release creation.

## Usage

```yaml
- uses: 42ByteLabs/actions/cargo/publish@main
  with:
    crate: "my-crate"
    cargo-token: ${{ secrets.CARGO_TOKEN }}
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `crate` | ✅ | - | Crate name |
| `cargo-token` | ✅ | - | crates.io API token |
| `crates` | ❌ | - | Comma-separated crates to publish in order |
| `cargo` | ❌ | `./Cargo.toml` | Path to Cargo.toml |
| `rust-toolchain` | ❌ | `stable` | Rust toolchain |
| `create-github-release` | ❌ | `true` | Create GitHub release after publishing |

## Outputs

| Output | Description |
|--------|-------------|
| `name` | Package name |
| `version` | Published version |
| `published` | `true` if published, `false` if skipped |
| `workspace` | `true` if workspace |
| `workspace-members` | Comma-separated member names |
| `crate-latest` | Latest version on crates.io |
| `crate-outdated` | `true` if local version is newer |

## Permissions

```yaml
permissions:
  contents: write  # For creating releases and tags
```

**Secrets:**
```yaml
secrets:
  CARGO_TOKEN: ${{ secrets.CARGO_TOKEN }}
```

## What It Does

1. **Load project & check version** using cargo/project
   - Extracts version from Cargo.toml
   - Queries crates.io API
   - Sets `crate-outdated=true` if local version is newer
   - Skips if versions match
2. **Setup Rust toolchain** (if publishing)
3. **Build & validate** using cargo/build scripts (if publishing)
4. **Publish crate(s)** using publish-crate.sh
   - Single crate: `cargo publish`
   - Multiple crates: Publishes in order with 30s delay
5. **Create GitHub release** (if enabled)
   - Creates git tag `v{version}`
   - Pushes tag
   - Creates release with auto-generated notes

## Scripts

### publish-crate.sh
**Env vars:**
- `CARGO_REGISTRY_TOKEN` - crates.io token
- `CRATES` - Comma-separated list (optional)

**Behavior:**
- If `CRATES` set: Publishes each with 30s delay
- Otherwise: `cargo publish --allow-dirty`

### create-release.sh
**Env vars:**
- `GH_TOKEN` - GitHub token
- `VERSION` - Version (e.g., "1.2.3")
- `REF_NAME` - Git ref name

**Creates:**
- Tag: `v{VERSION}` (e.g., `v1.2.3`)
- GitHub release with auto-generated notes

## Examples

### Single crate
```yaml
- uses: 42ByteLabs/actions/cargo/publish@main
  with:
    crate: "my-crate"
    cargo-token: ${{ secrets.CARGO_TOKEN }}
```

### Workspace with dependencies
```yaml
- uses: 42ByteLabs/actions/cargo/publish@main
  with:
    crate: "my-workspace"
    crates: "my-core,my-utils,my-cli"  # Order matters
    cargo-token: ${{ secrets.CARGO_TOKEN }}
```

### Without GitHub release
```yaml
- uses: 42ByteLabs/actions/cargo/publish@main
  with:
    crate: "my-crate"
    cargo-token: ${{ secrets.CARGO_TOKEN }}
    create-github-release: "false"
```

## Multi-Crate Publishing

When using `crates` input:
- Publishes in specified order
- 30-second delay between each (allows crates.io to update)
- Dependencies must be published before dependents
- All crates must be in workspace

## Version Checking

- Queries crates.io API for latest version
- Compares with Cargo.toml version
- Skips publishing if versions match
- Only builds/validates if version is newer

## Testing Scripts Locally

```bash
cd cargo/publish

# Test version check
export CRATE_NAME="serde"
export CARGO_LOCATION="./Cargo.toml"
./check-version.sh

# Test publish (dry-run)
export CARGO_REGISTRY_TOKEN="your-token"
export CRATES="crate1,crate2"
./publish-crate.sh

# Test release
export GH_TOKEN="your-token"
export VERSION="1.2.3"
export REF_NAME="main"
./create-release.sh
```
