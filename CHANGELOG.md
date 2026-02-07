# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of kubectl-pg-tunnel
- Create PostgreSQL tunnels through Kubernetes jump pods
- YAML-based configuration with environments and database aliases
- Support for multiple environments (staging, production, etc.)
- Built-in commands: `ls`, `edit-config`, `upgrade`, `uninstall`
- Automatic cleanup of jump pods on exit
- Configuration file at `~/.config/kubectl-pg-tunnel/config.yaml`
- Version checking and update notifications
- Comprehensive test suite with BATS
- CI/CD with GitHub Actions
- Installation via `curl | bash`
- Support for custom local and remote ports
- Reads local-port from config file when not specified via flag

### Fixed
- Local port configuration now properly read from config file

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release

[Unreleased]: https://github.com/sgyyz/kubectl-pg-tunnel/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/sgyyz/kubectl-pg-tunnel/releases/tag/v1.0.0
