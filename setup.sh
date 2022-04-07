#!/bin/bash

title="Welcome to the HRM installation script."

source scripts/argparser.sh

# Here we parse command line input. The script can be launched as non-interactive with --interactive=false

opti=true
interactive=true
optd=false
debug=false
devel=false
rolling=false
opth=false
help=false
optb=false
bypass=false
remotedeconv=false
srvhostname="remote.server.com"
dbtype=""
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
hrmurl=""
hrmrepo="https://github.com/aarpon/hrm.git"
hrmtag="latest"
imgdir="/data/images"
srvimgdir="/data/images"
hrmemail="hrm@localhost"
hrmpass="pwd4hrm"
zippath=""
license=""
postmax="2048M"
upmax="1024M"
step=0

hqn=$(hostname --fqdn)

# Detect family of installs (only debian or fedora based for now)
# Granularity with $dist variable
isdebianbased=false
isfedorabased=false

declare -A ARGPARSER_MAP
ARGPARSER_MAP=(
    [h]=help
    [i]=interactive
    [d]=debug
    [D]=devel
    [b]=bypass
)

parse_args "$@"

$optD && devel=true || devel=false
$optb && bypass=true || bypass=false

# This ensures we run the right installation script
# Can either run with hrmtag="devel" or run with -D
[[ "$hrmtag" == "devel" ]] && devel=true
$devel && hrmtag="devel"

# Handling of zip file installation
[ -n "$zippath" ] && hrmtag="zip"

if [ $opth == true ]; then
    # FIXME change devel to latest when we release
    echo -e 'Please check https://huygens-remote-manager.readthedocs.io/en/devel/admin/script_install.html'
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
vers=${vers:1:-1}
if  [ -z "$dist" ]; then
    dist=`cat /etc/os-release | head -n1 | cut -d '=' -f2`
fi

msg="OS detected: $dist $vers"

if [[ $dist == Debian || $dist == Ubuntu ]]; then
    isdebianbased=true
    isfedorabased=false

    msg1=""
    if [ "$dist" == "Ubuntu" ]  && [ $(ver $vers) -lt $(ver "18") ]; then
        # FIXME Which version of Ubuntu are we targetting for devel?
        [ $devel == true ] && msg1="Devel HRM only supports Ubuntu 18.04 or above."
    elif [ "$dist" == "Debian" ]  && [ $(ver $vers) -lt $(ver "9") ]; then
        # FIXME Which version of Debian are we targetting for devel?
        [ $devel == true ] && msg1="Devel HRM only supports Debian 9 or above."
    fi
    [ -n "$msg1" ] && wt_print "$msg\n\n$msg1" -q --title="$title" --interactive="$interactive" --debug=$debug
    source scripts/funs-ubu.sh
elif [[ $dist == CentOS* || $dist == Fedora || $dist == AlmaLinux || $dist == Rocky ]]; then
    isfedorabased=true
    isdebianbased=false

    fedpkg="dnf -y"
    apache_user="apache"

    # No whiptail by default on Centos or Fedora, so install it if interactive mode
    if [[ $interactive == true ]]; then
        $fedpkg install -y newt || true
    fi

    # TODO add a test to check if the version is supported...

    source scripts/funs-fed.sh
else
    msg="$msg\n\nThis distribution is not supported."
    wt_print "$msg" -q --title="$title" --interactive=false --debug=$debug
fi

echo $msg

# Check whether we are running the script as root or not...
if [[ "$(whoami)" != "root" ]]; then
    msg="You need to run setup.sh as root (sudo ./setup.sh)."
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
fi

# Check whether hucore is installed or not
hucorepath=`type -pf hucore 2>/dev/null` || true
if [ -z "$hucorepath" ] || [ ! -f "$hucorepath" ]; then
    msg="$msg\n\nPlease install hucore first (https://svi.nl/Download)"
    wt_print "$msg" -q --title="$title" --interactive="$interactive" --debug=$debug
fi

if [[ $step == 0 || $step == 1 ]]; then
    title="Installing system packages (step 1/7)"
    $interactive || echo "---- $title ----"
    source scripts/conf-hucore.sh
    source scripts/inst-pkgs.sh
fi

if [[ $step == 0 || $step == 2 ]]; then
    title="Configuring the database (step 2/7)"
    $interactive || echo "---- $title ----"
    source scripts/conf-db-generic.sh
    #TODO postgresql in the script above...
fi

if [[ $step == 0 || $step == 3 ]]; then
    title="Installing HRM files (step 3/7)"
    $interactive || echo "---- $title ----"
    source scripts/inst-hrm.sh
fi

if [[ $step == 0 || $step == 4 ]]; then
    title="Configuring HRM (step 4/7)"
    $interactive || echo "---- $title ----"
    source scripts/conf-hrm.sh
fi

if [[ $step == 0 || $step == 5 ]]; then
    title="Configuring PHP (step 5/7)"
    $interactive || echo "---- $title ----"
    source scripts/conf-php.sh
fi

if [[ $step == 0 || $step == 6 ]]; then
    title="Making the database (step 6/7)"
    $interactive || echo "---- $title ----"
    source scripts/make-db.sh
fi

if [[ $step == 0 || $step == 7 ]]; then
    title="Configuring the queue manager (step 7/7)"
    $interactive || echo "---- $title ----"
    source scripts/conf-qm.sh
fi

# This bypasses the license check in login.php (devel option to test the web interface)
if [ $bypass == true ]; then
    echo "WARNING! Added $hrmdir/.hrm_devel_version"
    echo "  to bypass the front-end license check."
    echo "  HRM may break silently because of this."
    echo "  Remove the file for normal HRM operation."
    [ -f $hrmdir/.hrm_devel_version ] || touch $hrmdir/.hrm_devel_version
else
    if [ -f $hrmdir/.hrm_devel_version ]; then
        rm -f $hrmdir/.hrm_devel_version
        echo "Removed the front-end bypass for license check ($hrmdir/.hrm_devel_version)"
    fi
fi

title="HRM installation complete"
$interactive || echo "---- $title ----"
source scripts/perms.sh

if [[ $isfedorabased == true ]]; then
    msg="Apache, database and queue manager system services will start automatically at boot."
    wt_print "$msg" -q --title="$title" --interactive=$interactive --debug=$debug --quit=false
    systemctl enable httpd.service
    [[ "$dbtype" == "postgres" ]] && systemctl enable postgresql.service
    [[ "$dbtype" == "mysql" ]] && systemctl enable mariadb.service
fi


#Display URL using qualified name $hqn if different from user entered URL $hrmurl
hrmd=`basename $hrmdir`
hrmd="http://$hqn/$hrmd"
[[ "$hrmurl" == "$hrmd" ]] && hrmd="" || hrmd=" or $hrmd"

msg="Please restart your system and open HRM in your web browser\n(e.g., $hrmurl$hrmd)."
msg="$msg\n\nThe default admin account is login 'admin' with password '$hrmpass'."

if [ -z "$license" ]; then
    msg="$msg\n\nFor full functionality, please note:\n* you will need to add a valid license string to $CONF_LICENSE and\n* you will need to remove the file $hrmdir/.hrm_devel_version\n\nFor now, hucore license check in HRM will be bypassed."
fi

wt_print "$msg" --title="$title" --interactive="$interactive" --debug=$debug
$interactive && printf "$msg\n"
