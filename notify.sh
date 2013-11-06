#!/bin/bash
# Created by Ben Bass
# Copyright 2011 Technology Revealed. All rights reserved.
# E-mail notification script.
# version 1.01


#Set the date and format
WHEN=$1
: ${WHEN:="$(date +%Y-%m-%d)"}

# logging that the script ran.
# defining the log file.

LOG="/path/to/logs/logfile.log"
echo "-------------------------"		>> "${LOG}"
echo "Starting notify script at "$WHEN"" 	>> "${LOG}"


# Create the email subject, adding the date for fun.
SUBJECT="Backup logs for $WHEN"

# Defining the recipient of the message. Can use a comma to seperate more recipients.
TO="user@example.com"

# Define parts of the body to be assembled with breaks below.
# tail is used to pull the end of the log files. tail -28 is good for most of the logs and stats for the rsync -stats flag.

BODY1=$2
: ${BODY1:="$(tail -28 /Users/admin/Library/Logs/com.trmacs.rsync/share1-bu.log)"}
BODY2=$3
: ${BODY2:="$(tail -28 /Users/admin/Library/Logs/com.trmacs.rsync/share2-bu.log)"}
BODY3=$4
: ${BODY3:="$(tail -28 /Users/admin/Library/Logs/com.trmacs.rsync/share3-bu.log)"}
BODY4=$5
: ${BODY4:="$(tail -28 /Users/admin/Library/Logs/com.trmacs.rsync/share4-bu.log)"}
BODY5=$6
: ${BODY5:="$(tail -28 /Users/admin/Library/Logs/com.trmacs.rsync/share5-bu.log)"}

# adding this to keep an eye on the amount of data on the Versions drive.
# Change to match the drive you are using for versions if needed.

DISKCHK=$7
: ${DISKCHK:="$(df -h | grep /Volumes/Versions)"}


# define a spacer - this will put in 2 line breaks ending a line
# and adding a line of space to clean things visually.  Other characters
# can be added to further visually differentiate.
SPACER=$8
: ${SPACER:="

"}

# Here we assemble the body with the spacer between each 
MESSAGEBODY="$DISKCHK""$SPACER""$BODY1""$SPACER""$BODY2""$SPACER""$BODY3""$SPACER""$BODY4""$SPACER""$BODY5"

# echoing the message body and piping it to mail with the subject and recipient.
# cc'ing or bcc'ing can be done if needed too.

echo "$MESSAGEBODY" | mail -s "$SUBJECT" "$TO"

# finishing off the log file after the mail command has been called.
echo e-mail sent at $(date) to "$TO" 	>> "${LOG}"
echo ""					>> "${LOG}"
echo ""  				>> "${LOG}"

