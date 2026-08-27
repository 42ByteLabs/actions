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
   - Sets `crate-outdated=true` if local version is newer or the crate is not published yet
   - Skips if the registry version is equal or newer
2. **Setup Rust toolchain** (if publishing)
3. **Build & validate** using cargo/build scripts (if publishing)
4. **Publish crate(s)** using publish-crate.sh
   - Single crate: `cargo publish --allow-dirty`
   - Multiple crates: checks each crate and publishes in order with a 30-second delay between publishes
5. **Create GitHub release** (if enabled)
   - Creates git tag `{version}`
   - Fails if the tag already exists locally or remotely
   - Creates release with auto-generated notes

## Scripts

### publish-crate.sh
**Env vars:**
- `CARGO_REGISTRY_TOKEN` - crates.io token
- `CRATES` - Comma-separated list (optional)
- `CARGO_LOCATION` - Path to Cargo.toml (optional)
- `DRY_RUN` - Set to `true` to run `cargo publish --dry-run`

**Behavior:**
- If `CRATES` set: Checks each crate and publishes only versions newer than crates.io, with a 30-second delay between publishes
- Otherwise: Checks and publishes the selected crate with `cargo publish --allow-dirty`

### create-release.sh
**Env vars:**
- `GH_TOKEN` - GitHub token
- `VERSION` - Version (e.g., "1.2.3")

**Creates:**
- Tag: `{VERSION}` (e.g., `1.2.3`)
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
- 30-second delay between published crates (allows crates.io to update)
- Dependencies must be published before dependents
- All crates must be in workspace

## Version Checking

- Uses `cargo search`, then the crates.io API fallback, to find the latest version
- Publishes only when the local version is newer than crates.io or the crate is not published yet
- Skips publishing if the registry version is equal or newer
- Workspace `crates` entries are checked independently by `publish-crate.sh`

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
export DRY_RUN="true"
./publish-crate.sh

# Test release
export GH_TOKEN="your-token"
export VERSION="1.2.3"
./create-release.sh
```
