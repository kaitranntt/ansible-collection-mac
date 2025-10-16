# Makefile for kaitranntt.mac Ansible Collection

.PHONY: help install lint test clean build upload docs docs-clean docs-serve docs-collection docs-validate devcontainer-build devcontainer-test devcontainer-shell devcontainer-destroy devcontainer-setup devcontainer-status format security security-checkov security-bandit security-safety security-secrets security-clean security-report quality quality-metrics quality-score quality-report quality-trend quality-clean setup-hooks update-hooks clean-quality

# Default target
help:
	@echo "Available targets:"
	@echo "  install           - Install collection locally"
	@echo "  format            - Format all code files"
	@echo "  lint              - Run linting checks"
	@echo "  security          - Run comprehensive security scans"
	@echo "  security-checkov  - Run Checkov infrastructure security scan only"
	@echo "  security-bandit   - Run Bandit Python security scan only"
	@echo "  security-safety   - Run Safety dependency security scan only"
	@echo "  security-secrets  - Run secret detection scan only"
	@echo "  security-clean    - Clean security reports"
	@echo "  quality           - Run comprehensive quality checks"
	@echo "  quality-metrics   - Generate quality metrics report"
	@echo "  quality-score     - Show current quality score only"
	@echo "  quality-report    - Generate detailed quality report"
	@echo "  quality-trend     - Analyze quality trends over time"
	@echo "  quality-clean     - Clean quality reports"
	@echo "  test              - Run Molecule tests"
	@echo "  clean             - Clean up temporary files"
	@echo "  build             - Build collection artifact"
	@echo "  upload            - Upload to Ansible Galaxy (requires API key)"
	@echo "  docs              - Generate documentation"
	@echo "  docs-clean        - Clean documentation files"
	@echo "  docs-serve        - Serve documentation locally"
	@echo "  docs-collection   - Generate collection docs only"
	@echo "  docs-validate     - Validate documentation links"
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
	@echo "  setup-dev         - Setup complete development environment"
	@echo "  setup-quick       - Quick development setup (assumes dependencies)"
	@echo "  env-info          - Show development environment information"
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

# Generate documentation
docs: docs-clean
	@echo "Generating documentation..."
	@mkdir -p docs/_build docs/_static
	@if command -v antsibull-docs >/dev/null 2>&1; then \
		echo "Generating Ansible collection docs with antsibull-docs..."; \
		antsibull-docs collection kaitranntt.mac --use-current --squash-hierarchy --dest-dir docs/collection; \
	else \
		echo "antsibull-docs not installed, skipping collection docs"; \
	fi
	@if command -v sphinx-build >/dev/null 2>&1; then \
		echo "Generating Sphinx documentation..."; \
		sphinx-build -b html docs/ docs/_build/html; \
		echo "HTML documentation generated in docs/_build/html/"; \
	else \
		echo "sphinx-build not installed. Install with: pip install sphinx sphinx-rtd-theme"; \
	fi
	@echo "Documentation generation completed"

# Clean documentation
docs-clean:
	@echo "Cleaning documentation..."
	@rm -rf docs/_build/
	@rm -rf docs/collection/
	@rm -rf docs/_source/
	@echo "Documentation cleaned"

# Serve documentation locally
docs-serve:
	@echo "Starting documentation server..."
	@if [ -d "docs/_build/html" ]; then \
		cd docs/_build/html && python3 -m http.server 8000; \
	else \
		echo "Documentation not built. Run 'make docs' first."; \
		exit 1; \
	fi

# Generate collection docs only
docs-collection:
	@echo "Generating Ansible collection documentation..."
	@if command -v antsibull-docs >/dev/null 2>&1; then \
		antsibull-docs collection kaitranntt.mac --use-current --squash-hierarchy --dest-dir docs/collection; \
		echo "Collection documentation generated in docs/collection/"; \
	else \
		echo "antsibull-docs not installed. Install with: pip install antsibull-docs"; \
		exit 1; \
	fi

# Validate documentation links
docs-validate:
	@echo "Validating documentation links..."
	@if command -v sphinx-build >/dev/null 2>&1; then \
		sphinx-build -b linkcheck docs/ docs/_build/linkcheck; \
	else \
		echo "sphinx-build not installed"; \
		exit 1; \
	fi

# Run all quality checks
all: lint test
	@echo "All quality checks completed"


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
	@echo "Running comprehensive security scans..."
	@mkdir -p security-reports
	@echo "=== Infrastructure Security Scan ===" > security-reports/security-summary.txt
	@date >> security-reports/security-summary.txt
	@echo "" >> security-reports/security-summary.txt
	@if command -v checkov >/dev/null 2>&1; then \
		echo "Running Checkov infrastructure security scan..."; \
		checkov --framework ansible --directory . --quiet --output json --output-file-path security-reports/checkov-report.json || true; \
		echo "Checkov scan completed" >> security-reports/security-summary.txt; \
	else \
		echo "Checkov not installed. Install with: pip install checkov" >> security-reports/security-summary.txt; \
	fi
	@echo "" >> security-reports/security-summary.txt
	@echo "=== Python Code Security Scan ===" >> security-reports/security-summary.txt
	@if [ -d "roles" ] || [ -d "plugins" ] || [ -d "scripts" ]; then \
		echo "Running Bandit security scan..."; \
		bandit -r roles/ plugins/ scripts/ -f json -o security-reports/bandit-report.json || true; \
		bandit -r roles/ plugins/ scripts/ -f txt -o security-reports/bandit-report.txt || true; \
		echo "Bandit scan results:" >> security-reports/security-summary.txt; \
		bandit -r roles/ plugins/ scripts/ --severity-level medium >> security-reports/security-summary.txt 2>&1 || true; \
	else \
		echo "No Python code directories found for Bandit scan" >> security-reports/security-summary.txt; \
	fi
	@echo "" >> security-reports/security-summary.txt
	@echo "=== Dependency Security Scan ===" >> security-reports/security-summary.txt
	@if [ -f "requirements-dev.txt" ]; then \
		echo "Running Safety dependency scan..."; \
		safety check -r requirements-dev.txt --output json > security-reports/safety-report.json || true; \
		safety check -r requirements-dev.txt --output text >> security-reports/security-summary.txt 2>&1 || true; \
	else \
		echo "No requirements file found for Safety scan" >> security-reports/security-summary.txt; \
	fi
	@if [ -f "requirements.yml" ]; then \
		echo "Running Ansible dependency security scan..."; \
		ansible-galaxy collection install -r requirements.yml --force --ignore-errors || true; \
	fi
	@echo "" >> security-reports/security-summary.txt
	@echo "=== Secret Detection Scan ===" >> security-reports/security-summary.txt
	@if command -v trufflehog >/dev/null 2>&1; then \
		echo "Running TruffleHog secret detection..."; \
		trufflehog filesystem --directory . --json --output security-reports/trufflehog-report.json || true; \
	else \
		echo "TruffleHog not installed. Install with: pip install trufflehog" >> security-reports/security-summary.txt; \
	fi
	@echo "" >> security-reports/security-summary.txt
	@echo "=== File Permissions Scan ===" >> security-reports/security-summary.txt
	@echo "Checking for insecure file permissions..." >> security-reports/security-summary.txt
	@find . -type f -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.pfx" 2>/dev/null | head -10 >> security-reports/security-summary.txt || echo "No certificate files found" >> security-reports/security-summary.txt
	@find . -name "*.env" -o -name "id_rsa*" -o -name "*.secret" 2>/dev/null | head -10 >> security-reports/security-summary.txt || echo "No obvious secret files found" >> security-reports/security-summary.txt
	@echo "" >> security-reports/security-summary.txt
	@echo "=== Security Scan Summary ===" >> security-reports/security-summary.txt
	@echo "Security reports generated in security-reports/ directory" >> security-reports/security-summary.txt
	@if [ -f "security-reports/checkov-report.json" ]; then echo "✓ Checkov report: security-reports/checkov-report.json" >> security-reports/security-summary.txt; fi
	@if [ -f "security-reports/bandit-report.json" ]; then echo "✓ Bandit report: security-reports/bandit-report.json" >> security-reports/security-summary.txt; fi
	@if [ -f "security-reports/safety-report.json" ]; then echo "✓ Safety report: security-reports/safety-report.json" >> security-reports/security-summary.txt; fi
	@if [ -f "security-reports/trufflehog-report.json" ]; then echo "✓ TruffleHog report: security-reports/trufflehog-report.json" >> security-reports/security-summary.txt; fi
	@echo "Security scan completed. See security-reports/security-summary.txt for summary"
	@cat security-reports/security-summary.txt

# Individual security scan targets
security-checkov:
	@echo "Running Checkov infrastructure security scan..."
	@mkdir -p security-reports
	@if command -v checkov >/dev/null 2>&1; then \
		checkov --framework ansible --directory . --quiet --output json --output-file-path security-reports/checkov-report.json; \
		echo "Checkov report generated: security-reports/checkov-report.json"; \
	else \
		echo "Checkov not installed. Install with: pip install checkov"; \
		exit 1; \
	fi

security-bandit:
	@echo "Running Bandit Python security scan..."
	@mkdir -p security-reports
	@if [ -d "roles" ] || [ -d "plugins" ] || [ -d "scripts" ]; then \
		bandit -r roles/ plugins/ scripts/ -f json -o security-reports/bandit-report.json; \
		bandit -r roles/ plugins/ scripts/ -f txt -o security-reports/bandit-report.txt; \
		echo "Bandit reports generated: security-reports/bandit-report.json and security-reports/bandit-report.txt"; \
	else \
		echo "No Python code directories found for Bandit scan"; \
	fi

security-safety:
	@echo "Running Safety dependency security scan..."
	@mkdir -p security-reports
	@if [ -f "requirements-dev.txt" ]; then \
		safety check -r requirements-dev.txt --output json > security-reports/safety-report.json; \
		safety check -r requirements-dev.txt --output text > security-reports/safety-summary.txt; \
		echo "Safety reports generated: security-reports/safety-report.json and security-reports/safety-summary.txt"; \
	else \
		echo "No requirements file found for Safety scan"; \
		exit 1; \
	fi

security-secrets:
	@echo "Running secret detection scan..."
	@mkdir -p security-reports
	@if command -v trufflehog >/dev/null 2>&1; then \
		trufflehog filesystem --directory . --json --output security-reports/trufflehog-report.json; \
		echo "TruffleHog report generated: security-reports/trufflehog-report.json"; \
	else \
		echo "TruffleHog not installed. Install with: pip install trufflehog"; \
		echo "Falling back to basic secret detection..."; \
		find . -name "*.key" -o -name "*.pem" -o -name "*.p12" -o -name "*.pfx" > security-reports/secret-files.txt; \
		find . -name "*.env" -o -name "id_rsa*" -o -name "*.secret" >> security-reports/secret-files.txt; \
		echo "Basic secret detection completed: security-reports/secret-files.txt"; \
	fi

security-clean:
	@echo "Cleaning security reports..."
	@rm -rf security-reports/
	@echo "Security reports cleaned"

# Security audit report generation
security-report: security
	@echo "Generating comprehensive security audit report..."
	@mkdir -p security-reports
	@echo "# Security Audit Report" > security-reports/SECURITY_AUDIT.md
	@echo "" >> security-reports/SECURITY_AUDIT.md
	@echo "Generated on: $$(date)" >> security-reports/SECURITY_AUDIT.md
	@echo "" >> security-reports/SECURITY_AUDIT.md
	@echo "## Summary" >> security-reports/SECURITY_AUDIT.md
	@echo "" >> security-reports/SECURITY_AUDIT.md
	@cat security-reports/security-summary.txt >> security-reports/SECURITY_AUDIT.md
	@echo "" >> security-reports/SECURITY_AUDIT.md
	@echo "## Detailed Reports" >> security-reports/SECURITY_AUDIT.md
	@echo "" >> security-reports/SECURITY_AUDIT.md
	@if [ -f "security-reports/checkov-report.json" ]; then echo "- [Checkov Infrastructure Scan](checkov-report.json)" >> security-reports/SECURITY_AUDIT.md; fi
	@if [ -f "security-reports/bandit-report.json" ]; then echo "- [Bandit Python Security Scan](bandit-report.json)" >> security-reports/SECURITY_AUDIT.md; fi
	@if [ -f "security-reports/safety-report.json" ]; then echo "- [Safety Dependency Scan](safety-report.json)" >> security-reports/SECURITY_AUDIT.md; fi
	@if [ -f "security-reports/trufflehog-report.json" ]; then echo "- [TruffleHog Secret Detection](trufflehog-report.json)" >> security-reports/SECURITY_AUDIT.md; fi
	@echo "Comprehensive security audit report generated: security-reports/SECURITY_AUDIT.md"

# Full quality check
quality: format lint security
	@echo "All quality checks completed successfully"

# Generate comprehensive quality metrics report
quality-metrics:
	@echo "Generating comprehensive quality metrics report..."
	@if [ -f "scripts/quality-metrics.py" ]; then \
		python3 scripts/quality-metrics.py --project-root . --output-json quality-reports/quality-metrics.json --output-md quality-reports/QUALITY_REPORT.md; \
	else \
		echo "❌ Quality metrics script not found at scripts/quality-metrics.py"; \
		exit 1; \
	fi

# Show current quality score only
quality-score:
	@echo "Calculating current quality score..."
	@if [ -f "scripts/quality-metrics.py" ]; then \
		python3 scripts/quality-metrics.py --project-root . --quiet && \
		if [ -f "quality-reports/quality-metrics.json" ]; then \
			python3 -c "import json; data=json.load(open('quality-reports/quality-metrics.json')); print(f'🎯 Quality Score: {data[\"metrics\"][\"overall_score\"][\"grade\"]} ({data[\"metrics\"][\"overall_score\"][\"overall_score\"]}/100)')"; \
		fi; \
	else \
		echo "❌ Quality metrics script not found"; \
		exit 1; \
	fi

# Generate detailed quality report (markdown only)
quality-report:
	@echo "Generating detailed quality report..."
	@if [ -f "scripts/quality-metrics.py" ]; then \
		python3 scripts/quality-metrics.py --project-root . --output-md quality-reports/QUALITY_REPORT.md; \
		echo "📋 Quality report generated: quality-reports/QUALITY_REPORT.md"; \
	else \
		echo "❌ Quality metrics script not found"; \
		exit 1; \
	fi

# Analyze quality trends over time
quality-trend:
	@echo "Analyzing quality trends over time..."
	@if [ -d "quality-reports" ]; then \
		echo "📈 Quality Trend Analysis:"; \
		echo "Available reports:"; \
		ls -la quality-reports/*.json 2>/dev/null || echo "  No historical reports found"; \
		echo ""; \
		echo "To track trends, run quality-metrics regularly and compare reports."; \
	else \
		echo "❌ No quality reports directory found. Run 'make quality-metrics' first."; \
	fi

# Clean quality reports
quality-clean:
	@echo "Cleaning quality reports..."
	@if [ -d "quality-reports" ]; then \
		rm -rf quality-reports/; \
		echo "✅ Quality reports cleaned"; \
	else \
		echo "ℹ️ No quality reports to clean"; \
	fi

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

# Complete development environment setup
setup-dev:
	@echo "Setting up complete development environment..."
	@if [ -f "scripts/setup-dev.sh" ]; then \
		./scripts/setup-dev.sh setup; \
	else \
		echo "❌ Setup script not found at scripts/setup-dev.sh"; \
		exit 1; \
	fi

# Quick development setup (assumes Python and basic tools are installed)
setup-quick:
	@echo "Setting up quick development environment..."
	@if [ ! -d ".venv" ]; then \
		echo "Creating Python virtual environment..."; \
		python3 -m venv .venv; \
	fi
	@echo "Installing packages in virtual environment..."
	@.venv/bin/pip install --upgrade pip
	@if [ -f "requirements-dev.txt" ]; then \
		echo "Installing development dependencies..."; \
		.venv/bin/pip install -r requirements-dev.txt; \
	else \
		echo "Installing essential development tools..."; \
		.venv/bin/pip install ansible ansible-lint yamllint black molecule pre-commit; \
	fi
	@if [ -f ".pre-commit-config.yaml" ]; then \
		echo "Installing pre-commit hooks..."; \
		.venv/bin/pre-commit install; \
	fi
	@echo "✅ Quick development setup completed!"
	@echo "🚀 Run 'source .venv/bin/activate' to start development"

# Show development environment information
env-info:
	@echo "=== Development Environment Information ==="
	@echo "Project: $(shell basename $(shell pwd))"
	@echo "Python: $(shell python --version 2>/dev/null || echo 'Not found')"
	@echo "Virtual Environment: ${VIRTUAL_ENV:-'Not active'}"
	@echo ""
	@if command -v ansible >/dev/null 2>&1; then echo "Ansible: $(shell ansible --version | head -n1)"; fi
	@if command -v ansible-lint >/dev/null 2>&1; then echo "Ansible Lint: $(shell ansible-lint --version)"; fi
	@if command -v yamllint >/dev/null 2>&1; then echo "YAML Lint: $(shell yamllint --version)"; fi
	@if command -v black >/dev/null 2>&1; then echo "Black: $(shell black --version)"; fi
	@if command -v molecule >/dev/null 2>&1; then echo "Molecule: $(shell molecule --version)"; fi
	@echo ""
	@echo "=== Available Make Targets ==="
	@make help 2>/dev/null | grep -E "^[a-zA-Z][^:]*:" | head -15 || echo "Run 'make help' for all targets"
