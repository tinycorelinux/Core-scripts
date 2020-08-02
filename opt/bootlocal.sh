#!/bin/sh

# To start serial terminal /w console
# Add the following to the cmdline.txt console=serial0,115200
# Reference https://www.raspberrypi.org/documentation/configuration/uart.md for UART configuration
# Uncomment the next line
# /usr/sbin/startserialtty &

# Set CPU frequency governor to ondemand (default is performance)
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Load modules - i2c-dev needs manually loaded even if enabled in config.txt
#/sbin/modprobe i2c-dev

# Start openssh daemon
/usr/local/etc/init.d/openssh start

# ------ Put other system startup commands below this line
