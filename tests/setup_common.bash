#!/usr/bin/env bash

# Common setup and teardown functions for all test suites
# This file is sourced by all test files

setup_test_environment() {
    # Set up test environment
    # shellcheck disable=SC2154  # BATS_TEST_TMPDIR is provided by BATS
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
    remote-port: 5432

  mysql: &mysql
    local-port: 13306
    remote-port: 3306

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
    ".settings.remote-port")
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
    "explode(.) | .environments.staging.connections.user-db.type.remote-port")
        echo "5432"
        ;;
    "explode(.) | .environments.staging.connections.order-db.type.local-port")
        echo "13306"
        ;;
    "explode(.) | .environments.staging.connections.order-db.type.remote-port")
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
    "explode(.) | .environments.production.connections.user-db.type.remote-port")
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
    "explode(.) | .environments.staging.connections.unknown_db.type.remote-port")
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
    ".environments[].k8s-context")
        echo "staging-cluster"
        echo "prod-cluster"
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
                # Check if this is a pod status check (with -o jsonpath)
                if [[ "$4" == "pod" ]] && [[ "$6" == "-o" ]] && [[ "$7" == "jsonpath={.status.phase}" ]]; then
                    # Check if pod exists marker file is present
                    if [[ -f "${TEST_DIR}/pod_exists" ]]; then
                        echo "Running"
                        exit 0
                    fi
                    exit 1
                fi
                # Regular pod existence check
                if [[ -f "${TEST_DIR}/pod_exists" ]]; then
                    exit 0
                fi
                exit 1  # Pod doesn't exist
                ;;
            run)
                # Mark pod as created
                touch "${TEST_DIR}/pod_exists"
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
                # Remove pod exists marker
                rm -f "${TEST_DIR}/pod_exists"
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
    # shellcheck disable=SC2154  # BATS_TEST_DIRNAME is provided by BATS
    PLUGIN="${BATS_TEST_DIRNAME}/../kubectl-tcp_tunnel"
}

teardown_test_environment() {
    # Clean up test directory
    rm -rf "${TEST_DIR}"
}

# Helper function to run plugin
run_plugin() {
    run bash "${PLUGIN}" "$@"
}
