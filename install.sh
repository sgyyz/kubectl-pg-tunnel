#!/usr/bin/env bash

set -euo pipefail

# kubectl-tcp-tunnel Installation Script

VERSION="2.1.1"
PLUGIN_NAME="kubectl-tcp_tunnel"
CONFIG_DIR="${HOME}/.config/kubectl-tcp-tunnel"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
GITHUB_REPO="sgyyz/kubectl-tcp-tunnel"
# Use version-specific tag for reliable installs (falls back to main if tag doesn't exist)
GITHUB_RAW="https://raw.githubusercontent.com/${GITHUB_REPO}/v${VERSION}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}❌ ERROR:${NC} $*" >&2
}

print_success() {
    echo -e "${GREEN}✅${NC} $*"
}

print_info() {
    echo -e "${BLUE}🔵${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $*"
}

print_header() {
    echo ""
    echo "======================================"
    echo "  kubectl-tcp-tunnel Installer v${VERSION}"
    echo "======================================"
    echo ""
}

# Detect OS and architecture
detect_os() {
    local os
    case "$(uname -s)" in
        Linux*)
            os="linux"
            ;;
        Darwin*)
            os="macos"
            ;;
        *)
            local detected_os
            detected_os=$(uname -s)
            print_error "Unsupported operating system: ${detected_os}"
            exit 1
            ;;
    esac
    echo "${os}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."

    local missing_deps=()

    # shellcheck disable=SC2310
    if ! command_exists kubectl; then
        missing_deps+=("kubectl")
    fi

    # shellcheck disable=SC2310
    if ! command_exists kubectx; then
        missing_deps+=("kubectx")
    fi

    # shellcheck disable=SC2310
    if ! command_exists yq; then
        missing_deps+=("yq")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - ${dep}"
        done
        echo ""
        echo "Please install missing dependencies and try again."
        echo ""
        echo "Installation instructions:"
        echo "  kubectl:  https://kubernetes.io/docs/tasks/tools/"
        echo "  kubectx:  https://github.com/ahmetb/kubectx#installation"
        echo "  yq:       https://github.com/mikefarah/yq#install"
        echo ""
        echo "Quick install (macOS):"
        echo "  brew install kubectl kubectx yq"
        exit 1
    fi

    print_success "All dependencies found"
}

# Determine installation directory
determine_install_dir() {
    local install_dir=""

    # Check for krew installation directory
    if [[ -d "${HOME}/.krew/bin" ]]; then
        install_dir="${HOME}/.krew/bin"
    # Check for local bin directory
    elif [[ -d "${HOME}/.local/bin" ]]; then
        install_dir="${HOME}/.local/bin"
    # Check for user local bin
    elif [[ -d "/usr/local/bin" ]] && [[ -w "/usr/local/bin" ]]; then
        install_dir="/usr/local/bin"
    else
        # Create local bin directory
        print_info "Creating ${HOME}/.local/bin..."
        mkdir -p "${HOME}/.local/bin"
        install_dir="${HOME}/.local/bin"
    fi

    echo "${install_dir}"
}

# Check if PATH includes the installation directory
check_path() {
    local install_dir="$1"

    if [[ ":${PATH}:" != *":${install_dir}:"* ]]; then
        print_warning "Installation directory is not in your PATH: ${install_dir}"
        echo ""
        echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "    export PATH=\"\${PATH}:${install_dir}\""
        echo ""
        return 1
    fi

    return 0
}

# Download plugin from GitHub
download_plugin() {
    local install_dir="$1"
    local plugin_path="${install_dir}/${PLUGIN_NAME}"
    local temp_file="/tmp/${PLUGIN_NAME}.$$"

    print_info "Downloading plugin from GitHub..."

    # Check if plugin already exists
    if [[ -f "${plugin_path}" ]]; then
        print_warning "Plugin already installed at: ${plugin_path}"

        # Check if force install or running in non-interactive mode
        if [[ -n "${FORCE_INSTALL:-}" ]] || [[ ! -t 0 ]]; then
            # Force install mode or non-interactive mode (e.g., upgrade command) - auto-overwrite
            print_info "Auto-overwriting existing installation..."
        else
            # Interactive mode - prompt user
            read -p "Overwrite existing installation? (y/n) " -n 1 -r
            echo
            if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
                print_info "Installation cancelled"
                exit 0
            fi
        fi

        # Backup existing installation
        local backup_path
        backup_path="${plugin_path}.backup.$(date +%s)"
        print_info "Backing up existing installation to: ${backup_path}"
        cp "${plugin_path}" "${backup_path}"
    fi

    # Download plugin file
    # shellcheck disable=SC2310
    if command_exists curl; then
        if ! curl -fsSL "${GITHUB_RAW}/${PLUGIN_NAME}" -o "${temp_file}"; then
            print_error "Failed to download plugin from GitHub"
            rm -f "${temp_file}"
            exit 1
        fi
    elif command_exists wget; then
        if ! wget -q "${GITHUB_RAW}/${PLUGIN_NAME}" -O "${temp_file}"; then
            print_error "Failed to download plugin from GitHub"
            rm -f "${temp_file}"
            exit 1
        fi
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    # Move to installation directory
    if ! mv "${temp_file}" "${plugin_path}"; then
        print_error "Failed to move plugin to ${plugin_path}"
        rm -f "${temp_file}"
        exit 1
    fi

    # Make executable
    if ! chmod +x "${plugin_path}"; then
        print_error "Failed to make plugin executable"
        exit 1
    fi

    print_success "Plugin installed successfully"
}

# Set up configuration
setup_config() {
    print_info "Setting up configuration..."

    # Create config directory
    if [[ ! -d "${CONFIG_DIR}" ]]; then
        mkdir -p "${CONFIG_DIR}"
        print_success "Created config directory: ${CONFIG_DIR}"
    fi

    # Download example config if config doesn't exist
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        print_info "Downloading example configuration..."

        local temp_config="/tmp/config.yaml.$$"

        # shellcheck disable=SC2310
        if command_exists curl; then
            if curl -fsSL "${GITHUB_RAW}/config/config.yaml.example" -o "${temp_config}" 2>/dev/null; then
                mv "${temp_config}" "${CONFIG_FILE}"
                print_success "Created example config: ${CONFIG_FILE}"
                print_warning "Please edit the config file to add your settings"
            else
                print_warning "Could not download example config"
                print_info "You'll need to create ${CONFIG_FILE} manually"
            fi
        elif command_exists wget; then
            if wget -q "${GITHUB_RAW}/config/config.yaml.example" -O "${temp_config}" 2>/dev/null; then
                mv "${temp_config}" "${CONFIG_FILE}"
                print_success "Created example config: ${CONFIG_FILE}"
                print_warning "Please edit the config file to add your settings"
            else
                print_warning "Could not download example config"
                print_info "You'll need to create ${CONFIG_FILE} manually"
            fi
        fi
    else
        print_info "Config file already exists: ${CONFIG_FILE}"
        print_info "To see the latest example, visit:"
        print_info "  ${GITHUB_RAW}/config/config.yaml.example"
    fi
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."

    if kubectl tcp-tunnel --version >/dev/null 2>&1; then
        print_success "Installation verified successfully"
        echo ""
        kubectl tcp-tunnel --version
        return 0
    else
        print_warning "Could not verify installation"
        print_info "You may need to restart your shell or update your PATH"
        return 1
    fi
}

# Print post-installation instructions
print_instructions() {
    echo ""
    echo "======================================"
    echo "  Installation Complete!"
    echo "======================================"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Edit your configuration file:"
    echo "   kubectl tcp-tunnel edit-config"
    echo ""
    echo "2. Update the following settings:"
    echo "   - namespace: Your Kubernetes namespace"
    echo "   - environments.*.k8s-context: Your kubectl contexts"
    echo "   - environments.*.databases.*: Your database hostnames"
    echo ""
    echo "3. Test the installation:"
    echo "   kubectl tcp-tunnel --help"
    echo "   kubectl tcp-tunnel ls"
    echo ""
    echo "4. Create your first tunnel:"
    echo "   kubectl tcp-tunnel --env staging --connection your_connection_alias"
    echo ""
    echo "For more information:"
    echo "  https://github.com/${GITHUB_REPO}"
    echo ""
}

# Main installation flow
main() {
    print_header

    # Detect OS
    local os
    os=$(detect_os)
    print_success "Detected OS: ${os}"

    # Check dependencies
    check_dependencies

    # Determine installation directory
    local install_dir
    install_dir=$(determine_install_dir)
    print_success "Installation directory: ${install_dir}"

    # Check PATH (non-fatal if not in PATH yet)
    # shellcheck disable=SC2310
    check_path "${install_dir}" || true

    # Download and install plugin
    download_plugin "${install_dir}"

    # Setup configuration
    setup_config

    # Verify installation (non-fatal)
    # shellcheck disable=SC2310
    verify_installation || true

    # Print instructions
    print_instructions
}

# Run main
main "$@"
