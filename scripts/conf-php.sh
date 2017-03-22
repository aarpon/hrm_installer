#!/bin/bash

source "$(dirname $BASH_SOURCE)/funs.sh"

echo "Enter PHP post_max_size (limits POST size for browser uploads)"
postmax=`readstring "256M"`

echo "Enter PHP upload_max_filesize (limits file size for browser uploads)"
upmax=`readstring "256M"`

if [ "$dist" == "Debian" ]
then
    phpinipath="/etc/php5/apache2/php.ini"
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
