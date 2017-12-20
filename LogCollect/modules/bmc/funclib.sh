#//::+------------------------------------------------------------------------------------------+
#//::| The RdPCIConfigLocal() command provides sideband read access to the PCI                  |
#//::| configuration space that resides within the processor. This includes all processor IIO   |
#//::| and uncore registers within the PCI configuration space as described in the              |
#//::| Intel?Xeon? Processor E5/E7 v3 Product Family External Design Specification (EDS),       |
#//::| Volume Two: Registers document.                                                          |
#//::|                                                                                          |
#//::| Usage:                                                                                   |
#//::|   RdPCIConfigLocal cpu bus dev fun reg name                                              |
#//::|                                                                                          |
#//::|   cpu - CPU index(0 ~ 8)                                                                 |
#//::|   bus - Bus number(0 or 1)                                                               |
#//::|   dev - Device number(0 ~ 31)                                                            |
#//::|   fun - Function number(0 ~ 7)                                                           |
#//::|   reg - Register offset(0 ~ 0xFFF)                                                       |
#//::|   name - Register name                                                                   |
#//::+------------------------------------------------------------------------------------------+
function RdPCIConfigLocal()
{
    local cpu=$1
    local bus=$2
    local dev=$3
    local fun=$4
    local reg=$5
    local regName=$6
    local ouputFile=$7

    local client_address
    ((client_address = cpu+0x30))
    local write_len="0x05";
    local read_len="0x05";
    local cmd_code="0xe1";
    local host_id="0x0";
    local PCA 
    let "PCA = (bus<<20)|(dev<<15)|(fun<<12)|(reg)"

    local pca0 
    let "pca0=(PCA)&0xff"
    local pca1 
    let "pca1=(PCA>>8)&0xff"
    local pca2 
    let "pca2=(PCA>>16)&0xff"
    local ipmicmd="$PECI_RAW_CMD_PRE $client_address $write_len $read_len $cmd_code $host_id $pca0 $pca1 $pca2"
    local outStrPre=`printf "(Bus:%-2s Dev:%-2s Fun:%-2s Reg:%-6s) CPU%s %-20s" "$bus" "$dev" "$fun" "$reg" "$cpu" "$regName"`
    #LOG_INFO "$outStrPre[$ipmicmd]"
    #echo "$outStrPre"
    sendMEIPMIWithRetry "$ipmicmd" "$ouputFile" "$outStrPre" 3
#    cmdline<<QString("%1").arg(client_address)
#            <<QString("%1").arg(write_len)
#            <<QString("%1").arg(read_len)
#            <<QString("%1").arg(cmd_code)
#            <<QString("%1").arg(host_id)
#            <<QString("%1").arg(pca0)
#            <<QString("%1").arg(pca1)
#            <<QString("%1").arg(pca2);

    #sendMEIPMIWithRetry
    return 0;
}

#//::+------------------------------------------------------------------------------------------+
#//::| The RdIAMSR() PECI command provides read access to the Machine Check Bank                |
#//::| Model Specific Registers (MSRs) defined in the processor’s Intel® Architecture (IA).     |
#//::| MSR definitions may be found in the Intel®Xeon® Processor E5/E7 v3 Product Family        |
#//::| External Design Specification (EDS), Volume Two: Registers.                              |
#//::|                                                                                          |
#//::| Usage:                                                                                   |
#//::|   RdIAMSR cpu processor reg name                                                         |
#//::|                                                                                          |
#//::|   cpu - CPU index(0 ~ 8)                                                                 |
#//::|   processor - processor ID                                                               |
#//::|   reg - Register offset(0 ~ 0xFFFF)                                                      |
#//::|   name - Register name                                                                   |
#//::+------------------------------------------------------------------------------------------+
function RdIAMSR()
{
    local cpu=$1
    local processor=$2
    local reg=$3
    local regName=$4
    local ouputFile=$5
    local client_address
    ((client_address=cpu+0x30))
    local write_len="0x05";
    local read_len="0x09";
    local cmd_code="0xb1";
    local host_id="0x0";
    local lsb
    let "lsb=(reg)&0xff"
    local msb
    let "msb=(reg>>8)&0xff"

 #   //::echo %PECI_RAW_CMD% %client_address% %write_len% %read_len% %cmd_code% %host_id% %processor% %lsb% %msb%
 #   //set /p=cpu%cpu% %name% <nul
 #   //%PECI_RAW_CMD% %client_address% %write_len% %read_len% %cmd_code% %host_id% %processor% %lsb% %msb%
    local ipmicmd="$PECI_RAW_CMD_PRE $client_address $write_len $read_len $cmd_code $host_id $processor $lsb $msb"
    local outStrPre=`printf "CPU%s_Proc%-2s %-20s" "$cpu" "$processor" "$regName"`
    #LOG_INFO "$outStrPre[$ipmicmd]"
    sendMEIPMIWithRetry "$ipmicmd" "$ouputFile" "$outStrPre" 3
    return 0;
}


PECI_INFO_MODE_CSR="0"
PECI_INFO_MODE_MSR="1"
CPU_PLATFORM_HASWELL="0"
CPU_PLATFORM_IVB="1"
CPU_PLATFORM_ROMLEY="2"
cpuPlatform=$CPU_PLATFORM_HASWELL
maxThreadID=12
function getMEPECIInfo()
{
    LOG_INFO "getMEPECIInfo cpuplatform:$cpuPlatform"
    if [ "$cpuPlatform" == "$CPU_PLATFORM_HASWELL" ] ; then
        echo "Parsed CPU Platform is Hasswell or Broadwell"
        getPECIInfoByMode "config/hsx_csr.txt" "$bmcLogPath/hsx_csr.txt" "$PECI_INFO_MODE_CSR"
        getPECIInfoByMode "config/hsx_msr.txt" "$bmcLogPath/hsx_msr.txt" "$PECI_INFO_MODE_MSR"
    elif [ "$cpuPlatform" == "$CPU_PLATFORM_IVB" ] ; then 
        echo "Parsed CPU Platform is IVB"  
        getPECIInfoByMode "config/ivt_csr.txt" "$bmcLogPath/ivt_csr.txt" "$PECI_INFO_MODE_CSR"
        getPECIInfoByMode "config/ivt_msr.txt" "$bmcLogPath/ivt_msr.txt" "$PECI_INFO_MODE_MSR"    
    elif [ "$cpuPlatform" == "$CPU_PLATFORM_ROMLEY" ] ; then 
        echo "Parsed CPU Platform is Romley"     
        getPECIInfoByMode "config/ivt_csr.txt" "$bmcLogPath/ivt_csr.txt" "$PECI_INFO_MODE_CSR"
        getPECIInfoByMode "config/romley_msr.txt" "$bmcLogPath/romley_msr.txt" "$PECI_INFO_MODE_CSR"
    else
        echo "Invalid CPU Platform: $cpuPlatform"
        return -1;
    fi

    return 0;
}


function getPECIInfoByMode
{
    local configFile=$1
    local outputFileName=$2
    local peciInfoMode=$3

    #echo "getPECIInfoByMode:$configFile $outputFileName $peciInfoMode maxThreadID:$maxThreadID"

    local socketIndex=0
    for((socketIndex = 0; socketIndex < 8; socketIndex++))
    do
        cat "output/mespec_pingcpu${socketIndex}.txt" | grep "57 01 00" > /dev/null
        if [ $? -ne 0 ] ; then
            LOG_INFO "CPU$socketIndex cannot ping!"
            continue
        fi

        cat "output/mespec_pingcpu${socketIndex}.txt" | grep "Unable" > /dev/null
        if [ $? -eq 0 ] ; then
            LOG_INFO "CPU$socketIndex cannot ping!"
            continue
        fi

        cat "output/mespec_pingcpu${socketIndex}.txt" | grep "Unknown" > /dev/null
        if [ $? -eq 0 ] ; then
            LOG_INFO "CPU$socketIndex cannot ping!"
            continue
        fi

        local line
        local lines=`cat $configFile | grep -v "#"`
        echo "$lines" | while read line
        do
            if [ "$line" == "" ]
            then
                continue
            fi

            echo $configFile | grep "csr" > /dev/null
            if [ $? -eq 0 ] ; then
                local bus=`echo "$line" | awk -F" " '{print $1}' |  sed 's/ //g'`
                local dev=`echo "$line" | awk -F" " '{print $2}' |  sed 's/ //g'`
                local fun=`echo "$line" | awk -F" " '{print $3}' |  sed 's/ //g'`
                local reg=`echo "$line" | awk -F" " '{print $4}' |  sed 's/ //g'`
                local name=`echo "$line" | awk -F" " '{print $5}' |  sed 's/ //g' | sed 's/[\r\n]//g' | sed 's/\n//g'`
              
                RdPCIConfigLocal $socketIndex $bus $dev $fun $reg $name $outputFileName 
            fi

            echo $configFile | grep "msr" > /dev/null
            if [ $? -eq 0 ] ; then
                local tmpMaxThreadId=1
                local reg=`echo "$line" | awk -F" " '{print $1}' |  sed 's/ //g' `
                local name=`echo "$line" | awk -F" " '{print $2}' |  sed 's/ //g' | sed 's/[\r\n]//g' | sed 's/\n//g'`
                #echo "test--$name--"
                #local corebased=`echo "$line" | awk -F" " '{print $3}' |  sed 's/ //g' | sed 's/[ \t]*$//g' `
                echo "$line" | grep "YES" > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    let "tmpMaxThreadId = maxThreadID+1"
                else
                    let "tmpMaxThreadId = 1"
                fi

                local i=0
                for((i=0; i<tmpMaxThreadId; i++))
                do
                    #echo "RdIAMSR $socketIndex $i $reg $outputFileName"
                    RdIAMSR $socketIndex $i $reg $name $outputFileName
                done
            fi

        done

    done

    return 0;
}


function CheckMEIpmiActive()
{
    local retry=0;
    for((retry=0; retry<5; retry++))
    do
        #${ipmitool} "-b 6 -t 0x2c raw 0x06 0x04" > /dev/null 2>&1
        #echo "${ipmitool} -b 6 -t 0x2c raw 0x06 0x04"
        ${ipmitool} -b 6 -t 0x2c raw 0x06 0x04 > /dev/null 2>&1
        if [ $? -eq 0 ] ; then
            MEChannel=6
            ME_RAW_CMD_PRE="${ipmitool} -b $MEChannel -t 0x2c "
            PECI_RAW_CMD_PRE="${ipmitool} -b $MEChannel -t 0x2c raw 0x2e 0x40 0x57 0x01 0x00 "
            return 0
        fi
    done

    for((retry=0; retry<5; retry++))
    do
        #${ipmitool} "-b 0 -t 0x2c raw 0x06 0x04" > /dev/null 2>&1
        ${ipmitool} -b 0 -t 0x2c raw 0x06 0x04 > /dev/null 2>&1
        if [ $? -eq 0 ] ; then
            MEChannel=0
            ME_RAW_CMD_PRE="${ipmitool} -b $MEChannel -t 0x2c "
            PECI_RAW_CMD_PRE="${ipmitool} -b $MEChannel -t 0x2c raw 0x2e 0x40 0x57 0x01 0x00"
            return 0
        fi
    done

    return 255;
}


function getPECICommonInfo()
{
    local configFile=$1
    local lines=`cat $configFile 2>/dev/null | grep -v "#" `
    echo "$lines" | while read line
    do
        if [ "$line" == "" ]
        then
            continue
        fi

        local cmdStr=`echo "$line" | awk -F">" '{print $1}' |  sed 's/[ \t]*$//g' `
        local outputFile=`echo "$line" | awk -F">" '{print $2}' | awk -F"/" '{print $2}' | sed 's/[ \t]*$//g' `
        outputFile="output/$outputFile"
        sendIPMIWithRetry "${ME_RAW_CMD_PRE} $cmdStr" "$outputFile" 3
    done
    return 0;
}

function sendIPMIWithRetry()
{
    local ipmicmd=$1
    local outputFile=$2
    local retry=$3
    local res=""
    local i=0
    local retCod=255
    if [ "$retry" == "" ] ; then
        let retry=3
    fi

    for((i=0;i<retry;i++))
    do
        LOG_INFO "$ipmicmd > $outputFile 2>&1"
        $ipmicmd > $outputFile 2>&1
        if [ $? -eq 0 ] ; then 
            let retCod=0
            break;
        fi
    done

    return $retCod
}

function sendMEIPMIWithRetry()
{
    local ipmicmd=$1
    local outputFile=$2
    local outStrPre="$3"
    local retry=$4
    local res=""
    local i=0
    if [ "$retry" == "" ] ; then
        let retry=3
    fi

    #sleep 0.001

    for((i=0;i<retry;i++))
    do
        res=`$ipmicmd`
        echo "$res" | grep "57 01 00 40" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break;
        fi
        echo "$res" | grep "57 01 00 90" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break;
        fi
        echo "$res" | grep "57 01 00 91" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break;
        fi
        echo "$res" | grep "57 01 00 92" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break;
        fi
        echo "$res" | grep "57 01 00 93" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break;
        fi
        echo "$res" | grep "57 01 00 94" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            break;
        fi
        LOG_INFO "$outStrPre[$ipmicmd] [$res]###Retry $i###"
        sleep 0.05
    done

	res=`echo $res | sed 's/Data length = b//g'`
    LOG_INFO "$outStrPre[$ipmicmd]"
    printf "%-40s %s\n" "$outStrPre" "$res"| tee -a "$outputFile"
}

PECI_GETCPUID_RES_FILE="mespec_cpuid.txt"
PECI_MAXTHREADID_RES_FILE="mespec_maxthreadid0.txt"
PECI_CPUID_HASSWELL=0x000306f0
PECI_CPUID_BROADWELL=0x000406f0
PECI_CPUID_IVB=0x000306e0
PECI_CPUID_MASK=0x07ff1ff0


function CheckCPUPlatForm()
{
    local filename="output/$PECI_GETCPUID_RES_FILE"

    local peciRes=`cat $filename | grep "57 01 00 40"`
    if [ "$peciRes" == "" ] ;then
        echo "CPU Platform parse failed, set to default HASWELL!"
        cpuPlatform="$CPU_PLATFORM_HASWELL"
        return 0
    fi

    local data0=`echo $peciRes | awk -F" " '{print $5}'`
    local data1=`echo $peciRes | awk -F" " '{print $6}'`
    local data2=`echo $peciRes | awk -F" " '{print $7}'`
    local data3=`echo $peciRes | awk -F" " '{print $8}'`

    local data="0x${data3}${data2}${data1}${data0}"
    local cpuid
    let "PECI_CPUID_HASSWELL=0x000306f0&$PECI_CPUID_MASK"
    let "PECI_CPUID_BROADWELL=0x000406f0&PECI_CPUID_MASK"
    let "PECI_CPUID_IVB=0x00030630&$PECI_CPUID_MASK"
    let "cpuid=$data&$PECI_CPUID_MASK"
    
    if [ $cpuid -eq $PECI_CPUID_HASSWELL ] ; then
        cpuPlatform="$CPU_PLATFORM_HASWELL"
    elif [ $cpuid -eq $PECI_CPUID_BROADWELL ] ; then
        cpuPlatform="$CPU_PLATFORM_HASWELL"
    elif [ $cpuid -eq $PECI_CPUID_IVB ] ; then
        cpuPlatform="$CPU_PLATFORM_IVB"
    else
        cpuPlatform="$CPU_PLATFORM_HASWELL"
    fi

    #echo "CheckCPUPlatForm:$cpuid==$PECI_CPUID_HASSWELL/$PECI_CPUID_BROADWELL/$PECI_CPUID_IVB? cpuPlatform:$cpuPlatform"
    LOG_INFO "CheckCPUPlatForm:$cpuid==$PECI_CPUID_HASSWELL/$PECI_CPUID_BROADWELL/$PECI_CPUID_IVB? cpuPlatform:$cpuPlatform"

}

function CheckMaxThreadID()
{
    filename="output/$PECI_MAXTHREADID_RES_FILE"
    local peciRes=`cat $filename | grep "57 01 00 40"`
    if [ "$peciRes" == "" ] ;then
        LOG_INFO "Max ThreadID parse failed, set to default 12!"
        cpuPlatform="$CPU_PLATFORM_HASWELL"
        return 0
    fi

    local data0=`echo $peciRes | awk -F" " '{print $5}'`
    local data1=`echo $peciRes | awk -F" " '{print $6}'`
    local data2=`echo $peciRes | awk -F" " '{print $7}'`
    local data3=`echo $peciRes | awk -F" " '{print $8}'`

    local data="0x${data3}${data2}${data1}${data0}"
    ((maxThreadID=data))

    if [ $maxThreadID -gt 255 ] ; then
        LOG_INFO "Max ThreadID parse invalid $maxThreadID, set to default 12!"
        maxThreadID=12
    fi

    LOG_INFO "CheckMaxThreadID raw:$data; maxThreadID:$maxThreadID"
}


function getpecilog()
{
    #echo "Come in getpecilog"
    CheckMEIpmiActive
    if [ $? -ne 0 ] ; then
        echo "Try to access ME failed!!!!"
        return 255
    fi

    getPECICommonInfo "config/cmd.list"
    CheckCPUPlatForm
    CheckMaxThreadID
    getMEPECIInfo
}


function getbmcservestatus()
{
    for i in "0x00" "0x01" "0x02" "0x03" "0x04" "0x05" "0x06" "0x07"
    do
        run_cmd "${ipmitool} raw 0x32 0x69 $i 0x00 0x00 0x00" "output/bmcservicestatus"
    done
    return
}

function getbmcreg()
{
#run under local system only
    if [ "$ipmitool" == "ipmitool" ]
    then
        run_cmd "./lxRW/lxRW_x64 p2a dump 1e600000 190000" "output/bmcreg"
    fi
    return
}

function get_hapi_status()
{
    if [ $# -lt 2 ]
    then
        LOG_INFO "web access failed, $bmcip:$2"
        return 255  
    fi
    HAPI_STATUS=`echo $1 |awk -F  'HAPI_STATUS:' '{print $2}' |awk -F  ' ' '{print $1}' `
    if [ -z "$HAPI_STATUS" ]
    then
        LOG_INFO "$bmcip:$2 failed!!"
        return 255
    fi  

    if [ $HAPI_STATUS -ne 0 ]
    then
        LOG_INFO "$bmcip:$2 failed with HAPI_STATUS $HAPI_STATUS!!"
        return 255  
    fi

    LOG_INFO "$bmcip:$2 success."
    return 0
}

bmcLogPath="output/logs"
bmcJasonResPath="output/logsJasonRes"
cookie=""
CSRFtoken=""
WEB_ACCESS_TIMEOUT="10"
function web_login()
{
    local bmcip="$1"
    local bmcuser="$2"
    local bmcpassword="$3"
    local webres=`curl --cookie-jar cookies --max-time $WEB_ACCESS_TIMEOUT -X POST  --data "WEBVAR_USERNAME=$bmcuser&WEBVAR_PASSWORD=$bmcpassword"  http://$bmcip/rpc/WEBSES/create.asp 2>/dev/null`
    local res=`echo $webres | awk -F 'SESSION_COOKIE' '{print $2}'`
    get_hapi_status "$res" "$bmcip: web login "
    if [ $? -ne 0 ]
    then
        return 255
    fi

    local SessionCookie=`echo $res | awk -F ''\''' '{print $3}'`
    CSRFtoken=`echo $webres | awk -F 'CSRFTOKEN' '{print $2}' | awk -F ''\''' '{print $3}'`
    cookie=`echo "BMC_IP_ADDR=$bmcip; test=1; SessionCookie=$SessionCookie; CSRFtoken=$CSRFtoken;"`

    res=`echo $cookie | grep Failure`
    if [ -n "$res" ]
    then
        LOG_INFO "$bmcip:web access failed with check cookie failed!"
        return 255
    fi

    LOG_INFO "$bmcip:web log in success"
    return 0
}

function web_logout()
{
    local bmcip="$1"
    local bmcuser="$2"
    local bmcpassword="$3"

    local res=`curl --cookie "$cookie" --max-time $WEB_ACCESS_TIMEOUT  -H "CSRFtoken: $CSRFtoken" http://$bmcip/rpc/WEBSES/logout.asp 2>/dev/null`
    get_hapi_status "$res" "$bmcip:web log out "
    if [ $? -ne 0 ]
    then
        return 255
    fi

    #LOG_INFO "$bmcip:web log out success"
    return 0
}

function web_get_request()
{
    local bmcip="$1"
    local bmcuser="$2"
    local bmcpassword="$3"
    local aspReqPath="$4"

    local res=`curl --cookie "$cookie" --max-time $WEB_ACCESS_TIMEOUT -H "CSRFtoken: $CSRFtoken" http://$bmcip/rpc/$aspReqPath 2>/dev/null`
    get_hapi_status "$res" "$bmcip:web req $aspReqPath "
    if [ $? -ne 0 ]
    then
        return 255
    fi

    #LOG_INFO "$bmcip:web req $aspReqPath success"
    return 0
}

function web_get_logs()
{
    local bmcip="$1"
    local bmcuser="$2"
    local bmcpassword="$3"
    local logPath="$4"
    local logName="$5"
    #curl --cookie "$cookie" --max-time $WEB_ACCESS_TIMEOUT  http://$bmcip$logPath -o $bmcLogPath/$logName
    local res=`curl --cookie "$cookie" -H "CSRFtoken: $CSRFtoken" --max-time $WEB_ACCESS_TIMEOUT  http://$bmcip$logPath -o $bmcLogPath/$logName  2>/dev/null`
    get_hapi_status "$res" "$bmcip:web get info [$logPath] "
    if [ $? -ne 0 ]
    then
        return 255
    fi
    #LOG_INFO "$bmcip:web get info [$logPath] success"
    return 0
}

jsonAspListFile="jason.list"
function web_get_jason_list()
{
    local bmcip="$1"
    local bmcuser="$2"
    local bmcpassword="$3"
    local logPath="$4"
    local logName="$5"
    local lines=`cat $jsonAspListFile 2>/dev/null | grep -v "#"`
    #echo "******$lines"
    local line=""
    echo "$lines" | while read line
    do
        local aspReq=`echo $line`
        #echo "test=###$aspReq==$line=$CSRFtoken=*****curl --cookie "$cookie" -H "CSRFtoken: $CSRFtoken" --max-time 3  http://$bmcip/rpc/$aspReq+++++"
        local res=`curl --cookie "$cookie" -H "CSRFtoken: $CSRFtoken" --max-time 3  http://$bmcip/rpc/$aspReq 2>/dev/null`
        get_hapi_status "$res" "$bmcip:web get info [$aspReq] "
#        if [ $? -ne 0 ]
  #      then
   #         return 255
   #     fi
        echo "$res" > "$bmcJasonResPath/$aspReq"
    done

    #LOG_INFO "$bmcip:web get info [$aspReq] success"
    return 0
}

parseBlackboxTool="./blackbox_decrypt/linux/blackbox_decrypt"
run_cmd "mkdir -p $bmcLogPath"
run_cmd "mkdir -p $bmcJasonResPath"
function getbmclogs()
{
    local loginOK="0"
    #for remote log collect
    if [ "$ipmitool" == "ipmitool" ]
    then
        return
    fi

    #run_cmd "mkdir -p $meLogPath"


    web_login "$bmcip" "$bmcuser" "$bmcpassword"
    let loginOK=$?
    #res=`curl --cookie "$cookie" --max-time 60  http://$bmcip/rpc/getdnscfg.asp 2>/dev/null`
    #echo "test=====$res"

    web_get_logs "$bmcip" "$bmcuser" "$bmcpassword" "/blackbox/record/blackbox.log" "blackbox.log"
    web_get_logs "$bmcip" "$bmcuser" "$bmcpassword" "/blackbox/record/blackboxpeci.log" "blackboxpeci.log"
    web_get_logs "$bmcip" "$bmcuser" "$bmcpassword" "/tmp/sol.log" "sol.log"

    #parse blackbox logs
    uname -a | grep "x86_64" >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
        parseBlackboxTool="./blackbox_decrypt/linux/blackbox_decrypt"
    else
        parseBlackboxTool="./blackbox_decrypt/linux/blackbox_decrypt_x86"
    fi
    chmod +x "$parseBlackboxTool"
    cat $bmcLogPath/blackbox.log | grep "Not Found" >/dev/null 2>&1
    if [ $? -ne 0 ] ;then
        run_cmd "$parseBlackboxTool  $bmcLogPath/blackbox.log $bmcLogPath/blackbox_decode.log"
    fi

    cat $bmcLogPath/blackboxpeci.log | grep "Not Found" >/dev/null 2>&1
    if [ $? -ne 0 ] ;then
        run_cmd "$parseBlackboxTool  $bmcLogPath/blackboxpeci.log $bmcLogPath/blackboxpeci_decode.log"
    fi

    if [ $loginOK -ne 0 ] ; then
        echo "web Log in failed $bmcip!"
        return 255
    fi
    #chicago should not use 0x3a 0xa8, for cmd is used for bios update
    web_get_request "$bmcip" "$bmcuser" "$bmcpassword" "triggerOneKeyLogCollect.asp"
    web_get_request "$bmcip" "$bmcuser" "$bmcpassword" "onekeylog.asp"
    local customidfile="output/bmc_customid.txt";
    if [  -f  $customidfile ] ; then
        #valid customer res
        cat $customidfile  2>/dev/null|grep "42 61 6f 54 75 00 00"
        if [ $? -eq 0 ]; then
                LOG_INFO "This is BaoTu, will trigger bmc onekeylog by send 0x3a 0xa8 0x02 0x00"
                sendIPMIWithRetry "${ipmitool} raw 0x3a 0xa8 0x02 0x00" "output/triggeronekey.txt" 3
        fi
        cat $customidfile  2>/dev/null|grep "5a 68 65 6e 5a 68 75 00 00"
        if [ $? -eq 0 ]; then
                LOG_INFO "This is ZhenZhu, will trigger bmc onekeylog by send 0x3a 0xa8 0x02 0x00"
                sendIPMIWithRetry "${ipmitool} raw 0x3a 0xa8 0x02 0x00" "output/triggeronekey.txt" 3
        fi
        cat $customidfile  2>/dev/null|grep "53 68 75 59 75 00 00"
        if [ $? -eq 0 ]; then
                LOG_INFO "This is ShuYu, will trigger bmc onekeylog by send 0x3a 0xa8 0x02 0x00"
                sendIPMIWithRetry "${ipmitool} raw 0x3a 0xa8 0x02 0x00" "output/triggeronekey.txt" 3
        fi
        cat $customidfile  2>/dev/null|grep "43 61 69 53 68 65 6e 00 00"
        if [ $? -eq 0 ]; then
                LOG_INFO "This is CaiShen, will trigger bmc onekeylog by send 0x3a 0xa8 0x02 0x00"
                sendIPMIWithRetry "${ipmitool} raw 0x3a 0xa8 0x02 0x00" "output/triggeronekey.txt" 3
        fi

    fi


    web_get_jason_list "$bmcip" "$bmcuser" "$bmcpassword"

    #sleep 15
    web_get_logs "$bmcip" "$bmcuser" "$bmcpassword" "/tmp/onekeylog.tar" "onekeylog.tar"

    web_logout "$bmcip" "$bmcuser" "$bmcpassword"
    #run_cmd "wget -t 1 -T 3 -P output/wget http://$bmcip/tmp/onekeylog.tar -O output/wget/onekeylog.tar >&/dev/null"
    #run_cmd "wget -t 1 -T 3 -P output/wget http://$bmcip/blackbox/record/blackbox.log -O output/wget/blackbox.log >&/dev/null"
    #run_cmd "wget -t 1 -T 3 -P output/wget http://$bmcip/blackbox/record/blackboxpeci.log -O output/wget/blackboxpeci.log >&/dev/null"
    #run_cmd "wget -t 1 -T 3 -P output/wget http://$bmcip/tmp/sol.log -O output/wget/sol_tmp.log >&/dev/null"
    #run_cmd "wget -t 1 -T 3 -P output/wget http://$bmcip/blackbox/sol.log -O output/wget/sol_blackbox.log >&/dev/null"
    #run_cmd "mkdir -p output/curl/"
    #curl --connect-timeout 3 –u ADMIN:ADMIN $bmcip/tmp/onekeylog.tar > output/curl/onekeylog.tar 2>/dev/null
    #curl --connect-timeout 3 –u ADMIN:ADMIN $bmcip/blackbox/record/blackbox.log > output/curl/blackbox.log 2>/dev/null
    #curl --connect-timeout 3 –u ADMIN:ADMIN $bmcip/blackbox/record/blackboxpeci.log > output/curl/blackboxpeci.log 2>/dev/null
    #curl --connect-timeout 3 –u ADMIN:ADMIN $bmcip/tmp/sol.log > output/curl/sol_tmp.log 2>/dev/null
    #curl --connect-timeout 3 –u ADMIN:ADMIN $bmcip/blackbox/sol.log > output/curl/sol_blackbox.log 2>/dev/null
    return
}

function getOneSensType()
{
  local sen=$1
  ${ipmitool} raw 0x04 0x2f ${sen} 2>/dev/null
  return $?
}

function getOneSensRead()
{
  local sen=$1
  ${ipmitool} raw 0x04 0x2D ${sen} 2>/dev/null
  return $?
}

function getOneSensReadFactor()
{
  local sen=$1
  ${ipmitool} raw 0x04 0x23 ${sen} 0x00 2>/dev/null
  return $?
}

function getOneSensThresholds()
{
  local sen=$1
  ${ipmitool} raw 0x04 0x27 ${sen} 2>/dev/null
  return $?
}

function getOneSensEventEnable()
{
  local sen=$1
  ${ipmitool} raw 0x04 0x29 ${sen} 2>/dev/null
  return $?
}

sdrElistFile="output/sdr_elist_all.txt"
function getSDRinfo()
{
  if [ -f "${sdrElistFile}" ] ; then
    cat "${sdrElistFile}" | grep "|" | grep -v "Dynamic MC" 2>/dev/null
  else
    ${ipmitool} sdr elist all | grep "|" | grep -v "Dynamic MC" 2>/dev/null
  fi
  return $?
}

oemSdrFile="output/sdrOEM.txt"
function get_bmc_sdr_oem()
{
    #./getSDR.sh "$ipmitool" > output/sdrOEM.txt 2>/dev/null

  thesdr=$(getSDRinfo)
  #echo "test1---------$thesdr----------"

  #thesdr=`echo $thesdr | grep -v "Dynamic MC"`

  #  echo "test2-------$thesdr------------"
  sensName=($(echo "${thesdr}" | awk -F'|' '{print $1}' | sed 's/ //g'))
  sensNumb=($(echo "${thesdr}" | awk -F'|' '{print $2}' | sed -e 's/ //g;s/h//g'))
  sensReading=($(echo "${thesdr}" | awk -F'|' '{print $5}' | sed -e 's/ /+/g'))

  if [ -f "$oemSdrFile" ] ;then
    rm "$oemSdrFile" 2>/dev/null
  fi

  local index=0
  local sen=""
  #printf "%-17s | %-13s | %-13s | %-13s | %s\n" "#Sensor Name" "Sensor Number" "Sensor Type" "Reading Value" "Alerts/Events"
  for sen in ${sensNumb[@]}
  do
    sen="0x${sen}"
    local sensorTypeRes=$(getOneSensType ${sen})
    sensorTypeRes=`echo $sensorTypeRes | sed 's/ /+/g'`
    local sensorReadRes=$(getOneSensRead ${sen})
    sensorReadRes=`echo $sensorReadRes | sed 's/ /+/g'`
    #local sensorFactorRes=$(getOneSensReadFactor ${sen})
    #local sensorThreshRes=$(getOneSensThresholds ${sen})
    #echo "${sen} |${sensName[$index]}|${sensReading[$index]}|$sensorTypeRes|$sensorReadRes|$sensorFactorRes|$sensorThreshRes"
    echo "${sen} |${sensName[$index]}|${sensReading[$index]}|$sensorTypeRes|$sensorReadRes|$sensorFactorRes|$sensorThreshRes" >> "$oemSdrFile"

    let "index++"
done
}

function isBMCActive()
{
    for((i=0;i<=2;i++))
    do
        #echo "=====++${ipmitool} mc info++"
        ${ipmitool} mc info 2>/dev/null |grep "Provides Device SDRs " >/dev/null 2>&1
        if [ $? = 0 ] ;then 
            LOG_INFO  "BMC is Active, with ip:$bmcip, user:$bmcuser, pass:$bmcpassword." 
            #sleep 1
            return 0
        else
            LOG_INFO  "BMC is not Active , with ip:$bmcip, user:$bmcuser, pass:$bmcpassword... " 
            sleep 1
        fi
    done
    
    LOG_INFO "BMC not response, please check ip $bmcip, user:$bmcuser, pass:$bmcpassword!!!!"
    return 1
}

##################
# input 1: ip
##################
function isPingActive()
{
    local ip=$1
    ping "$ip" -c 3 > /dev/null 2>&1 
    if [ $? = 1 ] ; then
        #echo "ping "$ip" not access!!"
        return 1
    fi
    #echo "ping "$ip" access OK!!"
    return 0
}
