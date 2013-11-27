#!/bin/bash

# start mysql, if its not running
service mysql start

echo "Enter password for the new HRM database user"
db_pass=`readstring`

# get DB admin user credentials
echo "Enter user name of MySQL administrator"
db_adm=`readstring "root"`

echo "Enter password of MySQL administrator"
db_admpass=`readstring`

# connect to mysql server and create user
mysqlcmd $db_adm $db_admpass "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
mysqlcmd $db_adm $db_admpass "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost' WITH GRANT OPTION;"

