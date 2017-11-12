#!/bin/bash

reset_terminal=$(tput sgr0)
#CPU monitor
echo -e '\E[34m' "*************CPU Performance***********" $reset_terminal 
    userspace=`top |head -6|grep Cpu|awk '{print $2}'|cut -d% -f1`%
    systemspace=`top |head -6|grep Cpu|awk '{print $3}'|cut -d% -f1`%
    allfree=`top |head -6|grep Cpu|awk '{print $5}'|cut -d% -f1`%
echo -e '\E[32m' "Idle CPU Time：" $reset_terminal $allfree
echo  -e '\E[32m' "User CPU Time：" $reset_terminal $userspace
echo  -e '\E[32m' "system CPU Time：:" $reset_terminal $systemspace
#Memory monitor
echo -e '\E[34m' "*************Mem Performance***********" $reset_terminal 
    Memtotal=` free -h|grep Mem|awk '{print $2}'`
    Memused=` free -h|grep Mem|awk '{print $3}'`
    Memfree=` free -h|grep Mem|awk '{print $4}'`
echo -e '\E[32m'  "Memory Total：" $reset_terminal $Memtotal
echo -e '\E[32m'  "Memory Used："  $reset_terminal $Memused
echo -e '\E[32m' "Memory Free：" $reset_terminal $Memfree

#Swap monitor
echo -e '\E[34m' "*************Swap Performance***********" $reset_terminal 
    swaptotal=`free -h|grep Swap|awk '{print $2}'`
    swapused=`free -h|grep Swap|awk '{print $3}'`
    swapfree=`free -h|grep Swap|awk '{print $4}'`
echo -e '\E[32m' "Swap Total：" $reset_terminal $swaptotal
echo -e '\E[32m' "Swap Used："  $reset_terminal $swapused
echo -e '\E[32m' "Swap Free：" $reset_terminal $swapfree

#disk monitor
echo -e '\E[34m' "*************Disk Performance***********" $reset_terminal 
    blk_read=` iostat -d /dev/sda |grep sda|awk '{print $3}'`
    blk_write=` iostat -d /dev/sda |grep sda|awk '{print $4}'`
echo -e '\E[32m' "The sda Disk Blk_read/s:" $reset_terminal $blk_read
echo -e '\E[32m' "The sda Disk Blk_wrtnd/s:" $reset_terminal $blk_write

#Network monitor
echo -e '\E[34m' "***********Network Performance*********" $reset_terminal 
r1=$( cat /sys/class/net/eth0/statistics/rx_bytes)
t1=$( cat /sys/class/net/eth0/statistics/tx_bytes)
sleep 1
r2=$( cat /sys/class/net/eth0/statistics/rx_bytes)
t2=$( cat /sys/class/net/eth0/statistics/tx_bytes)
tbps=$(expr $t2 - $t1)
rbps=$(expr $r2 - $r1)
tkbps=$(expr $tbps / 1024)kb/s
rkbps=$(expr $rbps / 1024)kb/s
echo -e '\E[32m' "The Upload Speed :" $reset_terminal $tbps b/s
echo -e '\E[32m' "The Download Speed:" $reset_terminal $rbps b/s

