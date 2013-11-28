#!/bin/bash

source funs.sh

echo "Enter the name for a system user for the HRM:"
hrm_user=`readstring "hrm-user"`
echo "Enter the name for a system group for the HRM:"
hrm_group=`readstring "hrm"`
echo "Creating HRM system user and group."
USEROPTS="--system --gid $hrm_group"
groupadd --system $hrm_group
useradd $hrm_user $USEROPTS
usermod www-data --append --groups $hrm_group

echo "Enter HRM installation directory (must be a sub-directory of Apache document root):"
hrmdir=`readstring "/var/www/hrm"`

# create hrmdir and set permission
mkdir -vp $hrmdir
chown $hrm_user:$hrm_group $hrmdir
chmod u+s,g+ws $hrmdir

echo "Downloading and extracting HRM."
HRMPKG="$(mktemp)"
wget -nv -O $HRMPKG http://sourceforge.net/projects/hrm/files/latest/download
tar xjf $HRMPKG -C $hrmdir --strip-components=1
#errcheck "Could not download and extract HRM."
rm $HRMPKG
echo "Done."

mkdir -vp /var/log/hrm
chown $hrm_user:$hrm_group /var/log/hrm
chmod u+s,g+ws /var/log/hrm

