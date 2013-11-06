#!/bin/bash -eu
# Time rsYnc Machine (tym), a back-up time machine as popularized by Apple.
readonly Notice='Copyright: M.T. Carrasco Benitez. License: EUPL.'
readonly Version=4
readonly LastUpdated='27 October 2012'

#================================================#===========================================#
# Parameters                                     # Set these variables. 
# Mandatory
readonly SourceList=/foo/source                  # local source list of files/directories
readonly DestDir=/foo/dest                       # local destination directory
#readonly DestDir=bar@example.com:/foo/dest      # remote destination directory

# Optionals
#LogDir=/foo/log                                 # defaults to "~.$Prog"

#================================================#===========================================#
Main () {                                        # this function is called from the end of the file
 readonly Prog=${2##*/}                          # program name - basename

 case $1                                         # number of arguments in the command line
  in 1 ) readonly Opt=$3
  ;; * ) echo "$Prog: error. Only one option is required" ; Help 40
 esac

 case $Opt
  in backup ) Backup        # back-up ; the other case below are auxiliary functions
  ;; help   ) Help 0        #                                        - no back-up is done
  ;; man    ) Manpage       #                                        - no back-up is done
  ;; mo     ) Monitor       # monitor current run                    - no back-up is done
  ;; log    ) Showlog       # show last/current logs                 - no back-up is done
  ;; list   ) ListBackup    # list the back-ups                      - no back-up is done
  ;; kill   ) Kill          # soft kill current run                  - no back-up is done
  ;; del    ) DelOld        # delete and log oldest backup           - no back-up is done
  ;; *      ) echo "$Prog: error. Unknown option: $Opt" ; Help 41  # - no back-up is done
 esac

 echo Sentinel-2. It must never come here. ; exit 62
}

#------------------------------------------------#-------------------------------------------#
Backup () {
 RedirectOutput                                  # redirect standard output and standard error
 TrapAllSignals                                  # the handler is the function SignalHandler
 LogHeader                                       # log the program headers
 Rsync                                           # run rsync to do the back-up
 echo Sentinel-3. It must never come here. ; exit 63
}

#------------------------------------------------#-------------------------------------------#
RedirectOutput () {
 readonly StartTime=$(date +%s)                  # start time in seconds
 readonly DirStamp=$(date +%y%m%d-%H%M%S)        # directory stamp - yymmdd-hhmmss - 120228-163606 
 LogDir=${LogDir-$HOME/.$Prog}                   # set LogDir, if unset -  example /home/foo/.tym
 readonly LogStamp=$LogDir/$DirStamp             # log directory - default : /home/foo/.tym/120228-163606
                                                 #                 foo     : /foo/log/120228-163606
 mkdir -p $LogStamp                              # create log directory if it does not exist
 exec 1>$LogStamp/out.txt                        # redirect standard output
 exec 2>$LogStamp/err.txt                        # redirect standard error
}

#------------------------------------------------#-------------------------------------------#
LogHeader () {
 LogCounter=1                                    # init log counter - used in function Log

 Log start-time         "$(date '+%T %d-%m-%Y')" # first entry in the log file
 Log prog-fullname      "Time rsYnc Machine (tym)"
 Log prog-shortname     "$Prog"
 Log prog-version       "$Version"
 Log prog-creation-date "18 February 2012"
 Log prog-lastupdate    "$LastUpdated"
 Log notice             "$Notice"
 Log source             "$SourceList"
 Log destination        "$DestDir"
 Log logs               "$LogStamp"
 Log signal-list        "$(echo $SignalList | tr -d '\n')"
 Log PID                "$$"
 Log PPID               "$PPID"
 Log HOSTNAME           "$HOSTNAME"
 Log user               "$(whoami)"
 Log BASH_VERSION       "$BASH_VERSION"
}

#------------------------------------------------#-------------------------------------------#
Rsync () {
 local readonly Rlog=$LogStamp/rsync.txt         # standard output of rsync
 local readonly Rformat='%o %i %3b %5l  %-f'     # rsync log format - see man rsyncd.conf
 local readonly Exclude='lost+found/'            # others might be added

 Log rsync-log-file    $Rlog
 Log rsync-log-format "$Rformat"
 Log rsync-exclude    "$Exclude"

 set +e                                          # exit on error: off - to avoid rsync killing the script
                                                 # -H might clash with --link-dest - see man rsync
 rsync                         \
  -azhq                        \
  --partial                    \
  --ignore-existing            \
  --exclude $Exclude           \
  --stats                      \
  --log-file=$Rlog             \
  --log-file-format="$Rformat" \
  $(LinkDest)                  \
  $SourceList                  \
  $DestDir/$DirStamp

 ExitRsync=$?
 set -e                                          # exit on error: on
 Log exit-rsync $ExitRsync
 Bye $ExitRsync                                  # in this case the tym and rsync have the same exit status
}

#------------------------------------------------#-------------------------------------------#
LinkDest () {
 local readonly Script="
     if [ ! -d   $DestDir  ]
   ;  then mkdir $DestDir
   ;  else ls    $DestDir | tail -1
   ; fi
 "

 local readonly IFSori=$IFS                                # find out if DestDir is local or remote
 IFS=':'                                                   # local       remote
 set - $DestDir                                            # /foo/dest | bar@example.com:/foo/dest
 IFS=$IFSori                                               # $# = 1      $# = 2

 case $#                                         
  in 1 ) Log backup-local-machine localhost                # local machine
         local readonly LastStamp=$(eval $Script)          # find last backup locally

  ;; 2 ) Machine=$1                                        # remote machine
         Log backup-remote-machine $Machine
         local readonly LastStamp=$(ssh $Machine $Script)  # find last backup in the remote machine

  ;; * ) Log FATAL-ERROR-bad-store-dir "$DestDir" ; Bye 50
 esac

 if [ "$LastStamp" ]
  then readonly LinkDest="--link-dest=$DestDir/$LastStamp" # last backup found, so hardlink to LastStamp
  else readonly LinkDest=''                                # no last backup found, so backup all
 fi

 Log this-dir-stamp   "$DirStamp"                          # directory stamp of the current run
 Log last-dir-stamp   "$LastStamp"                         # directory stamp of the last run
 Log rsync-link-dest  "$LinkDest"                          # the --link-dest argument for rsync
 echo "$LinkDest"                                          # return: LinkDest
}

#------------------------------------------------#-------------------------------------------#
TrapAllSignals () {                              # Linux 64 - OSX 31 - see trap -l
 readonly SignalList='
   ERR
   1  2  3  4  5  6  7  8    10
  11 12 13 14 15 16 17 18 19 20
  21 22 23 24 25 26 27 28 29 30
  31       34 35 36 37 38 39 40
  41 42 43 44 45 46 47 48 49 50
  51 52 53 54 55 56 57 58 59 60
  61 62 63 64
 '

 for Signal in $SignalList ; do
  trap "SignalHandler $Signal" $Signal
 done
}

#------------------------------------------------#-------------------------------------------#
SignalHandler () {
 local readonly Signal=$1

 set - $(caller 0)                               # return one line with three tokens
 local readonly Func=$2                          # the second token is the caller function

 case $Signal
  in ERR     ) Log signal-exit    "$Signal $Func" ; Bye 51
  ;; 15      ) Log signal-sofkill "$Signal $Func" ; Bye 52
  ;; *       ) Log signal-ignore  "$Signal $Func" # log the signal and continue
 esac
}

#------------------------------------------------#-------------------------------------------#
Bye () {                                         # tym allways exit from here, except for kill -9 or similar
 local readonly Status=$1

 local readonly S="$(( $(date '+%s') - $StartTime ))"  # execution time in seconds
 DHMS=$(printf "%02d:%02d:%02d:%02d\n" $(($S/86400)) $(($S/3600%24)) $(($S/60%60)) $(($S%60)))

 Log exit-$Prog      "$Status"
 Log execution-time  "$DHMS"                     # execution time as day:hour:minute:second
 Log end-time        "$(date '+%T %d-%m-%Y')"    # a crash if this is not the last entry in the log file

 exit $Status                                    # the same as rsync, except if interrupted
}

#------------------------------------------------#-------------------------------------------#
Log () { # log one line with the fields: SerialNumber|SecondsSinceInvocation|Key|Value|
 local readonly Key="$1"
 local readonly Value="$2"
 local readonly Fdel='|'                         # field delimiter
 echo "$((LogCounter++))$Fdel$SECONDS$Fdel$Key$Fdel$Value$Fdel" >> $LogStamp/log.txt
}

#================================================#===========================================#
# These are the auxiliary functions. Each one is independent. Only one is run according to the
# option passed in the command line. They are in foreground.

#------------------------------------------------#-------------------------------------------#
Help () {
 local readonly Status=$1

 echo 'Usage: tym <option>
  The options are
   backup : do a backup
   help   : help
   man    : man page
   mo     : monitor current run
   log    : show last/current logs
   list   : list the back-ups
   kill   : soft kill current run
   del    : delete and log oldest backup'

 exit $Status
}

#------------------------------------------------#-------------------------------------------#
Monitor () {                                     # monitor current run
 clear
 local readonly Last=$LogDir/$(ls $LogDir | tail -1 )

 tail -f --pid=$(GetPID)  \
  $Last/log.txt           \
  $Last/err.txt           \
  $Last/out.txt           \
  $Last/rsync.txt

 exit 0
}

#------------------------------------------------#-------------------------------------------#
Showlog () {                                     # show last/current logs
 clear
 Last=$LogDir/$(ls $LogDir | tail -1)

 more              \
  $Last/log.txt    \
  $Last/err.txt    \
  $Last/out.txt    \
  $Last/rsync.txt

 exit 0
}

#------------------------------------------------#-------------------------------------------#
ListBackup () {
 ls $DestDir
 exit 0
}

#------------------------------------------------#-------------------------------------------#
Kill () {                                        # soft kill current run
 kill $(GetPID)
 exit 0
}

#------------------------------------------------#-------------------------------------------#
DelOld () {                                      # delete and log oldest backup
 local readonly Old=$(ls $DestDir | head -1)
 local readonly Now=$(date "+%y%m%d-%H%M%S")
 echo "$Now|$DestDir/$Old|"> $LogDir/$Old/del.txt
 rm -rf $DestDir/$Old
 exit 0
}

#------------------------------------------------#-------------------------------------------#
GetPID () {                                      # get PID of the last/current backup tym
 local readonly Last=$LogDir/$(ls $LogDir | tail -1 )
 local readonly PIDline=$(grep '|PID|' $Last/log.txt)
 local readonly IFSori=$IFS
 IFS='|'
 set $PIDline
 IFS=$IFSori
 echo $4                                         # return PID
}

#------------------------------------------------#-------------------------------------------#
Manpage () {                                     # it creates the tym man page
man -l - << manpage
.\" Manpage for tym.
.TH tym 1 "$LastUpdated" "version 4" "" 
.SH NAME
tym \- rsync time machine

.SH SYNOPSIS
tym backup|help|man|mo|log|list|kill|del

.SH DESCRIPTION
.B Time rsYnc Machine
(tym) is a backup utility with the approach popularized by the Time Machine of Apple.
Each \fBrun\fP creates an incremental backup into a directory \fBDestDir/yymmdd-hhmmss\fP;
the destination directory \fBDestDir\fP contains a \fByymmdd-hhmmss\fP for each run,
and hence the time machine effect.
To recover data, use the operating system programs such as \fBcp\fP;
care should be taken to keep last accessed time, and similar.

The variable \fBSourceList\fP contains the files/directories to be backed-up.
To achieve the incremental backup, tym sets the rsync \fB--link-dest\fP
option to the last backup in DestDir;
this instructs rsync to hardlink unchanged files from --link-dest to the new backup.

Logs go into the directory \fBLogDir/yymmdd-hhmmss\fP.
The string \fByymmdd-hhmmss\fP is the run timestamp as
year, month, day, hours, minutes and seconds;
for each run,
it is the same in the directories DestDir and LogDir.
It is recommended to run tym in background;
login out will not kill the process.

From a design perspective,
the rationale has been to make a bash script easy to read and modify.
All is contained in one file, even the man page.

.SH OPTIONS
.nf 
\fBbackup\fP Do a backup.
\fBhelp\fP   Help.
\fBman\fP    Man page.
\fBmo\fP     Monitor current run.
\fBlog\fP    Show log of the current/last run.
\fBlist\fP   List the back-ups.
\fBkill\fP   Kill current run.
\fBdel\fP    Delete oldest run.
.fi

.SH SETUP
Set the internal variables at the beginning of the file.

.SS Mandatory variables
readonly SourceList=/foo/bar-source
.br
readonly DestDir=[bar@example.com:]/foo/bar-dest

.SS Optional variable
readonly LogDir=/foo/bar-log

.SH DEFAULT
.SS Logs
LogDir='~/.tym'

.SH FILES
.I /foo/bar-dest
.RS
Destination directory.  The value of the variable DestDir.  Each run creates one
.br
yymmdd-hhmmss run directory in DestDir.
.RE
.I /foo/bar-dest/yymmdd-hhmmss
.RS
Run destination directory; example:
.I /foo/bar-dest/120228-163606
.RE
.I /foo/bar-log
.RS
Logs directory.  The value of the variable LogDir.
Each run creates one yymmdd-hhmmss run directory in LogDir.
.RE
.I /foo/bar-dest/yymmdd-hhmmss
.RS
Run log directory;
example:
.I /foo/bar-dest/120228-163606
.RE
.I /foo/bar-log/yymmdd-hhmmss/log.txt
.RS
The main tym log file.
It contains four fields separated by '|':
sequencial number,
seconds into the process,
key,
value.
.RE
.I /foo/bar-log/yymmdd-hhmmss/rsync.txt
.RS
The output of rsync.
.RE
.I /foo/bar-log/yymmdd-hhmmss/out.txt
.RS
The standard output; it should be empty.
.RE
.I /foo/bar-log/yymmdd-hhmmss/err.txt
.RS
The standard error; it should be empty.
.RE
.I /foo/bar-log/yymmdd-hhmmss/del.txt
.RS
Deleted backup log.
It contains one line with two fields separated by '|':
time of the deletion
and
full path of the deleted backup.
.RE

.SH EXIT VALUES
Less than 40: the same meaning as rsync.
.br
40 : wrong number of options.
.br
41 : unknown option.
.br
50 : fatal error - bad store directory.
.br
51 : signal ERR.
.br
52 : signal 15.
.br
61 : sentinel 1; error in the program.
.br
62 : sentinel 2; error in the program.
.br
63 : sentinel 3; error in the program.

.SH EXAMPLES
.SS Doing a back-up
tym backup &

.SS Monitor progress
tym mo

.SS Run directories (yymmdd-hhmmss)
The command tym executed on 16:32:06 28 February 2012 created one run directory in each of the DestDir and LogDir directories, with the format \fB120228-163606\fP.

.SS One item for back-up
readonly SourceList=/foo/bar-source             

.SS Several items for back-up
readonly SourceList='
.br
/foo/bar
.br
/baz/foo
.br
.B '

.SS Destination directory
readonly DestDir=/foo/bar-dest  # it must contain only one directory name

.SS Log directory
readonly LogDir=/foo/bar-log  # it must contain only one directory name

.SH NOTES
.SS Lastest version
http://dragoman.org/tym

.SS Parameters
tym could be changed to accept the parameters SourceList, DestDir and LogDir in other ways.
Examples:
.br
- configuration file tymconf
.br
- environmet variables tym_src, tym_dest, tym_log

.SS Internal rsync time machine
One might consider implementing time machine functionalities into rsync:
.br
.B rsync ... --tm-source --tm-dest [--tm-log]

.SH AUTHOR
M.T. Carrasco Benitez
.SH WARNINGS
When using a remote machine,
.B ssh
and
.B rsync
each request the remote machine password;
use
.B ~/.ssh
keys to avoid password prompting.
Without the keys, it cannot be run in background.

.B -H
(hardlinks preservation) is not used and
"Without this option, hard-linked files in the transfer are treated as though they were separate files"
[rsync man page].
.B -H
might conflict with
.B --link-dest.
To add hardlinks, in the function
.B Sync
change the string
.B -azhq
to
.B -azhqH.

Simultaneous execution of more than one tym run with the same parameters would probably have unintended results. 
A locking mechanism might be considered.

.SH BUGS
The content of
.B SourceList
must be rsync and Linux safe as it goes into the command line.
Files and directories with blanks and similar character would
probably
.B not
work.
The rsync command line is something like:
.P
.B rsync ... \$SourceList

.SH REPORTING BUGS
ca AT dragoman DOT org
.SH COPYRIGHT
Copyright © 2012 M.T. Carrasco Benitez. License EUPL.  Use at your own risk.
.SH SEE ALSO
rsync(1),
rsyncd.conf(5),
ssh(1)
manpage

 exit 0
}

#================================================#===========================================#
Main $# $0 $*                                    # NoOfArguments ThisFilename ArgumentsList
echo Sentinel-1. It must never come here. ; exit 61
##
