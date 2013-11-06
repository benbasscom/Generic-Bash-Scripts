#!/bin/bash
# CCC Archiving post flight script v1.0
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# This is a CCC post flight script to move Archived folders from the backup drive to a different volume


log="/Library/Logs/com.trmacs/CCC_archive.log"
err_log="/Library/Logs/com.trmacs/CCC_archive-err.log"

exec 1>> "${log}" 
exec 2>> "${err_log}"

when="$(date +"%A %B %e, %G at %I:%M%p")"

#Check to see if the backup drive is mounted.  Exit if not.

# Directory CCC initially places the _CCC Archives folder
# STARTDIR=/Volumes/Data\ Offsite/_CCC\ Archives
STARTDIR=/Volumes/Backup/Share/_CCC\ Archives

# Desired final destination of folders within the _CCC Archives folder
# ARCHDIR=/Volumes/Archive\ Offsite
ARCHDIR=/Volumes/Versions/Versions

if [[ $(mount | awk '$3 == "/Volumes/Versions" {print $3}') != "" ]]; then

# Move the subfolders from the _CCC Archives folder to the Archive directory
# This should last until 2020 as we are searching for a folder starting with 201
# 2012-09-06 (September 06) 15-58-03 is the syntax CCC 3.5.1 uses.

	mv "$STARTDIR"/201* "$ARCHDIR"
	#cp -pRP "$STARTDIR"/201* "$ARCHDIR"
	#rm -rf "$STARTDIR"/201*
	echo "On "$when" versioning files"
	#Delete archives older than 90 days:
	find "$ARCHDIR" -name '201*' -type d -mtime +90 -print0 | xargs -0 rm -rf
	exit 0
else
	echo "At "$when" The Versions drive is not mounted, exiting"
	exit 1
fi
