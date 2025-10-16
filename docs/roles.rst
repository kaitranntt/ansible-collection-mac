Roles
=====

This collection includes the following roles:

.. toctree::
   :maxdepth: 1

   roles/tailscale

tailscale
---------

The ``tailscale`` role provides complete Tailscale VPN installation and configuration for macOS systems.

.. contents::
   :local:
   :depth: 2

Features
--------

* Multiple installation methods (Go, binary, Homebrew)
* Automatic service management with launchd
* Support for OAuth and authentication key authentication
* Route advertisement and acceptance
* DNS configuration management
* Comprehensive error handling and validation
* Cross-platform compatibility (macOS and Linux)

Requirements
------------

* macOS 10.15+ (Catalina) or later
* Administrative privileges (sudo access)
* Internet connectivity for installation
* Valid Tailscale authentication

Installation Methods
-------------------

Go Installation
~~~~~~~~~~~~~~~

Install Tailscale by building from source using Go:

.. code-block:: yaml

   - name: Install Tailscale via Go
     hosts: all
     vars:
       tailscale_installation_method: "go"
     roles:
       - kaitranntt.mac.tailscale

Binary Installation
~~~~~~~~~~~~~~~~~~

Download and install pre-compiled Tailscale binaries:

.. code-block:: yaml

   - name: Install Tailscale via binary
     hosts: all
     vars:
       tailscale_installation_method: "binary"
     roles:
       - kaitranntt.mac.tailscale

Homebrew Installation
~~~~~~~~~~~~~~~~~~~~~

Install Tailscale using Homebrew package manager:

.. code-block:: yaml

   - name: Install Tailscale via Homebrew
     hosts: all
     vars:
       tailscale_installation_method: "homebrew"
     roles:
       - kaitranntt.mac.tailscale

Configuration
------------

Basic Configuration
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Basic Tailscale setup
     hosts: all
     vars:
       tailscale_auth_key: "tskey-auth-your-key-here"
       tailscale_args:
         - "--accept-dns=true"
     roles:
       - kaitranntt.mac.tailscale

OAuth Authentication
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: OAuth-based Tailscale setup
     hosts: all
     vars:
       tailscale_oauth_client_id: "your-client-id"
       tailscale_oauth_client_secret: "your-client-secret"
     roles:
       - kaitranntt.mac.tailscale

Route Configuration
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Tailscale with route advertisement
     hosts: all
     vars:
       tailscale_auth_key: "{{ vault_tailscale_key }}"
       tailscale_advertise_routes:
         - "192.168.1.0/24"
         - "10.0.0.0/8"
       tailscale_accept_routes: true
     roles:
       - kaitranntt.mac.tailscale

Variables
---------

.. list-table:: Role Variables
   :header-rows: 1
   :widths: 35 15 50

   * - Variable
     - Default
     - Description
   * - ``tailscale_state``
     - ``present``
     - Desired state of Tailscale installation
   * - ``tailscale_installation_method``
     - ``"go"``
     - Installation method to use
   * - ``tailscale_auth_key``
     - ``""``
     - Tailscale authentication key
   * - ``tailscale_args``
     - ``[]``
     - Additional command-line arguments
   * - ``tailscale_oauth_client_id``
     - ``""``
     - OAuth client ID
   * - ``tailscale_oauth_client_secret``
     - ``""``
     - OAuth client secret
   * - ``tailscale_logout``
     - ``false``
     - Logout before re-authenticating
   * - ``tailscale_force_restart``
     - ``false``
     - Force service restart
   * - ``tailscale_start_service``
     - ``true``
     - Start service after installation
   * - ``tailscale_advertise_routes``
     - ``[]``
     - Routes to advertise
   * - ``tailscale_accept_routes``
     - ``false``
     - Accept advertised routes
   * - ``tailscale_accept_dns``
     - ``true``
     - Accept DNS configuration
   * - ``tailscale_timeout``
     - ``300``
     - Operation timeout (seconds)

Handlers
--------

The role includes the following handlers:

* ``restart tailscale`` - Restart Tailscale service
* ``load tailscale service`` - Load launchd service
* ``stop tailscale`` - Stop Tailscale service
* ``start tailscale`` - Start Tailscale service

Tasks
-----

The role is organized into the following task files:

* ``main.yml`` - Main task orchestration
* ``prerequisites.yml`` - System validation and requirements
* ``install.yml`` - Tailscale installation
* ``configure.yml`` - Tailscale configuration
* ``service.yml`` - Service management
* ``cleanup.yml`` - Cleanup on failure
* ``remove.yml`` - Uninstallation
* ``verify.yml`` - Post-installation verification

Testing
-------

The role includes comprehensive Molecule tests:

.. code-block:: bash

   cd roles/tailscale
   molecule test

Tests cover:
* Multiple installation methods
* Configuration scenarios
* Error handling
* Service management
* Cross-platform compatibility