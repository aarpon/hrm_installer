#!/bin/bash

source "$(dirname $BASH_SOURCE)/funs.sh"

echo "Configuring HRM queue manager to start at boot"

if [[ "$dist" == "Debian" ]]
then
    ans="v"
elif [[ "$dist" == "Ubuntu" ]]
then
    if [[ "$vers" < "14.10" ]]
    then
        ans="v"
    else
        ans="d"
    fi
elif [[ "$dist" == "Fedora" ]]
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
    if [ "$dbtype" == "pgsql" ]; then
        sedconf $hrmdir/resources/systemd/hrmd.service "Requires=mysql" "Requires=postgresql"
        sedconf $hrmdir/resources/systemd/hrmd.service "After=mysql" "After=postgresql"
    elif [ "$dist" == "Fedora" ] ; then
        # FIXME CentOS 7 uses mariadb -- Maybe need better tests here?
        sedconf $hrmdir/resources/systemd/hrmd.service "Requires=mysql" "Requires=mariadb"
        sedconf $hrmdir/resources/systemd/hrmd.service "After=mysql" "After=mariadb"
    fi

    sedconf $hrmdir/resources/systemd/hrmd.service "User=hrm" "User=$sysuser"
    sedconf $hrmdir/resources/systemd/hrmd.service "Group=hrm" "Group=$sysgroup"
    sedconf $hrmdir/resources/systemd/hrmd.service "ExecStart=/var/www/html/hrm" "ExecStart=$hrmdir"

    cp $hrmdir/resources/systemd/hrmd.service /etc/systemd/system/
    #chmod +x /etc/systemd/system/hrmd.service
    systemctl daemon-reload
    systemctl enable hrmd.service
    #systemctl start hrmd.service
    #systemctl status hrmd.service

    if [ "$dist" == "Fedora" ] ; then
        chkconfig httpd on
    fi

elif [ "$inittype" == "sysv" ] ; then
    cp $hrmdir/resources/sysv-init-lsb/hrmd /etc/init.d/
    chmod +x /etc/init.d/hrmd
    if [ "$dist" == "Ubuntu" ] || [[ "$dist" == "Debian" ]]; then
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

