#!/bin/bash
# afp_chck.sh
# Version 0.3
# Creation Date 2015-04-10
# Last Modified Date 2015-12-15
# 0.1 -	Initial Script
# 0.2 -	Addition of secondary check - AppleFileServer will not launch until a connection is attempted
# 0.3 -	Had to change quotes for server_admin_chck
# Created by Blake Robertson on 4/10/15.
# Script for OS X Server to check the AFP service and start it if it is not running
# Updated by Ben Bass on 12/15/2015
# 
###############################################
#
# Road Map of the script.
#
###############################################
# 00 Header
# Contains variables, functions and this road map.
#
#### 
# 01 Script Begins
# Run functions and check if afp is running and restart if not.
# 
###############################################
# 00a
# Define Functions
#
###############################################

rootcheck (){
if [ "`/usr/bin/whoami`" != "root" ] ; then
  /bin/echo "script must be run as root"
  exit 0
fi
}

###############################################

####################################
# 00d
# Set some variables and capture Std in and Std error
#
####################################

LOGFOLDER="/Library/Logs/companyname/"
log="/Library/Logs/companyname/afprefresh.log"
err_log="/Library/Logs/companyname/afprefresh-err.log"

# Check if the log folder exists, if not create and chmod it.
if [ ! -d "$LOGFOLDER" ];
then
	mkdir -p "$LOGFOLDER"
	chmod 755 "$LOGFOLDER"
fi
# Capture std err and std out to the log files above.
exec 1>> "${log}" 
exec 2>> "${err_log}"


when="$(date +%Y-%m-%d-%H:%M:%S)"
afp_status="$(ps awx | grep -q AppleFileServer ; echo $?)"
server_admin_chck="$(serveradmin status afp | awk '{print$3}')"

####################################
# 01
# Begin Script 
# Run functions and check if afp is running and restart if not.
####################################

rootcheck

# echo out to the log date and time and the current status of AFP
echo "On "$(date)", the afp status is "$afp_status" and "$server_admin_chck""

# Check the afp status
if [ "$afp_status" == 1 ] || [ "$server_admin_chck" != '"RUNNING"' ]; then
	echo "afp is not running, starting at ""$when"
	serveradmin start afp
	echo "AFP Service started on" "$when"
else
	echo "AFP Service is running properly at ""$when"

fi

exit 0