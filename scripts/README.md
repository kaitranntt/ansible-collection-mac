# macOS Testing Scripts

This directory contains scripts for managing macOS containers for testing with the kaitranntt.mac Ansible collection.

## 🚀 Quick Start

All scripts have been refactored to use common utility functions, reducing code duplication and improving maintainability.

## 📁 Scripts Overview

### Container Management Scripts

| Script | Purpose | Key Features |
|--------|---------|--------------|
| `start-macos-container.sh` | Start macOS container for testing | Docker Compose setup, health checks, artifact directory creation |
| `stop-macos-container.sh` | Stop and clean up macOS container | Graceful shutdown, artifact collection, resource cleanup |
| `check-macos-status.sh` | Check container and system status | Multi-level status reporting, resource monitoring |
| `cleanup-macos.sh` | Comprehensive cleanup of all resources | Remove containers, networks, images, temporary files |

### Monitoring and Utilities Scripts

| Script | Purpose | Key Features |
|--------|---------|--------------|
| `capture-screenshot.sh` | Visual monitoring via screenshots | Multiple capture methods, series capture, report generation |
| `collect-test-logs.sh` | Log collection and analysis | Comprehensive log gathering, automated analysis |
| `analyze-test-logs.py` | Advanced log analysis | Pattern detection, issue identification, recommendations |

## 🛠️ Common Features

All scripts now include:

### ✅ Standardized Arguments
- `--test-id TEST_ID` - Specify test ID for container operations
- `--debug` - Enable debug mode for verbose output
- `--help` - Display comprehensive help information

### ✅ Consistent Logging
- **Blue**: General information and progress
- **Green**: Success messages
- **Yellow**: Warnings and non-critical issues
- **Red**: Errors and critical failures
- **Cyan**: Additional information (info level)

### ✅ Environment Support
- Automatic loading of `.env.test` configuration files
- Support for all standard environment variables (WEB_PORT, VNC_PORT, SSH_PORT, etc.)
- Default values for all configuration options

### ✅ Error Handling
- Graceful error handling with informative messages
- Dependency checking before operations
- Interrupt signal handling for safe termination

## 📋 Common Utilities (`common/utils.sh`)

All scripts share a comprehensive utility library providing:

### 🔧 Configuration Management
- Directory path resolution
- Test ID and container name generation
- Port configuration with sensible defaults
- Environment variable loading

### 🔍 Dependency Checking
- Docker availability and daemon status
- Docker Compose detection
- KVM support verification
- Optional tool detection (curl, netcat, ImageMagick, etc.)

### 🐳 Docker Management
- Container existence and running status checks
- Docker Compose command detection
- Network management
- Resource cleanup utilities

### 📊 Monitoring Functions
- Network connectivity testing
- Resource usage reporting
- Artifact directory management
- Test summary generation

## 🚦 Usage Examples

### Basic Container Operations

```bash
# Start container with auto-generated test ID
./start-macos-container.sh

# Start container with specific test ID
./start-macos-container.sh --test-id my-test-001

# Check status
./check-macos-status.sh

# Stop container
./stop-macos-container.sh --test-id my-test-001
```

### Monitoring and Debugging

```bash
# Capture single screenshot
./capture-screenshot.sh --name before-installation

# Capture series over time
./capture-screenshot.sh --series --duration 600 --interval 60

# Check all containers
./check-macos-status.sh --all

# Enable debug mode
./start-macos-container.sh --debug
```

### Cleanup Operations

```bash
# Force cleanup of all resources
./cleanup-macos.sh --force

# Clean up but keep artifacts
./stop-macos-container.sh --keep-artifacts

# Dry run to see what would be cleaned
./cleanup-macos.sh --dry-run
```

## 📝 Environment Variables

All scripts respect the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `WEB_PORT` | `8006` | Web interface port |
| `VNC_PORT` | `5900` | VNC access port |
| `SSH_PORT` | `2222` | SSH access port |
| `TEST_ID` | auto-generated | Test identifier |
| `DEBUG` | `false` | Enable debug mode |
| `MACOS_VERSION` | `14` | macOS version for container |
| `DISK_SIZE` | `64G` | Container disk size |
| `RAM_SIZE` | `8G` | Container RAM allocation |
| `CPU_CORES` | `4` | Number of CPU cores |

## 🗂️ File Structure

```
scripts/
├── common/
│   └── utils.sh              # Shared utility functions
├── start-macos-container.sh  # Start container
├── stop-macos-container.sh   # Stop container
├── check-macos-status.sh     # Check status
├── cleanup-macos.sh          # Cleanup resources
├── capture-screenshot.sh     # Visual monitoring
├── collect-test-logs.sh      # Log collection
├── analyze-test-logs.py      # Log analysis
├── test.sh                   # Test runner
├── setup-dev.sh              # Development setup
├── monitor-test-progress.sh  # Progress monitoring
├── quality-metrics.py        # Quality reporting
└── README.md                 # This file
```

## 🔄 Code Duplication Reduction

The refactoring has achieved significant code reduction:

### Before Refactoring
- **5 scripts** with **~200 lines** of duplicated code each
- **Repeated implementations** for:
  - Logging functions (5 implementations)
  - Color definitions (5 implementations)
  - Dependency checking (5 implementations)
  - Configuration management (5 implementations)
  - Error handling (5 implementations)

### After Refactoring
- **1 shared utility library** with **~400 lines** of reusable code
- **5 streamlined scripts** with **~150 lines** each
- **Shared implementations** for all common functionality
- **Consistent behavior** across all scripts

### 📊 Improvements
- **~60% reduction** in duplicated code
- **Consistent interface** across all scripts
- **Centralized maintenance** for common functions
- **Enhanced error handling** and logging
- **Better documentation** and help systems

## 🔧 Development

### Adding New Scripts

When creating new scripts:

1. **Source the common utilities**:
   ```bash
   source "$SCRIPT_DIR/common/utils.sh"
   init_common
   ```

2. **Use standard functions**:
   - `log`, `error`, `success`, `warning`, `info` for output
   - `check_dependencies` for dependency verification
   - `container_exists`, `container_running` for container checks
   - `parse_common_args` for argument parsing

3. **Follow the established patterns**:
   - Use consistent help formatting
   - Implement standard error handling
   - Support common environment variables
   - Include debug mode support

### Testing Scripts

All scripts include syntax validation:
```bash
# Check syntax
bash -n scripts/script-name.sh

# Test help function
bash scripts/script-name.sh --help
```

## 🐛 Troubleshooting

### Common Issues

**Permission Denied Errors**
```bash
chmod +x scripts/*.sh
```

**Docker Not Running**
```bash
sudo systemctl start docker
# Or start Docker Desktop
```

**Container Already Exists**
```bash
# Remove existing container
./scripts/stop-macos-container.sh --force
```

**Port Conflicts**
```bash
# Use different ports
export WEB_PORT=8007 VNC_PORT=5901
./scripts/start-macos-container.sh
```

### Debug Mode

Enable debug mode for detailed troubleshooting:
```bash
./scripts/start-macos-container.sh --debug
export DEBUG=true
./scripts/check-macos-status.sh
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [dockur/macos Container](https://github.com/dockur/macos)
- [Ansible Collection Documentation](../README.md)
- [macOS Testing Framework](../docs/macos-docker-testing.md)
