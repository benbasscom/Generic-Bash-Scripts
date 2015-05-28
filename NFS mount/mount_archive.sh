#!/bin/bash
#mounts the Video Archive volume from the server via NFS
# unmounts from mount point, then mounts to same point

diskutil unmount /tmp/Video_Archive

mkdir -p /tmp/Video_Archive

mount_nfs 192.168.2.50:"/Volumes/Video Archive" /tmp/Video_Archive

exit 0