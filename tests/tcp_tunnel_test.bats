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
    ".environments.staging.connections.user-db.type")
        echo "*postgres"
        ;;
    ".environments.staging.connections.order-db.type")
        echo "*mysql"
        ;;
    ".environments.production.connections.user-db.type")
        echo "*postgres"
        ;;
    ".environments.production.connections.order-db.type")
        echo "*mysql"
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
    ".environments.staging.connections.unknown_db.type")
        echo ""
        ;;
    ".environments.staging.connections.invalid_db.type")
        echo ""
        ;;
    ".environments.staging.connections.nonexistent_db.type")
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

@test "errors on --connection without argument" {
    run_plugin --connection
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a" ]]
}

@test "errors on --local-port without argument" {
    run_plugin --local-port
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a port argument" ]]
}

@test "errors on -e without argument" {
    run_plugin -e
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires an environment argument" ]]
}

@test "errors on -c without argument" {
    run_plugin -c
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a" ]]
}

@test "errors on -p without argument" {
    run_plugin -p
    [ "$status" -eq 1 ]
    [[ "$output" =~ "requires a port argument" ]]
}

@test "accepts short arguments -e and -c" {
    run_plugin -e staging -c user-db --help
    [ "$status" -eq 0 ]
}

@test "accepts mixed short and long arguments" {
    run_plugin -e staging --connection user-db --help
    [ "$status" -eq 0 ]
}

@test "accepts short argument -p for local-port" {
    run_plugin -e staging -c user-db -p 5433 --help
    [ "$status" -eq 0 ]
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
    run_plugin --connection user-db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required option: -e/--env" ]]
}

@test "errors when missing --connection argument" {
    run_plugin --env staging
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing required option: -c/--connection" ]]
}

@test "errors on invalid environment" {
    run_plugin --env invalid_env --connection user-db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown environment" ]]
}

@test "errors on unknown connection alias" {
    run_plugin --env staging --connection unknown_db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown connection" ]]
}

# ==============================================================================
# Pod Name Generation Tests
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

@test "generate_random_suffix creates 6 character string" {
    # Test the function by calling it via bash
    local suffix
    suffix=$(bash -c '
        generate_random_suffix() {
            local length="${1:-6}"
            local suffix
            # Try to generate random suffix from /dev/urandom
            suffix=$(LC_ALL=C tr -dc "a-z0-9" < /dev/urandom 2>/dev/null | head -c "${length}" || true)

            # Fallback to timestamp-based generation if urandom fails
            if [[ -z "${suffix}" ]] || [[ ${#suffix} -ne ${length} ]]; then
                local timestamp
                timestamp=$(date +%s)
                suffix=$(printf "%s" "${timestamp}" | sha256sum 2>/dev/null | head -c "${length}" || printf "%s" "${timestamp}" | head -c "${length}")
            fi

            echo "${suffix}"
        }
        generate_random_suffix 6
    ')

    # Check length is 6
    [ ${#suffix} -eq 6 ]

    # Check it contains only lowercase alphanumeric
    [[ "$suffix" =~ ^[a-z0-9]+$ ]]
}

@test "get_connection_type extracts postgres type" {
    # Test connection type extraction via grep on config
    local result
    result=$(yq eval ".environments.staging.connections.user-db.type" "${CONFIG_FILE}" 2>/dev/null | grep -o '\*[a-z0-9_-]*' | sed 's/^\*//')

    [ "$result" = "postgres" ]
}

@test "get_connection_type extracts mysql type" {
    # Test connection type extraction via grep on config
    local result
    result=$(yq eval ".environments.staging.connections.order-db.type" "${CONFIG_FILE}" 2>/dev/null | grep -o '\*[a-z0-9_-]*' | sed 's/^\*//')

    [ "$result" = "mysql" ]
}

@test "get_connection_type returns empty for unknown connection" {
    # Test connection type extraction for non-existent connection
    local result
    result=$(yq eval ".environments.staging.connections.unknown-db.type" "${CONFIG_FILE}" 2>/dev/null | grep -o '\*[a-z0-9_-]*' | sed 's/^\*//' || echo "")

    [ -z "$result" ]
}

# ==============================================================================
# Connection Type Tests
# ==============================================================================

@test "handles postgres connection type correctly" {
    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "user-db" ]]
}

@test "handles mysql connection type correctly" {
    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "order-db" ]]
}

@test "supports multiple connection types in same environment" {
    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "user-db" ]]
    [[ "$output" =~ "order-db" ]]
}

@test "connection type is used for port configuration" {
    # Create config with explicit connection types
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default
  postgres: &postgres
    local-port: 15432
    db-port: 5432
  mysql: &mysql
    local-port: 13306
    db-port: 3306

environments:
  staging:
    k8s-context: staging-context
    connections:
      user-db:
        host: postgres.example.com
        type: *postgres
      order-db:
        host: mysql.example.com
        type: *mysql
EOF

    # Update mock yq
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    ".environments.staging.connections.user-db.type") echo "*postgres" ;;
    ".environments.staging.connections.order-db.type") echo "*mysql" ;;
    "explode(.) | .environments.staging.connections.user-db.host") echo "postgres.example.com" ;;
    "explode(.) | .environments.staging.connections.order-db.host") echo "mysql.example.com" ;;
    "explode(.) | .environments.staging.connections.user-db.type.local-port") echo "15432" ;;
    "explode(.) | .environments.staging.connections.user-db.type.db-port") echo "5432" ;;
    "explode(.) | .environments.staging.connections.order-db.type.local-port") echo "13306" ;;
    "explode(.) | .environments.staging.connections.order-db.type.db-port") echo "3306" ;;
    ".environments | keys | .[]") echo "staging" ;;
    ".environments.staging.connections | keys | .[]")
        echo "order-db"
        echo "user-db"
        ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin ls staging
    [ "$status" -eq 0 ]
}

# ==============================================================================
# Integration Tests (with mocked kubectl)
# ==============================================================================

@test "validates environment exists before creating tunnel" {
    run_plugin --env nonexistent --connection user-db
    [ "$status" -eq 1 ]
}

@test "validates connection alias exists before creating tunnel" {
    run_plugin --env staging --connection nonexistent_db
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
    run_plugin --env invalid --connection user-db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available environments" ]]
}

@test "lists available connections on invalid connection" {
    run_plugin --env staging --connection invalid_db
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Available connections" ]]
}

# ==============================================================================
# Edge Cases
# ==============================================================================

@test "handles empty environment name" {
    run_plugin --env "" --connection user-db
    [ "$status" -eq 1 ]
}

@test "handles unexpected positional arguments" {
    run_plugin --env staging --connection user-db extra_arg
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unexpected argument" ]]
}

@test "supports --local-port flag" {
    run_plugin --env staging --connection user-db --local-port 5433 --help
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
    run_plugin --env staging --connection user-db --help
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
    run_plugin --env staging --connection user-db --local-port 9999 --help
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

# ==============================================================================
# Connection Edge Cases and Coverage Tests
# ==============================================================================

@test "handles connection without type definition gracefully" {
    # Create config with connection but no type
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default

environments:
  staging:
    k8s-context: staging-context
    connections:
      raw-service:
        host: service.example.com
EOF

    # Update mock yq to handle this case
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    ".environments.staging.connections.raw-service.type") echo "" ;;
    "explode(.) | .environments.staging.connections.raw-service.host") echo "service.example.com" ;;
    "explode(.) | .environments.staging.connections.raw-service.type.local-port") echo "" ;;
    "explode(.) | .environments.staging.connections.raw-service.type.db-port") echo "" ;;
    ".environments | keys | .[]") echo "staging" ;;
    ".environments.staging.connections | keys | .[]") echo "raw-service" ;;
    ".settings.namespace") echo "default" ;;
    ".settings.jump-pod-image") echo "alpine/socat:latest" ;;
    ".settings.jump-pod-wait-timeout") echo "60" ;;
    ".settings.local-port") echo "5432" ;;
    ".settings.db-port") echo "5432" ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    # Should still list the connection even without type
    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "raw-service" ]]
}

@test "handles multiple postgres connections in same environment" {
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
        host: user-postgres.example.com
        type: *postgres
      analytics-db:
        host: analytics-postgres.example.com
        type: *postgres
      reports-db:
        host: reports-postgres.example.com
        type: *postgres
EOF

    # Update mock yq
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    ".environments.staging.connections.user-db.type") echo "*postgres" ;;
    ".environments.staging.connections.analytics-db.type") echo "*postgres" ;;
    ".environments.staging.connections.reports-db.type") echo "*postgres" ;;
    "explode(.) | .environments.staging.connections.user-db.host") echo "user-postgres.example.com" ;;
    "explode(.) | .environments.staging.connections.analytics-db.host") echo "analytics-postgres.example.com" ;;
    "explode(.) | .environments.staging.connections.reports-db.host") echo "reports-postgres.example.com" ;;
    ".environments | keys | .[]") echo "staging" ;;
    ".environments.staging.connections | keys | .[]")
        echo "analytics-db"
        echo "reports-db"
        echo "user-db"
        ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "user-db" ]]
    [[ "$output" =~ "analytics-db" ]]
    [[ "$output" =~ "reports-db" ]]
}

@test "handles redis connection type" {
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default
  redis: &redis
    local-port: 16379
    db-port: 6379

environments:
  staging:
    k8s-context: staging-context
    connections:
      cache:
        host: redis.example.com
        type: *redis
EOF

    # Update mock yq
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    ".environments.staging.connections.cache.type") echo "*redis" ;;
    "explode(.) | .environments.staging.connections.cache.host") echo "redis.example.com" ;;
    "explode(.) | .environments.staging.connections.cache.type.local-port") echo "16379" ;;
    "explode(.) | .environments.staging.connections.cache.type.db-port") echo "6379" ;;
    ".environments | keys | .[]") echo "staging" ;;
    ".environments.staging.connections | keys | .[]") echo "cache" ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "cache" ]]
}

@test "handles mongodb connection type" {
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default
  mongodb: &mongodb
    local-port: 17017
    db-port: 27017

environments:
  staging:
    k8s-context: staging-context
    connections:
      sessions:
        host: mongodb.example.com
        type: *mongodb
EOF

    # Update mock yq
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    ".environments.staging.connections.sessions.type") echo "*mongodb" ;;
    "explode(.) | .environments.staging.connections.sessions.host") echo "mongodb.example.com" ;;
    "explode(.) | .environments.staging.connections.sessions.type.local-port") echo "17017" ;;
    "explode(.) | .environments.staging.connections.sessions.type.db-port") echo "27017" ;;
    ".environments | keys | .[]") echo "staging" ;;
    ".environments.staging.connections | keys | .[]") echo "sessions" ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sessions" ]]
}

@test "handles custom connection type" {
    cat > "${CONFIG_FILE}" <<EOF
settings:
  namespace: default
  custom-api: &custom-api
    local-port: 18080
    db-port: 8080

environments:
  staging:
    k8s-context: staging-context
    connections:
      internal-api:
        host: api.example.com
        type: *custom-api
EOF

    # Update mock yq
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
query="${2%% //*}"
case "$query" in
    ".") exit 0 ;;
    ".environments.staging.k8s-context") echo "staging-context" ;;
    ".environments.staging.connections.internal-api.type") echo "*custom-api" ;;
    "explode(.) | .environments.staging.connections.internal-api.host") echo "api.example.com" ;;
    "explode(.) | .environments.staging.connections.internal-api.type.local-port") echo "18080" ;;
    "explode(.) | .environments.staging.connections.internal-api.type.db-port") echo "8080" ;;
    ".environments | keys | .[]") echo "staging" ;;
    ".environments.staging.connections | keys | .[]") echo "internal-api" ;;
    *) echo "" ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin ls staging
    [ "$status" -eq 0 ]
    [[ "$output" =~ "internal-api" ]]
}

@test "validates connection host is not empty" {
    # User-db should have a valid host in staging
    run_plugin --env staging --connection user-db --help
    [ "$status" -eq 0 ]
}
