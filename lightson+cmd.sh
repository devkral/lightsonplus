#!/usr/bin/env bash

#copyright devkral at web de
# This script is licensed under GNU GPL version 2.0 or above

# Description: extension to lightson+

#realdisp
realdisp="$(echo "$DISPLAY" | sed -e "s/\.[0-9]*$//" )"
inhibitfile="/tmp/lightsoninhibit-$UID-$realdisp"

inhibit()
{
	if [ ! -e "$inhibitfile" ]; then
    touch "$inhibitfile"
	  echo "inhibit screensaver" | wall
  else
    echo "screensaver is already inhibited"
  fi
}
uninhibit()
{
	if [ -e "$inhibitfile" ]; then
    rm "$inhibitfile"
	  echo "uninhibit screensaver" | wall
  else
    echo "screensaver is already uninhibited"
  fi
}

status()
{
	if [ -e "$inhibitfile" ]; then
	  echo "screensaver is inhibited"
  else
    echo "screensaver is uninhibited"
  fi
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
elif [ "$1" = "on" ] || [ "$1" = "true" ] || [ "$1" = "yes" ]; then
	inhibit
elif [ "$1" = "off" ] || [ "$1" = "false" ] || [ "$1" = "no" ]; then
	uninhibit
elif [ "$1" = "status" ]; then
	status
else
	echo -e "usage: $0 [command]\non: inhibits\noff: uninhibits\nstatus: print status\nnothing: switches"
fi
