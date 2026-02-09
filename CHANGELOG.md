# Changelog


## [2.1.1] - 2026-02-09

### Added

- add the cleanup flag when we start it (#25)
- use the hostname as the pod suffix to make it reusable (#24)
- use the job instead of pod to auto clean-up (#22)

### Fixed

- revert the job to use the pod (#23)


## [2.1.0] - 2026-02-08

### Changed

- split the tests by logically groups (#21)

### Fixed

- db-port is not working and change the db-port to remote-port (#20)
- set the default branch for the CI status badge (#19)


## [2.0.3] - 2026-02-08

### Added

- remove the CHANGELOG.md.bak after completed the release (#18)
- use the emoji for the output information (#17)


## [2.0.2] - 2026-02-08

### Added

- add the short arg for --env/-e --connection/-c --local-port/-p (#16)
- only keep the key information for the README (#14)

### Fixed

- update the --db to --connection (#15)


## [2.0.1] - 2026-02-08

### Added

- improve the pod name by connection type with random string (#13)


## [2.0.0] - 2026-02-08

### Changed

- change the project from kubectl-pg-tunnel to kubectl-tcp-tunnel (#12)

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

[Unreleased]: https://github.com/sgyyz/kubectl-tcp-tunnel/compare/v2.1.1...HEAD
[1.0.0]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v1.0.0
[1.0.1]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v1.0.1
[2.0.0]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v2.0.0
[2.0.1]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v2.0.1
[2.0.2]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v2.0.2
[2.0.3]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v2.0.3
[2.1.0]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v2.1.0
[2.1.1]: https://github.com/sgyyz/kubectl-tcp-tunnel/releases/tag/v2.1.1
