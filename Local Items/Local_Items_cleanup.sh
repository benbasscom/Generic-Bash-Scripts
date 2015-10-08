#!/bin/bash
# Script to remove Local Items folder.
# Strongly suggest restarting after running the tool.
# Ben Bass 2015

sphard="$(system_profiler SPHardwareDataType)"
uuid="$(echo "$sphard" | grep "Hardware UUID:" | awk '{print $3}')"

echo $HOME

mv $HOME/Library/Keychains/$uuid/ $HOME/.Trash

exit 0