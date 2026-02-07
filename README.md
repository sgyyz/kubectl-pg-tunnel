# kubectl-pg-tunnel

[![CI](https://github.com/sgyyz/kubectl-pg-tunnel/actions/workflows/ci.yml/badge.svg)](https://github.com/sgyyz/kubectl-pg-tunnel/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A kubectl plugin that simplifies creating secure PostgreSQL tunnels through Kubernetes jump pods.

## Overview

`kubectl-pg-tunnel` helps you securely access remote PostgreSQL databases through your Kubernetes cluster without exposing databases directly to the internet. It automates the process of creating temporary jump pods, establishing port forwards, and cleaning up resources.

### Key Features

- **Simple database access** - Connect to remote databases with a single command
- **Configuration-driven** - Define database aliases and environments in YAML
- **Multi-environment** - Support staging, production, and custom environments
- **Automatic cleanup** - Jump pods are automatically deleted when you disconnect
- **Safe by default** - Uses kubectx for explicit context switching
- **Zero permanent infrastructure** - Jump pods are temporary and ephemeral

### How It Works

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│              │         │   Kubernetes    │         │              │
│  Your Local  │────────▶│    Cluster      │────────▶│  PostgreSQL  │
│   Machine    │  Port   │   (Jump Pod)    │  Network│   Database   │
│              │  Forward│                 │  Access │              │
└──────────────┘         └─────────────────┘         └──────────────┘
   localhost:5432         alpine/socat pod           remote-db:5432
```

1. Plugin switches to the correct Kubernetes context (via kubectx)
2. Creates a temporary jump pod running alpine/socat in your cluster
3. Jump pod connects to the remote PostgreSQL host
4. kubectl port-forward tunnels localhost:5432 to the jump pod
5. You connect with psql or any PostgreSQL client to localhost:5432
6. When you disconnect (Ctrl+C), the jump pod is automatically deleted

## Quick Start

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-pg-tunnel/main/install.sh | bash
```

### Upgrade

Upgrade to the latest version using the built-in command:

```bash
kubectl pg-tunnel upgrade
```

Or run the install script again:

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-pg-tunnel/main/install.sh | bash
```

The installer will backup your existing installation and preserve your configuration.

### Uninstall

To uninstall kubectl-pg-tunnel:

```bash
kubectl pg-tunnel uninstall
```

Or run the uninstall script directly:

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-pg-tunnel/main/uninstall.sh | bash
```

The uninstaller will prompt you whether to remove your configuration files.

### Configure

```bash
kubectl pg-tunnel edit-config
```

Update with your Kubernetes contexts and database hosts:

```yaml
settings:
  namespace: default

environments:
  staging:
    k8s-context: my-staging-cluster
    databases:
      user-db: user-db.staging.example.com
      order-db: order-db.staging.example.com

  production:
    k8s-context: my-production-cluster
    databases:
      user-db: user-db.prod.example.com
      order-db: order-db.prod.example.com
```

### Use

```bash
# Create tunnel to staging user database
kubectl pg-tunnel --env staging --db user-db

# In another terminal, connect with psql
psql -h localhost -p 5432 -U myuser mydatabase
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

- **No direct exposure** - Database never exposed to the internet
- **Temporary access** - Jump pods exist only during your session
- **Context isolation** - Explicit context switching prevents accidents
- **Network policies** - Respects your cluster's network policies
- **Audit trail** - All operations logged in Kubernetes audit logs

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

For development setup:

```bash
git clone https://github.com/sgyyz/kubectl-pg-tunnel.git
cd kubectl-pg-tunnel
make dev-setup      # Install dependencies
make setup-hooks    # Set up pre-commit hooks
make check          # Run all checks
```

See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed documentation.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Links

- **GitHub**: https://github.com/sgyyz/kubectl-pg-tunnel
- **Issues**: https://github.com/sgyyz/kubectl-pg-tunnel/issues
- **Releases**: https://github.com/sgyyz/kubectl-pg-tunnel/releases

## Acknowledgments

- Built with [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Uses [kubectx](https://github.com/ahmetb/kubectx) for context switching
- Uses [yq](https://github.com/mikefarah/yq) for YAML parsing
- Jump pods use [alpine/socat](https://hub.docker.com/r/alpine/socat)

---

Made with ❤️ for Kubernetes and PostgreSQL users
