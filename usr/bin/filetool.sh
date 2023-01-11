#!/bin/busybox ash
# Original script by Robert Shingledecker
# (c) Robert Shingledecker 2003-2012
# A simple script to save/restore configs, directories, etc defined by the user
# in the file .filetool.lst
# Added ideas from WDef for invalid device check and removal of bfe password upon failure
# Added comparerestore and dry run (Brian Smith)
# Added colors (Alphons van der Heijden)
. /etc/init.d/tc-functions
useBusybox

K=1024
M=$(($K * $K))

Fixed3Div()
{
	# divide $1 by $2. Return result to 3 decimal places, no rounding.
	printf "%d.%03d\n" $(($1 / $2)) $(((($1 % $2) * 1000) / $2))
}

CMDLINE="$(cat /proc/cmdline)"

MYDATA=mydata
[ -r /etc/sysconfig/mydata ] && read MYDATA < /etc/sysconfig/mydata
# Functions --

abort(){
  echo "${RED}Usage: ${BLUE}filetool.sh ${MAGENTA}options ${YELLOW}device${NORMAL}"
  echo "Where required action options are:"
  echo "${MAGENTA}-b${NORMAL} backup"
  echo "${MAGENTA}-r${NORMAL} restore"
  echo "${MAGENTA}-s${NORMAL} safe backup mode"
  echo "${MAGENTA}-d${NORMAL} dry run backup"
  echo "Optional display options are:"
  echo "${MAGENTA}-p${NORMAL} prompted verbose listing"
  echo "${MAGENTA}-v${NORMAL} verbose listing"
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
echo "${MAGENTA}WARNING: Selected operation has failed. Proceed with extreme caution.${NORMAL}"
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
  echo "${BLUE}Performing dry run backup (backup will not actually take place).   Please wait.${NORMAL}"; echo
  totalcompressedsize=`sudo /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst -cvzf - 2>/tmp/backup_dryrun_list | wc -c`
  while read entry; do
    if [ -f "/${entry}" ]; then
      size=`sudo /bin/ls -al "/${entry}" | awk '{print $5}'`
      totalsize=$(($totalsize + $size))
      sizemb=`Fixed3Div $size $M`
      printf "%6.2f MB  ${YELLOW}/%s${NORMAL}\n" $sizemb "$entry"
    fi
  done < /tmp/backup_dryrun_list
  rm /tmp/backup_dryrun_list
  totalsizemb=`Fixed3Div $totalsize $M`
  totalcompressedsizemb=`Fixed3Div $totalcompressedsize $M`
  printf "\n${BLUE}Total backup size (uncompressed):  ${NORMAL}%6.2f MB (%d bytes)\n" $totalsizemb $totalsize
  printf "${BLUE}Total backup size (compressed)  :  ${NORMAL}%6.2f MB (%d bytes)\n\n" $totalcompressedsizemb $totalcompressedsize
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
    echo "${RED}Invalid or not found ${YELLOW}$TARGET${NORMAL}" > /tmp/backup_status
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
  echo "${RED}Invalid device ${YELLOW}$DEVICE${NORMAL}" > /tmp/backup_status
  wrapup
fi

if [ $MOUNTED == "no" ]; then
   sudo /bin/mount $MOUNTPOINT
   if [ "$?" != 0 ]; then
      echo "${RED}Unable to mount device ${YELLOW}$DEVICE${NORMAL}" > /tmp/backup_status
      wrapup
   fi
fi

echo "${D2#/dev/}"/$FULLPATH > /etc/sysconfig/backup_device

trap failed SIGTERM

if [ "$BACKUP" ] ; then
  # Use a dummy file to save .filetool.lst's timestamp, so we can restore it after sed changes it
  dummy=$(mktemp); touch -r /opt/.filetool.lst $dummy
  sed -i /^$/d /opt/.filetool.lst
  touch -r $dummy /opt/.filetool.lst; rm $dummy
  if [ "$SAFE" ]; then
    if [ -r $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz.bfe -o -r $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz ]; then                     
      echo -n "${BLUE}Copying existing backup to ${YELLOW}$MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.[tgz|tgz.bfe]${BLUE} .. "  
      sudo /bin/mv -f $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.tgz 2>/dev/null || sudo /bin/mv -f $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz.bfe $MOUNTPOINT/"$FULLPATH"/${MYDATA}bk.tgz.bfe 2>/dev/null
      if [ "$?" == 0 ]; then
        echo "${GREEN}Done.${NORMAL}"
      else
        echo -e "\n${RED}Error: Unable to rename ${YELLOW}${MYDATA}.tgz ${RED}to ${YELLOW}${MYDATA}bk.tgz${NORMAL}"
        exit 2
      fi
    else                                                                                                                      
      echo "${MAGENTA}Neither ${YELLOW}${MYDATA}.tgz${MAGENTA} nor ${YELLOW}${MYDATA}.tgz.bfe${MAGENTA} exist. ${BLUE}Proceeding with creation of initial backup ...${NORMAL}"
    fi
  fi
  if [ "$VERBOSE" ]; then
    sudo /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst  -czvf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz
    [ "$PROMPT" ] && echo -n "Press enter to continue:" &&  read ans
  else
    echo -n "${BLUE}Backing up files to ${YELLOW}$MOUNTPOINT/$FULLPATH/${MYDATA}.tgz ${BLUE}"
    [ -f /tmp/backup_status ] && sudo /bin/rm -f /tmp/backup_status
    sudo /bin/tar -C / -T /opt/.filetool.lst -X /opt/.xfiletool.lst -czf "$MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz" 2>/tmp/backup_status &
    rotdash $!
    sync
    [ -s /tmp/backup_status ] && sed -i '/socket ignored/d' /tmp/backup_status 2>/dev/null
    [ -s /tmp/backup_status ] && { echo -e "\n${RED}There was an issue, see ${YELLOW}/tmp/backup_status${RED}.${NORMAL}"; exit 1; }
    touch /tmp/backup_done
  fi
  if [ -f /etc/sysconfig/bfe ]; then
     echo -n "${BLUE}encrypting .. ${NORMAL} "
     blowfish_encrypt ${MYDATA}.tgz
  fi
  echo  "${GREEN}Done.${NORMAL}"
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
       echo -n "${BLUE}Restoring backup files from encrypted backup ${YELLOW}$MOUNTPOINT/$FULLPATH ${BLUE}mounted over device ${YELLOW}$D2 ${NORMAL}"
cat << EOD | sudo /usr/bin/bcrypt -o "$MOUNTPOINT"/"$FULLPATH"/$TARGETFILE 2>/dev/null | sudo /bin/tar  -C / -zxf -
"$KEY"
EOD
       if [ "$?" != 0 ]; then failed; fi
       echo "${GREEN}Done.${NORMAL}"
     fi
     clean_up 0
  else
     if [ -f /etc/sysconfig/bfe ]; then
        echo
        echo "${MAGENTA}Warning PROTECT boot code used and encrypted backup file not found!"
        echo "Proceeding with normal restore operations."
        echo "Encryption will occur upon next backup or shutdown.${NORMAL}"
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
    echo -n "${BLUE}Restoring backup files from ${YELLOW}$MOUNTPOINT/$FULLPATH/${MYDATA}.tgz${NORMAL} "
    sudo /bin/tar -C / -zxf $MOUNTPOINT/"$FULLPATH"/${MYDATA}.tgz 2>/dev/null &
    rotdash $!
    echo "${GREEN}Done.${NORMAL}"
  fi
  clean_up 0
fi
echo "${RED}Required action flag is missing:${YELLOW} $1 ${NORMAL}"
abort
