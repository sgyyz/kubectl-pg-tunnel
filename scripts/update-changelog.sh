#!/usr/bin/env bash

set -euo pipefail

# update-changelog.sh - Update CHANGELOG.md from git commits
#
# Usage: ./scripts/update-changelog.sh <version> [previous-tag]
# Example: ./scripts/update-changelog.sh 1.0.0
# Example: ./scripts/update-changelog.sh 1.1.0 v1.0.0

VERSION="${1:-}"
PREV_TAG="${2:-}"

if [[ -z "${VERSION}" ]]; then
    echo "Error: Version required"
    echo ""
    echo "Usage: $0 <version> [previous-tag]"
    echo "Example: $0 1.0.0"
    echo "Example: $0 1.1.0 v1.0.0"
    exit 1
fi

# Remove 'v' prefix if present
VERSION="${VERSION#v}"

# Get current date in YYYY-MM-DD format
RELEASE_DATE=$(date +%Y-%m-%d)

echo "Updating CHANGELOG for v${VERSION} (${RELEASE_DATE})..."
echo ""

# If no previous tag specified, try to find it
if [[ -z "${PREV_TAG}" ]]; then
    PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

# Get commit range
if [[ -n "${PREV_TAG}" ]]; then
    COMMIT_RANGE="${PREV_TAG}..HEAD"
    echo "Analyzing commits from ${PREV_TAG} to HEAD"
else
    COMMIT_RANGE="HEAD"
    echo "Analyzing all commits (no previous tag found)"
fi
echo ""

# Create temporary file for new changelog entries
TEMP_FILE=$(mktemp)

# Function to categorize commit
categorize_commit() {
    local message="$1"
    local category=""

    # Check conventional commit format (with or without scope)
    if [[ "${message}" =~ ^feat ]]; then
        category="Added"
    elif [[ "${message}" =~ ^fix ]]; then
        category="Fixed"
    elif [[ "${message}" =~ ^docs ]]; then
        category="Documentation"
    elif [[ "${message}" =~ ^refactor ]]; then
        category="Changed"
    elif [[ "${message}" =~ ^perf ]]; then
        category="Performance"
    elif [[ "${message}" =~ ^test ]]; then
        category="Testing"
    elif [[ "${message}" =~ ^chore ]]; then
        category="Maintenance"
    elif [[ "${message}" =~ ^style ]]; then
        category="Style"
    elif [[ "${message}" =~ ^build ]]; then
        category="Build"
    elif [[ "${message}" =~ ^ci ]]; then
        category="CI/CD"
    # Check for common keywords
    elif [[ "${message}" =~ ^[Aa]dd ]]; then
        category="Added"
    elif [[ "${message}" =~ ^[Ff]ix ]]; then
        category="Fixed"
    elif [[ "${message}" =~ ^[Uu]pdate ]]; then
        category="Changed"
    elif [[ "${message}" =~ ^[Rr]emove ]]; then
        category="Removed"
    elif [[ "${message}" =~ ^[Dd]eprecate ]]; then
        category="Deprecated"
    else
        category="Changed"
    fi

    echo "${category}"
}

# Parse commits and group by category
declare -A categories
categories=(
    ["Added"]=""
    ["Changed"]=""
    ["Fixed"]=""
    ["Removed"]=""
    ["Deprecated"]=""
    ["Security"]=""
    ["Documentation"]=""
    ["Performance"]=""
)

echo "Processing commits..."
# shellcheck disable=SC2312
while IFS= read -r commit; do
    # Get commit message (first line only)
    message=$(git log --format=%s -n 1 "${commit}")

    # Skip merge commits and release commits
    if [[ "${message}" =~ ^Merge\ |^Release\ v|^Prepare\ CHANGELOG ]]; then
        continue
    fi

    # Categorize
    category=$(categorize_commit "${message}")

    # Extract clean message (remove conventional commit prefix)
    clean_message="${message}"
    if [[ "${message}" =~ : ]]; then
        # Has colon, likely conventional commit format
        clean_message="${message#*: }"
    fi

    # Add to category
    if [[ -n "${categories[${category}]+x}" ]]; then
        if [[ -n "${categories[${category}]}" ]]; then
            categories[${category}]="${categories[${category}]}"$'\n'"- ${clean_message}"
        else
            categories[${category}]="- ${clean_message}"
        fi
    fi
done < <(git rev-list "${COMMIT_RANGE}")

echo "Commits processed"
echo ""

# Check if there are any changes
has_changes=false
for category in "${!categories[@]}"; do
    if [[ -n "${categories[${category}]}" ]]; then
        has_changes=true
        break
    fi
done

if [[ "${has_changes}" = false ]]; then
    echo "No commits found to add to CHANGELOG"
    rm "${TEMP_FILE}"
    exit 0
fi

# Build new changelog entry
cat > "${TEMP_FILE}" <<EOF
## [${VERSION}] - ${RELEASE_DATE}

EOF

# Add categories with content
# shellcheck disable=SC2129
for category in "Added" "Changed" "Fixed" "Removed" "Deprecated" "Security" "Performance" "Documentation"; do
    if [[ -n "${categories[${category}]}" ]]; then
        echo "### ${category}" >> "${TEMP_FILE}"
        echo "" >> "${TEMP_FILE}"
        echo "${categories[${category}]}" >> "${TEMP_FILE}"
        echo "" >> "${TEMP_FILE}"
    fi
done

# Check if CHANGELOG.md exists
if [[ ! -f CHANGELOG.md ]]; then
    echo "Error: CHANGELOG.md not found"
    rm "${TEMP_FILE}"
    exit 1
fi

# Create backup
cp CHANGELOG.md CHANGELOG.md.bak

# Find the [Unreleased] section and insert new version after it
if grep -q "## \[Unreleased\]" CHANGELOG.md; then
    # Insert after [Unreleased] section
    # shellcheck disable=SC2312
    awk -v new_content="$(cat "${TEMP_FILE}")" '
    /^## \[Unreleased\]/ {
        print
        # Print lines until next ## heading or end
        while (getline > 0 && !/^## /) {
            print
        }
        # Print new content
        print new_content
        # Print the ## line we just read
        if (NF > 0) print
        next
    }
    { print }
    ' CHANGELOG.md > CHANGELOG.md.tmp
    mv CHANGELOG.md.tmp CHANGELOG.md
else
    # No [Unreleased] section, insert at top after title
    # shellcheck disable=SC2312
    awk -v new_content="$(cat "${TEMP_FILE}")" '
    /^# Changelog/ {
        print
        getline
        print
        print new_content
        next
    }
    { print }
    ' CHANGELOG.md > CHANGELOG.md.tmp
    mv CHANGELOG.md.tmp CHANGELOG.md
fi

# Update the version comparison links at the bottom
if grep -q "\[Unreleased\]:" CHANGELOG.md; then
    # Update [Unreleased] link
    sed -i.tmp "s|\[Unreleased\]:.*|\[Unreleased\]: https://github.com/sgyyz/kubectl-pg-tunnel/compare/v${VERSION}...HEAD|g" CHANGELOG.md
    rm -f CHANGELOG.md.tmp

    # Add new version link if not exists
    if ! grep -q "\[${VERSION}\]:" CHANGELOG.md; then
        echo "[${VERSION}]: https://github.com/sgyyz/kubectl-pg-tunnel/releases/tag/v${VERSION}" >> CHANGELOG.md
    fi
else
    # Add comparison links section
    cat >> CHANGELOG.md <<EOF

[Unreleased]: https://github.com/sgyyz/kubectl-pg-tunnel/compare/v${VERSION}...HEAD
[${VERSION}]: https://github.com/sgyyz/kubectl-pg-tunnel/releases/tag/v${VERSION}
EOF
fi

# Clean up
rm "${TEMP_FILE}"

echo "✓ CHANGELOG.md updated successfully!"
echo ""
echo "Added entries under [${VERSION}] - ${RELEASE_DATE}"
echo ""
echo "Review the changes:"
echo "  git diff CHANGELOG.md"
echo ""
echo "Restore backup if needed:"
echo "  mv CHANGELOG.md.bak CHANGELOG.md"
echo ""
