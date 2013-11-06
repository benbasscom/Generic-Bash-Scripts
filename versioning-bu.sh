#!/bin/bash

# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# Rsync backup script with Versioning.
# version 1.10

# Setting the variable as 2011-07-6-16-38 (year, month, day, hour, minute)
# To create a unique directory as the destination of the backed up files.

UNIQUE=$1
: ${UNIQUE:="$(date +%Y-%m-%d-%H-%M)"}

# Setting variables for portability and ease of use
# if the path names have spaces DO NOT ESCAPE THEM
# how the variables are called removes the need for escaping spaces.

SOURCE="/path/to/source/"						# Source of the files
DESTINATION="/path/to/destination/"					# location of backup files
LOG="/Library/Logs/com.trmacs.rsync/logfile.log"			# User Log file location
RLOG="/Library/Logs/com.trmacs.rsync/rlogfile.log"			# rsync log file
EXCLUDES="/path/to/rsync-exclude.txt"					# File containing excludes
INTERVAL=60								# The number of Days, Mins Hours, Seconds before deleting old BU's
TYPE=d									# d = days, s = seconds, w = weeks, h = hours
BACKUPDIR=$2								# Unique directory for backup files.
: ${BACKUPDIR:="/path/to/backup/dir/$UNIQUE"}
BUDIR="/path/to/backup/dir/"						# Root of the backup dir
ARCHIVE="/path/to/archive"						# Instead of rm'ing old BU's can mv to this directory


# Path Variables
RSYNC="/usr/local/bin/rsync"						# Location of the rsync bin


# formatting for the log file readability
# the >> "${LOG}" is used to append to the log file.

echo "----------------------------------"		>> "${LOG}"
echo "        Generic Backup"				>> "${LOG}"
echo "----------------------------------"		>> "${LOG}"
echo ""							>> "${LOG}"
date							>> "${LOG}"
echo ""							>> "${LOG}"
system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print "Host Name: 	" $3}' >> "${LOG}"
echo "Source: 	"${SOURCE}""				>> "${LOG}"
echo "Destination: 	"${DESTINATION}""		>> "${LOG}"


# using patched rsync to backup From point A  to Point B
# we are excluding the files from /path/to/rsync-exclude.txt
# optional flags:
# -n for testing (dry run) USE THIS WHEN TESTING!!!!
# --delete-excluded  BE CAREFUL this will delete everything in the excludes file from the destination.  Can cause problems when used in conjunction with other versioning scripts.

$RSYNC								\
		-aNHAXDxh					\
		--numer-ids --fileflags --force-change		\
		--stats --protect-decmpfs --del			\
		--log-file="${RLOG}"				\
		--exclude-from="${EXCLUDES}"			\
		-b --backup-dir="${BACKUPDIR}"			\
		"${SOURCE}" "${DESTINATION}"			>> "${LOG}"

# formatting for the log file readability
echo ""							>> "${LOG}"
echo "The version folder is "${BACKUPDIR}""		>> "${LOG}"
echo ""							>> "${LOG}"
date							>> "${LOG}"
echo ""							>> "${LOG}"
echo ""							>> "${LOG}"

# Set mtime of the root versions folder and current version folder to prevent accidental deletion.
touch "$BACKUPDIR"
touch "$BUDIR"

# Search for old backups older than the DAYS variable.  Can change interval to days, minutes/hours if so desire
# ie - add "s" for seconds, "h" for hours, "m" for minutes "w" for weeks - "${INTERVAL}"s for seconds
for FILE in "$( find $BUDIR -maxdepth 1 -type d -mtime +"${INTERVAL}"$TYPE )"
do
	# mv -f $FILE $ARCHIVE				>> "${LOG}"
	# rm -Rf $FILE								# Deletes items found. Comment out when testing and uncomment Echo

	echo "Removed backup directories $FILE" 	>> "${LOG}"		# Echo's files found - good for testing and logging

done
exit 0
