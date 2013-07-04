#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
# put user shutdown commands here

# If no backup of home was done then loop through valid users to clean up.
if [ ! -e /tmp/backup_done ] || ! grep -q "^home" /opt/.filetool.lst; then
  awk 'BEGIN { FS=":" }  $3 >= 1000 && $1 != "nobody" { print $1 }' /etc/passwd > /tmp/users
  while read U; do
    while read F; do
      TARGET="/home/${U}/$F"
      if [ -d "$TARGET" ]; then
        rm -rf "$TARGET"
      else
        if [ -f "$TARGET" ]; then
          rm -f "$TARGET"
        fi
      fi
    done < /opt/.xfiletool.lst      
  done < /tmp/users 
fi
