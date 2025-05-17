#!/bin/busybox ash
. /etc/init.d/tc-functions
useBusybox

VERSION="Version 0.3 Nov 25, 2024"

# *****
# Environmental variable PROVIDESUPDATE can override MMIN.
# Add  export PROVIDESUPDATE=+N  to .profile file.
# log out, log in.
# N must be an integer.
# Set to -0 to block updates.
# Set to +0 for frequent updates.
# Set to +N where N is the update interval in minutes.
#	Ex.  PROVIDESUPDATE=+1440    for 24 hours.
MMINoverride="$PROVIDESUPDATE"

# Overide busybox awk with GNU awk.
[ -e /usr/local/bin/awk ] && alias awk='/usr/local/bin/awk'

TCEDIR="/etc/sysconfig/tcedir"
DB="provides.db"
LIST="$TCEDIR"/"$DB"

# Search for exact match. 0=No  1=Yes.
Exact=0

# Run zsync on provides.db file. 0=No  1=Yes.
NZ=1

# Maximum age of provides.db in minutes before checking for update.
MMIN=+15

# This will contain the search term.
TARGET=""

# --------------------------------------------------------------- #
# Checks first char is + or -.
# Checks remaining chars are digits.
IsSignedInteger()
{
	local __NUM=$1

	# Must be at least 2 chars long. + or - followed by a digit.
	[ ${#__NUM} -lt 2 ] && echo "" && return

	# Test to make sure first char is a + or -.
	[ ${__NUM:0:1} != "-" ] && [ ${__NUM:0:1} != "+" ] && echo "" && return

	# We know the first char. So deleting all digits should leave that char.
	[ ${__NUM//[0-9]/} != "-" ] && [ ${__NUM//[0-9]/} != "+" ] && echo "" && return

	# Valid signed integer.
	echo "$__NUM"
}
# --------------------------------------------------------------- #

# --------------------------------------------------------------- #
# Parse search term to escape troublesome chars.
SanitizeTarget()
{
	# Remove all backslashes.
	TARGET="${TARGET//\\}"

	# Add \ to any of the found chars.
	for Char in '/' '+' '$' '[' ']' '(' ')' '^'
	do
		TARGET="${TARGET//$Char/\\$Char}"
	done
}
# --------------------------------------------------------------- #

# --------------------------------------------------------------- #
# Remove command line switch __SW from TARGET.
StripTarget()
{
	local __SW=$1
	# Strip out __SW parameter if present.
	# Mingled with other switches (leading and trailing spaces).
	TARGET="${TARGET// $__SW /  }"
	# From beginning of parameters (trailing space only).
	TARGET="${TARGET#$__SW }"
	# From end of parameters (leading space only).
	TARGET="${TARGET% $__SW}"
	# No search term specified (no leading or trailing spacea).
	[ "$TARGET" == "$__SW" ] && TARGET=""
}
# --------------------------------------------------------------- #

# --------------------------------------------------------------- #
UpdateProvidesDB()
{

	# Check if MMINoverride is set and a signed integer.
	MMINoverride=$(IsSignedInteger $MMINoverride)

	# If it's valid, set MMIN.
	[ -n "$MMINoverride" ] && MMIN="$MMINoverride"

	# Check if the provides.db is old enough to warrant a zsync.
	[ -f "$LIST" ] && [ -z "$(find $LIST -mmin $MMIN)" ] && return 0

	# No point in going further if no network connectivity.
	/bin/ping -A -W 1 -c 2 8.8.8.8 2>&1 > /dev/null || return

	getMirror
	cd "$TCEDIR"
	if zsync -i "$LIST" -q "$MIRROR"/"$DB".zsync
	then
		rm -f "$DB".zs-old
	else
		if [ ! -f "$LIST" ]
		then
		  wget -O "$LIST".gz "$MIRROR"/"$DB".gz
		  gunzip "$LIST".gz
		fi
	fi
	chmod g+rw "$DB"
	touch "$DB"
	cd - > /dev/null
}
# --------------------------------------------------------------- #

# --------------------------------------------------------------- #
Usage()
{
	# Suppress help message if stdout is redirected.
	[ ! -t 1 ] && exit 1

	echo "
$VERSION

Find extension(s) that provide a filename.
Filenames in list being searched include full paths, for example:
	usr/local/bin/grep

Usage:
   ${0##*/} [ -nz ] FileName

   -nz    Skip updating (zsync) the provides.db file. This speeds up
          the search, but might miss items if provides.db is outdated.

Examples:
   ${0##*/} cal           Finds cal anywhere in FileName
   ${0##*/} bin/cal       Finds bin/cal anywhere in FileName
   ${0##*/} bin/cal$      Finds FileName that ends in bin/cal
   ${0##*/} Black Gnome   Finds FileName with embedded spaces

Searches are case sensitive.
The $ sign can only be used at the end of your search term.
"
	exit
}
# --------------------------------------------------------------- #

TARGET=$@
SanitizeTarget

# Read parameters.
for ARG in $TARGET
do
	case "$ARG" in
		-h|-help|--help) Usage;;
		-nz) NZ=0;;
	        *) continue;;
	esac
done

# Remove all command line switches from search term.
for OPT in "-nz"
do
	StripTarget "$OPT"
	StripTarget "$OPT"
done

# Strip any remaining leading and trailing spaces.
TARGET="$(echo $TARGET)"

# Run zsync on the provides.db file if NZ equals 1.
[ $NZ -eq 1 ] && UpdateProvidesDB

# Save string length of TARGET.
Length=${#TARGET}

# Remove trailing \$ (exact match request) if present.
TARGET="${TARGET%\\\$}"

# If TARGET is shorter, exact match was requested.
[ ${#TARGET} -lt $Length ] && Exact=1

# Test if search term is missing.
[ -z "$TARGET" ] && Usage

if [ $Exact -eq 0 ]
then
	awk 'BEGIN {FS="\n";RS=""} /'"${TARGET}"'/{print $1}' "$LIST"
else
	awk 'BEGIN {FS="\n";RS=""} /'"${TARGET}"'\n/||/'"${TARGET}"'$/{print $1}' "$LIST"
fi
