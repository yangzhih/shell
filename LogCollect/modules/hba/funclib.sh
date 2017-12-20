#you can add specall function here
#Function:		<get_fc_wwpn_info>
#Description:	get fc card wwpn information 
#Parameter:	NA
#Return:	hba logs
#Since:		driver\logCollect.cfg
#Other:		N/a				
###################################################################
function get_fc_wwpn_info()
{
    local log_dir="output"
    local ret=0
	
	cmd="ls /sys/class/fc_host/"
	result=$(eval "${cmd}" 2>&1)          
	retCode=$? 	
	
	if [ 0 -ne ${retCode}  ]
	then
	   ret=$retCode
	   LOG_ERROR "[$cmd] failed.Ret:$retCode. Desc:$result"
	   LOG_ERROR "Get fc wwpn info failed."
	else	
		for host in ${result}
		do
			run_cmd "cat /sys/class/fc_host/${host}/port_name" "${log_dir}/wwpn.txt"
			if [ 0 -ne $? ]
			then
				ret=1
				LOG_ERROR "No fc port found or get wwpn info failed."
			fi
		done	
	fi

    return "$ret"
}

################################################################
#Function:		<get_fc_fw_info>
#Description:	get fc card firmware information 
#Parameter:	NA
#Return:	hba logs
#Since:		driver\logCollect.cfg
#Other:		N/a				
###################################################################
function get_fc_fw_info()
{
    local log_dir="output"
    local ret=0
	
	cmd="ls /sys/class/scsi_host/"
	result=$(eval "${cmd}" 2>&1)          
	retCode=$? 	
	
	if [ 0 -ne "${retCode}"  ]
	then
	   ret=$retCode
	   LOG_ERROR "[$cmd] failed.Ret:$retCode. Desc:$result"
	   LOG_ERROR "Get fc fw info failed."
	else	
		for host in ${result}
		do
            run_cmd "cat /sys/class/scsi_host/${host}/fwrev" "${log_dir}/firmware_fc.txt"	
			if [ 0 -ne $? ]
			then
				ret=1
				LOG_ERROR "No fc port found or get fw info failed."
			fi
		done	
	fi

    return "$ret"
}
################################################################
#Function:		<get_fc_driver_info>
#Description:	get fc card driver information 
#Parameter:	NA
#Return:	hba logs
#Since:		driver\logCollect.cfg
#Other:		N/a				
###################################################################
function get_fc_driver_info()
{
    local log_dir="output"
    local ret=0
	
	cmd="ls /sys/class/scsi_host/"
	result=$(eval "${cmd}" 2>&1)          
	retCode=$? 	
	
	if [ 0 -ne "${retCode}"  ]
	then
	   ret=$retCode
	   LOG_ERROR "[$cmd] failed.Ret:$retCode. Desc:$result"
	   LOG_ERROR "Get fc driver info failed."
	else
		for host in ${result}
		do
            run_cmd "cat /sys/class/scsi_host/${host}/lpfc_drvr_version" "${log_dir}/driver_fc.txt"
			if [ 0 -ne $? ]
			then
				ret=1
				LOG_ERROR "No fc port found or get fc driver info failed."
			fi
		done	
	fi

    return "$ret"
}

################################################################
#Function:		<get_fc_pci_info>
#Description:	get fc pci information 
#Parameter:	NA
#Return:	hba logs
#Since:		driver\logCollect.cfg
#Other:		N/a				
###################################################################
function get_fc_pci_info()
{
    local log_dir="output"
    local ret=0
	#Get nic lspci info
	lspci |grep Fibre >> "${log_dir}"/lspci_fc.txt 2>&1
	if [ 0 -ne $? ]
	then
	    LOG_ERROR "Get ethernet pci info failed."
		ret=1
	else
		LOG_INFO "Get ethernet pci info succeed."
	fi    
	return $ret
}

