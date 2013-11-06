#!/bin/bash

# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# Basic rsync backup script
# version 1.5.2

log="/Library/Logs/com.trmacs/fm-rsync.log"
err_log="/Library/Logs/com.trmacs/fm-rsync-error.log"
exec 1>> "${log}" 
exec 2>> "${err_log}"

host_name="$(system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print $3" "$4}')"

# Setting variables for portability and ease of use
SOURCE="/Users/admin/Documents/Live FM Databases/Files/"		# Source of the files
DESTINATION="/Users/admin/Dropbox/New FM Backups/Files/"		# location of backup files
RLOG="/Library/Logs/com.trmacs/fm-rlog.log"				# rsync log file
EXCLUDES="/Library/Scripts/trmacs/rsync-excludes.txt"			# File containing excludes

# Path Variables
RSYNC="/usr/local/bin/rsync"						# Location of the rsync bin

# formatting for the log file readability
echo "----------------------------------"
echo "       Generic Backup"
echo "----------------------------------"
echo ""
date
echo ""

echo "Host Name: 	"$host_name""
echo "Source: 	"${SOURCE}""
echo "Destination: 	"${DESTINATION}""

# using patched rsync to backup the images from the live database to Dropbox.
# we are excluding the files from /Library/Scripts/trmacs/rsync-excludes.txt
# -n for testing (dry run) USE THIS WHEN TESTING!!!!

"$RSYNC"							\
		-aNHAXh						\
		--stats --del --delete-excluded			\
		--log-file="${RLOG}" 				\
		--exclude-from="${EXCLUDES}"			\
		"${SOURCE}" "${DESTINATION}"

# Manual run of the script.
#/usr/local/bin/rsync -axhPn --stats --del --delete-excluded --log-file=/Library/Logs/com.trmacs/fm-rlog.log --exclude-from=/Users/server/Documents/rsync-excludes.txt /Volumes/Data/Shared\ Items/TAM/ admin@192.168.1.96:/share/Mac-BU/

# formatting for the log file readability

echo ""
date
echo ""
echo ""

exit 0