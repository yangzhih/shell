#!/bin/bash
TOOL_VERSION="V2.0"
TOOL_RELEASE_DATE="2016-11-17"
function usage()
{
  printf "%-65.65s\n" "==============================================================================="
  printf "run.sh, used to call Diagnose Info Collect tool!\n"
  printf "1. Local mode, tool should run in host os, to collect local logs!\n"
  printf "2. Remote mode, tool should run in remote PC, to collect bmc logs!\n"
  printf "%-65.65s\n" "==============================================================================="
  #printf "\n"
}
usage

DiagInfoCollectTool="./DiagInfoCollect.sh"
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

ip=""
user=""
password=""
CollectMode="Remote"

while [ 1 ]
do
  #read -p "Please input collect mode, default remote mode, local mode inpu>" ip

  read -p "Please input BMC IP, No input will goto [Local Mode]!>" ip
  #echo "test0===$ip=="
  if [ "$ip" = "" ] ;then
    #echo "test1===$CollectMode=="
    CollectMode="Local"
    break
  fi

  #echo "test2===$CollectMode=="
  if [ "$CollectMode" = "Remote" ] ; then
    checkbmcpara "$ip"
    if [ $? -eq 0 ] ;    then 
              read -p "Please input BMC User(Defaut:admin)>" user
              read -p "Please input BMC PassWord(Defaut:admin)>" password
              if [ "$user" = "" ] ;then
                  user="admin"
              fi

              if [ "$password" = "" ] ;then
                  password="admin"
              fi
              break
    else
      continue
    fi
  fi
done

chmod +x $DiagInfoCollectTool
if [ "$CollectMode" = "Remote" ] ; then
  $DiagInfoCollectTool $ip $user $password
else
  $DiagInfoCollectTool
fi



