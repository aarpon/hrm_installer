#!/bin/bash

# start mysql, if its not running
service mysql start

echo "Enter password for the new HRM database user"
db_pass=`readstring`

# get DB admin user credentials
echo "Enter user name of MySQL administrator"
	user=`readstring "root"`

echo "Enter password of MySQL administrator"
	passwd=`readstring`

# connect to mysql server and create user
mysqlcmd $user $passwd "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
mysqlcmd $user $passwd "GRANT ALL PRIVILEGES ON *.* TO '$db_user'@'localhost' WITH GRANT OPTION;"

