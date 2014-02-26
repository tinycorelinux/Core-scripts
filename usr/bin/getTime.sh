#!/bin/busybox ash
# bmarkus - 26/02/2014

NTPSERVER=$(cat /etc/sysconfig/ntpserver)
/bin/ntpd -q -p $NTPSERVER
