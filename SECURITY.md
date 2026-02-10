# Security Policy

## Supported Versions

We release patches for security vulnerabilities. The following versions are
currently being supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 2.1.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

The kubectl-tcp-tunnel team takes security bugs seriously. We appreciate your
efforts to responsibly disclose your findings, and will make every effort to
acknowledge your contributions.

### How to Report a Security Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via GitHub's Security Advisories feature:

1. Go to the [Security tab](https://github.com/sgyyz/kubectl-tcp-tunnel/security) of this repository
2. Click "Report a vulnerability"
3. Fill out the advisory form with details about the vulnerability

Alternatively, you can send an email to the maintainers describing the issue.

### What to Include

Please include the following information in your report:

* Type of issue (e.g., command injection, privilege escalation, credential exposure)
* Full paths of source file(s) related to the manifestation of the issue
* The location of the affected source code (tag/branch/commit or direct URL)
* Any special configuration required to reproduce the issue
* Step-by-step instructions to reproduce the issue
* Proof-of-concept or exploit code (if possible)
* Impact of the issue, including how an attacker might exploit it

### What to Expect

After you submit a report:

* You will receive an acknowledgment within 48 hours
* We will investigate and validate the issue
* We will work with you to understand the scope and severity
* We will develop and test a fix
* We will release a security advisory and patched version
* We will credit you for the discovery (unless you prefer to remain anonymous)

## Security Considerations for Users

### Network Security

* kubectl-tcp-tunnel creates network tunnels through Kubernetes clusters
* Ensure your Kubernetes cluster has appropriate network policies in place
* Jump pods have network access within the cluster - ensure proper RBAC configuration
* Never expose sensitive services without proper authentication

### Access Control

* The plugin requires `kubectl` access to create pods and port-forwards
* Ensure users have appropriate RBAC permissions:
  * `pods/create` - to create jump pods
  * `pods/delete` - to clean up jump pods
  * `pods/portforward` - to establish tunnels
* Follow principle of least privilege when granting cluster access

### Configuration Security

* Configuration files may contain sensitive information (hostnames, ports)
* Default config location: `~/.config/kubectl-tcp-tunnel/config.yaml`
* Ensure config files have appropriate permissions: `chmod 600 config.yaml`
* Never commit configuration files with production credentials to version control
* Use environment variables (`TCP_TUNNEL_CONFIG`) for CI/CD environments

### Container Image Security

* The plugin uses `alpine/socat:latest` for jump pods
* This is a minimal, official Alpine Linux image
* Consider using a specific version tag instead of `latest` for production
* Scan the socat image for vulnerabilities in your environment
* Use private registries if required by your security policies

### Command Injection Risks

* The plugin executes shell commands (`kubectl`, `kubectx`, `yq`)
* Input validation is performed on user-provided values
* Configuration values are properly quoted to prevent injection
* If you find a potential injection vector, please report it immediately

### Credential Handling

* kubectl-tcp-tunnel does not store or transmit credentials
* It relies on existing kubectl authentication (kubeconfig)
* Protect your kubeconfig file with appropriate permissions
* Use short-lived tokens or certificate-based authentication when possible

### Jump Pod Lifecycle

* Jump pods remain running after tunnel disconnect (for reuse)
* Use `kubectl tcp-tunnel cleanup` to manually delete pods
* Use `--cleanup` flag to automatically delete pods on exit
* Audit running jump pods regularly in production environments
* Jump pods consume cluster resources - monitor and clean up as needed

## Known Limitations

### Not Suitable For

* Production workload tunneling (use proper Service/Ingress objects)
* High-security environments requiring audit trails
* Bypassing network policies for unauthorized access

### Best Practices

* Use kubectl-tcp-tunnel for development and debugging only
* Implement proper network segmentation in your cluster
* Use dedicated namespaces for jump pods
* Rotate kubeconfig credentials regularly
* Monitor cluster for unexpected tunnel pods
* Use cluster admission controllers to restrict pod creation if needed

## Security Updates

Security updates will be released as patch versions and announced via:

* GitHub Security Advisories
* Release notes in the repository
* Git tags following semantic versioning

Subscribe to repository releases to stay informed about security updates.
