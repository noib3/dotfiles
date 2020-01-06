#!/bin/sh
#
# ufetch-macos - tiny system info for macos

## INFO

# user is already defined
host="$(hostname)"
os="$(sw_vers -productName) $(sw_vers -productVersion)"
kernel="$(uname -sr)"
uptime="$(uptime | awk -F, '{sub(".*up ",x,$1);print $1}' | sed -e 's/^[ \t]*//')"
shell="$(basename "$SHELL")"

## PACKAGE MANAGER DETECTION

if [ -x "$(command -v pkgin)" ]; then
	packages="$(pkgin list | wc -l)"
elif [ -x "$(command -v brew)" ]; then
	brew_packages="$(brew list | wc -l)"
	cask_packages="$(brew cask list 2> /dev/null | wc -l)"
	packages="$(( ${brew_packages} + ${cask_packages} ))"
elif [ -x "$(command -v port)" ]; then
	packages="$(port installed | wc -l)"
else
	packages='unknown'
fi

packages="$(echo ${packages} | sed -e 's/^[ /t]*//')"

## UI DEECTION

if [ -n "${DE}" ]; then
	ui="${DE}"
	uitype='DE'
elif [ -n "${WM}" ]; then
	ui="${WM}"
	uitype='WM'
else
	ui='Aqua'
	uitype='UI'
fi

## DEFINE COLORS

# probably don't change these
if [ -x "$(command -v tput)" ]; then
	bold="$(tput bold)"
	black="$(tput setaf 0)"
	red="$(tput setaf 1)"
	green="$(tput setaf 2)"
	yellow="$(tput setaf 3)"
	blue="$(tput setaf 4)"
	magenta="$(tput setaf 5)"
	cyan="$(tput setaf 6)"
	white="$(tput setaf 7)"
	reset="$(tput sgr0)"
fi

# you can change these
lc="${reset}${bold}"                # labels
nc="${reset}${bold}"                # user and hostname
ic="${reset}"                       # info
c0="${reset}"                       # first color

## OUTPUT

cat <<EOF
${c0}          _${reset}
${c0}         (/     ${nc}${USER}${ic}@${nc}${host}${reset}
${c0}    .---__--.   ${lc}OS:        ${ic}${os}${reset}
${c0}   /         \  ${lc}KERNEL:    ${ic}${kernel}${reset}
${c0}  |         /   ${lc}UPTIME:    ${ic}${uptime}${reset}
${c0}  |         \\_  ${lc}PACKAGES:  ${ic}${packages}${reset}
${c0}   \         /  ${lc}SHELL:     ${ic}${shell}${reset}
${c0}    \`._.-._.\`   ${lc}${uitype}:        ${ic}${ui}${reset}

EOF
