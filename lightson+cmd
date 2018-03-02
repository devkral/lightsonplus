#!/usr/bin/env bash

#copyright devkral at web de
# This script is licensed under GNU GPL version 2.0 or above

# Description: extension to lightson+

#realdisp
realdisp=`echo "$DISPLAY" | cut -d. -f1`
inhibitfile="/tmp/lightsoninhibit-$UID-$realdisp"

inhibit() {
	[ ! -e "$inhibitfile" ] && (touch "$inhibitfile" && echo "inhibit screensaver" | wall) || echo "screensaver is already inhibited"
}
uninhibit() {
	[ -e "$inhibitfile" ] && (rm "$inhibitfile" && echo "uninhibit screensaver" | wall) || echo "screensaver is already uninhibited"
}

case $1 in
	"" )
		[ -f $inhibitfile ] && uninhibit || inhibit;;
	"on" | "true" | "yes" )
		inhibit;;
	"off" | "false" | "no" )
		uninhibit;;
	"status" )
		[ -e $inhibitfile ] && echo "screensaver is inhibited" || echo "screensaver is uninhibited";;
	* )
		echo -e "usage: $0 [command]\non: inhibits\noff: uninhibits\nstatus: print status\nnothing: switches";;
esac
