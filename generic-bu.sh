#!/bin/bash

# Created by Ben Bass
# Copyright 2011 Technology Revealed. All rights reserved.
# Basic rsync backup script
# version 1.05

# Setting variables for portability and ease of use
# if the path names have spaces DO NOT ESCAPE THEM
# how the variables are called removes the need for escaping spaces.

SOURCE="/path/to/source/"
DESTINATION="/path/to/destination/"
LOG="/Library/Logs/com.trmacs.rsync/logfile.log"
EXCLUDES="/path/to/rsync-exclude.txt"


# formatting for the log file readability
# the >> "${LOG}" is used to append to the log file.

echo "----------------------------------"		>> "${LOG}"
echo "        Generic Backup"				>> "${LOG}"
echo "----------------------------------"		>> "${LOG}"
echo ""							>> "${LOG}"
date							>> "${LOG}"
echo ""							>> "${LOG}"
system_profiler SPSoftwareDataType | grep "Computer Name:" | awk '{print "Host Name: 	" $3}' >> "${LOG}"
echo "Source: 	"${SOURCE}""			>> "${LOG}"
echo "Destination: 	"${DESTINATION}""		>> "${LOG}"

# using patched rsync to backup From point A  to Point B
# we are excluding the files from /path/to/rsync-exclude.txt
# optional flags:
# -n for testing (dry run) USE THIS WHEN TESTING!!!!
# --delete-excluded  BE CAREFUL this will delete everything in the excludes file from the destination.  Can cause problems when used in conjunction with other scripts.

/usr/local/bin/rsync -aNHAXxhD --partial --numeric-ids --fileflags --force-change --stats --protect-decmpfs --del --force --exclude-from="${EXCLUDES}" "${SOURCE}" "${DESTINATION}" >> "${LOG}"

# formatting for the log file readability

echo ""							>> "${LOG}"
date							>> "${LOG}"
echo ""							>> "${LOG}"
echo ""							>> "${LOG}"

