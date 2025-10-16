# GitHub Codespaces Setup

This repository supports GitHub Codespaces for cloud-based development with a complete macOS development environment.

## Quick Start

1. **Create a Codespace:**
   - Navigate to this repository on GitHub
   - Click "Code" → "Codespaces" → "Create codespace on main"
   - Wait for the environment to build (2-5 minutes)

2. **Start Development:**
   - The VS Code web interface will open automatically
   - All development tools are pre-installed and configured
   - Your repository code is already available in `/workspaces`

## Features

### Development Environment
- **macOS Container**: Authentic dockur/macos base image
- **Pre-installed Tools**: Xcode CLI, Homebrew, Ansible, Go, Molecule
- **VS Code Extensions**: Ansible, YAML, Python, Git, Docker integration
- **4 vCPU, 8GB RAM**: Standard compute resources
- **32GB Storage**: Persistent disk space

### Available Commands
```bash
# Run tests
make test

# Lint code
make lint

# Build collection
make build

# Check environment
make devcontainer-status
```

### Persistent Storage
- `/workspaces`: Your repository code
- `/root`: Home directory with configurations
- `/opt/homebrew`: Homebrew installation
- `/usr/local/go`: Go installation

## Using the Codespace

### VS Code Web Interface
- Full VS Code experience in your browser
- Terminal access with Zsh shell
- Integrated Git operations
- Debugging support
- Extension marketplace

### SSH Access
```bash
# SSH into your codespace from local terminal
gh codespace ssh --select <codespace-name>

# Or use VS Code Desktop
gh codespace code --select <codespace-name>
```

### Port Forwarding
- Port 22: SSH access
- Port 8080: Web applications
- Port 41641: Tailscale (auto-forwarded)

## Customization

### Environment Variables
The Codespace automatically sets these environment variables:
```bash
export ANSIBLE_INVENTORY=./inventory
export ANSIBLE_HOST_KEY_CHECKING=False
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin:$HOME/.local/bin
```

### Secrets
You can configure these secrets in your repository settings:
- `GALAXY_API_KEY`: For publishing to Ansible Galaxy
- `TAILSCALE_AUTH_KEY`: For testing Tailscale functionality

### Custom Scripts
You can add custom setup scripts to `.devcontainer/post-create.sh` for additional configuration.

## Best Practices

### Performance
- Save work frequently to auto-sync changes
- Use the browser's native VS Code interface for best performance
- Close browser tabs when not actively working

### Security
- Don't store sensitive data in your codespace
- Use repository secrets for API keys and credentials
- Remember to stop codespaces when finished to avoid charges

### Collaboration
- Share codespace URLs with team members for collaboration
- Use the built-in commenting features for code review
- Leverage the integrated terminal for pair programming

## Limitations

- **Resource Limits**: 4 vCPU, 8GB RAM, 32GB storage
- **Timeout**: Codespaces stop after 30 minutes of inactivity
- **Network**: Some network restrictions apply
- **Storage**: Persistent storage is limited to 32GB

## Troubleshooting

### Common Issues

**Codespace won't start**
```bash
# Check codespace status
gh codespace list

# Delete and recreate if needed
gh codespace delete <codespace-name>
```

**Build fails**
```bash
# Check build logs
gh codespace logs --follow <codespace-name>

# Recreate with clean state
gh codespace delete <codespace-name>
```

**Performance issues**
- Restart the codespace
- Check resource usage in VS Code
- Close unused browser tabs

**Access issues**
- Ensure you have repository access
- Check your GitHub authentication
- Verify network connectivity

### Getting Help
- [GitHub Codespaces documentation](https://docs.github.com/en/codespaces)
- [VS Code in the browser documentation](https://code.visualstudio.com/docs/editor/browser)
- Open an issue in this repository

## Cost Management

- **Free Tier**: 60 hours of usage per month (varies by plan)
- **Storage**: Included with repository
- **Compute**: Charged by the minute when active
- **Network**: Free within GitHub network

**Tips to minimize costs:**
- Stop codespaces when not in use
- Use the auto-timeout feature
- Monitor usage in your GitHub settings
- Delete unused codespaces

## Advanced Usage

### Docker Integration
```bash
# Test with Docker containers
docker run --rm alpine:latest echo "Hello from Docker"

# Build custom images
docker build -t my-image .
```

### Custom Extensions
Add your preferred VS Code extensions to `.devcontainer/devcontainer.json`:
```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "your.extension.here"
      ]
    }
  }
}
```

### Multiple Environments
Create multiple DevContainer configurations for different testing scenarios:
- `.devcontainer/devcontainer.json` (default)
- `.devcontainer/docker-compose.yml` (multi-container)
- `.devcontainer/test-environment.json` (testing only)