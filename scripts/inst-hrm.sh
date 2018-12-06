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

getent group | cut -f1 -d ":" | grep -q "^$sysgroup$" && rc=$? || rc=$?
if  [ $rc -eq 1 ]; then
	[ $interactive == false ] && echo "Group does not exist, creating it..."
    groupadd --system $sysgroup
fi

if ! id -u $sysuser > /dev/null 2>&1; then
	[ $interactive == false ] && echo "User does not exist, creating it..."
	USEROPTS="--system --gid $sysgroup"
    useradd $sysuser $USEROPTS
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

while : ;
do
    msg="HRM installation directory"
    [ $interactive == true ] && msg="$msg (must be a sub-directory of Apache document root)"
    hrmdir=$(wt_read "$hrmdir" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
    if [ -d "$hrmdir" ]; then

        #This (badly) checks the git version to support Centos7
        gitversion=$(git --version | cut -d' ' -f3)
        if [[ $gitversion < "1.8.5" ]]; then
            intohrm="--git-dir=$hrmdir/.git --work-tree=$hrmdir"
        else
            intohrm="-C $hrmdir"
        fi

        if [ $interactive == true ]; then
            if [ -d "$hrmdir/.git" ] ; then
                # The hrmdir is a git repository!
                msg="$hrmdir already contains the git repository.\nDo you want to update it now? (git fetch)"
                if (whiptail --title "$title" --yesno "$msg" 8 70); then
                    git $intohrm fetch
                fi
                break
            fi
        else
            # FIXME In non-interactive mode, what do we do if the folder already exists?
            # Do we abort?
            # Right now, we do an automatic update
            echo "The $hrmdir folder will be automaticaly updated"
            if [ -d "$hrmdir/.git" ] ; then
                git $intohrm fetch
            fi
            break
        fi
    fi

    # create hrmdir and set permission
    mkdir -vp $hrmdir && rc=$? || rc=$?

    if [ $rc -ne 0 ]; then
        msg="Could not create $hrmdir\n($stderr)"
        wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
    fi

    [ $rc -eq 0 ] && break 

    # This should not fail:
    chown $sysuser:$sysgroup $hrmdir
    chmod u+s,g+ws $hrmdir
done

######################### get the hrm executable ############################################
#
# In non-interactive mode, the latest HRM is checked out from github

# Here we get the tags from the hrm repo without a local copy. (Thanks Niko!)
#tags=$(git ls-remote "$hrmrepo" | grep tags | grep -v '\^' | LC_ALL=C sed -e 's/.*\ //' | tail -n 5 | tac)
tags=$(git ls-remote --refs --tags "$hrmrepo" | awk -F 'tags/' '{print $2}' | tail -n 3 | tac)

# For non interactive mode, we need to get the latest tag if hrmtag is "latest"
[ "$hrmtag" == "latest" ] && hrmtag=`echo "${tags}" | head -1`

if [ $interactive == true ]; then
    #Extra matches for master, pre-release and devel
    match="master\|release"
    [ $devel == true ] && match+="\|devel"
    tags+=" $(git ls-remote --refs "$hrmrepo" | grep $match | awk -F 'heads/' '{print $2}')"

    LIST=()
    for tag in $tags; do 
        # This selects the currently defined $hrmtag (if in $tags)
        [[ $tag == $hrmtag ]] && selection="on" || selection="off"

        # Generate an appropriate message for the current tag
        if [[ $tag == *"release"* ]]; then
            msg="Pre-release, use with caution!"
        elif [[ $tag == "devel" ]]; then
            msg="For HRM development only" 
        elif [[ $tag == "master" ]]; then
            msg="Rolling fixes for the latest release" 
        else
            msg="HRM release v$tag" 
        fi

        LIST+=( "$tag" "$msg" $selection )
    done

    [ -n "$zippath" ] && selection="on" || selection="off"

    LIST+=( "zip" "Extract HRM from a local ZIP file" $selection )

    msg="The HRM repo is: $hrmrepo\n\nChoose which version of HRM to install:" 

    ans=$(whiptail --title "$title" --radiolist \
        "$msg" 20 70 $(( ${#LIST[@]}/3 )) \
        "${LIST[@]}" \
        3>&1 1>&2 2>&3 )

    if [ "$ans" == "zip" ]; then
        # Here we install HRM from an existing ZIP file
        while : ;
        do
            msg="the full path to an existing HRM zip package"
            zippath=$(wt_read $zippath --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)
            [ -f "$zippath" ] && break
        done

        HRMTMPDIR="$(mktemp -d)"
        unzip $zippath -d $HRMTMPDIR
        mv $HRMTMPDIR/hrm/* $hrmdir
        rm -rf $HRMTMPDIR
    fi
    hrmtag=$ans
fi

if [ "$hrmtag" != "zip" ]; then
    # At this point, the answer is a valid tag.

    if [ -d "$hrmdir/.git" ] ; then
        echo "$hrmdir already contains the git repository."
        #FIXME There's probably a more robust way to do this:
        # We need to make sure we can actually checkout the branch or tag $hrmtag.
        # If we already have a repository in $hrmdir, git checkout -d simply creates a new branch
        # On the other hand, git clone below will fail if $hrmtag can't be checked out.
        lc=$(git ls-remote --refs "$hrmrepo" | awk '{print $2}' | grep -F "$hrmtag" | wc -l)
        if [ $lc -eq 0 ]; then
            msg="$hrmtag cannot be checked out from $hrmrepo"
            wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
        else
            branch=$(git $intohrm branch | grep -F "$hrmtag" || true)
            if [ -z "$branch" ] ; then
                ( cd $hrmdir ; git $intohrm checkout -b $hrmtag )
            else
                ( cd $hrmdir ; git $intohrm checkout $hrmtag )
            fi
        fi
    else
        #FIXME according to: https://stackoverflow.com/questions/35979642/what-is-git-tag-how-to-create-tags-how-to-checkout-git-remote-tags
        #Might be worth adding  --single-branch --depth 1 if all we're trying to do here is clone for deployment (unless devel?).
        git clone -b "$hrmtag" "$hrmrepo" $hrmdir
    fi

    # Versions 3.4+ have third party packages to be installed (the archive installation has those already included)
    hrmsetup="$hrmdir/setup/"
    $devel && release="devel" || release="release"
    if [ -f "$hrmsetup/setup_$release.sh" ] ; then
        $hrmsetup./setup_$release.sh
    fi
fi

######################## create the HRM log directory ######################################

mkdir -vp /var/log/hrm
chown -R $sysuser:$sysgroup /var/log/hrm
chmod -R u+s,g+ws /var/log/hrm

