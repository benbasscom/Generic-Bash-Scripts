#!/bin/bash
# rsync.net mount
# Created by Ben Bass
# Copyright 2012 Technology Revealed. All rights reserved.
# mounts Ben's rsync.net account as a local filesystem using sshfs to a directory in Ben's home directory.


/usr/local/bin/sshfs 2225@usw-s002.rsync.net: ~/rsync.net -oauto_cache,reconnect,local,volname=rsync.net,allow_other,defer_permissions

exit 0