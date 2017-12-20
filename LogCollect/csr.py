#%!/usr/bin/env python
"""
    Module: mcd.py

    Package Dependency: None
    Description: 
        This is a standalone MCA(Machine Check Architecture) decoder.
        Users could run the script as 1) manual decoding; or 2) pass in command line parameters.
        Please see the usage instruction document in the same script folder.

    Autor: Jerr Chen
    Date: August 14, 2014
"""

import textwrap as _textwrap
import sys
#key less than 255 mean bit offset
#key more than 255 mean, this is a bit range not a bit offset, high byte is high bit offset, low byte is low bit offset
csrList={
"viral":{
	'desc': 'This register provides the option to generate viral alert upon the detection of fatal error. \nBit 0 and Bit 2 must be set to 1 to enable viral. \nBit 1 must be set to 1 IF and ONLY IF BIOS also enables IOMCA in Viral mode. If IOMCA is disabled, then leave the bit at default of 0. \nThis register is supported in the EX processor only.',
	31: 'iio_viral_state - Indicates the IIO cluster is in a viral state. When set, all outbound requests are master aborted, all inbound requests are master aborted. This includes traffic to and from the DMI port, except the Reset_Warn message, which will be auto-completed by the DMI port.	If cleared by software by setting a 1, the IIO cluster will exit the viral state. This state	bit is cleared by warm reset.',
	30: 'iio_viral_status - Indicates the IIO cluster had gone to viral. This bit has no effect on hardware and does not indicate the IIO is currently in the viral state. This bit is persistent through warm reset (sticky), even though the viral state is not.',
	3: 'generate_viral_alert - Debug mode to generate a viral alert when viral is enabled.',
	2: 'iio_global_viral_mask - 0: IIO Viral State assertion will NOT cause IIO hardware packet containment.\n1: IIO Viral State assertion will cause IIO hardware packet containment.',
	1: 'iio_signal_global_fatal - Enables IIO to signal Global Fatal for an internal fatal error. When in Viral mode and IOMCA is enabled, this will result in signaling CATERR# when IIO detects an internal fatal error.\nNote that CATERR# assertion in this case will be in addition to assertion of IIO ERRx# pin.',
	0: 'iio_fatal_viral_alert_enable - Enables IIO viral alert.'
	},
"errpinsts":{
	'desc': 'Error Pin Status. \nThis register reflects the state of the error pin assertion. The status bit of the corresponding error pin is set upon the deassertion to assertion transition of the error pin. This bit is cleared by the software with writing 1 to the corresponding bit.',
	2:   'pin2 - Error[2] Pin status\n This bit is set upon the transition of deassertion to assertion of the Error pin. Software write 1 to clear the status. Hardware will only set this bit when the corresponding ERRPINCTL field is set to 10b.',
	1:   'pin1 - Error[1] Pin status\n This bit is set upon the transition of deassertion to assertion of the Error pin. Software write 1 to clear the status. Hardware will only set this bit when the corresponding ERRPINCTL field is set to 10b.',
	0:   'pin0 - Error[0] Pin status\n This bit is set upon the transition of deassertion to assertion of the Error pin. Software write 1 to clear the status. Hardware will only set this bit when the corresponding ERRPINCTL field is set to 10b.'
	},
"gcerrst":{'desc': 'Global Corrected Error Status.\nThis register indicates the corrected error reported to the IIO global error logic. An individual error status bit that is set indicates that a particular local interface has detected an error.',
	26: 'mc - Memory Controller Error Status.',
	25: 'vtd - Intel VT-d Error Status\nThis register indicates the corrected error reported to the Intel VT-d error logic. An individual error status bit that is set indicates that a particular local interface has detected an error.',
	24: 'mi - Miscellaneous Error Status',
	23: 'ioh - IIO Core Error Status\nThis bit indicates that IIO core has detected an error.',
	20: 'dmi - DMI Error Status\nThis bit indicates that IIO DMI port 0 has detected an error.',
	15: 'pcie10 - Port 3d PCIe* logical port has detected an error.',
	14: 'pcie9 - Port 3c PCIe* logical port has detected an error.',
	13: 'pcie8 - Port 3b PCIe* logical port has detected an error.',
	12: 'pcie7 - Port 3a PCIe* logical port has detected an error.',
	11: 'pcie6 - Port 2d PCIe* logical port has detected an error.',
	10: 'pcie5 - Port 2c PCIe* logical port has detected an error.',
	9:   'pcie4 - Port 2b PCIe* logical port has detected an error.',
	8:   'pcie3 - Port 2a PCIe* logical port has detected an error.',
	7:   'pcie2 - Port 1b PCIe* logical port has detected an error.',
	6:   'pcie1 - Port 1a PCIe* logical port has detected an error.',
	5:   'pcie0 - Bit 5: Port 0 PCIe* logical port has detected an error.',
	1:   'csi1_err - IRP1 Coherent Interface Error',
	0:   'csi0_err - IRP0 Coherent Interface Error'
	},
"gcferrst":{
	'desc': 'Global Corrected FERR Status.',
	'sameTo':'gcerrst'
	},
"gcnerrst":{
	'desc': 'Global Corrected NERR Status.',
	'sameTo':'gcerrst'
	},
"gnerrst":{
	'desc': 'Global Nonfatal Error Status.\nThis register indicates the non-fatal error reported to the IIO global error logic. An individual error status bit that is set indicates that a particular local interface has detected an error.',
	25: 'vtd - Intel VT-d Error Status\nThis register indicates the corrected error reported to the Intel VT-d error logic. An individual error status bit that is set indicates that a particular local interface has detected an error.',
	24: 'mi - Miscellaneous Error Status',
	23: 'ioh - IIO Core Error Status\nThis bit indicates that IIO core has detected an error.',
	22: 'For IVBrage CPU- dma:This bit indicates that IIO has detected an error in its DMA engine.',
	21: 'For IVBrage CPU- thermal',
	20: 'dmi - DMI Error Status\nThis bit indicates that IIO DMI port 0 has detected an error.',
	15: 'pcie10 - Port 3d PCIe* logical port has detected an error.',
	14: 'pcie9 - Port 3c PCIe* logical port has detected an error.',
	13: 'pcie8 - Port 3b PCIe* logical port has detected an error.',
	12: 'pcie7 - Port 3a PCIe* logical port has detected an error.',
	11: 'pcie6 - Port 2d PCIe* logical port has detected an error.',
	10: 'pcie5 - Port 2c PCIe* logical port has detected an error.',
	9:   'pcie4 - Port 2b PCIe* logical port has detected an error.',
	8:   'pcie3 - Port 2a PCIe* logical port has detected an error.',
	7:   'pcie2 - Port 1b PCIe* logical port has detected an error.',
	6:   'pcie1 - Port 1a PCIe* logical port has detected an error.',
	5:   'pcie0 - Port 0 PCIe* logical port has detected an error.',
	1:   'csi1_err - IRP1 Coherent Interface Error',
	0:   'csi0_err - IRP0 Coherent Interface Error'
	},
"gferrst":{
	'desc': 'Global Fatal Error Status.\nThis register indicates the fatal error reported to the IIO global error logic. An individual error status bit that is set indicates that a particular local interface has detected an error.',
	25: 'vtd - Intel VT-d Error Status\nThis register indicates the corrected error reported to the Intel VT-d error logic. An individual error status bit that is set indicates that a particular local interface has detected an error.',
	24: 'mi - Miscellaneous Error Status',
	23: 'ioh - IIO Core Error Status\nThis bit indicates that IIO core has detected an error.',
	22: 'For IVBrage CPU- dma:This bit indicates that IIO has detected an error in its DMA engine.',
	21: 'For IVBrage CPU- thermal',
	20: 'dmi - DMI Error Status\nThis bit indicates that IIO DMI port 0 has detected an error.',
	15: 'pcie10 - Port 3d PCIe* logical port has detected an error.',
	14: 'pcie9 - Port 3c PCIe* logical port has detected an error.',
	13: 'pcie8 - Port 3b PCIe* logical port has detected an error.',
	12: 'pcie7 - Port 3a PCIe* logical port has detected an error.',
	11: 'pcie6 - Port 2d PCIe* logical port has detected an error.',
	10: 'pcie5 - Port 2c PCIe* logical port has detected an error.',
	9:   'pcie4 - Port 2b PCIe* logical port has detected an error.',
	8:   'pcie3 - Port 2a PCIe* logical port has detected an error.',
	7:   'pcie2 - Port 1b PCIe* logical port has detected an error.',
	6:   'pcie1 - Port 1a PCIe* logical port has detected an error.',
	5:   'pcie0 - Port 0 PCIe* logical port has detected an error.',
	1:   'tras_csi1 - IRP1 Coherent Interface Error',
	0:   'tras_csi0 - IRP0 Coherent Interface Error'
	},
"gfferrst":{
	'desc': 'Global Fatal FERR Status.',
	'sameTo':'gferrst'
	},
"gfnerrst":{
	'desc': 'Global Fatal NERR Status.',
	'sameTo':'gferrst'
	},
"gnferrst":{
	'desc': 'Global Non-Fatal FERR Status.',
	'sameTo':'gnerrst'
	},
"gnnerrst":{
	'desc': 'Global Non-Fatal NERR Status.',
	'sameTo':'gnerrst'
	},
"gsysst":{
	'desc': 'Global System Event Status.\nThis register indicates the error severity signaled by the IIO global error logic. Setting of an individual error status bit indicates that the corresponding error severity has been detected by the IIO.',
	4:   'For IVBrage CPU- sev4 - Thermal Alert Error',
	3:   'For IVBrage CPU- sev3 - Thermal Alert Error',
	2:   'sev2 - When set, IIO has detected an error of error severity 2',
	1:   'sev1 - When set, IIO has detected an error of error severity 1',
	0:   'sev0 - When set, IIO has detected an error of error severity 0'
	},
"irpp0errst":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	14: 'protocol_parity_error - Protocol Parity Error (Error Code 0xDB)\nLogs parity errors on data from the IIO switch on the inbound path.',
	13: 'protocol_qt_overflow_underflow - Protocol Queue/Table Overflow or Underflow(Error Code 0xDA)',
	10: 'protocol_rcvd_unexprsp - Protocol Layer Received Unexpected Response/Completion (Error Code 0xD7)\nA completion has been received from the Coherent Interface that was unexpected.',
	6:   'csr_acc_32b_unaligned - CSR access crossing 32-bit boundary (Error Code 0xC3)',
	5:   'wrcache_uncecc_error_cs1 - Write Cache Un-correctable ECC (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set1.',
	4:   'wrcache_uncecc_error_cs0 - Write Cache Un-correctable ECC (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set0.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	3:   'protocol_rcvd_poison - Protocol Layer Received Poisoned Packet (Error Code 0xC1)\nA poisoned packet has been received from the Coherent Interface.\nFor IVBrage CPU- wrcache_uncecc_error: (C2)',
	2:   'wrcache_correcc_error_cs1 - Write Cache Correctable ECC (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set1.\nFor IVBrage CPU- protocol_rcvd_poison: (C1)',
	1:   'wrcache_correcc_error_cs0 - Write Cache Correctable ECC (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set0.\nFor IVBrage CPU- wrcache_correcc_error: (B4)'
	},
"irpp0fferrst":{
	'desc': 'IRP Protocol Fatal FERR Status.\nThe error status log indicates which error is causing the report of the first fatal error event.',
	14: 'protocol_parity_error - Protocol Parity Error (Error Code 0xDB)\nLogs parity errors on data from the IIO switch on the inbound path.',
	13: 'protocol_qt_overflow_underflow - (Error Code 0xDA)\nUsed for queue/table overflow or underflow in coherent Interface protocol layer.',
	10: 'protocol_rcvd_unexprsp - (Error Code 0xD7)\nA completion has been received from the Coherent Interface that was unexpected.',
	6:   'csr_acc_32b_unaligned - (Error Code 0xC3)\nCSR access crossing 32-bit boundary.',
	5:   'wrcache_uncecc_error_cs1 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set1.',
	4:   'wrcache_uncecc_error_cs0 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set0.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	3:   'protocol_rcvd_poison - (Error Code 0xC1)\nA poisoned packet has been received from the Coherent Interface.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	2:   'wrcache_correcc_error_cs1 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set1.\nFor IVBrage CPU- protocol_rcvd_poison: (C1)',
	1:   'wrcache_correcc_error_cs0 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set0.\nFor IVBrage CPU- wrcache_correcc_error: (B4)'
	},
"irpp0fnerrst":{
	'desc': 'IRP Protocol Fatal NERR Status.\nThe error status log indicates which error is causing the report of the next fatal error event (any event that is not the first).',
	14: 'protocol_parity_error - Protocol Parity Error (Error Code 0xDB)\nLogs parity errors on data from the IIO switch on the inbound path.',
	13: 'protocol_qt_overflow_underflow - (Error Code 0xDA)\nProtocol Queue/Table Overflow or Underflow.',
	10: 'protocol_rcvd_unexprsp - (Error Code 0xD7)\nA completion has been received from the Coherent Interface that was unexpected.',
	6:   'csr_acc_32b_unaligned - (Error Code 0xC3)\nCSR access crossing 32-bit boundary.',
	5:   'wrcache_uncecc_error_cs1 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set1.',
	4:   'wrcache_uncecc_error_cs0 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set0.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	3:   'protocol_rcvd_poison - (Error Code 0xC1)\nA poisoned packet has been received from the Coherent Interface.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	2:   'wrcache_correcc_error_cs1 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set1.\nFor IVBrage CPU- protocol_rcvd_poison: (C1)',
	1:   'wrcache_correcc_error_cs0 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set0.\nFor IVBrage CPU- wrcache_correcc_error: (B4)'
	},
"irpp0nferrst":{
	'desc': 'IRP Protocol Non-Fatal First Error.\nThe error status log indicates which error is causing the report of the first non-fatal error event.',
	14: 'protocol_parity_error - Protocol Parity Error (Error Code 0xDB)\nLogs parity errors on data from the IIO switch on the inbound path.',
	13: 'protocol_qt_overflow_underflow - (Error Code 0xDA)\nProtocol Queue/Table Overflow or Underflow.',
	10: 'protocol_rcvd_unexprsp - (Error Code 0xD7)\nA completion has been received from the Coherent Interface that was unexpected.',
	6:   'csr_acc_32b_unaligned - (Error Code 0xC3)\nCSR access crossing 32-bit boundary.',
	5:   'wrcache_uncecc_error_cs1 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set1.',
	4:   'wrcache_uncecc_error_cs0 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set0.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	3:   'protocol_rcvd_poison - (Error Code 0xC1)\nA poisoned packet has been received from the Coherent Interface.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	2:   'wrcache_correcc_error_cs1 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set1.\nFor IVBrage CPU- protocol_rcvd_poison: (C1)',
	1:   'wrcache_correcc_error_cs0 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set0.\nFor IVBrage CPU- wrcache_correcc_error: (B4)'
	},
"irpp0nnerrst":{
	'desc': 'IRP Protocol Non-Fatal NERR Status.\nThe error status log indicates which error is causing the report of the next non-fatal error event (any event that is not the first).',
	14: 'protocol_parity_error - (Error Code 0xDB)\nLogs parity errors on data from the IIO switch on the inbound path.',
	13: 'protocol_qt_overflow_underflow - (Error Code 0xDA)\nProtocol Queue/Table Overflow or Underflow.',
	10: 'protocol_rcvd_unexprsp - (Error Code 0xD7)\nA completion has been received from the Coherent Interface that was unexpected.',
	6:   'csr_acc_32b_unaligned - (Error Code 0xC3)\nCSR access crossing 32-bit boundary.',
	5:   'wrcache_uncecc_error_cs1 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set1.',
	4:   'wrcache_uncecc_error_cs0 - (Error Code 0xC2)\nA double bit ECC error was detected within the Write Cache in set0.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	3:   'protocol_rcvd_poison - (Error Code 0xC1)\nA poisoned packet has been received from the Coherent Interface.\nFor IVBrage CPU- csr_acc_32b_unaligned: (C3)',
	2:   'wrcache_correcc_error_cs1 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set1.\nFor IVBrage CPU- protocol_rcvd_poison: (C1)',
	1:   'wrcache_correcc_error_cs0 - (Error Code 0xB4)\nA single bit ECC error was detected and corrected within the Write Cache in set0.\nFor IVBrage CPU- wrcache_correcc_error: (B4)'
	},
"irpp0errcnt":{
	'desc': 'IRP Protocol Error Count.',
	7: 'errovf - Error Accumulator Overflow\n0: No overflow occurred\n1: Error overflow. The error count may not be valid.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0600: 'errcnt - This counter accumulates errors that occur when the associated error type is selected in the ERRCNTSEL register.\nNotes:\nThis register is cleared by writing 7Fh.\nMaximum counter available is 127d (7Fh)',
	},
"irpp1errst":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	'sameTo':'irpp0errst'
	},
"irpp1fferrst":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	'sameTo':'irpp0fferrst'
	},
"irpp1fnerrst":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	'sameTo':'irpp0fnerrst'
	},
"irpp1nferrst":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	'sameTo':'irpp0nferrst'
	},
"irpp1nnerrst":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	'sameTo':'irpp0nnerrst'
	},
"irpp1errcnt":{
	'desc': 'IRP Protocol Error Status.\nThis register indicates the error detected by the Coherent Interface.',
	'sameTo':'irpp0errcnt'
	},
"iioerrst":{
	'desc': 'IIO Core Error Status.\nThis register indicates the IIO internal core errors detected by the IIO error logic. An individual error status bit that is set indicates that a particular error occurred; software may clear an error status by writing a 1 to the respective bit. This register is sticky and can only be reset by PWRGOOD. Clearing of the IIO**ERRST is done by clearing the corresponding IIOERRST bits.',
	6:   'c6 - Overflow/Underflow Error Status (C6)',
	4:   'c4 - Master Abort Error Status (C4)',
	0:   'c7_multicast_target_error - Multicast target error indicating a multicast transaction has targeted more than the number of groups supported.'
	},
"iiofferrst":{
	'desc': 'IIO Core Fatal FERR Status.',
	'sameTo':'iioerrst'
	},
"iiofnerrst":{
	'desc': 'IIO Core Non-Fatal FERR Status.',
	'sameTo':'iioerrst'
	},
"iionferrst":{
	'desc': 'IIO Core Non-Fatal FERR Status.',
	'sameTo':'iioerrst'
	},
"iionnerrst":{
	'desc': 'IIO Core Non-Fatal NERR Status.',
	'sameTo':'iioerrst'
	},	
"iioerrcnt":{
	'desc': 'IIO Core Error Counter.',
	7: 'errovf - Error Accumulator Overflow\n0: No overflow occurred\n1: Error overflow. The error count may not be valid.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0600: 'errcnt - This counter accumulates errors that occur when the associated error type is selected in the ERRCNTSEL register.\nNotes:\nThis register is cleared by writing 7Fh.\nMaximum counter available is 127d (7Fh)',
	},
"mierrst":{
	'desc': 'Miscellaneous Error Status.',
	3:   'vpp_err_sts - VPP Hotplug I/O Extender Port Error Status. I/O module encountered persistent VPP failure. The VPP is unable to operate.',
	},
"mifferrst":{
	'desc': 'Miscellaneous Fatal FERR Status.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0a00: 'mi_err_st_log - There is 1 bit per VPP port to support up to 11 slots. This field only logs VPP errors. Vpp is serial bus that indicates which port (slot) has a hot plug event pending.',
	},
"mifnerrst":{
	'desc': 'Miscellaneous Fatal NERR Status.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0a00: 'mi_err_st_log - There is 1 bit per VPP port to support up to 11 slots. This field only logs VPP errors. Vpp is serial bus that indicates which port (slot) has a hot plug event pending.',
	},
"minferrst":{
	'desc': 'Miscellaneous Non-Fatal FERR Status.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0a00: 'mi_err_st_log - There is 1 bit per VPP port to support up to 11 slots. This field only logs VPP errors. Vpp is serial bus that indicates which port (slot) has a hot plug event pending.',
	},
"minnerrst":{
	'desc': 'Miscellaneous Non-Fatal NERR Status.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0a00: 'mi_err_st_log - There is 1 bit per VPP port to support up to 11 slots. This field only logs VPP errors. Vpp is serial bus that indicates which port (slot) has a hot plug event pending.',
	},
"mierrcnt":{
	'desc': 'Miscellaneous Error Count.',
	7: 'errovf - Error Accumulator Overflow\n0: No overflow occurred\n1: Error overflow. The error count may not be valid.',
	#bit 6 to bit 0, value more than 255 mean, this is a bit range not a bit offset
	0x0600: 'errcnt - This counter accumulates errors that occur when the associated error type is selected in the ERRCNTSEL register.\nNotes:\nThis register is cleared by writing 7Fh.\nMaximum counter available is 127d (7Fh)',
	},
"qpiviral0":{
	'desc': 'Intel QPI Viral Control and Status Register\nThis register has control/status bits for Intel QPI Viral',
	31: 'qpi_viral_state - Indicates that the Intel QPI Agent is currently asserting Viral in outgoing packet headers.',
	30: 'qpi_viral_status - Indicates previous detection of a Viral condition.',
	28: 'qpi_pkt_viral_set - Status that indicates the Intel QPI Agent has received a packet header with the Viral bit asserted.\nNote 1 - if this bit is set, the Intel QPI Agent will continue to assert Global Viral (if enabled).',
	26: 'qpi_unc_err_set - Status that indicates the Intel QPI Agent has detected an uncorrectable error.\nNote 1 - if this bit is set, the Intel QPI Agent will continue to assert Global Fatal/Global Viral (if enabled)\nNote 2 - uncorrectable error used here includes QPIERRDIS masking, but does NOT include QPI_MC_CTL masking',
	22: 'qpi_failover_status - Indicates an SMI was generated due to a clk/data failover condition.',
	2:   'qpi_global_viral_mask - Masks generation of outgoing packet headers with Viral asserted.',
	1:   'qpi_signal_global_fatal - Enables assertion of Global Fatal by Intel QPI Agent due to internal detection of an uncorrectable error.',
	0:   'qpi_fatal_viral_alert_enable - Enables assertion of Global Viral by Intel QPI Agent.'
	},
"qpiviral1":{
	'desc': 'Intel QPI Viral Control and Status Register\nThis register has control/status bits for Intel QPI Viral',
	'sameTo': 'qpiviral0'
	},
"qpiviral2":{
	'desc': 'Intel QPI Viral Control and Status Register\nThis register has control/status bits for Intel QPI Viral',
	'sameTo': 'qpiviral0'
	},
"QPIVIRAL":{
	'desc': 'Intel QPI Viral Control and Status Register\nThis register has control/status bits for Intel QPI Viral',
	'sameTo': 'qpiviral0'
	},
"R2PINGERRLOG0":{
	'desc': 'R2PCIe Ingress error log 0',
	15: 'IVSnpCrdOverFlow - IV Snoop credit overflow',
	14: 'IVBgfCrdOverFlow - IV BGF credit overflow',
	13: 'ParErrE2E1 - Ingress E2E data parity error - Agent 1',
	12: 'ParErrE2E0 - Ingress End2End data parity error - Agent 0',
	11: 'ParErrIng1 - Ingress BL data parity error - Agent 1',
	10: 'ParErrIng0 - Ingress BL data parity error - Agent 0',
	9:   'IioNcsCrdOverFlow - IIO NCS credit overflow',
	8:   'IioNcbCrdOverFlow - IIO NCB credit overflow. \nFor IVBrage CPU- IioNcsCrdOverFlow',
	7:   'IioIdiCrdOverFlow - IIO IDI credit overflow. \nFor IVBrage CPU- IioNcbCrdOverFlow:',
	6:   'UbxQpiNcsCrdOverFlow - Ubox QPI NCS credit overflow. \nFor IVBrage CPU- IioIdiCrdOverFlow:',
	5:   'UbxQpiNcbCrdOverFlow - Ubox QPI NCB credit overflow',
	4:   'UbxCboNcsCrdOverFlow - Ubox Cbo NCS credit overflow',
	3:   'UbxCboNcbCrdOverFlow - Ubox Cbo NCB credit overflow',
	2:   'BLBgfCrdOverFlow - BL BGF credit overflow. \nFor IVBrage CPU- UbxCboNcbCrdOverFlow:',
	1:   'AK1BgfCrdOverFlow - AK BGF 1 BGF credit overflow. \nFor IVBrage CPU- BLBgfCrdOverFlow:',
	0:   'AK0BgfCrdOverFlow - AK BGF 0 BGF credit overflow. \nFor IVBrage CPU- AKBgfCrdOverFlow:'
	},
"R2GLERRCFG":{
	'desc': 'R2PCIe global viral/fatal error configuration',
	20: 'FatalStatusFromUbox - Read only from Ubox fatal status',
	19: 'ViralStatusFromUbox - Read only from Ubox viral status',
	18: 'FatalStatusFromIio - Read only from IIO fatal status',
	17: 'ViralStatusFromIio - Read only from IIO viral status',
	16: 'ViralStatusToIio - Read only to IIO viral status',
	15: 'LocalErrorStatus - Read only R2PCIe error status',
	0x0e0d: 'MaskR2FatalError - Set to 0x3 to mask R2PCIE errors from the global fatal error status. Set to 0x0 to not mask. All others reserved.',
	10: 'MaskIIOViralIn - Set 1 to block Viral status from IIO to global viral status',
	9:   'MaskIIOViralOut - Set 1 to block Viral status from global viral status to IIO',
	7:   'MaskIIOFatalErrorIn - Set 1 to block fatal error status from IIO to global fatal status',
	6:   'MaskUboxFatalErrorIn - Set 1 to block fatal error status of Ubox to global fatal status',
	5:   'MaskUboxViralIn - Set 1 to block viral status of Ubox',
	4:   'ResetGlobalViral - Set 1 to force clear global viral status.',
	3:   'ResetGlobalFatalError - Set 1 to force clear global fatal error status.'
	},
"R2EGRERRLOG":{
	'desc': 'R2PCIe Egress error log',
	29: 'ADEgress1_Overflow - AD Egress Agent 1 buffer overflow',
	28: 'ADEgress0_Overflow - AD Egress Agent 0 buffer overflow',
	27: 'BLEgress1_Overflow - BL Egress Agent 1 buffer overflow',
	26: 'BLEgress0_Overflow - BL Egress Agent 0 buffer overflow',
	25:  'AKEgress1_Overflow - AK Egress Agent 1 buffer overflow',
	24:  'AKEgress0_Overflow - AK Egress Agent 0 buffer overflow',
	23:  'ADEgress1_Write_to_Valid_Entry - AD Egress Agent 1 write to occupied entry',
	22:  'ADEgress0_Write_to_Valid_Entry - AD Egress Agent 0 write to occupied entry',
	21:  'BLEgress1_Write_to_Valid_Entry - BL Egress Agent 1 write to occupied entry',
	20:  'BLEgress0_Write_to_Valid_Entry - BL Egress Agent 0 write to occupied entry',
	19:  'AKEgress1_Write_to_Valid_Entry - AK Egress Agent 1 write to occupied entry',
	18:  'AKEgress0_Write_to_Valid_Entry - AK Egress Agent 0 write to occupied entry',
	17:  'Cbo17PrqCrdOverflow - Cbo 17 PRQ Credit Overflow',
	16:  'Cbo16PrqCrdOverflow - Cbo 16 PRQ Credit Overflow',
	15:  'Cbo15PrqCrdOverflow - Cbo 15 PRQ Credit Overflow',
	14:  'Cbo14PrqCrdOverflow - Cbo 14 PRQ Credit Overflow',
	13:  'Cbo13PrqCrdOverflow - Cbo 13 PRQ Credit Overflow',
	12:  'Cbo12PrqCrdOverflow - Cbo 12 PRQ Credit Overflow',
	11:  'Cbo11PrqCrdOverflow - Cbo 11 PRQ Credit Overflow',
	10:  'Cbo10PrqCrdOverflow - Cbo 10 PRQ Credit Overflow',
	9:  'Cbo9PrqCrdOverflow - Cbo 9 PRQ Credit Overflow',
	8:  'Cbo8PrqCrdOverflow - Cbo 8 PRQ Credit Overflow',
	7:  'Cbo7PrqCrdOverflow - Cbo 7 PRQ Credit Overflow',
	6:  'Cbo6PrqCrdOverflow - Cbo 6 PRQ Credit Overflow',
	5:  'Cbo5PrqCrdOverflow - Cbo 5 PRQ Credit Overflow',
	4:  'Cbo4PrqCrdOverflow - Cbo 4 PRQ Credit Overflow',
	3:  'Cbo3PrqCrdOverflow - Cbo 3 PRQ Credit Overflow',
	2:  'Cbo2PrqCrdOverflow - Cbo 2 PRQ Credit Overflow',
	1:  'Cbo1PrqCrdOverflow - Cbo 1 PRQ Credit Overflow',
	0:  'Cbo0PrqCrdOverflow - Cbo 0 PRQ Credit Overflow'
	},
"R2EGRERRLOG-IVB":{
	'desc': 'R2PCIe Egress error log',
	30: 'Cbo14CrdOverflow',
	29: 'Cbo13CrdOverflow',
	28: 'Cbo12CrdOverflow',
	27: 'Cbo11CrdOverflow',
	26: 'Cbo10CrdOverflow',
	25: 'Cbo9CrdOverflow',
	24: 'Cbo8CrdOverflow',
	23: 'Cbo7CrdOverflow',
	22: 'Cbo6CrdOverflow',
	21: 'Cbo5CrdOverflow',
	20: 'Cbo4CrdOverflow',
	19: 'Cbo3CrdOverflow',
	18: 'Cbo2CrdOverflow',
	17: 'Cbo1CrdOverflow',
	16: 'Cbo0CrdOverflow',
	14: 'Cbo14VfifoCrdOverflow',
	13: 'Cbo13VfifoCrdOverflow',
	12: 'Cbo12VfifoCrdOverflow',
	11: 'Cbo11VfifoCrdOverflow',
	10: 'Cbo10VfifoCrdOverflow',
	9: 'Cbo9VfifoCrdOverflow',
	8: 'Cbo8VfifoCrdOverflow',
	7: 'Cbo7VfifoCrdOverflow',
	6: 'Cbo6VfifoCrdOverflow',
	5: 'Cbo5VfifoCrdOverflow',
	4: 'Cbo4VfifoCrdOverflow',
	3: 'Cbo3VfifoCrdOverflow',
	2: 'Cbo2VfifoCrdOverflow',
	1: 'Cbo1VfifoCrdOverflow',
	0: 'Cbo0VfifoCrdOverflow'
	},
'R2EGRERRLOG2':{
	'desc': 'R2PCIe Egress Error Log 2',
	29 :  'SboCreditOverflowBL1 - BL1 Sbo Credit Overflow',
	28 :  'SboCreditOverflowBL0 - BL0 Sbo Credit Overflow',
	27 :  'SboCreditOverflowAD1 - AD1 Sbo Credit Overflow',
	26 :  'SboCreditOverflowAD0 - AD0 Sbo Credit Overflow',
	0x1514 :  'ParErrEgr1 - BL egress data parity error - Agent 1',
	0x1312 :  'ParErrEgr0 - BL egress data parity error - Agent 0',
	17 :  'Cbo17IsochCrdOverflow - Cbo 17 isochronous credit overflow',
	16 :  'Cbo16IsochCrdOverflow - Cbo 16 isochronous credit overflow',
	15 :  'Cbo15IsochCrdOverflow - Cbo 15 isochronous credit overflow',
	14 :  'Cbo14IsochCrdOverflow - Cbo 14 isochronous credit overflow',
	13 :  'Cbo13IsochCrdOverflow - Cbo 13 isochronous credit overflow',
	12 :  'Cbo12IsochCrdOverflow - Cbo 12 isochronous credit overflow',
	11 :  'Cbo11IsochCrdOverflow - Cbo 11 isochronous credit overflow',
	10 :  'Cbo10IsochCrdOverflow - Cbo 10 isochronous credit overflow',
	9 :  'Cbo9IsochCrdOverflow - Cbo 9 isochronous credit overflow',
	8 :  'Cbo8IsochCrdOverflow - Cbo 8 isochronous credit overflow',
	7 :  'Cbo7IsochCrdOverflow - Cbo 7 isochronous credit overflow',
	6 :  'Cbo6IsochCrdOverflow - Cbo 6 isochronous credit overflow',
	5 :  'Cbo5IsochCrdOverflow - Cbo 5 isochronous credit overflow',
	4 :  'Cbo4IsochCrdOverflow - Cbo 4 isochronous credit overflow',
	3 :  'Cbo3IsochCrdOverflow - Cbo 3 isochronous credit overflow',
	2 :  'Cbo2IsochCrdOverflow - Cbo 2 isochronous credit overflow',
	1 :  'Cbo1IsochCrdOverflow - Cbo 1 isochronous credit overflow',
	0 :  'Cbo0IsochCrdOverflow - Cbo 0 isochronous credit overflow'
	},
'R2EGRERRLOG2-IVB':{
	'desc': 'R2PCIe Egress Error Log 2',
	9: 'ADEgress1_Overflow',
	8: 'ADEgress0_Overflow',
	7: 'BLEgress1_Overflow',
	6: 'BLEgress0_Overflow',
	5: 'AKEgress_Overflow',
	4: 'ADEgress1_Write_to_Valid_Entry',
	3: 'ADEgress0_Write_to_Valid_Entry',
	2: 'BLEgress1_Write_to_Valid_Entry',
	1: 'BLEgress0_Write_to_Valid_Entry',
	0: 'AKEgress_Write_to_Valid_Entry'
	},


'UBOXErrSts':{
	'desc': 'This is error status register in the Ubox and covers most of the interrupt related errors.',
	0x1712:  'Msg_Ch_Tkr_TimeOut - Message Channel Tracker TimeOut. This error occurs when any NP request doesn\'t receive response in 4K cycles. The event is debug use and logging only, not signaling as Ubox error. ',
	17: 'Msg_Ch_Tkr_Err - Message Channel Tracker Error. This error occurs such case that illegal broad cast port ID access to the message channel. The event is debug use and logging only, not signaling as Ubox error.',
	16:  'SMI_delivery_valid - SMI interrupt delivery status valid, write 1\'b0 to clear valid status.',
	7: 'MasterLockTimeOut - Master Lock Timeout received by Ubox.',
	6: 'SMITimeOut - SMI Timeout received by Ubox.',
	5: 'CFGWrAddrMisAligned - MMCFG Write Address Misalignment received by Ubox.',
	4: 'CFGRdAddrMisAligned - MMCFG Read Address Misalignment received by Ubox.',
	3: 'UnsupportedOpcode - Unsupported opcode received by Ubox',
	2: 'PoisonRsvd - Ubox received a poisoned transaction.',
	1: 'SMISrciMC - SMI is caused due to an imdication from the IMC.',
	0: 'SMISrcUMC - This is a bit that indicates that an SMI was caused due to a locally generated UMC.',
	},
'IerrLoggingReg':{
	'desc': 'IERR first/second logging error.',
	25:  'SecondIerrSrcFromCbo - Set to 1 if the second SrcID is from a Cbo or core.',
	24:  'SecondIerrSrcValid - set to 1 if the SecondIerrSrcID is valid.',
	0x1710:  'SecondIerrSrcId - If SecondIerrSrcValid is 1, the block responsible for generating the second IERR is logged here. Refer to decode table in FirstIerrSrcID.',
	9:  'FirstIerrSrcFromCbo - Set to 1 of the FirstIerrSrcID is from a Cbo or core.',
	8:  'FirstIerrSrcValid - Set to 1 if the FirstSrcID is valid.',
	0x0700: 'FirstIerrSrcId - msgCh portID of the end point with the first IERR. If FirstIerrSrcValid is 1, the block responsible for generating the first IERR is decoded as follows:\n01000100 - PCU\n10000000 - Core 0\n10000100 - Core 1\n10001000 - Core 2\n10001100 - Core 3\n10010000 - Core 4\n10010100 - Core 5\n10011000 - Core 6\n10011100 - Core 7\n10100000 - Core 8\n10100100 - Core 9\n10101000 - Core 10\n10101100 - Core 11\n10110000 - Core 12\n10110100 - Core 13	\n10111000 - Core 14	\n10111100 - Core 15	\n11000000 - Core 16	\n11000100 - Core 17'
	},
"IERRLOGINGREG":{
	'desc': 'IERR first/second logging error.',
	'sameTo': 'IerrLoggingReg'
	},

'MCerrLoggingReg':{
	'desc': 'MCERR first/second logging error.',
	25:  'SecondMCerrSrcFromCbo - Set to 1 if the second SrcID is from a Cbo or CORE. ',
	24:  'SecondMCerrSrcValid - Set to 1 if the SecondMCerrSrcID is valid.',
	0x1710:  'SecondMCerrSrcId - If SecondMCerrSrcValid is 1, the block responsible for generating the second MCERR is logged here. Refer to decode table in FirstMCerrSrcID.',
	9:  'FirstMCerrSrcFromCbo - Set to 1 of the FirstMCerrSrcID is from a Cbo or CORE.',
	8:  'FirstMCerrSrcValid - Set to 1 if the FirstSrcID is valid.',
	0x0700: 'FirstMCerrSrcId - msgCh portID of the EP with the first MCERR. If FirstMCerrSrcValid is 1, the block responsible for generating the first MCERR is decoded as follows:',
	},
'MCERRLOGGINGREG':{
	'desc': 'MCERR first/second logging error.',
	'sameTo': 'MCerrLoggingReg'
	},
'MCerrSrcId':{
	0b00000001:  'IMC 0 CH0',
	0b00000101:  'IMC 0 CH1',
	0b00000110:  'IMC 0 both CH0\CH1',
	0b00001001:  'IMC 0 CH2',
	0b00001101:  'IMC 0 CH3',
	0b00001110:  'IMC both CH2\CH3',
	0b00010001:  'IMC 1 CH0',
	0b00010101:  'IMC 1 CH1',
	0b00010110:  'IMC 1 both CH0\CH1',
	0b00010111:  'IMC 1 both CH2\CH3',
	0b00011001:  'IMC 1 CH2',
	0b00011101:  'IMC 1 CH3',
	0b00111100:  'Home Agent 0',
	0b00111110:  'Home Agent 1',
	0b01000100:  'PCU',
	0b01110000:  'Intel QPI 0',
	0b01110001:  'Intel QPI 1',
	0b01110011:  'Intel QPI 2',
	0b01111110:  'IIO',
	0b10000000:  'CORE OR Cbo 0',
	0b10000100:  'CORE OR Cbo 1',
	0b10001000:  'CORE OR Cbo 2',
	0b10001100:  'CORE OR Cbo 3',
	0b10010000:  'CORE OR Cbo 4',
	0b10010100:  'CORE OR Cbo 5',
	0b10011000:  'CORE OR Cbo 6',
	0b10011100:  'CORE OR Cbo 7',
	0b10100000:  'CORE OR Cbo 8',
	0b10100100:  'CORE OR Cbo 9',
	0b10101000:  'CORE OR Cbo 10',
	0b10101100:  'CORE OR Cbo 11',
	0b10110000:  'CORE OR Cbo 12',
	0b10110100:  'CORE OR Cbo 13',
	0b10111000:  'CORE OR Cbo 14',
	0b10111100:  'CORE OR Cbo 15',
	0b11000000:  'CORE OR Cbo 16',
	0b11000100:  'CORE OR Cbo 17'
	},
'EMCA_CORE_CSMI_LOG':{
	'desc': 'This is a log of which cores have signalled a CSMI to Ubox via the MCLK message.',
	17:  'Core17 - CSMI received indicator for core 17',
	16:  'Core16 - CSMI received indicator for core 16',
	15:  'Core15 - CSMI received indicator for core 15',
	14:  'Core14 - CSMI received indicator for core 14',
	13:  'Core13 - CSMI received indicator for core 13',
	12:  'Core12 - CSMI received indicator for core 12',
	11:  'Core11 - CSMI received indicator for core 11',
	10:  'Core10 - CSMI received indicator for core 10',
	9:  'Core9 - CSMI received indicator for core 9',
	8:  'Core8 - CSMI received indicator for core 8',
	7:  'Core7 - CSMI received indicator for core 7',
	6:  'Core6 - CSMI received indicator for core 6',
	5:  'Core5 - CSMI received indicator for core 5',
	4:  'Core4 - CSMI received indicator for core 4',
	3:  'Core3 - CSMI received indicator for core 3',
	2:  'Core2 - CSMI received indicator for core 2',
	1:  'Core1 - CSMI received indicator for core 1',
	0:  'Core0 - CSMI received indicator for core 0'
	},
'EMCA_CORE_CSMI':{
	'desc': 'This is a log of which cores have signalled a CSMI to Ubox via the MCLK message.',
	'sameTo': 'EMCA_CORE_CSMI_LOG'
	},
'EMCA_CORE_MSMI_LOG':{
	'desc': 'This is a log of which cores have signalled an MSMI to ubox via the MCLK message.',
	17:  'Core17 - MSMI received indicator for core 17',
	16:  'Core16 - MSMI received indicator for core 16',
	15:  'Core15 - MSMI received indicator for core 15',
	14:  'Core14 - MSMI received indicator for core 14',
	13:  'Core13 - MSMI received indicator for core 13',
	12:  'Core12 - MSMI received indicator for core 12',
	11:  'Core11 - MSMI received indicator for core 11',
	10:  'Core10 - MSMI received indicator for core 10',
	9:  'Core9 - MSMI received indicator for core 9',
	8:  'Core8 - MSMI received indicator for core 8',
	7:  'Core7 - MSMI received indicator for core 7',
	6:  'Core6 - MSMI received indicator for core 6',
	5:  'Core5 - MSMI received indicator for core 5',
	4:  'Core4 - MSMI received indicator for core 4',
	3:  'Core3 - MSMI received indicator for core 3',
	2:  'Core2 - MSMI received indicator for core 2',
	1:  'Core1 - MSMI received indicator for core 1',
	0:  'Core0 - MSMI received indicator for core 0'
	},
'EMCA_CORE_MSMI':{
	'desc': 'This is a log of which cores have signalled an MSMI to ubox via the MCLK message.',
	'sameTo': 'EMCA_CORE_MSMI_LOG'
	},
'BIST_RESULTS':{
	'desc': 'Config read-only access to core BIST results of core',
	0x1100:  'results - 0 - BIST failure, 1 - BIST pass'
	},
'IA_PERF_LIMIT_REASON':{
	'desc': 'Interface to allow software to determine what is causing resolved frequency to be clamped below the requested frequency. Status bits are updated by pcode through the IO interface IO_IA_PERF_LIMIT, log bits are set by HW on a status bit edge dected and cleared by a SW write of 0. \nThis CSR is a mirror of MSR (690h) IA_PERF_LIMIT_REASONS. Refer to this MSR for field descriptions.',
	8:  'CLIPPED_EDP - When set, indicates that EDP/Iccmax has caused IA frequency clipping.',
	6:  'CLIPPED_HOT_VR - When set, indicates that VR Therm Alert has caused IA frequency clipping.',
	1:  'CLIPPED_EMTTM - When set, indicates that Thermal Status has caused IA frequency clipping.',
	0:  'CLIPPED_EXT_PROCHOT - When set, indicates that PROCHOT# has caused IA frequency clipping.'
	},
'CORE_FIVR_ERR_LOG':{
	'desc': 'Reports Core FIVR Faults',
	0x1f00:  'FAULT_VECTOR - Fault vector - Bits correspond to cores which have a core IVR fault. Cores with a core IVR fault will not come out of reset. This field has the same field mapping as the CSR RESOLVED_CORES and results are reported in CSR RESOLVED_CORES.'
	},
'UNCORE_FIVR_ERR_LOG':{
	'desc': 'Reports Uncore FIVR Faults',
	0x1f00:  'FAULT_VECTOR - If any bit are set in 31:0 an uncore FIVR fault has occurred. Firmware can attempt to FRB the socket. An IERR will also occur on this condition.'
	},
'N0C0R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x02,0x104)|CORRERRCNT DEV_FUN_REG(0x10,0x06,0x104)',
	31:  'overflow_1 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0x1e10: 'cor_err_cnt_1 - The corrected error count for this rank.',
	15:  'overflow_0 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0xe00: 'cor_err_cnt_0 - The corrected error count for this rank.',
	},
'N0C0R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x02,0x108)|CORRERRCNT DEV_FUN_REG(0x10,0x06,0x108)',
	31:  'overflow_3 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0x1e10: 'cor_err_cnt_3 - The corrected error count for this rank.',
	15:  'overflow_2 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0xe00: 'cor_err_cnt_2 - The corrected error count for this rank.',
	},
'N0C0R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x02,0x10c)|CORRERRCNT DEV_FUN_REG(0x10,0x06,0x10c)',
	31:  'overflow_5 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0x1e10: 'cor_err_cnt_5 - The corrected error count for this rank.',
	15:  'overflow_4 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0xe00: 'cor_err_cnt_4 - The corrected error count for this rank.',
	},
'N0C0R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x02,0x110)|CORRERRCNT DEV_FUN_REG(0x10,0x06,0x110)',
	31:  'overflow_7 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0x1e10: 'cor_err_cnt_7 - The corrected error count for this rank.',
	15:  'overflow_6 - The corrected error count for this rank has been overflowed. Once set it can only be cleared via a write from BIOS.',
	0xe00: 'cor_err_cnt_6- The corrected error count for this rank.',
	},
'N0C1R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x03,0x104)|CORRERRCNT DEV_FUN_REG(0x10,0x07,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N0C1R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x03,0x108)|CORRERRCNT DEV_FUN_REG(0x10,0x07,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N0C1R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x03,0x10c)|CORRERRCNT DEV_FUN_REG(0x10,0x07,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N0C1R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x14,0x03,0x110)|CORRERRCNT DEV_FUN_REG(0x10,0x07,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'N0C2R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x02,0x104)|CORRERRCNT DEV_FUN_REG(0x10,0x02,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N0C2R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x02,0x108)|CORRERRCNT DEV_FUN_REG(0x10,0x02,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N0C2R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x02,0x10c)|CORRERRCNT DEV_FUN_REG(0x10,0x02,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N0C2R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x02,0x110)|CORRERRCNT DEV_FUN_REG(0x10,0x02,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'N0C3R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x03,0x104)|CORRERRCNT DEV_FUN_REG(0x10,0x03,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N0C3R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x03,0x108)|CORRERRCNT DEV_FUN_REG(0x10,0x03,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N0C3R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x03,0x10c)|CORRERRCNT DEV_FUN_REG(0x10,0x03,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N0C3R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x15,0x03,0x110)|CORRERRCNT DEV_FUN_REG(0x10,0x03,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'N1C0R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x02,0x104)|CORRERRCNT DEV_FUN_REG(0x1e,0x06,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N1C0R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x02,0x108)|CORRERRCNT DEV_FUN_REG(0x1e,0x06,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N1C0R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x02,0x10c)|CORRERRCNT DEV_FUN_REG(0x1e,0x06,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N1C0R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x02,0x110)|CORRERRCNT DEV_FUN_REG(0x1e,0x06,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'N1C1R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x03,0x104)|CORRERRCNT DEV_FUN_REG(0x1e,0x07,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N1C1R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x03,0x108)|CORRERRCNT DEV_FUN_REG(0x1e,0x07,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N1C1R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x03,0x10c)|CORRERRCNT DEV_FUN_REG(0x1e,0x07,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N1C1R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x17,0x03,0x110)|CORRERRCNT DEV_FUN_REG(0x1e,0x07,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'N1C2R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x02,0x104)|CORRERRCNT DEV_FUN_REG(0x1e,0x02,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N1C2R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x02,0x108)|CORRERRCNT DEV_FUN_REG(0x1e,0x02,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N1C2R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x02,0x10c)|CORRERRCNT DEV_FUN_REG(0x1e,0x02,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N1C2R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x02,0x110)|CORRERRCNT DEV_FUN_REG(0x1e,0x02,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'N0C3R0_R1':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x03,0x104)|CORRERRCNT DEV_FUN_REG(0x1e,0x0e,0x104)',
	'sameTo': 'N0C0R0_R1'
	},
'N1C3R2_R3':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x03,0x108)|CORRERRCNT DEV_FUN_REG(0x1e,0x0e,0x108)',
	'sameTo': 'N0C0R2_R3'
	},
'N1C3R4_R5':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x03,0x10c)|CORRERRCNT DEV_FUN_REG(0x1e,0x0e,0x10c)',
	'sameTo': 'N0C0R4_R5'
	},
'N1C3R6_R7':{
	'desc': 'Per Rank corrected error counters.',
	'defFunReg': 'CORRERRCNT DEV_FUN_REG(0x18,0x03,0x110)|CORRERRCNT DEV_FUN_REG(0x1e,0x0e,0x110)',
	'sameTo': 'N0C0R6_R7'
	},
'MCA_ERR_SRC_LOG':{
	'desc': 'Thi CSR is used by the PCU to log the error sources. This register is initialized to zeroes during reset. The PCU will set the relevant bits when the condition they represent appears. The PCU never clears the registers. The UBox or platform entities should clear them when they are consumed, unless their processing involves taking down the platform.',
	31: 'CATERR - External error: The package observed CATERR# (for any reason).It is OR (bit 30, bit29); functions as a Valid bit for the other two package conditions. It has no effect when a local core is associated with the error.',
	30: 'IERR - External error: The package observed IERR.',
	29: 'MCERR - External error: The package observed MCERR.',
	28: 'CATERR_INTERNAL - Internal error: This socket asserted a CATERR#. This is OR (bit27,26).',
	27: 'IERR_INTERNAL - Internal error: This socket asserted IERR.',
	26: 'MCERR_INTERNAL - Internal error: This socket asserted MCERR.',
	23: 'MSMI - External error: The package observed MSMI# (for any reason).It is or(bit 22, bit21); functions as a Valid bit for the other two package conditions. It has no effect when a local core is associated with the error.',
	22: 'MSMI_IERR - External error: The package observed MSMI_IERR.',
	21: 'MSMI_MCERR - External error: The package observed MSMI_MCERR.',
	20: 'MSMI_INTERNAL - Internal error: This socket asserted a MSMI#. This is OR (bit19,18).',
	19: 'MSMI_IERR_INTERNAL - Internal error: This socket asserted MSMI_IERR.',
	18: 'MSMI_MCERR_INTERNAL - Internal error: This socket asserted MSMI_MCERR.'
	},
'MCA_EER_SRC':{
	'desc': 'Thi CSR is used by the PCU to log the error sources. This register is initialized to zeroes during reset. The PCU will set the relevant bits when the condition they represent appears. The PCU never clears the registers. The UBox or platform entities should clear them when they are consumed, unless their processing involves taking down the platform.',
	'sameTo': 'MCA_ERR_SRC_LOG'
	},
}

import mcd
def perseOneCsr(regName, regValue):
	#print regName, regValue
	retValue=""			
	vec_status = mcd.BitVector(long(regValue,16))
	if vec_status[31:0] == 0:
	 	return ""
	if regName in csrList.keys():
		sameToKey=regName
		if "sameTo" in csrList[regName].keys():
			sameToKey=csrList[regName]["sameTo"]
		for key in csrList[sameToKey].keys():
			if  key == "desc" or key == "defFunReg":
				continue
			if key > 255:
				#print key
				lowOffset=key&0x00ff
				highOffset=(key>>8)&0x00ff
				if vec_status[highOffset:lowOffset]  != 0:
					retValue=retValue+csrList[regName]['desc']+"\n["+str(highOffset)+":"+str(lowOffset)+"]  = "+str(vec_status[highOffset:lowOffset]) +"\n"+csrList[sameToKey][key]
					#print highOffset, lowOffset, "to", vec_status[highOffset:lowOffset] , csrList[regName][key]
			else:
				if vec_status[key:key] != 0:
					#print "bit:",key," is one", csrList[regName][key]
					retValue=retValue+csrList[regName]['desc']+"\n["+str(key)+"]"+csrList[sameToKey][key]

	else:
		return ""

	return retValue

def main():
	print csrList["gcerrst"]["desc"], csrList["gcerrst"][26]
	print csrList["gnerrst"]["desc"], csrList["gnerrst"][0]

if __name__ == "__main__":
    main()

