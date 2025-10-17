<!-- Badges section -->
<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible Collection](https://img.shields.io/badge/Ansible%20Collection-kaitranntt.mac-blue.svg)](https://galaxy.ansible.com/kaitranntt/mac)
[![Python Version](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![macOS](https://img.shields.io/badge/macOS-10.15+-lightgrey.svg)](https://www.apple.com/macos/)
[![Tailscale](https://img.shields.io/badge/Tailscale-Compatible-green.svg)](https://tailscale.com/)

</div>

# kaitranntt.mac Ansible Collection

[![Ansible Galaxy](https://img.shields.io/badge/Ansible%20Galaxy-kaitranntt.mac-blue.svg)](https://galaxy.ansible.com/kaitranntt/mac)

A comprehensive Ansible collection for managing macOS systems with specialized support for Tailscale VPN installation, configuration, and management.

## 🚀 Quick Start

### Prerequisites

- **macOS 10.15 (Catalina) or later**
- **Ansible 2.15 or later**
- **Python 3.8 or later**
- **One of the following installation dependencies:**
  - Go toolchain (for Go-based installation)
  - Homebrew (for Homebrew-based installation)
  - Internet access (for binary download)

### Installation

#### From Ansible Galaxy (Recommended)

```bash
ansible-galaxy collection install kaitranntt.mac
```

#### From Source

```bash
git clone https://github.com/kaitranntt/ansible-collection-mac.git
cd ansible-collection-mac
ansible-galaxy collection install .
```

### Basic Usage

```yaml
---
- name: Install Tailscale on macOS
  hosts: macos
  collections:
    - kaitranntt.mac
  tasks:
    - name: Include Tailscale role
      include_role:
        name: tailscale
      vars:
        tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
        tailscale_accept_routes: true
        tailscale_ssh: true
```

## 📚 Table of Contents

- [Features](#-features)
- [Roles](#-roles)
- [Installation](#-installation)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Testing](#-testing)
- [Development](#-development)
- [Contributing](#-contributing)
- [Support](#-support)
- [License](#-license)

## ✨ Features

### 🚀 Core Capabilities

- **📦 Multiple Installation Methods**: Support for Go toolchain, binary download, or Homebrew installation
- **🌐 Advanced Network Configuration**: Support for exit nodes, route acceptance, DNS settings, and SSH
- **⚙️ Service Management**: Automatic service configuration and management
- **🔐 Flexible Authentication**: Support for auth keys, custom login servers, and self-hosted setups
- **✅ Comprehensive Validation**: System requirement checks and connectivity validation
- **🧪 Advanced Testing Framework**: Authentic macOS Docker testing with comprehensive validation
- **📊 Monitoring & Logging**: Visual monitoring, screenshot capture, and log analysis
- **🔄 CI/CD Integration**: GitHub Actions workflows for automated testing

### 🎯 Use Cases

- **Enterprise Deployments**: Standardized Tailscale deployment across macOS fleets
- **Development Environments**: Quick setup for development teams with consistent configurations
- **Self-Hosted Networks**: Support for Headscale and custom control plane setups
- **Automated Workflows**: Integration with CI/CD pipelines for infrastructure as code
- **Security Auditing**: Automated validation and compliance checking

## 🎭 Roles

### tailscale

Install and configure Tailscale VPN on macOS systems.

**Key Capabilities:**
- Multiple installation methods (Go, binary, Homebrew)
- Advanced networking and routing configuration
- Service lifecycle management
- Authentication and authorization setup
- Health monitoring and validation

## 🛠️ Installation

### Prerequisites

#### System Requirements

- **macOS 10.15 (Catalina) or later**
- **Ansible 2.15 or later**
- **Python 3.8 or later**
- **Administrator privileges** (for system-level operations)

#### Installation Dependencies

Choose **one** of the following based on your preferred installation method:

| Method | Dependencies | Use Case |
|--------|-------------|----------|
| **Go** | Go toolchain (1.19+) | Latest version, custom builds |
| **Binary** | Internet access | Quick installation, no dependencies |
| **Homebrew** | Homebrew package manager | Package management integration |

### Collection Installation

#### From Ansible Galaxy (Recommended)

```bash
# Install the latest version
ansible-galaxy collection install kaitranntt.mac

# Install specific version
ansible-galaxy collection install kaitranntt.mac==1.0.0
```

#### From Source

```bash
# Clone the repository
git clone https://github.com/kaitranntt/ansible-collection-mac.git
cd ansible-collection-mac

# Install from local source
ansible-galaxy collection install .

# Build for distribution
ansible-galaxy collection build .
```

### Workspace Integration

This collection is part of a larger multi-project workspace:

```bash
# Clone the full workspace (includes this collection as submodule)
git clone --recurse-submodules https://github.com/kaitranntt/PersonalOpenSource.git
cd PersonalOpenSource

# Navigate to this collection
cd apps/ansible-collection-mac

# Make changes and commit to the collection repository
git add .
git commit -m "feat: add new feature"
git push origin main

# Update the workspace submodule reference
cd ../..
git add apps/ansible-collection-mac
git commit -m "Update ansible-collection-mac to latest commit"
git push origin main
```

## 📖 Usage

### Quick Start Examples

#### Basic Installation

```yaml
---
- name: Install Tailscale on macOS
  hosts: macos
  collections:
    - kaitranntt.mac
  tasks:
    - name: Include Tailscale role
      include_role:
        name: tailscale
      vars:
        tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
```

#### Advanced Configuration

```yaml
---
- name: Configure Tailscale with custom settings
  hosts: macos
  collections:
    - kaitranntt.mac
  tasks:
    - name: Include Tailscale role
      include_role:
        name: tailscale
      vars:
        tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
        tailscale_accept_routes: true
        tailscale_accept_dns: false
        tailscale_ssh: true
        tailscale_exit_node: "exit-node.example.com"
        tailscale_installation_method: "homebrew"
        tailscale_log_level: "debug"
```

#### Self-Hosted Setup (Headscale)

```yaml
---
- name: Install Tailscale with Headscale
  hosts: macos
  collections:
    - kaitranntt.mac
  tasks:
    - name: Include Tailscale role
      include_role:
        name: tailscale
      vars:
        tailscale_auth_key: "{{ vault_headscale_auth_key }}"
        tailscale_login_server: "https://headscale.example.com"
        tailscale_hostname: "mac-prod-01"
        tailscale_installation_method: "binary"
```

#### Complete Setup with Validation

```yaml
---
- name: Complete Tailscale setup on macOS
  hosts: macos
  become: true
  collections:
    - kaitranntt.mac
  tasks:
    - name: Ensure Tailscale is installed and configured
      include_role:
        name: tailscale
      vars:
        tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
        tailscale_accept_routes: true
        tailscale_ssh: true
        tailscale_log_level: "info"
        tailscale_create_directories: true

    - name: Verify Tailscale status
      command: "{{ tailscale_binary_path }} status"
      register: tailscale_status

    - name: Display Tailscale status
      debug:
        var: tailscale_status.stdout_lines

    - name: Test network connectivity
      uri:
        url: "https://tailscale.com"
        method: GET
      register: connectivity_test
      failed_when: false

    - name: Report connectivity status
      debug:
        msg: "Network connectivity: {{ 'OK' if connectivity_test.status == 200 else 'FAILED' }}"
```

#### Removal

```yaml
---
- name: Remove Tailscale from macOS
  hosts: macos
  collections:
    - kaitranntt.mac
  tasks:
    - name: Remove Tailscale
      include_role:
        name: tailscale
      vars:
        tailscale_state: "absent"
```

### Using Tags for Targeted Execution

```bash
# Run only prerequisites and installation
ansible-playbook playbook.yml --tags "prerequisites,install"

# Run only configuration tasks
ansible-playbook playbook.yml --tags "configure"

# Run validation and connectivity checks
ansible-playbook playbook.yml --tags "validation,connectivity"
```

## ⚙️ Configuration

### Role Variables

The `tailscale` role supports extensive configuration options:

#### Core Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_version` | `"latest"` | Tailscale version to install |
| `tailscale_installation_method` | `"go"` | Installation method: `go`, `binary`, `homebrew` |
| `tailscale_state` | `"present"` | State: `present`, `absent` |
| `tailscale_auth_key` | `""` | Tailscale authentication key |

#### Network Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_accept_routes` | `true` | Accept subnet routes |
| `tailscale_accept_dns` | `false` | Accept DNS settings |
| `tailscale_advertise_tags` | `[]` | Tags to advertise |
| `tailscale_exit_node` | `""` | Exit node identifier |
| `tailscale_exit_node_allow_lan_access` | `false` | Allow LAN access when using exit node |
| `tailscale_ssh` | `false` | Enable Tailscale SSH |

#### Service Management

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_start_service` | `true` | Start Tailscale service |
| `tailscale_enable_service` | `true` | Enable service at boot |
| `tailscale_auto_start` | `true` | Auto-start service |
| `tailscale_log_level` | `"info"` | Log level: `debug`, `info`, `warn`, `error` |
| `tailscale_hostname` | `"{{ ansible_hostname }}"` | Hostname for Tailscale |
| `tailscale_user` | `"_tailscale"` | User account for service |

#### Advanced Options

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_auth_timeout` | `30` | Authentication timeout in seconds |
| `tailscale_login_server` | `""` | Custom login server for self-hosted setups |
| `tailscale_control_plane` | `""` | Custom control plane URL |
| `tailscale_args` | `[]` | Additional CLI arguments |
| `tailscale_update` | `true` | Update if already installed |
| `tailscale_force_update` | `false` | Force update even if same version |
| `tailscale_force_restart` | `false` | Force restart service |
| `tailscale_timeout` | `60` | Operation timeout in seconds |
| `tailscale_create_directories` | `true` | Create necessary directories |
| `tailscale_manage_firewall` | `false` | Manage firewall rules |
| `tailscale_backup_existing` | `true` | Backup existing installation |

#### Installation Method Details

**Go Method** (Default)
- Builds Tailscale from source using Go toolchain
- Requires Go to be installed on the target system
- Provides the latest version with full customization

**Binary Method**
- Downloads pre-compiled Tailscale binaries
- No additional dependencies required
- Fastest installation method

**Homebrew Method**
- Installs Tailscale via Homebrew package manager
- Requires Homebrew to be installed
- Easiest for systems already using Homebrew

### Role Tags

The role supports the following tags for targeted execution:

| Tag | Description |
|-----|-------------|
| `prerequisites` | Run system validation and dependency checks |
| `install` | Install Tailscale binaries |
| `configure` | Configure Tailscale settings |
| `service` | Manage Tailscale service |
| `remove` | Remove Tailscale installation |
| `validation` | Run validation checks only |
| `connectivity` | Check network connectivity |
| `version_check` | Check current version |

**Example using tags:**

```bash
ansible-playbook playbook.yml --tags "prerequisites,install"
```

#### Dependencies

- `community.general` collection for certain system operations

## 🧪 Testing

This collection includes comprehensive testing capabilities for validation:

### Standard Molecule Tests

```bash
cd tests/molecule/tailscale
molecule test
```

### macOS Docker Testing Framework

This collection features an advanced **macOS Docker Testing Framework** that provides authentic macOS testing environments using dockur/macos containers. This replaces traditional Ubuntu-based testing with real macOS environments for more accurate validation.

#### Quick Start with macOS Testing

```bash
# Check system requirements
make check-macos-requirements

# Run basic macOS tests
make test-macos

# Run all macOS test scenarios
make test-macos-all

# Collect and analyze test logs
make test-macos-logs
```

#### Available Test Scenarios

- **Installation Methods**: Go, binary, and Homebrew installation testing
- **Network Configuration**: Advanced networking and DNS settings
- **Configuration Matrix**: Multiple configuration combinations
- **Error Scenarios**: Robustness and failure testing
- **Visual Monitoring**: Screenshot capture and progress tracking

#### Key Features

- 🍎 **Authentic macOS Environment**: Real macOS containers for accurate testing
- 📊 **Comprehensive Logging**: Automated log collection and analysis
- 🖼️ **Visual Monitoring**: Screenshot capture and progress tracking
- ⚡ **CI/CD Integration**: GitHub Actions workflows for automated testing
- 🔧 **Flexible Configuration**: Support for different installation methods and settings

#### Manual Container Management

```bash
# Start a macOS container
./scripts/start-macos-container.sh

# Check container status
./scripts/check-macos-status.sh

# Capture screenshots
./scripts/capture-screenshot.sh --name "test"

# Collect logs
./scripts/collect-test-logs.sh

# Stop container
./scripts/stop-macos-container.sh
```

#### Available Makefile Targets for macOS Testing

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

**For detailed information, see [docs/macos-docker-testing.md](docs/macos-docker-testing.md)**

## 👨‍💻 Development

### Setting up Development Environment

#### Option 1: Using DevContainer (Recommended)

This project provides a complete macOS development environment using DevContainers with the authentic `dockur/macos` base image.

**Prerequisites:**
- Docker Desktop or Docker Engine
- VS Code with Remote - Containers extension
- 4GB+ RAM available for Docker

**Quick Start:**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kaitranntt/ansible-collection-mac.git
   cd ansible-collection-mac
   ```

2. **Open in VS Code:**
   ```bash
   code .
   ```

3. **Reopen in Container:**
   - When VS Code opens, click "Reopen in Container" when prompted
   - Or press `F1` and select "Remote-Containers: Reopen in Container"

4. **Wait for setup completion:**
   - The DevContainer will automatically build and install all dependencies
   - This includes Xcode tools, Homebrew, Ansible, Go, Molecule, and development tools

#### Option 2: Local Development Setup

**Prerequisites:**
- macOS 10.15 (Catalina) or later
- Python 3.8+
- Ansible
- Molecule
- Git

**Setup:**

```bash
# Clone standalone (for direct contribution)
git clone https://github.com/kaitranntt/ansible-collection-mac.git
cd ansible-collection-mac
pip install -r requirements-dev.txt
pre-commit install

# Or work within workspace (recommended)
git clone --recurse-submodules https://github.com/kaitranntt/PersonalOpenSource.git
cd PersonalOpenSource/apps/ansible-collection-mac
```

### Running Tests

**In DevContainer:**

```bash
# Run all tests
make test

# Run specific tests
make lint
molecule test

# Quick development cycle
make quick-test
```

**Local Development:**

```bash
# Run linting
ansible-lint

# Run molecule tests
molecule test

# Run full test suite
make test
```

### Building Collection

```bash
ansible-galaxy collection build .
```

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Getting Started

1. **Fork the repository** on GitHub
2. **Create a feature branch** for your contribution
3. **Make your changes** following our coding standards
4. **Test your changes** thoroughly
5. **Submit a pull request** with a clear description

### Development Guidelines

- **Follow existing code style** and conventions
- **Add tests** for new functionality
- **Update documentation** for any changes
- **Ensure all tests pass** before submitting
- **Use meaningful commit messages**

### Code Quality

- Run `make lint` to check code quality
- Use `make test` to run all tests
- Follow Ansible best practices and conventions

### Submitting Changes

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add some amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

## 🆘 Support

### Getting Help

- **Check the [GitHub Issues](https://github.com/kaitranntt/ansible-collection-mac/issues)** for known problems
- **Review [Tailscale Documentation](https://tailscale.com/kb/)** for official guidance
- **Enable debug mode** and review system logs for detailed error information

### Troubleshooting

**Common Issues and Solutions**

#### Installation Issues

*Installation fails with permission errors*
```yaml
- Ensure proper sudo access for the target user
- Check if the installation directory is writable
- Verify Go toolchain is properly installed (for go method)
```

*Service fails to start*
```yaml
- Check system logs: `tail -f /var/log/system.log`
- Verify binary permissions: `ls -la /usr/local/bin/tailscale`
- Check configuration file syntax
- Ensure the _tailscale user exists
```

#### Authentication Issues

*Authentication timeouts*
```yaml
- Increase `tailscale_auth_timeout` value
- Verify network connectivity to Tailscale control plane
- Check if auth key is valid and not expired
- Verify custom login server URL is accessible
```

#### Connectivity Issues

*Connectivity issues after installation*
```yaml
- Check Tailscale status: `tailscale status`
- Verify firewall settings allow Tailscale traffic
- Check if exit node is properly configured
- Verify DNS settings if using custom DNS
```

### Debug Mode

Enable debug logging for troubleshooting:

```yaml
tailscale_log_level: "debug"
tailscale_args:
  - "--debug"
```

### Reporting Issues

When reporting issues, please include:

- **macOS version** and system information
- **Ansible version** and collection version
- **Complete error messages** and logs
- **Minimal reproduction case** with playbook
- **Steps to reproduce** the issue

## 📄 License

This collection is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 👤 Author

- **Kai Tran (@kaitrantt)**

## 📋 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

---

<div align="center">

**[⬆ Back to top](#kaitrannttmac-ansible-collection)**

Made with ❤️ for the Ansible and Tailscale communities

</div>
