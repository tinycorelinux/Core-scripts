#!/bin/sh
NOAUTOLOGIN=/etc/sysconfig/noautologin
if [ -f "$NOAUTOLOGIN" ]; then
	if [ -s "$NOAUTOLOGIN" ]; then
		> "$NOAUTOLOGIN"
		exit
	fi
else
	if [ ! -f /etc/sysconfig/superuser ]; then 
		clear
		TCUSER="$(cat /etc/sysconfig/tcuser)"
		exec /bin/login -f "$TCUSER"
	fi
fi
