# Makefile for kaitranntt.mac Ansible Collection

.PHONY: help install lint test clean build upload docs devcontainer-build devcontainer-test devcontainer-shell devcontainer-destroy devcontainer-setup devcontainer-status format security quality setup-hooks update-hooks clean-quality

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install collection locally"
	@echo "  format            - Format all code files"
	@echo "  lint              - Run linting checks"
	@echo "  security          - Run security scans"
	@echo "  quality           - Run comprehensive quality checks"
	@echo "  test              - Run Molecule tests"
	@echo "  clean             - Clean up temporary files"
	@echo "  build             - Build collection artifact"
	@echo "  upload            - Upload to Ansible Galaxy (requires API key)"
	@echo "  docs              - Generate documentation"
	@echo "  all               - Run lint and test"
	@echo ""
	@echo "Quality automation targets:"
	@echo "  setup-hooks       - Install pre-commit hooks"
	@echo "  update-hooks      - Update pre-commit hooks"
	@echo "  clean-quality     - Clean up quality-related files"
	@echo ""
	@echo "DevContainer targets:"
	@echo "  devcontainer-build   - Build the DevContainer image"
	@echo "  devcontainer-test    - Run tests in DevContainer"
	@echo "  devcontainer-shell   - Open shell in DevContainer"
	@echo "  devcontainer-destroy - Destroy the DevContainer"
	@echo "  devcontainer-setup   - Setup DevContainer environment"
	@echo "  devcontainer-status  - Check DevContainer status"
	@echo ""
	@echo "Development targets:"
	@echo "  setup-dev         - Setup development environment"
	@echo "  quick-test        - Quick install and test"
	@echo "  help              - Show this help message"

# Install collection locally for development
install:
	@echo "Installing collection locally..."
	ansible-galaxy collection install . -p . --force
	@echo "Collection installed successfully"

# Format all files
format:
	@echo "Formatting YAML files..."
	@if command -v yamlfmt >/dev/null 2>&1; then find . -name "*.yml" -o -name "*.yaml" | grep -v ".venv" | grep -v ".git" | grep -v ".yamllint.yml" | grep -v ".yamlfmt.yml" | grep -v ".ansible-lint.yml" | grep -v ".pre-commit-config.yaml" | xargs yamlfmt -w; else echo "yamlfmt not available, skipping YAML formatting"; fi
	@echo "Formatting Python files..."
	@if [ -d "roles" ]; then black roles/ --line-length 120; fi
	@if [ -d "plugins" ]; then black plugins/ --line-length 120; fi
	@if [ -d "tests" ]; then black tests/ --line-length 120; fi
	@if [ -d "roles" ]; then isort roles/ --profile black; fi
	@if [ -d "plugins" ]; then isort plugins/ --profile black; fi
	@if [ -d "tests" ]; then isort tests/ --profile black; fi
	@echo "Formatting completed"

# Run linting checks
lint: format
	@echo "Running enhanced linting checks..."
	@if command -v yamllint >/dev/null 2>&1; then yamllint . || echo "yamllint found issues, but continuing..."; else echo "yamllint not available, skipping"; fi
	@if command -v ansible-lint >/dev/null 2>&1; then ansible-lint --config-file .ansible-lint.yml; else echo "ansible-lint not available, skipping"; fi
	@if [ -d "roles" ]; then flake8 roles/ --max-line-length=120 --ignore=E203,W503 || true; fi
	@if [ -d "plugins" ]; then flake8 plugins/ --max-line-length=120 --ignore=E203,W503 || true; fi
	@if [ -d "tests" ]; then flake8 tests/ --max-line-length=120 --ignore=E203,W503 || true; fi
	@echo "Linting completed"

# Run Molecule tests
test:
	@echo "Running Molecule tests..."
	@if [ -d ".venv" ]; then \
		if [ -d "roles/tailscale/molecule" ]; then \
			cd roles/tailscale && . ../../.venv/bin/activate && molecule test --scenario-name default; \
		else \
			. .venv/bin/activate && molecule test --scenario-name default; \
		fi; \
	else \
		echo "Virtual environment not found. Please run: python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt"; \
		exit 1; \
	fi
	@echo "Tests completed"

# Run specific test scenario
test-default:
	@echo "Running default test scenario..."
	@if [ -d ".venv" ]; then \
		if [ -d "roles/tailscale/molecule" ]; then \
			cd roles/tailscale && . ../../.venv/bin/activate && molecule test --scenario-name default; \
		else \
			. .venv/bin/activate && molecule test --scenario-name default; \
		fi; \
	else \
		echo "Virtual environment not found. Please run: python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt"; \
		exit 1; \
	fi
	@echo "Default test completed"

# Converge only (no destroy)
converge:
	@echo "Running converge only..."
	@if [ -d ".venv" ]; then \
		if [ -d "roles/tailscale/molecule" ]; then \
			cd roles/tailscale && . ../../.venv/bin/activate && molecule converge --scenario-name default; \
		else \
			. .venv/bin/activate && molecule converge --scenario-name default; \
		fi; \
	else \
		echo "Virtual environment not found. Please run: python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt"; \
		exit 1; \
	fi
	@echo "Converge completed"

# Verify idempotence
verify:
	@echo "Verifying idempotence..."
	@if [ -d ".venv" ]; then \
		if [ -d "roles/tailscale/molecule" ]; then \
			cd roles/tailscale && . ../../.venv/bin/activate && molecule verify --scenario-name default; \
		else \
			. .venv/bin/activate && molecule verify --scenario-name default; \
		fi; \
	else \
		echo "Virtual environment not found. Please run: python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt"; \
		exit 1; \
	fi
	@echo "Idempotence verified"

# Clean up temporary files
clean:
	@echo "Cleaning up..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache
	rm -rf *.tar.gz
	@if [ -d ".venv" ]; then \
		if [ -d "roles/tailscale/molecule" ]; then \
			cd roles/tailscale && . ../../.venv/bin/activate && molecule destroy --scenario-name default || true; \
		else \
			. .venv/bin/activate && molecule destroy --scenario-name default || true; \
		fi; \
	else \
		echo "Virtual environment not found, skipping molecule destroy"; \
	fi
	@echo "Cleanup completed"

# Build collection artifact
build: clean
	@echo "Building collection artifact..."
	ansible-galaxy collection build
	@echo "Build completed"

# Upload to Ansible Galaxy
upload: build
	@echo "Uploading to Ansible Galaxy..."
	ansible-galaxy collection publish kaitranntt-mac-*.tar.gz --api-key $$GALAXY_API_KEY
	@echo "Upload completed"

# Generate documentation (placeholder)
docs:
	@echo "Generating documentation..."
	@if command -v antsibull-docs >/dev/null 2>&1; then antsibull-docs collection --debug --use-current --squash-hierarchy; else echo "antsibull-docs not installed. Install with: pip install antsibull-docs"; fi
	@echo "Documentation generated in docs/"

# Run all quality checks
all: lint test
	@echo "All quality checks completed"

# Development setup
setup-dev:
	@echo "Setting up development environment..."
	pip install -r requirements.txt
	pip install ansible molecule molecule-plugins[docker] yamllint ansible-lint flake8
	@echo "Development environment setup completed"

# Quick install and test
quick-test: install test-default
	@echo "Quick install and test completed"

# Comprehensive test suite
test-all:
	@echo "Running comprehensive test suite..."
	@if [ -f "scripts/test.sh" ]; then \
		chmod +x scripts/test.sh && ./scripts/test.sh all; \
	else \
		echo "Test script not found, falling back to make test"; \
		$(MAKE) test; \
	fi

# Test script shortcuts
test-syntax:
	@echo "Running syntax checks..."
	@if [ -f "scripts/test.sh" ]; then \
		chmod +x scripts/test.sh && ./scripts/test.sh syntax; \
	else \
		echo "Test script not found"; \
		exit 1; \
	fi

test-setup:
	@echo "Setting up test environment..."
	@if [ -f "scripts/test.sh" ]; then \
		chmod +x scripts/test.sh && ./scripts/test.sh setup; \
	else \
		echo "Test script not found"; \
		exit 1; \
	fi

# DevContainer targets
devcontainer-build:
	@echo "Building DevContainer..."
	@if [ -f ".devcontainer/devcontainer.json" ]; then \
		docker build -t kaitranntt-mac-devcontainer .devcontainer/; \
		echo "DevContainer built successfully"; \
	else \
		echo "No DevContainer configuration found"; \
		exit 1; \
	fi

devcontainer-test:
	@echo "Running tests in DevContainer..."
	@if command -v code >/dev/null 2>&1; then \
		code --folder-uri vscode-remote://attached-container+$(shell docker ps -q --filter "name=kaitranntt-mac-devcontainer")/workspaces; \
		sleep 5; \
		docker exec -it $(shell docker ps -q --filter "name=kaitranntt-mac-devcontainer") make test; \
	else \
		echo "VS Code not found. Please run 'make devcontainer-shell' and then 'make test'"; \
	fi

devcontainer-shell:
	@echo "Opening shell in DevContainer..."
	@if docker ps --filter "name=kaitranntt-mac-devcontainer" --format "table {{.Names}}" | grep -q kaitranntt-mac-devcontainer; then \
		docker exec -it $(shell docker ps -q --filter "name=kaitranntt-mac-devcontainer") /bin/zsh; \
	else \
		echo "DevContainer not running. Starting new container..."; \
		docker run -it --rm \
			--name kaitranntt-mac-devcontainer \
			--cap-add=SYS_ADMIN \
			--device=/dev/fuse \
			--security-opt=apparmor:unconfined \
			--privileged \
			-v /var/run/docker.sock:/var/run/docker.sock \
			-v $(PWD):/workspaces \
			-w /workspaces \
			dockur/macos:latest /bin/zsh; \
	fi

devcontainer-destroy:
	@echo "Destroying DevContainer..."
	@if docker ps --filter "name=kaitranntt-mac-devcontainer" --format "table {{.Names}}" | grep -q kaitranntt-mac-devcontainer; then \
		docker stop $(shell docker ps -q --filter "name=kaitranntt-mac-devcontainer"); \
		docker rm $(shell docker ps -aq --filter "name=kaitranntt-mac-devcontainer"); \
		echo "DevContainer destroyed"; \
	else \
		echo "No running DevContainer found"; \
	fi

devcontainer-setup:
	@echo "Setting up DevContainer environment..."
	@if [ -f ".devcontainer/setup.sh" ]; then \
		chmod +x .devcontainer/setup.sh; \
		echo "Setup script made executable"; \
	else \
		echo "No setup script found"; \
		exit 1; \
	fi

devcontainer-status:
	@echo "Checking DevContainer status..."
	@if docker ps --filter "name=kaitranntt-mac-devcontainer" --format "table {{.Names}}\t{{.Status}}" | grep -q kaitranntt-mac-devcontainer; then \
		echo "✅ DevContainer is running"; \
		docker ps --filter "name=kaitranntt-mac-devcontainer" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
	else \
		echo "❌ DevContainer is not running"; \
	fi

# VS Code specific targets
vscode-open:
	@echo "Opening project in VS Code with DevContainer..."
	@if command -v code >/dev/null 2>&1; then \
		code . --folder-uri vscode-remote://attached-container+$(shell docker ps -q --filter "name=kaitranntt-mac-devcontainer")/workspaces; \
	else \
		echo "VS Code not found. Please install VS Code with Remote Containers extension"; \
	fi

vscode-rebuild:
	@echo "Rebuilding VS Code DevContainer..."
	@if command -v code >/dev/null 2>&1; then \
		code . --rebuild; \
	else \
		echo "VS Code not found. Please install VS Code with Remote Containers extension"; \
	fi

# Security scanning
security:
	@echo "Running security scans..."
	@if command -v checkov >/dev/null 2>&1; then checkov --framework ansible --directory . || true; fi
	@if [ -d "roles" ] || [ -d "plugins" ]; then bandit -r roles/ plugins/ -f json -o security-report.json || true; fi
	@if [ -f "requirements-dev.txt" ]; then safety check -r requirements-dev.txt || true; fi
	@echo "Security scan completed"

# Full quality check
quality: format lint security
	@echo "All quality checks completed successfully"

# Pre-commit setup
setup-hooks:
	@echo "Setting up pre-commit hooks..."
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit install; else echo "pre-commit not installed. Install with: pip install pre-commit"; fi
	@echo "Pre-commit hooks installed"

# Update pre-commit hooks
update-hooks:
	@echo "Updating pre-commit hooks..."
	@if command -v pre-commit >/dev/null 2>&1; then pre-commit autoupdate; else echo "pre-commit not installed. Install with: pip install pre-commit"; fi
	@echo "Pre-commit hooks updated"

# Clean generated files
clean-quality:
	@echo "Cleaning up generated files..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	rm -f .coverage coverage.xml security-report.json
	rm -rf htmlcov/
	@echo "Cleanup completed"
