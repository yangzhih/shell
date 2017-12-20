#!/bin/bash
TOOL_VERSION="V2.3"
TOOL_RELEASE_DATE="2017-3-17"
function usage()
{
  printf "Tools verion:$TOOL_VERSION\n"
  printf "Tools Release date:$TOOL_RELEASE_DATE\n"
  printf "Usage 1:DiagInfoCollect to collect system\n"
  printf "Usage 2:DiagInfoCollect <BMCIP> <BMCUSER> <BMCPASSWORD> to collect remmote BMC info.\n"
  printf "\n"
}
##################
# input 1 - IP
# input 2 - BMC User (if none, Default:admin)
# input 3 - BMC Password(if none, Default:admin)
#
###################
function checkbmcpara()
{
  if [ "$1" == "" ] 
  then
     echo "Invalid ip address-$1, please check!"
     return 1
  fi
  ip=$1
  echo "$ip" | grep -E "^[0-9]{1,3}\.([0-9]{1,3}\.){2}[0-9]{1,3}$" >/dev/null
  if [ $? -ne 0 ]
  then 
    echo "Invalid ip address-$1, please check!"
    return 1
  fi
  
  a=`echo $ip | awk -F. '{print $1}'`
  b=`echo $ip | awk -F. '{print $2}'`
  c=`echo $ip | awk -F. '{print $3}'`
  d=`echo $ip | awk -F. '{print $4}'`
  for num in $a $b $c $d
  do
    if [ $num -gt 255 ] || [ $num -lt 0 ]
    then
       return 1
    fi
  done
  return 0 
}

###########################
# input 1 - IP
# input 2 - User (default admin)
# input 2 - password(default admin)
###########################
bmcip=""
if [ $# -eq 3 ] || [ $# -eq 1 ]  || [ $# -eq 2 ] 
then
  bmcip=$1
  bmcuser=$2
  bmcpassword=$3
  checkbmcpara $1 $2 $3
  if [ $? -eq 0 ]
  then
    remote="TRUE"
  else
    usage
    exit 0 
  fi
elif [ $# -eq 0 ]
then
  remote="FALSE"
else
  usage
  exit 0
fi

#script direction
realpath=$(readlink -f "$0")
basedir=$(dirname "$realpath")

#cd to diagInfoCollect directory
cd "${basedir}"
modbase="$basedir/modules"
if [ "$bmcip" = "" ]
  then
    #OUTPUTLOG="$basedir/$(dmidecode -t 1 | grep "Serial Number" | awk -F": " '{print $2}' | sed 's/ //g')_$(date +%Y%m%d_%H%M%S)"
	productName=$(dmidecode -t 1 | grep "Product Name" | awk -F": " '{print $2}' | sed 's/ //g')
	serialNum=$(dmidecode -t 1 | grep "Serial Number" | awk -F": " '{print $2}' | sed 's/ //g')
	ipAddress=$(ifconfig|grep inet|awk '{print $2}'|head -n 1)
       echo $ipAddress | grep ":" > /dev/null
       if [ $? -eq 0 ] ; then
          #echo "test====$ipAddress"
          ipAddress=`echo $ipAddress | awk -F":" '{print $2}' | sed 's/ //g'`
          #echo "test====$ipAddress"
       fi

	OUTPUTLOG="$basedir/${productName}_${serialNum}_${ipAddress}_$(date +%Y%m%d_%H%M%S)"
  else
    OUTPUTLOG="$basedir/"$bmcip"_$(date +%Y%m%d_%H%M%S)"	
fi
unset setpath
unset log
unset common
if [ "setpath" ]
then
    for i in `find $modbase -maxdepth 1 -type d`;
    do
        PATH=$PATH:$(readlink -f $i);
    done
    export PATH
    export setpath="1"
fi

. log.sh
. common.sh

function main()
{
    LOG_INFO "InfoCollect start time is:$(date +%Y%m%d_%H%M%S)..."
    check_auth
    
    #run_cmd "mkdir -m a=r -p ${OUTPUTLOG}"
    run_cmd "mkdir -p ${OUTPUTLOG}"
    run_cmd "echo Tools verion:$TOOL_VERSION" "${OUTPUTLOG}/version.txt"
    run_cmd "echo Tools Release date:$TOOL_RELEASE_DATE"  "${OUTPUTLOG}/version.txt"
    
    main_collect_log
    
    run_cmd "cp -f runlog ${OUTPUTLOG}/runlog_main"
    create_filelist "${OUTPUTLOG}"



    firename=$(basename $OUTPUTLOG)
    cd "${OUTPUTLOG}/.."

    if [ "$remote" == "TRUE" ] ; then
        local productName=`cat ${OUTPUTLOG}/bmc/fru.txt 2> /dev/null | grep "Product Name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/ //g' | sed 's/\n//g'`
        local serialNum=`cat ${OUTPUTLOG}/bmc/fru.txt 2> /dev/null | grep "Product Serial" | head -n  1 | awk -F ":" '{print $2}' | sed 's/ //g' | sed 's/\n//g'`
        local tmpFileName="${productName}_${serialNum}_${firename}"
        #echo "productName:$productName; serialNum:$serialNum;tmpFileName:$tmpFileName"
        mv ${firename} $tmpFileName
        if [ $? -eq 0 ] ; then
          firename="${tmpFileName}"
        fi
    fi

    #echo "test======="
    #pwd
    #echo "test======="
    #copy to logParsing, used to diagnose
    if [ -d "../logParsing" ] ; then
        rm -rf  ../logParsing/* 2>/dev/null
        cp  -rf ${firename} ../logParsing 2>/dev/null
    fi

    local INFO_COLLECT_USED_TO_DISPLAY_FILE="../infoUsedDisplayFlag.txt"
    if [ ! -f "$INFO_COLLECT_USED_TO_DISPLAY_FILE" ] ; then
        #echo "test==INFO_COLLECT_USED_TO_DISPLAY_FILE===="
       echo "compress $firename"
        compression_dir "${firename}"

    fi
    run_cmd "rm -rf ${firename}"
    return
}


################################################################
#Function:		<main_collect_log>
#Description:	collect log according to config.ini and logCollect.cfg
#Parameter:	N/a	
#Return:	N/a
#Since:		
#Other:		N/a				
###################################################################
function main_collect_log()
{
    local module=$(ls modules 2>&1)
    local result="SUCCEED"
    local timeout=""
    local pid=""

    if [ -f "modules/lib/timeout.ini" ] 
    then
        timeout=`cat modules/lib/timeout.ini`
        if [[ "${timeout}" == *[!0-9]* ]] 
        then
            LOG_ERROR "Invalid timeout set value:${timeout}.User default."
            timeout=1800
        fi

        LOG_INFO "Module collect timeout value is:$timeout."

    else 
        timeout=1800
        LOG_INFO "No timeout.ini found.Module collect timeout value is default:$timeout."
    fi
    
    #install tools
    run_cmd "rm -rf opt" 
    run_cmd "cp modules/raid/RAIDtool/3108/storcli-1.15.04-1.tar.gz ."
    run_cmd "tar -xf storcli-1.15.04-1.tar.gz"

    showTitle "${TOOL_VERSION}" "${TOOL_RELEASE_DATE}"
    
    if [ "$remote" == "TRUE" ]
    then
        modlist="bmc"
    else
        modlist=$(ls $modbase)
    fi

    for mod in $modlist
    do
        subpid=""
        cnt=0
        modpath="$modbase/$mod"
        #cd to module dir
        cd "$modpath"
        #echo "$modpath"
        if [ -f "main.sh" ]
        then
	   chmod +x ./main.sh
            if [ "$remote" == "TRUE" ] && [ "$mod" == "bmc" ]
            then 
                ./main.sh "$bmcip" "$bmcuser" "$bmcpassword" &
            else
                ./main.sh &
            fi
            pid=$!
        fi
        cd $basedir
        LOG_INFO "Module ${moduleName} collect pid is:$pid"
#time start
        sleep 1
        for((i=0;i<timeout;i++))
        do
            ((cnt=cnt+1))
            sleep 1
            ps $pid >/dev/null
            #process finished
            if [ 0 -ne "$?" ]
            then
                LOG_INFO "Module ${moduleName} log collect process is finished in time."
                cnt=0
                break
            fi
        done
#time end
#outof time will kill pid
        if [ $timeout -eq $cnt ]
        then

            LOG_ERROR "Module ${moduleName} log collect process is timeout."
            LOG_INFO "kill ${moduleName} log collect process:$pid start."

            run_cmd "which pstree xargs >/dev/null 2>&1"
            if [ 0 -eq $? ]
            then
                process_list=$(pstree $pid -p | awk -F'[()]' '{for(j=0;j<=NF;j++)if($j~/[0-9]+/)print $j}' | xargs)
               
                LOG_INFO "Process to kill is :$process_list"
               
                for element in $process_list
                do
                    if [[ $element == *[!0-9]* ]]
                    then   
                         LOG_INFO "Process info:$element skipped." 
                         continue
                    fi  
                    LOG_INFO "kill ${moduleName} log collect process:$element start."
                    run_cmd "kill -9 $element >/dev/null 2>&1" 
                    LOG_INFO "kill ${moduleName} log collect process:$element end."
                done 

            else
                LOG_INFO "kill ${moduleName} log collect process:$pid start."
                run_cmd "kill -9 $pid  >/dev/null 2>&1"                
                LOG_INFO "kill ${moduleName} log collect process:$pid end."
            fi

            LOG_INFO "kill ${moduleName} log collect sub process done."
            LOG_INFO "${moduleName} log collect exsit."
            
            printf "\r %.60s" "[${moduleName}]...                                                                            "
            printf "%s\n" "Done"   
            continue
        fi

        #move module ouput files
        run_cmd "mv $modpath/output ${OUTPUTLOG}/$mod"
        LOG_INFO "move $modpath/output to ${OUTPUTLOG}/$mod ..."
        run_cmd "mv $modpath/runlog ${OUTPUTLOG}/runlog_$mod"
        LOG_INFO "move $modpath/runlog to ${OUTPUTLOG}/runlog_$mod ..."
    done
   
    run_cmd "rm -rf storcli-1.15.04-1.tar.gz"
    run_cmd "rm -rf CmdTool.log"
    run_cmd "rm -rf MegaSAS.log"
    run_cmd "rm -rf opt"
    return
}

main
