#!/bin/bash

# start mysql, if its not running
if [ "$dist" == "Ubuntu" ]
then
	if $(service mysql status | grep -q 'inactive') ; then
		service mysql start
	fi
	
	echo "Enter password for the new HRM database user"
	db_pass=`readstring`

	# connect to mysql server and create user
	# mysqlcmd === mysql -u root -p -e "command" -> opens password prompt
	echo "Please enter MySQL root password."
	mysql -u root -p -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; CREATE DATABASE $db_name; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
elif [ "$dist" == "Fedora" ]
then
	if $(service mysqld status | grep -q 'inactive') ; then
		service mysqld start
	fi
	
	echo "Enter password for the new HRM database user"
	db_pass=`readstring`

	# when run as sudo/root, no mysql admin credentials needed
	mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; CREATE DATABASE $db_name; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
else
	abort "Distribution unsupported."
fi

## first check if fresh mysql installation
# then set root password yourself

# get DB admin user credentials
#echo "Enter user name of MySQL administrator"
#db_adm=`readstring "root"`

#echo "Enter password of MySQL administrator"
#db_admpass=`readstring`

#mysqlcmd $db_adm $db_admpass "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
#mysqlcmd $db_adm $db_admpass "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION;"
