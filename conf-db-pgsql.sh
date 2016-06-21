#!/bin/bash

# init and start pgsql
[ "$dist" == "Fedora" ] && postgresql-setup initdb
service postgresql start
#systemctl enable postgresql.service
#systemctl start postgresql.service

# create postgresql user
pgret=`su postgres -c "createuser -e -P -d -A -S -R -N $db_user"`
db_pass=`echo "$pgret" | awk -F"PASSWORD" '{print $2}' | awk '{print $1}' | tr -d "'"`
pgret=`su postgres -c "createdb $db_name"`

# enable MD5 password authentication
# only necessary for Fedora and CentOS
# under Ubuntu MD5 is already the default authentication
if [ "$dist" == "Fedora" ]
then
	echo "Configure postgres for MD5 host authentication..."
	echo -e "host all $db_user 127.0.0.1/32 md5 \nhost all $db_user ::1/128 md5\n $(cat /var/lib/pgsql/data/pg_hba.conf)" > /var/lib/pgsql/data/pg_hba.conf
	service postgresql restart
#	systemctl restart postgresql.service
fi

