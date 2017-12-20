#you can add specall function here

function createdirs()
{
   mkdir -p output/etc/ 
   mkdir -p output/var/log/
   mkdir -p output/root/
   mkdir -p output/proc/
   mkdir -p output/proc/self/
   mkdir -p output/boot/
   mkdir -p output/boot/grub/
   mkdir -p output/boot/grub2/
   mkdir -p output/etc/ntp/
   mkdir -p output/proc/net/bonding/
   mkdir -p output/etc/network/
   mkdir -p output/etc/udev/rules.d/
   mkdir -p output/boot/menu/
   return
}

#Function:      <get_reboot_info>
#Description:   get reboot information
#Parameter:     NA
#Return:        reboot info from last logs
#Since:         system\logCollect.cfg
#Other:         N/a
###################################################################
function get_reboot_info()
{
    local log_dir="output"
    local ret=0
    run_cmd "/usr/bin/last -xF | grep 'reboot\|shutdown\|runlevel\|system'" "${log_dir}/command_log.txt"
    if [ 0 -ne $? ]
    then
        ret=1
        LOG_ERROR "Get reboot info from last failed."
    fi

    return "$ret"
}

#Function:		<get_redhat_log>
#Description:	get redhat log by sosreport command
#Parameter:	NA
#Return:	system logs
#Since:		system\logCollect.cfg 
#Other:		N/a				
###################################################################
function get_redhat_log()
{
    local ret=0 
    local log_dir="output"
    cmd="sosreport --batch"

    run_cmd "$cmd"    
    if [ "$?" -eq 0 ]
    then
        run_cmd "mkdir -p  $log_dir/redhat "
        if [ 0 -eq $? ]
        then
            redhatDir="$log_dir/redhat"
        else
            redhatDir="${log_dir}"
        fi

        redhat_log_tbz=$(find /tmp/ -name "sosreport-*.tar.xz" | sort -r | head -1)
        redhat_log_tbz_md5=$(find /tmp/ -name "sosreport-*.tar.xz.md5" | sort -r | head -1)
        run_cmd "mv ${redhat_log_tbz} ${redhatDir}"
        run_cmd "mv ${redhat_log_tbz_md5} ${redhatDir}"
        run_cmd "mv dmraid.ddf1 ${redhatDir}" 
        ret=0
        return ${ret}
    else
        ret=1
        LOG_INFO "sosreport not support or sosreport cmd failed."
    fi

    return ${ret}

}

################################################################
#Function:		<get_suse_log>
#Description:	get suse log by supportconfig command
#Parameter:	NA
#Return:	system logs
#Since:		system\logCollect.cfg 
#Other:		N/a				
###################################################################
function get_suse_log()
{
    local ret=0 
    local log_dir="output"
    run_cmd "supportconfig -Q"
    if [ "$?" -eq 0 ]
    then
        run_cmd "mkdir -p  $log_dir/suse"
        if [ 0 -eq $? ]
        then
            suseDir="$log_dir/suse"
        else
            suseDir="${log_dir}"
        fi

        suse_tbz=$(find /var/log/ -name "nts_$(hostname)*.tbz" | sort -r | head -1)
        suse_tbz_md5=$(find /var/log/ -name "nts_$(hostname)*.tbz.md5" | sort -r | head -1)
        
        run_cmd "mv ${suse_tbz} ${suseDir}"     
        run_cmd "mv ${suse_tbz_md5} ${suseDir}"  
        ret=0
        return ${ret}
    else
        ret=1
        LOG_INFO "supportconfig not support or supportconfig failed."
    fi 

    return ${ret}
   

}

################################################################
#Function:		<get_messages_log>
#Description:	get messages log in 7 days
#Parameter:	NA
#Return:	messages logs
#Since:		/var/log/ 
#Other:		N/a				
###################################################################
function get_messages_log()
{
    local start_time=$(date --date='7 days ago' +%Y%m%d)
    local basedir="/var/log/"
	local log_dir="output/var/log/"
    local flist=$(ls $basedir|grep message)
	
	for file in $flist
	do
		if [ $file = "messages" ]
		then
			cp $basedir$file $log_dir
        else
            subtime=$(basename $file|awk -F"-" '{print $2}'|awk -F"." '{print $1}')
			if [ $subtime -gt $start_time ]
			then
				cp $basedir$file $log_dir
			fi
        fi
	done
        
    return 0
   
}

function get_mail_log()
{
    local start_time=$(date --date='7 days ago' +%Y%m%d)
    local basedir="/var/log/"
	local log_dir="output/var/log/"
    local flist=$(ls $basedir|grep maillog)
	
	for file in $flist
	do
		if [ $file = "maillog" ]
		then
			cp $basedir$file $log_dir
        else
            subtime=$(basename $file|awk -F"-" '{print $2}'|awk -F"." '{print $1}')
			if [ $subtime -gt $start_time ]
			then
				cp $basedir$file $log_dir
			fi
        fi
	done
        
    return 0
   
}

function get_cron_log()
{
    local start_time=$(date --date='7 days ago' +%Y%m%d)
    local basedir="/var/log/"
	local log_dir="output/var/log/"
    local flist=$(ls $basedir|grep cron)
	
	for file in $flist
	do
		if [ $file = "cron" ]
		then
			cp $basedir$file $log_dir
        else
            subtime=$(basename $file|awk -F"-" '{print $2}'|awk -F"." '{print $1}')
			if [ $subtime -gt $start_time ]
			then
				cp $basedir$file $log_dir
			fi
        fi
	done
        
    return 0
   
}

function get_secure_log()
{
    local start_time=$(date --date='7 days ago' +%Y%m%d)
    local basedir="/var/log/"
	local log_dir="output/var/log/"
    local flist=$(ls $basedir|grep secure)
	
	for file in $flist
	do
		if [ $file = "secure" ]
		then
			cp $basedir$file $log_dir
        else
            subtime=$(basename $file|awk -F"-" '{print $2}'|awk -F"." '{print $1}')
			if [ $subtime -gt $start_time ]
			then
				cp $basedir$file $log_dir
			fi
        fi
	done
        
    return 0
   
}