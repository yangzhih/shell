#!/bin/bash
basedir=$(cd `dirname $0`;pwd)

##########################
# usage 1 : ./main.sh for local call
# usage 2: ./main.sh ip bmcuser bmcpass for remote call to access bmc;
#                 bmcuser canbe ""
#                 bmcpass canbe ""
##########################
if [ $# -eq 3 ] ||  [ $# -eq 2 ] ||  [ $# -eq 1 ]
then
  bmcip="$1"
  bmcuser="$2"
  bmcpassword="$3"
    if [ "$bmcuser" = "" ]
	then
	bmcuser="admin"
  fi
  if [ "$bmcpassword" = "" ]
	then
	bmcpassword="admin"
   fi
  ipmitool="ipmitool -Ilanplus -H${bmcip} -U${bmcuser} -P${bmcpassword}"
else
  ipmitool="ipmitool"
fi
ME_RAW_CMD_PRE=""
PECI_RAW_CMD_PRE=""
MEChannel=6

#echo $ipmitool
. ../lib/log.sh
. ../lib/common.sh
. ./funclib.sh

function bmcActiveCheck()
{
    local ipmiActive=1
    local pingActive=1
   if [ "$ipmitool" = "ipmitool" ] ; then
      isBMCActive
      let ipmiActive=$?
      if [  $ipmiActive  -ne 0 ] ; then 
          echo "BMC not response(ipmitool), please check if bmc is active!!!!" 
          LOG_INFO "BMC not response(ipmitool), please check if bmc is active!!!!"          
          exit 255
      fi
   else
      isPingActive "$bmcip"
      let pingActive=$?
      if [  $pingActive  -ne 0 ] ; then 
          echo "BMC $bmcip not access(ping), please check if bmcip correct!!!!"
          LOG_INFO "BMC $bmcip not access(ping), please check if bmcip correct!!!!"
          exit 255
      fi

      isBMCActive
       let ipmiActive=$?
      if [  $ipmiActive  -ne 0 ] ; then 
          echo "BMC $bmcip not response(ipmitool), please check if bmc is active!!!!"
          LOG_INFO "BMC $bmcip not response(ipmitool), please check if bmc is active!!!!"
          exit 255
      fi

      if [ $ipmiActive -ne 0 ] && [ $pingActive -ne 0 ] ; then
          echo "BMC $bmcip ipmitool and ping not access, exit bmc info collect !!!!"
          LOG_INFO "BMC $bmcip ipmitool and ping not access, exit bmc info collect !!!!"
          exit 255
      fi
   fi
 }

ipmitoolsourceFile="./ipmitool-1.8.11.tar.gz"
function installipmitool()
 {
    which ipmitool > /dev/null
    if [ $? -eq 0 ]
    then
        if [ "$ipmitool" = "ipmitool" ] ; then
          modprobe ipmi_watchdog 2>/dev/null
          modprobe ipmi_poweroff 2>/dev/null
          modprobe ipmi_devintf 2>/dev/null
          modprobe ipmi_si 2>/dev/null
          modprobe ipmi_msghandler 2>/dev/null
        fi
    else
        echo "Install ipmitool..."
        #echo "test==$(pwd)===="
        tar zxvf  $ipmitoolsourceFile >/dev/null 2>&1
        cd ipmitool-1.8.11      
        #echo "test==$(pwd)===="  
        chmod 755 ./*
        ./configure >/dev/null 2>&1
        make install >/dev/null 2>&1
        if [ "$ipmitool" = "ipmitool" ] ; then
          modprobe ipmi_watchdog 2>/dev/null
          modprobe ipmi_poweroff 2>/dev/null
          modprobe ipmi_devintf 2>/dev/null
          modprobe ipmi_si 2>/dev/null
          modprobe ipmi_msghandler 2>/dev/null
        fi
        cd ..
        #echo "test==$(pwd)===="
        rm ipmitool-1.8.11 -rf
  fi
 }

installipmitool
bmcActiveCheck 
module_log_collect "bmc"
