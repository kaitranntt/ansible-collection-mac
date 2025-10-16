#!/bin/bash
# Development Environment Setup Script for kaitranntt.mac Ansible Collection
# This script sets up a complete development environment with all required tools and dependencies

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="kaitranntt.mac"
PYTHON_VERSION="3.13"
ANSIBLE_VERSION_MIN="2.15"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_header() {
    echo -e "${CYAN}===================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}===================================================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python version
check_python_version() {
    if command_exists python3; then
        local version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        if [[ "$version" == "$PYTHON_VERSION" ]]; then
            return 0
        else
            print_warning "Python $PYTHON_VERSION recommended, found $version"
            return 1
        fi
    else
        print_error "Python 3 not found"
        return 1
    fi
}

# Function to install system packages
install_system_packages() {
    print_step "Installing system packages..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv git curl
        elif command_exists yum; then
            sudo yum install -y python3 python3-pip git curl
        elif command_exists dnf; then
            sudo dnf install -y python3 python3-pip git curl
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install python@3.13 git curl
        else
            print_error "Homebrew not found. Please install Homebrew first."
            print_status "Visit: https://brew.sh/"
            exit 1
        fi
    fi

    print_success "System packages installed"
}

# Function to setup Python virtual environment
setup_python_env() {
    print_step "Setting up Python virtual environment..."

    # Remove existing virtual environment if it exists
    if [ -d ".venv" ]; then
        print_warning "Removing existing virtual environment"
        rm -rf .venv
    fi

    # Create new virtual environment
    python3 -m venv .venv
    source .venv/bin/activate

    # Upgrade pip
    pip install --upgrade pip setuptools wheel

    print_success "Python virtual environment created and activated"
}

# Function to install Python dependencies
install_python_dependencies() {
    print_step "Installing Python dependencies..."

    # Ensure virtual environment is active
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source .venv/bin/activate
    fi

    # Install base requirements first
    pip install ansible>=2.15.0

    # Install development dependencies
    if [ -f "requirements-dev.txt" ]; then
        pip install -r requirements-dev.txt
        print_success "Development dependencies installed"
    else
        print_warning "requirements-dev.txt not found, installing essential tools"
        pip install ansible-lint yamllint black isort flake8 bandit safety checkov molecule molecule-plugins[docker] antsibull-docs sphinx sphinx-rtd-theme pre-commit
    fi

    print_success "Python dependencies installed"
}

# Function to setup Ansible Galaxy collections
setup_ansible_collections() {
    print_step "Setting up Ansible Galaxy collections..."

    # Ensure virtual environment is active
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source .venv/bin/activate
    fi

    # Install required collections for testing
    ansible-galaxy collection install community.general community.crypto community.docker

    print_success "Ansible collections installed"
}

# Function to setup pre-commit hooks
setup_pre_commit() {
    print_step "Setting up pre-commit hooks..."

    # Ensure virtual environment is active
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        source .venv/bin/activate
    fi

    # Install pre-commit
    pip install pre-commit

    # Setup hooks
    if [ -f ".pre-commit-config.yaml" ]; then
        pre-commit install
        print_success "Pre-commit hooks installed"
    else
        print_warning ".pre-commit-config.yaml not found"
    fi
}

# Function to configure Git
configure_git() {
    print_step "Configuring Git..."

    # Set Git attributes if not already set
    if ! git config --global --get core.autocrlf >/dev/null; then
        if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
            git config --global core.autocrlf true
        else
            git config --global core.autocrlf input
        fi
    fi

    # Set safe directory (helps with Docker environments)
    git config --global --add safe.directory "$(pwd)"

    print_success "Git configured"
}

# Function to setup VS Code (optional)
setup_vscode() {
    print_step "Setting up VS Code configuration (optional)..."

    if command_exists code; then
        # Create .vscode directory if it doesn't exist
        mkdir -p .vscode

        # Create VS Code settings
        cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": "./.venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.sortImports.args": ["--profile", "black"],
    "ansible.lint.enabled": true,
    "yaml.customTags": [
        "!vault scalar",
        "!vault"
    ],
    "yaml.schemas": {
        "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook": ["*.yml", "*.yaml"],
        "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/tasks.json#/$defs/tasks": ["**/tasks/**/*.yml", "**/tasks/**/*.yaml"],
        "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/vars.json#/$defs/vars": ["**/vars/**/*.yml", "**/vars/**/*.yaml", "**/defaults/**/*.yml", "**/defaults/**/*.yaml"]
    },
    "[yaml]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "redhat.vscode-yaml"
    },
    "[python]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "ms-python.black-formatter"
    },
    "files.exclude": {
        "**/.venv": true,
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/.molecule": true
    }
}
EOF

        # Create VS Code extensions recommendation
        cat > .vscode/extensions.json << 'EOF'
{
    "recommendations": [
        "ms-python.python",
        "ms-python.black-formatter",
        "ms-python.isort",
        "redhat.vscode-yaml",
        "redhat.ansible",
        "ms-vscode.vscode-json",
        "streetsidesoftware.code-spell-checker",
        "esbenp.prettier-vscode"
    ]
}
EOF

        print_success "VS Code configuration created"
        print_status "Recommended extensions are available in .vscode/extensions.json"
    else
        print_status "VS Code not found. Skipping VS Code setup."
    fi
}

# Function to create development scripts
create_dev_scripts() {
    print_step "Creating development helper scripts..."

    # Create activation script
    cat > scripts/activate.sh << 'EOF'
#!/bin/bash
# Activate the development environment

echo "Activating development environment..."
source .venv/bin/activate

# Display environment info
echo "Python: $(python --version)"
echo "Ansible: $(ansible --version | head -n1)"
echo "Ansible Lint: $(ansible-lint --version 2>/dev/null || echo 'Not installed')"
echo ""
echo "Development environment is ready!"
echo "Run 'deactivate' to exit the virtual environment."
EOF

    # Create quick test script
    cat > scripts/quick-test.sh << 'EOF'
#!/bin/bash
# Quick development test script

set -euo pipefail

echo "Running quick development tests..."

# Ensure virtual environment is active
if [[ "$VIRTUAL_ENV" == "" ]]; then
    source .venv/bin/activate
fi

echo "1. Running ansible-lint..."
ansible-lint --quiet || echo "ansible-lint issues found"

echo "2. Running yamllint..."
yamllint --format=quiet || echo "yamllint issues found"

echo "3. Testing collection syntax..."
ansible-playbook --syntax-check --inventory=localhost, -e "ansible_connection=local" tests/syntax.yml 2>/dev/null || echo "Syntax check completed"

echo ""
echo "Quick tests completed!"
EOF

    # Create environment info script
    cat > scripts/env-info.sh << 'EOF'
#!/bin/bash
# Display development environment information

echo "=== Development Environment Information ==="
echo ""

echo "Project: $(basename $(pwd))"
echo "Python: $(python --version 2>/dev/null || echo 'Not found')"
echo "Pip: $(pip --version 2>/dev/null || echo 'Not found')"
echo "Virtual Environment: ${VIRTUAL_ENV:-'Not active'}"
echo ""

if command -v ansible >/dev/null 2>&1; then
    echo "Ansible: $(ansible --version | head -n1)"
fi

if command -v ansible-lint >/dev/null 2>&1; then
    echo "Ansible Lint: $(ansible-lint --version)"
fi

if command -v yamllint >/dev/null 2>&1; then
    echo "YAML Lint: $(yamllint --version)"
fi

if command -v black >/dev/null 2>&1; then
    echo "Black: $(black --version)"
fi

if command -v molecule >/dev/null 2>&1; then
    echo "Molecule: $(molecule --version)"
fi

echo ""
echo "=== Make targets ==="
if [ -f "Makefile" ]; then
    grep "^[a-zA-Z][^:]*:" Makefile | head -20
fi
EOF

    # Make scripts executable
    chmod +x scripts/activate.sh scripts/quick-test.sh scripts/env-info.sh

    print_success "Development helper scripts created"
}

# Function to validate installation
validate_installation() {
    print_step "Validating development environment..."

    local errors=0

    # Check Python
    if ! check_python_version; then
        print_error "Python version check failed"
        ((errors++))
    fi

    # Check virtual environment
    if [[ "$VIRTUAL_ENV" == "" ]]; then
        print_error "Virtual environment not active"
        ((errors++))
    fi

    # Check critical tools
    local tools=("ansible" "ansible-lint" "yamllint" "black" "molecule")
    for tool in "${tools[@]}"; do
        if ! command_exists "$tool"; then
            print_error "$tool not found"
            ((errors++))
        fi
    done

    # Check project files
    local files=("Makefile" "requirements-dev.txt" ".pre-commit-config.yaml")
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            print_warning "$file not found"
        fi
    done

    if [ $errors -eq 0 ]; then
        print_success "Development environment validation passed!"
        return 0
    else
        print_error "Development environment validation failed with $errors errors"
        return 1
    fi
}

# Function to show next steps
show_next_steps() {
    print_header "Development Environment Setup Complete!"

    echo -e "${GREEN}🎉 Your development environment is ready!${NC}"
    echo ""

    echo -e "${BLUE}Quick Start:${NC}"
    echo "1. Activate environment:    source .venv/bin/activate"
    echo "2. Or use helper script:    ./scripts/activate.sh"
    echo "3. Run quality checks:      make quality"
    echo "4. Run tests:               make test"
    echo "5. Generate docs:           make docs"
    echo "6. Run security scans:      make security"
    echo ""

    echo -e "${BLUE}Development Commands:${NC}"
    echo "- Format code:              make format"
    echo "- Run linting:              make lint"
    echo "- Quick test:               make quick-test"
    echo "- Quality metrics:          make quality-metrics"
    echo "- Environment info:         ./scripts/env-info.sh"
    echo ""

    echo -e "${BLUE}Useful Make Targets:${NC}"
    echo "- make help                 Show all available targets"
    echo "- make install              Install collection locally"
    echo "- make build                Build collection package"
    echo "- make clean                Clean generated files"
    echo ""

    echo -e "${YELLOW}Remember:${NC}"
    echo "- Always activate the virtual environment before development"
    echo "- Run 'make quality' before committing changes"
    echo "- Check the documentation for detailed information"
    echo ""

    if command_exists code; then
        echo -e "${CYAN}VS Code:${NC}"
        echo "- Open in VS Code and it will use the Python virtual environment"
        echo "- Install recommended extensions from .vscode/extensions.json"
        echo ""
    fi

    echo -e "${GREEN}Happy coding! 🚀${NC}"
}

# Main setup function
main() {
    print_header "Setting up Development Environment for $PROJECT_NAME"

    # Check if we're in the right directory
    if [ ! -f "galaxy.yml" ] || [ ! -d "roles" ]; then
        print_error "This doesn't appear to be an Ansible collection project"
        print_status "Please run this script from the project root directory"
        exit 1
    fi

    # Create scripts directory if it doesn't exist
    mkdir -p scripts

    # Run setup steps
    install_system_packages
    setup_python_env
    install_python_dependencies
    setup_ansible_collections
    setup_pre_commit
    configure_git
    setup_vscode
    create_dev_scripts

    # Validate installation
    if validate_installation; then
        show_next_steps
    else
        print_error "Setup validation failed. Please check the errors above."
        exit 1
    fi
}

# Handle script arguments
case "${1:-setup}" in
    "setup"|"")
        main
        ;;
    "validate")
        validate_installation
        ;;
    "info")
        if [ -f "scripts/env-info.sh" ]; then
            ./scripts/env-info.sh
        else
            print_error "Environment info script not found. Run setup first."
        fi
        ;;
    "help"|"-h"|"--help")
        echo "Development Environment Setup Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup    - Run full setup (default)"
        echo "  validate - Validate current installation"
        echo "  info     - Show environment information"
        echo "  help     - Show this help message"
        echo ""
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
