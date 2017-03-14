#!/bin/bash

source scripts/funs.sh

if [ "$dist" == "Ubuntu" ]
then
	dbpkgs="mysql-server postgresql"
	mysqlpkgs="mysql-server php5-mysql"
	pgsqlpkgs="postgresql php5-pgsql"
	morepkgs="apache2 libapache2-mod-php5 php5 php5-cli php5-common zip"
elif [ "$dist" == "Fedora" ]
then
	#dbpkgs="community-mysql-server postgresql-server"
	dbpkgs="mariadb postgresql-server"
	mysqlpkgs="mariadb mariadb-server php-mysqlnd"
	pgsqlpkgs="postgresql-server postgresql-contrib php-pgsql"
	morepkgs="httpd php php-cli php-common zip unzip wget policycoreutils-python"
else
	abort "Distribution unsupported."
fi

dbmsmissing=`packages_missing $dbpkgs`

if [ -z "$dbmsmissing" ]; # empty, so both DBMS are installed
then
	echo "Two DBMS have been found, choose to use MySQL or PostgreSQL."
	ans=`readkey_choice 'm' 'p'`
else # one or both dbms are missing
	num_dbms=`echo $dbmsmissing | wc -w`

	if [ $num_dbms -eq 2 ]; # both DBMS are missing
	then
		echo "No DBMS has been found, choose to install MySQL or PostgreSQL."
		ans=`readkey_choice 'm' 'p'`
	else # only one DBMS has been found
		# which is missing/not installed, mysql?
		set +o errexit # do not exit uppon error for this test
		echo $dbmsmissing | grep -q "mysql"
		[[ ${PIPESTATUS[1]} -eq 0 ]] && ans='p' || ans='m'
		set -o errexit
	fi
fi

case $ans in
	m)
		dbmspkgs="$mysqlpkgs"
		dbtype="mysql"
		;;
	p)
		dbmspkgs="$pgsqlpkgs"
		dbtype="postgres"
		;;
	*) abort "Wrong database type selected: '$dbtype'."
		;;
esac
echo "Using $dbtype as DBMS."

#echo "Install optional LDAP support? [y/n]"
#[ $(readkey) == "n" ] || dbmspkgs+=" php5-ldap"

[ -n "$(which sendmail)" ] || mtapkg="postfix"

if [[ "$dist" == "Ubuntu" ]] && [[ "$vers" > '"15.10"' ]] ; then
    echo
    echo "Detected Ubuntu newer than '15.10', installing PHP backports."
    echo
    # we need to add the backport repository for PHP5 in this case:
    LC_ALL=C.UTF-8 apt-add-repository --yes --update ppa:ondrej/php
    allpkgs="$(echo $dbmspkgs $mtapkg $morepkgs | sed 's,php5,php5.6,g')"
else
    allpkgs="$dbmspkgs $mtapkg $morepkgs"
fi
install_packages "$allpkgs"
