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
	MISSING=$(packages_missing $1)
	if [ -n "$MISSING" ] ; then
	    echo -e "\nThe following packages will be installed:\n$MISSING\n"
	    waitconfirm
	    apt-get install $MISSING
	    MISSING=$(packages_missing $1)
	    [ -z "$MISSING" ] || errcheck "Could not install packages: $MISSING"
	fi
}

