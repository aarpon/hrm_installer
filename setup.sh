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

source funs.sh

echo -n "Looking for hucore installation: "
# "which" exits with non-zero in case the command couldn't be found, so we can
# use the exit status directly to test for success:
hucorepath=`which hucore` || abort "Hucore could not be found."
echo $hucorepath

source inst-pkgs.sh

source conf-db-generic.sh

source inst-hrm.sh
source conf-hrm.sh
source conf-php.sh
source make-db.sh
source conf-qm.sh
source perms.sh

echo "Please restart apache and change the default admin password 'pwd4hrm'."
