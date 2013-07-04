#!/bin/busybox ash
# (c) Robert Shingledecker 2003-2012
# Called from tc-config
# A non-interactive script to restore configs, directories, etc defined by the user
# in the file .filetool.lst
. /etc/init.d/tc-functions
useBusybox

TCE="$1"
DEVICE=""
MYDATA=mydata
[ -r /etc/sysconfig/mydata ] && read MYDATA < /etc/sysconfig/mydata
for i in `cat /proc/cmdline`; do
	case $i in
		*=*)
			case $i in
				restore*)
					RESTORE=1
					DEVICE=${i#*=}
				;;
			esac
		;;
		*)
			case $i in
				restore) RESTORE=1 ;;
				protect) PROTECT=1 ;;
			esac
		;;
	esac
done

if [ -n "$PROTECT" ]; then
	# Check if backup file is in TCE directory
	if [ -d "$TCE" ] && [ -f "$TCE"/"$MYDATA".tgz.bfe ]; then
		DEVICE="$(echo $TCE|cut -f3- -d/)"
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=`autoscan "$MYDATA".tgz.bfe 'f'`
	fi
	if [ -n "$DEVICE" ]; then
		/usr/bin/filetool.sh -r "$DEVICE"
		exit 0
	fi
fi

# Check if backup file is in TCE directory
if [ -d "$TCE" ] && [ -f "$TCE"/"$MYDATA".tgz ]; then
	TCEDIR="$(echo $TCE|cut -f3- -d/)"
fi

if [ -z "$DEVICE" ]; then
	if [ -n "$TCEDIR" ]; then
		DEVICE="$TCEDIR"
	else
		DEVICE=`autoscan "$MYDATA".tgz 'f'`
	fi
fi

if [ -n "$DEVICE" ]; then
	/usr/bin/filetool.sh -r "$DEVICE"
	exit 0
fi

# Nothing found, set default backup location
# use persistent TCE directory
if [ "${TCE:0:8}" != "/tmp/tce" ]; then
	DEVICE="${TCE#/mnt/}"
	echo "$DEVICE" > /etc/sysconfig/backup_device
fi
