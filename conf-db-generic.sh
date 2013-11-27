#!/bin/bash

source funs.sh

echo "Create new database account for HRM? [y/n]"
if [ $(readkey) == "y" ] ; then
    # get user credentials
    echo "Enter new user name to create for the HRM database"
    db_user=`readstring "hrm_user"`

    if [ "$dbtype" == "m" ];
    then
        source conf-mysql.sh
        dbtype="mysql"
    elif [ "$dbtype" == "p" ]
    then
        source conf-pgsql.sh
        dbtype="postgres"
    fi
else
    # get user credentials
    echo "Enter existing user name for the HRM database"
    db_user=`readstring "hrm_user"`

    echo "Enter password for the HRM database user"
    db_pass=`readstring`
fi
