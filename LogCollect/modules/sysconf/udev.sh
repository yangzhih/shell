#! /bin/sh
ouputPath=$1
function t()
{
 if [ "$1" == "udevblock" ];then
    echo -ne "$2,$3,$4,$5,$6\n" >>$ouputPath/udevblockinfo.csv
 else
    echo -ne "$2,$3,$4,$5,$6,$7,$8,$9,${10}\n">>$ouputPath/udevnetinfo.csv
 fi
}
t udevblock Sdx Storage-Controller-Bus-Number Sdx-Model Host Port  

for i in `ls -l /sys/class/block |grep sd |awk '{print $9}' |grep -v '[0-9]'`
 do
 vol1=$i
   vol2=`udevadm info -a -p /sys/class/block/$i |sed -n 8p|sed 's/\/host.*$//g' |awk -F '/' '{print $NF}'`
   vol4=`udevadm info -a -p /sys/class/block/$i |sed -n 8p|sed 's/^.*host//g' |awk -F '/' '{print $1}'`
   vol3=`udevadm info -a -p /sys/class/block/$i |grep model |sed 's/^.*\="//g'|sed 's/".*$//g'|awk '{OFS="-";print $1,$2}'`
 temp=`udevadm info -a -p /sys/class/block/$i|sed -n 8p |grep expander`
 if [ -n "$temp" ];then
   vol5=`udevadm info -a -p /sys/class/block/$i |sed -n 8p |sed 's/^.*expander//g' |awk -F '/' '{print $2}' `
   t udevblock $vol1 $vol2 $vol3 $vol4 $vol5
 else
    vol5=`udevadm info -a -p /sys/class/block/$i |sed -n 8p|grep port|sed 's/^.*host[0-9]//g'|awk -F '/' '{print $2}'`
   t udevblock $vol1 $vol2 $vol3 $vol4 $vol5
  #echo -ne "\n">>$DIR/result/udevblockinfo.csv
 fi
done
t udevnet Ethx Net-Domain-Bus-Number Micadd State Speed Duplex-State Driver  Net-Bridge-Bus-Number
for i in `ls -l /sys/class/net |grep eth |awk '{print $9}'`
do 
  net=$i
  micadd=` udevadm info -a -p /sys/class/net/$i |grep address |sed 's/^.*\=//g'` 
  state=`  udevadm info -a -p /sys/class/net/$i |grep operstate |sed 's/^.*\=//g'`
  speed=`  udevadm info -a -p /sys/class/net/$i |grep speed |sed 's/^.*\=//g'`
 duplex=`  udevadm info -a -p /sys/class/net/$i |grep duplex|sed 's/^.*\=//g'`
 driver=`  udevadm info -a -p /sys/class/net/$i |grep DRIVERS |sed -n 1p |sed 's/^.*\=//g'`
dnumber=`  udevadm info -a -p /sys/class/net/$i |sed -n 8p |awk -F '/'  '{print $5}'`
brigenum=` udevadm info -a -p /sys/class/net/$i |sed -n 8p |awk -F '/' '{print $4}'`
t udevnet $net $dnumber $micadd $state $speed $duplex $driver  $brigenum
done

