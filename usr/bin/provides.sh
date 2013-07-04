#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox

TARGET="$1"
[ -z "$TARGET" ] && exit 1

TCEDIR="/etc/sysconfig/tcedir"
DB="provides.db"

getMirror
cd "$TCEDIR"
if zsync -i "$TCEDIR"/"$DB" -q "$MIRROR"/"$DB".zsync
then
	rm -f "$DB".zs-old
else
	wget -O "$TCEDIR"/"$DB" "$MIRROR"/"$DB"
fi
cd - > /dev/null

awk 'BEGIN {FS="\n";RS=""} /'${TARGET}'/{print $1}' "$TCEDIR"/"$DB"
