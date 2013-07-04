#!/bin/sh
# (c) Robert Shingledecker 2012
# Wait for network to come up and then set time
CNT=0
until ifconfig | grep -q Bcast
do
	[ $((CNT++)) -gt 60 ] && break || sleep 1
done
if [ $CNT -le 60 ]
then
	CNT=0
	until /usr/bin/getTime.sh >/dev/null 2>&1
	do
		[ $((CNT++)) -gt 5 ] && break || sleep 1
	done
fi
