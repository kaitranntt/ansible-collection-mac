# kaitranntt.mac Ansible Collection

This Ansible collection provides roles and modules for managing macOS systems, with a focus on Tailscale VPN installation and configuration.

## Installation

### From Ansible Galaxy

```bash
ansible-galaxy collection install kaitranntt.mac
```

### From Source

```bash
git clone https://github.com/kaitranntt/ansible-collection-mac.git
cd ansible-collection-mac
ansible-galaxy collection install .
```

## Available Roles

### tailscale

Install and configure Tailscale VPN on macOS systems.

#### Features

- **Multiple Installation Methods**: Support for Go toolchain, binary download, or Homebrew installation
- **Advanced Network Configuration**: Support for exit nodes, route acceptance, DNS settings, and SSH
- **Service Management**: Automatic service configuration and management
- **Flexible Authentication**: Support for auth keys, custom login servers, and self-hosted setups
- **Comprehensive Validation**: System requirement checks and connectivity validation

#### Requirements

- macOS 10.15 (Catalina) or later
- One of the following for installation:
  - Go toolchain (for Go-based installation)
  - Homebrew (for Homebrew-based installation)
  - Internet access (for binary download)

#### Role Variables

Available variables are documented in the table below:

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_version` | `"latest"` | Tailscale version to install |
| `tailscale_installation_method` | `"go"` | Installation method: `go`, `binary`, `homebrew` |
| `tailscale_state` | `"present"` | State: `present`, `absent` |
| `tailscale_auth_key` | `""` | Tailscale authentication key |
| `tailscale_auth_timeout` | `30` | Authentication timeout in seconds |
| `tailscale_login_server` | `""` | Custom login server for self-hosted setups |
| `tailscale_control_plane` | `""` | Custom control plane URL |
| `tailscale_accept_routes` | `true` | Accept subnet routes |
| `tailscale_accept_dns` | `false` | Accept DNS settings |
| `tailscale_advertise_tags` | `[]` | Tags to advertise |
| `tailscale_exit_node` | `""` | Exit node identifier |
| `tailscale_exit_node_allow_lan_access` | `false` | Allow LAN access when using exit node |
| `tailscale_ssh` | `false` | Enable Tailscale SSH |
| `tailscale_args` | `[]` | Additional CLI arguments |
| `tailscale_start_service` | `true` | Start Tailscale service |
| `tailscale_enable_service` | `true` | Enable service at boot |
| `tailscale_auto_start` | `true` | Auto-start service |
| `tailscale_log_level` | `"info"` | Log level: `debug`, `info`, `warn`, `error` |
| `tailscale_hostname` | `"{{ ansible_hostname }}"` | Hostname for Tailscale |
| `tailscale_user` | `"_tailscale"` | User account for service |
| `tailscale_update` | `true` | Update if already installed |
| `tailscale_force_update` | `false` | Force update even if same version |
| `tailscale_force_restart` | `false` | Force restart service |
| `tailscale_timeout` | `60` | Operation timeout in seconds |
| `tailscale_create_directories` | `true` | Create necessary directories |
| `tailscale_manage_firewall` | `false` | Manage firewall rules |
| `tailscale_backup_existing` | `true` | Backup existing installation |

#### Example Playbooks

**Basic Installation**

```yaml
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

**Advanced Configuration**

```yaml
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

**Self-Hosted Setup (Headscale)**

```yaml
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

**Complete Setup Example**

```yaml
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
```

**Removal**

```yaml
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

#### Tags

The role supports the following tags for targeted execution:

- `prerequisites` - Run system validation and dependency checks
- `install` - Install Tailscale binaries
- `configure` - Configure Tailscale settings
- `service` - Manage Tailscale service
- `remove` - Remove Tailscale installation
- `validation` - Run validation checks only
- `connectivity` - Check network connectivity
- `version_check` - Check current version

Example using tags:

```bash
ansible-playbook playbook.yml --tags "prerequisites,install"
```

#### Dependencies

- `community.general` collection for certain system operations

#### Testing

This collection includes Molecule tests for validation:

```bash
cd tests/molecule/tailscale
molecule test
```

#### Troubleshooting

**Common Issues and Solutions**

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

*Authentication timeouts*
```yaml
- Increase `tailscale_auth_timeout` value
- Verify network connectivity to Tailscale control plane
- Check if auth key is valid and not expired
- Verify custom login server URL is accessible
```

*Connectivity issues after installation*
```yaml
- Check Tailscale status: `tailscale status`
- Verify firewall settings allow Tailscale traffic
- Check if exit node is properly configured
- Verify DNS settings if using custom DNS
```

**Debug Mode**

Enable debug logging for troubleshooting:

```yaml
tailscale_log_level: "debug"
tailscale_args:
  - "--debug"
```

**Getting Help**

- Check the [GitHub Issues](https://github.com/kaitranntt/ansible-collection-mac/issues) for known problems
- Review [Tailscale Documentation](https://tailscale.com/kb/) for official guidance
- Enable debug mode and review system logs for detailed error information

## Workspace Integration

This collection is part of a larger multi-project workspace. When working within the workspace context:

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

### Using the Collection from Workspace

When using this collection from within the workspace:

```bash
# Install from the workspace
cd apps/ansible-collection-mac
ansible-galaxy collection install . --force

# Or use directly in playbooks with relative path
ansible-playbook -i inventory playbook.yml \
  --collections-path ./apps/ansible-collection-mac
```

## Development

### Setting up Development Environment

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

## Contributing

Feel free to open issues for bug reports or feature requests. Pull requests are welcome!

## License

This collection is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- Kai Tran (@kaitrantt)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.