#!/bin/busybox ash
# bmarkus - 26/02/2014

NTPSERVER=$(cat /etc/sysconfig/ntpserver)
/usr/sbin/ntpd -q -p $NTPSERVER
