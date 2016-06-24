#!/bin/bash

# Exit on any error. That's very important as we require being run as root and
# thus anything that goes wrong has a huge potential impact on the system.
set -o errexit

# "xtrace" can be switched on for debugging if desired.
# set -o xtrace

# Ensure we don't get localized output from various tools, otherwise many of
# the tests will behave pretty much unpredictable.
export LC_ALL=C

echo "Welcome to the HRM installation script."

source scripts/funs.sh

#dist=`cat /etc/issue | head -n1 | cut -d ' ' -f1`;
dist=`cat /etc/os-release | head -n1 | grep -Po '".*?"' | tr -d '"'`
vers=`cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2`

if  [ "$dist" == "" ]
then
	dist=`cat /etc/os-release | head -n1 | cut -d '=' -f2`
fi

if [ "$dist" == "Ubuntu" ]
then
	source scripts/funs-ubu.sh
elif [ "$dist" == "Fedora" ]
then
	fedpkg="dnf"
	source scripts/funs-fed.sh
elif [ "$dist" == "CentOS Linux" ]
then
	dist="Fedora"
	fedpkg="yum"
	source scripts/funs-fed.sh
else
	abort "Distribution unsupported."
fi

echo -n "Looking for hucore installation: "
# "which" exits with non-zero in case the command couldn't be found, so we can
# use the exit status directly to test for success:
hucorepath=`which hucore` || { echo "Hucore could not be found, please provide full path:"; hucorepath=`readstring "/usr/local/svi/bin/hucore"`; }

source scripts/inst-pkgs.sh

source scripts/conf-db-generic.sh

source scripts/inst-hrm.sh
source scripts/conf-hrm.sh
source scripts/conf-php.sh
source scripts/make-db.sh
source scripts/conf-qm.sh
source scripts/perms.sh

if [ "$dist" == "Fedora" ]
then
	echo "Apache, database and queue manager system services will start automatically at boot."
	systemctl enable httpd.service
	[[ "$dbtype" == "postgres" ]] && systemctl enable postgresql.service
	[[ "$dbtype" == "mysql" ]] && systemctl enable mariadb.service
fi

echo "Please restart your system and open HRM in your web browser (e.g., http://localhost/hrm/)."
echo "The default admin account is login 'admin' with password 'pwd4hrm'."

