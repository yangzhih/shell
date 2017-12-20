#!/bin/bash
#global variable
#runmethod="remote" #local and remote
#source conf
#. conf
#media="lanplus"
IPMI="$1"

#if [[ ${runmethod} == "local" ]]
#then
#  IPMI="ipmitool"
#elif [[ ${runmethod} == "remote" ]]
#then
#  IPMI="ipmitool -H${IP} -I${media} -U${bmcuser} -P${bmcpasswd}"
#else
#  printf "Please check the value of runmethod in this script.\n"
#  printf "It can only be setted to be 'local' or 'remote'\n"
#  exit 1
#fi

function getOneSensType()
{
  local sen=$1
  ${IPMI} raw 0x04 0x2f ${sen} 2>/dev/null
  return $?
}

#getsensType
#printf "%-6s %-20s %-8s %-8s %-8s\n" "index" "sensName" "sensNumb" "sensType" "readType"
#for i in $(seq 0 $(expr ${#sensNumb[@]} - 1))
#do
#  printf "%03d    %-20s %-8s %-8s %-8s\n" ${i} ${sensName[$i]} ${sensNumb[$i]} ${sensType[$i]} ${readType[$i]}
#done

function getOneSensReadFactor()
{
  local sen=$1
  ${IPMI} raw 0x04 0x23 ${sen} 0x00 2>/dev/null
  return $?
}

function getOneSensRead()
{
  local sen=$1
  ${IPMI} raw 0x04 0x2D ${sen} 2>/dev/null
  return $?
}

#only for threshold-based sensors
function convertRawReading_T()
{
  local byte0="0x$1"
  local byte1="0x$2"
  local byte2="0x$3"
  local byte3="0x$4"
  local bitflag7=
  local bitflag6=
  local bitflag5=
  local realvalue=
  #[7] - 0b = All Event Messages disabled from this sensor
  #[6] - 0b = sensor scannning disabled
  #[5] - 1b = reading/state unavailable
  let "bitflag6=(byte1 & 0x40) >> 6"
  let "bitflag5=(byte1 & 0x20) >> 5"
  if [[ $bitflag6 -eq 0 ]]
  then
    echo "Disabled"
  elif [[ $bitflag5 -eq 1 ]]
  then
    echo "No Reading"
  else
    #let "realvalue= ((M * byte0) + B * (10 ** K1_B_exp)) * (10 ** K2_R_exp)"
    byte0=$(echo "${byte0}" | sed -e 's/0x//g' |tr [a-z] [A-Z])
    byte0=$(echo "ibase=16;$byte0"|bc)
    realvalue=$(echo "scale=3;((${M}*${byte0})+${B}*(10^${K1_B_exp}))*(10^${K2_R_exp})"|bc)
    echo ${realvalue} | grep '\.' >/dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
      echo ${realvalue} | sed -e 's/^\./0\./g;s/[0]*$//g;s/\.$//g'
    else
      echo ${realvalue}
    fi
  fi
}

#only for threshold-based sensors
function parseAlert_T()
{
  local byte0="0x$1"
  local byte1="0x$2"
  local byte2="0x$3"
  local byte3="0x$4"
  local bitflag7=
  local bitflag6=
  local bitflag5=
  
  #[7] - 0b = All Event Messages disabled from this sensor
  #[6] - 0b = sensor scannning disabled
  #[5] - 1b = reading/state unavailable
  let "bitflag7=(byte1 & 0x80) >> 7"
  let "bitflag6=(byte1 & 0x40) >> 6"
  let "bitflag5=(byte1 & 0x20) >> 5"
  if [[ $bitflag6 -eq 0 ]] ;  then
    echo "Disabled"
  elif [[ $bitflag7 -eq 0 ]] ;  then
    echo "OK"
  elif [[ $bitflag5 -eq 1 ]] ;  then
    echo "NA"
  else
    local bitflag=
    local string=""
    let "bitflag=byte2 & 0x01"
    if [[ ${bitflag} -eq 1 ]]
    then
      string+="lower non-critical, "
    fi
    
    let "bitflag=(byte2>>1) & 0x01"
    if [[ ${bitflag} -eq 1 ]]
    then
      string+="lower critical, "
    fi
    
    let "bitflag=(byte2>>2) & 0x01"
    if [[ ${bitflag} -eq 1 ]]
    then
      string+="lower non-recoverable, "
    fi
    
    let "bitflag=(byte2>>3) & 0x01"
    if [[ ${bitflag} -eq 1 ]]
    then
      string+="upper non-critical, "
    fi
    
    let "bitflag=(byte2>>4) & 0x01"
    if [[ ${bitflag} -eq 1 ]]
    then
      string+="upper critical, "
    fi
    
    let "bitflag=(byte2>>5) & 0x01"
    if [[ ${bitflag} -eq 1 ]]
    then
      string+="upper non-critical, "
    fi
    #string=$(echo ${string} | sed  's/, $//g')
    if [[ "x${string}" != "x" ]]
    then
      string+=" asserted"
    else
      string="OK"
    fi
    echo ${string}
  fi
}

#only for discrete-based sensors
function convertRawReading_D()
{
  local byte0="0x$1"
  local byte1="0x$2"
  local byte2="0x$3"
  local byte3="0x$4"
  local bitflag7=
  local bitflag6=
  local bitflag5=
  #[7] - 0b = All Event Messages disabled from this sensor
  #[6] - 0b = sensor scannning disabled
  #[5] - 1b = reading/state unavailable
  let "bitflag6=(byte1 & 0x40) >> 6"
  let "bitflag5=(byte1 & 0x20) >> 5"
  if [[ $bitflag6 -eq 0 ]]
  then
    echo "Disabled"
  elif [[ $bitflag5 -eq 1 ]]
  then
    echo "No Reading"
  else
    echo "0 reserved"
  fi
}

function PhysicalSecurity()
{
  #snesor type code is 0x05
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "General Chassis intrusion, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Drive Bay intrusion, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "I/O Card area intrusion, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Processor area intrusion, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "System unplugged from LAN, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "nauthorized dock, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FAN area intrusion, ";fi
}

function PlatformSecurity()
{
  #snesor type code is 0x06
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Front Panel Lockout violation attempted, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Pre-boot password violation - user password, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Pre-boot password violation - setup password, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Pre-boot password violation - network boot password, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Other pre-boot password violation, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Out-of-band access password violation, ";fi
}

function Processor()
{
  #snesor type code is 0x07
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "IERR, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Thermal Trip, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRB1/BIST failure, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRB2/Hang in POST failure, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRB3/Processor startup/init failure, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Configuration Error, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "SM BIOS Uncorrectable CPU-complex Error, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Presence detected, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Disabled, ";fi
  let "bitvalue=value >> 9 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Terminator presence detected, ";fi
  let "bitvalue=value >> 10 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Throttled, ";fi
  let "bitvalue=value >> 11 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Machine Check Exception(Uncorrectable), ";fi
  let "bitvalue=value >> 12 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Correctable Machine Check Error, ";fi
}

function PowerSupply()
{
  #snesor type code is 0x08
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Presence detected, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power Supply Failure detected, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Predictive Failure, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power Supply input lost (AC/DC), ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power Supply input lost or out-of-range, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power Supply input out-of-range, but present, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Configuration error(The Event Data 3 field provides a more detailed definition of the error), ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power Supply Inactive (in standby state), ";fi
}

function PowerUnit()
{
  #snesor type code is 0x09
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power off/down, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power cycle, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "240VA power down, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Interlock power down, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "AC lost, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Soft-power control failure, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Failure detected, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Predictive failure, ";fi
}

function Memory()
{
  #snesor type code is 0x0C
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Correctable ECC, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Uncorrectable ECC, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Parity, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Memory Scrub Failed, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Memory Device Disabled, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Correctable ECC logging limit reached, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Presence Detected, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Configuration Error, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Spare, ";fi
  let "bitvalue=value >> 9 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Memory Automatically Throttled, ";fi
  let "bitvalue=value >> 10 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Critical Overtemperature, ";fi
}

function DriveSlot()
{
  #snesor type code is 0x0D
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Drive Presence, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Drive Fault, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Predictive Failure, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Hot Spare, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Parity Check In Progress, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "In Critical Array, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "In Failed Array, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Rebuild In Progress, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Rebuild Aborted, ";fi
}

function SystemFirmwareProgress()
{
  #snesor type code is 0x0f
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "System Firmware Error (POST Error), ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "System Firmware Hang, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "System Firmware Progress, ";fi
}

function EventLoggingDisabled()
{
  #snesor type code is 0x10
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Correctable memory error logging disabled, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Event logging disabled, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Log area reset/cleared, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "All Event Logging Disabled, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "SEL Full, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "SEL Almost Full, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Correctable Machine Check Error Logging Disabled, ";fi
}

function Watchdog1()
{
  #snesor type code is 0x11
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "BIOS Reset, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS Reset, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS Shut Down, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS Power Down, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS Power Cycle, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS NMI/Diag Interrupt, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS Expired, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "pre-timeout Interrupt, ";fi
}

function SystemEvent()
{
  #snesor type code is 0x12
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "System Reconfigured, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OEM System boot event, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Undetermined system hardware failure, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Entry added to auxiliary log, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "PEF Action, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Timestamp Clock Sync, ";fi
}

function CriticalInterrupt()
{
  #snesor type code is 0x13
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Front Panel NMI / Diagnostic Interrupt, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Bus Timeout, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "I/O Channel check NMI, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Software NMI, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "PCI PERR, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "PCI SERR, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "EISA failsafe timeout, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Bus Correctable error, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Bus Uncorrectable error, ";fi
  let "bitvalue=value >> 9 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Fatal NMI, ";fi
  let "bitvalue=value >> 10 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Bus Fatal Error, ";fi
  let "bitvalue=value >> 11 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Bus Degraded, ";fi
}

function ButtonOrSwitch()
{
  #snesor type code is 0x14
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power Button pressed, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Sleep Button pressed, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Reset Button pressed, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Latch open, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU service request button, ";fi
}

function ChipSet()
{
  #snesor type code is 0x19
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Soft Power Control Failure, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Thermal Trip, ";fi
}

function CableOrInterconnect()
{
  #snesor type code is 0x1B
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Cable/Interconnect is connected, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Configuration Error - Incorrect cable connected / Incorrect interconnection, ";fi
}

function  SystemBootOrRestartInitiated()
{
  #snesor type code is 0x1D
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Initiated by power up, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Initiated by hard reset, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Initiated by warm reset, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "User requested PXE boot, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Automatic boot to diagnostic, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS initiated hard reset, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS initiated warm reset, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "System Restart, ";fi
}

function BootError()
{
  #snesor type code is 0x1e
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "No bootable media, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Non-bootable disk in drive, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "PXE server not found, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Invalid boot sector, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Timeout waiting for selection, ";fi
}

function BaseOSBootOrInstallationStatus()
{
  #snesor type code is 0x1f
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "A: boot completed, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "C: boot completed, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "PXE boot completed, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Diagnostic boot completed, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "CD-ROM boot completed, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "ROM boot completed, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "boot completed - device not specified, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Base OS/Hypervisor Installation started, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Base OS/Hypervisor Installation completed, ";fi
  let "bitvalue=value >> 9 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Base OS/Hypervisor Installation aborted, ";fi
  let "bitvalue=value >> 10 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Base OS/Hypervisor Installation failed, ";fi
}

function OSStopOrShutdown()
{
  #snesor type code is 0x20
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Error during system startup, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Run-time critical stop, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS graceful stop, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "OS graceful shutdown, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "PEF initiated soft shutdown, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Agent not responding, ";fi
}

function SlotOrConnector()
{
  #snesor type code is 0x21
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Fault Status, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Identify Status, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Device Installed, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Ready for Device Installation, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Ready for Device Removal, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Slot Power is Off, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Device Removal Request, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Interlock, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Slot is Disabled, ";fi
  let "bitvalue=value >> 9 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Spare Device, ";fi
}

function SystemACPIPowerState()
{
  #snesor type code is 0x22
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S0/G0: working, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S1: sleeping with system hw & processor context maintained, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S2: sleeping, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S3: sleeping, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S4: non-volatile sleep/suspend-to-disk, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S5/G2: soft-off, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S4/S5: soft-off, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "G3: mechanical off, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Sleeping in S1/S2/S3 state, ";fi
  let "bitvalue=value >> 9 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "G1: sleeping, ";fi
  let "bitvalue=value >> 10 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "S5: entered by override, ";fi
 let "bitvalue=value >> 11 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Legacy ON state, ";fi
 let "bitvalue=value >> 12 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Legacy OFF state, ";fi
 let "bitvalue=value >> 14 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Unknown, ";fi
}

function Watchdog2()
{
  #snesor type code is 0x23
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Timer expired, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Hard reset, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power down, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Power cycle, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "reserved, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "reserved, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "reserved, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "reserved, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Timer interrupt, ";fi
}

function PlatformAlert()
{
  #snesor type code is 0x24
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Platform generated page, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Platform generated LAN alert, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Platform Event Trap generated, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Platform generated SNMP trap, ";fi
}

function EntityPresence()
{
  #snesor type code is 0x25
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Entity Present, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Entity Absent, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Entity Disabled, ";fi
}

function LAN()
{
  #snesor type code is 0x27
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "LAN Heartbeat Lost, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "LAN Heartbeat, ";fi
}

function ManagementSubsystemHealth()
{
  #snesor type code is 0x28
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Sensor access degraded or unavailable, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Controller access degraded or unavailable, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Management controller off-line, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Management controller unavailable, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Sensor failure, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU failure, ";fi
}

function Battery()
{
  #snesor type code is 0x29
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "battery low (predictive failure), ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "battery failed, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "battery presence detected, ";fi
}

function SessionAudit()
{
  #snesor type code is 0x2A
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Session Activated, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Session Deactivated, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Invalid Username or Password, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Invalid password disable, ";fi
}

function VersionChange()
{
  #snesor type code is 0x2B
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Hardware change detected, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Firmware or software change detected, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Hardware incompatibility detected, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Firmware or software incompatibility detected, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Invalid or unsupported hardware version, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Invalid or unsupported firmware or software version, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Hardware change success, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Firmware or software change success, ";fi
}

function FRUState()
{
  #snesor type code is 0x2C
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Not Installed, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Inactive, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Activation Requested, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Activation in Progress, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Active, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Deactivation Requested, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Deactivation in Progress, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Communication lost, ";fi
}

function FRUHotSwap()
{
  #snesor type code is 0xF0
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M0, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M1, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M2, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M3, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M4, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M5, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M6, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "FRU Transition to M7, ";fi
}

function IPMB0Status()
{
  #snesor type code is 0xF1
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "IPMB-A disabled, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "IPMB-A enabled, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "IPMB-A disabled, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "IPMB-A enabled, ";fi
}

function ModuleHotSwap()
{
  #snesor type code is 0xF2
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Module Handle Closed, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Module Handle Opened, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Quiesced, ";fi
}

#only for discrete-based sensors
function parseAlert_D()
{
  local byte0="0x$1"
  local byte1="0x$2"
  local byte2="$3"
  local byte3="$4"
  local byte4="0x$5" #this byte is sensor type
  local bitflag7=
  local bitflag6=
  local bitflag5=

  #[7] - 0b = All Event Messages disabled from this sensor
  #[6] - 0b = sensor scannning disabled
  #[5] - 1b = reading/state unavailable
  let "bitflag7=(byte1 & 0x80) >> 7"
  let "bitflag6=(byte1 & 0x40) >> 6"
  let "bitflag5=(byte1 & 0x20) >> 5"
  if [[ $bitflag6 -eq 0 ]]
  then
    echo "Disabled"
  elif [[ $bitflag7 -eq 0 ]]
  then
    echo "OK"
  elif [[ $bitflag5 -eq 1 ]]
  then
    echo "NA"
  else
    case $byte4 in
      0x05) PhysicalSecurity ${byte2} ${byte3};;
      0x06) PlatformSecurity ${byte2} ${byte3};;
      0x07) Processor ${byte2} ${byte3};;
      0x08) PowerSupply ${byte2} ${byte3};;
      0x09) PowerUnit ${byte2} ${byte3};;
      0x0c) Memory ${byte2} ${byte3};;
      0x0d) DriveSlot ${byte2} ${byte3};;
      0x0f) SystemFirmwareProgress ${byte2} ${byte3};;
      0x10) EventLoggingDisabled ${byte2} ${byte3};;
      0x11) Watchdog1 ${byte2} ${byte3};;
      0x12) SystemEvent ${byte2} ${byte3};;
      0x13) CriticalInterrupt ${byte2} ${byte3};;
      0x14) ButtonOrSwitch ${byte2} ${byte3};;
      0x19) ChipSet ${byte2} ${byte3};;
      0x1b) CableOrInterconnect ${byte2} ${byte3};;
      0x1d) SystemBootOrRestartInitiated ${byte2} ${byte3};;
      0x1e) BootError ${byte2} ${byte3};;
      0x1f) BaseOSBootOrInstallationStatus ${byte2} ${byte3};;
      0x20) OSStopOrShutdown ${byte2} ${byte3};;
      0x21) SlotOrConnector ${byte2} ${byte3};;
      0x22) SystemACPIPowerState ${byte2} ${byte3};;
      0x23) Watchdog2 ${byte2} ${byte3};;
      0x24) PlatformAlert ${byte2} ${byte3};;
      0x25) EntityPresence ${byte2} ${byte3};;
      0x27) LAN ${byte2} ${byte3};;
      0x28) ManagementSubsystemHealth ${byte2} ${byte3};;
      0x29) Battery ${byte2} ${byte3};;
      0x2a) SessionAudit ${byte2} ${byte3};;
      0x2b) VersionChange ${byte2} ${byte3};;
      0x2c) FRUState ${byte2} ${byte3};;
      0xf0) FRUHotSwap ${byte2} ${byte3};;
      0xf1) IPMB0Status ${byte2} ${byte3};;
      0xf2) ModuleHotSwap ${byte2} ${byte3};;
      *) printf "sensor type code is %s" ${byte4}
    esac
  fi
}

function parseReadType02()
{
  #event/reading type code is 0x02
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Transition to Idle, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Transition to Active, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Transition to Busy, ";fi
}

function parseReadType03()
{
  #event/reading type code is 0x03
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "State Deasserted, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "State Asserted, ";fi
}

function parseReadType04()
{
  #event/reading type code is 0x04
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Predictive Failure deasserted, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Predictive Failure asserted, ";fi
}

function parseReadType05()
{
  #event/reading type code is 0x05
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Limit Not Exceeded, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Limit Exceeded, ";fi
}

function parseReadType06()
{
  #event/reading type code is 0x06
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Performance Met, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Performance Lags, ";fi
}

function parseReadType07()
{
  #event/reading type code is 0x07
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to OK, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Non-Critical from OK, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Critical from less severe, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Non-recoverable from less severe, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Non-Critical from more severe, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Critical from Non-recoverable, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Non-recoverable, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Monitor, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Informational, ";fi
}

function parseReadType08()
{
  #event/reading type code is 0x08
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Device Removed / Device Absent, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Device Inserted / Device Present, ";fi
}

function parseReadType09()
{
  #event/reading type code is 0x09
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Device Disabled, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Device Enabled, ";fi
}

function parseReadType0A()
{
  #event/reading type code is 0x0a
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Running, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to In Test, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Power Off, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to On Line, ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Off Line, ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Off Duty, ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Degraded, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "transition to Power Save, ";fi
  let "bitvalue=value >> 8 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Install Error, ";fi
}

function parseReadType0B()
{
  #event/reading type code is 0x0B
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Fully Redundant, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Redundancy Lost, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Redundancy Degraded, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Non-redundant(offset 03h), ";fi
  let "bitvalue=value >> 4 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Non-redundant(offset 04h), ";fi
  let "bitvalue=value >> 5 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Non-redundant(offset 05h), ";fi
  let "bitvalue=value >> 6 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Redundancy Degraded from Fully Redundant, ";fi
  let "bitvalue=value >> 7 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "Redundancy Degraded from Non-redundant, ";fi
}

function parseReadType0C()
{
  #event/reading type code is 0x0C
  local value="0x${2}${1}"
  local bitvalue=
  let "bitvalue=value >> 0 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "D0 Power State, ";fi
  let "bitvalue=value >> 1 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "D1 Power State, ";fi
  let "bitvalue=value >> 2 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "D2 Power State, ";fi
  let "bitvalue=value >> 3 & 0x01"
  if [[ $bitvalue -eq 1 ]]; then echo -n "D3 Power State, ";fi
}


function getOneSensThresholds()
{
  local sen=$1
  ${IPMI} raw 0x04 0x27 ${sen} 2>/dev/null
  return $?
}

function getOneSensEventEnable()
{
  local sen=$1
  ${IPMI} raw 0x04 0x29 ${sen} 2>/dev/null
  return $?
}


sdrElistFile="output/sdr_elist_all.txt"
function getSDRinfo()
{
  if [ -f "${sdrElistFile}" ] ; then
    cat "${sdrElistFile}" 2>/dev/null
  else
    ${IPMI} sdr elist all 2>/dev/null
  fi
  return $?
}

sensName=""
sensNumb=""
function parseSDR()
{
  local sdrcontent=$1
  sensName=($(echo "${sdrcontent}" | awk -F'|' '{print $1}' | sed 's/ //g'))
  sensNumb=($(echo "${sdrcontent}" | awk -F'|' '{print $2}' | sed -e 's/ //g;s/h//g'))
}

sensType=""
readType=""
function getAllSensType()
{
  local sen
  local index=0
  local retvalue
  for sen in ${sensNumb[@]}
  do
    sen="0x${sen}"
    retvalue=$(${IPMI} raw 0x04 0x2f ${sen} 2>/dev/null)
    if [ $? -ne 0 ] ; then
      sensType[${index}]="00"
      readType[${index}]="00"
    else
      sensType[${index}]=$(echo "${retvalue}" | awk '{print $1}' | sed 's/ //g')
      readType[${index}]=$(echo "${retvalue}" | awk '{print $2}' | sed 's/ //g')
    fi
    let "index++"
  done
}

function mainFunc()
{
  thesdr=$(getSDRinfo)
  sensName=($(echo "${thesdr}" | awk -F'|' '{print $1}' | sed 's/ //g'))
  sensNumb=($(echo "${thesdr}" | awk -F'|' '{print $2}' | sed -e 's/ //g;s/h//g'))

  #getAllSensType
  local index=0
  local sen=""
  printf "%-17s | %-13s | %-13s | %-13s | %s\n" "#Sensor Name" "Sensor Number" "Sensor Type" "Reading Value" "Alerts/Events"
  for sen in ${sensNumb[@]}
  do
    sen="0x${sen}"
    ${IPMI} raw 0x04 0x2f ${sen} 2>/dev/null
    ${IPMI} raw 0x04 0x23 ${sen} 0x00 2>/dev/null
    retvalue=$(getOneSensReadFactor $sen)
    parseReadFactor $retvalue
    readvalue=$(getOneSensRead ${sen})
    reading=$(convertRawReading_T ${readvalue})
    alerts=$(parseAlert_T ${readvalue})
}

function mainFunc()
{
  thesdr=$(getSDRinfo)
  #parseSDR "${thesdr}"
  #local sdrcontent=$1
  sensName=($(echo "${thesdr}" | awk -F'|' '{print $1}' | sed 's/ //g'))
  sensNumb=($(echo "${thesdr}" | awk -F'|' '{print $2}' | sed -e 's/ //g;s/h//g'))
  getAllSensType
  local index=0
  local sen=""
  printf "%-17s | %-13s | %-13s | %-13s | %s\n" "#Sensor Name" "Sensor Number" "Sensor Type" "Reading Value" "Alerts/Events"
  for sen in ${sensNumb[@]}
  do
    sen="0x${sen}"
    if [[ "x_${readType[$index]}" == "x_01" ]]
    then
      retvalue=$(getOneSensReadFactor $sen)
      parseReadFactor $retvalue
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_T ${readvalue})
      alerts=$(parseAlert_T ${readvalue})
    elif [[ "x_${readType[$index]}" == "x_6f" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseAlert_D ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_02" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType02 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_03" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType03 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_04" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType04 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_05" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType05 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_06" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType06 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_07" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType07 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_08" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType08 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_09" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType09 ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_0a" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType0A ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_0b" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType0B ${readvalue} ${sensType[$index]})
    elif [[ "x_${readType[$index]}" == "x_0c" ]]
    then
      readvalue=$(getOneSensRead ${sen})
      reading=$(convertRawReading_D ${readvalue})
      alerts=$(parseReadType0C ${readvalue} ${sensType[$index]})
    else
      readvalue=$(getOneSensRead ${sen})
    fi
    alerts=$(echo "${alerts}" | sed -e 's/, $//g')
    printf "%-17s | %-13s | %-13s | %-13s | %s\n" "${sensName[$index]}" "${sensNumb[$index]}h" "${sensType[$index]}h" "${reading}" "${alerts}"
    let "index++"
  done
}

mainFunc

