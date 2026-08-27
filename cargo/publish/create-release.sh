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

echo "🏷️  Creating release for version: $VERSION"

git config user.name github-actions
git config user.email github-actions@github.com

if git rev-parse "refs/tags/${VERSION}" >/dev/null 2>&1; then
  echo "Error: local tag '${VERSION}' already exists"
  exit 1
fi

if git ls-remote --exit-code --tags origin "${VERSION}" >/dev/null 2>&1; then
  echo "Error: remote tag '${VERSION}' already exists"
  exit 1
fi

git tag "${VERSION}"
git push origin "${VERSION}"

gh release create --latest --generate-notes --title "v${VERSION}" "${VERSION}"

echo "✅ GitHub release created successfully"
