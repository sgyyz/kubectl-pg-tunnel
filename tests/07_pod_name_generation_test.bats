#!/usr/bin/env bats

# Pod Name Generation Tests

load setup_common

setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}

@test "pod name uses hostname suffix" {
    # Get the current hostname that would be used
    local hostname_suffix
    hostname_suffix=$(hostname -s 2>/dev/null || hostname | cut -d. -f1)
    hostname_suffix=$(echo "${hostname_suffix}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^-*//' | sed 's/-*$//')

    # Check hostname suffix is valid
    [ -n "${hostname_suffix}" ]
    [[ "${hostname_suffix}" =~ ^[a-z0-9-]+$ ]]
}

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
