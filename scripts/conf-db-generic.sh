#!/bin/bash

source funs.sh

# The dbupdate script takes care if the DB already exists or creates it
# otherwise, so wee need the name in any case for the config file:
echo "Enter the name of the database to use for the HRM"
db_name=`readstring "hrm"`

echo "Create new database account for HRM?"
if [ $(readkey_choice) == "y" ] ; then
    echo -e "\nEnter new user name to create for the HRM database"
    db_user=`readstring "hrmuser"`

    if [ "$dbtype" == "mysql" ];
    then
        source conf-db-mysql.sh
    elif [ "$dbtype" == "postgres" ]
    then
        source conf-db-pgsql.sh
    else
        abort "Could not configure database."
    fi
else
    echo -e "\nEnter existing user name for the HRM database"
    db_user=`readstring "hrmuser"`

    echo "Enter password for the HRM database user"
    db_pass=`readstring`
fi
