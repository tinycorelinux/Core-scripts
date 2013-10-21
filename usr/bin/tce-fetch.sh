#!/bin/busybox ash
#(c) Robert Shingledecker 2004-2012
#
. /etc/init.d/tc-functions
useBusybox
getMirror
KERNELVER=$(uname -r)
if [ "$1" == "-O" ]; then
	shift
	wget -cq -O- "$MIRROR"/"${1//-KERNEL.tcz/-${KERNELVER}.tcz}"
else
	F="${1//-KERNEL.tcz/-${KERNELVER}.tcz}"
	[ -f "$F" ] && rm -f "$F"
	wget -cq "$MIRROR"/"$F"
fi
