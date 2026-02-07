# Development Guide

This guide covers setting up your development environment for kubectl-pg-tunnel.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/sgyyz/kubectl-pg-tunnel.git
cd kubectl-pg-tunnel

# 2. Install development dependencies
make dev-setup

# 3. Set up git hooks (optional but recommended)
make setup-hooks

# 4. Run checks
make check
```

## Development Dependencies

### Required Tools

- **shellcheck** - Bash/shell script linter
- **bats-core** - Bash Automated Testing System
- **yq** - YAML processor for config parsing

### Installation

#### macOS

```bash
brew install shellcheck bats-core yq
```

Or use the automated script:

```bash
make dev-setup
```

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y shellcheck bats yq
```

#### Fedora

```bash
sudo dnf install -y shellcheck bats yq
```

## Makefile Commands

The project includes a Makefile for common development tasks:

### Development Workflow

```bash
# Show all available commands
make help

# Install all dev dependencies (shellcheck, bats, yq)
make dev-setup

# Set up pre-commit hooks
make setup-hooks

# Run shellcheck linting
make lint

# Run BATS test suite
make test

# Run both lint and test (recommended before committing)
make check

# Clean temporary files
make clean
```

### Local Testing

```bash
# Install plugin locally for testing
make install

# Test the plugin
kubectl pg-tunnel --help
kubectl pg-tunnel --version

# Uninstall after testing
make uninstall
```

## Git Hooks

### Pre-commit Hook

The repository includes a pre-commit hook that automatically runs shellcheck on modified shell scripts.

#### Setup

```bash
make setup-hooks
```

This configures git to use `.githooks/pre-commit` which will:
- Run shellcheck on all staged shell scripts
- Prevent commits if shellcheck finds issues
- Can be bypassed with `git commit --no-verify` (not recommended)

#### Manual Hook Installation

If you prefer to manually install the hook:

```bash
git config core.hooksPath .githooks
```

## Running Checks Locally

### Before Committing

Always run this before committing:

```bash
make check
```

This ensures:
- ✓ All shellcheck linting passes
- ✓ All BATS tests pass
- ✓ Code follows style guidelines

### Individual Checks

```bash
# Run only shellcheck
make lint

# Run only tests
make test
```

## Shellcheck Configuration

The project uses `.shellcheckrc` for consistent linting rules:

```bash
# Disabled rules
disable=SC1090,SC1091  # Can't follow non-constant source files

# Shell directive
shell=bash

# Severity level
severity=style

# Enable all optional checks
enable=all
```

### Common Shellcheck Fixes

When shellcheck reports issues, here are common patterns:

#### SC2250 - Variable braces
```bash
# Bad
$variable

# Good
${variable}
```

#### SC2064 - Trap expansion
```bash
# If you want variables to expand now (usually correct)
# shellcheck disable=SC2064
trap "cleanup '${pod_name}'" EXIT

# If you want variables to expand when trap fires
trap 'cleanup "${pod_name}"' EXIT
```

#### SC2310 - Functions in conditionals
```bash
# This is intentional and correct
# shellcheck disable=SC2310
if ! command_exists kubectl; then
    echo "kubectl not found"
fi
```

## Testing

### BATS Tests

Tests are located in `tests/pg_tunnel_test.bats`.

#### Running Tests

```bash
# Run all tests
make test

# Run with BATS directly
bats tests/pg_tunnel_test.bats

# Run specific test
bats tests/pg_tunnel_test.bats -f "shows help"
```

#### Writing Tests

Test structure:

```bash
@test "test description" {
    # Setup
    export CONFIG_FILE="${TEST_CONFIG}"

    # Execute
    run_plugin --help

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" =~ "expected text" ]]
}
```

### Mocking

Tests use mocked `kubectl` and `kubectx` commands to avoid requiring a real cluster.

## Code Style Guidelines

### Bash Best Practices

1. **Always use braces for variables**
   ```bash
   ${variable}  # Good
   $variable    # Bad
   ```

2. **Use set -euo pipefail**
   ```bash
   set -euo pipefail  # Exit on error, undefined vars, pipe failures
   ```

3. **Quote variables**
   ```bash
   "${variable}"     # Good
   $variable         # Bad
   ```

4. **Use local for function variables**
   ```bash
   function my_func() {
       local var="value"
   }
   ```

5. **Separate declaration and assignment for command substitution**
   ```bash
   # Good
   local result
   result=$(command)

   # Bad (SC2155)
   local result=$(command)
   ```

### Comments

- Add comments for complex logic
- Function headers should describe purpose, parameters, and return values
- Use `# shellcheck disable=SCXXXX` when intentionally violating a rule (with explanation)

### Error Handling

```bash
# Check command success
if ! command; then
    print_error "Command failed"
    exit 1
fi

# Non-fatal errors
command || true

# Command substitution with error checking
if ! result=$(command); then
    print_error "Failed to get result"
    exit 1
fi
```

## Project Structure

```
kubectl-pg-tunnel/
├── kubectl-pg_tunnel           # Main plugin executable
├── install.sh                  # Installation script
├── uninstall.sh                # Uninstallation script
├── dev-setup.sh                # Development setup script
├── Makefile                    # Development commands
├── README.md                   # User documentation
├── CONTRIBUTING.md             # Contribution guidelines
├── DEVELOPMENT.md              # This file
├── LICENSE                     # MIT license
├── .gitignore                  # Git ignore patterns
├── .shellcheckrc               # Shellcheck configuration
├── .githooks/
│   └── pre-commit              # Pre-commit hook
├── config/
│   └── config.yaml.example     # Example configuration
├── tests/
│   └── pg_tunnel_test.bats     # BATS test suite
└── .github/
    └── workflows/
        └── ci.yml              # GitHub Actions CI/CD
```

## CI/CD

The project uses GitHub Actions for continuous integration.

### Workflow

See `.github/workflows/ci.yml` for the full workflow definition.

Jobs:
1. **Lint** - Runs shellcheck on all scripts
2. **Test** - Runs BATS test suite
3. **Compatibility** - Tests on Ubuntu and macOS
4. **Security** - Scans for hardcoded secrets
5. **Documentation** - Validates documentation completeness

### Triggering CI

CI runs on:
- Push to `main` branch
- All pull requests
- Manual workflow dispatch

### Concurrency

New CI runs automatically cancel previous runs for the same branch/PR to save resources.

## Troubleshooting

### Shellcheck not found

```bash
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt-get install shellcheck

# Fedora
sudo dnf install shellcheck
```

### BATS not found

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Fedora
sudo dnf install bats
```

### yq not found

```bash
# macOS
brew install yq

# Linux
See https://github.com/mikefarah/yq#install
```

### Git hooks not running

```bash
# Verify hooks are configured
git config core.hooksPath

# Should output: .githooks

# Reconfigure if needed
make setup-hooks
```

## Getting Help

- Check the [README.md](../README.md) for user documentation
- Check [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines
- Open an issue on GitHub for bugs or questions
- Review existing issues and pull requests

## Resources

- [Shellcheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [BATS Documentation](https://bats-core.readthedocs.io/)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [Bash Best Practices](https://mywiki.wooledge.org/BashGuide/Practices)

## Release Process

See [RELEASE.md](RELEASE.md) for detailed instructions on creating releases.

Quick release:

```bash
# Update CHANGELOG.md first
git add CHANGELOG.md
git commit -m "Update CHANGELOG for v1.0.0"

# Prepare release
make release VERSION=1.0.0

# Push with tags
git push origin main --tags
```

GitHub Actions will automatically create the release.

For more information, see:
- [RELEASE.md](RELEASE.md) - Complete release documentation
- [CHANGELOG.md](../CHANGELOG.md) - Version history
