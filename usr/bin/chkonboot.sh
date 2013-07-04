#!/bin/sh
. /etc/init.d/tc-functions
BOOTLIST=`getbootparam lst` || BOOTLIST="onboot.lst"
TCEDIR=/etc/sysconfig/tcedir
[ -s "$TCEDIR"/"$BOOTLIST" ] || exit 1
for B in $(cat "$TCEDIR"/"$BOOTLIST")
do
	if [ -s "$TCEDIR"/optional/"$B".dep ]
	then
		for D in $(cat "$TCEDIR"/optional/"$B".dep)
		do
			if grep -q "^$D$" "$TCEDIR"/"$BOOTLIST"
			then
				echo "$D" not needed a dep of "$B"
			fi
		done
	fi
done
echo "Scan of $BOOTLIST completed."
