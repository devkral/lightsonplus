#!/usr/bin/env bash
# lightson+.sh


# Copyright (c) 2014 devkral at web de
# url: https://github.com/devkral/lightson+

#basing on
# Copyright (c) 2011 iye.cba at gmail com
# url: https://github.com/iye/lightsOn
# This script is licensed under GNU GPL version 2.0 or above

# Description: Bash script that prevents the screensaver and display power
# management (DPMS) to be activated when you are watching Flash Videos
# fullscreen on Firefox and Chromium.
# Can detect mplayer and VLC when they are fullscreen too but I have disabled
# this by default.
# lightsOn.sh needs xscreensaver, kscreensaver or gnome-screensaver to work.

# HOW TO USE: Start the script with the number of seconds you want the checks
# for fullscreen to be done. Example:
# "./lightson+.sh 120 &" will Check every 120 seconds if Mplayer,
# VLC, Firefox or Chromium are fullscreen and delay screensaver and Power Management if so.
# You want the number of seconds to be ~10 seconds less than the time it takes
# your screensaver or Power Management to activate.
# If you don't pass an argument, the checks are done every 50 seconds.


# Modify these variables if you want this script to detect if Mplayer,
# VLC or Firefox Flash Video are Fullscreen and disable
# xscreensaver/kscreensaver/gnome-screensaver and PowerManagement.
mplayer_detection=0
vlc_detection=1
totem_detection=1
firefox_flash_detection=1
chromium_flash_detection=1
webkit_flash_detection=1 #untested
html5_detection=1 #checks if the browser window is fullscreen; will disable the screensaver if the browser window is in fullscreen so it doesn't work correctly if you always use the browser (Firefox or Chromium) in fullscreen
steam_detection=0 #untested
minitube_detection=0  #untested

defaultdelay=50

#realdisp
realdisp="$(echo "$DISPLAY" | sed -e "s/\.[0-9]*$//" )"



inhibitfile="/tmp/lightsoninhibit-$UID-$realdisp"
pidfile="/tmp/lightson-$UID-$realdisp.pid"

# YOU SHOULD NOT NEED TO MODIFY ANYTHING BELOW THIS LINE


# pidlocking
pidcreate()
{
#just one instance can run simultanous
if [ ! -e "$pidfile" ]; then
  echo "$$" > "$pidfile"
else
  if [ -d "/proc/$(cat "$pidfile")" ]; then
    echo "an other instance is running, abort!" >&2
    exit 1;
  else
    echo "$$" > "$pidfile"
  fi
fi
}

pidremove()
{
if [ ! -e "$pidfile" ]; then
  echo "error: missing pidfile" >&2
elif [ ! -f "$pidfile" ]; then
  echo -e "error: \"$pidfile\" is not a file\n" >&2
else
  if [ "$(cat "$pidfile")" != "$$" ]; then
    echo "an other instance is running, abort!" >&2
    exit 1
  else
    rm "$pidfile"
  fi
fi
exit 0
}


pidcreate
trap "pidremove" EXIT





# enumerate all the attached screens
displays=""
while read id
do
    displays="$displays $id"
done< <(xvinfo | sed -n 's/^screen #\([0-9]\+\)$/\1/p')


# Detect screensaver been used (xscreensaver, kscreensaver, gnome-screensaver or none)
#pgrep cuts off last character
if [ `pgrep -lc xscreensave` -ge 1 ];then
    screensaver="xscreensaver"
elif [ `pgrep -lc gnome-screensave` -ge 1 ] || [ `pgrep -lc gnome-shel` -ge 1 ] ;then
    screensaver="gnome-screensaver"
elif [ `pgrep -lc kscreensave` -ge 1 ];then
    screensaver="kscreensaver"
elif [ `pgrep -lc xautoloc` -ge 1 ]; then 
    screensaver="xautolock"
else
    screensaver=""
    echo "No screensaver detected"     
fi


checkFullscreen()
{
    # loop through every display looking for a fullscreen window
    for display in $displays
    do
        #get id of active window and clean output
        activ_win_id=`DISPLAY=$realdisp.${display} xprop -root _NET_ACTIVE_WINDOW`
        activ_win_id=${activ_win_id##*# }
				activ_win_id=${activ_win_id:0:9} #eliminate potentially trailing spaces

				top_win_id=`DISPLAY=$realdisp.${display} xprop -root _NET_CLIENT_LIST_STACKING`
        top_win_id=${activ_win_id##*, }
				top_win_id=${top_win_id:0:9} #eliminate potentially trailing spaces


        # Check if Active Window (the foremost window) is in fullscreen state
        if [ ${#activ_win_id} -eq 9 ]; then
            isActivWinFullscreen=`DISPLAY=$realdisp.${display} xprop -id $activ_win_id | grep _NET_WM_STATE_FULLSCREEN`
        else
            isActiveWinFullscreen=""
        fi
        if [ ${#top_win_id} -eq 9 ]; then
            isTopWinFullscreen=`DISPLAY=$realdisp.${display} xprop -id $top_win_id | grep _NET_WM_STATE_FULLSCREEN`
        else
            isTopWinFullscreen=""
        fi
            if [[ "$isActivWinFullscreen" = *NET_WM_STATE_FULLSCREEN* ]] || [[ "$isTopWinFullscreen" = *NET_WM_STATE_FULLSCREEN* ]];then
                isAppRunning
                var=$?
                if [[ $var -eq 1 ]];then
                    delayScreensaver
                fi
            fi
    done
}



    

# check if active windows is mplayer, vlc or firefox
#TODO only window name in the variable activ_win_id, not whole line. 
#Then change IFs to detect more specifically the apps "<vlc>" and if process name exist

isAppRunning()
{    
    #Get title of active window
    activ_win_title=`xprop -id $activ_win_id | grep "WM_CLASS(STRING)"`   # I used WM_NAME(STRING) before, WM_CLASS more accurate.



    # Check if user want to detect Video fullscreen on Firefox, modify variable firefox_flash_detection if you dont want Firefox detection
    if [ $firefox_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *unknown* || "$activ_win_title" = *plugin-container* ]];then
        # Check if plugin-container process is running
            #pgrep cuts off last character
            flash_process=`pgrep -lc plugin-containe`
            if [[ $flash_process -ge 1 ]];then
                return 1
            fi
        fi
    fi

    
    # Check if user want to detect Video fullscreen on Chromium, modify variable chromium_flash_detection if you dont want Chromium detection
    if [ $chromium_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *chrom* ]];then   
        # Check if Chromium Flash process is running
            flash_process=`pgrep -lfc "chromium --type=ppapi"`
            if [[ flash_process -ge 1 ]];then
                return 1
            fi
            # Check if Chrome flash is running (by cadejager)
            flash_process=`pgrep -lf "chrome --type=ppapi "`
            if [[ -n $flash_process ]];then
                return 1
            fi
        fi
    fi

    # Check if user want to detect Video fullscreen on WebKit, modify variable webkit_flash_detection if you dont want Webkit detection (by dyskette)
    if [ $webkit_flash_detection == 1 ];then
        if [[ "$activ_win_title" = *WebKitPluginProcess* ]];then
        # Check if WebKit Flash process is running
            flash_process=`pgrep -lfc ".*WebKitPluginProcess.*flashp.*"`
            if [[ $flash_process -ge 1 ]];then
                log "isAppRunning(): webkit flash fullscreen detected"
                return 1
            fi
        fi
    fi

    #html5 (Firefox or Chromium full-screen)
    if [ $html5_detection == 1 ];then
        if [[ "$activ_win_title" = *chromium-browser* || "$activ_win_title" = *Firefox* || "$activ_win_title" = *epiphany* || "$activ_win_title" = *opera* ]];then   
            #check if firefox or chromium is running.
            if [[ `pgrep -lc firefox` -ge 1 || `pgrep -lc chromium-browser` -ge 1  || `pgrep -lc opera` -ge 1 || `pgrep -lc epiphany` -ge 1 ]]; then
                return 1
            fi
        fi
    fi

    
    #check if user want to detect mplayer fullscreen, modify variable mplayer_detection
    if [ $mplayer_detection == 1 ];then  
        if [[ "$activ_win_title" = *mplayer* || "$activ_win_title" = *MPlayer* ]];then
            #check if mplayer is running.
            #mplayer_process=`pgrep -l mplayer | grep -wc mplayer`
            mplayer_process=`pgrep -lc mplayer`
            if [ $mplayer_process -ge 1 ]; then
                return 1
            fi
        fi
    fi
    
    
    # Check if user want to detect vlc fullscreen, modify variable vlc_detection
    if [ $vlc_detection == 1 ];then  
        if [[ "$activ_win_title" = *vlc* ]];then
            #check if vlc is running.
            #vlc_process=`pgrep -l vlc | grep -wc vlc`
            vlc_process=`pgrep -lc vlc`
            if [ $vlc_process -ge 1 ]; then
                return 1
            fi
        fi
    fi
    # Check if user want to detect totem fullscreen, modify variable totem_detection (by lancelotsix)
    if [ $totem_detection == 1 ];then
        if [[ "$activ_win_title" = *totem* ]];then
            #check if totem is running.
            totem_process=`pgrep -lc totem`
            if [ $totem_process -ge 1 ]; then
                return 1
            fi
        fi
    fi
    if [ $steam_detection == 1 ];then
        if [[ "$activ_win_title" = *steam* ]];then
            #check if totem is running.
            totem_process=`pgrep -lc steam`
            if [ $totem_process -ge 1 ]; then
                return 1
            fi
        fi
    fi
    # Check if user want to detect minitube fullscreen, modify variable minitube_detection (by dyskette)
    if [ $minitube_detection == 1 ];then
        if [[ "$activ_win_title" = *minitube* ]];then
            #check if minitube is running.
            #minitube_process=`pgrep -l minitube | grep -wc minitube`
            minitube_process=`pgrep -lc minitube`
            if [ $minitube_process -ge 1 ]; then
                log "isAppRunning(): minitube fullscreen detected"
                return 1
            fi
        fi
    fi

return 0
}


delayScreensaver()
{

    # reset inactivity time counter so screensaver is not started
    if [ "$screensaver" == "xscreensaver" ]; then
   #This tells xscreensaver to pretend that there has just been user activity. This means that if the screensaver is active (the screen is blanked), then this command will cause the screen to un-blank as if there had been keyboard or mouse activity. If the screen is locked, then the password dialog will pop up first, as usual. If the screen is not blanked, then this simulated user activity will re-start the countdown (so, issuing the -deactivate command periodically is one way to prevent the screen from blanking.)
        xscreensaver-command -deactivate > /dev/null
    elif [ "$screensaver" == "gnome-screensaver" ]; then
        #new way, first try
        dbus-send --session --dest=org.freedesktop.ScreenSaver --reply-timeout=2000 --type=method_call /ScreenSaver org.freedesktop.ScreenSaver.SimulateUserActivity > /dev/null
        #old way second try
        dbus-send --session --type=method_call --dest=org.gnome.ScreenSaver --reply-timeout=20000 /org/gnome/ScreenSaver org.gnome.ScreenSaver.SimulateUserActivity > /dev/null
    elif [ "$screensaver" == "kscreensaver" ]; then
        qdbus org.freedesktop.ScreenSaver /ScreenSaver SimulateUserActivity > /dev/null
    elif [ "$screensaver" == "xautolock" ]; then  #by cadejage
        xautolock -disable
        xautolock -enable
    fi


    #Check if DPMS is on. If it is, deactivate and reactivate again. If it is not, do nothing.    
    dpmsStatus=`xset -q | grep -ce 'DPMS is Enabled'`
    if [ $dpmsStatus == 1 ];then
        xset -dpms
        xset dpms
    fi
}



delay=$1


# If argument empty, use 50 seconds as default.
if [ -z "$1" ];then
    delay=$defaultdelay
fi


# If argument is not integer quit.
if [[ $1 = *[^0-9]* ]]; then
    echo "The Argument \"$1\" is not valid, not an integer"
    echo "Please use the time in seconds you want the checks to repeat."
    echo "You want it to be ~10 seconds less than the time it takes your screensaver or DPMS to activate"
    exit 1
fi

echo "start lightsOn mainloop"
while true
do
    if [ ! -f "$inhibitfile" ]; then
      checkFullscreen
    else
      delayScreensaver
    fi
    sleep $delay
done


exit 0    

