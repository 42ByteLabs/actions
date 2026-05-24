#!/bin/bash
# Extract Cargo project information using yq/tomlq
set -e

# Check if tomlq is already installed
if ! command -v tomlq &>/dev/null; then
    echo "📦 Installing yq / tomlq"
    pip3 install --break-system-packages yq
else
    echo "✅ yq / tomlq already installed"
fi

if [ ! -f "$CARGO_LOCATION" ]; then
    CARGO_LOCATION="./Cargo.toml"
fi

echo "📋 Extracting project information from $CARGO_LOCATION"

# Check if this is a workspace
is_workspace=$(cat "$CARGO_LOCATION" | tomlq -r '.workspace // "null"')
if [ "$is_workspace" != "null" ]; then
    echo "workspace=true" >>$GITHUB_OUTPUT

    # Get workspace members and extract package names
    workspace_paths=$(cat "$CARGO_LOCATION" | tomlq -r '.workspace.members[]?' 2>/dev/null || echo "")

    if [ -n "$workspace_paths" ]; then
        member_names=""

        # Get the directory containing the Cargo.toml
        cargo_dir=$(dirname "$CARGO_LOCATION")

        for member_path in $workspace_paths; do
            # Handle current directory "."
            if [ "$member_path" = "." ]; then
                # Use the root Cargo.toml (same as $CARGO_LOCATION)
                member_name=$(cat "$CARGO_LOCATION" | tomlq -r '.package.name // empty')
                if [ -n "$member_name" ]; then
                    if [ -z "$member_names" ]; then
                        member_names="$member_name"
                    else
                        member_names="$member_names,$member_name"
                    fi
                fi
            # Check if it's a glob pattern
            elif [[ "$member_path" == *"/*" ]]; then
                # Remove trailing /*
                clean_path=$(echo "$member_path" | sed 's/\/\*$//')

                # Find all Cargo.toml files in matching directories
                for cargo_file in "$cargo_dir/$clean_path"/*/Cargo.toml; do
                    if [ -f "$cargo_file" ]; then
                        member_name=$(cat "$cargo_file" | tomlq -r '.package.name // empty')
                        if [ -n "$member_name" ]; then
                            if [ -z "$member_names" ]; then
                                member_names="$member_name"
                            else
                                member_names="$member_names,$member_name"
                            fi
                        fi
                    fi
                done
            else
                # Direct path to a member
                member_cargo="$cargo_dir/$member_path/Cargo.toml"
                if [ -f "$member_cargo" ]; then
                    member_name=$(cat "$member_cargo" | tomlq -r '.package.name // empty')
                    if [ -n "$member_name" ]; then
                        if [ -z "$member_names" ]; then
                            member_names="$member_name"
                        else
                            member_names="$member_names,$member_name"
                        fi
                    fi
                fi
            fi
        done

        echo "workspace-members=$member_names" >>$GITHUB_OUTPUT
        echo "✅ Workspace members: $member_names"
    else
        echo "workspace-members=" >>$GITHUB_OUTPUT
    fi

    # For workspaces, try to get the workspace package name if it exists
    # Handle workspace inheritance (e.g., version.workspace = true)
    name=$(cat "$CARGO_LOCATION" | tomlq -r '.package.name // .workspace.package.name // empty')
    
    # Check if version is using workspace inheritance
    version_check=$(cat "$CARGO_LOCATION" | tomlq -r 'if (.package.version | type) == "object" then .package.version.workspace // empty else empty end')
    if [ "$version_check" = "true" ]; then
        version=$(cat "$CARGO_LOCATION" | tomlq -r '.workspace.package.version // empty')
    else
        version=$(cat "$CARGO_LOCATION" | tomlq -r '.package.version // .workspace.package.version // empty')
    fi
    
    # Check if rust-version is using workspace inheritance
    rust_version_check=$(cat "$CARGO_LOCATION" | tomlq -r 'if (.package."rust-version" | type) == "object" then .package."rust-version".workspace // empty else empty end')
    if [ "$rust_version_check" = "true" ]; then
        rust_version=$(cat "$CARGO_LOCATION" | tomlq -r '.workspace.package."rust-version" // empty')
    else
        rust_version=$(cat "$CARGO_LOCATION" | tomlq -r '.package."rust-version" // .workspace.package."rust-version" // empty')
    fi
else
    echo "workspace=false" >>$GITHUB_OUTPUT
    echo "workspace-members=" >>$GITHUB_OUTPUT

    # Get package name, version, and rust-version
    name=$(cat "$CARGO_LOCATION" | tomlq -r '.package.name // empty')
    
    # For non-workspace projects, still check if somehow referencing workspace
    version_check=$(cat "$CARGO_LOCATION" | tomlq -r 'if (.package.version | type) == "object" then .package.version.workspace // empty else empty end')
    if [ "$version_check" = "true" ]; then
        version=$(cat "$CARGO_LOCATION" | tomlq -r '.workspace.package.version // empty')
    else
        version=$(cat "$CARGO_LOCATION" | tomlq -r '.package.version // empty')
    fi
    
    rust_version_check=$(cat "$CARGO_LOCATION" | tomlq -r 'if (.package."rust-version" | type) == "object" then .package."rust-version".workspace // empty else empty end')
    if [ "$rust_version_check" = "true" ]; then
        rust_version=$(cat "$CARGO_LOCATION" | tomlq -r '.workspace.package."rust-version" // empty')
    else
        rust_version=$(cat "$CARGO_LOCATION" | tomlq -r '.package."rust-version" // empty')
    fi
fi

# Output name and version
if [ -n "$name" ]; then
    echo "name=$name" >>$GITHUB_OUTPUT
    echo "✅ Project name: $name"
else
    echo "name=" >>$GITHUB_OUTPUT
fi

if [ -n "$version" ]; then
    echo "version=$version" >>$GITHUB_OUTPUT
    echo "✅ Project version: $version"
else
    echo "version=" >>$GITHUB_OUTPUT
fi

if [ -n "$rust_version" ]; then
    echo "rust-version=$rust_version" >>$GITHUB_OUTPUT
    echo "✅ Rust version (MSRV): $rust_version"
else
    echo "rust-version=" >>$GITHUB_OUTPUT
fi

# Get examples
examples=$(cat "$CARGO_LOCATION" | tomlq -r '.example[]?.name' 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "")
if [ -n "$examples" ]; then
    echo "examples=$examples" >>$GITHUB_OUTPUT
    echo "✅ Examples: $examples"
else
    echo "examples=" >>$GITHUB_OUTPUT
fi

# Get binaries
bins=$(cat "$CARGO_LOCATION" | tomlq -r '.bin[]?.name' 2>/dev/null | tr '\n' ',' | sed 's/,$//' || echo "")
if [ -n "$bins" ]; then
    echo "bins=$bins" >>$GITHUB_OUTPUT
    echo "✅ Binaries: $bins"
else
    echo "bins=" >>$GITHUB_OUTPUT
fi

echo "📦 Project information extraction complete"

# Check crates.io version if we have a package name
if [ -n "$name" ]; then
    echo ""
    echo "🔍 Checking crates.io version using cargo search..."
    crates_latest=$(cargo search "$name" --limit 1 2>/dev/null | grep "^$name = " | sed -E 's/.*= "([^"]+)".*/\1/' || echo "")
    
    # Fallback to API if cargo search fails or returns empty
    if [ -z "$crates_latest" ] || [ "$crates_latest" == "null" ]; then
        echo "⚠️  Cargo search failed or returned no results, falling back to API..."
        crates_latest=$(curl -s "https://crates.io/api/v1/crates/$name/versions" 2>/dev/null | jq -r '.versions[0].num' 2>/dev/null || echo "")
        
        if [ -z "$crates_latest" ] || [ "$crates_latest" == "null" ]; then
            echo "[!] Unable to get remote crates version (new crate?)"
            echo "crate-latest=" >>$GITHUB_OUTPUT
            echo "crate-outdated=unknown" >>$GITHUB_OUTPUT
        else
            echo "crate-latest=$crates_latest" >>$GITHUB_OUTPUT
            echo "🦀 Crates.io latest: $crates_latest"
            
            # Compare versions if we have both
            if [ -n "$version" ]; then
                if [ "$version" != "$crates_latest" ]; then
                    echo "crate-outdated=true" >>$GITHUB_OUTPUT
                    echo "🚀 Crate is outdated: $version -> $crates_latest"
                else
                    echo "crate-outdated=false" >>$GITHUB_OUTPUT
                    echo "✅ Crate is up to date: $version"
                fi
            else
                echo "crate-outdated=unknown" >>$GITHUB_OUTPUT
            fi
        fi
    else
        echo "crate-latest=$crates_latest" >>$GITHUB_OUTPUT
        echo "🦀 Crates.io latest: $crates_latest"
        
        # Compare versions if we have both
        if [ -n "$version" ]; then
            if [ "$version" != "$crates_latest" ]; then
                echo "crate-outdated=true" >>$GITHUB_OUTPUT
                echo "🚀 Crate is outdated: $version -> $crates_latest"
            else
                echo "crate-outdated=false" >>$GITHUB_OUTPUT
                echo "✅ Crate is up to date: $version"
            fi
        else
            echo "crate-outdated=unknown" >>$GITHUB_OUTPUT
        fi
    fi
else
    echo "crate-latest=" >>$GITHUB_OUTPUT
    echo "crate-outdated=unknown" >>$GITHUB_OUTPUT
fi
