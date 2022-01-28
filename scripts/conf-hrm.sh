#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"
source "$context/funs-input.sh"

######################### choose the HRM administrator's email address ######################

msg="administrator's email address"
hrmemail=$(wt_read "$hrmemail" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

######################### choose where images are stored ####################################
#
# For non-interactive mode, we create the folder if not present. Abort if cannot be created
ans=true

while : ;
do
    msg="Image storage directory"
    [ $interactive == true ] && msg="$msg (will be created if needed)"
    imgdir=$(wt_read "$imgdir" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

    # What to do if $imgdir already exists?
    msg2="Warning! You will need to manually check $sysuser permissions for $imgdir"
    if [ -d "$imgdir" ]; then
        if [ $interactive == true ]; then
            msg="Do you want to recursively change permissions on $imgdir?\nWarning! This step is irreversible."
            if (whiptail --title "$title" --yesno --defaultno "$msg" 8 70); then
                chown -R $sysuser:$sysgroup $imgdir
                chmod -R u+s,g+ws $imgdir
            else
                wt_print "$msg2" --title="$title" --interactive=$interactive
            fi
        else
            # Non-interactive mode
            wt_print "$msg2" --title="$title" --interactive=$interactive
        fi
        break
    fi

    # Here we ask whether to create the folder (in non-interactive mode, the answer is yes)
    if [ $interactive == true ]; then
        msg="$imgdir does not exist, create it?"
        if (whiptail --title "$title" --yesno "$msg" 8 70); then
            ans=true
        else
            ans=false
        fi
    fi

    # create imgdir and set permission
    if [ $ans == true ]; then
        mkdir -vp $imgdir
        rc=$?

        if [ $rc -ne 0 ]; then
            msg="Could not create $imgdir"
            wt_print "$msg" --title="$title" --interactive=$interactive
            [ $interactive == false ] && exit 1
        else
            # Here we change permissions on the newly created folder
            # This should not fail:
            chown $sysuser:$sysgroup $imgdir
            chmod u+s,g+ws $imgdir
            break 
        fi
    fi
done

# The server image folder
msg="image storage directory on the server"
srvimgdir=$(wt_read "$srvimgdir" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

# copy config file
CONF_ETC="/etc/hrm.conf"
cp $hrmdir/config/samples/hrm.conf.sample $CONF_ETC

# do substitutions in config file
sedconf $CONF_ETC "^HRM_HOME=.*" "HRM_HOME=\"$hrmdir\""
sedconf $CONF_ETC "^SUSER=.*" "SUSER=\"$sysuser\""

# copy more config files
CONF_SRV="$hrmdir/config/hrm_server_config.inc"
cp $hrmdir/config/samples/hrm_server_config.inc.sample $CONF_SRV

# do substitutions in config file

if [ "$dbtype" == "postgres" ]; then
    sedconf $CONF_SRV '^$db_type =.*' '$db_type = "postgres";'
elif [ "$dbtype" != "mysql" ]; then
    sedconf $CONF_SRV '^$db_type =.*' '$db_type = "'$dbtype'";'
fi

sedconf $CONF_SRV '^$huygens_user =.*' '$huygens_user = "'$sysuser'";'
sedconf $CONF_SRV '^$huygens_group =.*' '$huygens_group = "'$sysgroup'";'
sedconf $CONF_SRV '^$image_folder =.*' '$image_folder = "'$imgdir'";'
sedconf $CONF_SRV '^$huygens_server_image_folder =.*' '$huygens_server_image_folder = "'$srvimgdir'";'

sedconf $CONF_SRV '^$db_user =.*' '$db_user = "'$dbuser'";'
sedconf $CONF_SRV '^$db_password =.*' '$db_password = "'$dbpass'";'
sedconf $CONF_SRV '^$db_name =.*' '$db_name = "'$dbname'";'
sedconf $CONF_SRV '^$hrm_path =.*' '$hrm_path = "'$hrmdir'";'
sedconf $CONF_SRV '^$local_huygens_core =.*' '$local_huygens_core = "'$hucorepath'";'

sedconf $CONF_ETC "^HRM_DATA=.*" "HRM_DATA=\"$imgdir\""
sedconf $CONF_SRV '^$image_folder =.*' '$image_folder = "'$imgdir'";'
sedconf $CONF_SRV '^$huygens_server_image_folder =.*' '$huygens_server_image_folder = "'$imgdir'/";'

sedconf $CONF_SRV '^$email_sender =.*' '$email_sender = "'$hrmemail'";'
sedconf $CONF_SRV '^$email_admin =.*' '$email_admin = "'$hrmemail'";'

# assume client and server run on same machine, config file are identical
link="$hrmdir/config/hrm_client_config.inc"
if [ ! -f "$link" ];
then
    ln -s $CONF_SRV "$link"
fi
