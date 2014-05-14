#!/bin/busybox ash
# Original script by Robert Shingledecker
# (c) Robert Shingledecker 2003-2012
# A simple script to save/restore configs, directories, etc defined by the user
# in the file .filetool.lst
# Added ideas from WDef for invalid device check and removal of bfe password upon failure
# Added comparerestore and dry run (Brian Smith)
. /etc/init.d/tc-functions
useBusybox
CMDLINE="$(cat /proc/cmdline)"

MYDATA=mydata
[ -r /etc/sysconfig/mydata ] && read MYDATA < /etc/sysconfig/mydata
# Functions --

abort(){
  echo "Usage: filetool.sh options device"
  echo "Where required action options are:"
  echo "-b backup"
  echo "-r restore"
  echo "-s safe backup mode"
  echo "-d dry run backup"
  echo "Optional display options are:"
  echo "-p prompted verbose listing"
  echo "-v verbose listing"
  echo -n "Press enter to continue:" ; read ans
  exit 1
}

blowfish_encrypt(){
KEY=$(sudo /bin/cat /etc/sysconfig/bfe)
cat << EOD | sudo /usr/bin/bcrypt -c "$MOUNTPOINT"/"$FULLPATH"/$1 2>/dev/null
"$KEY"
"$KEY"
EOD
if [ "$?" != 0 ]; then failed; fi
sync
}

# clean_up and failed - from non-interactive boot time use.
clean_up(){
if [ $MOUNTED == "no" ]; then
  sudo /bin/umount $MOUNTPOINT
fi
# Only store device name if backup/restore successful
[ $1 -eq 0 ] && echo "${D2#/dev/}"/$FULLPATH  > /etc/sysconfig/backup_device
# Remove bfe password if decryption fails
[ $1 -eq 98 ] && sudo /bin/rm -f /etc/sysconfig/bfe
sync
exit $1
}

failed(){
echo "WARNING: Selected operation has failed. Proceed with extreme caution."
[ "$PROMPT" ] && echo -n "Press enter to continue:" && read ans
clean_up 98
}

# wrapup from after boot to handle both interacive not called from GUI
wrapup(){
	if [ -s /tmp/backup_status ] && [ "$VERBOSE" ]
	then
		cat /tmp/backup_status
		[ "$PROMPT" ] && echo -n "Press enter to continue:" &&  read ans
	fi
	exit 1
}

# Main  --
unset BACKUP PROMPT RESTORE SAFE DRYRUN VERBOSE

[ -z $1 ] && abort
if grep -q "safebackup" /proc/cmdline; then SAFE=TRUE; fi
while getopts bprsdv OPTION
do
  case ${OPTION} in
   b) BACKUP=TRUE ;;
   p) PROMPT=TRUE ;;
   r) RESTORE=TRUE ;;
   s) SAFE=TRUE ;;
   d) DRYRUN=TRUE ;;
   v) VERBOSE=TRUE ;;
   *) abort ;;
  esac
done
[ "$BACKUP" ] && [ "$RESTORE" ] && abort
shift `expr $OPTIND - 1`
# TARGET device is now $1

[ "$PROMPT" ] && VERBOSE=TRUE

if [ $DRYRUN ]; then
  echo "Performing dry run backup (backup will not actually take place).   Please wait."; echo
  totalcompressedsize=`sudo /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst -cvzf - 2>/tmp/backup_dryrun_list | wc -c`
  while read entry; do
    if [ -f "/${entry}" ]; then
      size=`sudo /bin/ls -al "/${entry}" | awk '{print $5}'`
      totalsize=$(($totalsize + $size))
      sizemb=`dc $size 1024 / 1024 / p`
      printf "%6.2f MB  /%s\n" $sizemb "$entry"
    fi
  done < /tmp/backup_dryrun_list
  rm /tmp/backup_dryrun_list
  totalsizemb=`dc $totalsize 1024 / 1024 / p`
  totalcompressedsizemb=`dc $totalcompressedsize 1024 / 1024 / p`
  printf "\nTotal backup size (uncompressed):  %6.2f MB (%d bytes)\n" $totalsizemb $totalsize
  printf "Total backup size (compressed)  :  %6.2f MB (%d bytes)\n\n" $totalcompressedsizemb $totalcompressedsize
  exit 0
fi

#Get the TARGET name from argument 1 or /etc/sysconfig/backup_device
if [ -z $1 ]; then
  TARGET="$(cat /etc/sysconfig/backup_device 2>/dev/null)"
else
  TARGET="$1"
fi

if [ -z "$TARGET" ]; then
  # Last chance to default to persistent TCE directory if exists
  TCEDIR="$(readlink /etc/sysconfig/tcedir)"
  if [ "$TCEDIR" == "/tmp/tce" ]; then
    echo "Invalid or not found $TARGET" > /tmp/backup_status
    wrapup
  else
    TARGET="${TCEDIR#/mnt/}"
  fi
fi

TARGET="${TARGET#/dev/}"
DEVICE="${TARGET%%/*}"
FULLPATH="${TARGET#$DEVICE/}"
[ "$FULLPATH" = "$DEVICE" ] && FULLPATH=""

find_mountpoint $DEVICE

if [ -z "$MOUNTPOINT" ]; then
  echo "Invalid device $DEVICE" > /tmp/backup_status
  wrapup
fi

if [ $MOUNTED == "no" ]; then
   sudo /bin/mount $MOUNTPOINT
   if [ "$?" != 0 ]; then
      echo "Unable to mount device $DEVICE" > /tmp/backup_status
      wrapup
   fi
fi

echo "${D2#/dev/}"/$FULLPATH > /etc/sysconfig/backup_device

trap failed SIGTERM

if [ "$BACKUP" ] ; then
  sed -i /^$/d /opt/.filetool.lst
  if [ "$SAFE" ]; then
    if [ -r $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz.bfe -o -r $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz ]; then                     
      echo -n "Copying existing backup to $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.[tgz|tgz.bfe] .. "  
      sudo /bin/mv -f $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.tgz 2>/dev/null || sudo /bin/mv -f $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz.bfe $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.tgz.bfe 2>/dev/null
      if [ "$?" == 0 ]; then
        echo -e "\nDone."
      else
        echo "Error: Unable to rename ${MYDATA}.tgz to ${MYDATA}bk.tgz"
        exit 2
      fi
    else                                                                                                                      
      echo "Neither ${MYDATA}.tgz nor ${MYDATA}.tgz.bfe exist.  Proceeding with creation of initial backup ..."               
    fi
  fi
  if [ "$VERBOSE" ]; then
    sudo /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst  -czvf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz
    [ "$PROMPT" ] && echo -n "Press enter to continue:" &&  read ans
  else
    echo -n "Backing up files to $MOUNTPOINT/$FULLPATH/${MYDATA}.tgz"
    [ -f /tmp/backup_status ] && sudo /bin/rm -f /tmp/backup_status
    sudo /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst  -czf "$MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz"  2>/tmp/backup_status &
    rotdash $!
    sync
    [ -s /tmp/backup_status ] && sed -i '/socket ignored/d' /tmp/backup_status 2>/dev/null
    [ -s /tmp/backup_status ] && exit 1
    touch /tmp/backup_done
  fi
  if [ -f /etc/sysconfig/bfe ]; then
     echo -n "encrypting .. "
     blowfish_encrypt ${MYDATA}.tgz
  fi
  echo -e "\nDone."
  clean_up 0
fi

if [ "$RESTORE" ] ; then
  if [ -f /etc/sysconfig/bfe ]; then
     TARGETFILE="${MYDATA}.tgz.bfe"
  else
     TARGETFILE="${MYDATA}.tgz"
  fi
  
  if [ ! -f $MOUNTPOINT/"$FULLPATH"/$TARGETFILE ] ; then
     if [ $MOUNTED == "no" ]; then
      sudo /bin/umount $MOUNTPOINT
     fi
  fi
  
  if [ -f /etc/sysconfig/bfe ] && [ -f "$MOUNTPOINT"/"$FULLPATH"/"$TARGETFILE" ]; then
     KEY=$(sudo /bin/cat /etc/sysconfig/bfe)
     cat << EOD | sudo /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/"$TARGETFILE" 2>/dev/null >/dev/null
"$KEY"
EOD
     if [ "$?" != 0 ]; then failed; fi
     if grep -q "comparerestore" /proc/cmdline && [ ! -e /etc/sysconfig/comparerestore ]; then
       for file in `cat << EOD | /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | tar -tzf -
"$KEY"
EOD`; do
	 if [ -f "/${file}" ]; then
	   sudo /bin/mv "/${file}" "/${file}.orig_file"
	 fi
       done
       sudo /bin/touch /etc/sysconfig/comparerestore
     fi
     
     if [ "$VERBOSE" ]; then
cat << EOD | sudo /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | sudo /bin/tar  -C / -zxvf -
"$KEY"
EOD
       if [ "$?" != 0 ]; then failed; fi
     else
       echo -n "Restoring backup files from encrypted backup $MOUNTPOINT/$FULLPATH mounted over device $D2 "
cat << EOD | sudo /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | sudo /bin/tar  -C / -zxf -
"$KEY"
EOD
       if [ "$?" != 0 ]; then failed; fi
       echo -e "\nDone."
     fi
     clean_up 0
  else
     if [ -f /etc/sysconfig/bfe ]; then
        echo
        echo "Warning PROTECT boot code used and encrypted backup file not found!"
        echo "Proceeding with normal restore operations."
        echo "Encryption will occur upon next backup or shutdown."
	[ "$PROMPT" ] && echo -n "Press enter to continue:" && read ans
     fi
  fi
# End bfe  
  
  if grep -q "comparerestore" /proc/cmdline && [ ! -e /etc/sysconfig/comparerestore ]; then
    for file in `tar -tzf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz`; do
      if [ -f "/${file}" ]; then
	sudo /bin/mv "/${file}" "/${file}.orig_file"
      fi
    done
    sudo /bin/touch /etc/sysconfig/comparerestore
  fi
  
  if [ "$VERBOSE" ]; then
    sudo /bin/tar -C / -zxvf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz
    [ "$PROMPT" ] && echo -n "Press enter to continue:" && read ans
  else
    echo -n "Restoring backup files from $MOUNTPOINT/$FULLPATH/${MYDATA}.tgz "
    sudo /bin/tar -C / -zxf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz 2>/dev/null &
    rotdash $!
    echo -e "\nDone."
  fi
  clean_up 0
fi
echo "Required action flag is missing: $1"
abort
