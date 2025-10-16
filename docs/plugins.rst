Plugins
=======

This collection currently does not include custom plugins. All functionality is provided through Ansible roles and built-in plugins.

If you need custom plugins for macOS-specific tasks, they will be documented here when added.

Built-in Plugins Used
---------------------

The collection leverages the following Ansible built-in plugins:

Filters
~~~~~~~

* ``default`` - Default value filtering
* ``join`` - List joining
* ``length`` - List length calculation
* ``bool`` - Boolean conversion
* ``regex_replace`` - Regular expression replacement

Tests
~~~~~

* ``defined`` - Variable definition testing
* ``bool`` - Boolean value testing
* ``in`` - Membership testing

Lookups
~~~~~~~

* ``file`` - File content lookup
* ``env`` - Environment variable lookup

Future Plugins
--------------

Planned custom plugins for future releases:

Filters
~~~~~~~

* ``tailscale_status`` - Parse Tailscale status output
* ``macos_version`` - Parse macOS version information
* ``semver`` - Semantic version filtering

Lookups
~~~~~~~

* ``tailscale_key`` - Secure Tailscale key retrieval
* ``macos_pref`` - macOS preference lookup

Connection Plugins
~~~~~~~~~~~~~~~~~

* ``tailscale`` - Direct Tailscale network connection