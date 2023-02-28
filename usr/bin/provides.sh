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
	if [ ! -f "$TCEDIR"/"$DB" ]
	then
	  wget -O "$TCEDIR"/"$DB".gz "$MIRROR"/"$DB".gz
	  gunzip "$TCEDIR"/"$DB".gz
	fi
fi
cd - > /dev/null

awk 'BEGIN {FS="\n";RS=""} /'${TARGET}'/{print $1}' "$TCEDIR"/"$DB"
chmod g+rw "$TCEDIR"/"$DB"
