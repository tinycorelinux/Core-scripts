#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
cd /tmp
SEARCH="NAME"
if [ "$1" == "-t" ]; then
	SEARCH="TAGS"
	shift
fi
# Now $* is the search targets 
[ -z "$1" ] && exit 1

if [ ! -f tags.db ]; then
	tce-fetch.sh tags.db.gz || exit 1
	gunzip -f tags.db.gz
	touch tags.db
else # Check if the file is older than 5 hours
	age=$((`date +%s` - `date -r tags.db +%s`))
	if [ $age -ge 18000 ]; then
		tce-fetch.sh tags.db.gz || exit 1
		gunzip -f tags.db.gz
		touch tags.db
	fi
fi

if [ "$SEARCH" == "NAME" ]; then
	grep -i ^$1 tags.db | cut -f1
else
	I=1
	IN="tags.db"
	OUT=`mktemp`
	RESULTS="tags.lst"
	while [ -n "$1" ]
	do
		if [ "$I" == 1 ]
		then
			grep -i "$1" "$IN" > "$OUT"
		else
			grep -i "$1" "$RESULTS" > "$OUT"
		fi
		cp "$OUT" "$RESULTS"
		shift
		I=`expr "$I" + 1`
	done
	rm "$OUT"
	cat "$RESULTS" | awk '{print $1}'
#	cat "$RESULTS"
fi
