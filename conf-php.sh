#!/bin/bash

source funs.sh

echo "Enter PHP post_max_size (limits POST size for browser uploads)"
postmax=`readstring "256M"`

echo "Enter PHP upload_max_filesize (limits file size for browser uploads)"
upmax=`readstring "256M"`

if [ "$dist" == "Ubuntu" ]
then
	phpinipath="/etc/php5/apache2/php.ini"
elif [ "$dist" == "Fedora" ]
then
	phpinipath="/etc/php.ini"
else
	abort "Distribution unsupported."
fi

sedconf $phpinipath "post_max_size = .*" "post_max_size = $postmax"
sedconf $phpinipath "upload_max_filesize = .*" "upload_max_filesize = $upmax"
