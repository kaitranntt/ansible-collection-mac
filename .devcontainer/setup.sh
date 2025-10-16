#!/bin/bash

# Setup script for macOS DevContainer
# This script installs all necessary development dependencies in the dockur/macos container

set -e

echo "🍎 Setting up macOS development environment..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Xcode command line tools
install_xcode_tools() {
    echo "📦 Installing Xcode command line tools..."
    xcode-select --install || echo "Xcode tools already installed or installation in progress"

    # Wait for installation to complete
    while ! command_exists xcode-select; do
        echo "⏳ Waiting for Xcode tools installation..."
        sleep 5
    done
    echo "✅ Xcode command line tools installed"
}

# Function to install Homebrew
install_homebrew() {
    if ! command_exists brew; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        echo "✅ Homebrew installed"
    else
        echo "✅ Homebrew already installed"
    fi
}

# Function to install Python and pip
install_python() {
    echo "🐍 Installing Python and pip..."

    # Install Python 3 via Homebrew if not available
    if ! command_exists python3; then
        brew install python@3.11
    fi

    # Upgrade pip
    python3 -m pip install --upgrade pip
    echo "✅ Python and pip installed"
}

# Function to install Ansible and related tools
install_ansible() {
    echo "🔧 Installing Ansible and related tools..."

    python3 -m pip install --user ansible
    python3 -m pip install --user ansible-lint
    python3 -m pip install --user molecule molecule-plugins[docker]
    python3 -m pip install --user ansible-compat

    echo "✅ Ansible tools installed"
}

# Function to install Go
install_go() {
    echo "🐹 Installing Go..."

    if ! command_exists go; then
        brew install go

        # Set up Go environment
        echo 'export GOPATH=$HOME/go' >> ~/.zshrc
        echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> ~/.zshrc
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    else
        echo "✅ Go already installed"
    fi
}

# Function to install additional development tools
install_dev_tools() {
    echo "🛠️ Installing additional development tools..."

    # Install essential tools
    brew install git curl wget vim nano

    # Install additional useful tools
    brew install tree htop jq yq

    # Install pre-commit
    python3 -m pip install --user pre-commit

    echo "✅ Development tools installed"
}

# Function to setup development environment
setup_dev_environment() {
    echo "⚙️ Setting up development environment..."

    # Create development directories
    mkdir -p ~/go/bin ~/Development

    # Set up shell configuration
    cat >> ~/.zshrc << 'EOF'

# macOS DevContainer Environment
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin:$HOME/.local/bin
export EDITOR=vim

# Ansible development
export ANSIBLE_INVENTORY=./inventory
export ANSIBLE_HOST_KEY_CHECKING=False

# Enable colors in terminal
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Custom prompt
autoload -U promptinit; promptinit
prompt adam1

EOF

    echo "✅ Development environment configured"
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."

    local tools=("python3" "pip3" "ansible" "ansible-lint" "molecule" "go" "brew" "git")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            echo "✅ $tool is available"
        else
            echo "❌ $tool is missing"
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -eq 0 ]; then
        echo "🎉 All tools installed successfully!"
    else
        echo "⚠️ Some tools are missing: ${missing_tools[*]}"
        exit 1
    fi
}

# Main execution
main() {
    echo "🚀 Starting macOS DevContainer setup..."

    install_xcode_tools
    install_homebrew
    install_python
    install_ansible
    install_go
    install_dev_tools
    setup_dev_environment
    verify_installation

    echo "🎉 macOS DevContainer setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open a new terminal or run: source ~/.zshrc"
    echo "   2. Run 'make test' to verify the Ansible collection"
    echo "   3. Start developing with: make devcontainer-shell"
}

# Run main function
main "$@"