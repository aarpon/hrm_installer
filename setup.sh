#!/bin/bash

title="Welcome to the HRM installation script." 

source scripts/argparser.sh

# Here we parse command line input. The script can be launched as non-interactive with --interactive=false

opti=true
interactive=true
optd=false
debug=false
opth=false
help=false
dbtype="mysql"
dbhost="localhost"
dbadmin="root"
adminpass=""
dbname="hrm"
dbuser="hrmuser"
dbpass="pwd4hrm"
sysuser="hrmuser"
sysgroup="hrm"
apache_user="www-data"
hrmdir="/var/www/html/hrm"
hrmrepo="https://github.com/aarpon/hrm.git"
hrmtag="latest"
imgdir="/data/images"
hrmemail="hrm@localhost"

declare -A ARGPARSER_MAP
ARGPARSER_MAP=(
    [h]=help
    [i]=interactive
    [d]=debug
)
 
parse_args "$@"

if [ $opth == true ]; then
    echo "This is all the help you will ever need..."
    exit 0
fi

if [ $optd == true ]; then
    echo "---"
    echo "\$opth = $opth" 
    echo "\$opti = $opti" 
    echo "\$optd = $optd" 
    echo "\$dbtype = $dbtype" 
    echo "\$dbhost = $dbhost" 
    echo "\$dbname = $dbname" 
    echo "\$dbhost = $dbhost" 
    echo "\$dbuser = $dbuser" 
    echo "\$dbpass = $dbpass" 
    echo "\$help = $help" 
    echo "\$interactive = $interactive" 
    echo "\$debug = $debug" 
    echo "\$help = $help" 
fi

source scripts/funs.sh
source scripts/funs-input.sh

# Exit on any error. That's very important as we require being run as root and
# thus anything that goes wrong has a huge potential impact on the system.
set -o errexit

# "xtrace" can be switched on for debugging if desired.
#set -o xtrace

# Ensure we don't get localized output from various tools, otherwise many of
# the tests will behave pretty much unpredictable.
export LC_ALL=C

#dist=`cat /etc/issue | head -n1 | cut -d ' ' -f1`;
dist=`cat /etc/os-release | head -n1 | grep -Po '".*?"' | tr -d '"'`
dist=${dist%% *}
vers=`cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2`
msg="Detected $dist $vers installation"

if  [ "$dist" == "" ]
then
    dist=`cat /etc/os-release | head -n1 | cut -d '=' -f2`
fi

if [ "$dist" == "Debian" ]
then
    if [ "$(whoami)" != "root" ]
    then
        msg="$msg\n\nYou need to run setup.sh as root (sudo ./setup.sh)."
        wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
    fi
    source scripts/funs-ubu.sh
elif [ "$dist" == "Ubuntu" ]
then
    source scripts/funs-ubu.sh
elif [ "$dist" == "Fedora" ]
then
    fedpkg="dnf"
    source scripts/funs-fed.sh
elif [ "$dist" == "CentOS Linux" ]
then
    dist="Fedora"
    fedpkg="yum"
    source scripts/funs-fed.sh
else
    msg="$msg\n\nThis distribution is not supported."
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
fi

hucorepath=`which hucore || true`
if [ -z "$hucorepath" ] || [ ! -f "$hucorepath" ]
then
    msg="$msg\n\nPlease install hucore first (https://svi.nl/Download)"
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
fi

source scripts/inst-pkgs.sh

source scripts/conf-db-generic.sh
#TODO postgresql in the script above...
source scripts/inst-hrm.sh
source scripts/conf-hrm.sh

source scripts/conf-php.sh
source scripts/make-db.sh
source scripts/conf-qm.sh
source scripts/perms.sh

if [ "$dist" == "Fedora" ]
then
    echo "Apache, database and queue manager system services will start automatically at boot."
    systemctl enable httpd.service
    [[ "$dbtype" == "postgres" ]] && systemctl enable postgresql.service
    [[ "$dbtype" == "mysql" ]] && systemctl enable mariadb.service
fi

msg="Please restart your system and open HRM in your web browser (e.g., http://localhost/hrm/)."
msg="$msg\nThe default admin account is login 'admin' with password 'pwd4hrm'."
wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
