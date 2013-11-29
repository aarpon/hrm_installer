#!/bin/bash

source funs.sh

dbmsmissing=`packages_missing mysql-server postgresql`

if [ -z "$dbmsmissing" ]; # empty, so both dbms are installed
then
	echo "Two DBMS have been found, choose to use MySQL or PostgreSQL."
	ans=`readkey_choice 'm' 'p'`
else # one or both dbms are missing
	num_dbms=`echo $dbmsmissing | wc -w`

	if [ $num_dbms == 2 ]; # both dbms are missing
	then
		echo "No DBMS has been found, choose to install MySQL or PostgreSQL."
		ans=`readkey_choice 'm' 'p'`
	else
		ans=`echo "mysql-server postgresql " | sed s/$dbmsmissing.//g | cut -c 1`
	fi
fi

dbtype=$ans;

case $dbtype in
	m)
		dbmspkgs="mysql-server php5-mysql"
		dbtype="mysql"
		;;
	p)
		dbmspkgs="postgresql php5-pgsql"
		dbtype="postgres"
		;;
	*) errcheck "Wrong database type selected: '$dbtype'."
		;;
esac

#echo "Install optional LDAP support? [y/n]"
#[ $(readkey) == "y" ] && dbmspkgs+=" php5-ldap"

mtainstalled=`which sendmail`
[ -z  "$mtainstalled" ] && mtapkg="postfix"

pkgs="$dbmspkgs $mtapkg apache2 libapache2-mod-php5 php5 php5-cli php5-common zip"
MISSING=$(packages_missing $pkgs)
if [ -n "$MISSING" ] ; then
    echo -e "\nThe following packages will be installed:\n$MISSING\n"
    waitconfirm
    aptitude install $MISSING
    MISSING=$(packages_missing $pkgs)
    [ -n "$MISSING" ] && errcheck "Could not install packages: $MISSING"
fi
