# Commit Message Conventions

This project uses structured commit messages to automatically generate CHANGELOGs.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

The type determines which section of the CHANGELOG your commit appears in:

| Type | CHANGELOG Section | Description | Example |
|------|------------------|-------------|---------|
| `feat` | **Added** | New feature | `feat: add uninstall command` |
| `fix` | **Fixed** | Bug fix | `fix: local-port config not read` |
| `docs` | **Documentation** | Documentation only | `docs: update installation guide` |
| `refactor` | **Changed** | Code change (no fix/feat) | `refactor: simplify version check` |
| `perf` | **Performance** | Performance improvement | `perf: optimize config loading` |
| `test` | **Testing** | Add/update tests | `test: add upgrade command tests` |
| `build` | **Build** | Build system changes | `build: update release workflow` |
| `ci` | **CI/CD** | CI configuration | `ci: add shellcheck to workflow` |
| `chore` | **Maintenance** | Other changes | `chore: update dependencies` |
| `style` | **Style** | Code style changes | `style: fix shellcheck warnings` |

## Simple Keywords (Also Supported)

If you don't use conventional commits, these keywords in commit messages are also recognized:

| Keyword | CHANGELOG Section | Example |
|---------|------------------|---------|
| `Add` | **Added** | `Add version checking` |
| `Fix` | **Fixed** | `Fix port binding issue` |
| `Update` | **Changed** | `Update documentation` |
| `Remove` | **Removed** | `Remove deprecated flag` |
| `Deprecate` | **Deprecated** | `Deprecate old config format` |

## Examples

### Good Examples

**Feature:**
```
feat: add uninstall command

- Add uninstall_plugin() function
- Update help text with uninstall subcommand
- Add tests for uninstall command
```

**Bug Fix:**
```
fix: local-port config not being read

The local_port variable was initialized with hardcoded default
instead of reading from config file. Now reads from config when
--local-port flag is not provided.

Fixes #123
```

**Documentation:**
```
docs: add release process documentation

Create comprehensive guide for creating releases including:
- Version management
- CHANGELOG updates
- GitHub Actions workflow
```

**Refactor:**
```
refactor: simplify version comparison logic

Replace string comparison with sort -V for proper semantic versioning.
```

**Multiple Changes:**
```
feat: implement version management

- Add dynamic version placeholders
- Implement update checking
- Create release automation scripts
- Update documentation
```

### Bad Examples

❌ `update stuff` - Too vague, no context
❌ `WIP` - Not descriptive
❌ `fix bug` - Which bug?
❌ `changes` - What changes?

## Scopes (Optional)

Scopes provide additional context:

```
feat(cli): add --debug flag
fix(config): handle missing yaml keys
docs(readme): update quick start
test(integration): add tunnel creation tests
```

Common scopes:
- `cli` - Command-line interface
- `config` - Configuration handling
- `docs` - Documentation
- `test` - Testing
- `ci` - CI/CD
- `release` - Release process

## Breaking Changes

For breaking changes, add `!` after type or add footer:

```
feat!: change config format to YAML

BREAKING CHANGE: Configuration format changed from bash to YAML.
See migration guide in docs/MIGRATION.md
```

## Footer Keywords

Special footers:

- `Fixes #123` - Links to issue/PR
- `Closes #456` - Closes issue
- `BREAKING CHANGE:` - Breaking change description
- `Co-authored-by:` - Additional authors

Example:
```
fix: resolve port conflict on restart

Check if port is already in use before binding.

Fixes #42
Co-authored-by: Jane Doe <jane@example.com>
```

## What Gets Excluded from CHANGELOG

These are automatically filtered out:

- Merge commits (`Merge branch...`, `Merge pull request...`)
- Release commits (`Release v1.0.0`)
- CHANGELOG update commits (`Update CHANGELOG`, `Prepare CHANGELOG`)

## CHANGELOG Generation

When you run `make release VERSION=1.0.0`, the script:

1. Analyzes all commits since the last tag
2. Categorizes each commit by type/keyword
3. Groups commits into CHANGELOG sections
4. Generates a new version entry
5. Updates the release date automatically

Example generated CHANGELOG:

```markdown
## [1.0.0] - 2024-01-15

### Added
- Add uninstall command
- Add version checking and update notifications
- Implement automatic CHANGELOG generation

### Fixed
- Fix local-port config not being read
- Resolve port conflict on restart

### Changed
- Simplify version comparison logic
- Update CLI help text

### Documentation
- Add release process guide
- Update installation instructions
```

## Best Practices

1. **Write clear, descriptive messages**
   - Explain what and why, not just what
   - Future you will thank you

2. **Use imperative mood**
   - "Add feature" not "Added feature"
   - "Fix bug" not "Fixed bug"

3. **Keep first line under 72 characters**
   - Makes it easier to read in logs
   - GitHub truncates longer messages

4. **Use body for detailed explanation**
   - First line is summary
   - Body explains context and reasoning

5. **Reference issues**
   - Link related issues/PRs
   - Helps track changes

6. **One logical change per commit**
   - Makes review easier
   - Simplifies rollback if needed

## Pre-commit Hook

The pre-commit hook checks:
- Shellcheck passes
- No syntax errors

It does NOT enforce commit message format, but following conventions helps with CHANGELOG generation.

## Manual CHANGELOG Edits

You can manually edit CHANGELOG.md before release:

1. Run `make release VERSION=1.0.0` to generate entries
2. Review and edit `CHANGELOG.md`
3. Clean up entries, add context
4. Commit the edited version
5. Continue with release process

The script creates a backup (`CHANGELOG.md.bak`) in case you need to restore.

## Checking Your Commits

Before creating a release, review recent commits:

```bash
# See commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# See commits with full messages
git log $(git describe --tags --abbrev=0)..HEAD
```

Ensure messages are clear and categorized correctly.

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)
