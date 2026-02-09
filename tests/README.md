# Test Suite

This directory contains the BATS test suite for kubectl-tcp-tunnel. The tests are organized into multiple files for better maintainability and parallel execution.

## Test Structure

The test suite is split into logical groups:

### Test Files

1. **`setup_common.bash`** - Common setup and teardown functions
   - Shared test environment setup
   - Mock implementations (yq, kubectl, kubectx)
   - Helper functions used across all test files

2. **`01_argument_parsing_test.bats`** (16 tests)
   - Command-line argument parsing
   - Flag validation
   - Short and long argument forms
   - Error handling for missing/invalid arguments

3. **`02_config_handling_test.bats`** (5 tests)
   - Configuration file loading
   - YAML validation
   - Environment variable handling (TCP_TUNNEL_CONFIG)
   - Error messages for missing/invalid config

4. **`03_subcommands_test.bats`** (11 tests)
   - `ls` subcommand functionality
   - `edit-config` subcommand
   - Help and documentation display
   - Version information

5. **`04_validation_test.bats`** (11 tests)
   - Environment validation
   - Connection alias validation
   - Error messages for invalid inputs
   - Connection host validation

6. **`05_port_configuration_test.bats`** (8 tests)
   - Local port configuration
   - Remote port configuration
   - Port fallback behavior
   - Connection type port settings

7. **`06_connection_types_test.bats`** (12 tests)
   - PostgreSQL, MySQL, Redis, MongoDB connection types
   - Custom connection types
   - Multiple connections of same type
   - Connection type extraction

8. **`07_pod_name_generation_test.bats`** (4 tests)
   - Hostname-based pod naming
   - Mock tool verification (kubectl, kubectx, yq)

9. **`08_cleanup_command_test.bats`** (3 tests)
   - Cleanup command functionality
   - Multi-context cleanup
   - Hostname suffix handling

**Total: 70 tests**

## Running Tests

### Local Development

Run all tests sequentially:
```bash
make test
```

Run tests with parallel execution (CI only):
```bash
make test-parallel
```

Run a specific test file:
```bash
bats tests/01_argument_parsing_test.bats
```

Run a specific test by name:
```bash
bats tests/01_argument_parsing_test.bats -f "shows help"
```

### CI/CD (GitHub Actions)

Tests run in parallel across multiple jobs in CI:
- Each test file runs as a separate job
- Faster overall test execution
- Better isolation between test suites
- Fail-fast disabled to see all failures

## Test Environment

Each test runs with:
- Isolated temporary directory (`$TEST_DIR`)
- Mock implementations of external tools:
  - `yq` - YAML parser
  - `kubectl` - Kubernetes CLI
  - `kubectx` - Context switching tool
- Test configuration file
- Clean environment for each test

## Adding New Tests

### Adding tests to an existing file

1. Find the appropriate test file based on the feature area
2. Add your test using the `@test` directive:
   ```bash
   @test "descriptive test name" {
       run_plugin --your-args
       [ "$status" -eq 0 ]
       [[ "$output" =~ "expected output" ]]
   }
   ```

### Creating a new test file

1. Create a new file with naming pattern: `0X_category_test.bats`
2. Add the header:
   ```bash
   #!/usr/bin/env bats

   # Category Name Tests

   load setup_common

   setup() {
       setup_test_environment
   }

   teardown() {
       teardown_test_environment
   }
   ```
3. Add your tests
4. Update this README with the new file
5. Update `.github/workflows/ci.yml` matrix to include the new file

## Test Helpers

### `setup_test_environment()`
Sets up the test environment, creates mocks, and prepares config files.

### `teardown_test_environment()`
Cleans up temporary test directories.

### `run_plugin(...args)`
Helper function to run the plugin with arguments.
Internally uses `run bash "${PLUGIN}" "$@"`

## Mock Implementations

### Mock `yq`
Returns predefined values for common config queries. Simulates YAML parsing without requiring actual yq installation in tests.

### Mock `kubectl`
Records commands to `kubectl.log` and returns success. Simulates pod lifecycle operations.

### Mock `kubectx`
Records context switches to `kubectx.log`. Simulates context switching.

## Debugging Tests

### View test output in detail
```bash
bats tests/01_argument_parsing_test.bats --verbose
```

### Run a single test
```bash
bats tests/01_argument_parsing_test.bats -f "shows help with --help flag"
```

### Check mock command logs
Mocks write to log files in `$TEST_DIR`:
- `$TEST_DIR/kubectl.log` - kubectl commands
- `$TEST_DIR/kubectx.log` - kubectx calls

### Enable debug output
Add to your test:
```bash
@test "my test" {
    echo "Debug: current dir is $(pwd)" >&3
    # rest of test
}
```

## Coverage

Current test coverage includes:
- ✅ Argument parsing and validation
- ✅ Configuration loading and validation
- ✅ All subcommands (ls, edit-config, help, version, cleanup)
- ✅ Environment and connection validation
- ✅ Local and remote port configuration
- ✅ All connection types (postgres, mysql, redis, mongodb, custom)
- ✅ Error messages and user guidance
- ✅ Pod name generation (hostname-based)
- ✅ Pod cleanup functionality
- ✅ Mock tool verification

## Maintenance

When modifying the plugin:
1. Run `make check` before committing
2. Add tests for new features
3. Update existing tests if behavior changes
4. Keep test descriptions clear and specific
5. Group related tests in appropriate files

## Performance

- Local sequential run: ~5-10 seconds
- CI parallel run: ~2-3 minutes (includes setup time)
- Individual test file: ~1-2 seconds

## References

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [Testing Shell Scripts](https://github.com/bats-core/bats-core#writing-tests)
