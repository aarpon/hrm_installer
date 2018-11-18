#!/bin/bash

source "$(dirname $BASH_SOURCE)/funs.sh"

echo "Enter PHP post_max_size (limits POST size for browser uploads)"
postmax=`readstring "256M"`

echo "Enter PHP upload_max_filesize (limits file size for browser uploads)"
upmax=`readstring "256M"`

if [ "$dist" == "Debian" ]
then
    # This will(?) return the correct path for Debian 9
    # and a valid path for previous versions
    # TODO do we need a test in the path does not exist?
    phppath=`find /etc/{php,php?} -maxdepth 0 -type d | tail -n 1`
    phpinipath="$phppath/apache2/php.ini"
elif [ "$dist" == "Ubuntu" ]
then
	phpinipath="/etc/php5/apache2/php.ini"
	if [[ "$vers" > '"15.10"' ]]
	then
		phpinipath="/etc/php/5.6/apache2/php.ini"
	fi
elif [ "$dist" == "Fedora" ]
then
	phpinipath="/etc/php.ini"
	tz=`ls -l /etc/localtime | sed "s:zoneinfo/:\n:g" | tail -1`
	sedconf $phpinipath "\;date\.timezone =" "date.timezone = $tz"
else
	abort "Distribution unsupported."
fi

sedconf $phpinipath "post_max_size = .*" "post_max_size = $postmax"
sedconf $phpinipath "upload_max_filesize = .*" "upload_max_filesize = $upmax"

# restart Apache as otherwise it doesn't recognize the PHP-MySQL stuff (this
# might be required for other distributions / versions as well!!)
if [[ "$dist" == "Ubuntu" ]] && [[ "$vers" > '"15.10"' ]] ; then
	service apache2 restart
fi
