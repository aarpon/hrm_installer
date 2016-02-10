#!/bin/bash

echo "Configuring HRM queue manager to start at boot"

cp $hrmdir/bin/hrmd /etc/init.d/
chmod +x /etc/init.d/hrmd

if [ "$dist" == "Ubuntu" ]
then
#	cp hrmd /etc/init.d/	### hotfix till next release
#	chmod +x /etc/init.d/hrmd #####
	update-rc.d hrmd defaults
	/etc/init.d/hrmd start
elif [ "$dist" == "Fedora" ]
then
	cp hrmd.service /etc/systemd/system/
	cp hrmd /etc/init.d/hrmd
	systemctl enable hrmd.service
else
	abort "Distribution unsupported."
fi

