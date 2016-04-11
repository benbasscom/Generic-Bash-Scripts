#!/bin/bash
# bridgeblock.sh
# Updated by Ben Bass on 2016-04-03.
# Version 1.1
# Designed to determine what NIC's are active, and if one specified as Ethernet is active
# disable the one noted as 80211x.
# 1.0 - Initial script.
# 1.1 -	Adding notify aspect and sleep at the bottom.
# To Do: optimize script and make it easier to read.

# this causes the script to wait for one notification of "edu.jhuapl.bridgeblock"
# the notification is being sent by the asl extension edu.jhuapl.edu which is looking for
# changes in ip addresses sent via configd.
notifyutil -1 edu.jhuapl.bridgeblock


#############################################
#Some variables to make things easier to read:
#############################################

PlistBuddy=/usr/libexec/PlistBuddy
plist=/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist


#############################################
#Find out how many Interfaces there are
#############################################

count=`networksetup -listallhardwareports | grep Hardware | wc -l | tr -s " "`
echo "Found$count network interfaces"


#############################################
#Get Interfaces
#############################################
#############################################
#reset counter
#############################################
counter=0

while [ $counter -lt $count ] 
do
		interface[$counter]=`$PlistBuddy -c "Print Interfaces:$counter:SCNetworkInterfaceType" $plist` 
	let "counter += 1"
done


#############################################
#Get Real Interfaces
#############################################
#reset counter
#############################################
counter=0

while [ $counter -lt $count ] 
do
		bsdname[$counter]=`$PlistBuddy -c "Print Interfaces:$counter:BSD\ Name" $plist`
	let "counter += 1"
done


#############################################
#Build Airport Array ${airportArray[@]} and Ethernet Array ${ethernetArray[@]}
#############################################
#reset counter
#############################################
counter=0

while [ $counter -lt $count ] 
do
#############################################
#Check for Airport
#############################################
		if [ "${interface[$counter]}" = "IEEE80211" ]
		then
#############################################
#Add it to the Array
#############################################
			airportArray[$counter]=${bsdname[$counter]}
		fi
#############################################
#Check for Ethernet
#############################################
		if [ "${interface[$counter]}" = "Ethernet" ]
		then
#############################################
#Add it to the Array
#############################################
			ethernetArray[$counter]=${bsdname[$counter]}
		fi
#############################################
	let "counter += 1"
#############################################
done
#############################################



#############################################
#Tell us what was found
#############################################
for i in ${ethernetArray[@]}
do
	echo $i is Ethernet
done

for i in ${airportArray[@]}
do
	echo $i is Airport
done


#############################################
#Check to see if Ethernet is connected
#############################################
#############################################
#Figure out which Interface has activity
#############################################
for i in ${ethernetArray[@]}
	do
	activity=`netstat -I $i | wc -l`
		if [ $activity -gt 1 ]
		then
			echo "$i has activity..."
			checkActive=`ifconfig $i | grep status | cut -d ":" -f2`
#############################################
#Ethernet IS connected
#############################################
			if [ "$checkActive" = " active" ]
			then
				echo "$i is connected...turning off Airport"
#############################################
#Turn off Airport
#############################################
				networksetup -setairportpower ${airportArray[@]} off
				echo "Airport off"
				exit 0
			fi
			if [ "$checkActive" = " inactive" ]
			then
				echo "$i is not active"
			fi
		fi
done
	echo "Checked all Interfaces"




#############################################
#If the script makes it this far assume Ethernet is not connected.
#############################################
#Turn on Airport
#############################################
#APL Mod 20121212 remove the comment flag from next line to enable WiFi.
#networksetup -setairportpower ${airportArray[@]} on
#echo "Airport on"


# sleeping 10 to prevent the job from logging a less than 10 seconds since last respawn, waiting x seconds.
sleep 10

exit 0

