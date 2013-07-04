#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
busybox | sed '1,/functions:$/d' \
| tr -d ' \t\n' | tr ',' '\n' | while read F ; do
  L=$(which $F)
  T=$(ls -l $L 2> /dev/null | sed -e 's#.* -> ##' -e 's#.*/##')
  [ -z "$L" ] && echo "no softlink for $F"
  [ -n "$L" ] && [ "$T" != "busybox" ] && echo "$L not using busybox"
done