#!/bin/bash

#remove ACL's.
#Set to r/o for group
#chown to have Neimand Staff (GUID is 501) be the group, and local admin (UID is also 501) as owner.
#chmod neimandstaff to have the read only ACL recursively.

# set the log and error files.
log="/var/log/maclab-ccc.log"
err_log="/var/log/maclab-ccc-error.log"

# capture std out to log, and std-error to the err_log.
exec 1>> "${log}"
exec 2>> "${err_log}"

# Set the target directory here, less typing and less chance of misspelling/typos.
targetDirectory="/Volumes/Service Data/Shared Files/"

# possibly use more variables to make this portable - set the owner ID and group ID, as well as ACL name here.
# Setting the ACL's here could work too - maybe have a few known "good" configs, and then just pass the name of the
# one you want; ie, this one would be read only ACL, another could be R/W for this group, etc.
# It could get messy, but it's just an idea.


# echoing out the script name.  Remember since we are capturing std-out, everything echo'd goes to the log.
echo "Running $0"
echo "Starting CCC postflight permissions refresh on" "$(date)"

# Performing some basic checking - is the varible set above?
if [[ -z "$targetDirectory" ]]; then
     echo "Please set the variable targetDirectory in the postflight."
     echo ""
     echo "#########################################################"
     exit 1
fi

# Does the target directory exist and is it a directory?
if [[ ! -d "$targetDirectory" ]]; then
     echo "Can't find the $targetDirectory. Exiting"
     echo ""
     echo "#########################################################"
     exit 2
fi

# adding the -v flag to have it list out the files that are having the changes made.
echo "Removing existing ACL's"
chmod -RN "$targetDirectory"
echo ""
echo "Changing the POSIX permissions to 740 for RO access."
chmod -Rv 740 "$targetDirectory"
echo ""
echo "Changing the owner to 501:501"
chown -Rfv 501:501 "$targetDirectory"
echo ""
echo "Adding the ACL's for neimandstaff"
chmod -Rv +a "group:neimandstaff allow list,search,readattr,readextattr,readsecurity,file_inherit,directory_inherit" "$targetDirectory"
echo ""
echo "Checking the permissions of the files"
# l = list format
# a = show files that begin with a "."
# e = show ACL's
# h = with file sizes show B for byte, K for KB, M for MB, etc.
# O = capital o, not a number.  Used for showing file flags ex; hidden, or if SIP protected, or symlink.
# 
# This won't show everything, but is a good start.  You can append a subdirectory here if you want to get a little more granular and get more files
# if there aren't any in the root of the fileshare.
ls -laehO "$targetDirectory"

echo ""
echo "#########################################################"
exit 0
