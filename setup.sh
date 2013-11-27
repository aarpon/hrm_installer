#!/bin/bash

# Ensure we don't get localized output from various tools, otherwise many of
# the tests will behave pretty much unpredictable.
export LC_ALL=C

echo "Welcome to the HRM installation script."

source funs.sh

echo "Looking for hucore installation."
hucorepath=`which hucore`
[ -z  "$hucorepath" ] && abort "Hucore could not be found."

source inst-pkgs.sh

source conf-db-generic.sh

source inst-hrm.sh
source conf-hrm.sh
source conf-php.sh
source make-db.sh
source conf-qm.sh
source perms.sh

echo "Please restart apache and change the default admin password 'pwd4hrm'."
