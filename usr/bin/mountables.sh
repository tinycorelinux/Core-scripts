#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
TEMP=/tmp/mountables$$
LIST=/tmp/mountables
[ -f "$LIST" ] && rm -f "$LIST"
cat /etc/fstab | awk -F '/' '/\/mnt\// {print $3}' | awk '{ sub(/[ \t]+$/, ""); print }' | sort -r | awk 'a != $0; { a = $0 }' | sort > "$TEMP"
while read DEVICE; do
  LABEL=""
  [ ${DEVICE:0:2} != "fd" ] && LABEL="$(getdisklabel "/dev/$DEVICE")"
  echo "$DEVICE"~"$LABEL" >> "$LIST"
done < "$TEMP"
rm "$TEMP"
