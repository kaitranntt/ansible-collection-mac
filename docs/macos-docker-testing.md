# macOS Docker Testing Framework

This document describes the comprehensive macOS Docker testing framework for the kaitranntt.mac Ansible collection.

## Overview

The macOS Docker testing framework provides authentic macOS testing environments using [dockurr/macos](https://github.com/dockur/macos) containers, replacing traditional Ubuntu-based testing with real macOS environments for more accurate and reliable validation of Tailscale installation and management.

## Architecture

### Core Components

1. **Docker Infrastructure**
   - `docker-compose.test.yml` - Container orchestration configuration
   - dockurr/macos containers with KVM virtualization support
   - Network configuration for web interface, VNC, and SSH access

2. **Test Framework**
   - Molecule-based test scenarios for different configurations
   - Configuration matrix testing across installation methods
   - Error scenario testing for robustness validation

3. **Monitoring & Debugging**
   - Screenshot capture system for visual monitoring
   - Comprehensive log collection and analysis
   - Progress tracking and health monitoring

4. **CI/CD Integration**
   - GitHub Actions workflows for automated testing
   - Multi-scenario test execution with artifact collection

## Quick Start

### Prerequisites

- Docker Engine 20.10+ with Docker Compose
- KVM support (Linux hosts, optional but recommended)
- Python 3.11+ with Ansible and Molecule
- Sufficient disk space (8GB+ for container images)

### Basic Usage

```bash
# Check system requirements
make check-macos-requirements

# Run basic macOS tests
make test-macos

# Run tests with visual monitoring
make test-macos-visual

# Clean up after testing
make test-macos-clean
```

## Test Scenarios

### Installation Methods

The framework supports testing all Tailscale installation methods:

1. **Go Installation** (`test-macos-installation` with method=go)
   - Downloads and installs Tailscale Go binary
   - Tests version verification and basic functionality

2. **Binary Installation** (`test-macos-installation` with method=binary)
   - Downloads pre-compiled Tailscale binary
   - Tests installation and command availability

3. **Homebrew Installation** (`test-macos-installation` with method=homebrew)
   - Uses Homebrew package manager
   - Tests package installation and verification

### Configuration Testing

1. **Basic Configuration** (`test-macos`)
   - Default Tailscale configuration
   - Basic connectivity and status checks

2. **Network Configuration** (`test-macos-network`)
   - Advanced networking with DNS and route acceptance
   - Multi-network configuration testing

3. **Configuration Matrix** (`test-macos-matrix`)
   - Multiple configuration combinations
   - Parameter matrix testing for comprehensive coverage

4. **Error Scenarios** (`test-macos-errors`)
   - Invalid authentication keys
   - Network connectivity issues
   - Permission and access problems

## Makefile Targets

### Testing Commands

```bash
# Core testing targets
make test-macos                 # Basic macOS container tests
make test-macos-visual          # Tests with visual monitoring
make test-macos-all             # All test scenarios
make test-macos-quick           # Quick functionality check

# Specific scenario tests
make test-macos-installation    # All installation method tests
make test-macos-network         # Network configuration tests
make test-macos-matrix          # Configuration matrix tests
make test-macos-errors          # Error scenario tests

# Log collection and analysis
make test-macos-logs            # Collect and analyze test logs
make test-macos-analyze         # Analyze existing test logs

# Management commands
make test-macos-status          # Check container status
make test-macos-clean           # Clean up test artifacts
make check-macos-requirements   # Verify system requirements
```

## Container Management

### Manual Container Operations

```bash
# Start a container
./scripts/start-macos-container.sh

# Check container status
./scripts/check-macos-status.sh

# Capture screenshots
./scripts/capture-screenshot.sh --name "test-screenshot"

# Collect logs
./scripts/collect-test-logs.sh

# Stop container
./scripts/stop-macos-container.sh

# Clean up all resources
./scripts/cleanup-macos.sh
```

### Environment Variables

```bash
# Test identification
export TEST_ID="custom_test_$(date +%Y%m%d_%H%M%S)"

# Container configuration
export MACOS_VERSION="14"          # macOS version
export DISK_SIZE="64G"            # Disk size
export RAM_SIZE="8G"              # RAM allocation
export CPU_CORES="4"              # CPU cores

# Visual monitoring
export VISUAL_MODE="true"         # Enable visual monitoring
export CAPTURE_SCREENSHOTS="true" # Capture screenshots

# Authentication
export TAILSCALE_TEST_AUTHKEY="tskey-auth-xxxxx"
```

## Log Collection and Analysis

### Automated Log Collection

```bash
# Collect and analyze logs
./scripts/collect-test-logs.sh --test-id $TEST_ID --archive

# Analyze existing logs
./scripts/analyze-test-logs.py \
  --log-dir "test-artifacts/$TEST_ID/logs" \
  --output-dir "test-artifacts/$TEST_ID/analysis" \
  --verbose
```

### Log Categories

1. **Container Logs**
   - Container startup and shutdown logs
   - macOS boot logs and system messages
   - Resource usage and performance metrics

2. **Docker Logs**
   - Docker Compose orchestration logs
   - Container health check logs
   - Network and volume management logs

3. **Molecule Logs**
   - Ansible playbook execution logs
   - Test task results and timing
   - Idempotence verification results

4. **Tailscale Logs**
   - Service startup and authentication logs
   - Connection status and peer information
   - Configuration changes and errors

5. **System Logs**
   - Host system diagnostics
   - Container system information
   - Resource utilization metrics

### Analysis Reports

The log analysis system generates:

- **Executive Summary**: High-level overview of test results
- **Issue Detection**: Automated identification of common problems
- **Performance Metrics**: Resource usage and timing information
- **Recommendations**: Actionable suggestions for improvement
- **Timeline**: Chronological view of test events

## Visual Monitoring

### Screenshot Capture

```bash
# Capture single screenshot
./scripts/capture-screenshot.sh \
  --name "before-installation" \
  --output-dir test-artifacts/screenshots

# Capture with custom settings
./scripts/capture-screenshot.sh \
  --name "installation-progress" \
  --container "macos-test-custom" \
  --method "web" \
  --output-dir custom-screenshots
```

### Progress Monitoring

```bash
# Initialize progress tracking
./scripts/monitor-test-progress.sh --init --test-id my_test

# Update progress phases
./scripts/monitor-test-progress.sh --update "installation" "in_progress" "Starting Tailscale installation"

# Monitor automatically
./scripts/monitor-test-progress.sh --monitor --interval 30 --duration 1800
```

## Configuration Matrix

### Test Matrix Structure

The configuration matrix tests combinations of:

| Parameter | Values | Description |
|-----------|--------|-------------|
| Installation Method | go, binary, homebrew | Tailscale installation approach |
| Route Acceptance | true, false | Accept subnet routes |
| DNS Acceptance | true, false | Use Tailscale DNS |
| SSH Access | true, false | Enable Tailscale SSH |
| Userspace Mode | true, false | Run in userspace networking |
| Force Reauth | true, false | Force re-authentication |
| Log Level | debug, info, warn | Tailscale logging verbosity |

### Custom Test Configurations

Create custom matrix configurations by modifying `tests/molecule/macos-config-matrix/playbooks/config-matrix.yml`:

```yaml
test_configs:
  - name: "custom_secure_config"
    description: "Secure configuration with restricted networking"
    config:
      tailscale_accept_routes: false
      tailscale_accept_dns: false
      tailscale_ssh: false
      tailscale_force_reauth: true
      tailscale_log_level: "warn"
```

## CI/CD Integration

### GitHub Actions

The framework includes comprehensive GitHub Actions workflows:

1. **`test-macos-docker.yml`** - Full test suite
   - Multiple test scenarios in parallel
   - Artifact collection and analysis
   - Visual monitoring for scheduled runs

2. **`test-macos-quick.yml`** - Quick validation
   - Container health checks
   - Basic syntax validation
   - Fast feedback on pull requests

### Workflow Triggers

```yaml
# Manual dispatch
- workflow_dispatch:
    inputs:
      test_scenario:
        description: 'Test scenario to run'
        type: choice
        options: [all, basic, installation, network, matrix, errors]
      visual_mode:
        description: 'Enable visual monitoring'
        type: boolean
      debug_mode:
        description: 'Enable debug mode'
        type: boolean
```

### Artifact Management

- **Test Artifacts**: 7-day retention
- **Analysis Reports**: 30-day retention
- **Screenshots**: Available for visual tests
- **Log Archives**: Compressed and downloadable

## Troubleshooting

### Common Issues

1. **Container Startup Failure**
   ```bash
   # Check Docker daemon
   docker system info

   # Verify KVM support
   ls -la /dev/kvm

   # Check disk space
   df -h
   ```

2. **Network Connectivity**
   ```bash
   # Check container networking
   docker network ls
   docker-compose -f docker-compose.test.yml ps

   # Test port accessibility
   curl -f http://localhost:8006
   ```

3. **Performance Issues**
   ```bash
   # Monitor resource usage
   docker stats

   # Check container health
   ./scripts/check-macos-status.sh --test-id $TEST_ID
   ```

### Debug Mode

Enable debug mode for detailed logging:

```bash
export DEBUG_MODE=true
export LOG_LEVEL="debug"

# Run with verbose output
make test-macos-visual

# Collect additional logs
./scripts/collect-test-logs.sh --test-id $TEST_ID --debug
```

### Recovery Procedures

```bash
# Force cleanup of all test resources
make test-macos-clean

# Remove orphaned containers
docker container prune -f

# Clean up unused images
docker image prune -f

# Reset Docker system (use with caution)
docker system prune -a -f
```

## Best Practices

### Test Design

1. **Idempotent Tests**: Ensure tests can be run multiple times
2. **Parallel Execution**: Design tests to run concurrently when possible
3. **Resource Cleanup**: Always clean up containers and volumes
4. **Error Handling**: Provide clear error messages and recovery steps

### Performance Optimization

1. **Container Reuse**: Reuse containers when running multiple test scenarios
2. **Log Management**: Rotate and archive logs to prevent disk space issues
3. **Resource Limits**: Set appropriate memory and CPU limits
4. **Network Efficiency**: Optimize Docker networking for faster startup

### Security Considerations

1. **Authentication Keys**: Use test-only authentication keys
2. **Network Isolation**: Isolate test containers from production networks
3. **Secret Management**: Never commit authentication keys to version control
4. **Access Control**: Limit container privileges to minimum required

## Contributing

### Adding New Test Scenarios

1. Create new Molecule scenario directory
2. Configure `molecule.yml` with appropriate settings
3. Write test playbooks and verification steps
4. Update Makefile with new targets
5. Add documentation

### Extending Log Analysis

1. Add new pattern definitions to `scripts/analyze-test-logs.py`
2. Implement custom analysis functions
3. Update the reporting system
4. Add tests for new analysis features

## Support

For issues and questions:

1. Check existing GitHub issues
2. Review log analysis reports
3. Examine container health status
4. Review troubleshooting section

For framework-specific issues, include:
- Test ID and scenario
- Container logs and status
- System information
- Steps to reproduce