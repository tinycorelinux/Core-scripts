#!/bin/busybox ash
# Find which extensions depend on a particular extension.
# Usage:
#        depends-on.sh poppler07.tcz
#
#  Returns a list of all extensions that depend on poppler07.tcz.
#  Search is fuzzy by default. Use -e flag for an exact search.
#
#  Most of this script was copied from provides.sh.  Rich.

. /etc/init.d/tc-functions
useBusybox

exact=false
if [ "$1" = "-e" ]; then
	exact=true
	shift
fi

TARGET="$1"

case $TARGET in
    ""|-h|-help|--help)
        echo
        head -n8 $0 | grep -v "!/bin/" | tr '#' ' '
        echo
        exit 1
        ;;
esac

TCEDIR="/etc/sysconfig/tcedir"
DB="dep.db"
DBGZ="$DB.gz"

# This downloads a fresh copy of dep.dbgz if any of the following are true:
# 1. The file does not exist.
# 2. The file is older than 1 hour (3600 seconds).
cd "$TCEDIR"
if [ -f "$DBGZ" ]
then
        # Compute number of seconds since provides.db modified (downloaded).
        Age=$(( $(date +%s) - $(date -r "$DBGZ"  +%s) ))
        if [ $Age -gt 3600 ]
        then
                # File is too old, delete it.
                rm "$DBGZ"
        fi
fi
if [ ! -f "$DBGZ" ]
then
        getMirror
        wget -q -O "$TCEDIR"/"$DBGZ" "$MIRROR"/"$DBGZ"
        # Make sure it has a current timestamp.
        touch "$DBGZ"
fi

gunzip -kf "$DBGZ"

cd - > /dev/null

if $exact; then
	TARGET="${TARGET%.tcz}.tcz"
	awk 'BEGIN {FS="\n";RS=""} /\n'${TARGET}'/{print $1}' "$TCEDIR"/"$DB" | grep -v "^${TARGET}"
else
	awk 'BEGIN {FS="\n";RS=""} /'${TARGET}'/{print $1}' "$TCEDIR"/"$DB"
fi

