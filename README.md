hrm_installer
=============

Set of bash scripts for the automated installation and setup of the Huygens
Remote Manager (HRM).

About
-----

This set of Bash scripts guides you through the installation and configuration
process of the Huygens Remote Manager (HRM). It installs all necessary
dependencies, configures the web server, sets up the database, downloads the
latest version of HRM and sets the required permissions. The scripts may be used
for quick installation of HRM and testing. However, for production use further
configuration is recommended. In this case, please also read the HRM
installation documentation
(http://huygens-remote-manager.readthedocs.org/en/latest/admin/index.html)

Changelog
---------

Requirements
------------

* Ubuntu 14.04 or Fedora 21
* Superuser rights
* HuCore installation and license

HuCore must be running on the same machine.

Usage
-----

Go to the shell, run

$ sudo bash setup.sh

and follow the on-screen instuctions.

The default account names and passwords are as follows:


Detailed steps
--------------

These are the steps performed by the installation script in more detail.

1. Check for HuCore installation and get installation path.
2. Check for missing dependencies and try to install those packages. If a
   database management system, either MySQL or PostgreSQL is missing you have to
   choose.
3. Configuration of missing packages through system's package manager.
4. Creation of HRM's system account, database account and database for chosen
   DBMS.
5. Installation of HRM by downloading latest version or supplying downloaded ZIP
   file.

Troubleshooting
---------------

Contact
-------

Copyright and licensing
-----------------------


