# kubectl-tcp-tunnel

[![CI](https://github.com/sgyyz/kubectl-tcp-tunnel/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sgyyz/kubectl-tcp-tunnel/actions/workflows/ci.yml)
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
- **Pod reuse** - One pod per machine/connection type, automatically reused on reconnection
- **Safe by default** - Uses kubectx for explicit context switching
- **Zero permanent infrastructure** - Jump pods can be manually cleaned up when no longer needed

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
2. Creates or reuses a jump pod running alpine/socat in your cluster (one pod per machine)
3. Jump pod connects to the remote TCP service host
4. kubectl port-forward tunnels your local port to the jump pod
5. You connect with any client to localhost:port
6. When you disconnect (Ctrl+C), the port forward stops (pod remains for reuse)
7. Use `kubectl tcp-tunnel cleanup` to manually delete pods when finished

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

### Use

```bash
# Create tunnel to staging PostgreSQL database
kubectl tcp-tunnel -e staging -c user-db
# Connect: psql -h localhost -p 15432 -U myuser mydatabase

# Create tunnel to staging MySQL database
kubectl tcp-tunnel -e staging -c order-db
# Connect: mysql -h localhost -P 13306 -u myuser mydatabase

# Create tunnel to Redis cache
kubectl tcp-tunnel -e staging -c cache
# Connect: redis-cli -h localhost -p 16379

# Override local port (using long form)
kubectl tcp-tunnel --env staging --connection user-db --local-port 5433
# Or using short form
kubectl tcp-tunnel -e staging -c user-db -p 5433

# Clean up jump pods when finished
kubectl tcp-tunnel cleanup
```

### Pod Reuse

Jump pods are now reused across connections:

- **One pod per machine/connection type** - Pods are named using your machine's hostname (e.g., `postgres-tunnel-johns-macbook`)
- **Automatic reuse** - Reconnecting to the same service reuses the existing pod (faster startup)
- **Manual cleanup** - Use `kubectl tcp-tunnel cleanup` to delete all jump pods for your machine
- **No automatic deletion** - Pods remain after Ctrl+C for quick reconnection

**Example workflow:**
```bash
# First connection - creates pod
kubectl tcp-tunnel -e staging -c user-db
# Press Ctrl+C to stop port forwarding

# Second connection - reuses pod (faster!)
kubectl tcp-tunnel -e staging -c user-db
# Press Ctrl+C again

# When finished for the day, clean up
kubectl tcp-tunnel cleanup
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
- **Reusable pods** - Jump pods remain running until manually cleaned up
- **Context isolation** - Explicit context switching prevents accidents
- **Network policies** - Respects your cluster's network policies
- **Audit trail** - All operations logged in Kubernetes audit logs

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

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
