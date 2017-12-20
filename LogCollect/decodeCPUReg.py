#!/usr/bin/python
#-*- coding: utf-8 -*-

#date: 20170116
#.py logFolder
#log should be collected by inspurDiagInfoCollectTools
#will parse cpu registers reading by real time script  and blackbox.
#output parsed file will be created in bmc/logs, named parsed_csr.txt and parsed_msr.txt

import os
import sys
#import requests
import json
import threading
import mcd
import mcd_ivt
import csr
import time
#import rpc.rpc as rpc
#import error.error as Error

memTypeMap={
0x01: "Other",
0x02: "Unknown",
0x03: "DRAM",
0x04: "EDRAM",
0x05: "VRAM",
0x06: "SRAM",
0x07: "RAM",
0x08: "ROM",
0x09: "FLASH",
0x0A: "EEPROM",
0x0B: "FEPROM",
0x0C: "EPROM",
0x0D: "CDRAM",
0x0E: "3DRAM",
0x0F: "SDRAM",
0x10: "SGRAM",
0x11: "RDRAM",
0x12: "DDR",
0x13: "DDR2",
0x14: "DDR2 FB-DIMM",
0x15: "Reserved",
0x16: "Reserved",
0x17: "Reserved",
0x18: "DDR3",
0x19: "FBD2",
0x1A: "DDR4"
}

MEMNameBaoT=[
 	"CHA_0",
 	"CHA_1",
 	"CHA_2",
 	"CHB_0",
 	"CHB_1",
 	"CHB_2",
 	"CHC_0",
 	"CHC_1",
 	"CHC_2",
 	"CHD_0",
 	"CHD_1",
 	"CHD_2",
 	"CHE_0",
 	"CHE_1",
	"CHE_2",
 	"CHF_0",
 	"CHF_1",
	"CHF_2",
 	"CHG_0",
 	"CHG_1",
	"CHG_2",
 	"CHH_0",
 	"CHH_1",
	"CHH_2"]

MEMNameShuY=[
 	"CHA_0",
 	"CHA_1",
 	"CHA_2",
 	"CHB_0",
 	"CHB_1",
 	"CHB_2",
 	"CHC_0",
 	"CHC_1",
 	"CHC_2",
 	"CHD_0",
 	"CHD_1",
 	"CHD_2",
 	"CHE_0",
 	"CHE_1",
 	"CHF_0",
 	"CHF_1",
 	"CHG_0",
 	"CHG_1",
 	"CHH_0",
 	"CHH_1"]

def makejson(web_resp,name):
    nPos=web_resp.find('[')
    if nPos < 0:
    	return 1
    nPos=web_resp.find(']')
    if nPos < 0:
    	return 1
    info=web_resp.split('[')[1]
    info=info.split(']')[0]
    info='{\''+name+'\''+':'+'['+info+']}'
    info=info.replace('\'',"\"")
    return info

#index is [info...] in file's index. from 1 to N
def makeSlecetedJson(web_resp,name, index):
    nPos=web_resp.find('[')
    if nPos < 0:
    	return 1
    nPos=web_resp.find(']')
    if nPos < 0:
    	return 1
    info=web_resp.split('[')[index]
    info=info.split(']')[0]
    info='{\''+name+'\''+':'+'['+info+']}'
    info=info.replace('\'',"\"")
    return info

def getCPUInfo4Socket():
    #print 'test getCPUInfo'
    #filePath=sys.argv[1]
    fileName=logJasonPath+ 'getHWInfo.asp'
    if False==os.path.exists(fileName):
    	#print 'File', fileName, 'Not Exist'
    	return
    f=open(fileName, 'r+')
    tmpinfo=f.read()

    #print tmpinfo
    resp = makejson(tmpinfo,'cpu')
    if resp == 1:
    	return
    #print resp
    json_info=json.loads(resp)
    #print json_info
    #return info
    #print 'test222'
    #print json_info['cpu'][0]['CPUSocket']
    count=len(json_info['cpu'])-1
    #print 'test333'
    #print count
    if count >0:
 	for cnt in range(count):
		#print  json_info['cpu'][cnt]['CPUSocket'], json_info['cpu'][cnt]['CPUVersion']
		tmpString=json_info['cpu'][cnt]['CPUSocket'] + '|' + json_info['cpu'][cnt]['CPUVersion'] + '|' + 'CPU#' + '\n'
		#print tmpString
		f.write(tmpString)
    f.close()
    return

def getCPUInfo2Socket():
    #print 'test getCPUInfo2Socket'
    #filePath=sys.argv[1]
    fileName=logJasonPath+ 'getcpuinfo.asp'
    if False==os.path.exists(fileName):
    	#print 'File', fileName, 'Not Exist'
    	return
    f=open(fileName, 'r+')
    tmpinfo=f.read()

    #print tmpinfo
    resp = makejson(tmpinfo,'cpu')
    if resp == 1:
    	return
    #print resp
    json_info=json.loads(resp)
    #print json_info
    #return info
    #print 'test222'
    #print json_info['cpu'][0]['CPUSocket']
    count=len(json_info['cpu'])-1
    #print 'test333'
    #print count
    if count >0:
 	for cnt in range(count):
		#print  json_info['cpu'][cnt]['CPUSocket'], json_info['cpu'][cnt]['CPUVersion']
		tmpString='CPU' + str(json_info['cpu'][cnt]['CPUID']) + '|' + json_info['cpu'][cnt]['Model'] + '|' + 'CPU#' + '\n'
		#print tmpString
		f.write(tmpString)
    f.close()
    return


def getMemInfo4Socket():
	#print 'test getMemInfo'
	#filePath=sys.argv[1]
	fileName=logJasonPath+ 'getHWInfo.asp'
	if False==os.path.exists(fileName):
	    	#print 'File', fileName, 'Not Exist'
	    	return
	f=open(fileName, 'r+')
	tmpinfo=f.read()

	#print tmpinfo
	resp = makeSlecetedJson(tmpinfo,'mem', 2)
	if resp == 1:
    		return
	#print resp
	json_info=json.loads(resp)
	#print 'test222'
	#print json_info
	#print json_info['mem'][0]['MemDimm']
	count=len(json_info['mem'])-1
	#print 'test333'
	#print count
	if count >0:
		for cnt in range(count):
			#print  json_info['mem'][cnt]['MemDimm'], json_info['mem'][cnt]['MemManufacturer']
			tmpString=json_info['mem'][cnt]['MemDimm'] + '|' + json_info['mem'][cnt]['MemManufacturer'] + '|' + str(json_info['mem'][cnt]['memSize'])  + '|' +  str(json_info['mem'][cnt]['MemSpeed']) +  '|'  + memTypeMap[json_info['mem'][cnt]['MemType']] + '|' + 'MEM#' +  '\n'			
			#print tmpString
			f.write(tmpString)
	f.close()
	return


def getMemInfo2Socket():
	#print 'test getMemInfo'
	#filePath=sys.argv[1]
	fileName=logJasonPath+ 'getmeminfo.asp'
	if False==os.path.exists(fileName):
	    	#print 'File', fileName, 'Not Exist'
	    	return
	f=open(fileName, 'r+')
	tmpinfo=f.read()

	#print tmpinfo
	resp = makeSlecetedJson(tmpinfo,'mem', 1)
	if resp == 1:
    		return
	#print resp
	json_info=json.loads(resp)
	#print 'test222'
	#print json_info
	#print json_info['mem'][0]['MemDimm']
	count=len(json_info['mem'])-1
	#print 'test333'
	#print count
	if count >0:
		for cnt in range(count):
			if json_info['mem'][cnt]['Present'] == 1:
				#print  json_info['mem'][cnt]['MEMID'], json_info['mem'][cnt]['Manufacture']
				tmpMemId=json_info['mem'][cnt]['MEMID']
				tmpMemLocat=''
				if count == 16:
					#print MEMNameShuY[tmpMemId]
					tmpMemLocat=MEMNameShuY[tmpMemId]
				if count == 24:
					tmpMemLocat=MEMNameBaoT[tmpMemId]
				if count >= 96:
					tmpMemLocat = 'Node_' + str(tmpMemId/ 12) + '_Ch_' + str( (tmpMemId % 12)/3 ) + '_Dimm' + str(tmpMemId% 3);
					#tmpMemLocat=tmpMemId

				#print tmpMemLocat
				tmpString=tmpMemLocat + '|' + json_info['mem'][cnt]['Manufacture'] + '|' + str(json_info['mem'][cnt]['Capacity'])  + '|' +  str(json_info['mem'][cnt]['Speed']) +  '|'  + ' ' + '|' + 'MEM#' +  '\n'
				#print tmpString
				f.write(tmpString)
	f.close()
	return


def getPsuInfo():
	#print 'test getPsuInfo'
	#filePath=sys.argv[1]
	fileName=logJasonPath+ 'getallpsuinfo.asp'
	if False==os.path.exists(fileName):
	    	#print 'File', fileName, 'Not Exist'
	    	return
	f=open(fileName, 'r+')
	tmpinfo=f.read()

	#print tmpinfo
	resp = makeSlecetedJson(tmpinfo,'psu', 1)
	if resp == 1:
    		return
	#print resp
	json_info=json.loads(resp)
	#print 'test222'
	#print json_info
	#print json_info['mem'][0]['MemDimm']
	count=len(json_info['psu'])-1
	#print 'test333'
	#print count
	if count >0:
		for cnt in range(count):
			#if json_info['psu'][cnt]['Present'] == 1:
				#print  json_info['mem'][cnt]['MEMID'], json_info['mem'][cnt]['Manufacture']
			tmpPsuID=json_info['psu'][cnt]['Id']
			tmpPsuMaxPower=json_info['psu'][cnt]['OutputPowerMax']
			if tmpPsuMaxPower == 0 or tmpPsuMaxPower ==65535:
				tmpPsuMaxPower="NA"
			tmpMFRModel=json_info['psu'][cnt]['MFRModel']
			tmpMFRID=json_info['psu'][cnt]['MFRID']
			tmpSN=json_info['psu'][cnt]['SN']
			tmpTemp=json_info['psu'][cnt]['Temperature']
			if tmpTemp == 0 or tmpTemp ==65535:
				tmpTemp="NA"
			tmpOutPower=json_info['psu'][cnt]['PwrInWatts']
			if tmpOutPower == 0 or tmpOutPower ==65535:
				tmpOutPower="NA"
			tmpInputPower=json_info['psu'][cnt]['InputPower']
			if tmpInputPower == 0 or tmpInputPower ==65535:
				tmpInputPower="NA"
			tmpFW=json_info['psu'][cnt]['FWVersion']

			tmpString='PSU' + str(tmpPsuID) + '|' + tmpMFRID + '|' + tmpMFRModel + '|' +  str(tmpPsuMaxPower) +  '|'  + tmpSN + '|' + str(tmpOutPower) +  '|' + str(tmpInputPower) + '|' + str(tmpTemp) + '|'  + tmpFW + '|' + 'PSU#' + '\n'
			#print tmpString
			f.write(tmpString)
	f.close()
	return

PCI_IDS_LIST={
            0x1000:"LSI Logic / Symbios Logic",
            0x1002:"Advanced Micro Devices, Inc",
            0x1077:"QLogic Corp.",  
            0x10df:"Emulex Corporation",
            0x1166:"Broadcom",
            0x10de:"NVIDIA Corporation",
            0x11f8:"PMC-Sierra Inc.",
            0x19a2:"Emulex Corporation", 
            0x1fc1:"QLogic, Corp.",
            0x8086:"Intel Corporation" }

PCI_IDS_DEVICE_LIST={
            0x1000:{0x005b:"MegaRAID SAS 2208",0x005d:"MegaRAID SAS-3 3108",0x005f:"MegaRAID SAS-3 3008"},
            0x8086:{0x10c9:"82576 Gigabit Network Connection",
                0x10f8:"82599 10 Gigabit Dual Port Backplane Connection",
                0x10fb:"82599ES 10-Gigabit SFI/SFP+ Network Connection",
                0x1521:"I350 Gigabit Network Connection",
                0x1529:"82599 10 Gigabit Dual Port Network Connection with FCoE",
                0x152a:"82599 10 Gigabit Dual Port Backplane Connection with FCoE"}}


ListPCIEDevType=["Other",#0x00
"Mass Storage Controller",#0x01
"Network Controller",#0x02
"Display Controller",#0x03
"Multimedia Device",#0x04
"Memory Controller",#0x05
"Bridge Device",#0x06
"Simple Communication Controllers",#0x07
"Base System Peripherals",#0x08
"Input Devices",#0x09
"Docking Stations",#0x0a
"Processors",#0x0b
"Serial Bus Controllers",#0x0c
"Wireless Controller",#0x0d
"Intelligent I/0 Controllers",#0x0e
"Satellite Communication Controllers",#0x0f
"Encryption/Decryption Controllers",#0x10
"Data Acquisitions and Signal Processing Controllers"]#0x11

def getPcieInfo4Socket():
	#print 'test getPcieInfo'
	#filePath=sys.argv[1]
	fileName=logJasonPath+ 'getHWInfo.asp'
	if False==os.path.exists(fileName):
	    	#print 'File', fileName, 'Not Exist'
	    	return
	f=open(fileName, 'r+')
	tmpinfo=f.read()

	#print tmpinfo
	resp = makeSlecetedJson(tmpinfo,'pcie', 3)
	if resp == 1:
    		return
	#print resp
	json_info=json.loads(resp)
	#print 'test222'
	#print json_info
	#print json_info['mem'][0]['MemDimm']
	count=len(json_info['pcie'])-1
	#print 'test333'
	#print count
	if count >0:
		for cnt in range(count):
			#if json_info['pcie'][cnt]['Present'] == 1:
			#print  json_info['mem'][cnt]['MEMID'], json_info['mem'][cnt]['Manufacture']
			tmpPCIESlot=json_info['pcie'][cnt]['PCIESlot']
			tmpPCIEClass=json_info['pcie'][cnt]['PCIEClass']
			if tmpPCIEClass < len(ListPCIEDevType):
					tmpType=ListPCIEDevType[tmpPCIEClass]

			tmpPCIESubClass=json_info['pcie'][cnt]['PCIESubClass']

			tmpPCIEVendorId=json_info['pcie'][cnt]['PCIEVendorId']
			if None != PCI_IDS_LIST.get(tmpPCIEVendorId):
				tmpPCIEVendorId=PCI_IDS_LIST.get(tmpPCIEVendorId)
			else:
				tmpPCIEVendorId=hex(tmpPCIEVendorId)

			tmpPCIEDeviceId=json_info['pcie'][cnt]['PCIEDeviceId']			
			if   None != PCI_IDS_DEVICE_LIST.get(tmpPCIEVendorId):
				if PCI_IDS_DEVICE_LIST.get(tmpPCIEVendorId).get(tmpPCIEDeviceId) != None:
					tmpPCIEDeviceId=PCI_IDS_DEVICE_LIST.get(tmpPCIEVendorId).get(tmpPCIEDeviceId) 
				else:
					tmpPCIEDeviceId=hex(tmpPCIEDeviceId)
			else:
				tmpPCIEDeviceId=hex(tmpPCIEDeviceId)

			tmpPCIELinkSpeed=json_info['pcie'][cnt]['PCIELinkSpeed']
			tmpPCIELinkWidth=json_info['pcie'][cnt]['PCIELinkWidth']

			tmpString=tmpPCIESlot + '|' + str(tmpType) + '|' + str(tmpPCIEVendorId) + '|' +  str(tmpPCIEDeviceId) +  '|'  + tmpPCIELinkSpeed + '|' + tmpPCIELinkWidth +  '|' + 'PCIE#' + '\n'
			#print tmpString
			f.write(tmpString)
	f.close()
	return


def getPcieInfo2Socket():
	#print 'test getPcieInfo'
	#filePath=sys.argv[1]
	fileName=logJasonPath+ 'getpcieinfo.asp'
	if False==os.path.exists(fileName):
	    	#print 'File', fileName, 'Not Exist'
	    	return
	f=open(fileName, 'r+')
	tmpinfo=f.read()

	#print tmpinfo
	resp = makeSlecetedJson(tmpinfo,'pcie', 1)
	if resp == 1:
    		return
	#print resp
	json_info=json.loads(resp)
	#print 'test222'
	#print json_info
	#print json_info['mem'][0]['MemDimm']
	count=len(json_info['pcie'])-1
	#print 'test333'
	#print count
	if count >0:
		for cnt in range(count):
			if json_info['pcie'][cnt]['Present'] == 1:
			#print  json_info['mem'][cnt]['MEMID'], json_info['mem'][cnt]['Manufacture']
				tmpIndex=json_info['pcie'][cnt]['Index']
				tmpslot=json_info['pcie'][cnt]['slot']

				tmponwhichcpu=json_info['pcie'][cnt]['onwhichcpu']
				if tmponwhichcpu == 0x80:
					tmponwhichcpu=1

				tmpType=json_info['pcie'][cnt]['type']
				if tmpType < len(ListPCIEDevType):
					tmpType=ListPCIEDevType[tmpType]

				tmpPCIEVendorId=json_info['pcie'][cnt]['VendorID']
				if None != PCI_IDS_LIST.get(tmpPCIEVendorId):
					tmpPCIEVendorId=PCI_IDS_LIST.get(tmpPCIEVendorId)
				else:
					tmpPCIEVendorId=hex(tmpPCIEVendorId)

				tmpPCIEDeviceId=json_info['pcie'][cnt]['DeviceID']
				if   None != PCI_IDS_DEVICE_LIST.get(tmpPCIEVendorId):
					if PCI_IDS_DEVICE_LIST.get(tmpPCIEVendorId).get(tmpPCIEDeviceId) != None:
						tmpPCIEDeviceId=PCI_IDS_DEVICE_LIST.get(tmpPCIEVendorId).get(tmpPCIEDeviceId) 
					else:
						tmpPCIEDeviceId=hex(tmpPCIEDeviceId)
				else:
					tmpPCIEDeviceId=hex(tmpPCIEDeviceId)

				tmpPCIELinkSpeed=json_info['pcie'][cnt]['Speed']
				tmpPCIELinkWidth=json_info['pcie'][cnt]['width']
				
				tmpString='PCIE_'  + str(tmpIndex)  + '_CPU' + str(tmponwhichcpu) + '|' + str(tmpType) + '|' + str(tmpPCIEVendorId) + '|' +  str(tmpPCIEDeviceId) +  '|'  + 'GEN'  +  str(tmpPCIELinkSpeed) + '|' + 'X' +  str(tmpPCIELinkWidth) + '|' + 'PCIE#' + '\n'
				#print tmpString
				f.write(tmpString)
	f.close()
	return
PLATFORM_IVT=0
PLATFORM_HASWELL=1
platForm=PLATFORM_HASWELL
cpuNum=8
procNum=31
bankNum=31
regDetailList={}
splitStr="57 01 00 40"
def createRegList():
	global platForm
	global PLATFORM_HASWELL
	global PLATFORM_IVT
	fileHdl=0
	try:
		fileHdl=open(logHsxMsrPath, 'r')
		platForm=PLATFORM_HASWELL
		runningLog("createRegList open hsx_msr.txt OK, platform: "+str(platForm))
	except IOError, e:
   		#print "createRegList: open file failed:",e
   		runningLog("createRegList: open file failed:"+str(e))   		
   		try:
			fileHdl=open(logIvtMsrPath, 'r')
			platForm=PLATFORM_IVT
			runningLog("createRegList open ivt_msr.txt OK,  platform: "+str(platForm))
		except IOError, e:
			runningLog("createRegList: open file failed:"+str(e))   	
			try:
				fileHdl=open(logRomleyMsrPath, 'r')
				platForm=PLATFORM_IVT
				runningLog("createRegList  open romley_msr.txt OK, platform: "+str(platForm))
			except IOError, e:
				runningLog("createRegList: open file failed:"+str(e))   	
				return -1
   		#return -1
		#print "createRegList: open file failed:",logHsxMsrPath,",open with return:",fileHdl
	for line in fileHdl.readlines():
		regName=str(line.split()[0])+str(line.split()[1])
		#print "0", str(line.split()[0]), "1", str(line.split()[1]),  ":", regName
		#print line, str(line.find(splitStr))
		if line.find(splitStr)>=0:
			#print "find!"
			regValueStr=str(line.split(splitStr)[1])
			regValueList=regValueStr.split()
			regValue=""
			if len(regValueList)==8:
				regValue=str("0x"+regValueList[7]+regValueList[6]+regValueList[5]+regValueList[4]+regValueList[3]
					+regValueList[2]+regValueList[1]+regValueList[0])
			else:
				regValue="0x00"
			#print regValue
			regDetailList[regName]=regValue
			#print regDetailList[regName]
		else:
			#print "Not find 57 01 00!"
			regDetailList[regName]="0x00"
		#print "result:", regName, regDetailList[regName] 
	fileHdl.close()
	return 0

def fetchProcNum():
	fileHdl=open(logMaxThread, 'r')
	for line in fileHdl.readlines():
		if line.find(splitStr)>=0:
			valueList=line.split()
			if len(valueList)==8:
				tmpProcNum=int("0x"+valueList[4], 16)
				if tmpProcNum<255:
					procNum=tmpProcNum
				runningLog("fetchProcNum:"+str(procNum))
				break;
	fileHdl.close()

MSR_MODE_BLACKBOX=0
MSR_MODE_REAL_READING=1
def parseMsr():
	fetchProcNum()
	if 0!=createRegList():
		#print "exit !!"
		runningLog("createRegList failed")
	if os.path.isfile(logParsedHsxMsrPath):
		os.remove(logParsedHsxMsrPath)

	tmpFileHdl=open(logParsedHsxMsrPath, "a")
	savedStdout = sys.stdout
	sys.stdout = tmpFileHdl
	for cpuid in range(cpuNum):
		for bankid in range(bankNum):
			procid=0			
			if bankid>=4:
				parseOneMsr(cpuid, procid, bankid, MSR_MODE_REAL_READING, "", "", "0x00")
				continue
			for procid in range(procNum):
				parseOneMsr(cpuid, procid, bankid, MSR_MODE_REAL_READING, "", "", "0x00")
	parseMsrInBlackbox()
	sys.stdout = savedStdout
	tmpFileHdl.close()

def parseMsrInBlackbox():
	fileHdl=0
	peciFile="blackboxpeci_decode.txt"
	fileList=os.listdir(logLogsPath)
	#print fileList
	for i in range(len(fileList)):
		if fileList[i].find("blackboxpeci_") >= 0:
			peciFile=fileList[i]
			break;
	#print peciFile

	try:
		fileHdl=open(logLogsPath+peciFile, 'r')
	except IOError, e:
   		runningLog("createRegList: open file failed:"+str(e))
   		return -1

	for line in fileHdl.readlines():
		#print line
		tmpPos=line.find("MC") 
		if tmpPos >= 0 and line.find("_STATUS")>=0:
			#print line
			if len(line.split(": 0x"))>=2:
				bankid=line.split("MC")[1].split("_STATUS")[0]
				#bankid=line[tmpPos+2]
				#print bankid, line
				statusValue="0x"+line.split(": 0x")[1].strip('.\n')
				#print statusValue
				parseOneMsr(0, 0, bankid, MSR_MODE_BLACKBOX, statusValue, line, "0x00")

	fileHdl.close()
	return 0

def parseOneMsr(cpuid, procid, bankid, mode, statusValue, outInfotitle, statusShadow):
	tmpCTLKey="CPU"+str(cpuid)+"_Proc"+str(procid)+"IA32_MC"+str(bankid)+"_CTL"
	tmpStatusKey="CPU"+str(cpuid)+"_Proc"+str(procid)+"IA32_MC"+str(bankid)+"_STATUS"
	tmpAddrKey="CPU"+str(cpuid)+"_Proc"+str(procid)+"IA32_MC"+str(bankid)+"_ADDR"
	tmpMiscKey="CPU"+str(cpuid)+"_Proc"+str(procid)+"IA32_MC"+str(bankid)+"_MISC"
	tmpStatus="0"
	tmpAddr="0"
	tmpMisc="0"

	error = mcd._mcaBankInfo()
	error.bankNum = long(str(bankid), 10)
	if mode == MSR_MODE_REAL_READING:
		if tmpStatusKey not in regDetailList.keys() and  tmpAddrKey not in regDetailList.keys() and tmpMiscKey not in regDetailList.keys():
			return -1
		if tmpStatusKey in regDetailList.keys():
			tmpStatus=regDetailList[tmpStatusKey]
		if tmpAddrKey in regDetailList.keys():
			tmpAddr=regDetailList[tmpAddrKey]
		if tmpMiscKey in regDetailList.keys():
			tmpMisc=regDetailList[tmpMiscKey]
		error.status = long(tmpStatus, 16)
		error.misc = long(tmpMisc, 16)
		error.addr = long(tmpAddr, 16)
		error.outInfotitle = "Realtime:"+"CPU"+str(cpuid)+"_Proc"+str(procid)+"IA32_MC"+str(bankid)
		runningLog("RealTimeDecode:"+tmpStatusKey+":"+str(tmpStatus)+ ";"+tmpAddrKey+":"+str(tmpAddr)+ ";"+tmpMiscKey+":"+str(tmpMisc))
	else:

		error.status = long(statusValue, 16)
		error.status_shadow = long(statusShadow, 16)
		#print error.status
		error.misc = 0
		error.addr = 0
		error.outInfotitle = "Blackbox: "+outInfotitle
		runningLog("BlackboxDecode:"+str(bankid)+"-"+statusValue)
	#print tmpStatusKey+":", tmpStatus, ";"+tmpAddrKey+":",  tmpAddr, ";"+tmpMiscKey+":", tmpMisc
	# stuff object into decoder
	if platForm==PLATFORM_IVT:
		mcd_ivt._decodeMCABank(error)
	else:
		mcd._decodeMCABank(error)
regStatusShadowLow=""
regStatusShadowHigh=""
def parseCsr():
	#global platForm
	fileHdl=0
	try:
		fileHdl=open(logHsxCsrPath, 'r')
		#platForm=PLATFORM_HASWELL
		runningLog("createRegList open hsx_msr.txt OK, platform: "+str(platForm))
	except IOError, e:
   		#print "createRegList: open file failed:",e
   		runningLog("createRegList: open file failed:"+str(e))   		
   		try:
			fileHdl=open(logIvtCsrPath, 'r')
			#platForm=PLATFORM_IVT
			runningLog("createRegList open ivt_msr.txt OK,  platform: "+str(platForm))
		except IOError, e:
			runningLog("createRegList: open file failed:"+str(e))   	
			return -1
   		#return -1
		#print "createRegList: open file failed:",logHsxMsrPath,",open with return:",fileHdl
	if os.path.isfile(logParsedHsxCsrPath):
		os.remove(logParsedHsxCsrPath)

	parseCsrInBlackbox()
	
	#outFileHdl=open(logParsedHsxCsrPath, "a")
	for line in fileHdl.readlines():
		#regName=str(line.split()[0])+str(line.split()[1])
		if line.find(splitStr)>=0:
			regNameInfo=str(line.split(splitStr)[0])
			regNameInfoSplit=regNameInfo.split()
			if regNameInfoSplit>=1:
				regName=regNameInfoSplit[len(regNameInfoSplit)-1]

			regValueStr=str(line.split(splitStr)[1])
			regValueList=regValueStr.split()
			regValue=""

			global regStatusShadowLow
			global regStatusShadowHigh
			if len(regValueList)==4:
				regValue=str("0x"+regValueList[3]+regValueList[2]+regValueList[1]+regValueList[0])

				#specific MC7/8_status_shadow
				if line.find("_Status_Shadow_lo")>=0:
					regStatusShadowLow=regValueList[3]+regValueList[2]+regValueList[1]+regValueList[0]
				elif line.find("_Status_Shadow_hi") >=0 and regStatusShadowLow!="":
					regStatusShadowHigh=regValue+regStatusShadowLow
					if line.find("MC7_Status_Shadow") >=0:
						bankid=7
					elif line.find("MC8_Status_Shadow") >=0:
						bankid=8
					else:
						continue
					#print line, regStatusShadowHigh
					tmpFileHdl=open(logParsedHsxMsrPath, "a")
					sys.stdout = tmpFileHdl
					parseOneMsr(0, 0, bankid, MSR_MODE_BLACKBOX, "0x00", line, regStatusShadowHigh)
					savedStdout = sys.stdout
					sys.stdout = tmpFileHdl

				else:
					regStatusShadowLow=""
					regStatusShadowHigh=""
			else:
				regValue="0x00"
				regStatusShadowLow=""
				regStatusShadowHigh=""

			#print regValue
			#regDetailList[regName]=regValue
			#print regName, regValue, long(regValue,16)
			if regName in csr.csrList.keys():
				#print "found"
				#vec_status = mcd.BitVector(long(regValue,16))
				retValue=""
				retValue=csr.perseOneCsr(regName, regValue)
				if retValue != "":
					#outValue="\n-----------------------------------------------------------------------------------------------\n"+ line+ retValue +  "\n-----------------------------------------------------------------------------------------------\n"
					outValue="\n-----------------------------------------------------------------------------------------------\n"+ line+ retValue
					WriteStrToFile(logParsedHsxCsrPath, outValue)
				else:
					#global platForm
					if platForm == PLATFORM_IVT:
						retValue=csr.perseOneCsr(regName+"-IVB", regValue)
						if retValue != "":
							outValue="\n-----------------------------------------------------------------------------------------------\n"+ line+ retValue
							WriteStrToFile(logParsedHsxCsrPath, outValue)
	fileHdl.close()
	return 0

def parseCsrInBlackbox():
	fileHdl=0
	peciFile="blackboxpeci_decode.txt"
	fileList=os.listdir(logLogsPath)
	#print fileList
	for i in range(len(fileList)):
		if fileList[i].find("blackboxpeci_") >= 0:
			peciFile=fileList[i]
			break;
	try:
		fileHdl=open(logLogsPath+peciFile, 'r')
	except IOError, e:
   		#print "createRegList: open file failed:",e
   		runningLog("parseCsrInBlackbox: open file failed:"+str(e))
   		#print ("createRegList: open file failed:"+str(e))
   		return -1
		#print "createRegList: open file failed:",logHsxMsrPath,",open with return:",fileHdl
	for line in fileHdl.readlines():
		parseOneCsrInBlackbox(line)



def parseOneCsrInBlackbox(lineInBlackBox):
	regValue = ""
	if len(lineInBlackBox.split(": 0x"))>=2:
		regValue="0x"+lineInBlackBox.split(": 0x")[1].strip('.\n')
	else:
		return 
	#vec_status = mcd.BitVector(long(regValue,16))
	for key in csr.csrList.keys():
		#print key
		if lineInBlackBox.upper().find(key.upper())>=0:
			#print lineInBlackBox
			retValue=""
			retValue=csr.perseOneCsr(key, regValue)
			if retValue != "":
				outValue="\n-----------------------------------------------------------------------------------------------\n"+ lineInBlackBox+ retValue
				WriteStrToFile(logParsedHsxCsrPath, outValue)
			continue
		if "defFunReg" in csr.csrList[key].keys() :
			defFunRegList=csr.csrList[key]["defFunReg"].split("|")
			#print defFunRegList
			if  len(defFunRegList)==1:
				if lineInBlackBox.upper().fine(defFunRegList[0].upper()):
					retValue=""
					retValue=csr.perseOneCsr(key, regValue)
					if retValue != "":
						#outValue="\n-----------------------------------------------------------------------------------------------\n"+ lineInBlackBox+ retValue +  "\n-----------------------------------------------------------------------------------------------\n"
						outValue="\n-----------------------------------------------------------------------------------------------\n"+ lineInBlackBox+ retValue 
						WriteStrToFile(logParsedHsxCsrPath, outValue)
			elif len(defFunRegList)==2:				
				if lineInBlackBox.upper().find(defFunRegList[0].upper())>=0 or lineInBlackBox.upper().find(defFunRegList[1].upper())>=0:
					#print lineInBlackBox
					#print "test", lineInBlackBox, defFunRegList, lineInBlackBox.upper().find(defFunRegList[0].upper()), lineInBlackBox.upper().find(defFunRegList[1].upper())
					retValue=""
					retValue=csr.perseOneCsr(key, regValue)
					if retValue != "":
						#outValue="\n-----------------------------------------------------------------------------------------------\n"+ lineInBlackBox+ retValue +  "\n-----------------------------------------------------------------------------------------------\n"
						outValue="\n-----------------------------------------------------------------------------------------------\n"+ lineInBlackBox+ retValue
						WriteStrToFile(logParsedHsxCsrPath, outValue)
def WriteStrToFile(fileName, str):
	fileHdl=0
	try:
		fileHdl=open(fileName, 'a')
	except IOError, e:
   		print "WriteStrToFile: open file failed:",fileName,e
   		return -1
   	#print "Test:", fileHdl
   	fileHdl.write(str+'\n')
   	fileHdl.close()
   	return 0

def runningLog(str):
 	outStr="["+time.strftime("%Y-%m-%d %X", time.localtime())+"]"+str
 	return WriteStrToFile(logRunningPath, outStr)

#print mcd.TESTss
#print sys.argv[0]
logFilePath=sys.argv[1]
if logFilePath[len(logFilePath)-1] != '/':
	logFilePath = logFilePath+"/"
print logFilePath
logJasonPath=logFilePath+"bmc/logsJasonRes/"
logLogsPath=logFilePath+"bmc/logs/"
logRunningPath=logLogsPath+"cpuRegDecodeRunning.log"
logHsxMsrPath=logFilePath+"bmc/logs/hsx_msr.txt"
logIvtMsrPath=logFilePath+"bmc/logs/ivt_msr.txt"
logHsxCsrPath=logFilePath+"bmc/logs/hsx_csr.txt"
logIvtCsrPath=logFilePath+"bmc/logs/ivt_csr.txt"
logRomleyMsrPath=logFilePath+"bmc/logs/romley_msr.txt"
logBlacboxPeciPath=logFilePath+"bmc/logs/blackboxpeci_*.txt"
logParsedHsxMsrPath=logFilePath+"bmc/logs/parsed_msr.txt"
logParsedHsxCsrPath=logFilePath+"bmc/logs/parsed_csr.txt"
logIvbMsrPath=logFilePath+"bmc/logs/ivt_msr.txt"
logMaxThread=logFilePath+"bmc/mespec_maxthreadid0.txt"
#print logFilePath
#print logJasonPath
#print logLogsPath

#getCPUInfo4Socket()
#getCPUInfo2Socket()
#getMemInfo4Socket()
#getMemInfo2Socket()
#getPsuInfo()
#getPcieInfo4Socket()
#getPcieInfo2Socket()
#parseMsrInBlackbox()
parseMsr()
parseCsr()