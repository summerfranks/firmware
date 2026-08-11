//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#pragma once
#include <stdint.h>
#include <sys/types.h>

#include "format/formatf.h"

#include "uart/UartStatusRegister.hpp"

#include "cgraph/CGraphCommon.hpp"

union CGraphFSMHardwareControlRegister
{
    uint32_t all;
    struct 
    {
        uint32_t FaultNegV : 1; //b0;
		uint32_t Fault1V : 1; //b1;
		uint32_t Fault2VA : 1; //b2;
		uint32_t Fault2VD : 1; //b3;
		uint32_t Fault3VA : 1; //b4;
		uint32_t Fault3VD : 1; //b5;
		uint32_t Fault43V : 1; //b6;
		uint32_t Fault5V : 1; //b7;
		
		uint32_t FaultHV : 1; //b8;
		uint32_t nHVFaultA : 1; //b9;
		uint32_t nHVFaultB : 1; //b10;
		uint32_t nHVFaultC : 1; //b11;
		uint32_t nHVFaultD : 1; //b12;
		uint32_t PowerCycdAndClr : 1; //b13;
		uint32_t PowernEn : 1; //b14;
		uint32_t ChopEn : 1; //b15;
		
		uint32_t Uart0OE : 1; //b16;
		uint32_t Uart1OE : 1; //b17;
		uint32_t Uart2OE : 1; //b18;
		uint32_t Uart3OE : 1; //b19;
		uint32_t Ux1SelJmp : 1; //b20;
		uint32_t reserved2 : 1; //b21;
		uint32_t PPSDetectedAndRst : 1; //b22;
		uint32_t reserved3 : 1; //b23;
		
		uint32_t PowernEnHV : 1; //b24;
		uint32_t HVEn1 : 1; //b25;
		uint32_t HVEn2 : 1; //b26;
		uint32_t DacSelectMaxti : 1; //b27;
		uint32_t GlobalFaultInhibit : 1; //b28;
		uint32_t nFaultsClr : 1; //b29;
		uint32_t ChopRefState : 1; //b30;
		uint32_t ChopAdcState : 1; //b31;
        
    } __attribute__((packed, aligned(4)));

    CGraphFSMHardwareControlRegister() { all = 0; }

    void formatf() const 	
	{ 
	::formatf("CGraphFSMHardwareControlRegister: all: 0x%lx, \
	FaultNegV: %lu, \
	Fault1V: %lu, \
	Fault2VA: %lu, \
	Fault2VD: %lu, \
	Fault3VA: %lu, \
	Fault3VD: %lu, \
	Fault43V: %lu, \
	Fault5V: %lu, \
	FaultHV: %lu, \
	nHVFaultA: %lu, \
	nHVFaultB: %lu, \
	nHVFaultC: %lu, \
	nHVFaultD: %lu, \
	PowerCycdAndClr: %lu, \
	PowernEn: %lu, \
	ChopEn: %lu, \
	Uart0OE: %lu, \
	Uart1OE: %lu, \
	Uart2OE: %lu, \
	Uart3OE: %lu, \
	Ux1SelJmp: %lu, \
	reserved2: %lu, \
	PPSDetectedAndRst: %lu, \
	reserved3: %lu, \
	PowernEnHV: %lu, \
	HVEn1: %lu, \
	HVEn2: %lu, \
	DacSelectMaxti: %lu, \
	GlobalFaultInhibit: %lu, \
	nFaultsClr: %lu, \
	ChopRefState: %lu, \
	ChopAdcState: %lu",
	all,
	FaultNegV,
	Fault1V,
	Fault2VA,
	Fault2VD,
	Fault3VA,
	Fault3VD,
	Fault43V,
	Fault5V,
	FaultHV,
	nHVFaultA,
	nHVFaultB,
	nHVFaultC,
	nHVFaultD,
	PowerCycdAndClr,
	PowernEn,
	ChopEn,
	Uart0OE,
	Uart1OE,
	Uart2OE,
	Uart3OE,
	Ux1SelJmp,
	reserved2,
	PPSDetectedAndRst,
	reserved3,
	PowernEnHV,
	HVEn1,
	HVEn2,
	DacSelectMaxti,
	GlobalFaultInhibit,
	nFaultsClr,
	ChopRefState,
	ChopAdcState);
	}

}// __attribute__((packed, aligned(4)));
__attribute__((packed, aligned(4)));

struct CGraphFSMHardwareInterface
{
    uint32_t DeviceSerialNumber; //0; ro; FPGA manufacturer hardcoded device UUID
    uint32_t FpgaFirmwareBuildNumber; //4; ro; Auto-incremented firmware UUID
    uint32_t UnixSeconds; //8; rw; equivalent to time_t for 32b systems; low order bits of time_t on 64b systems; write to set/initialize FPGA clock
    uint32_t IdealTicksPerSecond; //12; ro; Target clock speed of FPGA device, approx 100M; likely 14.7456M * 7 = 103,219,200.
    uint32_t ActualTicksLastSecond; //16; ro; Count of clock ticks for entire last second; equal to IdealTicksPerSecond unless clock was set or GPS PPS signal is present
	uint32_t ClockTicksThisSecondAddr; //20; ro Running count of clock ticks since the start of the current second
    uint32_t ClockSteeringDacSetpoint; //24; rw; 
	uint32_t reserved1; //28; PPSRtcPhaseCmpAddr
	CGraphFSMHardwareControlRegister ControlRegister; //32; rw
	AdcConfigRegister AdcConfig; //36
	AccumulatorConfigRegister AccumConfig; //40; wo; Transfers AdcAccumulators to read registers so reads are atomic across channels & datawords
    uint32_t DacASetpoint; //44; rw; First D/A; Zero = zero travel, DacFullScale = full scale travel
    uint32_t DacBSetpoint; //48; rw; Second D/A; Zero = zero travel, DacFullScale = full scale travel
    uint32_t DacCSetpoint; //52; rw; Third D/A; Zero = zero travel, DacFullScale = full scale travel
	uint32_t DacDSetpoint; //56; rw; Third D/A; Zero = zero travel, DacFullScale = full scale travel
	
	//Our compiler is now wholy incapable of dealing with reading 64bit integers from the bus, proven by wasting a week of my life debugging!! If you read them as 2 32b pointers and smash together in code, it is show that there is no problem in the FPGA, and it is GCC making a mess! As usual when something truly inexplicable happens!!
    //~ AdcAccumulator AdcAAccumulator; //60; rw; First A/D; read or write any value to clear & reset accumulator
    //~ AdcAccumulator AdcBAccumulator; //68; rw; Second A/D; read or write any value to clear & reset accumulator
    //~ AdcAccumulator AdcCAccumulator; //76; rw; Third A/D; read or write any value to clear & reset accumulator
	//~ AdcAccumulator AdcDAccumulator; //84; rw; Third A/D; read or write any value to clear & reset accumulator
	int32_t AdcAAccumulator; //60; rw; First A/D; read or write any value to clear & reset accumulator
    int32_t AdcAAccumulatorHiandNumAccums; //64; rw; First A/D; read or write any value to clear & reset accumulator
    int32_t AdcBAccumulator; //68; rw; Second A/D; read or write any value to clear & reset accumulator
    int32_t AdcBAccumulatorHiandNumAccums; //72; rw; Second A/D; read or write any value to clear & reset accumulator
    int32_t AdcCAccumulator; //76; rw; Third A/D; read or write any value to clear & reset accumulator
	int32_t AdcCAccumulatorHiandNumAccums; //80; rw; Third A/D; read or write any value to clear & reset accumulator
	int32_t AdcDAccumulator; //84; rw; Third A/D; read or write any value to clear & reset accumulator
    int32_t AdcDAccumulatorHiandNumAccums; //88; rw; Third A/D; read or write any value to clear & reset accumulator
    
	int32_t MonitorAdcAccumulator; //92; ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
	int32_t MonitorAdcAccumulatorHiandNumAccums; //96; ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
	uint32_t MonitorAdcReadChannel; //100; rw; which channel to read for MonitorA/D
	uint32_t MonitorAdcSpiTransactionRegister; //104; rw
	CGraphDualMonitorAdcCommandStatusRegister MonitorAdcSpiCommandStatusRegister; //108; 
	
	CGraphBaudDividers BaudDividers; //112; rw
	
	uint32_t UartFifo0; //116; rw; send or read bytes from uart(s)
	UartStatusRegister UartStatusRegister0; //120; ro; what state are the uart(s) in?
	uint32_t UartFifo0ReadData; //124; ro
    
	uint32_t UartFifo1; //128; rw; send or read bytes from uart(s)
	UartStatusRegister UartStatusRegister1; //132; ro; what state are the uart(s) in?
	uint32_t UartFifo1ReadData; //136
    
	uint32_t UartFifo2; //140; rw; send or read bytes from uart(s)
	UartStatusRegister UartStatusRegister2; //144; ro; what state are the uart(s) in?
	uint32_t UartFifo2ReadData; //148
    
	uint32_t UartFifo3; //152; rw; send or read bytes from uart(s)
	UartStatusRegister UartStatusRegister3; //156; ro; what state are the uart(s) in?
	uint32_t UartFifo3ReadData; //160
    
	//~ uint32_t UartFifoLab; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegisterLab; //ro; what state are the uart(s) in?
	//~ uint32_t UartFifoLabReadData;

	//~ uint32_t ExtSpiAddrOut; //
	//~ uint32_t ExtSpiAddrIn; //
	//~ uint32_t ExtSpiXfer; //
	//~ uint32_t ExtSpiReadback; //
	
	uint32_t Uart0RxFifoPeekReadAddr; //164
	uint32_t Uart0RxFifoPeekWriteAddr; //168
	uint32_t Uart0RxFifoPeekPeekAddr; //172
	uint32_t Uart0RxFifoPeekPeekData; //176
	uint32_t Uart0RxFifoPeekMultiPopAddr; //180
	uint32_t Uart0CrcStartAddr; //184
	uint32_t Uart0CrcEndAddr; //188
	CGraphCrcCurrentAddr Uart0CrcCurrentAddr; //192
	uint32_t Uart0Crc; //196
	
	uint32_t LatchAdcs; //200; wo; Transfers AdcAccumulators to read registers so reads are atomic across channels & datawords
	DacConfigRegister DacConfig; //204; rw; configure D/A's

	static const uint32_t DacFullScale; //2^20 - 1
    static const double DacDriverFullScaleOutputVoltage; //150 Volts, don't get your fingers near this thing!
    static const double PZTDriverFullScaleOutputTravel; //Meters; note our granularity is this / DacFullScale which is approx 10pm

    //~ void formatf() const { ::formatf("CGraphFSMHardwareInterface: Sample: %+10.0lf ", (double)Sample); ::formatf("(0x%.8lX", (uint32_t)(all >> 32));  ::formatf("%.8lX)", (uint32_t)(all)); ::formatf(", NumAccums: %lu ", (uint32_t)NumAccums); ::formatf("(0x%lX)", (uint32_t)NumAccums); }

	//While we're struggling with gcc trying to read 32b values as 3 unaligned bytes (and one aligned one) and crash the processor, this is our workaround:
	void InititateLatchAdcs();

}// __attribute__((packed, aligned(4))) __attribute__((__unaligned__));
__attribute__((packed, aligned(4)));

extern CGraphFSMHardwareInterface* volatile FSM;
 
//EOF
