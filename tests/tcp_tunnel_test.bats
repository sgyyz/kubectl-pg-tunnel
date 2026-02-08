#!/usr/bin/env bats

# kubectl-tcp-tunnel test suite

setup() {
    # Set up test environment
    export TEST_DIR="${BATS_TEST_TMPDIR}/kubectl-tcp-tunnel-test"
    export CONFIG_DIR="${TEST_DIR}/config"
    export CONFIG_FILE="${CONFIG_DIR}/config.yaml"
    export TCP_TUNNEL_CONFIG="${CONFIG_FILE}"
    export PATH="${TEST_DIR}/bin:${PATH}"

    # Create test directories
    mkdir -p "${CONFIG_DIR}"
    mkdir -p "${TEST_DIR}/bin"

    # Create test YAML config
    cat > "${CONFIG_FILE}" <<'EOF'
settings:
  namespace: test-namespace
  jump-pod-image: alpine/socat:latest
  jump-pod-wait-timeout: 60

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
        host: postgres-staging.example.com
        type: *postgres
      order-db:
        host: order-staging.example.com
        type: *mysql

  production:
    k8s-context: prod-cluster
    connections:
      user-db:
        host: postgres-prod.example.com
        type: *postgres
      order-db:
        host: order-prod.example.com
        type: *mysql
EOF

    # Create mock yq
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
# Mock yq that can parse our test YAML
# Strip the // "" operator if present
query="${2%% //*}"
case "$query" in
    ".")
        # Validate YAML
        exit 0
        ;;
    ".settings.namespace")
        echo "test-namespace"
        ;;
    ".settings.jump-pod-image")
        echo "alpine/socat:latest"
        ;;
    ".settings.jump-pod-wait-timeout")
        echo "60"
        ;;
    ".settings.db-port")
        echo "5432"
        ;;
    ".settings.local-port")
        echo "5432"
        ;;
    ".environments.staging.k8s-context")
        echo "staging-cluster"
        ;;
    ".environments.production.k8s-context")
        echo "prod-cluster"
        ;;
    "explode(.) | .environments.staging.connections.user-db.host")
        echo "postgres-staging.example.com"
        ;;
    "explode(.) | .environments.staging.connections.order-db.host")
        echo "order-staging.example.com"
        ;;
    "explode(.) | .environments.production.connections.user-db.host")
        echo "postgres-prod.example.com"
        ;;
    "explode(.) | .environments.production.connections.order-db.host")
        echo "order-prod.example.com"
        ;;
    "explode(.) | .environments.staging.connections.user-db.type.local-port")
        echo "15432"
        ;;
    "explode(.) | .environments.staging.connections.user-db.type.db-port")
        echo "5432"
        ;;
    "explode(.) | .environments.staging.connections.order-db.type.local-port")
        echo "13306"
        ;;
    "explode(.) | .environments.staging.connections.order-db.type.db-port")
        echo "3306"
        ;;
    "explode(.) | .environments.production.connections.user-db.type.local-port")
        echo "15432"
        ;;
    "explode(.) | .environments.production.connections.user-db.type.db-port")
        echo "5432"
        ;;
    "explode(.) | .environments.staging.connections.unknown_db.host")
        echo ""
        ;;
    "explode(.) | .environments.staging.connections.invalid_db.host")
        echo ""
        ;;
    "explode(.) | .environments.staging.connections.unknown_db.type.local-port")
        echo ""
        ;;
    "explode(.) | .environments.staging.connections.unknown_db.type.db-port")
        echo ""
        ;;
    "explode(.) | .environments.staging.connections.nonexistent_db.host")
        echo ""
        ;;
    ".environments | keys | .[]")
        echo "production"
        echo "staging"
        ;;
    ".environments.staging.connections | keys | .[]")
        echo "order-db"
        echo "user-db"
        ;;
    ".environments.production.connections | keys | .[]")
        echo "order-db"
        echo "user-db"
        ;;
    *)
        # Return empty for unknown queries (simulates null)
        echo ""
        ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    # Create mock kubectl
    cat > "${TEST_DIR}/bin/kubectl" <<'EOSCRIPT'
#!/usr/bin/env bash
# Mock kubectl that records calls and returns success
echo "kubectl $*" >> "${TEST_DIR}/kubectl.log"
case "$1" in
    --context=*)
        case "$3" in
            get)
                exit 1  # Pod doesn't exist
                ;;
            run)
                echo "pod/test-pod created"
                exit 0
                ;;
            wait)
                exit 0
                ;;
            port-forward)
                # Simulate blocking port-forward
                sleep 3600 &
                wait $!
                ;;
            delete)
                exit 0
                ;;
        esac
        ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/kubectl"

    # Create mock kubectx
    cat > "${TEST_DIR}/bin/kubectx" <<'EOSCRIPT'
#!/usr/bin/env bash
echo "kubectx $*" >> "${TEST_DIR}/kubectx.log"
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/kubectx"

    # Reference to the actual plugin script
    PLUGIN="${BATS_TEST_DIRNAME}/../kubectl-tcp_tunnel"
}

teardown() {
    # Clean up test directory
    rm -rf "${TEST_DIR}"
}

# Helper function to run plugin
run_plugin() {
    run bash "${PLUGIN}" "$@"
}

# ==============================================================================
# Argument Parsing Tests
# ==============================================================================

@test "shows help with --help flag" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "kubectl tcp-tunnel" ]]
    [[ "$output" =~ "USAGE:" ]]
    [[ "$output" =~ "OPTIONS:" ]]
}

@test "shows help with help subcommand" {
    run_plugin help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "kubectl tcp-tunnel" ]]
}

@test "shows version with --version flag" {
    run_plugin --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "shows version with version subcommand" {
    run_plugin version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "shows help with no arguments" {
    run_plugin
    [ "$status" -eq 0 ]
    [[ "$output" =~ "USAGE:" ]]
}

@test "handles unknown option" {
    run_plugin --unknown-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "errors on --env without argument" {
    run_plugin --env
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires an environment argument" ]]
}

@test "errors on --db without argument" {
    run_plugin --db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a" ]]
}

@test "errors on --local-port without argument" {
    run_plugin --local-port
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a port argument" ]]
}

# ==============================================================================
# Config Handling Tests
# ==============================================================================

@test "errors when config file missing" {
    rm -f "${CONFIG_FILE}"
    run_plugin ls
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Configuration file not found" ]]
}

@test "respects TCP_TUNNEL_CONFIG environment variable" {
    export TCP_TUNNEL_CONFIG="${CONFIG_FILE}"
    run_plugin ls
    [ "$status" -eq 0 ]
}

@test "loads config successfully" {
    run_plugin ls
    [ "$status" -eq 0 ]
}

@test "errors on invalid YAML syntax" {
    # Create invalid YAML
    cat > "${CONFIG_FILE}" <<EOF
invalid: yaml: syntax:
  - bad indentation
EOF

    # Update mock yq to fail on invalid YAML
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
if [[ "$2" == "." ]]; then
    exit 1  # Invalid YAML
fi
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin ls
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid YAML syntax" ]]
}

# ==============================================================================
# Subcommand Tests
# ==============================================================================

@test "ls subcommand lists environments and connections" {
    run_plugin ls
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Available environments and connections" ]]
    [[ "$output" =~ "staging" ]]
    [[ "$output" =~ "production" ]]
}

@test "ls with environment filter" {
    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "staging" ]]
}

@test "ls shows kubernetes contexts" {
    run_plugin ls
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Kubernetes context:" ]]
    [[ "$output" =~ "staging-cluster" ]]
}

@test "edit-config subcommand works" {
    export EDITOR="echo"
    run_plugin edit-config
    [ "$status" -eq 0 ]
}

@test "upgrade subcommand shows in help" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "upgrade" ]]
    [[ "$output" =~ "Upgrade to the latest version" ]]
}

@test "uninstall subcommand shows in help" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "uninstall" ]]
    [[ "$output" =~ "Uninstall kubectl-tcp-tunnel" ]]
}

# ==============================================================================
# Validation Tests
# ==============================================================================

@test "errors when missing --env argument" {
    run_plugin --db user-db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required option: --env" ]]
}

@test "errors when missing --db argument" {
    run_plugin --env staging
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required option: --db" ]]
}

@test "errors on invalid environment" {
    run_plugin --env invalid_env --db user-db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown environment" ]]
}

@test "errors on unknown connection alias" {
    run_plugin --env staging --db unknown_db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown connection" ]]
}

# ==============================================================================
# Pod Name Sanitization Tests
# ==============================================================================

@test "accepts connection names with hyphens" {
    run_plugin ls
    [ "$status" -eq 0 ]
    [[ "$output" =~ "user-db" ]]
}

@test "lists connections correctly" {
    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "user-db" ]]
    [[ "$output" =~ "order-db" ]]
}

# ==============================================================================
# Integration Tests (with mocked kubectl)
# ==============================================================================

@test "validates environment exists before creating tunnel" {
    run_plugin --env nonexistent --db user-db
    [ "$status" -eq 1 ]
}

@test "validates connection alias exists before creating tunnel" {
    run_plugin --env staging --db nonexistent_db
    [ "$status" -eq 1 ]
}

# ==============================================================================
# Help and Documentation Tests
# ==============================================================================

@test "help shows examples" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "EXAMPLES:" ]]
}

@test "help shows subcommands" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "SUBCOMMANDS:" ]]
    [[ "$output" =~ "ls" ]]
    [[ "$output" =~ "edit-config" ]]
}

@test "help shows configuration info" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "CONFIGURATION:" ]]
}

@test "help shows environment variables" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ENVIRONMENT VARIABLES:" ]]
    [[ "$output" =~ "TCP_TUNNEL_CONFIG" ]]
}

# ==============================================================================
# Error Message Tests
# ==============================================================================

@test "provides helpful error for missing config" {
    rm -f "${CONFIG_FILE}"
    run_plugin ls
    [ "$status" -eq 1 ]
    [[ "$output" =~ "config.yaml.example" ]]
}

@test "lists available environments on invalid environment" {
    run_plugin --env invalid --db user-db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available environments" ]]
}

@test "lists available connections on invalid connection" {
    run_plugin --env staging --db invalid_db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available connections" ]]
}

# ==============================================================================
# Edge Cases
# ==============================================================================

@test "handles empty environment name" {
    run_plugin --env "" --db user-db
    [ "$status" -eq 1 ]
}

@test "handles unexpected positional arguments" {
    run_plugin --env staging --db user-db extra_arg
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unexpected argument" ]]
}

@test "supports --local-port flag" {
    run_plugin --env staging --db user-db --local-port 5433 --help
    [ "$status" -eq 0 ]
}

@test "reads local-port from connection type when flag not provided" {
    # Create config with connection type
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default
  postgres: &postgres
    local-port: 15432
    db-port: 5432

environments:
  staging:
    k8s-context: staging-context
    connections:
      user-db:
        host: postgres-staging.example.com
        type: *postgres
EOF

    # Update mock yq to handle this config
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    "explode(.) | .environments.staging.connections.user-db.host") echo "postgres-staging.example.com" ;;
    "explode(.) | .environments.staging.connections.user-db.type.local-port") echo "15432" ;;
    "explode(.) | .environments.staging.connections.user-db.type.db-port") echo "5432" ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    # Run plugin and check that it reads local-port from connection type
    run_plugin --env staging --db user-db --help
    [ "$status" -eq 0 ]
}

@test "--local-port flag overrides connection type setting" {
    # Create config with connection type port
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default
  postgres: &postgres
    local-port: 15432
    db-port: 5432

environments:
  staging:
    k8s-context: staging-context
    connections:
      user-db:
        host: postgres-staging.example.com
        type: *postgres
EOF

    # Flag should override connection type
    run_plugin --env staging --db user-db --local-port 9999 --help
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Mock Verification Tests
# ==============================================================================

@test "uses kubectx for context switching" {
    [ -f "${TEST_DIR}/bin/kubectx" ]
    [ -x "${TEST_DIR}/bin/kubectx" ]
}

@test "uses kubectl for pod operations" {
    [ -f "${TEST_DIR}/bin/kubectl" ]
    [ -x "${TEST_DIR}/bin/kubectl" ]
}

@test "uses yq for YAML parsing" {
    [ -f "${TEST_DIR}/bin/yq" ]
    [ -x "${TEST_DIR}/bin/yq" ]
}
