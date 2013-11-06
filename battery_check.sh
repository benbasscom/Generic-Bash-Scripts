#!/bin/bash
# Private Eyes log automation part 2
# Created by Ben Bass
vers="battery_chck-0.1"
# Copyright 2012 Technology Revealed. All rights reserved.

# set a variable for a unique log files.  Also used in syslog check for todays log entries.
# when=$(date +%Y-%m-%d)

# Set log files for stdout & stderror
# log="/Library/Logs/com.trmacs/pi/current/"$when"-syslog.log"
# err_log="/Library/Logs/com.trmacs/pi/current/"$when"-syslog.error.log"

log="/Users/benbass/Desktop/battery.log"
err_log="/Users/benbass/Desktop/battery-err.log"


# exec 1 captures stdtout and exec 2 captures stderr and we are appending to log files.
exec 1>> "${log}" 
exec 2>> "${err_log}"


host_name="$(scutil --get ComputerName)"
battery_raw="$(system_profiler SPPowerDataType)"
ioreg_raw="$(ioreg -rd1 -c IOPlatformExpertDevice)"

serial_num=$(echo "$ioreg_raw" | grep "IOPlatformSerialNumber" | cut -d \" -f4)
model=$(echo "$ioreg_raw" | grep "model" | cut -d \" -f4)
battery_max=$(echo "$battery_raw" | grep "Full Charge Capacity" | cut -d " " -f11-20)
battery_current=$(echo "$battery_raw" | grep "Charge Remaining" | cut -d " " -f11-20)
battery_cycle=$(echo "$battery_raw" | grep "Cycle Count" | cut -d " " -f11-20)
battery_condition=$(echo "$battery_raw" | grep "Condition" | cut -d " " -f11-20)


echo "$host_name"
echo "$serial_num"
echo "$model"
echo "$battery_max"
echo "$battery_current"
echo "$battery_cycle"
echo "$battery_condition"
echo ""

exit 0