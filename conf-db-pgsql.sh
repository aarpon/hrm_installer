#!/bin/bash

# start mysql, if its not running
service postgresql start

# create postgresql user
pgret=`su postgres -c "createuser -e -P -d -A -S -R -N $db_user"`
db_pass=`echo "$pgret" | awk -F"PASSWORD" '{print $2}' | awk '{print $1}' | tr -d "'"`

