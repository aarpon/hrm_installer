hrm_installer
=============

Set of bash scripts for the automated installation and configuration of the
Huygens Remote Manager (HRM).


About
-----

This set of Bash scripts guides you through the installation and configuration
process of the Huygens Remote Manager (HRM). It installs all necessary
dependencies, configures the web server, sets up the database, downloads the
latest version of HRM and sets the required permissions, SELinux and firewall
rules. The scripts may be used for quick installation of HRM and testing.
However, for production use review and further configuration is recommended.
In this case, please also read the HRM installation documentation
(http://huygens-remote-manager.readthedocs.org/en/latest/admin/index.html)


Changelog
---------

Version 0.2 (Jun. 2016):
  - Updated scripts for Ubuntu 16.04 and CentOS 7

Version 0.1 (Jun. 2015):
  - Initial release


Requirements
------------

* Ubuntu 14.04+, CentOS 7
* Superuser rights
* Internet connection
* HuCore installation and license

HuCore must already be running on the machine.


Usage
-----

Go to the shell, change to the installation script's directory and run:

```
$ su -c "bash setup.sh"
```

Then follow the on-screen instructions and fill in your desired settings. When
the installation has completed successfully, please reboot the computer. After
that you may use HRM via your web browser on localhost at your chosen path,e.g.
http://localhost/hrm/ . The default HRM admin account name and password are
admin / pwd4hrm .


Detailed steps
--------------

These are the steps performed by the installation script in more detail.

1. Check for HuCore installation and get installation path.
2. Check for missing dependencies and try to install those packages. If a
   database management system, either MySQL/MariaDB or PostgreSQL, is missing
   you have to choose one.
3. Configuration of missing packages through system's package manager.
4. Creation of HRM's system account, database account and database for chosen
   DBMS. You have to provide or set account names and passwords.
5. Installation and configuration of HRM. The latest stable version will be
   downloaded or you may also offer an offline ZIP file of HRM. You have to
   provide the installation path and an image data storage path.
6. Setup of web server, configuring PHP, creating the database and running the
   HRM queue manager as system daemon.
7. Setting all necessary access permissions. The apache web server user will
   become member of the hrmgroup, the queue manager is run as hrmuser, and the
   image data storage directory's group is set to hrmgroup with sticky bit
   enabled. For Fedora and CentOS also the required SELinux and firewall rules
   are set.


Authors and contact
-------------------

Author of the HRM installation scripts:

Torsten Stöter (torsten.stoeter@lin-magdeburg.de),
Leibniz Institute for Neurobiology, Magdeburg

Further authors of the Huygens Remote Manager:
* Aaron Ponti, Department of Biosystems Science and Engineering, ETH Zurich
* Daniel Sevilla, Scientific Volume Imaging (Hilversum)
* Niko Ehrenfeuchter, Biozentrum (Basel)
* Olivier Burri, BioImaging and Optics Platform, EPFL (Lausanne)
* Frederik Grüll, Biozentrum (Basel)


Copyright and licensing
-----------------------

This software is copyright by the HRM developers (see above) and licensed under
GPLv3 (http://www.gnu.org/licenses/gpl.txt).

