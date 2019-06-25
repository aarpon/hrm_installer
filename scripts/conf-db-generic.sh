#!/bin/bash

# The dbupdate script
#   checks whether the $dbname db exists and if not creates it.
#   checks whether the $dbuser user exists and if not creates it.
#   links $dbuser to $dbname 

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"
source "$context/funs-input.sh"

#Choose between the mysql and pgsql function prototypes
if [ "$dbtype" == "mysql" ]; then
    source "$context/conf-db-mysql.sh"
else
    source "$context/conf-db-pgsql.sh"
fi

# Add the DBMS type to the title
title=${title//database/${dbms[$dbtype]} database}

REPLY=$(init_dbms) && rc=$? || rc=$?
echo "Initializing the DBMS: rc=$rc -- $REPLY"

# For mysql, we allow the possibility to connect to a remote database
# FIXME do the same for pgsql
if [ "$dbtype" == "mysql" ]; then
    msg="HRM database host"
    dbhost=$(wt_read "$dbhost" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
fi

# Check the admin username and password
if [ "$dbtype" == "mysql" ]; then
    while : ;
    do
        REPLY=$(check_admin) && rc=$? || rc=$?
        [ $rc -eq 0 ] && break 

        wt_print "$REPLY" --title="$title" --interactive=$interactive
        if [ $interactive == true ]; then
            msg="admin username for MySQL"
            dbadmin=$(wt_read "$dbadmin" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

            msg="admin password for MySQL"
            adminpass=$(wt_read "$adminpass" --interactive=$interactive --title="$title" --message="$msg" --password=true --allowempty=true)
        else
            exit 1
        fi
    done
fi

# Let the user enter the database name
msg="HRM database name"
[ $interactive == true ] && msg="$msg. It will be created if unavailable"
dbname=$(wt_read "$dbname" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

# Check if we have a database.
REPLY=$(check_db) && rc=$? || rc=$?
if [ $rc == 0 ]; then
    msg="The database $dbname already exists."
    wt_print "$msg" --title="$title" --interactive=false
else
    # If not, create one.
    REPLY=$(create_db) && rc=$? || rc=$?
    if [ $rc != 0 ]; then 
        msg="The database $dbname could not be created. Contact your system administrator.\n$REPLY"
        wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
    fi
fi

# Let the user enter a user name. (create a new user if not already defined)
msg="username for the HRM database"
[ $interactive == true ] && msg="$msg. A new user will be created if unavailable"
dbuser=$(wt_read "$dbuser" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

# Check if we have a user
REPLY=$(check_user) && rc=$? || rc=$?
if [ $rc == 0 ]; then
    msg="The user $dbuser already exists."
    wt_print "$msg" --title="$title" --interactive=false
else
    # If not, create one.

    #Here we want to display the password...
    msg="password for the HRM user"
    dbpass=$(wt_read "$dbpass" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false --password=false)

    REPLY=$(create_user) && rc=$? || rc=$?
    if [ $rc != 0 ]; then 
        msg="The user $dbuser could not be created. Contact your system administrator.\n$REPLY"
        wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
    fi
fi

# Give dbuser access to dbname
REPLY=$(link_user_db) && rc=$? || rc=$?
if [ $rc != 0 ]; then 
    msg="The user $dbuser could not be linked to database $dbname. Contact your system administrator.\n$REPLY"
    wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
fi

