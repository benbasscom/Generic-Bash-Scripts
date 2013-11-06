#!/bin/bash -x
# Std out redirect test.  Good for logging and not cluttering up scripts appending to log files.

when=$(date +%Y-%m-%d)
log="/Library/Logs/com.trmacs/pi/"$when"1.log"
err_log="/Library/Logs/com.trmacs/pi/err_"$when".log"
exec 1>> "${log}" 
exec 2>> "${err_log}"

echo "testing"
date

exit 0