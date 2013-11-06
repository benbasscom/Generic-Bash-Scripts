#!/bin/bash  
  
# Mountain Lion: run caffeinate in the background so the system doesn't sleep  
caffeinate &  
  
# Download updates to the daily backup on Red King to the local drive  
server='username@my.server.com'  
backups='/Volumes/Backups'  
  
archive='Teacup.quanta'  
echo "$(date): Downloading ${archive} from ${server}"  
rsync --recursive --delete --times --verbose "${server}:${backups}/${archive}" '/Volumes/Local Backups/Server'  
echo ""  
  
archive='Important Stuff.quanta'  
echo "$(date): Uploading ${archive} to ${server}"  
rsync --recursive --delete --times --verbose "/Volumes/Local Backups/${archive}" "${server}:${backups}"  
echo ""  
  
echo "$(date): Synchronization complete"  
  
# kill the caffeinate process; we're done now  
kill %1; sleep 1  
echo "==========================================================="  

