Modules
=======

This collection currently does not include custom modules. All functionality is provided through Ansible roles and built-in modules.

If you need custom modules for macOS-specific tasks, they will be documented here when added.

Built-in Modules Used
---------------------

The collection leverages the following Ansible built-in modules:

* ``ansible.builtin.command`` - Execute system commands
* ``ansible.builtin.shell`` - Execute shell commands
* ``ansible.builtin.package`` - Package management
* ``ansible.builtin.service`` - Service management
* ``ansible.builtin.stat`` - File system information
* ``ansible.builtin.copy`` - File copying
* ``ansible.builtin.template`` - Template processing
* ``ansible.builtin.assert`` - Condition validation
* ``ansible.builtin.debug`` - Debug output
* ``ansible.builtin.fail`` - Error handling
* ``ansible.builtin.set_fact`` - Variable assignment
* ``ansible.builtin.include_tasks`` - Task inclusion

Future Modules
--------------

Planned custom modules for future releases:

* ``tailscale_info`` - Gather Tailscale status information
* ``tailscale_route`` - Manage Tailscale routes
* ``tailscale_acl`` - Manage Tailscale ACLs
* ``macos_pref`` - Manage macOS preferences
* ``macos_profile`` - Manage macOS configuration profiles
