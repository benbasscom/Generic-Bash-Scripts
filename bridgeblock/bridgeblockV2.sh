#!/bin/bash
# bridgeblock.sh
# Updated by Ben Bass on 2016-04-03.
# Version 2.0
# Designed to determine what NIC's are active, and if one specified as Ethernet is active
# disable the one noted as 80211x.
# 1.0 - Initial script.
# 1.1 -	Adding notify aspect and sleep at the bottom.
# 2.0 - Complete rewrite to not use PlistBuddy and do as few system calls as possible


# this causes the script to wait for one notification of "edu.jhuapl.bridgeblock"
# the notification is being sent by the asl extension edu.jhuapl.edu which is looking for
# changes in ip addresses sent via configd.
# Commenting out for testing.
notifyutil -1 edu.jhuapl.bridgeblock


# Get all of the necessary info from the plist into a variable
networkStatus_raw="$(defaults read /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist Interfaces)"
nicType="$(echo "$networkStatus_raw" | grep SCNetworkInterfaceType | awk '{ print $3 }' | sed 's/.$//')"
nicBSD="$(echo "$networkStatus_raw" | grep BSD | awk '{ print $4 }' | sed 's/.$//')"

# Build an array of the NIC types, BSD names and get the count:
# each position will correspond to the same device as the information is contained in all NIC's in the plist.
nicType_array=($(echo $nicType))
nicBSD_array=($(echo $nicBSD))
nicCount=${#nicType_array[*]}

#find wifi BSD, and set it to a variable for ease of powering down.
if [[ ${nicType_array[${i}]} = "IEEE80211" ]]; then
	wifiNIC=${nicBSD_array[${i}]}
fi


# now we go across the arrays and determine which is active and which is not.

for ((i=0;i<$nicCount;i++)); do
	isActive="$(ifconfig ${nicBSD_array[${i}]} 2>/dev/null | grep status | awk '{ print $2 }')"

# only caring about a NIC if it exists, if isActive is not null, then continue.
	if [[ -n "$isActive" ]]; then
		#logging for fun and profit.
		if [[ ${nicType_array[${i}]} = "Ethernet" ]]; then
			echo  "${nicBSD_array[${i}]} is Ethernet and "$isActive""		
		elif [[ ${nicType_array[${i}]} = "IEEE80211" ]]; then
			echo  "${nicBSD_array[${i}]} is WiFi and "$isActive""
		fi

		# ending if wifi is not active.
		if [[ ${nicType_array[${i}]} = "IEEE80211" ]] && [[ "$isActive" == "inactive" ]]; then
			echo "WiFi is not active, exiting"
			exit 0
		# Check to see if Ethernet is active, and if so, disabling WiFi.
		elif [[ ${nicType_array[${i}]} = "Ethernet" ]] && [[ "$isActive" == "active" ]]; then
			echo "turning off Wifi since Ethernet is active"
			networksetup -setairportpower "$wifiNIC" off
			exit 0
		fi
	fi
done

exit 0