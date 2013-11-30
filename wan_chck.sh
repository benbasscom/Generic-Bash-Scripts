#!/bin/bash
# Checks the WAN IP.
vers="wan_chck-0.1"
# reads the previous WAN IP from file, then compares to current WAN IP.
# if the wan_chck_ip.log does not exist, create it.
# logs everything to files.

log="/Library/Logs/com.example/wan_chck.log"
err_log="/Library/Logs/com.example/wan_chck-err.log"
exec 1>> "${log}" 
exec 2>> "${err_log}"

when=$(date '+%m/%d/%Y %H:%M')

wan_ip="$(curl -s www.icanhazip.com | awk '{print $1}')"
prev_wan_ip="$(tail -1 /Library/Logs/com.example/wan_chck_ip.log)"

if [[ ! -f /Library/Logs/com.trmacs/wan_chck_ip.log ]]; then
		echo "WAN IP log does not exist, creating."
		mkdir -p /Library/Logs/com.example/
		echo $wan_ip >> /Library/Logs/com.example/wan_chck_ip.log
fi


if [[ $wan_ip == $prev_wan_ip ]]; then
	echo "WAN IP has not changed, exiting."
	echo $wan_ip >> /Library/Logs/com.example/wan_chck_ip.log
else
	echo "WAN IP has changed, now do something"
	echo $wan_ip >> /Library/Logs/com.example/wan_chck_ip.log
fi
exit 0