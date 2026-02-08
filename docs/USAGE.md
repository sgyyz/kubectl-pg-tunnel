# Usage Guide

Comprehensive guide for using kubectl-tcp-tunnel for any TCP service.

## Table of Contents

- [Basic Usage](#basic-usage)
- [Configuration](#configuration)
- [Commands](#commands)
- [Examples](#examples)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)

## Basic Usage

### Command Syntax

```bash
kubectl tcp-tunnel -e <environment> -c <connection> [OPTIONS]
kubectl tcp-tunnel --env <environment> --connection <connection> [OPTIONS]
```

### Required Flags

- `-e, --env <environment>` - Environment to use (staging, production, etc.)
- `-c, --connection <connection>` - Connection alias to use (supports any TCP service)

### Optional Flags

- `-p, --local-port <port>` - Local port to forward to (overrides connection type default)
- `--help` - Show help message
- `--version` - Show version information

## Configuration

### Config File Location

The plugin looks for configuration at:
- `~/.config/kubectl-tcp-tunnel/config.yaml` (default)
- Or set `TCP_TUNNEL_CONFIG` environment variable to use a custom location

### Configuration Structure

```yaml
# Global settings
settings:
  namespace: default
  jump-pod-image: alpine/socat:latest
  jump-pod-wait-timeout: 60

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

  mongodb: &mongodb
    local-port: 17017
    db-port: 27017

# Define environments
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

### Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `settings.namespace` | Kubernetes namespace for jump pods | `default` |
| `settings.jump-pod-image` | Docker image with socat | `alpine/socat:latest` |
| `settings.jump-pod-wait-timeout` | Seconds to wait for pod ready | `60` |
| `settings.<type>.local-port` | Local port for connection type | Type-specific |
| `settings.<type>.db-port` | Remote port for connection type | Type-specific |
| `environments.<name>.k8s-context` | Kubectl context for environment | Required |
| `environments.<name>.connections.<alias>.host` | Service hostname | Required |
| `environments.<name>.connections.<alias>.type` | Connection type (YAML anchor) | Required |

### Editing Configuration

```bash
# Edit configuration with your default editor
kubectl tcp-tunnel edit-config

# Or edit directly
$EDITOR ~/.config/kubectl-tcp-tunnel/config.yaml
```

### Adding New Environments

```yaml
environments:
  # Add a new environment
  dev:
    k8s-context: my-dev-cluster
    connections:
      main-db:
        host: postgres-dev.internal.example.com
        type: *postgres
      analytics-db:
        host: analytics-dev.internal.example.com
        type: *postgres
```

### Adding Custom Connection Types

You can define custom connection types for any TCP service:

```yaml
settings:
  # Custom application on port 8080
  myapp: &myapp
    local-port: 18080
    db-port: 8080

  # SSH tunnel
  ssh: &ssh
    local-port: 2222
    db-port: 22

environments:
  staging:
    k8s-context: staging-cluster
    connections:
      app-server:
        host: app.staging.example.com
        type: *myapp
      bastion:
        host: bastion.staging.example.com
        type: *ssh
```

## Commands

### Create a Tunnel

```bash
# Connect to staging user database (short form)
kubectl tcp-tunnel -e staging -c user-db

# Connect to production order database (long form)
kubectl tcp-tunnel --env production --connection order-db

# Use custom local port (short form)
kubectl tcp-tunnel -e staging -c user-db -p 5433
```

When the tunnel is established, you'll see:

```
✓ Switched to context: my-staging-cluster
✓ Created jump pod: pg-jump-user-db
✓ Pod is ready

✓ Tunnel established!
→ Local:  localhost:5432
→ Remote: user-db.staging.example.com:5432

→ Connect with: psql -h localhost -p 5432 -U <username> <database>

⚠ Press Ctrl+C to stop the tunnel and clean up
```

### List Resources

```bash
# List all environments and connections
kubectl tcp-tunnel ls

# List connections for specific environment
kubectl tcp-tunnel ls staging
```

Output:
```
Available environments and connections:

Environment: staging
  Kubernetes context: my-staging-cluster
  Connections:
    - user-db: user-db.staging.example.com
    - order-db: order-db.staging.example.com
    - cache: redis.staging.example.com

Environment: production
  Kubernetes context: my-production-cluster
  Connections:
    - user-db: user-db.prod.example.com
    - order-db: order-db.prod.example.com
```

### Edit Configuration

```bash
kubectl tcp-tunnel edit-config
```

### Show Help

```bash
kubectl tcp-tunnel --help
```

### Show Version

```bash
kubectl tcp-tunnel --version
```

### Upgrade

```bash
kubectl tcp-tunnel upgrade
```

Upgrades to the latest version from GitHub. Your configuration will be preserved.

### Uninstall

```bash
kubectl tcp-tunnel uninstall
```

Uninstalls kubectl-tcp-tunnel. You'll be prompted whether to remove configuration files.

## Examples

### Connect to PostgreSQL

```bash
# Terminal 1: Create tunnel (short form)
kubectl tcp-tunnel -e staging -c user-db

# Terminal 2: Connect with psql
psql -h localhost -p 15432 -U myuser mydatabase
```

### Connect to MySQL

```bash
# Terminal 1: Create tunnel (short form)
kubectl tcp-tunnel -e staging -c order-db

# Terminal 2: Connect with mysql
mysql -h localhost -P 13306 -u myuser mydatabase
```

### Connect to Redis

```bash
# Terminal 1: Create tunnel (short form)
kubectl tcp-tunnel -e staging -c cache

# Terminal 2: Connect with redis-cli
redis-cli -h localhost -p 16379
```

### Connect to MongoDB

```bash
# Terminal 1: Create tunnel (short form)
kubectl tcp-tunnel -e staging -c mongo-db

# Terminal 2: Connect with mongosh
mongosh "mongodb://localhost:17017/mydatabase"
```

### Connect with GUI Tools

**TablePlus / Postico / pgAdmin:**

1. Create the tunnel:
   ```bash
   kubectl tcp-tunnel --env production --connection user-db
   ```

2. Configure your GUI tool:
   - Host: `localhost`
   - Port: `5432`
   - User: your database username
   - Password: your database password
   - Database: your database name

### Run a Query Script

```bash
# Terminal 1: Create tunnel
kubectl tcp-tunnel --env staging --connection user-db

# Terminal 2: Run script
psql -h localhost -p 5432 -U myuser -d mydatabase -f query.sql
```

### Use with pg_dump

```bash
# Terminal 1: Create tunnel
kubectl tcp-tunnel --env production --connection user-db

# Terminal 2: Dump database
pg_dump -h localhost -p 5432 -U myuser mydatabase > backup.sql
```

### Multiple Databases Simultaneously

```bash
# Terminal 1: Connect to user database on default port
kubectl tcp-tunnel --env staging --connection user-db

# Terminal 2: Connect to order database on different port
kubectl tcp-tunnel --env staging --connection order-db --local-port 5433

# Terminal 3: Connect to both
psql -h localhost -p 5432 -U user1 userdb    # user-db
psql -h localhost -p 5433 -U user2 orderdb   # order-db
```

## How It Works

### Architecture

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│              │         │   Kubernetes    │         │              │
│  Your Local  │────────▶│    Cluster      │────────▶│  PostgreSQL  │
│   Machine    │  Port   │   (Jump Pod)    │  Network│   Database   │
│              │  Forward│                 │  Access │              │
└──────────────┘         └─────────────────┘         └──────────────┘
   localhost:5432         alpine/socat pod           remote-db:5432
```

### Process Flow

1. **Context Switching**: Plugin uses `kubectx` to switch to the correct Kubernetes context
2. **Jump Pod Creation**: Creates a temporary pod running alpine/socat in your cluster
3. **Socat Relay**: Inside the jump pod, socat listens on port 5432 and forwards to remote database
4. **Port Forwarding**: kubectl port-forward tunnels localhost:5432 to jump pod
5. **Database Connection**: You connect with any PostgreSQL client to localhost:5432
6. **Cleanup**: When you disconnect (Ctrl+C), the jump pod is automatically deleted

### Security

- **No direct exposure**: Database never exposed to the internet
- **Temporary access**: Jump pods exist only during your session
- **Context isolation**: Explicit context switching prevents accidental production access
- **Network policies**: Jump pods respect your cluster's network policies
- **Audit trail**: Jump pod creation/deletion logged in Kubernetes audit logs

### Resource Usage

Jump pods are minimal:
- Image size: ~8MB (alpine/socat)
- Memory: ~10MB
- CPU: negligible
- Network: only PostgreSQL traffic

## Migration Guide

### Upgrading from v1.x to v2.0

Version 2.0 introduces a **breaking change** to support generic TCP connections. The configuration format has changed from a flat `databases:` map to a structured `connections:` format with YAML anchors for connection types.

#### Old Configuration (v1.x)

```yaml
settings:
  local-port: 5432
  db-port: 5432

environments:
  staging:
    k8s-context: staging-cluster
    databases:
      user-db: user-db.staging.example.com
      order-db: order-db.staging.example.com
```

#### New Configuration (v2.0)

```yaml
settings:
  postgres: &postgres
    local-port: 15432
    db-port: 5432

  mysql: &mysql
    local-port: 13306
    db-port: 3306

environments:
  staging:
    k8s-context: staging-cluster
    connections:
      user-db:
        host: user-db.staging.example.com
        type: *postgres
      order-db:
        host: order-db.staging.example.com
        type: *mysql
```

#### Migration Steps

1. **Backup your current config:**
   ```bash
   cp ~/.config/kubectl-tcp-tunnel/config.yaml ~/.config/kubectl-tcp-tunnel/config.yaml.backup
   ```

2. **Define connection types in settings:**
   ```yaml
   settings:
     postgres: &postgres
       local-port: 15432
       db-port: 5432
   ```

3. **Rename `databases:` to `connections:`:**
   ```yaml
   # Old:
   databases:

   # New:
   connections:
   ```

4. **Convert each database entry:**
   ```yaml
   # Old:
   user-db: user-db.example.com

   # New:
   user-db:
     host: user-db.example.com
     type: *postgres
   ```

5. **Test your configuration:**
   ```bash
   kubectl tcp-tunnel ls
   ```

#### Port Changes

Note that default ports have changed to avoid conflicts:
- PostgreSQL: 5432 → 15432
- MySQL: 3306 → 13306
- Redis: 6379 → 16379
- MongoDB: 27017 → 17017

You can override these with `--local-port` flag or modify the connection type definitions.

## Troubleshooting

### Pod Won't Start

**Problem**: Jump pod fails to become ready

**Solutions**:
- Check pod logs: `kubectl logs pg-jump-<name> -n <namespace>`
- Verify image pull: `kubectl describe pod pg-jump-<name> -n <namespace>`
- Check resource quotas in the namespace
- Increase `jump-pod-wait-timeout` in config

### Can't Connect to Database

**Problem**: Tunnel is established but connection fails

**Solutions**:
- Verify the database host is correct in your config
- Check network connectivity from within the cluster:
  ```bash
  kubectl run -it --rm debug --image=alpine/socat --restart=Never -- sh
  # Inside pod: nc -zv your-db-host 5432
  ```
- Check database firewall rules allow connections from cluster
- Verify database credentials

### Context Switch Fails

**Problem**: `kubectx` fails to switch context

**Solutions**:
- List available contexts: `kubectl config get-contexts`
- Verify context name in config matches exactly
- Check kubectl authentication is valid
- Try switching manually: `kubectx <context-name>`

### Port Already in Use

**Problem**: Local port 5432 is already in use

**Solutions**:
- Change `local-port` in config to a different port (e.g., `5433`)
- Or use `--local-port` flag: `kubectl tcp-tunnel --env staging --connection user-db --local-port 5433`
- Or stop other PostgreSQL services on your local machine
- Check what's using the port: `lsof -i :5432` (macOS/Linux)

### Permission Denied

**Problem**: Can't create pods in namespace

**Solutions**:
- Verify your service account has permission to create/delete pods
- Check RBAC policies in the namespace
- Contact your cluster administrator

### Jump Pod Already Exists

**Problem**: Error that jump pod already exists

**The plugin automatically handles this** - it will delete the existing pod and create a new one. If this fails:

```bash
# Manually delete the pod
kubectl delete pod pg-jump-<name> -n <namespace> --grace-period=0
```

### yq Not Found

**Problem**: Plugin reports "yq is required but not installed"

**Solutions**:
```bash
# macOS
brew install yq

# Ubuntu/Debian
sudo apt-get install yq

# Or see: https://github.com/mikefarah/yq#install
```

### Configuration File Not Found

**Problem**: "Configuration file not found"

**Solutions**:
```bash
# Create configuration
kubectl tcp-tunnel edit-config

# Or copy example
cp config/config.yaml.example ~/.config/kubectl-tcp-tunnel/config.yaml
$EDITOR ~/.config/kubectl-tcp-tunnel/config.yaml
```

### Invalid YAML Syntax

**Problem**: "Invalid YAML syntax in config file"

**Solutions**:
- Check your YAML indentation (use 2 spaces, not tabs)
- Validate YAML syntax: `yq eval '.' ~/.config/kubectl-tcp-tunnel/config.yaml`
- Copy from example and modify: `config/config.yaml.example`

## Safety Notes

### Production Access

- **Double-check context**: Always verify you're in the correct Kubernetes context
- **Use read-only users**: When possible, connect with read-only database users
- **Use replicas for queries**: Use replica databases for analytics and read-heavy operations
- **Monitor connections**: Be aware that your connection goes through the cluster network

### Context Switching Warnings

The plugin explicitly switches Kubernetes contexts using kubectx. This is intentional to:
- Make context switches explicit and visible
- Prevent accidental operations in the wrong environment
- Follow the principle of least surprise

Your kubectl context will remain switched after the tunnel closes. Always verify your context:

```bash
kubectl config current-context
```

### Network Policies

If your cluster uses network policies, ensure:
- Jump pods can be created in your namespace
- Jump pods can reach your database hosts
- Your database hosts accept connections from the cluster network

## Environment Variables

### TCP_TUNNEL_CONFIG

Override the default config file location:

```bash
export TCP_TUNNEL_CONFIG=/path/to/custom/config.yaml
kubectl tcp-tunnel --env staging --connection user-db
```

## Tips and Best Practices

### Use Aliases

Create shell aliases for frequently used databases:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias pg-staging-user='kubectl tcp-tunnel --env staging --connection user-db'
alias pg-prod-user='kubectl tcp-tunnel --env production --connection user-db'
alias pg-prod-order='kubectl tcp-tunnel --env production --connection order-db'
```

### Use Different Ports for Different Environments

Avoid conflicts by using different local ports:

```yaml
environments:
  staging:
    k8s-context: staging
    databases:
      user-db: user-db.staging.example.com
  # Use default port 5432

# Connect to staging
kubectl tcp-tunnel --env staging --connection user-db --local-port 5432

# Connect to production simultaneously
kubectl tcp-tunnel --env production --connection user-db --local-port 5433
```

### Keep Tunnels Alive

Use `tmux` or `screen` to keep tunnels alive:

```bash
# Start tmux session
tmux new -s tcp-tunnel

# Create tunnel
kubectl tcp-tunnel --env staging --connection user-db

# Detach: Ctrl+B then D
# Reattach: tmux attach -t tcp-tunnel
```

### Connection Strings

Create connection strings for easy use:

```bash
# PostgreSQL connection string
postgresql://username:password@localhost:5432/database

# With pg_dump
pg_dump "postgresql://user@localhost:5432/db" > backup.sql
```

## Additional Resources

- [Installation Guide](INSTALLATION.md) - How to install kubectl-tcp-tunnel
- [Development Guide](DEVELOPMENT.md) - Contributing and development setup
- [Contributing Guidelines](../CONTRIBUTING.md) - How to contribute
- [GitHub Issues](https://github.com/sgyyz/kubectl-tcp-tunnel/issues) - Report bugs or request features
