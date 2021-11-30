#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"
source "$context/funs-input.sh"

############################### PHP post_max_size (limits POST size for browser uploads) ####

msg="PHP post_max_size (limits POST size for browser uploads)"
postmax=$(wt_read "$postmax" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

######################### PHP upload_max_filesize (limits file size for browser uploads) ####

msg="PHP upload_max_filesize (limits file size for browser uploads)"
upmax=$(wt_read "$upmax" --interactive=$interactive --title="$title" --message="$msg" --allowempty=false)

if [ "$dist" == "Debian" ] || [ "$dist" == "Ubuntu" ]
then
    # This will(?) return the correct path for Debian 9 or any recent Ubuntu
    # and a valid path for previous versions
    if [ "$dist" == "Debian" ] && [ $(ver $vers) -lt $(ver "9") ]; then
        phppath=`find /etc/php? -maxdepth 0 -type d | tail -n 1`
    else
        phppath=`find /etc/php -maxdepth 1 -type d | tail -n 1`
    fi
    if [ ! -d $phppath ]; then
        msg="$phppath does not exist. Contact your system administrator."
        wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
    fi
    phpinipath="$phppath/apache2/php.ini"
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
if [ "$dist" == "Ubuntu" ] && [ $(ver $vers) -gt $(ver "15.10") ]; then
	service apache2 restart
fi
