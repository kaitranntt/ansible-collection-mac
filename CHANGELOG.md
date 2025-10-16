# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-10-16

### Added
- Complete macOS DevContainer support with dockur/macos base image
- Pre-configured VS Code development environment with Ansible extensions
- GitHub Codespaces compatibility and configuration
- Automated development environment setup script
- Comprehensive Makefile targets for DevContainer management
- VS Code workspace settings and debugging configurations
- DevContainer validation and testing scripts

### Features
- Authentic macOS development environment in containers
- Pre-installed development tools (Xcode CLI, Homebrew, Ansible, Go, Molecule)
- One-click development environment setup
- Persistent workspace with Git integration
- Docker-in-Docker support for testing
- Automated dependency installation and configuration

### Development
- VS Code extensions pre-configured for Ansible development
- Debugging configurations for playbooks and roles
- Integrated terminal with optimized shell configuration
- Task runner for common development operations
- Workspace settings for YAML, Python, and Ansible development

### Documentation
- Comprehensive DevContainer setup guide
- GitHub Codespaces usage instructions
- Troubleshooting section for common container issues
- Updated README with container-based development workflow
- Development environment best practices

### Infrastructure
- DevContainer configuration with proper security settings
- GitHub Codespaces configuration with resource management
- Automated setup scripts for development dependencies
- Container testing and validation framework

## [1.0.0] - 2024-10-15

### Added
- Initial release of kaitranntt.mac collection
- Complete Tailscale role for macOS
- Support for macOS 11.0 through 15.2
- Professional Ansible Galaxy compliance
- Comprehensive documentation and examples
- Molecule testing framework
- MIT License

### Features
- Tailscale installation and configuration
- Custom login server support
- Service management (start/stop/enable)
- Authentication key handling
- Flexible configuration options
- Idempotent operations

### Documentation
- Complete README with usage examples
- Role-specific documentation
- Example playbooks
- Development setup guide
- Contributing guidelines

### Testing
- Molecule test scenarios
- Installation testing
- Cleanup testing
- Idempotence verification

### Supported Platforms
- macOS 11.0 (Big Sur) and later
- Tested on Intel and Apple Silicon Macs