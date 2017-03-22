#!/bin/bash

# start mysql, if its not running
if [ "$dist" == "Ubuntu" ] || [ "$dist" == "Debian" ]
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
	if $(service mariadb status | grep -q 'inactive') ; then
		service mariadb start
	fi
	
	echo "Enter password for the new HRM database user"
	db_pass=`readstring`

	# when run as sudo/root, no mysql admin credentials needed
	mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass'; CREATE DATABASE $db_name; GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
else
	abort "Distribution unsupported."
fi
