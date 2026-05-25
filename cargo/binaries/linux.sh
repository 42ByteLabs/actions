#!/bin/bash
# Linux platform dispatcher - automatically selects the appropriate build script
# based on LINUX_PLATFORM environment variable or auto-detects the current distro
set -e

if [ -z "$CRATE" ]; then
  echo "Error: CRATE environment variable not set"
  exit 1
fi

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to detect Linux distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  else
    echo "unknown"
  fi
}

# Function to validate platform choice
validate_platform() {
  local platform="$1"
  case "$platform" in
    debian|arch|musl|flatpak|appimage)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Determine which platform to use
if [ -n "$LINUX_PLATFORM" ]; then
  # User specified platform explicitly
  PLATFORM="$LINUX_PLATFORM"
  echo "🐧 Using explicitly specified Linux platform: $PLATFORM"
else
  # Auto-detect based on current system
  DETECTED_DISTRO=$(detect_distro)
  echo "🔍 Detected Linux distribution: $DETECTED_DISTRO"
  
  # Map detected distro to platform script
  case "$DETECTED_DISTRO" in
    debian|ubuntu|linuxmint|pop|elementary)
      PLATFORM="debian"
      ;;
    arch|manjaro|endeavouros|artix)
      PLATFORM="arch"
      ;;
    alpine)
      PLATFORM="musl"
      ;;
    *)
      # Default to debian if unknown (most common)
      echo "⚠️  Unknown distribution, defaulting to debian"
      PLATFORM="debian"
      ;;
  esac
  
  echo "🎯 Auto-selected platform: $PLATFORM"
fi

# Validate the platform choice
if ! validate_platform "$PLATFORM"; then
  echo "Error: Invalid platform '$PLATFORM'"
  echo "Valid platforms: debian, arch, musl, flatpak, appimage"
  exit 1
fi

# Map platform to script name
case "$PLATFORM" in
  debian)
    SCRIPT="debian.sh"
    ;;
  arch)
    SCRIPT="arch.sh"
    ;;
  musl)
    SCRIPT="linux-musl.sh"
    ;;
  flatpak)
    SCRIPT="flatpak.sh"
    ;;
  appimage)
    SCRIPT="appimage.sh"
    ;;
esac

# Check if script exists
if [ ! -f "$SCRIPT_DIR/$SCRIPT" ]; then
  echo "Error: Platform script not found: $SCRIPT"
  exit 1
fi

# Execute the platform-specific script
echo "🚀 Executing platform script: $SCRIPT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exec "$SCRIPT_DIR/$SCRIPT"
