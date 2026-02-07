# Release Process

This document describes how to create a new release of kubectl-pg-tunnel.

## Prerequisites

- Write access to the repository
- All tests passing (`make check`)
- Updated CHANGELOG.md
- Clean working directory

## Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
  - **MAJOR**: Incompatible API changes
  - **MINOR**: New functionality (backwards-compatible)
  - **PATCH**: Bug fixes (backwards-compatible)

## Release Steps

### 1. Update CHANGELOG.md

Edit `CHANGELOG.md` and move items from `[Unreleased]` to a new version section:

```markdown
## [1.0.0] - 2024-01-15

### Added
- Feature A
- Feature B

### Fixed
- Bug fix A
```

Update the comparison links at the bottom:

```markdown
[Unreleased]: https://github.com/sgyyz/kubectl-pg-tunnel/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sgyyz/kubectl-pg-tunnel/releases/tag/v1.0.0
```

### 2. Commit CHANGELOG

```bash
git add CHANGELOG.md
git commit -m "Update CHANGELOG for v1.0.0"
```

### 3. Prepare Release

Use the Makefile to prepare the release:

```bash
make release VERSION=1.0.0
```

This will:
- Update version placeholder in `kubectl-pg_tunnel`
- Update version in `install.sh`
- Show you the next steps

### 4. Review Changes

```bash
git diff
```

Verify that:
- `kubectl-pg_tunnel` has `VERSION="v1.0.0"` (not `__VERSION__`)
- `install.sh` has `VERSION="1.0.0"`

### 5. Commit and Tag

```bash
# Commit version changes
git commit -am "Release v1.0.0"

# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Push to main and tags
git push origin main --tags
```

### 6. Automated Release

Once you push the tag, GitHub Actions will automatically:
1. Update version placeholders
2. Run all tests
3. Create release archive
4. Generate checksums
5. Create GitHub Release with:
   - Release notes
   - Download links
   - Installation instructions

### 7. Verify Release

1. Visit https://github.com/sgyyz/kubectl-pg-tunnel/releases
2. Verify the new release appears
3. Check that assets are attached:
   - `kubectl-pg-tunnel-v1.0.0.tar.gz`
   - `checksums.txt`
   - Individual files
4. Test installation:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-pg-tunnel/v1.0.0/install.sh | bash
   ```

### 8. Announce

- Update README.md badges if needed
- Announce in relevant channels
- Close related issues/PRs

## Manual Release (if needed)

If GitHub Actions fails, you can create a manual release:

### 1. Prepare Files

```bash
VERSION=1.0.0

# Update version in files
sed -i "s/__VERSION__/v${VERSION}/g" kubectl-pg_tunnel
sed -i "s/VERSION=\".*\"/VERSION=\"${VERSION}\"/g" install.sh

# Create archive
mkdir -p release
cp kubectl-pg_tunnel release/
cp install.sh release/
cp uninstall.sh release/
cp -r config release/
cp README.md LICENSE release/

cd release
tar -czf ../kubectl-pg-tunnel-v${VERSION}.tar.gz *
cd ..

# Create checksums
sha256sum kubectl-pg-tunnel-v${VERSION}.tar.gz > checksums.txt
```

### 2. Create GitHub Release

1. Go to https://github.com/sgyyz/kubectl-pg-tunnel/releases/new
2. Choose your tag
3. Add release notes
4. Upload files:
   - `kubectl-pg-tunnel-v1.0.0.tar.gz`
   - `checksums.txt`
5. Publish release

## Post-Release

### 1. Prepare for Next Release

Update `CHANGELOG.md` with new `[Unreleased]` section:

```markdown
## [Unreleased]

### Added

### Changed

### Fixed
```

Commit:

```bash
git add CHANGELOG.md
git commit -m "Prepare CHANGELOG for next release"
git push origin main
```

### 2. Verify Update Detection

Test that version checking works:

```bash
kubectl pg-tunnel --version
```

Should show current version and notify if update is available.

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
$ kubectl pg-tunnel --version
kubectl pg-tunnel version 1.0.0

⚠ A newer version is available: 1.1.0

Update with: kubectl pg-tunnel upgrade
```

This helps users stay up to date.
