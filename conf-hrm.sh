#!/bin/bash

source funs.sh

# copy config file
cp $hrmdir/config/samples/hrm.conf.sample /etc/hrm.conf

# do substitutions in config file
sedconf /etc/hrm.conf "HRM_HOME=\"/path/to/hrm/home\"" "HRM_HOME=\"$hrmdir\""
sedconf /etc/hrm.conf "SUSER=\"hrm\"" "SUSER=\"hrm-user\""

# copy more config files
cp $hrmdir/config/samples/hrm_server_config.inc.sample $hrmdir/config/hrm_server_config.inc

# do substitutions in config file
sedconf $hrmdir/config/hrm_server_config.inc '$db_type = "mysql";' '$db_type = "'$dbtype'";'
sedconf $hrmdir/config/hrm_server_config.inc '$db_user = "dbuser";' '$db_user = "'$db_user'";'
sedconf $hrmdir/config/hrm_server_config.inc '$db_password = "dbpasswd";' '$db_password = "'$db_pass'";'
sedconf $hrmdir/config/hrm_server_config.inc '$hrm_path = "/var/www/html/hrm";' '$hrm_path = "'$hrmdir'";'
sedconf $hrmdir/config/hrm_server_config.inc '$local_huygens_core = "/usr/local/bin/hucore";' '$local_huygens_core = "'$hucorepath'";'

# get image store
echo "Enter image storage directory"
imgdir=`readstring "/data/images"`

# check if $imgdir exists
if [ ! -d $imgdir ];
then
	echo "Image storage directory $imgdir does not exist, create it? [y/n]"
	if [ $(readkey) == "y" ];
	then
		mkdir -vp $imgdir
		chown $hrm_user $imgdir
		chgrp $hrm_group $imgdir
		chmod u+s,g+ws $imgdir
	fi
fi

sedconf /etc/hrm.conf "HRM_DATA=\"/path/to/hrm/data\"" "HRM_DATA=\"$imgdir\""
sedconf $hrmdir/config/hrm_server_config.inc '$image_folder = "/path/to/hrm_data";' '$image_folder = "'$imgdir'";'
sedconf $hrmdir/config/hrm_server_config.inc '$huygens_server_image_folder = "/path/to/hrm_data/";' '$huygens_server_image_folder = "'$imgdir'/";'

echo "Enter HRM administrator's email address"
hrmemail=`readstring`
sedconf $hrmdir/config/hrm_server_config.inc '$email_sender = "hrm@localhost";' '$email_sender = "'$hrmemail'";'
sedconf $hrmdir/config/hrm_server_config.inc '$email_admin = "hrm@localhost";' '$email_admin = "'$hrmemail'";'

# assume client and server run on same machine, config file are identical
ln -s $hrmdir/config/hrm_server_config.inc $hrmdir/config/hrm_client_config.inc
