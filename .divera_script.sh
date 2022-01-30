#!/bin/bash

# set Installationdirectory
BASEFOLDER=~/divera

# set ACCESSKEY
ACCESSKEY="{YOUR ACCESS KEY}"

# set URLS for API v1 and v2
API_URL_ALARM="https://www.divera247.com/api/last-alarm?accesskey=${ACCESSKEY}"
APIV2_URL_AUTH="https://www.divera247.com/api/v2/auth/jwt?accesskey=${ACCESSKEY}"
APIV2_URL_EVENTS="https://www.divera247.com/api/v2/events?accesskey=${ACCESSKEY}"

# set Variables
IS_MONITOR_ACTIVE=true
HAS_ALARM=false

# routes logging
exec > $BASEFOLDER/log.txt
exec 2> $BASEFOLDER/error.txt

# set events file location
EVENT_JSON=$BASEFOLDER/events.json

# includes the divera commands
source $BASEFOLDER/divera_commands.sh

# boot log
echo "Booting up"
date

# test network
while ! ping -c 1 -W 1 divera247.com>/dev/null; do
	echo "Waiting for network to come up and connect to divera"
	sleep 1
done

# Download Events
curl -X GET ${APIV2_URL_AUTH} -H "accept: application/json" | jq -r -j -e '.sucess' > /dev/null && echo "API V2 authorized"
sleep 10
curl -X GET ${APIV2_URL_EVENTS} -H "accept: application/json"  | jq '. | .data.items[] | {title:.title, start:.start, end:.end}' > $EVENT_JSON
echo "Authorized and Events downloaded"
sleep 1

# set weekly duty times to add to JSON
REG_DUTY_TIME="18:00"
REG_DUTY_DAY="Wed"

#add next dutytime to events.json
date --date="$REG_DUTY_TIME next $REG_DUTY_DAY" +%s | jq '[. , .+21600] | {title:"Dienstabend", start:.[0], end:.[1]}' >> $EVENT_JSON

# at boot show the monitor
monitor on

sleep 60

while true; do
    HAS_ALARM=`curl -s ${API_URL} | jq -r -j '.success'`
    
    # get Time and DOW only for restart, plan to fix this
    DOW=$(date +%u) #Monday=1 
    HOUR=$(date +%H)
    MINUTES=$(date +%M)
    
    DUTY_TIME=false
    
    #Parse events.json for active event +-1h
    DUTY_TIME=$(cat $EVENT_JSON | jq '[[.start|.<now+3600],[.end|.>now-3600]] | transpose | .[] | all' |  jq -s -e '. | any')
    
    #case: active mission and monitor off
    if [ $HAS_ALARM = true ] && [ $IS_MONITOR_ACTIVE = false ]; then
        echo "Mission turning display on"
        screen on
        IS_MONITOR_ACTIVE=true
        
    #case: duty time and mission off
    elif [ $DUTY_TIME = true ] && [ $IS_MONITOR_ACTIVE = false ]; then
        echo "Duty turning display on"
        screen on
        IS_MONITOR_ACTIVE=true
        
    #case: no mission and no duty time but monitor on
    elif [ $HAS_ALARM = false ] && [ $DUTY_TIME = false ] && [ $IS_MONITOR_ACTIVE = true ]; then
        echo "Turn display off"
        screen off
        IS_MONITOR_ACTIVE=false
    
    #case: monitor off and no mission and it is night time then make updates
    elif [ $HAS_ALARM = false ] && [ $IS_MONITOR_ACTIVE = false ] && [ $HOUR = 3 ] && [ $MINUTES = 5 ]; then
        echo "Updating and restarting Raspberry"

	#wait a moment that he wont do two updates when he is faster then a minute with update and reboot
        sleep 45

        sudo apt update
        sudo apt --yes --force-yes upgrade
        sudo reboot
    fi
    
    #sleeps 30 seconds and starts again
    sleep 30
done
