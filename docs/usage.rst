Usage Guide
===========

Basic Usage
-----------

To use the kaitranntt.mac collection in your playbooks, include the collection namespace:

.. code-block:: yaml

   - name: Install and configure Tailscale
     hosts: macos_hosts
     collections:
       - kaitranntt.mac
     tasks:
       - name: Include Tailscale role
         include_role:
           name: tailscale

Example Playbooks
-----------------

Basic Tailscale Installation
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Install Tailscale
     hosts: all
     become: true
     vars:
       tailscale_auth_key: "your-auth-key-here"
       tailscale_state: present
     roles:
       - kaitranntt.mac.tailscale

Advanced Configuration
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Advanced Tailscale setup
     hosts: all
     become: true
     vars:
       tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
       tailscale_args:
         - "--accept-dns=false"
         - "--accept-routes=true"
         - "--advertise-routes=192.168.1.0/24"
       tailscale_oauth_client_id: "{{ vault_tailscale_client_id }}"
       tailscale_oauth_client_secret: "{{ vault_tailscale_client_secret }}"
       tailscale_logout: false
       tailscale_force_restart: false
       tailscale_start_service: true
     roles:
       - kaitranntt.mac.tailscale

Uninstall Tailscale
~~~~~~~~~~~~~~~~~~~

.. code-block:: yaml

   - name: Remove Tailscale
     hosts: all
     become: true
     vars:
       tailscale_state: absent
     roles:
       - kaitranntt.mac.tailscale

Configuration Variables
-----------------------

Essential Variables
~~~~~~~~~~~~~~~~~~~

.. list-table:: Essential Tailscale Variables
   :header-rows: 1
   :widths: 30 70

   * - Variable
     - Description
   * - ``tailscale_auth_key``
     - Tailscale authentication key (required for initial setup)
   * - ``tailscale_state``
     - Desired state: ``present`` or ``absent``
   * - ``tailscale_installation_method``
     - Installation method: ``go``, ``binary``, or ``homebrew``

Advanced Variables
~~~~~~~~~~~~~~~~~~

.. list-table:: Advanced Configuration Variables
   :header-rows: 1
   :widths: 30 70

   * - Variable
     - Description
   * - ``tailscale_args``
     - Additional command-line arguments for Tailscale
   * - ``tailscale_built_args``
     - Built-in arguments combined with ``tailscale_args``
   * - ``tailscale_oauth_client_id``
     - OAuth client ID for authentication
   * - ``tailscale_oauth_client_secret``
     - OAuth client secret for authentication
   * - ``tailscale_logout``
     - Whether to logout before re-authenticating
   * - ``tailscale_force_restart``
     - Whether to force restart Tailscale service
   * - ``tailscale_start_service``
     - Whether to start Tailscale service after installation

Network Configuration
~~~~~~~~~~~~~~~~~~~~~

.. list-table:: Network Configuration Variables
   :header-rows: 1
   :widths: 30 70

   * - Variable
     - Description
   * - ``tailscale_advertise_routes``
     - List of routes to advertise
   * - ``tailscale_accept_routes``
     - Whether to accept advertised routes
   * - ``tailscale_accept_dns``
     - Whether to accept DNS configuration
   * - ``tailscale_timeout``
     - Operation timeout in seconds

Security Considerations
-----------------------

When using this collection:

* Store sensitive authentication keys in Ansible Vault
* Use OAuth authentication when possible instead of auth keys
* Review and understand the Tailscale security model
* Test configurations in non-production environments first
* Regularly rotate authentication keys

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

**Authentication Failures**
  - Verify auth key is valid and not expired
  - Check network connectivity to Tailscale servers
  - Ensure proper permissions on target hosts

**Service Issues**
  - Check macOS service status with ``launchctl list``
  - Review Tailscale logs in ``/var/log/tailscaled.log``
  - Verify proper file permissions

**Network Connectivity**
  - Test connectivity to Tailscale servers
  - Check firewall rules and network policies
  - Verify DNS configuration

Debug Mode
~~~~~~~~~~

Enable debug mode for troubleshooting:

.. code-block:: yaml

   - name: Debug Tailscale installation
     hosts: all
     become: true
     vars:
       tailscale_debug: true
     roles:
       - kaitranntt.mac.tailscale