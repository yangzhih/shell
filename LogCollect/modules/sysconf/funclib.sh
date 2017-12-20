#you can add specall function here

function get_asset_info()
{
    export DIR=`pwd`
    if [  -d $DIR/result ];then
        rm -f -r $DIR/result
        mkdir -p $DIR/result
    else 
       mkdir -p $DIR/result
    fi
    #sleep 15
    #chmod +x $DIR/cpucheck.sh 
    #$DIR/cpucheck.sh $DIR/result
    #echo "test====$DIR/result===="
    run_cmd "sh $DIR/cpucheck.sh $DIR/result"
    run_cmd "sh $DIR/memorycheck.sh $DIR/result"
    run_cmd "sh $DIR/udev.sh $DIR/result"
    run_cmd "sh $DIR/pciecheck.sh $DIR/result"
    run_cmd "cp -rf result/ output/"
    run_cmd "rm -rf result"
    #psu
    #run_cmd "ipmitool raw 0x3a 0x72 " "output/psuinfo.txt"
    #for id in "0x00" "0x01" "0x02" "0x03"
    #do
    #    run_cmd "ipmitool raw 0x3a 0x71 $id" "output/psuinfo.txt"
    #done
    return
}

function get_asset_by_cmds()
{
   run_cmd "lscpu" "output/lscmds"
   run_cmd "lshw"  "output/lshw"
   run_cmd "lsblk"  "output/lsblk"
   run_cmd "lspci"  "output/lspci"
   run_cmd "lsscsi"  "output/lsscsi"
   run_cmd "lsusb"  "output/lsusb"
   return
}


function get_fw_version()
{
    run_cmd "echo BMC Version" "output/Fwsversion.txt"
    run_cmd "ipmitool mc info 2>&1 | grep 'Firmware Revision'" "output/Fwsversion.txt"
    run_cmd "echo BIOS Version" "output/Fwsversion.txt"
    run_cmd "dmidecode -t 0 | grep 'Version:'" "output/Fwsversion.txt"
    run_cmd "echo ME Version" "output/Fwsversion.txt"
    run_cmd "ipmitool -b 0 -t  0x2c raw 6 1" "output/Fwsversion.txt"
    run_cmd "echo PSU Version" "output/Fwsversion.txt"
    for id in "0x00" "0x01" "0x02" "0x03"
    do
        run_cmd "ipmitool raw 0x3a 0x71 $id" "output/Fwsversion.txt"
    done
    return
}
