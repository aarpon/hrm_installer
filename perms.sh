#!/bin/bash

# correct all permissions
chmod g+w /var/log/hrm/*

# check for $imgdir permissions
# check group, owner,and sticky
line=`ls -la $imgdir | head -n2 | tail -n1`
sticky=`echo "$line" | cut -c 7`
owner=`echo "$line" | cut -d ' ' -f 3`
group=`echo "$line" | cut -d ' ' -f 4`

[ "$sticky" != "s" ] || [ "$owner" != "$hrm_user" ] || [ "$group" != "$hrm_group" ] && echo "Bad permissions on $imgdir, please set permissions (drwsrwsr-x) and ownership (hrmuser hrm)."

# patch script, which creates user dirs, hopefully not needed for next release
sedconf $hrmdir/bin/hrm 'CMD="sudo -u \$SUSER"' 'CMD=""'

if [ "$dist" == "Fedora" ]
then
	setsebool -P allow_httpd_anon_write=1
	semanage fcontext -a -f d -t httpd_sys_rw_content_t "$imgdir"
	restorecon -RF "$imgdir"
	semanage fcontext -a -t httpd_sys_script_exec_t $hrmdir/bin/hrm
	restorecon -RF $hrmdir/bin/hrm
	setsebool -P httpd_can_network_connect 1
	setsebool -P httpd_execmem 1
	setsebool -P httpd_enable_cgi 1
	setsebool -P httpd_unified 1
	setsebool -P httpd_tty_comm 1
fi

