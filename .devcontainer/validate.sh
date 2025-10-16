#!/bin/bash

# Validation script for DevContainer configuration
# This script validates that all DevContainer files are properly configured

set -e

echo "🔍 Validating DevContainer configuration..."

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

# Track overall success
total_checks=0
passed_checks=0

# Check DevContainer configuration files
echo -e "\n📁 Checking configuration files..."

if [ -f ".devcontainer/devcontainer.json" ]; then
    print_status "OK" "devcontainer.json exists"
    ((passed_checks++))

    # Validate JSON syntax
    if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
        print_status "OK" "devcontainer.json valid JSON"
        ((passed_checks++))
    else
        print_status "FAIL" "devcontainer.json invalid JSON"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "devcontainer.json missing"
    ((total_checks++))
fi

if [ -f ".devcontainer/setup.sh" ]; then
    print_status "OK" "setup.sh exists"
    ((passed_checks++))

    if [ -x ".devcontainer/setup.sh" ]; then
        print_status "OK" "setup.sh is executable"
        ((passed_checks++))
    else
        print_status "WARN" "setup.sh is not executable"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "setup.sh missing"
    ((total_checks++))
fi

if [ -f ".devcontainer/test.sh" ]; then
    print_status "OK" "test.sh exists"
    ((passed_checks++))

    if [ -x ".devcontainer/test.sh" ]; then
        print_status "OK" "test.sh is executable"
        ((passed_checks++))
    else
        print_status "WARN" "test.sh is not executable"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "test.sh missing"
    ((total_checks++))
fi

if [ -f ".devcontainer/validate.sh" ]; then
    print_status "OK" "validate.sh exists"
    ((passed_checks++))

    if [ -x ".devcontainer/validate.sh" ]; then
        print_status "OK" "validate.sh is executable"
        ((passed_checks++))
    else
        print_status "WARN" "validate.sh is not executable"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "validate.sh missing"
    ((total_checks++))
fi

# Check VS Code configuration
echo -e "\n💻 Checking VS Code configuration..."

if [ -f ".vscode/settings.json" ]; then
    print_status "OK" "VS Code settings.json exists"
    ((passed_checks++))

    if jq empty .vscode/settings.json 2>/dev/null; then
        print_status "OK" "VS Code settings.json valid JSON"
        ((passed_checks++))
    else
        print_status "FAIL" "VS Code settings.json invalid JSON"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "VS Code settings.json missing"
    ((total_checks++))
fi

if [ -f ".vscode/extensions.json" ]; then
    print_status "OK" "VS Code extensions.json exists"
    ((passed_checks++))

    if jq empty .vscode/extensions.json 2>/dev/null; then
        print_status "OK" "VS Code extensions.json valid JSON"
        ((passed_checks++))
    else
        print_status "FAIL" "VS Code extensions.json invalid JSON"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "VS Code extensions.json missing"
    ((total_checks++))
fi

if [ -f ".vscode/tasks.json" ]; then
    print_status "OK" "VS Code tasks.json exists"
    ((passed_checks++))

    if jq empty .vscode/tasks.json 2>/dev/null; then
        print_status "OK" "VS Code tasks.json valid JSON"
        ((passed_checks++))
    else
        print_status "FAIL" "VS Code tasks.json invalid JSON"
    fi
    ((total_checks+=2))
else
    print_status "WARN" "VS Code tasks.json missing"
    ((total_checks++))
fi

if [ -f ".vscode/launch.json" ]; then
    print_status "OK" "VS Code launch.json exists"
    ((passed_checks++))

    if jq empty .vscode/launch.json 2>/dev/null; then
        print_status "OK" "VS Code launch.json valid JSON"
        ((passed_checks++))
    else
        print_status "FAIL" "VS Code launch.json invalid JSON"
    fi
    ((total_checks+=2))
else
    print_status "WARN" "VS Code launch.json missing"
    ((total_checks++))
fi

# Check GitHub Codespaces configuration
echo -e "\n☁️ Checking GitHub Codespaces configuration..."

if [ -f ".devcontainer/codespaces.json" ]; then
    print_status "OK" "codespaces.json exists"
    ((passed_checks++))

    if jq empty .devcontainer/codespaces.json 2>/dev/null; then
        print_status "OK" "codespaces.json valid JSON"
        ((passed_checks++))
    else
        print_status "FAIL" "codespaces.json invalid JSON"
    fi
    ((total_checks+=2))
else
    print_status "WARN" "codespaces.json missing"
    ((total_checks++))
fi

if [ -d ".github" ]; then
    print_status "OK" ".github directory exists"
    ((passed_checks++))

    if [ -f ".github/codespaces.md" ]; then
        print_status "OK" "codespaces.md documentation exists"
        ((passed_checks++))
    else
        print_status "WARN" "codespaces.md documentation missing"
    fi
    ((total_checks+=2))
else
    print_status "WARN" ".github directory missing"
    ((total_checks++))
fi

# Check Makefile
echo -e "\n🔨 Checking Makefile..."

if [ -f "Makefile" ]; then
    print_status "OK" "Makefile exists"
    ((passed_checks++))

    if grep -q "devcontainer" Makefile; then
        print_status "OK" "Makefile contains DevContainer targets"
        ((passed_checks++))
    else
        print_status "FAIL" "Makefile missing DevContainer targets"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "Makefile missing"
    ((total_checks++))
fi

# Check documentation
echo -e "\n📚 Checking documentation..."

if [ -f "README.md" ]; then
    print_status "OK" "README.md exists"
    ((passed_checks++))

    if grep -q "DevContainer\|devcontainer" README.md; then
        print_status "OK" "README.md contains DevContainer documentation"
        ((passed_checks++))
    else
        print_status "WARN" "README.md missing DevContainer documentation"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "README.md missing"
    ((total_checks++))
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "OK" "CHANGELOG.md exists"
    ((passed_checks++))

    if grep -q "DevContainer\|devcontainer" CHANGELOG.md; then
        print_status "OK" "CHANGELOG.md mentions DevContainer"
        ((passed_checks++))
    else
        print_status "WARN" "CHANGELOG.md doesn't mention DevContainer"
    fi
    ((total_checks+=2))
else
    print_status "WARN" "CHANGELOG.md missing"
    ((total_checks++))
fi

if [ -f "ATTRIBUTIONS.md" ]; then
    print_status "OK" "ATTRIBUTIONS.md exists"
    ((passed_checks++))
else
    print_status "WARN" "ATTRIBUTIONS.md missing"
fi
((total_checks++))

# Check Molecule configuration
echo -e "\n🧪 Checking Molecule configuration..."

if [ -d "tests/molecule/tailscale" ]; then
    print_status "OK" "Molecule test directory exists"
    ((passed_checks++))

    if [ -f "tests/molecule/tailscale/molecule.yml" ]; then
        print_status "OK" "molecule.yml exists"
        ((passed_checks++))

        if grep -q "macos\|devcontainer" tests/molecule/tailscale/molecule.yml; then
            print_status "OK" "molecule.yml contains DevContainer configuration"
            ((passed_checks++))
        else
            print_status "WARN" "molecule.yml missing DevContainer configuration"
        fi
        ((total_checks+=2))
    else
        print_status "FAIL" "molecule.yml missing"
        ((total_checks++))
    fi
else
    print_status "FAIL" "Molecule test directory missing"
    ((total_checks++))
fi

# Check Ansible collection structure
echo -e "\n🔧 Checking Ansible collection structure..."

if [ -f "galaxy.yml" ]; then
    print_status "OK" "galaxy.yml exists"
    ((passed_checks++))
else
    print_status "FAIL" "galaxy.yml missing"
fi
((total_checks++))

if [ -d "roles" ]; then
    print_status "OK" "roles directory exists"
    ((passed_checks++))

    if [ -d "roles/tailscale" ]; then
        print_status "OK" "tailscale role exists"
        ((passed_checks++))
    else
        print_status "FAIL" "tailscale role missing"
    fi
    ((total_checks+=2))
else
    print_status "FAIL" "roles directory missing"
    ((total_checks++))
fi

# Summary
echo -e "\n📊 Validation Summary"
echo "===================="
echo "Total checks: $total_checks"
echo "Passed checks: $passed_checks"
echo "Failed checks: $((total_checks - passed_checks))"

if [ $passed_checks -eq $total_checks ]; then
    print_status "OK" "All validation checks passed! DevContainer configuration is ready."
    exit 0
elif [ $passed_checks -gt $((total_checks * 80 / 100)) ]; then
    print_status "WARN" "Most checks passed. DevContainer should work but may need attention."
    exit 0
else
    print_status "FAIL" "Too many validation checks failed. Please fix the issues."
    exit 1
fi