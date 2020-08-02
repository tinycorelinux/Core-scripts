                               Introduction
                               ============

piCore is the Raspberry Pi port of Tiny Core Linux, which is an
independent system architected by Robert Shingledecker and now
developed by a small team of developers with strong community support.

Tiny Core Linux is not a traditional distribution but a toolkit to
create your own customized system. It offers not only flexibility,
small footprint but a very recent kernel and set of applications making
it ideal for custom system, appliances as well as to learn Linux
specially on the Raspberry Pi.


Concept
=======

piCore is running entirely in RAM. Boot media is not used after boot
and there is no installation in conventional terms.

Default operational mode is Cloud (Internet) Mode. Extensions
(applications) are downloaded from the repository via Internet. File
system is in RAM, extensions are mounted to the file system read-only.
Changes are not saved over reboots, you get always the same clean
system after boot.

In Mounted Mode, which requires a persistent storage, there is a second
LINUX partition where downloaded extensions are stored on the SD card and
available during next boot, but changes not saved automatically, it is
done manually or by a script, it can be configured what is backed up.
Backed up files are restored automatically by the system.

It is also possible to use partitions as persistent storage for /home 
or /var but in most cases Mounted Mode is used.

For details on concept read

http://tinycorelinux.net/concepts.html


Installation
============

piCore is distributed in a .zip archive containing raw SD card image 
which can be installed with dd command on Linux or Win32 Disk Imager on 
Windows. After successfully copying image to SD card it is ready to boot 
in Raspberry Pi. While it works offline, advised to have a wired 
Internet connections to have proper system time, to install packages or 
for remote SSH access for headless systems.


After the first run
===================

Execute 'filetool.sh -b' shell command after the first boot to save 
generated unique SSH keys which will be used during next boots. It will
speed up boot and eliminate to bother new keys in SSH client.


SD card partitioning
====================

First partition, mmcblk0p1 is VFAT type; it contains the basic piCore 
system and the Raspberry Pi boot loader, firmware and other support 
files. Partition is unmounted during operation, system is not using it 
after boot and never writes.

Second partition, mmcblk0p2 is a Linux ext4 partion which contains 
preinstalled extensions, openssh and mc (Midnight Commander) and 
configuration files. It is a small partion with no free space, you must 
expand its size to have enough room for additional extensions, updates
and  backups. It can be done on the running system locally or remote
via SSH following these steps:

1) Start fdisk partitioning tool as root:

   sudo fdisk -u /dev/mmcblk0

   Now list partitions with 'p' command and write down the starting and
   ending sectors of the second partition.

2) Delete second partition with 'd' than recreate it with 'n' command.
   Use the same starting sector as deleted had and provide end
   sectore or size greater than deleted had having enough free space
   for Mounted Mode. When finished, exit fdisk with 'w' command. Now
   partition size increased but file system size is not yet changed.

3) Reboot piCore. It is necessary to make Kernel aware of changes.

4) After reboot expand file system to the new partition boundaries with 
   typing the following command as root:

   resize2fs /dev/mmcblk0p2

Now you are ready to use the bigger partition.


Swap
----

By default piCore has a gzip compressed swap in RAM, automatically 
sized to 25% of available RAM. This can be disabled with the NOZSWAP
boot code.

Create a swap partition with fdisk if you need more swap or not using 
ZSWAP (do not forget to format with mkswap command). Size depends on 
applications you are running, compilation of large programs may require 
more than 1 Gbyte swap, while for everyday use 512k may be enough.

While swap file can be used, we encourage use of swap partition for 
performance.

Note: You can use other tools, e.g. gparted on third-party Linux
      systems to make necessary changes.


Boot codes
==========

Additionally to the common Linux boot codes there are many Tiny Core 
Linux (piCore) specific options. See

http://tinycorelinux.net/faq.html#bootcodes

for list. Boot codes are specified in the /mnt/mmcblk0p1/cmdline.txt 
file.


Login, passwords
================

Default user is tc. There are no user passwords, tc user is auto logged 
in on the terminal. In case of piCore-x.y password for tc user is

piCore

It is not possible to log in as root.


Support
=======

piCore is community supported. Use the Raspberry Pi section of the Tiny 
Core Linux Forums:

http://forum.tinycorelinux.net/index.php/board,57.0.html

You can find many useful information in other sections also, related to 
Tiny Core Linux operation and use in general. 


Core Book
=========

Also, strongly advised to read the Core book, "Into the Core":

http://tinycorelinux.net/book.html

It is about the x86 version in details, but generic parts, like 
concept, tools, etc. valid for other ports, like piCore.

Enjoy!

Bela Markus (bmarkus)

