#!/bin/bash

source funs.sh

echo "Enter PHP post_max_size (limits POST size for browser uploads)"
postmax=`readstring "256M"`
sedconf /etc/php5/apache2/php.ini "post_max_size = .*" "post_max_size = $postmax"

echo "Enter PHP upload_max_filesize (limits file size for browser uploads)"
upmax=`readstring "256M"`
sedconf /etc/php5/apache2/php.ini "upload_max_filesize = .*" "upload_max_filesize = $upmax"
