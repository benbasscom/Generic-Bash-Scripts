#!/bin/bash
### TITLE: BASH Script To Get Uptime In Hours ###
### Mac OS 10.8.x ###

up_raw=`uptime`
up_type=`echo $up_raw | grep -o up.* | awk '{print $3}' | sed 's/,//g' | sed 's/s//g'`
up_dura=`echo $up_raw | grep -o up.* | awk '{print $2}' | sed 's/,//g'`
if [ $up_type == "day" ]; then
	day_dayToHrs=$(($up_dura*24))
	day_hrsToHrs=`echo $up_raw | grep -o up.* | awk '{print $4}' | cut -c 1,2`
	up_final=$(($day_dayToHrs + $day_hrsToHrs))
elif [ $up_type == "min" ]; then
	up_final="1"
	else up_final=`echo $up_raw | grep -o up.* | awk '{print $2}' | cut -c 1,2`
fi
echo ""; echo "Uptime: $up_final hours"; echo ""