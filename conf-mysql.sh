#!/bin/bash

source funs.sh

echo "Create new database account for HRM? [y/n]"

if [ $(readkey) == "y" ];
then
	# start mysql, if its not running
	service mysql start

	# get user credentials
	echo "Enter user name of MySQL administrator"
	user=`readstring "root"`

	echo "Enter password of MySQL administrator"
	passwd=`readstring`

	# get user credentials
	echo "Enter new user name to create for HRM database"
	db_user=`readstring "hrm-user"`

	echo "Enter password for HRM database user"
	db_pass=`readstring`

	# connect to mysql server and create user
	mysqlcmd $user $passwd "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
	mysqlcmd $user $passwd "GRANT ALL PRIVILEGES ON *.* TO '$db_user'@'localhost' WITH GRANT OPTION;"
else
	# get user credentials
	echo "Enter existing user name for HRM database"
	db_user=`readstring "hrm-user"`

	echo "Enter password for HRM database user"
	db_pass=`readstring`
fi

