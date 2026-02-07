# Contributing to kubectl-pg-tunnel

Thank you for your interest in contributing to kubectl-pg-tunnel! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming environment

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:

1. **Clear title** - Briefly describe the issue
2. **Environment details** - OS, kubectl version, kubectx version, bash version
3. **Steps to reproduce** - Detailed steps to reproduce the issue
4. **Expected behavior** - What you expected to happen
5. **Actual behavior** - What actually happened
6. **Error messages** - Any error messages or logs
7. **Configuration** - Relevant parts of your config (sanitize sensitive data)

Example:
```
Title: Jump pod fails to start with timeout error

Environment:
- OS: macOS 13.0
- kubectl: v1.28.0
- kubectx: v0.9.4
- bash: 5.2.15

Steps to reproduce:
1. Run: kubectl pg-tunnel -p staging staging_primary
2. Wait for pod creation

Expected: Pod becomes ready within 60 seconds
Actual: Timeout after 60 seconds

Error: "Pod failed to become ready within 60s"

Config:
JUMP_POD_WAIT_TIMEOUT="60"
NAMESPACE="default"
```

### Suggesting Features

Feature requests are welcome! Please open an issue with:

1. **Use case** - Describe the problem you're trying to solve
2. **Proposed solution** - Your idea for how to solve it
3. **Alternatives** - Other solutions you've considered
4. **Additional context** - Any other relevant information

### Submitting Pull Requests

#### Before You Start

1. **Check existing issues** - Make sure your change isn't already being worked on
2. **Open an issue first** - For large changes, discuss the approach first
3. **One PR per feature** - Keep PRs focused on a single change

#### Development Process

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/kubectl-pg-tunnel.git
   cd kubectl-pg-tunnel
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**
   - Follow the code style guidelines below
   - Add tests for new functionality
   - Update documentation as needed

4. **Test your changes**
   ```bash
   # Run shellcheck
   shellcheck kubectl-pg_tunnel install.sh uninstall.sh

   # Run tests
   bats tests/pg_tunnel_test.bats

   # Test installation
   ./install.sh
   kubectl pg-tunnel --help
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: description of feature"
   ```

   Use clear, descriptive commit messages:
   - `Add: <feature>` - New feature
   - `Fix: <issue>` - Bug fix
   - `Update: <component>` - Update existing feature
   - `Docs: <change>` - Documentation only
   - `Test: <change>` - Tests only
   - `Refactor: <component>` - Code refactoring

6. **Push to your fork**
   ```bash
   git push origin feature/my-feature
   ```

7. **Open a Pull Request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Describe what changed and why
   - List any breaking changes
   - Include testing steps

#### Pull Request Template

```markdown
## Description
Brief description of the change

## Related Issues
Fixes #123

## Changes
- Change 1
- Change 2

## Testing
How to test this change:
1. Step 1
2. Step 2

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Shellcheck passes
- [ ] All tests pass
- [ ] No breaking changes (or documented)
```

## Code Style Guidelines

### Bash Style

- **Use `set -euo pipefail`** - Exit on errors, undefined variables, and pipe failures
- **Quote variables** - Always quote variables: `"${var}"` not `$var`
- **Use functions** - Break code into logical functions
- **Add comments** - Explain complex logic
- **Use lowercase** - Function and variable names in lowercase with underscores
- **Constants in UPPERCASE** - Configuration constants in UPPERCASE

Example:
```bash
# Good
my_function() {
    local input="$1"
    echo "Processing: ${input}"
}

# Bad
myFunction() {
    echo "Processing: $1"
}
```

### Error Handling

- **Check return codes** - Use `if ! command; then` or `command || handle_error`
- **Provide helpful errors** - Include context and suggestions
- **Clean up on failure** - Use traps for cleanup

Example:
```bash
# Good
if ! kubectl get pod "${pod_name}" &>/dev/null; then
    print_error "Pod not found: ${pod_name}"
    echo "Available pods:"
    kubectl get pods
    exit 1
fi

# Bad
kubectl get pod $pod_name
```

### Output Style

- **Use color functions** - `print_error`, `print_success`, `print_info`, `print_warning`
- **Be consistent** - Follow existing output format
- **User-friendly messages** - Clear, actionable messages

### Testing Requirements

All new features and bug fixes must include tests:

1. **Unit tests** - Test individual functions
2. **Integration tests** - Test command flows
3. **Error cases** - Test error handling
4. **Edge cases** - Test boundary conditions

Example:
```bash
@test "errors on missing required argument" {
    run_plugin -p staging
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required argument" ]]
}
```

## Documentation Requirements

### Code Documentation

- **Function headers** - Describe purpose, parameters, and return values
- **Complex logic** - Add inline comments
- **Configuration** - Document all config variables

Example:
```bash
# Create a tunnel to the specified database
# Arguments:
#   $1 - profile name (staging, prod, etc.)
#   $2 - database host alias
# Returns:
#   0 on success, 1 on failure
create_tunnel() {
    local profile="$1"
    local host_alias="$2"
    # ...
}
```

### User Documentation

When adding features, update:

- **README.md** - Usage examples, configuration, troubleshooting
- **Help text** - Update `show_help()` function
- **Example config** - Update `pg-tunnel.conf.example`
- **CHANGELOG** - Add entry for the change

## Testing

### Running Tests

```bash
# Install BATS
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# Fedora
sudo dnf install bats

# Run all tests
bats tests/pg_tunnel_test.bats

# Run specific test
bats tests/pg_tunnel_test.bats -f "test name"
```

### Running Shellcheck

```bash
# Install shellcheck
# macOS
brew install shellcheck

# Ubuntu/Debian
sudo apt-get install shellcheck

# Run on all scripts
shellcheck kubectl-pg_tunnel install.sh uninstall.sh

# Run with specific severity
shellcheck -S warning kubectl-pg_tunnel
```

## Release Process

Maintainers follow this process for releases:

1. **Update version** - In `kubectl-pg_tunnel` and `install.sh`
2. **Update CHANGELOG** - Document all changes
3. **Run all tests** - Ensure everything passes
4. **Create tag** - `git tag -a v1.0.0 -m "Release v1.0.0"`
5. **Push tag** - `git push origin v1.0.0`
6. **Create release** - On GitHub with release notes

## Getting Help

- **Questions** - Open a GitHub issue with the "question" label
- **Discussions** - Use GitHub Discussions for general topics
- **Real-time chat** - (Add your chat platform if applicable)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- GitHub contributors page

Thank you for contributing to kubectl-pg-tunnel!

## Commit Message Conventions

We use structured commit messages to automatically generate CHANGELOGs. This makes it easy to track changes and understand what each release includes.

### Quick Reference

Use these prefixes in your commit messages:

- `feat:` - New feature (appears under **Added** in CHANGELOG)
- `fix:` - Bug fix (appears under **Fixed**)
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Test updates
- `chore:` - Maintenance tasks

### Examples

```bash
feat: add uninstall command
fix: local-port config not being read
docs: update installation guide
refactor: simplify version comparison
test: add upgrade command tests
```

For complete guidelines, see [COMMIT_CONVENTIONS.md](docs/COMMIT_CONVENTIONS.md).

### Benefits

- Automatic CHANGELOG generation
- Clear communication of changes
- Easy to understand git history
- Professional release notes

While not strictly enforced, following these conventions helps maintain a clean project history and makes releases smoother.
