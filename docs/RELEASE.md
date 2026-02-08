# Release Process

This document describes how to create a new release of kubectl-tcp-tunnel.

## Prerequisites

- Write access to the repository
- All tests passing (`make check`)
- On main branch and up-to-date with remote
- Clean working directory (no uncommitted changes)

## Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
  - **MAJOR**: Incompatible API changes
  - **MINOR**: New functionality (backwards-compatible)
  - **PATCH**: Bug fixes (backwards-compatible)

## Release Steps

The release process is fully automated through the Makefile. Here's how to create a release:

### 1. Ensure Clean State

```bash
# Make sure you're on main and up-to-date
git checkout main
git pull origin main

# Verify no uncommitted changes
git status

# Run tests
make check
```

### 2. Create Release

Run a single command to create the release:

```bash
make release VERSION=1.0.0
```

This command will automatically:
1. **Verify prerequisites:**
   - Check you're on main branch
   - Verify working directory is clean
   - Ensure local main is up-to-date with origin/main

2. **Update CHANGELOG.md:**
   - Analyze commits since last release
   - Categorize changes (Added, Fixed, Changed, etc.)
   - Generate new version section with today's date
   - Support conventional commits (feat:, fix:, docs:, etc.)

3. **Update versions:**
   - Update `kubectl-tcp_tunnel` to new version (e.g., v1.0.0 → v1.0.1)
   - Update `install.sh` to new version

4. **Commit and tag:**
   - Create commit: "Release v1.0.0"
   - Create annotated tag: v1.0.0
   - Ready to push

### 3. Push to GitHub

```bash
git push origin main --tags
```

### 4. Automated GitHub Release

Once you push the tag, GitHub Actions will automatically:
1. Package release files into tarball
2. Generate checksums
3. Extract release notes from CHANGELOG.md
4. Create GitHub Release with:
   - Release notes
   - Download links
   - Installation instructions
   - Release assets

### 7. Verify Release

1. Visit https://github.com/sgyyz/kubectl-tcp-tunnel/releases
2. Verify the new release appears
3. Check that assets are attached:
   - `kubectl-tcp-tunnel-v1.0.0.tar.gz`
   - `checksums.txt`
   - Individual files
4. Test installation:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-tcp-tunnel/v1.0.0/install.sh | bash
   ```

### 8. Announce

- Update README.md badges if needed
- Announce in relevant channels
- Close related issues/PRs

## Quick Reference

The entire release process in one command:

```bash
# Prerequisites: on main, up-to-date, clean working directory, tests pass
make release VERSION=1.0.0   # Updates, commits, and tags
git push origin main --tags  # Triggers GitHub Actions to publish
```

That's it! The rest is automated.

## Post-Release

### 1. Verify Release

1. Visit https://github.com/sgyyz/kubectl-tcp-tunnel/releases
2. Verify the new release appears
3. Check that assets are attached:
   - `kubectl-tcp-tunnel-v1.0.0.tar.gz`
   - `checksums.txt`
   - Individual files

### 2. Test Installation

Test the installation from the new release:

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-tcp-tunnel/v1.0.0/install.sh | bash
```

### 3. Test Upgrade Command

Test that existing users can upgrade:

```bash
kubectl tcp-tunnel upgrade
```

### 4. Verify Update Detection

Test that version checking works:

```bash
kubectl tcp-tunnel --version
```

Should show current version and notify if update is available.

### 5. Announce

- Update README.md badges if needed
- Announce in relevant channels
- Close related issues/PRs

## Hotfix Releases

For urgent bug fixes:

1. Create a hotfix branch from the tag:
   ```bash
   git checkout -b hotfix/1.0.1 v1.0.0
   ```

2. Make fixes and test:
   ```bash
   # Fix the bug
   make check
   ```

3. Update CHANGELOG.md with hotfix notes

4. Follow release process for patch version (1.0.1)

5. Merge back to main:
   ```bash
   git checkout main
   git merge hotfix/1.0.1
   git push origin main
   ```

## Rollback

If a release has critical issues:

1. Mark the release as pre-release on GitHub
2. Add warning to release notes
3. Prepare hotfix immediately
4. Notify users through issues/discussions

## Troubleshooting

### Version Placeholder Not Replaced

If `__VERSION__` appears in the released files:
- Check that GitHub Actions ran successfully
- Verify sed commands in `.github/workflows/release.yml`
- Manually update and re-release

### GitHub Actions Fails

1. Check Actions log for errors
2. Fix the issue in main
3. Delete the tag: `git tag -d v1.0.0 && git push origin :refs/tags/v1.0.0`
4. Recreate the release

### Release Assets Missing

1. Check GitHub Actions artifacts
2. Re-run the workflow
3. Or create manual release (see above)

## Best Practices

1. **Always test before releasing**
   ```bash
   make check
   ```

2. **Update CHANGELOG.md before tagging**
   - Helps with release notes
   - Documents what changed

3. **Use annotated tags**
   ```bash
   git tag -a v1.0.0 -m "Release v1.0.0"
   ```

4. **Test installation immediately**
   - Verify curl install works
   - Test upgrade command
   - Check version detection

5. **Keep versions consistent**
   - Tag: `v1.0.0`
   - In code: `1.0.0` or `v1.0.0`
   - Release: `v1.0.0`

6. **Document breaking changes**
   - Highlight in CHANGELOG
   - Include migration guide
   - Update documentation

## Version Detection

The plugin checks for updates on `--version`:

```bash
$ kubectl tcp-tunnel --version
kubectl tcp-tunnel version 1.0.0

⚠ A newer version is available: 1.1.0

Update with: kubectl tcp-tunnel upgrade
```

This helps users stay up to date.
