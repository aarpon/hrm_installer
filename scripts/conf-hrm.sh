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

# The server hostname and image folder
#
# First we ask if the deconvolution will be performed remotely (default is no).
# If yes, need to ask the remote server hostname (srvhostname) and server image directory (srcimgdir)
if [ $interactive == true ]; then
    #the default answer can be modified using remotedeconv
    msg="Will you be performing deconvolution on a remote machine?"
    if (whiptail --title "$title" --yesno $( [ $remotedeconv == true ] && printf %s '--defaultno' ) "$msg" 8 70); then
        remotedeconv=true
    else
        remotedeconv=false
    fi
    if [ $remotedeconv == true ]; then
        msg="Enter the remote server hostname or ip address\non which deconvolution is performed"
        srvhostname=$(wt_read "$srvhostname" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
        msg="Image storage directory on the remote server"
        srvimgdir=$(wt_read "$srvimgdir" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
    fi
fi


# Some very simple logic to try and deal with the presence of new style HRM sample config files
# If not present, revert back to server / client config file logic

old_config=false
CONF_HRM="$hrmdir/config/hrm_config.inc"
CONF_HRM_SAMPLE="$hrmdir/config/samples/hrm_config.inc.sample"
if [ ! -f "$CONF_HRM_SAMPLE" ]; then
    echo "Warning! Using the old HRM config file hrm_server_config.inc"
    CONF_HRM="$hrmdir/config/hrm_server_config.inc"
    CONF_HRM_CLIENT="$hrmdir/config/hrm_client_config.inc"
    CONF_HRM_SAMPLE="$hrmdir/config/samples/hrm_server_config.inc.sample"
    old_config=true
fi

# we need to make a backup in case some parameters were changed manually
cp --backup=numbered $CONF_HRM_SAMPLE $CONF_HRM

# do substitutions in config file
sedconf $CONF_HRM '^$huygens_user =.*' '$huygens_user = "'$sysuser'";'
sedconf $CONF_HRM '^$huygens_user =.*' '$huygens_user = "'$sysuser'";'
sedconf $CONF_HRM '^$huygens_group =.*' '$huygens_group = "'$sysgroup'";'
sedconf $CONF_HRM '^$email_sender =.*' '$email_sender = "'$hrmemail'";'
sedconf $CONF_HRM '^$email_admin =.*' '$email_admin = "'$hrmemail'";'
sedconf $CONF_HRM '^$image_folder =.*' '$image_folder = "'$imgdir'";'

sedconf $CONF_HRM '^$db_user =.*' '$db_user = "'$dbuser'";'
sedconf $CONF_HRM '^$db_password =.*' '$db_password = "'$dbpass'";'
sedconf $CONF_HRM '^$db_name =.*' '$db_name = "'$dbname'";'
sedconf $CONF_HRM '^$hrm_path =.*' '$hrm_path = "'$hrmdir'";'
sedconf $CONF_HRM '^$local_huygens_core =.*' '$local_huygens_core = "'$hucorepath'";'

if [ "$dbtype" == "mysql" ]; then
    sedconf $CONF_SRV '^$db_type =.*' '$db_type = "mysqli";'
else
    sedconf $CONF_SRV '^$db_type =.*' '$db_type = "'$dbtype'";'
fi

if [ $remotedeconv == false ]; then
    sedconf $CONF_HRM '^$huygens_server_image_folder =.*' '$huygens_server_image_folder = "'$imgdir'";'

    if [[ "$CONF_HRM" == *hrm_server_config.inc ]]; then
        # We're dealing with old format config files.
	# Assume client and server are running on the same machine, config files are identical
        ln -s --backup=numbered $CONF_HRM "$CONF_HRM_CLIENT"
    fi
else
    sedconf $CONF_HRM '^$image_host =.*' '$image_host = "'$srvhostname'";'
    sedconf $CONF_HRM '^$huygens_server_image_folder =.*' '$huygens_server_image_folder = "'$srvimgdir'";'
    sedconf $CONF_HRM '^$imageProcessingIsOnQueueManager =.*' '$imageProcessingIsOnQueueManager = false;'

    if [[ "$CONF_HRM" == *hrm_server_config.inc ]]; then
        # We're dealing with old format config files.
        # Duplicate the file in case specific changes needed to be made
        cp --force --backup=numbered $CONF_HRM $CONF_HRM_CLIENT
        sedconf $CONF_HRM_CLIENT '// This configuration file is used by the QUEUE MANAGER.' '// This configuration file is used by the WEB INTERFACE.'
    fi

    #Following https://huygens-remote-manager.readthedocs.io/en/devel/admin/set_server.html
    sql="USE $dbname; UPDATE server SET name = '$srvhostname', huscript_path = '/usr/bin/hucore';"
    echo $sql
    REPLY=$(docommand "$sql") && rc=$? || rc=$?
    echo $REPLY
fi

# copy config file if needed
CONF_ETC="/etc/hrm.conf"
CONF_ETC_SAMPLE="$hrmdir/config/samples/etc/hrm.conf.sample"
if [ ! -f "$CONF_ETC" ]; then
    if [ $old_config == true ]; then
        CONF_ETC_SAMPLE="$hrmdir/config/samples/hrm.conf.sample"
    fi
    cp --backup=numbered $CONF_ETC_SAMPLE $CONF_ETC
fi

# do substitutions in config file
sedconf $CONF_ETC "^HRM_HOME=.*" "HRM_HOME=\"$hrmdir\""
sedconf $CONF_ETC "^SUSER=.*" "SUSER=\"$sysuser\""
sedconf $CONF_ETC "^HRM_DATA=.*" "HRM_DATA=\"$imgdir\""

