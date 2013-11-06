#!/bin/bash
# Geek tool script
# Created by Ben Bass
# Geek tool Version 0.6.5
# Copyright 2012 Technology Revealed. All rights reserved.
# requires the airport command to be linked.
# Piecing together some geek tools to not just be one long bash command, but a real script.
# Removed nested IF/Then statements and replaced with the 'format' function from "yet_another_uptime" geeklet.
# Changed Load/Top/CPU to call top once instead of 3 times.
# If using on 10.6 and earlier, change Wi-Fi to Airport in the SSID checks.


# Setting variables.
host_raw="$(scutil --get HostName)"

if [ -z "$host_raw" ]; then
	host_name="$(scutil --get ComputerName)"
else	
	host_name="$host_raw"
fi

# HOST=$(system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print $3}')
EXTERNALIP=$(curl -s www.icanhazip.com | awk '{print $1}')
AIRPORTIP=$(ifconfig en1 | GREP inet | awk '{print$2}')
SSID=$(networksetup -getairportnetwork en1)
SSID_chk=$(echo $SSID | grep "You are not associated with an AirPort network. Wi-Fi power is currently off.")
SSID_false="You are not associated with an AirPort network. Wi-Fi power is currently off."
TXRATE=$(airport -I | grep lastTxRate | awk '{print $2}')
ETHERNET=$(ifconfig en0 | GREP "inet " | awk '{print $2}')
PPP0=$(ifconfig ppp0 | GREP "inet " | awk '{print $2}')
utun1=$(ifconfig utun1 | GREP "inet " | awk '{print $2}')
DNS=$(nslookup "$EXTERNALIP"| grep "name =" | awk '{print ""$4}')
top_raw=$(top -l 1)
LOAD=$(echo "$top_raw" | grep 'Load')
CPU=$(echo "$top_raw"  | grep 'CPU usage')
PHYSMEM=$(echo "$top_raw" | grep 'PhysMem')
AC=$(system_profiler SPPowerDataType | grep Connected: | awk  '{print $2}')

# Trying to embed this process for uptime
then=$(sysctl kern.boottime | awk '{print $5}' | sed "s/,//")
now=$(date +%s)
diff=$(($now-$then))

days=$(($diff/86400));
diff=$(($diff-($days*86400)))
hours=$(($diff/3600))
diff=$(($diff-($hours*3600)))
minutes=$(($diff/60))
seconds=$(($diff-($minutes*60)))

function format {
	if [ "$1" == "1" ]; then
		echo "$1" " " "$2"
	else
		echo "$1" " " "$2""s"
	fi
}

# Displaying the information
echo "Host Name: "$host_name""

if [ -n "$AIRPORTIP"  ]; then
	echo "Airport IP Address: "$AIRPORTIP""
fi
if [ "$SSID_chk" != "$SSID_false" ]; then
	echo ""$SSID""
	echo "Airport Link Speed: $TXRATE Mbit/s"
fi
if [ -n "$ETHERNETIP" ]; then
	echo "Ethernet IP Address: "$ETHERNET""
fi
if [ -n "$PPP0" ]; then
	echo "VPN IP: "$PPP0""
fi	
if [ -n "$utun1" ]; then
	echo "VPN IP: "$utun1""
fi	
if [ -n "$EXTERNALIP" ]; then
	echo "External IP: $EXTERNALIP"
	echo "DNS = $DNS"
fi	
echo " "
echo "Uptime: "`format "$days" "day"` `format "$hours" "hour"` `format "$minutes" "minute"` # `format $seconds "second"`
echo "$LOAD"
echo "$CPU"
echo "$PHYSMEM"
echo "A/C Adapter Connected: ${AC}"
echo " "
date
exit 0