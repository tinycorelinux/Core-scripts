#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
TMP=/tmp/select.$$
LOCAL=/opt/localmirrors
MIRRORS="/usr/local/share/mirrors"

[ -f "$LOCAL" ] && cat "$LOCAL" > "$TMP"
[ -f "$MIRRORS" ] && cat "$MIRRORS" >> "$TMP"
if [ ! -s "$TMP" ]; then
   echo "Requires mirrors.tcz extension or /opt/localmirrors"
   exit 1
fi
select "Tiny Core Linux - Mirror Selection" "$TMP"
ANS="$(cat /tmp/select.ans)"
rm "$TMP"

case "$ANS" in
https*)
   if ! [ -f /usr/local/tce.installed/ca-certificates ]; then
      echo "https mirrors require the ca-certificates.tcz extension to be installed"
      exit 1
   fi
   ;;
esac
[ "$ANS" != "q" ] && echo "$ANS" > /opt/tcemirror
