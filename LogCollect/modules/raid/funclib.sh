#you can add specall function here
#Function:		<get_sas_raid_log>
#Description:	get lsi3108/2208 log file 
#Parameter:	NA
#Return:	logs
#Since:		logCollect.cfg
#Other:		N/a				
#only for raid
###################################################################
function get_storage_info()
{
    local TOOLS=""
    #local adpCnt=0
    local log_file="output/sasraidlog.txt"


    if [ "$(uname -m)" == "x86_64" ]; then
        TOOLS="../../opt/MegaRAID/storcli/storcli64"
        megacli="RAIDtool/MegaCli/MegaCli64"
    else
        TOOLS="../../opt/MegaRAID/storcli/storcli"
        megacli="RAIDtool/MegaCli/MegaCli"
    fi

    run_cmd "$TOOLS -AdpAllInfo -aALL" "output/storcliAdpAllInfo"
    run_cmd "$TOOLS -PDList -aALL" "output/storcliPDList"
    run_cmd "$megacli -LDInfo -Lall -aALL " "output/MegaCliLDInfo"
}

 function get_sas_raid_log()
 {  
	local TOOLS=""
	#local adpCnt=0
	local log_file="output/sasraidlog.txt"


    if [ "$(uname -m)" == "x86_64" ]; then
        TOOLS="../../opt/MegaRAID/storcli/storcli64"
    else
        TOOLS="../../opt/MegaRAID/storcli/storcli"
    fi
    
    #adpCnt=`$TOOLS -AdpAllinfo -aALL | grep -i "device id" | wc -l`
    run_cmd "$TOOLS /call/vall show all" "output/storcliVallShowAll"
    #run_cmd "$TOOLS -AdpAllInfo -aALL" "output/storcliAdpAllInfo"
    #run_cmd "$TOOLS -PDList -aALL" "output/storcliPDList"
    #event log is part of alilog.
    run_cmd "$TOOLS -adpalilog -aALL" "output/storcliAdpalilog"

    run_cmd "$TOOLS -adpbbucmd -aALL" "output/storcliAdpbbucmd"

    run_cmd "$TOOLS /call/pall show all" "output/storcliPallShowAll"
    return 0
}

################################################################
#Function:		<get_lsi2308_log>
#Description:	get lsi2308 log file 
#Parameter:	NA
#Return:	2308 logs
#Since:		logCollect.cfg
#Other:		N/a				
###################################################################
function get_lsi2308_log()
{
    local sas2ircu="RAIDtool/2308/sas2ircu"
    local sas2flash="RAIDtool/2308/sas2flash"
    local log_file="output/sashbalog.txt"
    local adpCnt=$($sas2ircu LIST | grep "^ *[0-9]" | awk '{print $4}' | grep "87h\|86h" | wc -l)
  
    for((adpNum=0;adpNum<adpCnt;adpNum++))
    do
        run_cmd "${sas2ircu} ${adpNum} display" "${log_file}"
 
        run_cmd "${sas2flash} -c $adpNum -list" "$log_file"

        run_cmd "${sas2ircu} ${adpNum} status" "${log_file}"
 
        run_cmd "${sas2ircu} ${adpNum} logir upload" "${log_file}"
    done

    if [ -f "logir.log" ]	
    then
        run_cmd "rm -rf logir.log"
    fi
	
    return 0


}

################################################################
#Function:		<get_lsi3008_log>
#Description:	get lsi3008 log file 
#Parameter:	NA
#Return:	3008 logs
#Since:		logCollect.cfg
#Other:		N/a				
###################################################################
function get_lsi3008_log()
{
    local sas3ircu="RAIDtool/3008/sas3ircu"
    local sas3flash="RAIDtool/3008/sas3flash"
    local log_file="output/sashbalog.txt"
    local adpCnt=`$sas3ircu LIST | grep "SAS3008" | grep -v "Adapter" | wc -l`

    for((adpNum=0;adpNum<adpCnt;adpNum++))
    do
        
        run_cmd "${sas3ircu} $adpNum display" "$log_file"

        run_cmd "${sas3flash} -c $adpNum -list" "$log_file"

        run_cmd "${sas3ircu}  $adpNum status" "$log_file"

        run_cmd "${sas3ircu}  $adpNum logir upload" "$log_file"
    done

    if [ -f "logir.log" ]
    then
        run_cmd "rm -rf logir.log"
    fi
	
    return 0

}

function get_megaraid_log()
{
    local megacli=""
    if [ "$(uname -m)" == "x86_64" ]; then
        megacli="RAIDtool/MegaCli/MegaCli64"
    else
        megacli="RAIDtool/MegaCli/MegaCli"
    fi
 
    ###########################################################
    #Adapter Commands
    #run_cmd "$megacli -AdpAliLog -aALL" "output/MegaCliAdpAliLog"
    run_cmd "$megacli -FwTermLog Dsply -aALL" "output/MegaCliFwTermLog"
    run_cmd "$megacli -AdpEventLog -GetEventlogInfo -aALL" "output/MegaCliAdpEventLogGetEventlogInfo"
    run_cmd "$megacli -FwTermLog Dsply -aALL" "output/MegaCliFwTermLog"

    run_cmd "$megacli -AdpEventLog -GetEvents -f output/MgEvtLog -aALL"
    run_cmd "$megacli -AdpEventLog -GetSinceShutdown -f output/MegaCliAdpEvtLogGetSinceShutdown  -aALL"
    run_cmd "$megacli -AdpEventLog -GetSinceReboot -f output/MegaCliAdpEvtLogGetSinceReboot.log  -aALL"
    #$megacli -AdpEventLog -IncludeDeleted -f output/MegaCliAdpEvtLogIncludeDeleted.log  -aALL
    run_cmd "$megacli -AdpEventLog -GetLatest 50 -f output/MegaCliAdpEvtLogLatest50 -aALL"

    #Display Adapter Information
    #run_cmd "$megacli -AdpAllInfo -aALL" "output/MegaCliAdpAllInfo"
    #Enable or Disable Automatic Rebuild"
    run_cmd "$megacli -AdpAutoRbld -Dsply -aALL" "output/MegaCliAdpAutoRbldDsply"
    #Display Specified Adapter Properties"
    for option in `cat opt.txt`
    do
        run_cmd "$megacli -AdpGetProp $option -aALL " "output/MegaCliAdpPropoptions"
    done
    #Display Adapter Time
    n=$($megacli -adpCount | grep 'Controller Count' | awk '{print $3}' | sed 's/\.//g')
    if [ $n -gt 0 ]
    then
      let n=n-1
      for i in `seq 0 $n`
      do
        run_cmd "$megacli -AdpGetTime -a$i " "output/MegaCliAdpTime"
      done
    fi
    
    run_cmd "$megacli -AdpGetTime -aAll " "output/MegaCliAdpTime"
    ###########################################################
    #BIOS Commands
    #Set or Display Bootable Logical Drive ID"
    run_cmd "$megacli -AdpBootDrive -Get -aALL " "output/MegaCliAdpBootDrive"
    #Set BIOS Options
    run_cmd "$megacli -AdpBIOS -Dsply -aALL " "output/MegaCliAdpBIOSDsply"
    
    ###########################################################
    #Configuration Commands
    #Display Existing Configuration
    run_cmd "$megacli -CfgDsply -aALL" "output/MegaCliCfgDsply"
    #Save Adapter Configuration
    n=$($megacli -adpCount | grep 'Controller Count' | awk '{print $3}' | sed 's/\.//g')
    if [ $n -gt 0 ]
    then
      let n=n-1
      for i in `seq 0 $n`
      do
        run_cmd "$megacli -CfgSave -f infos/MegaCliAdapterConfiguration$i -a$i > /dev/null"
      done
    fi
    #Display Free Space
    run_cmd "$megacli -CfgFreeSpaceInfo -aALL " "output/MegaCliCfgFreeSpaceInfo"
    
    ###########################################################
    #Logical Drive Commands
    #Display Logical Drive Information
    #run_cmd "$megacli -LDInfo -Lall -aALL " "output/MegaCliLDInfo"
    #Display Logical Drive Disk Cache Settings
    run_cmd "$megacli -LDGetProp -DskCache -Lall -aALL" "output/MegaCliLDPropDskCache"
    #Manage Logical Drive Initialization
    run_cmd "$megacli -LDInit -ShowProg -Lall -aALL " "output/MegaCliLDInitShowProg"
    run_cmd "$megacli -LDInit -ProgDsply -Lall -aALL " "output/MegaCliLDInitProgDsply"
    #Manage Consistency Check
    run_cmd "$megacli -LDCC -ShowProg -Lall -aALL " "output/MegaCliLDCCShowProg"
    run_cmd "$megacli -LDCC -ProgDsply -Lall -aALL " "output/MegaCliLDCCProgDsply"
    #View Ongoing Background Initialization
    run_cmd "$megacli -LDBI -GetSetting -Lall -aALL " "output/MegaCliLDBIGetSetting"
    run_cmd "$megacli -LDBI -ShowProg -Lall -aALL " "output/MegaCliLDBIShowProg"
    #Display Logical Drive and Physical Drive Information
    run_cmd "$megacli -LDPDInfo -aALL" "output/MegaCliLDPDInfo"
    #Display Number of Logical Drives
    run_cmd "$megacli -LDGetNum -aALL" "output/MegaCliLDNum"
    
    ###########################################################
    run_cmd "$megacli -EncInfo -aALL" "output/MegaCliEncInfo"
    run_cmd "$megacli -PhyErrorCounters -aALL" "output/MegaCliPhyErrorCounters"
    ###########################################################"
    
    #Display Number of Physical Disk Drives
    run_cmd "$megacli -PDGetNum -aALL " "output/MegaCliPDNum"
    #Display List of Physical Drives
    #run_cmd "$megacli -PDList -aAll " "output/MegaCliPDList"
    return
}

function get_pmc_info()
{
   local arcconf=""
    if [ "$(uname -m)" == "x86_64" ]; then
        arcconf="RAIDtool/Arcconf-Linux/arcconf-x64"
    else
        arcconf="RAIDtool/Arcconf-Linux/arcconf-x86"
    fi
   run_cmd "./$arcconf savesupportarchive > output/pmc_tool_run.log"
   if [ -e /var/log/Support ]
   then
      run_cmd "tar czf support.tar.gz -C /var/log Support"
      run_cmd "mv support.tar.gz output/"
   fi
}
