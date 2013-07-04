#!/bin/busybox ash
#(c) Robert Shingledecker 2009
# awk script to find and add symlinks for cdrom and dvd devices
# typically called from /etc/udev/rules.d/75-cd-dvd.rules
. /etc/init.d/tc-functions
useBusybox
awk '
BEGIN {
  c=0
  d=0
}
{
  if ( index($0,"drive name:") > 0 )
  {
    if ( NF > 2 )
    {
      for ( i=3; i<= NF; i++ )
      {
        devices[i-2]=$i
        printf "/dev/%s ",$i
      }
    }
  }
  if ( index($0,"Can read DVD:") > 0 )
  {
    if ( NF > 3 )
    {
      for ( j=4; j <= NF; j++ )
      {
        if ( $j == 1)
        {
           d++
           dvds[d]=devices[j-3]
        } else {
           c++
           cdroms[c]=devices[j-3]
        }
      }
    }
  }
} 
END {
  if ( 1 in cdroms )
  {
   system ("ln -sf /dev/"cdroms[1]" /dev/cdrom")
  }
  if ( 1 in dvds )
  {
    system ("ln -sf /dev/"dvds[1]" /dev/dvd")
    if ( 1 in cdroms )
    { } else {
      system ("ln -sf /dev/"dvds[1]" /dev/cdrom")
    }
  }
} ' /proc/sys/dev/cdrom/info > /etc/sysconfig/cdroms
