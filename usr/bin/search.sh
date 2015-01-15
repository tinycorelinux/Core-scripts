#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox
cd /tmp
SEARCH="NAME"
if [ "$1" == "-t" -a "$2" ]; then
	SEARCH="TAGS"
	shift
fi
# Now $* is the search targets 
[ -z "$1" ] && exit 1

fetchtags() {
	tce-fetch.sh tags.db.gz || exit 1
	gunzip -f tags.db.gz
	touch tags.db
}

if [ ! -f tags.db ]; then
	fetchtags
else # Check if the file is older than 5 hours
	age=$((`date +%s` - `date -r tags.db +%s`))
	if [ $age -ge 18000 ]; then
		fetchtags
	fi
fi

if [ "$SEARCH" == "NAME" ]; then
	awk -v word="$1" '
	BEGIN {IGNORECASE=1;}
	{name=$1; sub(/\.\w+$/, "", name); if (name ~ word) print $1;}
	' tags.db
else
	words="$@"
	awk '
	BEGIN {IGNORECASE=1; split("'"$words"'", ws);}
	{	ok=1
		line=$0
		sub(/\.\w+\s/, " ", line)
		for (i in ws) {
			if (line !~ ws[i]) {
				ok=0
				break
			}
		}
		if (ok) print $1
	}' tags.db
fi
