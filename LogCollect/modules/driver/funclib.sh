#you can add specall function here
#Function:		<get_module_info>
#Description:	get modue info log 
#Parameter:	NA
#Return:	3008 logs
#Since:		driver\logCollect.cfg
#Other:		N/a				
###################################################################
function get_module_info()
{
    local log_dir="output/modinfo.txt"
    local ret=0
    local cmd
    lsmod | awk '{
                    if(NR!=1)
                    {
                        print "modinfo " $1; 
                        print "{";
                        cmd = sprintf("modinfo %s",$1);
                        system(cmd);
                        print "}";
                    }
                }' >> "$log_dir"   
    ret=$?
    if [ "${ret}" -eq 0 ]; then
        LOG_INFO "Get modinfo success"
    else
        LOG_ERROR "Get modinfo fail and exitCode is ${ret}"
    fi

    return "$ret"
}

