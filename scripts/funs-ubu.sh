#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"
source "$context/funs-input.sh"

function packages_missing() {
    # Check the debian dpkg database for one or more packages to ensure they
    # are installed on the system. Returns the name of all packages that don't
    # have the dpkg-query status "install ok installed".
    #
    # TODO Please someone confirm the followin fix! (@zindy to blame).
    # There was an issue detecting the "mariadb-server" package, so I
    # extented the search by adding a star at the end of the package name
    # so we can detect that "mariadb-server-10.1" (for example) is installed.
    # However, $VALID may not be at the beginning of the status returned by
    # dpkg-query. For example, the search for "mariadb-server*" returns:
    #
    # unknown ok not-installedinstall ok installedunknown ok \
    # not-installedunknown ok not-installedinstall ok
    #
    # Grep-ing for 'install ok installed' somewhere in the $Status string
    # should be enough to confirm a package is installed, but do let me know
    # if this change breaks the query test for any other packages used by HRM.

    local VALID='install ok installed'
    unset PKGSMISSING
    for PKG in $* ; do
        if ! dpkg-query -W -f='${Status}' "$PKG*" 2>&1 | grep -q "$VALID" ; then
            PKGSMISSING="$PKGSMISSING $PKG"
        fi
    done
    echo $PKGSMISSING
}

function install_packages()
{
	MISSING=$(packages_missing $1)
	if [ -n "$MISSING" ] ; then
	    msg="The following packages will be installed:\n$MISSING"

        set_adminpass=false
        if [[ $MISSING == *"mysql-server"* ]]; then
            if [ $dbadmin != "root" ]; then
                echo "New mysql-server install, changing dbadmin to root"
                dbadmin="root"
            fi
            [ -n "$adminpass" ] && set_adminpass=true
        fi

        if [ $interactive == true ]; then
            # Here we exit if user selected no.
            (whiptail --title "$title" --yesno "$msg" 8 70) || exit 1
        else
            printf "$msg\n"
            export DEBIAN_FRONTEND=noninteractive
        fi
        apt-get -y install $MISSING

	    MISSING=$(packages_missing $1)
	    if [ -n "$MISSING" ]; then
            msg="Could not install packages: $MISSING"
            wt_print "$msg" --title="$title" --interactive=$interactive --quit=true
        fi

        # Set the root password
        if [ $set_adminpass == true ]; then
            mysqladmin -u root password "$adminpass"
        fi
	fi
}

