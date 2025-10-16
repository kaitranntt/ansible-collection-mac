#!/bin/bash

# Test script for validating DevContainer functionality
# This script runs inside the DevContainer to verify all tools are working

set -e

echo "🍎 Testing macOS DevContainer functionality..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "FAIL")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️ $message${NC}"
            ;;
        "INFO")
            echo -e "ℹ️ $message"
            ;;
    esac
}

# Function to check if command exists
check_command() {
    local cmd=$1
    local description=$2

    if command -v "$cmd" >/dev/null 2>&1; then
        print_status "OK" "$description"
        return 0
    else
        print_status "FAIL" "$description"
        return 1
    fi
}

# Function to test specific functionality
test_functionality() {
    local test_name=$1
    local test_command=$2

    echo -e "\n🧪 Testing: $test_name"

    if eval "$test_command" >/dev/null 2>&1; then
        print_status "OK" "$test_name"
        return 0
    else
        print_status "FAIL" "$test_name"
        return 1
    fi
}

# Track overall success
total_tests=0
passed_tests=0

# Test basic commands
echo -e "\n🔍 Checking basic command availability..."

check_command "python3" "Python 3 interpreter" && ((passed_tests++))
((total_tests++))

check_command "pip3" "Python package manager" && ((passed_tests++))
((total_tests++))

check_command "ansible" "Ansible" && ((passed_tests++))
((total_tests++))

check_command "ansible-lint" "Ansible Lint" && ((passed_tests++))
((total_tests++))

check_command "molecule" "Molecule" && ((passed_tests++))
((total_tests++))

check_command "go" "Go programming language" && ((passed_tests++))
((total_tests++))

check_command "brew" "Homebrew package manager" && ((passed_tests++))
((total_tests++))

check_command "git" "Git version control" && ((passed_tests++))
((total_tests++))

check_command "xcode-select" "Xcode command line tools" && ((passed_tests++))
((total_tests++))

# Test functionality
echo -e "\n🧪 Testing functionality..."

test_functionality "Python version check" "python3 --version" && ((passed_tests++))
((total_tests++))

test_functionality "Ansible version check" "ansible --version" && ((passed_tests++))
((total_tests++))

test_functionality "Ansible connectivity test" "ansible localhost -m ping" && ((passed_tests++))
((total_tests++))

test_functionality "Go version check" "go version" && ((passed_tests++))
((total_tests++))

test_functionality "Homebrew update check" "brew --version" && ((passed_tests++))
((total_tests++))

# Test collection specific functionality
echo -e "\n🎯 Testing Ansible collection functionality..."

if [ -f "/workspaces/galaxy.yml" ]; then
    print_status "OK" "Galaxy configuration file found"
    ((passed_tests++))
else
    print_status "FAIL" "Galaxy configuration file not found"
fi
((total_tests++))

if [ -d "/workspaces/roles" ]; then
    print_status "OK" "Roles directory found"
    ((passed_tests++))
else
    print_status "FAIL" "Roles directory not found"
fi
((total_tests++))

if [ -f "/workspaces/roles/tailscale/tasks/main.yml" ]; then
    print_status "OK" "Tailscale role tasks found"
    ((passed_tests++))
else
    print_status "FAIL" "Tailscale role tasks not found"
fi
((total_tests++))

# Test environment variables
echo -e "\n🌍 Checking environment variables..."

[ -n "$ANSIBLE_HOST_KEY_CHECKING" ] && print_status "OK" "ANSIBLE_HOST_KEY_CHECKING set" && ((passed_tests++)) || print_status "WARN" "ANSIBLE_HOST_KEY_CHECKING not set"
((total_tests++))

[ -n "$GOPATH" ] && print_status "OK" "GOPATH set" && ((passed_tests++)) || print_status "WARN" "GOPATH not set"
((total_tests++))

# Test VS Code integration
echo -e "\n💻 Checking VS Code integration..."

if [ -n "$VSCODE_IPC_HOOK" ] || [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
    print_status "OK" "VS Code server running"
    ((passed_tests++))
else
    print_status "WARN" "VS Code server not detected"
fi
((total_tests++))

# Test Docker availability (if applicable)
echo -e "\n🐳 Checking Docker availability..."

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        print_status "OK" "Docker daemon accessible"
        ((passed_tests++))
    else
        print_status "WARN" "Docker command found but daemon not accessible"
    fi
else
    print_status "WARN" "Docker not available"
fi
((total_tests++))

# Test file permissions
echo -e "\n📁 Checking file permissions..."

if [ -w "/workspaces" ]; then
    print_status "OK" "Workspace directory writable"
    ((passed_tests++))
else
    print_status "FAIL" "Workspace directory not writable"
fi
((total_tests++))

if [ -x "/workspaces/.devcontainer/setup.sh" ]; then
    print_status "OK" "Setup script executable"
    ((passed_tests++))
else
    print_status "WARN" "Setup script not executable"
fi
((total_tests++))

# Test network connectivity
echo -e "\n🌐 Checking network connectivity..."

if curl -s --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    print_status "OK" "Network connectivity working"
    ((passed_tests++))
else
    print_status "WARN" "Network connectivity issues"
fi
((total_tests++))

# Summary
echo -e "\n📊 Test Summary"
echo "==============="
echo "Total tests: $total_tests"
echo "Passed tests: $passed_tests"
echo "Failed tests: $((total_tests - passed_tests))"

if [ $passed_tests -eq $total_tests ]; then
    print_status "OK" "All tests passed! DevContainer is fully functional."
    exit 0
elif [ $passed_tests -gt $((total_tests * 80 / 100)) ]; then
    print_status "WARN" "Most tests passed. DevContainer should be functional."
    exit 0
else
    print_status "FAIL" "Too many tests failed. DevContainer may need attention."
    exit 1
fi