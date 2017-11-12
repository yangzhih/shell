#!/bin/bash
resettem=$(tput sgr0)
declare -A ssharray
i=0
numbers=""
menu(){
for script_file in `ls -I "monitor_man.sh" ./`
do
	echo -e '\e[1;31m' "The Script:" ${i} '==>' $resettem $script_file
	ssharray[$i]=${script_file}
	numbers="$numbers|${i}"
	let i+=1
done
unset i
i=0
}
#echo $numbers
menu
while true
do
	read -p "Please input a number [ $numbers ]:" execshell
	if [[ ! $execshell =~ ^[0-9]+ ]];then
		exit 0
	fi
	/bin/bash ./${ssharray[$execshell]}
	unset numbers
	menu
done
