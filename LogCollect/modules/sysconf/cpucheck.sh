#!/bin/sh
# cpu information
#echo -ne "###Following is CPU Information###\n" >>$DIR/result/cpuinfo.csv
#echo "test====$DIR====="
ouputPath=$1
#echo "ouputPath==$ouputPath==="
echo -ne "Vendor \t`cat /proc/cpuinfo |grep "vendor"|uniq |awk -F ':' '{print $2}'`\n" >>$ouputPath/cpuinfo.csv
echo -ne "Model Name \t`cat /proc/cpuinfo |grep "model name" |uniq |awk -F  ':' '{print $2}'`\n" >>$ouputPath/cpuinfo.csv
echo -ne "Family \t`cat /proc/cpuinfo|grep "family"|uniq |awk -F ':' '{print $2}'` \n" >>$ouputPath/cpuinfo.csv
echo -ne "Stepping \t`cat /proc/cpuinfo|grep "stepping" |uniq |awk -F ':' '{print $2}'`\n" >>$ouputPath/cpuinfo.csv
echo -ne "Last Cache \t`cat /proc/cpuinfo |grep "cache size" |uniq |awk -F ':' '{print $2 }'`\n" >>$ouputPath/cpuinfo.csv
echo -ne "Cores  \t`cat /proc/cpuinfo |grep "cores"|uniq |awk -F ':' '{print $2}'`\n " >>$ouputPath/cpuinfo.csv
echo -ne "\n" >>$ouputPath/cpuinfo.csv
#HT State check #
#echo -ne "###Following is HT States###\n" >>$DIR/result/cpuinfo.csv
siblings=`cat /proc/cpuinfo  |grep siblings |uniq |awk -F ':' '{print $2}'`
cores=`cat /proc/cpuinfo  |grep cores |uniq |awk -F ':' '{print $2}'`
if [ $siblings == $cores ];then
  echo -ne "HT Status\t HT is off or HT is not supported\n" >>$ouputPath/cpuinfo.csv
elif [ $siblings == `expr $cores \* 2` ];then 
  echo -ne "HT Status \t Intel CPU HT is ON \n" >>$ouputPath/cpuinfo.csv
elif  [ $siblings == `expr $cores \* 4` ];then
  echo -ne "HT Status \t AMD CPU that supported 4 Threads is ON\n" >>$ouputPath/cpuinfo.csv
elif  [ $siblings == `expr $cores \* 8` ];then
  echo -ne "HT Status \t AMD CPU that supported 8 Threads is ON\n" >>$ouputPath/cpuinfo.csv
elif  [ $siblings == `expr $cores \* 16` ];then
  echo -ne "HT Status \t AMD CPU that supported 16 Threads is ON\n" >>$ouputPath/cpuinfo.csv
else 
  echo -ne "HT Status \t wrong\n" >>$ouputPath/cpuinfo.csv
fi
echo -ne "\n" >>$ouputPath/cpuinfo.csv
#C states check#
echo -ne "C states running on the system now\t">>$ouputPath/cpuinfo.csv
N=`ls -l /sys/devices/system/cpu/cpu0/cpuidle|grep state|wc -l`
  for ((i=0;i<N;i++))
do
   echo -ne "`cat /sys/devices/system/cpu/cpu0/cpuidle/state$i/name`\t">>$ouputPath/cpuinfo.csv
done
echo -ne "\n"  >>$ouputPath/cpuinfo.csv
#cpu topology#
#echo -ne "### CPU Topology###\n" >>$DIR/result/cpuinfo.csv
echo -ne "processor\t physical id\n" >>$ouputPath/cpuinfo.csv
cat /proc/cpuinfo |grep "processor"|awk '{print $3}'  > $ouputPath/processor
cat /proc/cpuinfo |grep "physical id" |awk '{print $4}'>$ouputPath/physicalid
paste $ouputPath/processor $ouputPath/physicalid >>$ouputPath/cpuinfo.csv
echo -ne "\n" >>$ouputPath/cpuinfo.csv
rm -f $ouputPath/processor
rm -f $ouputPath/physicalid
