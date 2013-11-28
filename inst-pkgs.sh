#!/bin/bash

source funs.sh

dbmsmissing=`packages_missing mysql-server postgresql`

if [ -z "$dbmsmissing" ]; # empty, so both dbms are installed
then
	echo "Two DBMS have been found, choose to use MySQL or PostgreSQL. [m/p]"
	ans=`readkey`
else # one or two dbms found
	num_dbms=`echo $dbmsmissing | wc -w`

	if [ $num_dbms == 2 ]; # both dbms are missing
	then
		echo "No DBMS has been found, choose to install MySQL or PostgreSQL. [m/p]"
		ans=`readkey`
	else
		ans=`echo "mysql-server postgresql " | sed s/$dbmsmissing.//g | cut -c 1`
	fi
fi

dbtype=$ans;

case $dbtype in
	m) dbmspkgs="mysql-server php5-mysql"
		;;
	p) dbmspkgs="postgresql php5-pgsql"
		;;
esac

#echo "Install optional LDAP support? [y/n]"
#[ $(readkey) == "y" ] && dbmspkgs+=" php5-ldap"

mtainstalled=`which sendmail`
[ -z  "$mtainstalled" ] && mtapkg="postfix"

echo "Trying to install missing packages."
pkgs="$dbmspkgs $mtapkg apache2 libapache2-mod-php5 php5 php5-cli php5-common zip"
aptitude install $pkgs
#errcheck "Could not install all missing packages." # aptitude has unreliable return code behavior

