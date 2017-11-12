#!/bin/sh
clear
if [[ $# -eq 0  ]]
then
#
reset_terminal=$(tput sgr0)
##Print Hardware infomation
	echo -e '\E[34m' "*************Hardware Information***********" $reset_terminal 
#Check CPU information
	cpu_name=$(grep 'model name' /proc/cpuinfo |sort -u|awk -F ": " '{print $2}')
	cpu_number=$(grep 'physical id' /proc/cpuinfo |sort -u|wc -l)
	cpu_core_number=$(grep 'core id' /proc/cpuinfo |sort -u |wc -l)
	cpu_processor_number=$(grep 'processor' /proc/cpuinfo |sort -u|wc -l)
	echo -e '\E[32m' "CPU Name : " $reset_terminal $cpu_name
	echo -e '\E[32m' "CPU Physical Number : " $reset_terminal $cpu_number
	echo -e '\E[32m' "CPU Core Number : " $reset_terminal $cpu_core_number
 	echo -e '\E[32m' "CPU Processor Number : " $reset_terminal $cpu_processor_number
#Check Memory information
#	memtotal=$(grep 'MemT' /proc/meminfo |sort -u|awk -F ":        " '{print $2}')
	memtotal=$(free -h|grep Mem|awk '{print $2}')
	echo -e '\E[32m' "Memory Total : " $reset_terminal $memtotal
#Check Disk information
	disk=$(lsblk |grep "^[h|s]d" |awk '{print $1,$4}')
	echo -e '\E[32m' "Disk Total : " $reset_terminal $disk
#Check VGA information	
	vga_name=$(lspci|grep VGA|awk -F ":" '{print $3}')
	echo -e '\E[32m' "VGA Name : " $reset_terminal $vga_name
#Check Nerwork Interface Card
	nic=$(lspci |grep Ethernet|awk -F ":" '{print $3}')
	echo -e '\E[32m' "NIC Name : " $reset_terminal $nic
	echo -e '\E[34m' "************System Information************" $reset_terminal 
# Check OS Type
	os=$(uname -o)
	echo -e '\E[32m' "Operating System Type : " $reset_terminal $os
# Check OS Release Version and Name
	os_name=$(cat /etc/issue |grep -e "[r|R]elease")
	echo -e '\E[32m' "Os Release Version and Name :" $reset_terminal $os_name
# Check Architecture
	architecture=$(uname -m)
	echo -e '\E[32m' "Architecture :"$reset_terminal  $architecture
# Check Kernel Release
	kernerrelease=$(uname -r)
	echo -e '\E[32m' "Kernel Release :"$reset_terminal $kernerrelease
# Check hostname
	hostname=$(hostname)
	echo -e '\E[32m' "Hostname :"$reset_terminal  $hostname
# Check Internal IP
	internalip=$(hostname -I)
	echo -e '\E[32m' "Internal IP : " $reset_terminal $internalip
# check External IP

	externalip=$(curl -s http://ipecho.net/plain)
	echo -e '\E[32m' "External IP :"$reset_terminal $externalip
# Check DNS
	dns=$(cat /etc/resolv.conf |grep -E "nameserver[ ]+"|awk '{print $2}')
	echo -e '\E[32m' "DNS :"$reset_terminal $dns
# Check if connected to Internet or not
	ping -c 1 baidu.com &>/dev/null &&  echo -e "\e[32m Internet :\e[0m Connected" $reset_terminal||echo -e "\E[32m  Internet :\E[0m Disconnected"
# Check Logged In Users
	who>/tmp/who
	echo -e '\E[32m' "Logged In Users"$reset_terminal && cat /tmp/who
	rm -rf /tmp/who
fi
#

