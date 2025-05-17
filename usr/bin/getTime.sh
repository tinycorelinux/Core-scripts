#!/bin/busybox ash
if [ -f /etc/sysconfig/ntpserver ]; then
        set $(cat /etc/sysconfig/ntpserver)
        while [ "$1" != "" ]; do
                NTPOPTS="$NTPOPTS -p $1"
                shift
        done
else
        NTPOPTS=""
fi
/usr/sbin/ntpd -q $NTPOPTS
