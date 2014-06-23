#!/bin/bash

source funs.sh

# copy config file
CONF_ETC="/etc/hrm.conf"
cp $hrmdir/config/samples/hrm.conf.sample $CONF_ETC

# do substitutions in config file
sedconf $CONF_ETC "HRM_HOME=\"/path/to/hrm/home\"" "HRM_HOME=\"$hrmdir\""
sedconf $CONF_ETC "SUSER=\"hrm\"" "SUSER=\"$hrm_user\""

# copy more config files
CONF_SRV="$hrmdir/config/hrm_server_config.inc"
cp $hrmdir/config/samples/hrm_server_config.inc.sample $CONF_SRV

# do substitutions in config file
sedconf $CONF_SRV '$db_type = "mysql";' '$db_type = "'$dbtype'";'
sedconf $CONF_SRV '$db_user = "dbuser";' '$db_user = "'$db_user'";'
sedconf $CONF_SRV '$db_password = "dbpasswd";' '$db_password = "'$db_pass'";'
sedconf $CONF_SRV '$db_name = "hrm";' '$db_name = "'$db_name'";'
sedconf $CONF_SRV '$hrm_path = "/var/www/html/hrm";' '$hrm_path = "'$hrmdir'";'
sedconf $CONF_SRV '$local_huygens_core = "/usr/local/bin/hucore";' '$local_huygens_core = "'$hucorepath'";'

# get image store
echo "Enter image storage directory"
imgdir=`readstring "/data/images"`

# check if $imgdir exists
if [ ! -d $imgdir ];
then
	echo "Image storage directory $imgdir does not exist, create it?"
	if [ $(readkey_choice) == "y" ];
	then
		mkdir -vp $imgdir
		chown $hrm_user $imgdir
		chgrp $hrm_group $imgdir
		chmod u+s,g+ws $imgdir
	fi
fi

sedconf $CONF_ETC "HRM_DATA=\"/path/to/hrm/data\"" "HRM_DATA=\"$imgdir\""
sedconf $CONF_SRV '$image_folder = "/path/to/hrm_data";' '$image_folder = "'$imgdir'";'
sedconf $CONF_SRV '$huygens_server_image_folder = "/path/to/hrm_data/";' '$huygens_server_image_folder = "'$imgdir'/";'

echo "Enter HRM administrator's email address"
hrmemail=`readstring`
sedconf $CONF_SRV '$email_sender = "hrm@localhost";' '$email_sender = "'$hrmemail'";'
sedconf $CONF_SRV '$email_admin = "hrm@localhost";' '$email_admin = "'$hrmemail'";'

# assume client and server run on same machine, config file are identical
ln -s $CONF_SRV $hrmdir/config/hrm_client_config.inc
