#!/bin/bash

# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# Rsync backup script with Versioning. Still testing self thinning version code at end.
# version 1.1TAM

# Setting the variable as 2011-07-6-16-38 (year, month, day, hour, minute)
# To create a unique directory as the destination of the backed up files.

UNIQUE=$1
: ${UNIQUE:="$(date +%Y-%m-%d-%H-%M)"}

# Setting variables for portability and ease of use
# if the path names have spaces DO NOT ESCAPE THEM
# how the variables are called removes the need for escaping spaces.

SOURCE="/Volumes/Data/Shared Items/TAM/"			# Source of the files
DESTINATION="admin@192.168.1.96:/share/Mac-BU/"			# location of backup files
LOG="/Library/Logs/com.trmacs/TAM-bu.log"			# User Log file location
RLOG="/Library/Logs/com.trmacs/TAM.log"			# rsync log file
EXCLUDES="/Library/Scripts/trmacs/rsync-excludes.txt"		# File containing excludes

# Path Variables
RSYNC="/usr/local/bin/rsync"					# Location of the rsync bin


# formatting for the log file readability
# the >> "${LOG}" is used to append to the log file.

echo "----------------------------------"		>> "${LOG}"
echo "        TAM QNAP Backup"				>> "${LOG}"
echo "----------------------------------"		>> "${LOG}"
echo ""							>> "${LOG}"
date							>> "${LOG}"
echo ""							>> "${LOG}"
system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print "Host Name: 	" $3}' >> "${LOG}"
echo "Source: 	"${SOURCE}""			>> "${LOG}"
echo "Destination: 	"${DESTINATION}""		>> "${LOG}"


# using patched rsync to backup From TAM's mac server to the QNAP NAS for offsite replication
# we are excluding the files from /Users/server/Documents/rsync-exclude.txt
# optional flags:
# -n for testing (dry run) USE THIS WHEN TESTING!!!!
# --delete-excluded  BE CAREFUL this will delete everything in the excludes file from the destination.  Can cause problems when used in conjunction with other versioning scripts.

# Manual run of the script.
#/usr/local/bin/rsync -axzhPn --stats --del --delete-excluded --log-file="${RLOG}" --exclude-from=/Users/server/Documents/rsync-excludes.txt /Volumes/Data/Shared\ Items/TAM/ admin@192.168.1.96:/share/Mac-BU/

# keeping -n flag until QNAP is ready for the mac backups. - 6/5/12
# -n flag removed and manually started 6/12/12 Brian Patterson gave OK that PC backups have completed.
# --rsh="ssh -C" - try using ssh compression.

$RSYNC								\
		-axzh						\
		--stats --del --delete-excluded			\
		--log-file="${RLOG}" 				\
		--exclude-from="${EXCLUDES}"			\
		"${SOURCE}" "${DESTINATION}"		>> "${LOG}"

# formatting for the log file readability

echo ""						>> "${LOG}"
date						>> "${LOG}"
echo ""						>> "${LOG}"
echo ""						>> "${LOG}"


exit 0
