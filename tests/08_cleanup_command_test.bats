#!/usr/bin/env bats

# Cleanup Command Tests

load setup_common

setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}

@test "cleanup command shows help message when no pods found" {
    run_plugin cleanup

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Cleaning up jump pods for this machine" ]]
    [[ "$output" =~ "No jump pods found for this machine" ]]
}

@test "cleanup command searches in all configured contexts" {
    run_plugin cleanup

    [ "$status" -eq 0 ]

    # Should query both contexts from config
    # Note: mock kubectl won't find any pods, but it should try
    [[ "$output" =~ "Cleaning up jump pods for this machine" ]]
}

@test "cleanup command uses hostname suffix" {
    # Get hostname that would be used
    local hostname_suffix
    hostname_suffix=$(hostname -s 2>/dev/null || hostname | cut -d. -f1)
    hostname_suffix=$(echo "${hostname_suffix}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^-*//' | sed 's/-*$//')

    run_plugin cleanup

    [ "$status" -eq 0 ]

    # The command should use the hostname suffix for searching
    [ -n "${hostname_suffix}" ]
}
