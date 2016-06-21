#!/bin/bash

echo "Configuring HRM queue manager to start at boot"

if [[ "$dist" == "Ubuntu" ]]
then
	if [[ "$vers" < "14.10" ]]
	then
		ans="v"
	else
		ans="d"
	fi
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
	cp $hrmdir/resources/systemd/hrmd.service /etc/systemd/system/
	systemctl enable hrmd.service
	systemctl start hrmd.service
	systemctl status hrmd.service
elif [ "$inittype" == "sysv" ] ; then
	cp $hrmdir/resources/sysv-init-lsb/hrmd /etc/init.d/
	chmod +x /etc/init.d/hrmd
	if [ "$dist" == "Ubuntu" ] ; then
		update-rc.d hrmd defaults
	elif [ "$dist" == "Fedora" ] ; then
		chkconfig hrmd on
	else
		abort "Distribution unsupported."
	fi
	service hrmd start > /dev/null
	sleep 2
	service hrmd status
fi

