#!/bin/bash
if [ ! -z "$log" ];then
    return
fi
log="log.sh"
#Max file size, with bytes.
LOG_MAX_SIZE=10000000

#DEBUG
#INFO
#ERROR
LOG_LEVEL="DEBUG"

alias LOG_DEBUG='log "[DEBUG] [${BASH_SOURCE} ${LINENO}]"'
alias LOG_INFO='log "[INFO ] [${BASH_SOURCE} ${LINENO}]"'
alias LOG_WARN='log "[WARN ] [${BASH_SOURCE} ${LINENO}]"'
alias LOG_ERROR='log "[ERROR] [${BASH_SOURCE} ${LINENO}]"'
shopt -s expand_aliases

LOG_DIR="."
LOG_TYPE="runlog"

#${sysTime}-${LOG_TYPE}-${logSN}.log is suggest.
LOG_NAME="runlog"

LOG_PATH=""

function init_log()
{
    mkdir -p "${LOG_DIR}"
    chmod 700 "${LOG_DIR}"
    
    local maxTotalLog=10
    local logSN=1 #the log sn of new log file
    local logNameArr #the array contains all the logs' name
    local newestLogName="" #the newest log's name
    
    local logCount=0
    for file in $(ls -t -1 "${LOG_DIR}" | grep -E "^(([1-9][0-9][0-9][0-9])(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|30|31)-([0-1][0-9]|2[0-4])([0-5][0-9])([0-5][0-9])-${LOG_TYPE}-([1-9]|10)(\.log))$")
    do
        logNameArr[${logCount}]=${file}
        logCount=$(expr $logCount + 1)
    done
        
    if [ ${logCount} -gt 0 ]
    then
        newestLogName=${logNameArr[0]}
        local logSNTemp=$(echo ${newestLogName} | sed "s/\./-/g" | awk -F "-" '{print $4}')
        logSN=${logSNTemp}
        local logSize=$(ls -lk ${LOG_DIR}/${newestLogName}|awk -F " " '{print $5}')
        if [ "${logSize}" -ge "${LOG_MAX_SIZE}" ]
        then
            let "logSNTemp=logSNTemp + 1"
            logSN=$(expr ${logSNTemp} % ${maxTotalLog})
            if [ ${logSN} -eq 0 ]
            then
                logSN=10
            fi
        else
            LOG_NAME="${newestLogName}"
            LOG_PATH="${LOG_DIR}/${LOG_NAME}"
            return 0
        fi
    fi
    
    cd "${LOG_DIR}"
    ls -1 "${LOG_DIR}" | grep -E "^(([1-9][0-9][0-9][0-9])(0[1-9]|1[0-2])(0[1-9]|1[0-9]|2[0-9]|30|31)-([0-1][0-9]|2[0-4])([0-5][0-9])([0-5][0-9])-${LOG_TYPE}-${logSN}(\.log))$" | xargs rm -f
    rm -f runlog
    cd - > /dev/null
    
    sleep 0.1
    
    local sysTime=$(date -d today +"%Y%m%d-%H%M%S")
    LOG_PATH="${LOG_DIR}/${LOG_NAME}"
    touch "${LOG_PATH}"
    if [ $? -ne 0 ]
    then
        echo "init log error! touch \"${LOG_PATH}\" error"
        exit ${INIT_LOG_ERROR}
    fi
    chmod 600 "${LOG_PATH}"
}

function log()
{
    if [ "2" -gt "$#" ]
    then
        echo "log error! the number of input parameters must be equal to 2"
        exit 1
    fi
    
    local logInfo="$2"
    
    if [ -z "${logInfo}" ]
    then
        echo "log error! the log information can not be null"
        exit 1
    fi

    if [ "1" == "$3" ]
    then
        echo $logInfo
    fi
    
    if [ -z "${LOG_PATH}" ] || [ ! -e "${LOG_PATH}" ]
    then
        init_log
    fi
    
    local logSize=$(ls -lk ${LOG_PATH}|awk -F " " '{print $5}')
    
    if [ "${logSize}" -ge "${LOG_MAX_SIZE}" ]
    then
        init_log
    fi
    
    local logStr="$*"
    
    local systemDate=$(date -d today +"%Y-%m-%d %H:%M:%S")
    local grepRes=""
    
    if [ "${LOG_LEVEL}" = "DEBUG" ]
    then
        echo "[ ${systemDate} ] ${logStr}" >> "${LOG_PATH}"
    elif [ "${LOG_LEVEL}" = "INFO" ]
    then
        grepRes=$(echo "$1" | grep "[DEBUG]")
        if [ -z "${grepRes}" ]
        then
            echo "[ ${systemDate} ] ${logStr}" >> "${LOG_PATH}"
        fi
    elif [ "${LOG_LEVEL}" = "WARN" ]
    then
        grepRes=$(echo "$1" | grep "[INFO]" | grep "[DEBUG]")
        if [ -z "${grepRes}" ]
        then
            echo "[ ${systemDate} ] ${logStr}" >> "${LOG_PATH}"
        fi
    elif [ "${LOG_LEVEL}" = "ERROR" ]
    then
        grepRes=$(echo "$1" | grep "[ERROR]")
        if [ ! -z "${grepRes}" ]
        then
            echo "[ ${systemDate} ] ${logStr}" >> "${LOG_PATH}"
        fi
    fi
}
