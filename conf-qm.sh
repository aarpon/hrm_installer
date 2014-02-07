#!/bin/bash

echo "Configuring HRM queue manager to start at boot"

cp $hrmdir/bin/hrmd /etc/init.d/
chmod +x /etc/init.d/hrmd

if [ "$dist" == "Ubuntu" ]
then
	update-rc.d hrmd defaults
	/etc/init.d/hrmd start
elif [ "$dist" == "Fedora" ]
then
	chkconfig --add hrmd
	service hrmd start
else
	abort "Distribution unsupported."
fi

