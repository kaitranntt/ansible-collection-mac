# Makefile for kaitranntt.mac Ansible Collection

.PHONY: help install lint test clean build upload docs

# Default target
help:
	@echo "Available targets:"
	@echo "  install    - Install collection locally"
	@echo "  lint       - Run linting checks"
	@echo "  test       - Run Molecule tests"
	@echo "  clean      - Clean up temporary files"
	@echo "  build      - Build collection artifact"
	@echo "  upload     - Upload to Ansible Galaxy (requires API key)"
	@echo "  docs       - Generate documentation"
	@echo "  all        - Run lint and test"
	@echo "  help       - Show this help message"

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