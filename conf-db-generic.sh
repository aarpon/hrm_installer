#!/bin/bash

source funs.sh

echo "Create new database account for HRM?"
if [ $(readkey_choice) == "y" ] ; then
    echo -e "\nEnter new user name to create for the HRM database"
    db_user=`readstring "hrm_user"`

    if [ "$dbtype" == "m" ];
    then
        source conf-db-mysql.sh
        dbtype="mysql"
    elif [ "$dbtype" == "p" ]
    then
        source conf-db-pgsql.sh
        dbtype="postgres"
    fi
else
    echo -e "\nEnter existing user name for the HRM database"
    db_user=`readstring "hrm_user"`

    echo "Enter password for the HRM database user"
    db_pass=`readstring`
fi

# The dbupdate script takes care if the DB already exists or creates it
# otherwise, so wee need the name in any case for the config file:
echo "Enter the name of the database to use for the HRM"
db_name=`readstring "hrm"`
