#!/bin/sh
ouputPath=$1
function t()
{
echo -ne "$1,$2,$3,$4,$5,$6,$7,$8,$9,${10},${11}\n">>$ouputPath/pcieinfo.csv
}
t Bus-Number vendor-Device Pcie-Version Maxpayload-Supported Maxpayload-Use Readpayload-Supported Link-Supported Link-Use Driver MSI/MSI-X-Status PME-Status
lspci |grep -E -v '[Bb]ridge|USB|SMBus|DMA|Integrated|QPI|peripheral|Home Agent |PIC' |awk '{print $1}' >$ouputPath/pciebus 
for i in `cat $ouputPath/pciebus`
do
  temp=`lspci -s $i -vvvvv |grep Endpoint`
  if [ -n "$temp" ];then
     busnumber=$i
     #vendor=`lspci -n |grep $i |awk -F ':' '{print $3,$4}'|awk '{print $1,$2}'`
      vendor=`lspci -s $i -vvvv |grep Subsystem |awk -F ':' '{print $2}'|awk '{OFS="-"; print $1,$2,$3,$4,$5,$6}'`
     version=`lspci -s $i -vvvv |grep Endpoint |sed 's/^.*Express//g' |sed 's/Endpoint.*$//g'`
     maxpayloadsupported=`lspci -s $i -vvvv |grep DevCap |sed -n 1p |awk -F ',' '{print $1}'|sed 's/^.*MaxPayload//g'|sed 's/bytes//g'`
    maxpayloadlink=`lspci -s $i -vvvv |grep DevCtl -A 2 |grep MaxPayload |awk -F ',' '{print $1}' |awk '{print $2}'`
    readpayloadsupported=`lspci -s $i -vvvv |grep DevCtl -A 2 |grep MaxPayload|awk -F ',' '{print $2}' |awk '{print $2}'`
    linkattr=`lspci -s $i -vvvv |grep LnkCap |awk -F ',' '{print $2,$3}'|sed 's/Speed//g'|sed 's/Width//g'`
    linkinuse=`lspci -s $i -vvvv |grep LnkSta |sed -n 1p |awk -F ':' '{print $2}'|awk '{print $2,$4}' |sed 's/,//g'`
    drivermodule=`lspci -s $i -vvvv |grep "Kernel driver" |awk -F ':' '{print $2}'`
    Interrupt=`lspci -s $i -vvvv |grep "MSI"|grep "Enable+"|awk '{print $3,$4}'|sed 's/://g'`
    PME=`lspci -s $i -vvvv |grep "PME-Enable"|awk '{print $4}'`
  t  $busnumber $vendor $version $maxpayloadsupported $maxpayloadlink $readpayloadsupported $linkattr $linkinuse $drivermodule $Interrupt $PME

fi
done
rm -f $ouputPath/pciebus


