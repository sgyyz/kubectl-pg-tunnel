#!/usr/bin/env bash

set -euo pipefail

# prepare-release.sh - Prepare a release by updating version placeholders
#
# Usage: ./scripts/prepare-release.sh <version>
# Example: ./scripts/prepare-release.sh 1.0.0

VERSION="${1:-}"

if [[ -z "${VERSION}" ]]; then
    echo "Error: Version required"
    echo ""
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

echo "Preparing release v${VERSION}..."
echo ""

# Step 1: Update CHANGELOG from commits
echo "Step 1: Updating CHANGELOG.md..."
if [[ -f "./scripts/update-changelog.sh" ]]; then
    ./scripts/update-changelog.sh "${VERSION}"
    echo ""
else
    echo "Warning: scripts/update-changelog.sh not found, skipping CHANGELOG update"
    echo ""
fi

# Step 2: Update version in kubectl-pg_tunnel
echo "Step 2: Updating kubectl-pg_tunnel..."
# Extract current version from kubectl-pg_tunnel
# shellcheck disable=SC2016
CURRENT_VERSION=$(grep 'VERSION="\${KUBECTL_PG_TUNNEL_VERSION:-' kubectl-pg_tunnel | head -1 | sed 's/.*:-\([^}]*\)}.*/\1/')
if [[ -z "${CURRENT_VERSION}" ]]; then
    echo "Error: Could not detect current version in kubectl-pg_tunnel"
    exit 1
fi
echo "  Current version: ${CURRENT_VERSION}"
echo "  New version: v${VERSION}"
# Replace current version with new version
sed -i.bak "s/VERSION=\"\\\${KUBECTL_PG_TUNNEL_VERSION:-${CURRENT_VERSION}}\"/VERSION=\"\\\${KUBECTL_PG_TUNNEL_VERSION:-v${VERSION}}\"/g" kubectl-pg_tunnel
rm kubectl-pg_tunnel.bak

# Step 3: Update version in install.sh
echo "Step 3: Updating install.sh..."
sed -i.bak "s/VERSION=\".*\"/VERSION=\"${VERSION}\"/g" install.sh
rm install.sh.bak

echo ""
echo "✓ Release v${VERSION} prepared!"
echo ""
echo "Files updated:"
echo "  - CHANGELOG.md (from commit messages)"
echo "  - kubectl-pg_tunnel (version updated to v${VERSION})"
echo "  - install.sh (version updated to ${VERSION})"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit: git commit -am 'Release v${VERSION}'"
echo "  3. Tag: git tag -a v${VERSION} -m 'Release v${VERSION}'"
echo "  4. Push: git push origin main --tags"
echo "  5. GitHub Actions will create the release automatically"
echo ""
echo "Note: Keep CHANGELOG.md.bak if you need to restore"
echo ""
