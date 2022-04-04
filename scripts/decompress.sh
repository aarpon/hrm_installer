#!/bin/bash

title="---- Self Extracting HRM Installer ----"
echo $title

export TMPDIR=`mktemp -d /tmp/hrm_selfextract.XXXXXX`
echo "Script files extracted to $TMPDIR"

ARCHIVE=`awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0`

tail -n+$ARCHIVE $0 | tar xjv -C $TMPDIR

CDIR=`pwd`
cd $TMPDIR

echo ""
./setup.sh "$@"

cd $CDIR

echo ""
echo $title
echo "Temporary location $TMPDIR was removed"
rm -rf $TMPDIR

exit 0

__ARCHIVE_BELOW__
