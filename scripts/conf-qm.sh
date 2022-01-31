#!/bin/bash

source "$(dirname $BASH_SOURCE)/funs.sh"

echo "Configuring HRM queue manager to start at boot"

if [ "$dist" == "Debian" ]
then
    if [ $(ver $vers) -lt $(ver "8.0") ]
    then
        ans="v"
    else
        ans="d"
    fi
elif [ "$dist" == "Ubuntu" ]
then
    if [ $(ver $vers) -lt $(ver "14.10") ]
    then
        ans="v"
    else
        ans="d"
    fi
elif [ "$dist" == "Fedora" ]
then
    ans="d"
else
    echo "Please select which init system your distribution is using, 'systemd' [d]"
    echo "or classical 'System-V-init' [v] (shellscripts in /etc/init.d/ or similar)"
    ans=`readkey_choice 'd' 'v'`
fi

case $ans in
    d)
        inittype="systemd"
        ;;
    v)
        inittype="sysv"
        ;;
    *) abort "Wrong init system type selected!"
        ;;
esac
echo "Configuring startup for init system type '$inittype'."


if [ "$inittype" == "systemd" ] ; then
    sysdir="/etc/systemd/system/"
    cp $hrmdir/resources/systemd/hrmd.service $sysdir

    if [ "$dbtype" == "pgsql" ]; then
        sedconf $sysdir/hrmd.service "^Requires=.*" "Requires=postgresql"
        sedconf $sysdir/hrmd.service "^After=.*" "After=postgresql"
    elif [ "$dist" == "Fedora" ] ; then
        # FIXME CentOS 7 uses mariadb -- Maybe need better tests here?
        sedconf $sysdir/hrmd.service "^Requires=.*" "Requires=mariadb"
        sedconf $sysdir/hrmd.service "^After=.*" "After=mariadb"
    fi

    sedconf $sysdir/hrmd.service "^User=.*" "User=$sysuser"
    sedconf $sysdir/hrmd.service "^Group=.*" "Group=$sysgroup"

    #chmod +x /etc/systemd/system/hrmd.service
    systemctl daemon-reload
    systemctl enable hrmd.service
    systemctl restart hrmd.service
    #systemctl status hrmd.service

    if [ "$dist" == "Fedora" ] ; then
        chkconfig httpd on
    fi

elif [ "$inittype" == "sysv" ] ; then
    cp $hrmdir/resources/sysv-init-lsb/hrmd /etc/init.d/
    chmod +x /etc/init.d/hrmd
    if [ "$dist" == "Ubuntu" ] || [ "$dist" == "Debian" ]; then
        update-rc.d hrmd defaults
    elif [ "$dist" == "Fedora" ] ; then
        chkconfig hrmd on
    else
        abort "Distribution unsupported."
    fi
    service hrmd start > /dev/null
    sleep 2
    /etc/init.d/hrmd status
fi

