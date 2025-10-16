# Makefile for kaitranntt.mac Ansible Collection

.PHONY: help install lint test clean build upload docs devcontainer-build devcontainer-test devcontainer-shell devcontainer-destroy devcontainer-setup devcontainer-status

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install collection locally"
	@echo "  lint              - Run linting checks"
	@echo "  test              - Run Molecule tests"
	@echo "  clean             - Clean up temporary files"
	@echo "  build             - Build collection artifact"
	@echo "  upload            - Upload to Ansible Galaxy (requires API key)"
	@echo "  docs              - Generate documentation"
	@echo "  all               - Run lint and test"
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

# Run linting checks
lint:
	@echo "Running linting checks..."
	yamllint .
	ansible-lint
	flake8 --max-line-length=120 --ignore=E203,W503 roles/ plugins/ tests/
	@echo "Linting completed"

# Run Molecule tests
test:
	@echo "Running Molecule tests..."
	cd tests/molecule/tailscale && molecule test
	@echo "Tests completed"

# Run specific test scenario
test-default:
	@echo "Running default test scenario..."
	cd tests/molecule/tailscale && molecule test --scenario-name default
	@echo "Default test completed"

# Converge only (no destroy)
converge:
	@echo "Running converge only..."
	cd tests/molecule/tailscale && molecule converge
	@echo "Converge completed"

# Verify idempotence
verify:
	@echo "Verifying idempotence..."
	cd tests/molecule/tailscale && molecule verify
	@echo "Idempotence verified"

# Clean up temporary files
clean:
	@echo "Cleaning up..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache
	rm -rf *.tar.gz
	cd tests/molecule/tailscale && molecule destroy || true
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
	@echo "Documentation generation not yet implemented"
	@echo "See README.md for usage examples"

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