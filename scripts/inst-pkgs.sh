#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"

# Check which OS we are running
if [ "$dist" == "Ubuntu" ]; then
    #dbpkgs="mariadb-server mysql-server postgresql"
    dbpkgs="mysql-server postgresql"
    mysqlpkgs="mysql-server php-mysql"
    pgsqlpkgs="postgresql php-pgsql"
    morepkgs="apache2 libapache2-mod-php php php-cli php-common zip git php-xml"
    if [ $devel == true ]; then
        morepkgs+=" php-simplexml php-xmlreader"
    fi
elif [ "$dist" == "Fedora" ];
then
    #dbpkgs="community-mysql-server postgresql-server"
    dbpkgs="mariadb postgresql-server"
    mysqlpkgs="mariadb mariadb-server php-mysqlnd"
    pgsqlpkgs="postgresql-server postgresql-contrib php-pgsql"
    morepkgs="httpd php php-cli php-common zip unzip wget git php-xml policycoreutils-python*"
    # composer install from source seems to need php-json
    # but is already installed with the remi package (Centos 7)
    if [ "$vers" != '"7"' ]; then
        morepkgs+=" php-json"
    fi
elif [ "$dist" == "Debian" ];
then
    dbpkgs="mysql-server postgresql"
    mysqlpkgs="mysql-server php-mysql"
    pgsqlpkgs="postgresql php-pgsql"
    morepkgs="apache2 libapache2-mod-php php php-cli php-common zip git sysvinit-utils php-xml"
    if [ $devel == true ]; then
        morepkgs+=" php-simplexml php-xmlreader php-xmlwriter"
    fi

    if [ "$vers" \< '"9"' ]; then
        #For version < 9 install the php5 packages instead of php
        mysqlpkgs=${mysqlpkgs//php/php5}
        pgsqlpkgs=${pgsqlpkgs//php/php5}
        morepkgs=${morepkgs//php/php5}
    fi
else
    abort "Distribution unsupported."
fi

dbmsmissing=`packages_missing $dbpkgs`

if [ $interactive == true ] && [ -z dbtype ]; then
    IFS=' ' read -r -a array <<< "$dbpkgs"
    LIST=()
    for index in ${!array[*]}; do 
        selection="off"
        if [ $index -eq 0 ]; then
            selection="on"
        fi
        LIST+=( "${array[$index]}" "${dbms[${array[$index]}]} database server" $selection )
    done

    num_dbms=$(echo $dbmsmissing | wc -w) && rc=$? || rc=$?
    if [ $num_dbms -eq 0 ]; # empty, so both DBMS are installed
    then
        msg="Two database management systems were found on this system.\n\nChoose which DBMS HRM will use" 
    elif [ $num_dbms -eq 2 ]; # both DBMS are missing
    then
      msg="No database management system installed on this system\n\nPlease choose one of the following:"
    else # only one DBMS has been found
      # which is missing/not installed, mysql?
      [ "$dbmissing" == "mysql-server" ] && dbtype="postgres" || dbtype="mysql"
    fi

    # we must choose between multiple possibilities
    if [ $num_dbms -ne 1 ] # both DBMS are missing or both are available
    then
        ans=$(whiptail --title "$title" --radiolist \
            "$msg" 20 70 ${#array[@]} \
            "${LIST[@]}" \
                      3>&1 1>&2 2>&3 )
        if [ "$ans" == "${array[0]}" ];
        then
            dbtype="mysql"
        else
            dbtype="postgres"
        fi
    fi
fi

# By default, install mysql (case where non-interactive mode, but no dbtype was specified)
[ -z "$dbtype" ] && dbtype="mysql"

# Once dbtype is defined (interactively or pre-defined), we can select the appropriate dbmspkgs
[ "$dbtype" == "mysql" ] && dbmspkgs="$mysqlpkgs" || dbmspkgs="$pgsqlpkgs"

#Always echo the following (this is good info)
echo "Using ${dbms[$dbtype]} as the DBMS."

#echo "Install optional LDAP support? [y/n]"
#[ $(readkey) == "n" ] || dbmspkgs+=" php-ldap"

[ -n "$(type -pf sendmail 2>/dev/null)" ] || mtapkg="postfix"

if [[ "$dist" == "Ubuntu" ]] && [[ "$vers" > '"15.10"' ]] ; then
    echo
    echo "Detected Ubuntu newer than '15.10', installing PHP backports."
    echo
    # we need to add the backport repository for PHP5 in this case:
    #LC_ALL=C.UTF-8 apt-add-repository --yes --update ppa:ondrej/php
    #allpkgs="$(echo $dbmspkgs $mtapkg $morepkgs | sed 's,php5,php5.6,g')"
    allpkgs="$dbmspkgs $mtapkg $morepkgs"
else
    allpkgs="$dbmspkgs $mtapkg $morepkgs"
fi

install_packages "$allpkgs"
