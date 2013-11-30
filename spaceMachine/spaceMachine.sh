#!/bin/bash

# SPACE MACHINE (v20130409)
# Copyright (c) 2013, Elmar Czeko
# relevantcircuits.org - gplus.to/elmarczeko - twitter @elmarczeko
# This work is licensed under a Creative Commons Attribution 3.0 Unported License.
# http://creativecommons.org/licenses/by/3.0/

# on Mac set first line as "/bin/bash"
# on Diskstation NAS with IPKG installed use "/opt/bin/bash"

# function testWifi checks whether the indicated Wifi network is currently active
# if the Wifi network is detected as active, the function replies "0"
# this function is Mac specific 
function testWifi ()
{

	/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep -q "SSID: $1$"
	[ $? -eq 0 ] && echo 0 || echo 1

}

# function testSSH checks whether the user indicated in the job file can log into the server via the indicated port
# if log in is succesful, the function replies "0"
function testSSH ()
{

	ssh -q -p $sshPort $sshUser@$1 "echo >/dev/null" && echo 0 || echo 1

}

# function testInternet checks whether internet access is available
# if internet access is available, the function replies "0"
# as a test for internet connection, a ping signal is sent to google.com
function testInternet ()
{

	if test "$linuxDistribution" = "mac"; then
		/sbin/ping -o google.com 1> /dev/null 2> /dev/null
		exitStatus=$?
	elif test "$linuxDistribution" = "diskstation"; then
		/bin/ping -c 1 google.com 1> /dev/null 2> /dev/null
		exitStatus=$?
	fi	
		
	[ $exitStatus -eq 0 ] && echo 0 || echo 1

}

# function notification is used to send notifications
# depending on the system environment and settings either mail, nail (both for mail) or growl (desktop notification) are used
# a notification is only sent if its verbosity level indicated in the call is lower or equal to
# the threshold verbosity indicated in the job file
function notification ()
{
	if [ $1 -le $verbosityLevel ]; then
		if [ $# -eq 4 ]; then
			if test "$notificationType" = "nail"; then
				# "nail" can be used on Diskstation to send emails; it is installed via IPKG
				echo | /opt/bin/nail -s "$2" "$4 $3"
				exitStatus=$?	
			else
				# otherwise "mail" is used
				echo | mail -s "$2" -c $4 $3
				exitStatus=$?
			fi
			echo "notification mail was sent to $manualTargetActivationMail and $administratorMail (exit status $exitStatus)" >> $logFile
		else
			# desktop notifications can be send via growl
			if test "$notificationType" = "growl"; then
				/usr/local/bin/growlnotify -m "$2 at $(date +%H:%M)" -s -t spaceMachine
				echo "notification was sent to growl (exit status $?)" >> $logFile
			elif test "$notificationType" = "nail"; then
				echo | /opt/bin/nail -s "$2" $3
				echo "notification mail was sent to $administratorMail (exit status $?)" >> $logFile
			else
				echo | mail -s "$2" $3
				echo "notification mail was sent to $administratorMail (exit status $?)" >> $logFile
			fi
		fi
	fi

}

# function setServer determines whether a server is contacted via its "local" or "remote" address (specified in the job file)
# "local" is supposed to be the address of the NAS server within the home Wifi
# "remote" should be the address via which the NAS server is available over the internet
# if the location is not specified explicitly as either "local" or "remote" in the job file,
# the location is automatically set as "local" if the computer is currently in the home Wifi network ("localWifi"), otherwise as "remote"
function setServer ()
{
	previousServer="$server"
	if test "$setLocation" = "local"; then
		server=$rsyncTargetLocalServer
		location="local"
	elif test "$setLocation" = "remote"; then
		server=$rsyncTargetRemoteServer
		location="remote"
	else
		if [ $(testWifi $localWifi) -eq "0" ]; then
			server=$rsyncTargetLocalServer
			location="local"
			echo "wifi $localWifi is available" >>$logFile
		else
			server=$rsyncTargetRemoteServer
			location="remote"
			echo "wifi $localWifi is not available" >> $logFile
		fi
	fi

	[ "$server" != "$previousServer" ] && echo "target server is $server ($setLocation)" >> $logFile
}

# jobFile and derivatives (extract name of job file from call argument)
jobFile="$1"
jobFileNoExtension=${jobFile%".job"} # cut shortest match of pattern from end of string
jobFileNoPath=${jobFile##*/} # cut longest match of pattern from front of string
logFile="$jobFileNoExtension.log"

# if date folders are specified for backup, the transfer initially occurs to a temporary folder which is later renamed
# needs to have trailing /
tempFolder="spaceMachine-temporaryFolder-$jobFileNoPath/" 

# delays between and limit for reconnection attempts to server
sleepUponError=300
cycleUponError=10

# limit for overall rsync calls
totalCallLimit=500

# default job parameter settings
# if not specified in job file, default values are used
dateFolder="off"
jobInterval="1"
manualTargetActivation="off"
waitForTargetReminder="1"
notificationType="mail"	
verbosityLevel="2"	
rsyncFilter="off"
sshPort="22"
linuxDistribution="mac"
powerOffRemoteServer="off"
generalLogMac="${HOME}/spaceMachine.${USER}.log"
generalLogDiskstation="/volume1/spaceMachine.default.log"
setLocation="detect"
# flag file that indicates whether the remote NAS was powered up automatically (set by startCheck.sh script)
startStopFlag="/volume1/startStop.flag"

# call errors
# should actually go to stderror, not stdout
[ $# -eq 0 ] && { echo "Please designate a job file."; exit 1; } 
[ ! -f $jobFile ] && { echo "Designated job file does not exist." ; exit 1; }
[ ! -r $jobFile ] && { echo "Designated job file cannot be read."; exit 1; }

# read job file	
exec 3<$jobFile

i=0

while read -u 3 parameter setting
do

	if test "$parameter" = "folderJob"; then
		sourceFolder[i]="$(echo $setting | cut -d , -f 1)"
		targetFolder[i]="$(echo $setting | cut -d , -f 2)"
		serverType[i]="$(echo $setting | cut -d , -f 3)"
		((i++))
	elif test "$parameter" = "dateFolder"; then
		dateFolder="$setting"
	elif test "$parameter" = "setLocation"; then
		setLocation="$setting"
	elif test "$parameter" = "localWifi"; then
		localWifi="$setting"
	elif test "$parameter" = "jobInterval"; then
		jobInterval="$setting"
	elif test "$parameter" = "manualTargetActivation"; then
		manualTargetActivation="$setting"
	elif test "$parameter" = "manualTargetActivationMail"; then
		manualTargetActivationMail="$setting"
	elif test "$parameter" = "waitForTargetReminder"; then
		waitForTargetReminder="$setting"
	elif test "$parameter" = "administratorMail"; then
		administratorMail="$setting"
	elif test "$parameter" = "notificationType"; then
		notificationType="$setting"	
	elif test "$parameter" = "verbosityLevel"; then
		verbosityLevel="$setting"	
	elif test "$parameter" = "rsyncTargetLocalServer"; then
		rsyncTargetLocalServer="$setting"
	elif test "$parameter" = "rsyncTargetRemoteServer"; then
		rsyncTargetRemoteServer="$setting"
	elif test "$parameter" = "rsyncLocalParameters"; then
		rsyncLocalParameters="$setting"
	elif test "$parameter" = "rsyncRemoteParameters"; then
		rsyncRemoteParameters="$setting"
	elif test "$parameter" = "rsyncFilter"; then
		rsyncFilter="$setting"
	elif test "$parameter" = "sshUser"; then
		sshUser="$setting"
	elif test "$parameter" = "sshPort"; then
		sshPort="$setting"
	elif test "$parameter" = "linuxDistribution"; then
		linuxDistribution="$setting"
	elif test "$parameter" = "powerOffRemoteServer"; then
		powerOffRemoteServer="$setting"
	elif test "$parameter" = "generalLogMac"; then
		generalLogMac="$setting"
	elif test "$parameter" = "generalLogDiskstation"; then
		generalLogDiskstation="$setting"
	elif test "$parameter" = "startStopFlag"; then
		startStopFlag="$setting"
	fi

	parameter=""; setting=""

done

exec 3<&-

# check if indicated rsync filter file is available
if [ $rsyncFilter != "off" ]; then
	[ ! -f $rsyncFilter ] && { echo "Designated filter file does not exist." ; exit 1; }
	[ ! -r $rsyncFilter ] && { echo "Designated filter file cannot be read."; exit 1; }
fi

# check for running instance of script
# on Macs a new cron job is started no matter whether the previous cron job is already finished (which is undesirable)
# on Diskstation, new cron jobs are apparently only started when the previous job is finished (which is good here)
# if a running job is detected, this is reported to the general log file and the present call is aborted
if test "$linuxDistribution" = "mac"; then
	generalLog=$generalLogMac
	runningProcesses=$(ps -ef | grep -c "$jobFile")
elif test "$linuxDistribution" = "diskstation"; then
	generalLog=$generalLogDiskstation
	notificationType="nail"	# force notification type for diskstation
	setLocation="remote"
	runningProcesses=$(ps | grep -c "$jobFile")
fi

if [ $runningProcesses -gt 3 ]; then 
	echo "$(date)" >> $generalLog
	echo "Job $jobFile already running (count is $runningProcesses)" >> $generalLog
	echo >> $generalLog
	exit 1
fi

[ ! -f $logFile ] && echo > $logFile

# check whether the last exit code in the job's log file has the expected format
exitCodeCheck=$(tail -n 1 $logFile | grep -oc "^[[:digit:]]*,[[:digit:]]*,[[:digit:]]*$")

# read the last exit code from the job's log file
if [ $exitCodeCheck -eq 1 ]; then
	lastBackupExitStatus=$(tail -n 1 $logFile | cut -d , -f 1)
	mailReminderDay=$(tail -n 1 $logFile | cut -d , -f 2)
	folderJobCompleted=$(tail -n 1 $logFile | cut -d , -f 3)
	nextBackup=$(expr $lastBackupExitStatus + $jobInterval)
else
	# if exit code format is not as expected, reinitiate log file
	lastBackupExitStatus=0
	mailReminderDay=0
	folderJobCompleted=0
	nextBackup=0
	
	echo >> $logFile
	echo "no previous exit status detected, reinitiating log" >> $logFile
fi

# exit code 10 freezes further execution of script
# used when total rsync call limit was reached before, administrator intervention required 
[ $lastBackupExitStatus -eq 10 ] && exit 1

# calculate today's date value to check whether a new backup run is due
# this calculation is an approximation; the intended backup interval may vary when spanning years or months
year=$(date "+%Y"); month=$(date "+%m"); day=$(date "+%d")
currentDay=$(expr 360 \* $year + 30 \* $month + $day)

# perform a new backup run when today's date value is greater or equal to the next backup date value
if [ $currentDay -ge $nextBackup ]; then

	echo >> $logFile
	echo "$(date)" >> $logFile 
	echo "backup due" >> $logFile
	
	ii=$folderJobCompleted
	setServer
	
	if [ $(testSSH $server) -eq "0" ]; then
		echo "$server is available" >>$logFile

		if test "$linuxDistribution" = "diskstation"; then
			# check for an automatic startup flag file set by the startCheck.sh script on a remote NAS; remove if flag file is present
			# removal of the flag file indicates that a backup run has been initiated
			# if flag file is not removed the remote NAS may be shut down by the stopCheck.sh script later 
			ssh -q -p $sshPort root@$server [ -f $startStopFlag ] &&
			{
				ssh -q -p $sshPort root@$server rm $startStopFlag;
				echo "Removing automatic target activation flag (exit code $?)" >>$logFile;
			} || echo "no target activation flag detected" >>$logFile
		
		fi

		if [ $lastBackupExitStatus -eq 1 ]; then
			echo "resuming backup" >> $logFile
			notification 2 "Backup $jobFileNoPath resumed" $administratorMail
		else
			echo "initiating backup" >> $logFile
			notification 2 "Backup $jobFileNoPath initiated" $administratorMail
		fi
		
		((i--))
		totalCallCounter=0
		
		while [ $ii -le $i ]
		do
			loopRsync=1
				
			while [ $loopRsync -ge 1 ]
			do
             	# set rsync parameters
				if test ${serverType[ii]} = "serverIsTarget"; then
					sourceParameter="${sourceFolder[ii]}"
					targetParameter="$server:${targetFolder[ii]}" 
				else
					sourceParameter="$server:${sourceFolder[ii]}"
					targetParameter="${targetFolder[ii]}"
				fi
				
				test $dateFolder = "on" && targetParameter="$targetParameter$tempFolder"
				test $location = "local" && rsyncParameters=$rsyncLocalParameters || rsyncParameters=$rsyncRemoteParameters 
            	
            	rsyncLogFile="$jobFileNoExtension.$(date +%Y%m%d-%H%M%S)-j${ii}c${loopRsync}.txt"
            	
            	[ $loopRsync -eq 1 ] && echo "starting job $ii, source is $sourceParameter" >> $logFile
            	echo "call $loopRsync on $(date)" >> $logFile
            	            	
            	# RSYNC CALL (cannot include quotes in string, why?)            	
            	if test "$rsyncFilter" = "off"; then
            		# rsync call to log (without filter file)
            		echo "rsync $rsyncParameters --log-file=$rsyncLogFile -e \"ssh -l $sshUser -p $sshPort\" $sourceParameter $targetParameter 1>/dev/null 2>/dev/null" >> $logFile
            		# export current status before rsync call (in case script is interrupted)
            		echo "1,0,$ii" >> $logFile
            		
            		rsync $rsyncParameters --log-file="$rsyncLogFile" -e "ssh -l $sshUser -p $sshPort" "$sourceParameter" "$targetParameter" 1>/dev/null 2>/dev/null
            		exitCode=$?
            	else
            		# rsync call to log (with filter file)
            		echo "rsync $rsyncParameters --log-file=$rsyncLogFile --filter=\"merge $rsyncFilter\" -e \"ssh -l $sshUser -p $sshPort\" $sourceParameter $targetParameter 1>/dev/null 2>/dev/null" >> $logFile
            		# export current status before rsync call (in case script is interrupted)
            		echo "1,0,$ii" >> $logFile
            		
            		rsync $rsyncParameters --log-file="$rsyncLogFile" --filter="merge $rsyncFilter" -e "ssh -l $sshUser -p $sshPort" "$sourceParameter" "$targetParameter" 1>/dev/null 2>/dev/null
            		exitCode=$?
            	fi
            	            	
            	echo "rsync exit code was $exitCode" >> $logFile
             	
             	if (($exitCode == 0)) || (($exitCode == 23)) || (($exitCode == 24)); then
             		# minor exit codes (do not initiate another rsync call)
             		[ $exitCode -eq 23 ] && echo "some files or attributes were not transferred" >> $logFile
             		[ $exitCode -eq 24 ] && echo "some files vanished before they could be transferred" >> $logFile
             		loopRsync=0
             		
             		# rename temporary date folders to current date
             		if test $dateFolder = "on"; then
             			if test ${serverType[ii]} = "serverIsTarget"; then
				 			ssh -q -p $sshPort $sshUser@$server "mv ${targetFolder[ii]}$tempFolder ${targetFolder[ii]}$(date +%Y.%m.%d)/"
							echo "renamed temporary to dated folder on $server (exit code was $?)" >> $logFile
						else
							mv $targetParameter $targetParameterRoot$(date +%Y.%m.%d)/
							echo "renamed temporary to dated folder locally (exit code was $?)" >> $logFile
						fi
             		fi
             		
             		echo "completed job $ii on $(date)" >> $logFile
             	else
             		# serious exit codes (followed by another rsync call)
             		[ $exitCode -eq 11 ] && echo "error in file input/output" >> $logFile
             		[ $exitCode -eq 12 ] && echo "error in rsync protocol data stream" >> $logFile
             		[ $exitCode -eq 20 ] && echo "received user termination signal" >> $logFile
             		[ $exitCode -eq 30 ] && echo "timeout in data send/receive" >> $logFile
             		[ $exitCode -eq 43 ] && echo "rsync service is not running" >> $logFile
             		[ $exitCode -eq 255 ] && echo "broken pipe, possibly $server obtained a new IP" >> $logFile
             		((loopRsync++))
             		             							
					# in case location (local/remote) changed, setServer anew (may only be relevant for exit code 255)
					setServer	
					
					# recheck if remote server is still available
					# retry $cycleUponError times and wait $sleepUponError seconds between connection attempts
					# if the connection cannot be reestablished, backup is only resumed when script is restarted (e.g. next time by cron)
					cycleCounter=0
					
					while [ $(testSSH $server) -eq "1" ]
					do
             			if [ $cycleCounter -eq $cycleUponError ]; then
							echo "$server is not available anymore" >>$logFile
							
							if [ $(testInternet) -eq "1" ]; then
								echo "internet access is not available anymore" >>$logFile
							else
								echo "internet access is available" >>$logFile
							fi
							
							notification 2 "Backup $jobFileNoPath paused" $administratorMail
							
							# set lastBackupExitStatus to 1, so that the backup is resumed independent of the date value upon the next call
							# completed folder jobs are logged by $ii, so that the backup is resumed with the last incomplete folder job
							lastBackupExitStatus=1
							echo "$lastBackupExitStatus,0,$ii" >> $logFile
							exit 1
						fi
						((cycleCounter++))
						
						sleep $sleepUponError
            			setServer
					done
				fi
        		
        		# if a high number of rsync calls is reached, as limited by $totalCallCounter, a serious problem may be involved;
        		# in this situation the backup is stopped for this and all subsequent calls until exit code 10 is manually removed
        		# from the log file
        		((totalCallCounter++))
				if [ $totalCallCounter -eq $totalCallLimit ]; then
					echo "Call limit reached, administrator attention required, reexecution of script halted by exit code 10" >>$logFile
					notification 0 "Call limit for $jobFileNoPath reached, administrator attention required" $administratorMail
					echo "10,0,0" >> $logFile
					exit 1
				fi
        	done
		
			((ii++))
		done
		
		echo "backup $jobFile completed" >> $logFile
				
		# shut down remote server if set in job file (command for Diskstation NAS)
		if test "$powerOffRemoteServer" = "on"; then
			ssh -q -p $sshPort root@$server poweroff
			echo "Shutting down $server (exit code $?)" >> $logFile
		fi
		
		notification 1 "Backup $jobFileNoPath completed" $administratorMail
		
		# log exit code: $currentDay indicates the date value for the last completed backup
		echo "$currentDay,0,0" >> $logFile
		exit 0
			
	else
		
		echo "$server is not reachable" >> $logFile
		
		if [ $(testInternet) -eq "0" ]; then
			echo "internet access is available" >> $logFile
			
			# send (repeated) request by email to $manualTargetActivationMail to manually power up remote NAS
			if test $manualTargetActivation = "on"; then
				if [ $currentDay -ge $mailReminderDay ]; then
					notification 0 "Netzwerkserver $server bitte starten" $manualTargetActivationMail $administratorMail
					echo "new reminder will be sent in $waitForTargetReminder day(s)" >> $logFile
					nextReminder=$(expr $currentDay + $waitForTargetReminder)
				else
					echo "new reminder for activation of $server will be sent in $(expr $mailReminderDay - $currentDay) day(s)" >> $logFile
					nextReminder=$mailReminderDay
				fi
			else
				echo "notification for manual target activation is off" >> $logFile
				nextReminder=0
			fi
			
			echo "$lastBackupExitStatus,$nextReminder,$folderJobCompleted" >> $logFile
			exit 1
		else
			echo "internet access is not available" >> $logFile
			if test $manualTargetActivation = "on"; then
				echo "cannot send request for manual target activation" >> $logFile
			else
				echo "no notification for manual target activation sent (off)" >> $logFile
			fi
			echo "$lastBackupExitStatus,$mailReminderDay,$folderJobCompleted" >> $logFile
			exit 1
		fi
	fi

else

	# logging for script calls without backup run can be uncommented below
	# depending on cron call intervals, this may lead to long log files
	
	# echo "backup not yet due" >> $logFile
	# echo "$lastBackupExitStatus,0,0" >> $logFile
	exit 0

fi
