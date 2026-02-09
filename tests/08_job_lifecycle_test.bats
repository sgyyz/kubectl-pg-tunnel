#!/usr/bin/env bats

# Job Lifecycle Tests
# Tests for Kubernetes Job creation, activeDeadlineSeconds, and cleanup

load setup_common

setup() {
    setup_test_environment

    # Override the mock kubectl to capture job manifest and exit early
    cat > "${TEST_DIR}/bin/kubectl" <<EOSCRIPT
#!/usr/bin/env bash
# Mock kubectl that captures job manifest and exits without port-forward
TEST_DIR="${TEST_DIR}"
echo "kubectl \$*" >> "\${TEST_DIR}/kubectl.log"

# Handle kubectl get pods with selector (pod name discovery)
if [[ "\$*" == *"get pods"* ]] && [[ "\$*" == *"--selector="* ]]; then
    # Extract job name from selector
    job_name=\$(echo "\$*" | grep -o 'job-name=[^ ]*' | cut -d= -f2)
    # Return a generated pod name
    echo "\${job_name}-abcde"
    exit 0
fi

# Handle create command (can be at position 3 or 5 depending on flags)
if [[ "\$*" == *"create -f -"* ]] || [[ "\$*" == *"create"* ]]; then
    # Mock job creation - read YAML from stdin and save it
    cat > "\${TEST_DIR}/job-manifest.yaml"
    echo "job.batch/test-job created"
    exit 0
fi

case "\$1" in
    --context=*)
        # Skip context and namespace args to find the actual command
        shift  # skip --context=...
        if [[ "\$1" == "-n" ]]; then
            shift 2  # skip -n namespace
        fi

        case "\$1" in
            get)
                # Check if we're getting a job or pod
                if [[ "\$2" == "job"* ]] || [[ "\$2" == "pod"* ]]; then
                    exit 1  # Job/Pod doesn't exist
                fi
                exit 1
                ;;
            wait)
                exit 0
                ;;
            port-forward)
                # Exit immediately instead of blocking
                exit 0
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
}

teardown() {
    teardown_test_environment
}

@test "creates job instead of bare pod" {
    run_plugin --env staging --connection user-db

    # Should call kubectl create with job manifest
    [ -f "${TEST_DIR}/kubectl.log" ]
    grep -q "kubectl.*create.*-f" "${TEST_DIR}/kubectl.log"
}

@test "job includes activeDeadlineSeconds" {
    run_plugin --env staging --connection user-db

    # Save manifest before teardown deletes it
    local manifest_content=""
    if [ -f "${TEST_DIR}/job-manifest.yaml" ]; then
        manifest_content=$(cat "${TEST_DIR}/job-manifest.yaml")
    fi

    # Check that YAML includes activeDeadlineSeconds: 28800
    [ -n "$manifest_content" ]
    echo "$manifest_content" | grep -q "activeDeadlineSeconds: 28800"
}

@test "job includes correct labels" {
    run_plugin --env staging --connection user-db

    # Check that YAML includes correct labels
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q "app: kubectl-tcp-tunnel" "${TEST_DIR}/job-manifest.yaml"
    grep -q "managed-by: kubectl-tcp-tunnel" "${TEST_DIR}/job-manifest.yaml"
}

@test "job uses correct image from config" {
    run_plugin --env staging --connection user-db

    # Check that YAML includes correct image
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q "image: alpine/socat:latest" "${TEST_DIR}/job-manifest.yaml"
}

@test "job includes correct socat command" {
    run_plugin --env staging --connection user-db

    # Check that YAML includes correct socat command
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q -- "- socat" "${TEST_DIR}/job-manifest.yaml"
    grep -q "TCP-LISTEN:5432" "${TEST_DIR}/job-manifest.yaml"
    grep -q "TCP:postgres-staging.example.com:5432" "${TEST_DIR}/job-manifest.yaml"
}

@test "job has backoffLimit set to 0" {
    run_plugin --env staging --connection user-db

    # Check that YAML includes backoffLimit: 0
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q "backoffLimit: 0" "${TEST_DIR}/job-manifest.yaml"
}

@test "job has restartPolicy set to Never" {
    run_plugin --env staging --connection user-db

    # Check that YAML includes restartPolicy: Never
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q "restartPolicy: Never" "${TEST_DIR}/job-manifest.yaml"
}

@test "displays auto-cleanup duration in output" {
    run_plugin --env staging --connection user-db

    # Check output includes auto-cleanup duration
    [[ "$output" =~ "Auto-cleanup: 28800s" ]] || [[ "$output" =~ "auto-cleanup after 28800s" ]]
}

@test "reads tunnel-max-duration from config" {
    # Update config with custom duration
    cat > "${CONFIG_FILE}" <<'EOF'
settings:
  namespace: test-namespace
  jump-pod-image: alpine/socat:latest
  jump-pod-wait-timeout: 60
  tunnel-max-duration: 3600

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

    # Update mock yq to return custom value
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
# Mock yq that can parse our test YAML with custom tunnel duration
# Strip the // "" operator if present
query="${2%% //*}"
case "$query" in
    ".")
        # Validate YAML
        exit 0
        ;;
    ".settings.tunnel-max-duration")
        echo "3600"
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

    run_plugin --env staging --connection user-db

    # Check that YAML includes custom activeDeadlineSeconds
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q "activeDeadlineSeconds: 3600" "${TEST_DIR}/job-manifest.yaml"
}

@test "uses default tunnel-max-duration when not configured" {
    # Remove tunnel-max-duration from config
    cat > "${CONFIG_FILE}" <<'EOF'
settings:
  namespace: test-namespace
  jump-pod-image: alpine/socat:latest
  jump-pod-wait-timeout: 60

  postgres: &postgres
    local-port: 15432
    remote-port: 5432

environments:
  staging:
    k8s-context: staging-cluster
    connections:
      user-db:
        host: postgres-staging.example.com
        type: *postgres
EOF

    # Update mock yq to return empty for tunnel-max-duration
    cat > "${TEST_DIR}/bin/yq" <<'EOSCRIPT'
#!/usr/bin/env bash
# Mock yq that returns empty for tunnel-max-duration
query="${2%% //*}"
case "$query" in
    ".")
        exit 0
        ;;
    ".settings.tunnel-max-duration")
        echo ""
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
    ".environments.staging.k8s-context")
        echo "staging-cluster"
        ;;
    "explode(.) | .environments.staging.connections.user-db.host")
        echo "postgres-staging.example.com"
        ;;
    "explode(.) | .environments.staging.connections.user-db.type.local-port")
        echo "15432"
        ;;
    "explode(.) | .environments.staging.connections.user-db.type.remote-port")
        echo "5432"
        ;;
    ".environments.staging.connections.user-db.type")
        echo "*postgres"
        ;;
    ".environments | keys | .[]")
        echo "staging"
        ;;
    ".environments.staging.connections | keys | .[]")
        echo "user-db"
        ;;
    *)
        echo ""
        ;;
esac
exit 0
EOSCRIPT
    chmod +x "${TEST_DIR}/bin/yq"

    run_plugin --env staging --connection user-db

    # Check that YAML includes default activeDeadlineSeconds (28800)
    [ -f "${TEST_DIR}/job-manifest.yaml" ]
    grep -q "activeDeadlineSeconds: 28800" "${TEST_DIR}/job-manifest.yaml"
}

@test "pod name discovery from job" {
    run_plugin --env staging --connection user-db

    # Check that kubectl get pods with selector was called
    [ -f "${TEST_DIR}/kubectl.log" ]
    grep -q "get pods.*--selector=.*job-name=" "${TEST_DIR}/kubectl.log"
}
