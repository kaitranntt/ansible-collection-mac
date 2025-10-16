# Tailscale Role for macOS

This Ansible role installs and configures Tailscale on macOS systems. It handles the complete lifecycle including installation, configuration, service management, and removal.

## Requirements

- macOS 11.0 (Big Sur) or later
- Ansible 2.12.0 or later
- Administrative privileges (sudo access)
- Internet connection for Tailscale installation

## Role Variables

### Main Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_version` | `"latest"` | Tailscale version to install (`"latest"` or specific version like `"1.58.2"`) |
| `tailscale_state` | `"present"` | State of Tailscale installation (`"present"` or `"absent"`) |
| `tailscale_auth_key` | `""` | Tailscale authentication key (optional) |
| `tailscale_args` | `[]` | Additional arguments for Tailscale daemon (array) |
| `tailscale_login_server` | `""` | Custom login server for self-hosted setups (optional) |
| `tailscale_start_service` | `true` | Whether to start Tailscale service |
| `tailscale_enable_service` | `true` | Whether to enable Tailscale service at boot |
| `tailscale_update` | `true` | Whether to update Tailscale if already installed |
| `tailscale_force_restart` | `false` | Force restart of Tailscale service |

### Advanced Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `tailscale_user` | `"_tailscale"` | User account for running Tailscale service |
| `tailscale_timeout` | `60` | Timeout for Tailscale operations (in seconds) |
| `tailscale_base_url` | `"https://pkgs.tailscale.com/stable/"` | Base URL for Tailscale downloads |

## Dependencies

None. This role is self-contained and handles all dependencies.

## Example Playbooks

### Basic Installation

```yaml
---
- name: Install Tailscale on macOS
  hosts: macos_hosts
  become: yes
  collections:
    - kaitranntt.mac

  tasks:
    - name: Install Tailscale
      include_role:
        name: tailscale
```

### Installation with Authentication

```yaml
---
- name: Install and configure Tailscale with authentication
  hosts: macos_hosts
  become: yes
  collections:
    - kaitranntt.mac

  vars:
    tailscale_auth_key: "{{ vault_tailscale_auth_key }}"

  tasks:
    - name: Install and configure Tailscale
      include_role:
        name: tailscale
```

### Advanced Configuration

```yaml
---
- name: Advanced Tailscale configuration
  hosts: macos_hosts
  become: yes
  collections:
    - kaitranntt.mac

  vars:
    tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
    tailscale_args:
      - "--accept-dns=false"
      - "--accept-routes"
      - "--exit-node=exit-node.example.com"
      - "--operator={{ ansible_user }}"
    tailscale_login_server: "https://headscale.example.com"

  tasks:
    - name: Configure Tailscale with advanced settings
      include_role:
        name: tailscale
```

### Self-Hosted Setup

```yaml
---
- name: Install Tailscale with self-hosted control server
  hosts: macos_hosts
  become: yes
  collections:
    - kaitranntt.mac

  vars:
    tailscale_login_server: "https://control.example.com"
    tailscale_args:
      - "--accept-dns=true"
      - "--accept-routes"

  tasks:
    - name: Install Tailscale for self-hosted setup
      include_role:
        name: tailscale
```

### Removal

```yaml
---
- name: Remove Tailscale from macOS
  hosts: macos_hosts
  become: yes
  collections:
    - kaitranntt.mac

  vars:
    tailscale_state: "absent"

  tasks:
    - name: Remove Tailscale
      include_role:
        name: tailscale
```

## Configuration Details

### Authentication

The role supports multiple authentication methods:

1. **Auth Key**: Provide `tailscale_auth_key` variable for automatic authentication
2. **Manual Login**: Leave `tailscale_auth_key` empty and log in manually after installation
3. **Self-Hosted**: Use `tailscale_login_server` for custom control servers

### Service Management

- The role installs Tailscale as a LaunchDaemon (system service)
- Service automatically starts at boot if `tailscale_enable_service: true`
- Service can be controlled with standard `launchctl` commands

### Network Configuration

Common `tailscale_args` options:

- `--accept-dns=false` - Don't use Tailscale DNS
- `--accept-routes` - Accept subnet routes from other nodes
- `--exit-node=<node>` - Use specific node as exit node
- `--operator=<user>` - Set operator user
- `--advertise-routes=<routes>` - Advertise local subnet routes

## Security Considerations

- Store authentication keys in Ansible Vault
- Use least privilege principle for auth keys
- Consider network segmentation with subnet routes
- Review DNS settings based on security requirements

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure running with `become: yes`
2. **Network Timeout**: Increase `tailscale_timeout` for slow connections
3. **Authentication Failed**: Verify auth key and login server settings
4. **Service Not Starting**: Check system logs with `log show --predicate 'process == "tailscaled"'`

### Debug Commands

```bash
# Check Tailscale version
tailscale version

# Check service status
launchctl list | grep tailscale

# Check connectivity
tailscale status

# View logs
log show --predicate 'process == "tailscaled"' --last 1h
```

## License

MIT License - see the [LICENSE](../../../LICENSE) file for details.

## Author

Tam Nhu (Kai) Tran - [kaitran.ntt@gmail.com](mailto:kaitran.ntt@gmail.com)
