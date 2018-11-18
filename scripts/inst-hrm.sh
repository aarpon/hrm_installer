#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"
source "$context/funs-input.sh"

############# input system user and system group ############################################

msg="system user which will run HRM"
[ $interactive == true ] && msg="$msg. A new user will be created if unavailable"
sysuser=$(wt_read "$sysuser" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

msg="system group for $sysuser"
[ $interactive == true ] && msg="$msg. A new group will be created if unavailable"
sysgroup=$(wt_read "$sysgroup" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)


############# check if user exists, if it doesnt.. create... ################################

if ! getent group | cut -f1 -d ":" | grep -q "^$sysgroup$"
then
	[ $interactive == false ] && echo "Group does not exist, creating it..."
    catch stdout stderr groupadd --system $sysgroup
fi

catch stdout stderr id $sysuser

if [ $? -eq 0 ]; then
    msg="HRM will run with:\n$stdout"
    wt_print "$msg" --title="$title" --interactive=$interactive
else
	[ $interactive == false ] && echo "User does not exist, creating it..."
	USEROPTS="--system --gid $sysgroup"
    catch stdout stderr useradd $sysuser $USEROPTS
fi


############# use default apache user?? #####################################################

if [ $interactive == true ]; then
    msg="Do you want to use the system's default apache user?"
    if (whiptail --title "$title" --yesno "$msg" 8 70); then
        [[ "$dist" == "Ubuntu" ]] && apache_user="www-data"
        [[ "$dist" == "Debian" ]] && apache_user="www-data"
        [[ "$dist" == "Fedora" ]] && apache_user="apache"
    else
        msg="the apache user name"
        apache_user=$(wt_read "$apache_user" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
    fi
fi

usermod $apache_user --append --groups $sysgroup


######################### choose where hrm directory ########################################
#interactive=true

while : ;
do
    msg="HRM installation directory"
    [ $interactive == true ] && msg="$msg (must be a sub-directory of Apache document root)"
    hrmdir=$(wt_read "$hrmdir" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
    if [ -d "$hrmdir" ]; then
        if [ $interactive == true ]; then
            if [ -d "$hrmdir/.git" ] ; then
                # The hrmdir is a git repository!
                msg="$hrmdir already contains the git repository.\nDo you want to update it now? (git fetch)"
                if (whiptail --title "$title" --yesno "$msg" 8 70); then
                    git -C $hrmdir fetch
                fi
                break
            fi
        else
            # FIXME In non-interactive mode, what do we do if the folder already exists?
            # Do we abort?
            # Right now, we do an automatic update
            echo "The $hrmdir folder will be automaticaly updated"
            git -C $hrmdir fetch
            break
        fi
    fi

    # create hrmdir and set permission
    catch stdout stderr mkdir -vp $hrmdir && rc=$? || rc=$?
    echo "rc=$rc"

    if [ $rc -ne 0 ]; then
        msg="Could not create $hrmdir\n($stderr)"
        wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
    fi

    [ $rc -eq 0 ] && break 

    # This should not fail:
    chown $sysuser:$sysgroup $hrmdir
    chmod u+s,g+ws $hrmdir
done
#interactive=true

######################### get the hrm executable ############################################
#
# In non-interactive mode, the latest HRM is checked out from github

#Here we get the tags from the hrm repo without a local copy. (Thanks Nico!)
tags=$(git ls-remote "$hrmrepo" | grep tags | grep -v '\^' | cut -d/ -f 3 | tail -n 5 | tac)

# For non interactive mode, we need to get the latest tag if hrmtag is "latest"
[ "$hrmtag" == "latest" ] && hrmtag=`echo "${tags}" | head -1`

if [ $interactive == true ]; then
    LIST=()
    selection="on"
    for tag in $tags; do 
        LIST+=( "$tag" "Download HRM revision $tag" $selection )
        selection="off"
    done

    LIST+=( "master" "Download HRM pre-release" $selection )
    LIST+=( "zip" "Extract HRM from a local ZIP file" $selection )

    msg="Choose which version of HRM to install:" 

    ans=$(whiptail --title "$title" --radiolist \
        "$msg" 20 70 $(( ${#LIST[@]}/3 )) \
        "${LIST[@]}" \
        3>&1 1>&2 2>&3 )

    if [ "$ans" == "zip" ]; then
        # Here we install HRM from an existing ZIP file
        while : ;
        do
            msg="the full path to an existing HRM zip package"
            HRMTAR=$(wt_read "" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
            [ -f "$HRMTAR" ] && break
        done

        HRMTMPDIR="$(mktemp -d)"
        unzip $HRMTAR -d $HRMTMPDIR
        mv $HRMTMPDIR/hrm/* $hrmdir
        rm -rf $HRMTMPDIR
    fi
    hrmtag=$ans
fi

if [ "$hrmtag" != "zip" ]; then
    # At this point, the answer is a valid tag.
    echo "The \$hrmtag is now $hrmtag"

    if [ -d "$hrmdir/.git" ] ; then
        echo "$hrmdir already contains the git repository."
    else
        git clone "$hrmrepo" $hrmdir
    fi

    branch=$(git -C $hrmdir branch | grep $hrmtag || true)
    echo $branch

    if [ -z "$branch" ] ; then
        git -C $hrmdir checkout -b $hrmtag
    else
        git -C $hrmdir checkout $hrmtag
    fi

    # Versions 3.4+ have third party packages to be installed (the archive installation has those already included)
    hrmsetup="$hrmdir/setup/"
    if [ -f "$hrmsetup/setup_release.sh" ] ; then
        $hrmsetup./setup_release.sh
    fi
fi

######################## create the HRM log directory ######################################

mkdir -vp /var/log/hrm
chown -R $sysuser:$sysgroup /var/log/hrm
chmod -R u+s,g+ws /var/log/hrm

