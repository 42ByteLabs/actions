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
    name=$(cat "$CARGO_LOCATION" | tomlq -r '.package.name // .workspace.package.name // empty')
    version=$(cat "$CARGO_LOCATION" | tomlq -r '.package.version // .workspace.package.version // empty')
    rust_version=$(cat "$CARGO_LOCATION" | tomlq -r '.package."rust-version" // .workspace.package."rust-version" // empty')
else
    echo "workspace=false" >>$GITHUB_OUTPUT
    echo "workspace-members=" >>$GITHUB_OUTPUT

    # Get package name, version, and rust-version
    name=$(cat "$CARGO_LOCATION" | tomlq -r '.package.name // empty')
    version=$(cat "$CARGO_LOCATION" | tomlq -r '.package.version // empty')
    rust_version=$(cat "$CARGO_LOCATION" | tomlq -r '.package."rust-version" // empty')
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
