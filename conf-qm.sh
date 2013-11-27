#!/bin/bash

echo "Configuring HRM queue manager to start at boot"

cp $hrmdir/bin/hrmd /etc/init.d/
chmod +x /etc/init.d/hrmd
update-rc.d hrmd defaults

# bring up queue manager
/etc/init.d/hrmd start
