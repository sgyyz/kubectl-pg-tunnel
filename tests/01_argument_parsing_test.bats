#!/usr/bin/env bats

# Argument Parsing Tests

load setup_common

setup() {
    setup_test_environment
}

teardown() {
    teardown_test_environment
}

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

@test "handles unexpected positional arguments" {
    run_plugin --env staging --connection user-db extra_arg
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unexpected argument" ]]
}

@test "accepts --cleanup flag" {
    run_plugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--cleanup" ]]
}
