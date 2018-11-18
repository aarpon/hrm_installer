#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"

function start_mysql() {
    rc=0
    if [ "$dist" == "Ubuntu" ] || [ "$dist" == "Debian" ]
    then
        if $(service mysql status | grep -q 'inactive') ; then
            rc=$(service mysql start)
        fi
        
    elif [ "$dist" == "Fedora" ]
    then
        if $(service mariadb status | grep -q 'inactive') ; then
            rc=$(service mariadb start)
        fi
    else
        #unknown distribution
        return 1
    fi
    return $rc
}

function docommand() {
    #FIXME Always a danger that a sql statement could start with "mysql"
    if [[ "$1" =~ ^mysql.* ]]; then
        cmd=$1
    else
        cmd="mysql -u $dbadmin -p$adminpass --host=$dbhost -e \"$1\""
    fi

    #Remove the -p if password is empty
    [ -z "$adminpass" ] && cmd=${cmd/ -p/}

    REPLY=$(eval $cmd 3>&1 1>&2 2>&3) && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

function check_user() {
    sql="SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user='$dbuser');"
    cmd="mysql -u $dbadmin -p$adminpass --host=$dbhost --database=$dbname -sse \"$sql\""
    [ -z "$adminpass" ] && cmd=${cmd/ -p/}

    #We need both stdout and stderr for this one.
    catch stdout stderr eval $cmd && rc=$? || rc=$?

    if [ -z $stderr ]; then
        #This means the command was successful (no error message).
        #stdout contains the number of existing users for the query (1 or 0)
        if [ $stdout -eq 0 ]; then
            rc=1
            REPLY="User $dbuser not in database $dbname"
        else
            rc=0
        fi
    else
        #There was an error message, return 1
        rc=1
    fi

    echo $REPLY
    return $rc
}

function create_user() {
    sql="CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
    echo $sql
    REPLY=$(docommand "$sql") && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

function link_user_db() {
    sql="GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    echo $sql
    REPLY=$(docommand "$sql") && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

function check_db() {
    cmd="mysql -u $dbadmin -p$adminpass --database=$dbname --host=$dbhost -e;"
    [ -z "$adminpass" ] && cmd=${cmd/ -p/}
    REPLY=$($cmd 3>&1 1>&2 2>&3) && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

#This one is same as check_db but without specifiying the database
function check_admin() {
    cmd="mysql -u $dbadmin -p$adminpass --host=$dbhost -e;"
    [ -z "$adminpass" ] && cmd=${cmd/ -p/}
    REPLY=$($cmd 3>&1 1>&2 2>&3) && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

function create_db() {
    sql="CREATE DATABASE $dbname;"
    REPLY=$(docommand "$sql") && rc=$? || rc=$?
    echo $REPLY
    return $rc
}
