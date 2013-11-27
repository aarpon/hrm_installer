#!/bin/bash

source funs.sh

echo "Create new database account for HRM? [y/n]"

if [ $(readkey) == "y" ];
then
	# start mysql, if its not running
	service postgresql start

	# get user name
	echo "Enter new user name to create for HRM database"
	db_user=`readstring "hrm_user"`

	# create postgresql user
	pgret=`su postgres -c "createuser -e -P -d -A -S -R -N $db_user"`
	db_pass=`echo "$pgret" | awk -F"PASSWORD" '{print $2}' | awk '{print $1}' | tr -d "'"`
else
	# get user credentials
	echo "Enter existing user name for HRM database"
	db_user=`readstring "hrm_user"`

	echo "Enter password for HRM database user"
	db_pass=`readstring`
fi

