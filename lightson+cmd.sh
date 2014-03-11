#!/usr/bin/env bash

#copyright devkral at web.de
# This script is licensed under GNU GPL version 2.0 or above

# Description: extension to lightsOn

#realdisp
realdisp="$(echo "$DISPLAY" | sed -e "s/\.[0-9]*$//" )"
inhibitfile="/tmp/lightsoninhibit-$UID-$realdisp"

inhibit()
{
	touch "$inhibitfile"
	echo "inhibited screensaver" | wall
}
uninhibit()
{
	rm "$inhibitfile"
	echo "uninhibited screensaver" | wall
}

switch()
{
	if [ -f "$inhibitfile" ]; then
		uninhibit
	else
		inhibit
	fi
}

if [ "$1" = "" ]; then
	switch
elif [ "$1" = "on"|"true"|"yes" ]; then
	inhibit
elif [ "$1" = "off"|"false"|"no" ]; then
	uninhibit
else
	echo "usage: $0 [command]\non: inhibits\noff: uninhibits,nothing: switches"
fi
