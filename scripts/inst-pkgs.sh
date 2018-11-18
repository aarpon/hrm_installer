#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"

# Check which OS we are running
if [ "$dist" == "Ubuntu" ]; then
    #dbpkgs="mariadb-server mysql-server postgresql"
    dbpkgs="mysql-server postgresql"
    mysqlpkgs="mysql-server php5-mysql"
    pgsqlpkgs="postgresql php5-pgsql"
    morepkgs="apache2 libapache2-mod-php5 php5 php5-cli php5-common zip git"
elif [ "$dist" == "Fedora" ];
then
    #dbpkgs="community-mysql-server postgresql-server"
    dbpkgs="mariadb postgresql-server"
    mysqlpkgs="mariadb mariadb-server php-mysqlnd"
    pgsqlpkgs="postgresql-server postgresql-contrib php-pgsql"
    morepkgs="httpd php php-cli php-common zip unzip wget policycoreutils-python git"
elif [ "$dist" == "Debian" ];
then
    dbpkgs="mysql-server postgresql"
    mysqlpkgs="mysql-server php-mysql"
    pgsqlpkgs="postgresql php-pgsql"
    morepkgs="apache2 libapache2-mod-php php php-cli php-common zip git sysvinit-utils"

    if [ "$vers" \< '"9"' ]; then
        #For version < 9 install the php5 packages instead of php
        mysqlpkgs=${mysqlpkgs//php/php5}
        pgsqlpkgs=${pgsqlpkgs//php/php5}
        morepkgs=${morepkgs//php/php5}
    fi
else
    abort "Distribution unsupported."
fi

declare -A dbms=( ["mysql-server"]="MySQL" ["mariadb"]="MariaDB" ["postgresql"]="PostgreSQL")

dbmsmissing=`packages_missing $dbpkgs`

if [ $interactive == true ]; then
    IFS=' ' read -r -a array <<< "$dbpkgs"
    LIST=()
    for index in ${!array[*]}; do 
        selection="off"
        if [ $index -eq 0 ]; then
            selection="on"
        fi
        LIST+=( "${array[$index]}" "${dbms[${array[$index]}]} database server" $selection )
    done

    if [ -z "$dbmsmissing" ]; # empty, so both DBMS are installed
    then
        msg="Two database management systems were found on this system.\n\nChoose which DBMS HRM will use" 
        ans=""
    else # one or both dbms are missing
        num_dbms=`echo $dbmsmissing | wc -w`

        if [ $num_dbms -eq 2 ]; # both DBMS are missing
        then
            msg="No database management system installed on this system\n\nPlease choose one of the following:"
            ans=""
        else # only one DBMS has been found
            # which is missing/not installed, mysql?
            set +o errexit # do not exit uppon error for this test
            echo $dbmsmissing | grep -q "mysql"
            [[ ${PIPESTATUS[1]} -eq 0 ]] && ans=array[1] || ans=array[0]
            set -o errexit
        fi
    fi

    # we do not have an answer yet, so need to ask...
    if [ -z "$ans" ];
    then
        ans=$(whiptail --title "$title" --radiolist \
            "$msg" 20 70 ${#array[@]} \
            "${LIST[@]}" \
                      3>&1 1>&2 2>&3 )
    fi

    if [ $ans = ${array[0]} ];
    then
        dbtype="mysql"
    else
        dbtype="postgres"
    fi
fi

# Once dbtype is defined (interactively or pre-defined), we can select the appropriate dbmspkgs
[ "$dbtype" == "mysql" ] && dbmspkgs="$mysqlpkgs" || dbmspkgs="$pgsqlpkgs"

#Only echo this if non-interactive mode
[ $interactive == false ] && echo "Using $dbtype as DBMS."

#echo "Install optional LDAP support? [y/n]"
#[ $(readkey) == "n" ] || dbmspkgs+=" php-ldap"

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
