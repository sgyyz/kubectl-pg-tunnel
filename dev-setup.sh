#!/usr/bin/env bash

set -euo pipefail

# Development setup script for kubectl-tcp-tunnel

echo "kubectl-tcp-tunnel - Development Setup"
echo "======================================"
echo ""

# Detect OS
UNAME_OS="$(uname)"
if [[ "${UNAME_OS}" == "Darwin" ]]; then
    OS="macos"
    PKG_MGR="brew"
elif [[ "${UNAME_OS}" == "Linux" ]]; then
    OS="linux"
    if command -v apt-get &>/dev/null; then
        PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    else
        echo "Unsupported package manager"
        exit 1
    fi
else
    echo "Unsupported OS"
    exit 1
fi

echo "Detected OS: ${OS}"
echo "Package manager: ${PKG_MGR}"
echo ""

# Check and install dependencies
check_and_install() {
    local cmd="$1"
    local install_name="${2:-$1}"

    if command -v "${cmd}" &>/dev/null; then
        echo "✓ ${cmd} is already installed"
    else
        echo "→ Installing ${install_name}..."
        case "${PKG_MGR}" in
            brew)
                brew install "${install_name}"
                ;;
            apt)
                sudo apt-get update
                sudo apt-get install -y "${install_name}"
                ;;
            dnf)
                sudo dnf install -y "${install_name}"
                ;;
            *)
                echo "Error: Unsupported package manager: ${PKG_MGR}"
                exit 1
                ;;
        esac
        echo "✓ ${install_name} installed"
    fi
}

echo "Installing development dependencies..."
echo ""

# Install shellcheck
check_and_install shellcheck shellcheck

# Install BATS
if [[ "${PKG_MGR}" == "brew" ]]; then
    check_and_install bats bats-core
else
    check_and_install bats bats
fi

# Install yq
check_and_install yq yq

echo ""
echo "======================================"
echo "✓ Development setup complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Run 'make lint' to check code style"
echo "  2. Run 'make test' to run tests"
echo "  3. Run 'make check' to run all checks"
echo ""
echo "See 'make help' for all available commands"
echo ""
