#!/bin/bash
then=$(sysctl kern.boottime | awk '{print $5}' | sed "s/,//")
now=$(date +%s)
diff=$(($now-$then))

days=$(($diff/86400));
diff=$(($diff-($days*86400)))
hours=$(($diff/3600))
diff=$(($diff-($hours*3600)))
minutes=$(($diff/60))
seconds=$(($diff-($minutes*60)))

function format {
	if [ $1 == 1 ]; then
		echo $1 ' ' $2
	else
		echo $1 ' ' $2's'
	fi
}
echo 'Uptime: '`format $days "day"` `format $hours "hour"` `format $minutes "minute"` `format $seconds "second"`