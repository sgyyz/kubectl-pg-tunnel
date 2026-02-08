#!/usr/bin/env bash

set -euo pipefail

# kubectl-tcp-tunnel Uninstallation Script

PLUGIN_NAME="kubectl-tcp_tunnel"
CONFIG_DIR="${HOME}/.config/kubectl-tcp-tunnel"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}ERROR:${NC} $*" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $*"
}

print_info() {
    echo -e "${BLUE}→${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

print_header() {
    echo ""
    echo "======================================"
    echo "  kubectl-tcp-tunnel Uninstaller"
    echo "======================================"
    echo ""
}

# Find installed plugin
find_plugin() {
    local search_dirs=(
        "${HOME}/.krew/bin"
        "${HOME}/.local/bin"
        "/usr/local/bin"
    )

    for dir in "${search_dirs[@]}"; do
        if [[ -f "${dir}/${PLUGIN_NAME}" ]]; then
            echo "${dir}/${PLUGIN_NAME}"
            return 0
        fi
    done

    return 1
}

# Remove plugin
remove_plugin() {
    local plugin_path

    # shellcheck disable=SC2310
    if plugin_path=$(find_plugin); then
        print_info "Found plugin at: ${plugin_path}"

        if rm -f "${plugin_path}"; then
            print_success "Removed plugin: ${plugin_path}"
            return 0
        else
            print_error "Failed to remove plugin: ${plugin_path}"
            print_info "You may need to run with sudo: sudo $0"
            return 1
        fi
    else
        print_warning "Plugin not found in standard locations"
        print_info "If installed elsewhere, please remove manually"
        return 1
    fi
}

# Remove configuration
remove_config() {
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        print_info "No configuration directory found"
        return 0
    fi

    echo ""
    print_warning "Configuration directory found: ${CONFIG_DIR}"
    print_info "This contains your database configurations and settings"
    echo ""
    read -p "Remove configuration directory? (y/n) " -n 1 -r
    echo ""

    if [[ ${REPLY} =~ ^[Yy]$ ]]; then
        if rm -rf "${CONFIG_DIR}"; then
            print_success "Removed configuration directory"
        else
            print_error "Failed to remove configuration directory"
            return 1
        fi
    else
        print_info "Keeping configuration directory"
        print_info "To remove manually later: rm -rf ${CONFIG_DIR}"
    fi

    return 0
}

# Clean up any running jump pods
cleanup_jump_pods() {
    echo ""
    read -p "Search for and clean up any running jump pods? (y/n) " -n 1 -r
    echo ""

    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        return 0
    fi

    if ! command -v kubectl >/dev/null 2>&1; then
        print_warning "kubectl not found, skipping jump pod cleanup"
        return 0
    fi

    print_info "Searching for jump pods (pg-jump-*)..."

    local contexts
    contexts=$(kubectl config get-contexts -o name 2>/dev/null || true)

    if [[ -z "${contexts}" ]]; then
        print_info "No kubectl contexts found"
        return 0
    fi

    local found_pods=false

    while IFS= read -r context; do
        local pods
        pods=$(kubectl --context="${context}" get pods --all-namespaces -o json 2>/dev/null | \
               jq -r '.items[] | select(.metadata.name | startswith("pg-jump-")) | "\(.metadata.namespace)/\(.metadata.name)"' 2>/dev/null || true)

        if [[ -n "${pods}" ]]; then
            found_pods=true
            echo ""
            print_warning "Found jump pods in context: ${context}"
            echo "${pods}"
            echo ""
            read -p "Delete these pods? (y/n) " -n 1 -r
            echo ""

            if [[ ${REPLY} =~ ^[Yy]$ ]]; then
                while IFS= read -r pod_info; do
                    local namespace="${pod_info%/*}"
                    local pod_name="${pod_info#*/}"

                    if kubectl --context="${context}" -n "${namespace}" delete pod "${pod_name}" --grace-period=0 2>/dev/null; then
                        print_success "Deleted: ${namespace}/${pod_name}"
                    else
                        print_warning "Failed to delete: ${namespace}/${pod_name}"
                    fi
                done <<< "${pods}"
            fi
        fi
    done <<< "${contexts}"

    if [[ "${found_pods}" == "false" ]]; then
        print_info "No jump pods found"
    fi
}

# Verify uninstallation
verify_uninstall() {
    print_info "Verifying uninstallation..."

    if command -v kubectl >/dev/null 2>&1; then
        if kubectl tcp-tunnel --version >/dev/null 2>&1; then
            print_warning "Plugin still accessible via kubectl"
            print_info "You may need to restart your shell"
            return 1
        fi
    fi

    local plugin_path
    # shellcheck disable=SC2310
    if plugin_path=$(find_plugin); then
        print_warning "Plugin file still exists: ${plugin_path}"
        return 1
    fi

    print_success "Uninstallation verified"
    return 0
}

# Print completion message
print_completion() {
    echo ""
    echo "======================================"
    echo "  Uninstallation Complete!"
    echo "======================================"
    echo ""
    echo "kubectl-tcp-tunnel has been removed from your system."
    echo ""

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo "Configuration preserved at: ${CONFIG_DIR}"
        echo "Remove manually if no longer needed: rm -rf ${CONFIG_DIR}"
        echo ""
    fi

    echo "Thank you for using kubectl-tcp-tunnel!"
    echo ""
}

# Main uninstallation flow
main() {
    print_header

    print_warning "This will uninstall kubectl-tcp-tunnel from your system"
    echo ""
    read -p "Continue with uninstallation? (y/n) " -n 1 -r
    echo ""

    if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi

    echo ""

    # Remove plugin (non-fatal if fails)
    # shellcheck disable=SC2310
    remove_plugin || true

    # Remove configuration (with prompt, non-fatal)
    # shellcheck disable=SC2310
    remove_config || true

    # Clean up jump pods (with prompt, non-fatal)
    # shellcheck disable=SC2310
    cleanup_jump_pods || true

    # Verify uninstallation (non-fatal)
    echo ""
    # shellcheck disable=SC2310
    verify_uninstall || true

    # Print completion message
    print_completion
}

# Run main
main "$@"
