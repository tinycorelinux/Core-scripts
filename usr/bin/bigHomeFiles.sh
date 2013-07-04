#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
find ${HOME} -type f -size +1024k | xargs ls -lSh 2>/dev/null |  awk '{printf "%s\t%s\n",$5,$9}'
