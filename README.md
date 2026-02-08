# kubectl-tcp-tunnel

[![CI](https://github.com/sgyyz/kubectl-tcp-tunnel/actions/workflows/ci.yml/badge.svg)](https://github.com/sgyyz/kubectl-tcp-tunnel/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A kubectl plugin that simplifies creating secure TCP tunnels through Kubernetes jump pods. Supports any TCP service including PostgreSQL, MySQL, Redis, MongoDB, and more.

## Overview

`kubectl-tcp-tunnel` helps you securely access remote TCP services through your Kubernetes cluster without exposing them directly to the internet. It automates the process of creating temporary jump pods, establishing port forwards, and cleaning up resources.

### Key Features

- **Simple service access** - Connect to remote TCP services with a single command
- **Multi-service support** - PostgreSQL, MySQL, Redis, MongoDB, and any TCP service
- **Configuration-driven** - Define connection aliases and environments in YAML
- **Type system** - Use YAML anchors to define reusable connection types
- **Multi-environment** - Support staging, production, and custom environments
- **Automatic cleanup** - Jump pods are automatically deleted when you disconnect
- **Safe by default** - Uses kubectx for explicit context switching
- **Zero permanent infrastructure** - Jump pods are temporary and ephemeral

### How It Works

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│              │         │   Kubernetes    │         │              │
│  Your Local  │────────▶│    Cluster      │────────▶│  TCP Service │
│   Machine    │  Port   │   (Jump Pod)    │  Network│ (Postgres/   │
│              │  Forward│                 │  Access │  MySQL/etc)  │
└──────────────┘         └─────────────────┘         └──────────────┘
   localhost:port         alpine/socat pod          remote-host:port
```

1. Plugin switches to the correct Kubernetes context (via kubectx)
2. Creates a temporary jump pod running alpine/socat in your cluster
3. Jump pod connects to the remote TCP service host
4. kubectl port-forward tunnels your local port to the jump pod
5. You connect with any client to localhost:port
6. When you disconnect (Ctrl+C), the jump pod is automatically deleted

## Quick Start

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-tcp-tunnel/main/install.sh | bash
```

### Upgrade

Upgrade to the latest version using the built-in command:

```bash
kubectl tcp-tunnel upgrade
```

Or run the install script again:

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-tcp-tunnel/main/install.sh | bash
```

The installer will backup your existing installation and preserve your configuration.

### Uninstall

To uninstall kubectl-tcp-tunnel:

```bash
kubectl tcp-tunnel uninstall
```

Or run the uninstall script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-tcp-tunnel/main/uninstall.sh | bash
```

The uninstaller will prompt you whether to remove your configuration files.

### Configure

```bash
kubectl tcp-tunnel edit-config
```

Update with your Kubernetes contexts and service hosts:

```yaml
settings:
  namespace: default

  # Define connection types with YAML anchors
  postgres: &postgres
    local-port: 15432
    db-port: 5432

  mysql: &mysql
    local-port: 13306
    db-port: 3306

  redis: &redis
    local-port: 16379
    db-port: 6379

environments:
  staging:
    k8s-context: my-staging-cluster
    connections:
      user-db:
        host: user-db.staging.example.com
        type: *postgres
      order-db:
        host: order-db.staging.example.com
        type: *mysql
      cache:
        host: redis.staging.example.com
        type: *redis

  production:
    k8s-context: my-production-cluster
    connections:
      user-db:
        host: user-db.prod.example.com
        type: *postgres
      order-db:
        host: order-db.prod.example.com
        type: *mysql
```

### Use

```bash
# Create tunnel to staging PostgreSQL database
kubectl tcp-tunnel --env staging --db user-db
# Connect: psql -h localhost -p 15432 -U myuser mydatabase

# Create tunnel to staging MySQL database
kubectl tcp-tunnel --env staging --db order-db
# Connect: mysql -h localhost -P 13306 -u myuser mydatabase

# Create tunnel to Redis cache
kubectl tcp-tunnel --env staging --db cache
# Connect: redis-cli -h localhost -p 16379

# Override local port
kubectl tcp-tunnel --env staging --db user-db --local-port 5433
```

## Requirements

- **kubectl** (v1.20+) - Kubernetes command-line tool
- **kubectx** - Fast context switching for kubectl
- **yq** - YAML processor for parsing config files
- **bash** (v4.0+) - Bash shell

Install dependencies:

```bash
# macOS
brew install kubectl kubectx yq

# Ubuntu/Debian
sudo apt-get install kubectl kubectx yq
```

## Documentation

- **[Installation Guide](docs/INSTALLATION.md)** - Detailed installation instructions and setup
- **[Usage Guide](docs/USAGE.md)** - Complete usage documentation, commands, and examples
- **[Development Guide](docs/DEVELOPMENT.md)** - Contributing and development setup
- **[Contributing Guidelines](CONTRIBUTING.md)** - How to contribute

## Security

- **No direct exposure** - Services never exposed to the internet
- **Temporary access** - Jump pods exist only during your session
- **Context isolation** - Explicit context switching prevents accidents
- **Network policies** - Respects your cluster's network policies
- **Audit trail** - All operations logged in Kubernetes audit logs

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

For development setup:

```bash
git clone https://github.com/sgyyz/kubectl-tcp-tunnel.git
cd kubectl-tcp-tunnel
make dev-setup      # Install dependencies
make setup-hooks    # Set up pre-commit hooks
make check          # Run all checks
```

See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed documentation.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Links

- **GitHub**: https://github.com/sgyyz/kubectl-tcp-tunnel
- **Issues**: https://github.com/sgyyz/kubectl-tcp-tunnel/issues
- **Releases**: https://github.com/sgyyz/kubectl-tcp-tunnel/releases

## Acknowledgments

- Built with [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Uses [kubectx](https://github.com/ahmetb/kubectx) for context switching
- Uses [yq](https://github.com/mikefarah/yq) for YAML parsing
- Jump pods use [alpine/socat](https://hub.docker.com/r/alpine/socat)

---

Made with ❤️ for Kubernetes users
