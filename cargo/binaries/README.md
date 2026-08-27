# Cargo Binaries Action

Build Rust binaries for multiple platforms and create packages (DMG, DEB, PKG, MSI, AppImage, Flatpak).

## Usage

```yaml
- uses: 42ByteLabs/actions/cargo/binaries@main
  with:
    platform: linux
    create-package: true
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `platform` | ✅ | - | `macos`, `linux`, or `windows` |
| `linux-platform` | ❌ | auto | `debian`, `arch`, `musl`, `flatpak`, `appimage` |
| `crate` | ❌ | auto | Crate name (auto-detected from Cargo.toml) |
| `version` | ❌ | auto | Version (auto-detected from Cargo.toml) |
| `cargo` | ❌ | `./Cargo.toml` | Path to Cargo.toml |
| `features` | ❌ | `""` | Cargo features |
| `rust-toolchain` | ❌ | `stable` | Rust toolchain |
| `create-package` | ❌ | `false` | Create platform package |
| `upload-release` | ❌ | `true` | Upload to GitHub Release |
| `create-attestation` | ❌ | `true` | Create build attestation |
| `app-id` | ❌ | `com.42bytelabs.{crate}` | App ID (Flatpak only) |

## Outputs

| Output | Description |
|--------|-------------|
| `binary-name` | Built binary filename |
| `package-name` | Package filename (if created) |

## Permissions

```yaml
permissions:
  contents: write      # Upload to GitHub Release
  attestations: write  # Build attestations
  id-token: write      # Sign attestations
```

## Supported Platforms

### macOS
- **Targets:** ARM64, x86_64
- **Package:** DMG (if `create-package: true`)
- **Output:** `{crate}-{version}-{arch}`, `{crate}-{version}-{arch}.dmg`

### Linux
Auto-detects from `/etc/os-release` or use `linux-platform`:

| Platform | Package | Output |
|----------|---------|--------|
| `debian` | `.deb` | `{crate}-{version}-x86_64.deb` |
| `arch` | `.pkg.tar.zst` | `{crate}-{version}-x86_64.pkg.tar.zst` |
| `musl` | Static binary | `{crate}-{version}-x86_64-musl` |
| `flatpak` | `.flatpak` package-only artifact | `{crate}-{version}-x86_64.flatpak` |
| `appimage` | `.AppImage` package-only artifact | `{crate}-{version}-x86_64.AppImage` |

### Windows
- **Target:** x86_64
- **Package:** MSI (if `create-package: true`, requires WiX)
- **Output:** `{crate}-{version}-x86_64.exe`, `{crate}-{version}-x86_64.msi`

## Examples

### Basic Linux build
```yaml
- uses: 42ByteLabs/actions/cargo/binaries@main
  with:
    platform: linux
```

### Debian package
```yaml
- uses: 42ByteLabs/actions/cargo/binaries@main
  with:
    platform: linux
    linux-platform: debian
    create-package: true
```

### Multi-platform matrix
```yaml
strategy:
  matrix:
    include:
      - platform: macos
        os: macos-latest
      - platform: linux
        linux-platform: debian
        os: ubuntu-latest
      - platform: windows
        os: windows-latest

runs-on: ${{ matrix.os }}

steps:
  - uses: actions/checkout@v4
  - uses: 42ByteLabs/actions/cargo/binaries@main
    with:
      platform: ${{ matrix.platform }}
      linux-platform: ${{ matrix.linux-platform }}
      create-package: true
```

### Linux packages on compatible runners
```yaml
strategy:
  matrix:
    linux-platform: [debian, arch, musl, flatpak, appimage]

runs-on: ubuntu-latest

steps:
  - uses: actions/checkout@v4
  - uses: 42ByteLabs/actions/cargo/binaries@main
    with:
      platform: linux
      linux-platform: ${{ matrix.linux-platform }}
      create-package: true
```

## What It Does

1. **Load project metadata** using cargo/project
2. **Setup Rust toolchain**
3. **Build binary** using platform-specific script:
   - macOS: `macos.sh`
   - Linux: `linux.sh` (dispatches to debian.sh, arch.sh, etc.)
   - Windows: `windows.ps1`
4. **Create package** (if `create-package: true`; Flatpak/AppImage always produce package artifacts)
5. **Upload to GitHub Release** (if `upload-release: true` and version tag exists)
6. **Create attestations** (if `create-attestation: true`)

## Platform Scripts

- `macos.sh` - Builds universal binary, creates DMG
- `linux.sh` - Detects distro and dispatches to specific script
- `debian.sh` - Builds .deb with cargo-deb
- `arch.sh` - Builds .pkg.tar.zst with makepkg
- `linux-musl.sh` - Static binary with musl
- `flatpak.sh` - Flatpak bundle
- `appimage.sh` - AppImage bundle
- `windows.ps1` - Windows .exe and .msi

## Auto-Detection

### Crate & Version
Uses cargo/project action to extract from Cargo.toml.

### Linux Platform
Reads `/etc/os-release`:
- Debian/Ubuntu → `debian.sh`
- Arch/Manjaro → `arch.sh`
- Alpine → `linux-musl.sh`
- Unknown → `debian.sh` (default)

## Requirements

- **macOS DMG:** `create-dmg` (auto-installed)
- **Debian:** `cargo-deb` (auto-installed)
- **Arch:** `makepkg` from `base-devel`; use an Arch runner/container for Arch packages
- **MUSL:** `musl-tools`, `x86_64-unknown-linux-musl` target (target is installed automatically)
- **Flatpak:** `flatpak-builder`; `app-id` defaults to `com.42bytelabs.{crate}`
- **AppImage:** `appimagetool` (auto-downloaded)
- **Windows MSI:** WiX Toolset

## Notes

- Binary naming: `{crate}-{version}-{arch}.{ext}`
- Uploads target the release named by `version` (for example, `1.0.0`)
- Some platform-specific tools are auto-installed when the runner supports them
- Debian, MUSL, Flatpak, and AppImage builds can run on Ubuntu; Arch packages require an Arch-compatible environment
