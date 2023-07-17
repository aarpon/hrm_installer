#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"

# Check which OS we are running
if [[ $isdebianbased == true ]]; then
    #dbpkgs="mariadb-server mysql-server postgresql"
    if [ "$dist" == "Ubuntu" ]; then
        dbpkgs="mysql-server postgresql"
        mysqlpkgs="mysql-server php-mysql"
        morepkgs="apache2 libapache2-mod-php php php-cli php-common zip git php-xml php-ldap"
    else
        # FIXME do we really need sysvinit-utils tools in debian?
        dbpkgs="mariadb-server postgresql"
        mysqlpkgs="mariadb-server php-mysql"
        morepkgs="apache2 libapache2-mod-php php php-cli php-common zip git sysvinit-utils php-xml php-ldap"
    fi
    pgsqlpkgs="postgresql php-pgsql"
elif [[ $isfedorabased == true ]]; then
    #dbpkgs="community-mysql-server postgresql-server"
    dbpkgs="mariadb postgresql-server"
    mysqlpkgs="mariadb mariadb-server php-mysqlnd"
    pgsqlpkgs="postgresql-server postgresql-contrib php-pgsql"
    morepkgs="httpd php php-cli php-common zip unzip wget git php-xml php-ldap policycoreutils-python*"
    # composer install from source seems to need php-json
    # but is already installed with the remi package (Centos 7)
    if [ $(ver $vers) -lt $(ver "7") ]; then
        morepkgs+=" php-json"
    fi
else
    abort "Distribution unsupported."
fi

if [ $devel == true ]; then
    morepkgs+=" php-mbstring"
fi

dbmsmissing=`packages_missing $dbpkgs`

if [ $interactive == true ] && [ -z $dbtype ]; then
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
      [ "$dbmissing" == "mysql-server" ] && dbtype="pgsql" || dbtype="mysql"
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
            dbtype="pgsql"
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

# TODO check if additional packages to be inserted here
allpkgs="$dbmspkgs $mtapkg $morepkgs"
install_packages "$allpkgs"
