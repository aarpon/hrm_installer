#!/bin/bash

# correct all permissions
chmod g+w /var/log/hrm/*

# check for $imgdir permissions
# check group, owner,and sticky
line=`ls -la $imgdir | head -n2 | tail -n1`
sticky=`echo "$line" | cut -c 7`
owner=`echo "$line" | cut -d ' ' -f 3`
group=`echo "$line" | cut -d ' ' -f 4`

[ "$sticky" != "s" ] || [ "$owner" != "$hrm_user" ] || [ "$group" != "$hrm_group" ] && echo "Bad permissions on $imgdir, please set permissions (drwsrwsr-x) and ownership (hrm-user hrm)."

# patch script, which creates user dirs, hopefully not needed for next release
sedconf $hrmdir/bin/hrm 'CMD="sudo -u \$SUSER"' 'CMD=""'

if [ "$dist" == "Fedora" ]
then
	setsebool -P allow_httpd_anon_write=1
	chcon -R -t httpd_sys_script_rw_t "$imgdir"
fi

