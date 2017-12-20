#!/bin/sh
ouputPath=$1
function t()
{
echo -ne "$1,$2,$3\n">>$ouputPath/memoryinfo.csv 
}
vol1=`dmidecode -t memory |grep "Memory Array" -A 5 |grep Correction |uniq|awk -F ':' '{print $2}' |awk '{OFS="-";print $1,$2}'`
vol2=`dmidecode -t memory |grep "Memory Array" -A 5|grep Max |uniq|awk -F ':' '{print $2}' |awk '{OFS=":";print $1,$2}'`
vol3=`dmidecode -t memory |grep "Memory Array" -A 5|grep Handle |uniq|awk -F ':' '{print $2}'|awk '{OFS="-";print $1,$2}'`
dmidecode -t memory |grep "Memory Device" -A 18 |grep Locator |grep -v Bank >$ouputPath/mem-locat
dmidecode -t memory |grep "Memory Device" -A 18 |grep Size >$ouputPath/mem-size
dmidecode -t memory |grep "Memory Device" -A 18 |grep Type |grep -v Detail >$ouputPath/mem-type
dmidecode -t memory |grep "Memory Device" -A 18 |grep Speed |grep -v Clock >$ouputPath/mem-speed
dmidecode -t memory |grep "Memory Device" -A 18 |grep Manufacturer >$ouputPath/mem-menufacturer
dmidecode -t memory |grep "Memory Device" -A 18 |grep "Clock Speed">$ouputPath/mem-clockspeed
paste  $ouputPath/mem-locat  $ouputPath/mem-menufacturer  $ouputPath/mem-type  $ouputPath/mem-size $ouputPath/mem-speed $ouputPath/mem-clockspeed > $ouputPath/memorytopology.csv
rm -f $ouputPath/mem-temp1
rm -f $ouputPath/mem-temp2
rm -f $ouputPath/mem-locat
rm -f $ouputPath/mem-size
rm -f $ouputPath/mem-type
rm -f $ouputPath/mem-speed
rm -f $ouputPath/mem-menufacturer
rm -f $ouputPath/mem-clockspeed
echo -ne "The following is the memory spec that system supported\n">>$ouputPath/memoryinfo.csv
t Error-Correction-Type Maximum-Capacity Error-Handle 
t $vol1 $vol2 $vol3
 




