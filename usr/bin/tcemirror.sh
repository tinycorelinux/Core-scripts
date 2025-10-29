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

[ "$ANS" == "q" ] && exit

MIRRORPROTO="${ANS%%://*}"

# if this is changed also change /etc/init.d/tc-functions

# supported protocols for mirror
if
  [ "$MIRRORPROTO" != "http" ] &&
  [ "$MIRRORPROTO" != "https" ] &&
  [ "$MIRRORPROTO" != "ftp" ]; then
  echo "Mirror must use http[s] or ftp"
  exit 1
fi

# https mirrors can't be done without some extensions
if [ "$MIRRORPROTO" == "https" ]; then
  # Test if the required extensions are installed
  [ -e /usr/local/tce.installed/ca-certificates ] || NeedCrt=1
  [ -e /usr/local/tce.installed/openssl ] || NeedSSL=1

  if [ -n "$NeedCrt$NeedSSL" ]; then
    echo "The following are required before using https mirrors:"
    [ -n "$NeedCrt" ] && echo "ca-certificates.tcz"
    [ -n "$NeedSSL" ] && echo "openssl.tcz"
    exit 1
  fi
fi

echo "$ANS" > /opt/tcemirror
