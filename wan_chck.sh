#!/bin/bash
# Checks the WAN IP.
vers="wan_chck-0.3"
# reads the previous WAN IP from file, then compares to current WAN IP.
# if the wan_chck_ip.log does not exist, create it.
# logs everything to files.


#check for logging directory.  If it does exist, continue, else create it.
if [ -d /Library/Logs/com.example/ ]; then
	echo "log directoy exists, continuing"
	else
	echo "Log directory does not exist, creating."
	mkdir /Library/Logs/com.example/
fi


log="/Library/Logs/com.example/wan_chck.log"
err_log="/Library/Logs/com.example/wan_chck-err.log"
exec 1>> "${log}" 
exec 2>> "${err_log}"

when=$(date '+%m/%d/%Y %H:%M')
wan_ip="$(curl -s www.icanhazip.com | awk '{print $1}')"
prev_wan_ip="$(tail -1 /Library/Logs/com.example/wan_chck_ip.log)"

if [[ $wan_ip == $prev_wan_ip ]]; then
	echo "WAN IP has not changed, exiting."
	echo $wan_ip >> /Library/Logs/com.example/wan_chck_ip.log
else
	echo "WAN IP has changed, now do something"
	echo "The new external IP address is now "$win_ip" | mail -s "E-mail Subject" "e-mail recipient"
	echo $wan_ip >> /Library/Logs/com.example/wan_chck_ip.log
fi

echo $wan_ip >> /Library/Logs/com.example/wan_chck_ip.log
exit 0