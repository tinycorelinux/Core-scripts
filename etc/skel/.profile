# ~/.profile: Executed by Bourne-compatible login SHells.
#
# Path to personal scripts and executables (~/.local/bin).
[ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin"
export PATH=$HOME/.local/bin:$PATH

ONDEMAND=/etc/sysconfig/tcedir/ondemand
[ -d "$ONDEMAND" ] && export PATH=$PATH:"$ONDEMAND"

# Environment variables and prompt for Ash SHell
# or Bash. Default is a classic prompt.
#
PS1='\u@\h:\w\$ '
PAGER='less -EM'
MANPAGER='less -isR'

EDITOR=vi

export PS1 PAGER FILEMGR EDITOR MANPAGER

export BACKUP=1
[ "`id -un`" = "`cat /etc/sysconfig/tcuser`" ] && echo "$BACKUP" | sudo tee /etc/sysconfig/backup >/dev/null 2>&1
export FLWM_TITLEBAR_COLOR="58:7D:AA"

if [ -f "$HOME/.ashrc" ]; then
	export ENV="$HOME/.ashrc"
	. "$HOME/.ashrc"
fi

read USER < /etc/sysconfig/tcuser
USERID=$(id -u "$USER")
XDG_RUNTIME_DIR="/run/user/$USERID"

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
	sudo mkdir -p "$XDG_RUNTIME_DIR"
	sudo chown "$USER":staff "$XDG_RUNTIME_DIR"
	sudo chmod 700 "$XDG_RUNTIME_DIR"
fi
export XDG_RUNTIME_DIR

TERMTYPE=`/usr/bin/tty`
[ ${TERMTYPE:5:3} == "tty" ] && (
[ ! -f /etc/sysconfig/Xserver ] ||
[ -f /etc/sysconfig/text ] ||
[ -e /tmp/.X11-unix/X0 ] || 
startx
)
