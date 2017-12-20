#you can add specall function here
function get_disk_partition_info()
{
   local log_dir="output/parted_disk.txt"
   local ret=0
  
 
   cmd="ls /dev/sd[a-z]"
   result=$(eval "${cmd}" 2>&1)          
   retCode=$? 

   if [ 0 -ne $retCode  ]
   then
       ret=$retCode
       LOG_ERROR "[$cmd] failed.Ret:$retCode. Desc:$result"
       LOG_ERROR "Get disk part info failed."
       ret=1
   else 
       LOG_INFO "[$cmd] successfull."
       for sd in ${result}
       do
           run_cmd "parted ${sd} print" "$log_dir"
           if [ 0 -ne $?  ]
           then
               LOG_ERROR "Get $sd part info failed."
               ret=1
           else
               LOG_INFO "Get $sd part info succeed."
           fi
       done
   fi 

   return $ret
}

################################################################
#Function:		<get_disk_smart_info>
#Description:	get disk smart info
#Parameter:	0£ºok  1: error
#Return:	errocode  0:ok
#Since:		disk\logCollect.cfg 
#Other:		N/a				
###################################################################
function get_disk_smart_info()
{
   local log_dir="output/disk_smart.txt"
   local ret=0
   local did=""
   local inf=""
   local dnum=0
   
    if [ "$(uname -m)" == "x86_64" ]; then
        TOOLS="../../opt/MegaRAID/storcli/storcli64"
    else
        TOOLS="../../opt/MegaRAID/storcli/storcli"
    fi

   #get system LD info
   cmd="ls /dev/sd[a-z]"
   result=$(eval "${cmd}" 2>&1)
   retCode=$?
   if [ 0 -ne $retCode  ]
   then
       ret=$retCode
       LOG_ERROR "[$cmd] failed.Ret:$retCode. Desc:$result"
       LOG_ERROR "Get disk part info failed."
   else
   
       for sd in ${result}
       do
	   local tmpStr=`echo "$sd" | sed 's/[/]/-/g'`
	   logFileName="output/devSmart.$tmpStr"
           run_cmd "smartctl -a ${sd}" "$logFileName"
           if [ 0 -ne $?  ] 
           then
               LOG_ERROR "Get $sd smart info failed."
               ret=1
           else 
               LOG_INFO "Get $sd smart info succeed."
           fi

           #run_cmd "smartctl -a  -d aacraid,H,L,ID ${sd}" "$logFileName"
           #if [ 0 -ne $?  ] 
           #then
            #   LOG_ERROR "Get $sd pmc smart info failed."
             #  ret=1
           #else 
          #     LOG_INFO "Get $sd pmc smart info succeed."
          # fi
           
           #disk num
           dnum=`"${TOOLS}" -ldpdinfo -aall | grep "Device Id:" | wc -l`
           for((i=1;i<=dnum;i++))
           do
               #get did
               did=`"${TOOLS}" -ldpdinfo -aall | grep "Device Id:" | awk '(NR=='$i')' | awk -F": " '{print $2}' | tr -d '\r\n'`
               #get interface:sas,sata
               inf=`"${TOOLS}" -ldpdinfo -aall | grep "PD Type:" | awk '(NR=='$i')' | awk -F": " '{print $2}' | tr -d '\r\n'`
               
               if [ "SAS" == "$inf" ]
               then
                    # error code:2  means invalid cmd
                    smartctl -a --device=megaraid,$did ${sd} >/dev/null
                    if [ 2 -ne "$?" ]
                    then
			local tmpStr2="$tmpStr.DevId$did"
			logFileName="output/devSmart.$tmpStr2"
                        run_cmd "smartctl -a --device=megaraid,$did ${sd}" "$logFileName"
                    fi
               else 
                    smartctl -a --device=sat+megaraid,$did ${sd} >/dev/null
                    if [ 2 -ne "$?" ]
                    then
			local tmpStr2="$tmpStr.DevId$did"
			logFileName="output/devSmart.$tmpStr2"
                        run_cmd "smartctl -a --device=sat+megaraid,$did ${sd}" "$logFileName"
                    fi
               fi
               
           done

       done

    fi
    

   return $ret 
}

