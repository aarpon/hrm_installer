#!/bin/bash

source "$(dirname $BASH_SOURCE)/funs.sh"

echo "Enter the name for a system user for the HRM:"
hrm_user=`readstring "hrmuser"`
echo "Enter the name for a system group for the HRM:"
hrm_group=`readstring "hrm"`

############# check if user exists, if it doesnt.. create... ################################

if ! getent group | cut -f1 -d ":" | grep -q "^$hrm_group$"
then
	echo "Group does not exist, creating it..."
	groupadd --system $hrm_group
fi

if ! id $hrm_user
then
	echo "User does not exist, creating it..."
	USEROPTS="--system --gid $hrm_group"
	useradd $hrm_user $USEROPTS
fi

############# use default apache user?? #####################################################

echo "Use default systems's apache user?"
if [ $(readkey_choice "y" "n") == "y" ] ; then
	[[ "$dist" == "Ubuntu" ]] && apache_user="www-data"
	[[ "$dist" == "Fedora" ]] && apache_user="apache"
else
    echo -e "\nEnter apache user name"
    apache_user=`readstring`
fi

usermod $apache_user --append --groups $hrm_group

######################### get the hrm executable ############################################

echo -e "\nEnter HRM installation directory (must be a sub-directory of Apache document root):"
hrmdir=`readstring "/var/www/html/hrm"`

# create hrmdir and set permission
mkdir -vp $hrmdir
chown $hrm_user:$hrm_group $hrmdir
chmod u+s,g+ws $hrmdir

echo "Download [d] the HRM package or use an existing one [e]:"
if [ $(readkey_choice "d" "e") == "d" ] ; then
    if [ -d "$hrmdir/.git" ] ; then
        echo "$hrmdir already contains the git repository."
    else
#        echo ""
        git clone "https://github.com/aarpon/hrm.git" $hrmdir
    fi

    echo "Use the latest HRM version [l] or choose an older one [o]:"
    tag="$(git -C $hrmdir tag -l | tail -n 1)"
    if [ $(readkey_choice "l" "o") == "o" ] ; then
        git -C $hrmdir tag -l
        echo "Choose and input one of the version numbers above:"
        tag=$(readstring "$tag")
    fi

    branch=$(git -C $hrmdir branch | grep $tag || true)
    echo $branch
    if [ -z "$branch" ] ; then
        git -C $hrmdir checkout -b $tag
    else
        git -C $hrmdir checkout $tag
    fi
else
    echo -e "\nEnter the full path to an existing HRM zip package"
    HRMTAR=`readstring`
    echo "Extracting the HRM package."
    HRMTMPDIR="$(mktemp -d)"
    unzip $HRMTAR -d $HRMTMPDIR
    mv $HRMTMPDIR/hrm/* $hrmdir
    rm -rf $HRMTMPDIR
fi

#errcheck "Could not download and extract HRM."
## HRMPKGTMP is only set if we downloaded it, so we can use it to clean up:
#rm -f $HRMPKGTMP
echo "Done."

######################## create the HRM log directory ######################################

mkdir -vp /var/log/hrm
chown $hrm_user:$hrm_group /var/log/hrm
chmod u+s,g+ws /var/log/hrm
