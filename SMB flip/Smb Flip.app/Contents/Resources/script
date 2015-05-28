#!/bin/bash
# Created by Ben Bass
# Copyright 2014 Ben Bass. All rights reserved.

nsmb=""$HOME"/Library/Preferences/nsmb.conf"

if [ -a "$nsmb" ]; then
	rm "$nsmb"
	echo "Enabling SMB2 for this user only"
else
	echo "Forcing SMB1 connections for this user only"
	echo "[default]" > "$nsmb"
	echo "smb_neg=smb1_only" >> "$nsmb"
fi

exit 0