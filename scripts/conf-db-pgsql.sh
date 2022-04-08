#!/bin/bash

# init and start pgsql
function init_dbms() {
    [[ $isfedorabased == true ]] && postgresql-setup initdb
    service postgresql start
    #systemctl enable postgresql.service
    #systemctl start postgresql.service
}

# create postgresql dabase
function create_db() {
    REPLY=`su - postgres -c "createdb $dbname"` && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

# drop postgresql dabase
function drop_db() {
    REPLY=`su - postgres -c "dropdb $dbname"` && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

# check whether database dbname exists
function check_db() {
    REPLY=`su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -qw $dbname"` && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

# create postgresql user
function create_user() {
    REPLY=`su - postgres -c "psql -c \"CREATE USER $dbuser WITH PASSWORD '$dbpass';\""` && rc=$? || rc=$?
    #REPLY=`su - postgres -c "createuser -e -P -d -A -S -R -N $dbuser"`
    #dbpass=`echo "$rc" | awk -F"PASSWORD" '{print $2}' | awk '{print $1}' | tr -d "'"`

    # enable MD5 password authentication
    # only necessary for Fedora and CentOS
    # under Ubuntu MD5 is already the default authentication
    if [[ $isfedorabased == true ]];
    then
        echo "Configure postgres for MD5 host authentication..."
        echo -e "host all $dbuser 127.0.0.1/32 md5 \nhost all $dbuser ::1/128 md5\n $(cat /var/lib/pgsql/data/pg_hba.conf)" > /var/lib/pgsql/data/pg_hba.conf
        service postgresql restart
    #	systemctl restart postgresql.service
    fi
    echo $REPLY
    return $rc
}

function check_user() {
    REPLY=`su - postgres -c "psql -t -c '\du' | cut -d \| -f 1 | grep -qw $dbuser"` && rc=$? || rc=$?
    echo $REPLY
    return $rc
}

function link_user_db() {
    # Starting point: https://stackoverflow.com/questions/22483555/give-all-the-permissions-to-a-user-on-a-db/22484041
    sql="REVOKE ALL ON DATABASE \\\"$dbname\\\" FROM public; GRANT CONNECT ON DATABASE \\\"$dbname\\\" TO $dbuser; GRANT USAGE ON SCHEMA public TO $dbuser; GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $dbuser; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $dbuser;"
    REPLY=`su - postgres -c "psql -c \"$sql\""` && rc=$? || rc=$?
    return $rc
}
