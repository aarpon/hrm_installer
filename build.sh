#!/bin/bash

# Compression scheme based on https://www.linuxjournal.com/node/1005818

output_archive='hrm_installer.tar.gz'
output_script='hrm_setup'

tar cvzf "$output_archive" setup.sh scripts

if [ -e "$output_archive" ]; then
    cat scripts/decompress.sh "$output_archive" > "$output_script"
else
    echo "$output_archive does not exist"
    exit 1
fi

chmod 755 "$output_script"
echo "$output_script created"
exit 0
