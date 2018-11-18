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
    msg="image storage directory"
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
        ans=(whiptail --title "$title" --yesno "$msg" 8 70)
    fi

    # create imgdir and set permission
    if [ $ans == true ]; then
        catch stdout stderr mkdir -vp $imgdir
        rc=$?
        msg="Could not create $imgdir"

        if [ $interactive == true ]; then
            wt_print "$msg" --title="$title" --interactive=$interactive
        else
            if [ $rc -ne 0 ]; then
                echo msg
                exit 1
            fi
        fi

        # Here we change permissions on the newly created folder
        if [ rc -eq 0 ]; then
            # This should not fail:
            chown $sysuser:$sysgroup $imgdir
            chmod u+s,g+ws $imgdir
            break 
        fi
    fi
done

# copy config file
CONF_ETC="/etc/hrm.conf"
cp $hrmdir/config/samples/hrm.conf.sample $CONF_ETC

# do substitutions in config file
sedconf $CONF_ETC "HRM_HOME=\"/var/www/html/hrm\"" "HRM_HOME=\"$hrmdir\""
sedconf $CONF_ETC "SUSER=\"hrm\"" "SUSER=\"$sysuser\""

# copy more config files
CONF_SRV="$hrmdir/config/hrm_server_config.inc"
cp $hrmdir/config/samples/hrm_server_config.inc.sample $CONF_SRV

# do substitutions in config file
sedconf $CONF_SRV '$db_type = "mysql";' '$db_type = "'$dbtype'";'
sedconf $CONF_SRV '$db_user = "dbuser";' '$db_user = "'$dbuser'";'
sedconf $CONF_SRV '$db_password = "dbpasswd";' '$db_password = "'$dbpass'";'
sedconf $CONF_SRV '$db_name = "hrm";' '$db_name = "'$dbname'";'
sedconf $CONF_SRV '$hrm_path = "/var/www/html/hrm";' '$hrm_path = "'$hrmdir'";'
sedconf $CONF_SRV '$local_huygens_core = "/usr/local/bin/hucore";' '$local_huygens_core = "'$hucorepath'";'

sedconf $CONF_ETC "HRM_DATA=\"/scratch/hrm_data\"" "HRM_DATA=\"$imgdir\""
sedconf $CONF_SRV '$image_folder = "/scratch/hrm_data";' '$image_folder = "'$imgdir'";'
sedconf $CONF_SRV '$huygens_server_image_folder = "/scratch/hrm_data/";' '$huygens_server_image_folder = "'$imgdir'/";'

sedconf $CONF_SRV '$email_sender = "hrm@localhost";' '$email_sender = "'$hrmemail'";'
sedconf $CONF_SRV '$email_admin = "hrm@localhost";' '$email_admin = "'$hrmemail'";'

# assume client and server run on same machine, config file are identical
link="$hrmdir/config/hrm_client_config.inc"
if [ ! -f "$link" ];
then
    ln -s $CONF_SRV "$link"
fi
