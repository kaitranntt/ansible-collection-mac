# Molecule Testing Infrastructure

This document explains the Molecule testing setup for the kaitranntt.mac Ansible collection.

## Overview

Molecule is used for testing Ansible roles and collections. The current setup uses Docker containers for isolated testing environments.

## Structure

```
extensions/molecule/
└── default/
    ├── molecule.yml          # Molecule configuration
    ├── converge.yml           # Main test playbook
    ├── prepare.yml            # Preparation tasks
    ├── destroy.yml            # Cleanup tasks
    ├── verify.yml             # Verification tasks
    └── requirements.yml       # Galaxy dependencies
```

## Configuration

### Driver: Docker
- Uses Docker containers for isolated testing
- Base image: `python:3.11-slim`
- Container name: `instance`

### Test Sequence
The current test sequence includes:
1. **dependency** - Install required collections
2. **syntax** - Validate playbook syntax
3. **create** - Create Docker container
4. **prepare** - Run preparation tasks
5. **converge** - Apply the role
6. **destroy** - Clean up container

## Running Tests

### Using Make
```bash
# Run full test suite
make test

# Run specific scenario
make test-default

# Run only converge step
make converge

# Run verification only
make verify
```

### Using Molecule directly
```bash
# Activate virtual environment
source .venv/bin/activate

# Run all tests
molecule test --scenario-name default

# Run specific steps
molecule syntax --scenario-name default
molecule converge --scenario-name default
```

## Current Limitations

1. **macOS-specific role**: The tailscale role is designed specifically for macOS systems and will fail in Linux Docker containers. This is expected behavior.

2. **Platform Testing**: The current setup uses Docker containers, which cannot fully replicate macOS environments. For complete macOS testing, consider:
   - Using macOS runners in CI/CD
   - Using virtual machines with macOS
   - Testing on actual macOS hardware

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Molecule Tests
on: [push, pull_request]

jobs:
  molecule:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          python -m venv .venv
          . .venv/bin/activate
          pip install -r requirements-dev.txt

      - name: Run Molecule tests
        run: |
          . .venv/bin/activate
          make test
```

## Troubleshooting

### Common Issues

1. **Virtual environment not found**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements-dev.txt
   ```

2. **Docker not available**
   - Ensure Docker is installed and running
   - Check user permissions for Docker access

3. **Collection not found**
   - Ensure the collection is properly installed:
   ```bash
   ansible-galaxy collection install .
   ```

4. **Role validation failures**
   - Check that playbooks reference the correct collection namespace
   - Verify role syntax and structure

## Future Improvements

1. **Multi-platform testing**: Add support for testing on actual macOS environments
2. **Test coverage**: Expand test scenarios to cover more use cases
3. **Performance testing**: Add performance benchmarks
4. **Integration testing**: Test with real Tailscale installations

## Maintenance

- Keep Molecule and dependencies updated regularly
- Review and update test scenarios when roles change
- Monitor test execution time and optimize where needed
- Ensure CI/CD pipeline uses the same configuration as local development
