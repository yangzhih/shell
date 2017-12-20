##!/bin/bash
if [  ! -z "$common" ];then
    return
fi
common="common.sh"
#. log.sh
################################################################
#Function:		<create_filelist>
#Description:	get file list in destdir $1
#Parameter:	$1 : destdir
#Return:	filelist.txt
#Since:		
#Other:		NA			
###################################################################
function create_filelist()
{
    oldpath=`pwd`
    local destdir=$1
    cd ${destdir}
    local subDir=$(ls)
    local i=0
    #echo "subdir=$subDir"
    for thisfile in ${subDir}
    do
        #echo "zwt :"$thisfile
        if [ -d "${thisfile}" ]
        then            
            find ${thisfile} ! -type d  | awk -v title="${thisfile}"\
            'BEGIN{print "\n" title " Dir file list:";i = 0;}\
            {printf "  %-5s %s\n",i+1,$0;i = i+1;}'\
             >> filelist.txt
        else
            files[${i}]="${thisfile}"
            i=$((i+1))
        fi
    done
    
    #write file name to the end of the filelist
    local fnum=${#files[@]}
    for((i=0;i<${fnum};i++))
    do
        if [ "" != "${files[${i}]}" ]
        then        
            ls ${files[${i}]} >> filelist.txt
        fi
    done
    
    echo "filelist.txt" >> filelist.txt
    cd ${oldpath}
    return
}

function showTitle()
{
    local TOOL_VERSION="$1"
    local TOOL_RELEASE_TATE="$2"
    printf "%-65.65s\n" "==============================================================================="
    printf "%-65.65s\n" "        Inspur Diag Info Collect: ${TOOL_VERSION}              "
    printf "%-65.65s\n" "             Release Date:${TOOL_RELEASE_DATE}                                    "
    printf "%-65.65s\n" "                                                                                "
    #printf "%-65.65s\n" " -Supported mainstream Linux 64-bit operating systems (OSs):                     "
    #printf "%-65.65s\n" "  RedHat/CentOS 6.4 ~ 6.6 x64                                                        "
    #printf "%-65.65s\n" "  SLES 11.1 ~ 11.3 x64                                                      "
    printf "%-65.65s\n" " -Only professionals are qualified to use this tool.                             "
    printf "%-65.65s\n" " -Before performing any maintenance operations by using this                   "
    printf "%-65.65s\n" "  tool,obtain authorization from the customer.                                "
    #printf "%-65.65s\n" " -Before transmitting fault locating data out of the customer's               "
    #printf "%-65.65s\n" "  network,obtain written authorized from the customer.                         "
    printf "%-65.65s\n" "==============================================================================="
    return
}

################################################################
#Function:		<Compression_dir>
#Description:	Compression directory
#Parameter:	$1 : dir to compress
#Return:	N/a
#Since:		
#Other:		N/a				
###################################################################
function compression_dir()
{   
    local file_num=""
    local inputdir="$1"
    local Fbasename=$(basename "$inputdir")
    local compress_file="${Fbasename}.tar.gz"
    local Log_size=""
    printf "\r%-65.65s\n" "==[ DONE ]============================================================================================="
	
    run_cmd "chmod 400 -R ${inputdir}"
    run_cmd "tar -czf ${compress_file} ${inputdir}"
    if [ 0 -eq $? ]
    then
        #run_cmd "rm -rf ${inputdir}"
        run_cmd "chmod 400 ${compress_file}"
        md5sum "${compress_file}" > "${Fbasename}.md5"
        if [ $? -ne 0 ]; then
            #echo -e "\033[31mcompressed file fail, please manual compression" | tee -a "${OUTPUTLOG}/system/${OUTPUTRUNLOG}\033[0m"
            echo -e "\033[31mcompressed file fail, please manual compression\033[0m"
        else
            run_cmd "chmod 400 ${Fbasename}.md5"
            file_size=$(du -sh "${compress_file}"  | awk '{print $1}')
            file_path=$(readlink -f "$compress_file")
            echo -e "\033[32mFile Path: ${file_path} \033[0m"
            echo -e "\033[32mFile size: ${file_size} \033[0m"
            echo -e "\033[32mFile md5sum: $(cat ${Fbasename}.md5 | cut -d ' ' -f 1) \033[0m"
        fi
        #file_num=$(ls -A1 /var/crash/ 2>/dev/null | wc -l)
        #if [ "${file_num}" -gt 0 ]; then
         #   echo -e "\033[31mPlease collect crash files[/var/crash] manually.\033[0m"
        #fi
    else
        echo -e "\033[31mCompress $inputdir failed. Please compress manually.\033[0m"
        LOG_ERROR "Compress $inputdir failed. Please compress manually."
    fi
    printf "%-65.65s\n" "================================================================================================="
}

################################################################
#Function:		<check_auth>
#Description:	check auth id is 0
#Parameter:	N/a	
#Return:	exit 1 if not  id0 user
#Since:		
#Other:		N/a				
###################################################################
function check_auth()
{
    local login_id=$(id -u $(whoami))
    if [ "${login_id}" -ne 0 ]; then
        echo  "Current user id is ${login_id}.Recommendation to use ID:0 user to collect logs."
        LOG_ERROR "Current user id is ${login_id}.Recommendation to use ID:0 user to collect logs."
    else 
        LOG_INFO "User ID is:$(id $(whoami))"
    fi 
}

################################################################
#Function:		<run_cmd>
#Description:	exec cmd 
#Parameter:	$1£ºcmd to be run  $2: Variable parameter£ºout put the result to file£¬ 
#Return:	errocode  0:ok
#Since:		
#Other:		N/a				
###################################################################
function run_cmd()
{
   local ret=1
   local cmd="$1"
   local output="$2"
   local result=""
   local retCode=""

    if [ "" == "$cmd" ] || [ 2 -lt $# ] 
    then
        LOG_ERROR "Invalid parameters."
        ret=1
        return $ret 
    fi
	
	LOG_INFO "[$cmd] is called."
        local cmdshow=$(echo $cmd | awk -F">" '{print $1}' | sed 's/^\s*\|\s*$//g')
        
                if [ "" != "$output" ]      
	then
	   echo "${cmdshow}" >> "$output"  
	   echo "{" >> "$output"            
	fi

	result=$(eval "${cmd}" 2>&1)          
	retCode=$?
	if [ 0 -ne $retCode  ]
	then
	   ret=$retCode
	   LOG_ERROR "[$cmd] failed.Ret:$retCode. Desc:$result"
	else 
	   ret=0
	   LOG_INFO "[$cmd] successfull."
	fi 

	if [ "" != "$output" ]      
	then
                    echo "$result" >> "$output"
	    echo "}" >> "$output"
	fi

    return $ret

}

function cmdisfunc()
{
    local cmd="$1"
	local flist=$(grep '^function' funclib.sh | awk '{print $2}' | sed -e 's/[( )]//g')
	
	for i in $flist
	do
	    if [ "$cmd" == "$i" ]
		then
		    return 0
        fi
	done
	return 1
}

#INFO_COLLECT_USED_TO_DISPLAY="yes"
function module_log_collect()
{ 
    #local file=""
    local cmd=""
    local cmdshow=""
    #local cmdType=""
    #local lineNum=""
    local result="SUCCEED"
    #local line=""
    local modname="$1"
    LOG_INFO "${moduleName} collect start." 
    mkdir -p output
    printf "\r\033[K Collect %.60s" "[${moduleName}] information..." 
    #lineNumber=`cat config.ini 2>/dev/null | grep -v '#' | grep '|' | wc -l`
    groupid=`cat ../../config.ini | grep -v -E "^#" |grep "|" | grep "yes"| grep "module=$modname" | awk -F"|" '{print $2}' | awk -F"=" '{print $2}' `
    groupid="base ""$groupid"

    local  usedToDisplayFlag=""
    local INFO_COLLECT_USED_TO_DISPLAY_FILE="../../../infoUsedDisplayFlag.txt"
    if [ -f "$INFO_COLLECT_USED_TO_DISPLAY_FILE" ] ; then
        #echo "test==77777INFO_COLLECT_USED_TO_DISPLAY_FILE===="
        usedToDisplayFlag="yes"
    fi
    #echo "Test1=========="
    #echo "$groupid"
    #echo "Test2=========="
    for id in $groupid
    do
        con=`cat cmd.list | grep -v -E "^#" | grep "|" |grep -E "^\s*$id"`
        #echo "$con"
        ##start collect
        LOG_INFO  "group [${id}] collect start." 
        #printf "\r%.75s" "                                                   "
        printf "\r\033[K Collect [${id}] ...... please wait"
        echo "$con" | while read line
        do
            cmd=$(echo $line | awk -F"|" '{print $2}'| awk -F"#" '{print $1}'| sed 's/^\s*\|\s*$//g')
            cmdshow=$(echo $cmd | awk -F">" '{print $1}' | sed 's/^\s*\|\s*$//g')
            if [ "$usedToDisplayFlag" = "yes" ] ; then
                cmdInfoDisplayMode=$(echo $line | awk -F"|" '{print $3}' | sed 's/ //g')
                #echo "test=cmdInfoDisplayMode:$cmdInfoDisplayMode===="
                if [ "$cmdInfoDisplayMode" != "yes" ] ;then
                    continue
                fi
            fi
            #avoid cmd too long
            if [ ${#cmdshow} -gt 40 ]
            then
                cmdshow=${cmdshow:0:40}" ..."
            fi
            outfile=$(echo $line | awk -F"|" '{print $2}'| awk -F"#" '{print $2}'| sed 's/^\s*\|\s*$//g')
            needw=$(echo "$outfile"| grep -c -E '^writehead:')
            if [ $needw -eq 0 ]
            then
                outfile=""
            else
                outfile=$(echo "$outfile" | awk -F':' '{print $2}'|sed 's/^\s*\|\s*$//g')
            fi
            
            if [ "$cmd" == "" ]
            then
                continue
            fi 
            LOG_INFO  "[${cmd}] excute start." 
            #printf "\r%.75s" "                                                   "
            printf "\r\033[K Excute [${cmdshow}] ...... please wait"
            #echo $cmd
                        #echo "test===$ipmitool==$cmd======"
            #$ipmitool -b 0x06 -t 0x2c raw 0x06 0x01
            cmdisfunc "$cmd"

            if [ "0" == "$?" ]
            then
                 $cmd
            else
                    #             echo "$cmd"

                 run_cmd "$cmd" "$outfile"
                 
                 if [ "0" == "$?" ]
                 then
                     LOG_INFO "$cmd excute ok."
                     result="SUCCEED"
            else
                     LOG_INFO "$cmd excute failed."
                     result="FAILED"
                 fi
            fi
        done

        printf "\r\033[K Collect group [${id}] ...... Done        "
        done

    printf "\r\033[K %.60s" "[${modname}]...                                                                            "
    printf "%s\n" "Done"
    LOG_INFO "${modname} collect finished." 
    return
}

