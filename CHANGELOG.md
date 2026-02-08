# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### Fixed
- Local port configuration now properly read from config file

## [1.0.1] - 2026-02-07

### Fixed

- kubectl tcp-tunnel will failed when upgrade it (#8)


## [1.0.0] - 2026-02-07

### Added

- Initial release of kubectl-tcp-tunnel
- Create PostgreSQL tunnels through Kubernetes jump pods
- YAML-based configuration with environments and database aliases
- Support for multiple environments (staging, production, etc.)
- Built-in commands: `ls`, `edit-config`, `upgrade`, `uninstall`
- Automatic cleanup of jump pods on exit
- Configuration file at `~/.config/kubectl-tcp-tunnel/config.yaml`
- Version checking and update notifications
- Comprehensive test suite with BATS
- CI/CD with GitHub Actions
- Installation via `curl | bash`
- Support for custom local and remote ports
- Reads local-port from config file when not specified via flag
- fix the release version management (#6)
- add the auto release workflow (#5)
- add the uninstall command for this plugin (#4)
- improve the README.md and remove the duplicate sections (#1)

[Unreleased]: https://github.com/sgyyz/kubectl-tcp-tunnel/compare/v1.0.1...HEAD
[1.0.0]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v1.0.0
[1.0.1]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v1.0.1
