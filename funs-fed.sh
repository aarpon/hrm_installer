function packages_missing() {
    # Check the yum pkg database for one or more packages to ensure they
    # are installed on the system. Returns the name of all packages that aren't
    # listed as installed.
    local VALID='Installed Packages$'
    unset PKGSMISSING
    for PKG in $* ; do
        if ! $fedpkg list installed $PKG 2>&1 | grep -q "$VALID" ; then
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
	    $fedpkg install $MISSING
	    MISSING=$(packages_missing $1)
	    [ -z "$MISSING" ] || errcheck "Could not install packages: $MISSING"
	fi
}

