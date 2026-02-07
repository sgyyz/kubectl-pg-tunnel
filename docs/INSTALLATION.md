# Installation Guide

Complete guide for installing kubectl-pg-tunnel.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Verification](#verification)
- [Uninstallation](#uninstallation)

## Requirements

### System Requirements

- **Operating System**: macOS or Linux
- **Shell**: Bash 4.0+

### Required Dependencies

The following tools must be installed before using kubectl-pg-tunnel:

| Tool | Purpose | Minimum Version |
|------|---------|-----------------|
| **kubectl** | Kubernetes command-line tool | v1.20+ |
| **kubectx** | Fast context switching for kubectl | Any recent version |
| **yq** | YAML processor for parsing config files | v4.0+ |

### Kubernetes Requirements

- **Cluster Access**: Valid kubectl configuration with access to your cluster(s)
- **Permissions**: Ability to create and delete pods in your target namespace
- **Network Access**: Jump pods must be able to reach PostgreSQL hosts from within the cluster

## Installation

### Method 1: Quick Install (Recommended)

Download and run the installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/sgyyz/kubectl-pg-tunnel/main/install.sh | bash
```

This will:
- Download the plugin directly from GitHub
- Install it to your kubectl plugins directory
- Set up the configuration directory
- Download the example configuration file

### Method 2: Manual Installation

#### Step 1: Install Dependencies

**macOS:**
```bash
brew install kubectl kubectx yq
```

**Ubuntu/Debian:**
```bash
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kubectx
sudo apt-get install -y kubectx

# yq
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

**Fedora:**
```bash
sudo dnf install -y kubectl kubectx yq
```

#### Step 2: Clone Repository

```bash
git clone https://github.com/sgyyz/kubectl-pg-tunnel.git
cd kubectl-pg-tunnel
```

#### Step 3: Run Installer

```bash
./install.sh
```

The installer will:
1. Check for required dependencies
2. Determine the appropriate installation directory
3. Copy the plugin to your PATH
4. Create configuration directory
5. Copy example configuration file
6. Verify the installation

### Installation Directories

The plugin will be installed to one of these locations (in order of preference):

1. `~/.krew/bin/` - If you have krew installed
2. `~/.local/bin/` - Standard user local binaries
3. `/usr/local/bin/` - System-wide installation (requires sudo)

The installer will automatically choose the first available directory that is writable.

### Add to PATH (if needed)

If the installation directory is not in your PATH, add it to your shell profile:

```bash
# For bash (~/.bashrc)
echo 'export PATH="${PATH}:${HOME}/.local/bin"' >> ~/.bashrc
source ~/.bashrc

# For zsh (~/.zshrc)
echo 'export PATH="${PATH}:${HOME}/.local/bin"' >> ~/.zshrc
source ~/.zshrc
```

## Configuration

### Create Configuration File

The installer creates an example configuration at:
```
~/.config/kubectl-pg-tunnel/config.yaml
```

### Edit Configuration

```bash
kubectl pg-tunnel edit-config
```

Or manually:

```bash
$EDITOR ~/.config/kubectl-pg-tunnel/config.yaml
```

### Basic Configuration

Update the following settings:

```yaml
settings:
  # Your Kubernetes namespace where jump pods will be created
  namespace: default

  # Leave these as defaults unless you have specific needs
  jump-pod-image: alpine/socat:latest
  jump-pod-wait-timeout: 60
  local-port: 5432
  db-port: 5432

environments:
  # Update with your actual Kubernetes context name
  staging:
    k8s-context: my-staging-cluster  # Change this!
    databases:
      user-db: user-db.staging.example.com  # Change this!
      order-db: order-db.staging.example.com  # Change this!

  production:
    k8s-context: my-production-cluster  # Change this!
    databases:
      user-db: user-db.prod.example.com  # Change this!
      order-db: order-db.prod.example.com  # Change this!
```

### Get Your Kubernetes Context Names

```bash
# List all available contexts
kubectl config get-contexts

# Or use kubectx
kubectx
```

Use the context names from the output in your configuration.

### Configuration Tips

1. **Namespace**: Use a namespace where you have permissions to create/delete pods
2. **Context Names**: Must exactly match your kubectl context names
3. **Database Hosts**: Must be accessible from within your Kubernetes cluster
4. **Multiple Environments**: Add as many environments as needed
5. **Database Aliases**: Use descriptive names (e.g., `user-db`, `order-db`, `analytics-db`)

### Example Configuration

Here's a complete example:

```yaml
settings:
  namespace: infrastructure
  jump-pod-image: alpine/socat:latest
  jump-pod-wait-timeout: 60
  local-port: 5432
  db-port: 5432

environments:
  dev:
    k8s-context: dev-cluster-us-west
    databases:
      main: postgres.dev.internal.company.com

  staging:
    k8s-context: staging-cluster-us-west
    databases:
      user-db: user-db.staging.internal.company.com
      order-db: order-db.staging.internal.company.com
      analytics: analytics.staging.internal.company.com

  production:
    k8s-context: prod-cluster-us-west
    databases:
      user-db: user-db.prod.internal.company.com
      order-db: order-db.prod.internal.company.com
      analytics-replica: analytics-replica.prod.internal.company.com

  production-eu:
    k8s-context: prod-cluster-eu-central
    databases:
      user-db: user-db.prod-eu.internal.company.com
      order-db: order-db.prod-eu.internal.company.com
```

## Verification

### Verify Installation

```bash
# Check if plugin is accessible
kubectl pg-tunnel --version

# Should output: kubectl pg-tunnel version 1.0.0
```

### Verify Dependencies

```bash
# Check kubectl
kubectl version --client

# Check kubectx
kubectx --version

# Check yq
yq --version
```

### Verify Configuration

```bash
# List configured environments and databases
kubectl pg-tunnel ls

# Should display your configured environments
```

### Test Connection (Optional)

If you have a test database accessible from your cluster:

```bash
# Create a tunnel
kubectl pg-tunnel --env staging --db user-db

# In another terminal, test connection
psql -h localhost -p 5432 -U your-username your-database
```

Press Ctrl+C in the first terminal to stop the tunnel.

## Uninstallation

### Quick Uninstall

```bash
# If installed from the repository
cd kubectl-pg-tunnel
./uninstall.sh
```

### Manual Uninstall

```bash
# Remove the plugin
rm -f ~/.local/bin/kubectl-pg_tunnel
# Or if installed elsewhere:
# rm -f ~/.krew/bin/kubectl-pg_tunnel
# sudo rm -f /usr/local/bin/kubectl-pg_tunnel

# Optionally remove configuration
rm -rf ~/.config/kubectl-pg-tunnel
```

### Uninstall Options

The uninstall script will prompt you to:
1. Remove the plugin binary
2. Remove configuration directory (optional)
3. Clean up any running jump pods (optional)

## Troubleshooting Installation

### "kubectl not found"

Install kubectl:
```bash
# macOS
brew install kubectl

# Linux
# See https://kubernetes.io/docs/tasks/tools/
```

### "kubectx not found"

Install kubectx:
```bash
# macOS
brew install kubectx

# Linux
# See https://github.com/ahmetb/kubectx#installation
```

### "yq not found"

Install yq:
```bash
# macOS
brew install yq

# Linux
# See https://github.com/mikefarah/yq#install
```

### "Plugin not found" after installation

Check your PATH:
```bash
# Show current PATH
echo $PATH

# Find where plugin was installed
which kubectl-pg_tunnel

# Add to PATH if needed (example for ~/.local/bin)
echo 'export PATH="${PATH}:${HOME}/.local/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Permission Denied

If you get permission errors during installation:

```bash
# Make install script executable
chmod +x install.sh

# Run installer
./install.sh

# If installing to /usr/local/bin, you may need sudo
sudo ./install.sh
```

### Installation Directory Not in PATH

If the installer reports the directory is not in your PATH:

```bash
# Add the directory to your shell profile
# Replace ~/.local/bin with the actual directory

# For bash
echo 'export PATH="${PATH}:${HOME}/.local/bin"' >> ~/.bashrc
source ~/.bashrc

# For zsh
echo 'export PATH="${PATH}:${HOME}/.local/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify
echo $PATH | grep -q ".local/bin" && echo "✓ In PATH"
```

## Upgrading

### Upgrade to Latest Version

```bash
# Pull latest changes
cd kubectl-pg-tunnel
git pull origin main

# Run installer (will overwrite existing installation)
./install.sh
```

The installer will:
- Backup your existing installation
- Install the new version
- Preserve your configuration file

### Check for Updates

```bash
# Check current version
kubectl pg-tunnel --version

# Check latest version on GitHub
# Visit: https://github.com/sgyyz/kubectl-pg-tunnel/releases
```

## Post-Installation

### Next Steps

1. **Configure**: Edit `~/.config/kubectl-pg-tunnel/config.yaml` with your settings
2. **Verify**: Run `kubectl pg-tunnel ls` to see your environments
3. **Test**: Create a test tunnel to verify everything works
4. **Learn**: See [USAGE.md](USAGE.md) for detailed usage instructions

### Recommended Setup

```bash
# Create useful shell aliases
echo 'alias pg-staging="kubectl pg-tunnel --env staging --db user-db"' >> ~/.bashrc
echo 'alias pg-prod="kubectl pg-tunnel --env production --db user-db"' >> ~/.bashrc
source ~/.bashrc
```

## Additional Resources

- [Usage Guide](USAGE.md) - How to use kubectl-pg-tunnel
- [Development Guide](DEVELOPMENT.md) - Contributing and development setup
- [GitHub Repository](https://github.com/sgyyz/kubectl-pg-tunnel)
- [Report Issues](https://github.com/sgyyz/kubectl-pg-tunnel/issues)
