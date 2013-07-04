#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
version="1.00"
scriptName="getTime.sh"
#
# This script gets time information from time.nist.gov in
# universal time format. It then rearranges it into ISO 8601
# format that the busybox date command accepts (i.e. CCYY-MM-DD hh:mm:ss)
# and issues the date command as super user, unless when just required to
# print the time information
#
# An internet connection must be available
#
#  sample of returned information follows
#54144 07-02-13 16:14:43 00 0 0  95.3 UTC(NIST) *
#12345678901234567890123456789012345678901234567890
#
[ "x$1" = "x-p" ] && shift && PRINT=1
NIST="$1"
USTIMING_SERVERS="atl chi sj"   # the whole list: "atl chi la lv nj ny pa sj"
[ -z "$NIST" ] && NIST="nist1-$( echo "$USTIMING_SERVERS" \
    | awk '{ srand(); n=int(rand() * NF) + 1; print $n }' ).ustiming.org"
R=$( nc -w 3 "$NIST" 13 | grep "UTC(NIST)")
if [ -n "$R" ] ; then
  S=20$( echo "$R" | cut -c 7-23 )
  if [ -n "$PRINT" ] ; then
    echo "${S}$( echo $R | cut -c 37-46 )"
  else
    sudo busybox date -u "$S"
  fi
  date
else
  echo "no response from $NIST" > /dev/stderr
  exit 1
fi
