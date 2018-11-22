#!/bin/bash

title="Welcome to the HRM installation script." 

source scripts/argparser.sh

# Here we parse command line input. The script can be launched as non-interactive with --interactive=false

opti=true
interactive=true
optd=false
debug=false
devel=false
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
hrmpass="pwd4hrm"
zippath=""

declare -A ARGPARSER_MAP
ARGPARSER_MAP=(
    [h]=help
    [i]=interactive
    [d]=debug
    [D]=devel
)
 
parse_args "$@"

$optD && devel=true || devel=false

# This ensures we run the right installation script
# Can either run with hrmtag="devel" or run with -D
[[ "$hrmtag" == "devel" ]] && devel=true
$devel && hrmtag="devel"

# Handling of zip file installation
[ -n "$zippath" ] && hrmtag="zip"

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

    # FIXME xtrace breaks the script because of the extra output
    # May need to fix that, xtrace can be quite useful...
    #
    # "xtrace" can be switched on for debugging if desired.
    #set -o xtrace

fi

source scripts/funs.sh
source scripts/funs-input.sh

# Exit on any error. That's very important as we require being run as root and
# thus anything that goes wrong has a huge potential impact on the system.
set -o errexit

# Ensure we don't get localized output from various tools, otherwise many of
# the tests will behave pretty much unpredictable.
export LC_ALL=C

#dist=`cat /etc/issue | head -n1 | cut -d ' ' -f1`;
dist=`cat /etc/os-release | head -n1 | grep -Po '".*?"' | tr -d '"'`
dist=${dist%% *}
vers=`cat /etc/os-release | grep VERSION_ID | cut -d '=' -f2`
msg="Detected $dist $vers installation"

if  [ "$dist" == "" ]; then
    dist=`cat /etc/os-release | head -n1 | cut -d '=' -f2`
fi

if [ "$dist" == "Debian" ] || [ "$dist" == "Ubuntu" ]; then
    msg1=""
    if [[ "$(whoami)" != "root" ]]; then
        msg1="You need to run setup.sh as root (sudo ./setup.sh)."
    elif [[ "$dist" == "Ubuntu" ]]  && [[ "$vers" < '"18"' ]]; then
        # FIXME Which version of Ubuntu are we targetting for devel?
        [ $devel == true ] && msg1="Devel HRM only supports Ubuntu 18.04 or above."
    elif [[ "$dist" == "Debian" ]]  && [[ "$vers" < '"9"' ]]; then
        # FIXME Which version of Debian are we targetting for devel?
        [ $devel == true ] && msg1="Devel HRM only supports Debian 9 or above."
    fi
    [ -n "$msg1" ] && wt_print "$msg\n\n$msg1" -q --title="$title" --interactive="$interactive" --debug=$debug
    source scripts/funs-ubu.sh
elif [ "$dist" == "Fedora" ]; then
    fedpkg="dnf"
    source scripts/funs-fed.sh
elif [ "$dist" == "CentOS Linux" ]; then
    dist="Fedora"
    fedpkg="yum"
    source scripts/funs-fed.sh
else
    msg="$msg\n\nThis distribution is not supported."
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
fi

hucorepath=`which hucore || true`
if [ -z "$hucorepath" ] || [ ! -f "$hucorepath" ]; then
    msg="$msg\n\nPlease install hucore first (https://svi.nl/Download)"
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
fi

title="Installing system packages (step 1/7)" 
$interactive || echo "---- $title ----"
source scripts/inst-pkgs.sh

title="Configuring the database (step 2/7)" 
$interactive || echo "---- $title ----"
source scripts/conf-db-generic.sh
#TODO postgresql in the script above...

title="Installing HRM files (step 3/7)" 
$interactive || echo "---- $title ----"
source scripts/inst-hrm.sh

title="Configuring HRM (step 4/7)" 
$interactive || echo "---- $title ----"
source scripts/conf-hrm.sh

title="Configuring PHP (step 5/7)" 
$interactive || echo "---- $title ----"
source scripts/conf-php.sh

title="Making the database (step 6/7)" 
$interactive || echo "---- $title ----"
source scripts/make-db.sh

title="Configuring the queue manager (step 7/7)" 
$interactive || echo "---- $title ----"
source scripts/conf-qm.sh

title="HRM installation complete" 
$interactive || echo "---- $title ----"
source scripts/perms.sh

if [ "$dist" == "Fedora" ]
then
    msg="Apache, database and queue manager system services will start automatically at boot."
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
    systemctl enable httpd.service
    [[ "$dbtype" == "postgres" ]] && systemctl enable postgresql.service
    [[ "$dbtype" == "mysql" ]] && systemctl enable mariadb.service
fi

hqn=`host -TtA $(hostname -s)|grep "has address"|awk '{print $1}'`
hrmd=`basename $hrmdir`

msg="Please restart your system and open HRM in your web browser\n(e.g., http://localhost/$hrmd or http://$hqn/$hrmd)."
msg="$msg\nThe default admin account is login 'admin' with password '$hrmpass'."

wt_print "$msg" --title="$title" --interactive="$interactive" --debug=$debug
$interactive && printf "$msg\n"
