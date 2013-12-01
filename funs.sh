function abort()
{
        echo -e "$1\nAborting HRM installation."
        exit 1
}

function errcheck()
{
        [ $? ] && abort "$1"
}

function packages_missing() {
    # Check the debian dpkg database for one or more packages to ensure they
    # are installed on the system. Returns the name of all packages that don't
    # have the dpkg-query status "install ok installed".
    local VALID='install ok installed$'
    unset PKGSMISSING
    for PKG in $* ; do
        if ! dpkg-query -W -f='${Status}' $PKG 2>&1 | grep -q "$VALID" ; then
            PKGSMISSING="$PKGSMISSING $PKG"
        fi
    done
    echo $PKGSMISSING
}

function install_packages()
{
        aptitude install "$1"
}

function readkey() {
    # Read a single keypress and return it as lower-case. Optionally, the
    # prompt can be set by providing a string as 1st positional parameter.
    if [ -n "$1" ] ; then
        _PROMPT="$1"
    else
        _PROMPT="> "
    fi
    read -p "$_PROMPT" -n 1
    echo $REPLY | tr '[A-Z]' '[a-z]'
    unset _PROMPT
}

function readkey_choice() {
    # Ask the user for pressing one of two keys (case insensitive). If not
    # specified otherwise, 'y' and 'n' are the default keys.
    [ -n "$1" ] && CH1="$1" || CH1="y"
    [ -n "$2" ] && CH2="$2" || CH2="n"
    unset REPLY
    while [ "$REPLY" != "$CH1" ] && [ "$REPLY" != "$CH2" ] ; do
        REPLY=$(readkey " [$CH1/$CH2] ")
    done
    echo $REPLY
    unset REPLY CH1 CH2
}

function readstring() {
    # Show a preset string that can be changed or accepted.
    # Do not accept empty return values.
    while [ -z "$REPLY" ] ; do
        read -p '> ' -e -i "$1"
    done
    echo $REPLY
}

function waitconfirm() {
    # Display a message and wait for the user to confirm by pressing 'y'.
    echo "Press [y] to continue, [Ctrl]-[C] to abort."
    while ! [ "$(readkey)" == "y" ] ; do
        echo
    done
}

function mysqlcmd()
{
	mysql -h localhost -u $1 -p$2 -e "$3"
}

function pgsqlcmd()
{
	su postgres -c "psql -c \"$1\""
}

function sedconf()
{
	sed -i -e "s|$2|$3|" "$1"
}
