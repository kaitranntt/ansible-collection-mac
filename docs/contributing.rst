Contributing
=============

We welcome contributions to the kaitranntt.mac collection! This document provides guidelines for contributors.

Getting Started
---------------

1. Fork the repository
2. Clone your fork locally
3. Create a virtual environment
4. Install development dependencies
5. Create a feature branch
6. Make your changes
7. Run tests and quality checks
8. Submit a pull request

Development Setup
-----------------

.. code-block:: bash

   # Clone the repository
   git clone https://github.com/your-username/ansible-collection-mac.git
   cd ansible-collection-mac

   # Create virtual environment
   python3 -m venv .venv
   source .venv/bin/activate

   # Install development dependencies
   pip install -r requirements-dev.txt

   # Install pre-commit hooks
   make setup-hooks

   # Run initial quality checks
   make quality

Code Style Standards
---------------------

This project follows strict code quality standards:

YAML Files
~~~~~~~~~~

* Use 2 spaces for indentation
* No trailing whitespace
* Use consistent quoting
* Follow yamllint configuration

Python Files
~~~~~~~~~~~~

* Follow PEP 8 guidelines
* Use Black for code formatting
* Use isort for import sorting
* Include type hints where appropriate

Ansible Code
~~~~~~~~~~~~

* Follow ansible-lint rules
* Use descriptive task names
* Include proper error handling
* Document complex tasks with comments

Testing
-------

Before submitting changes, ensure all tests pass:

.. code-block:: bash

   # Run quality checks
   make quality

   # Run Molecule tests
   make test

   # Run security scans
   make security

   # Run full CI/CD pipeline locally
   make ci

Types of Contributions
----------------------

Bug Fixes
~~~~~~~~~~

1. Create an issue describing the bug
2. Fork the repository
3. Create a bugfix branch
4. Write tests that reproduce the bug
5. Fix the bug
6. Ensure all tests pass
7. Submit a pull request

Features
~~~~~~~~

1. Open an issue to discuss the feature
2. Fork the repository
3. Create a feature branch
4. Write tests for the new feature
5. Implement the feature
6. Update documentation
7. Ensure all tests pass
8. Submit a pull request

Documentation
~~~~~~~~~~~~

Documentation improvements are always welcome:

* Fix typos and grammatical errors
* Improve existing documentation
* Add examples and use cases
* Document new features

Submit documentation changes through pull requests with the prefix ``docs:``.

Pull Request Process
---------------------

Before submitting a pull request:

1. **Branch Naming**: Use descriptive branch names
   * ``feature/your-feature-name``
   * ``bugfix/your-bugfix-name``
   * ``docs/your-docs-change``

2. **Commit Messages**: Follow conventional commit format
   * ``feat: add new feature``
   * ``fix: resolve bug description``
   * ``docs: update installation guide``

3. **Quality Checks**: Ensure all quality checks pass
   * ``make quality`` must pass
   * ``make test`` must pass
   * ``make security`` must pass

4. **Documentation**: Update relevant documentation
   * README.md if needed
   * Role documentation
   * Changelog for significant changes

5. **Testing**: Include tests for new functionality
   * Unit tests for new modules
   * Integration tests for roles
   * Molecule tests for infrastructure

Pull Request Template
---------------------

Use this template for pull requests:

````markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review of the code completed
- [ ] Documentation updated
- [ ] Changelog updated (if applicable)
````

Release Process
---------------

Releases are managed through semantic versioning:

1. **Patch Release** (x.x.1): Bug fixes only
2. **Minor Release** (x.1.x): New features, backward compatible
3. **Major Release** (1.x.x): Breaking changes

Release Steps:

1. Update version in galaxy.yml
2. Update CHANGELOG.md
3. Create git tag
4. Build and publish collection
5. Update Ansible Galaxy

Community Guidelines
--------------------

* Be respectful and inclusive
* Provide constructive feedback
* Help others learn and grow
* Follow the code of conduct
* Focus on what is best for the community

Getting Help
------------

If you need help:

* Check existing issues and documentation
* Create an issue with detailed information
* Join discussions in GitHub
* Reach out to maintainers

Resources
---------

* `Ansible Documentation <https://docs.ansible.com>`_
* `Molecule Documentation <https://molecule.readthedocs.io>`_
* `Ansible Collection Development <https://docs.ansible.com/ansible/latest/dev_guide/developing_collections.html>`_

Thank you for contributing to kaitranntt.mac!