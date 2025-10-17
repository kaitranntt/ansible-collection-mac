Installation
============

Requirements
------------

* Ansible >= 2.19.0
* Python >= 3.11
* macOS host (for collection usage)

From Ansible Galaxy
-------------------

Install the collection from Ansible Galaxy:

.. code-block:: bash

   ansible-galaxy collection install kaitranntt.mac

From Source
-----------

Clone the repository and install the collection:

.. code-block:: bash

   git clone https://github.com/kaitranntt/ansible-collection-mac.git
   cd ansible-collection-mac
   ansible-galaxy collection install .

Development Installation
-------------------------

For development, clone the repository and create a symlink:

.. code-block:: bash

   git clone https://github.com/kaitranntt/ansible-collection-mac.git
   cd ansible-collection-mac
   ansible-galaxy collection link .

Dependencies
------------

The collection requires the following Python packages for development:

.. code-block:: bash

   pip install -r requirements-dev.txt

For production usage, ensure you have:

* Ansible core packages
* Required system packages on target macOS hosts

Verification
------------

To verify the installation:

.. code-block:: bash

   ansible-galaxy collection list | grep kaitranntt.mac

You should see the collection listed with its version.
