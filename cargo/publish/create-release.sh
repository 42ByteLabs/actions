#!/bin/bash
# Create GitHub release and push tags
set -e

if [ -z "$VERSION" ]; then
  echo "Error: VERSION environment variable not set"
  exit 1
fi

if [ -z "$GH_TOKEN" ]; then
  echo "Error: GH_TOKEN environment variable not set"
  exit 1
fi

if [ -z "$REF_NAME" ]; then
  REF_NAME="main"
fi

echo "🏷️  Creating release for version: $VERSION"

git config user.name github-actions
git config user.email github-actions@github.com

git tag "${VERSION}" --force
git push origin "${REF_NAME}"
git push origin --tags --force

gh release create --latest --generate-notes --title "v${VERSION}" "${VERSION}"

echo "✅ GitHub release created successfully"
