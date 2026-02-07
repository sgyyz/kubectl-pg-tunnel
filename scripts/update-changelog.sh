#!/usr/bin/env bash

# Use bash 4.0+ if available for better performance, otherwise fall back to bash 3.2
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

# Parse commits and group by category (bash 3.2 compatible)
cat_added=""
cat_changed=""
cat_fixed=""
cat_removed=""
cat_deprecated=""
cat_security=""
cat_documentation=""
cat_performance=""

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

    # Add to appropriate category variable
    # shellcheck disable=SC2249
    case "${category}" in
        "Added")
            if [[ -n "${cat_added}" ]]; then
                cat_added="${cat_added}"$'\n'"- ${clean_message}"
            else
                cat_added="- ${clean_message}"
            fi
            ;;
        "Changed")
            if [[ -n "${cat_changed}" ]]; then
                cat_changed="${cat_changed}"$'\n'"- ${clean_message}"
            else
                cat_changed="- ${clean_message}"
            fi
            ;;
        "Fixed")
            if [[ -n "${cat_fixed}" ]]; then
                cat_fixed="${cat_fixed}"$'\n'"- ${clean_message}"
            else
                cat_fixed="- ${clean_message}"
            fi
            ;;
        "Removed")
            if [[ -n "${cat_removed}" ]]; then
                cat_removed="${cat_removed}"$'\n'"- ${clean_message}"
            else
                cat_removed="- ${clean_message}"
            fi
            ;;
        "Deprecated")
            if [[ -n "${cat_deprecated}" ]]; then
                cat_deprecated="${cat_deprecated}"$'\n'"- ${clean_message}"
            else
                cat_deprecated="- ${clean_message}"
            fi
            ;;
        "Security")
            if [[ -n "${cat_security}" ]]; then
                cat_security="${cat_security}"$'\n'"- ${clean_message}"
            else
                cat_security="- ${clean_message}"
            fi
            ;;
        "Documentation")
            if [[ -n "${cat_documentation}" ]]; then
                cat_documentation="${cat_documentation}"$'\n'"- ${clean_message}"
            else
                cat_documentation="- ${clean_message}"
            fi
            ;;
        "Performance")
            if [[ -n "${cat_performance}" ]]; then
                cat_performance="${cat_performance}"$'\n'"- ${clean_message}"
            else
                cat_performance="- ${clean_message}"
            fi
            ;;
    esac
done < <(git rev-list "${COMMIT_RANGE}")

echo "Commits processed"
echo ""

# Check if there are any changes
has_changes=false
if [[ -n "${cat_added}" ]] || [[ -n "${cat_changed}" ]] || [[ -n "${cat_fixed}" ]] || \
   [[ -n "${cat_removed}" ]] || [[ -n "${cat_deprecated}" ]] || [[ -n "${cat_security}" ]] || \
   [[ -n "${cat_documentation}" ]] || [[ -n "${cat_performance}" ]]; then
    has_changes=true
fi

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
# Using individual redirects for clarity (disable SC2129 style warning)
# shellcheck disable=SC2129
if [[ -n "${cat_added}" ]]; then
    echo "### Added" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_added}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_changed}" ]]; then
    echo "### Changed" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_changed}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_fixed}" ]]; then
    echo "### Fixed" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_fixed}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_removed}" ]]; then
    echo "### Removed" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_removed}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_deprecated}" ]]; then
    echo "### Deprecated" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_deprecated}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_security}" ]]; then
    echo "### Security" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_security}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_performance}" ]]; then
    echo "### Performance" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_performance}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

# shellcheck disable=SC2129
if [[ -n "${cat_documentation}" ]]; then
    echo "### Documentation" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
    echo "${cat_documentation}" >> "${TEMP_FILE}"
    echo "" >> "${TEMP_FILE}"
fi

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
    # Insert after [Unreleased] section using sed
    # Find the line number of [Unreleased]
    line_num=$(grep -n "^## \[Unreleased\]" CHANGELOG.md | head -1 | cut -d: -f1)

    # Find the next ## heading after [Unreleased]
    next_heading=$(tail -n +"$((line_num + 1))" CHANGELOG.md | grep -n "^## " | head -1 | cut -d: -f1)

    if [[ -n "${next_heading}" ]]; then
        # Insert before next heading
        insert_line=$((line_num + next_heading))
    else
        # No next heading, append at end
        insert_line=$(wc -l < CHANGELOG.md)
        insert_line=$((insert_line + 1))
    fi

    # Insert the new content
    {
        head -n "$((insert_line - 1))" CHANGELOG.md
        cat "${TEMP_FILE}"
        echo ""
        tail -n +"${insert_line}" CHANGELOG.md
    } > CHANGELOG.md.tmp
    mv CHANGELOG.md.tmp CHANGELOG.md
else
    # No [Unreleased] section, insert at top after title
    # Find # Changelog line
    line_num=$(grep -n "^# Changelog" CHANGELOG.md | head -1 | cut -d: -f1)

    if [[ -n "${line_num}" ]]; then
        # Insert after title and blank line
        {
            head -n "$((line_num + 1))" CHANGELOG.md
            echo ""
            cat "${TEMP_FILE}"
            tail -n +"$((line_num + 2))" CHANGELOG.md
        } > CHANGELOG.md.tmp
        mv CHANGELOG.md.tmp CHANGELOG.md
    else
        # No title found, insert at top
        {
            cat "${TEMP_FILE}"
            echo ""
            cat CHANGELOG.md
        } > CHANGELOG.md.tmp
        mv CHANGELOG.md.tmp CHANGELOG.md
    fi
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
