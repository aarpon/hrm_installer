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

Version 0.3 (Nov. 2018):
  - Added whiptail dialogs and a non-interactive mode
  
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
$ sudo ./setup.sh
```

Then follow the on-screen instructions and fill in your desired settings. When
the installation has completed successfully, please reboot the computer. After
that you may use HRM via your web browser on localhost at your chosen path,e.g.
http://localhost/hrm/ . The default HRM admin account name and password are
admin / pwd4hrm .


Detailed steps
--------------

These are the steps performed by the installation script in more detail. They are grouped under 7 different headings:

1. Installing system packages (step 1/7)
2. Configuring the database (step 2/7)
3. Installing HRM files (step 3/7)
4. Configuring HRM (step 4/7)
5. Configuring PHP (step 5/7)
6. Making the database (step 6/7)
7. Configuring the queue manager (step 7/7)

And under the hood, the following operations are performed:

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


Non-interactive mode and script modifiers
-----------------------------------------

In non-interactive mode, the script can perform a complete installation without any user intervention. Simply add the `--interactive=false` flag to the command:

```
$ sudo ./setup.sh --interactive=false
```

The following default values will be used. However, any of those can be set via the command-line (e.g. `--hrmtag="devel"`).

| Variable name | Default value | Function |
| --- | --- | --- |
| interactive | true | Interactive mode |
| debug | false | Some debug output |
| devel | false | Install the development version of HRM |
| help | false | Very limited help |
| dbtype | "mysql" | The database type ("mysql" or "pgsql") |
| dbhost | "localhost" | The database hostname |
| dbadmin | "root" | The database admin user |
| adminpass | "" | The default admin password |
| dbname | "hrm" | The name of the HRM database |
| dbuser | "hrmuser" | The name of the database user for HRM |
| dbpass | "pwd4hrm" | The password of the HRM database user |
| sysuser | "hrmuser" | The system user that will run the HRM queue manager |
| sysgroup | "hrm" | The system group the of the HRM system user |
| apache_user | "www-data" | The apache user |
| hrmdir | "/var/www/html/hrm" | The location of the HRM website |
| hrmrepo | "https://github.com/aarpon/hrm.git" | The GIT repository used for pulling HRM |
| hrmtag | "latest" | The HRM tar or branch ("latest" is converted to the tag of the current release) |
| imgdir | "/data/images" | The folder HRM will use to store images and user data |
| hrmemail | "hrm@localhost" | The email address which will appear when HRM sends e-mails |
| hrmpass | "pwd4hrm" | The default HRM admin password |
| zippath | "" | The path of a zip installation file which will be used instead of the GIT repository |

Script usage
------------

Here are some ways in which the script can be used.

To run the script in non-interactive mode:

```
$ sudo ./setup.sh --interactive=false
```

To install the development version of HRM, use the following command:

```
$ sudo ./setup.sh -D
```

To install from a zip file (the path will be checked):

```
$ sudo ./setup.sh --zipfile="hrm_v3.4.0.zip"
```

To change the folder in which HRM will be installed:

```
$ sudo ./setup.sh --hrmdir="/var/www"
```

To change the email address HRM uses to communicate:

```
$ sudo ./setup.sh --hrmmail="hrm@valid.email.address"
```


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
* Egor Zindy, University of Manchester

Copyright and licensing
-----------------------

This software is copyright by the HRM developers (see above) and licensed under
GPLv3 (http://www.gnu.org/licenses/gpl.txt).

