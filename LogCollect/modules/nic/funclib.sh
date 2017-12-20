#you can add specall function here
#Function:		<get_eth_pci_info>
#Description:	get nic pci information 
#Parameter:	NA
#Return:	hba logs
#Since:		driver\logCollect.cfg
#Other:		N/a				
###################################################################
function get_eth_pci_info()
{
    local log_dir="output"
    local ret=0
	#Get nic lspci info
	lspci |grep -i -E "Ethernet|network" >> "${log_dir}"/lspci_eth.txt 2>&1
	if [ 0 -ne $? ]
	then
	    LOG_ERROR "Get ethernet pci info failed."
		ret=1
	else
		LOG_INFO "Get ethernet pci info succeed."
	fi
    return $ret
}

################################################################
#Function:		<get_ethtool_info>
#Description:	get nic info by ethtool 
#Parameter:	NA
#Return:	3008 logs
#Since:		nic\logCollect.cfg 
#Other:		N/a				
###################################################################
function get_ethtool_info()
{
    #Nic config info
    local log_dir="output/ethtool.txt"
    local nic_devices=""
    local device=""

    nic_devices=$(ls /sys/class/net/  2>&1)
    for device in ${nic_devices}
    do
        if [ "${device}" != 'lo' ]
        then             
            run_cmd  "ethtool -i ${device}" "${log_dir}"     
            run_cmd  "ethtool ${device}" "${log_dir}"
            run_cmd  "ethtool -S ${device}" "${log_dir}"
        fi
    done
}

function createdirs()
{
    mkdir -p output/etc/modprobe.d/
    mkdir -p output/etc/sysconfig/
    mkdir -p output/etc/sysconfig/network-scripts/
}

function get_nic_dmesg_info()
{
    local nic_devices=""
    local device=""

    nic_devices=$(ls /sys/class/net/  2>&1)
    local content=$(dmesg)
    for device in ${nic_devices}
    do
        if [ "${device}" != 'lo' ]
        then
            echo "$content" | grep "${device}" >> output/dmesg_eth.txt 2>&1
        fi
    done

}
