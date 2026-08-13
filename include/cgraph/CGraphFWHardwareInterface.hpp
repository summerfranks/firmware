//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Usbratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#pragma once
#include <stdint.h>
#include <sys/types.h>
#include <algorithm>

#include "uart/UartStatusRegister.hpp"

#include "format/formatf.h"

#include "cgraph/CGraphCommon.hpp"

union CGraphFWHardwareControlRegister
{
    uint32_t all;
    struct 
    {
        uint32_t PosLedsEnA : 1; //b0; rw turn on A leds
        uint32_t PosLedsEnB : 1; //b1; rw turn on B leds
        uint32_t MotorEnable : 1; //b2; rw turn on motor
		uint32_t ResetSteps : 1; //b3; rw reset all step counters
        uint32_t MotorAPlus : 1; //b4; ro current state of motor control signal
        uint32_t MotorAMinus : 1; //b5; ro current state of motor control signal
        uint32_t MotorBPlus : 1; //b6; ro current state of motor control signal
        uint32_t MotorBMinus : 1; //b7; ro current state of motor control signal
		
		uint32_t Fault1V : 1; //b8; r: current fault state; w: reset fault
        uint32_t Fault3V : 1; //b9; r: current fault state; w: reset fault
        uint32_t Fault5V : 1; //b10; r: current fault state; w: reset fault
		uint32_t PowernEn5V : 1; //b11; rw turn +5V on/off
        uint32_t PowerCycd : 1; //b12; r: current fault state; w: reset fault
        uint32_t LedR : 1; //b13; rw: led state
        uint32_t LedG : 1; //b14; rw: led state
        uint32_t LedB : 1; //b15; rw: led state
		
		//note: earlier versions of f/w are 16b and these high bits may be inacessible...
		
		uint32_t Uart0OE : 1; //b16; rw: jumper state
		uint32_t Uart1OE : 1; //b17; rw: jumper state
		uint32_t Uart2OE : 1; //b18; rw: jumper state
		uint32_t Uart3OE : 1; //b19; rw: jumper state
		
		uint32_t Ux1SelJmp : 1; //b20; rw: jumper state
		uint32_t Ux2SelJmp : 1; //b21; rw: jumper state

    } __attribute__((packed, aligned(4)));

    CGraphFWHardwareControlRegister() { all = 0; }
	CGraphFWHardwareControlRegister(const uint32_t& a) { all = a; }

    void formatf() const 
	{ 
		::formatf("CGraphFWHardwareControlRegister: All: %.4X ", all); 
		::formatf(", PosLedsEnA: %u ", (unsigned)PosLedsEnA);
		::formatf(", PosLedsEnB: %u ", (unsigned)PosLedsEnB);
		::formatf(", MotorEnable: %u ", (unsigned)MotorEnable);
		::formatf(", ResetSteps: %u ", (unsigned)ResetSteps);
		::formatf(", MotorAPlus: %u ", (unsigned)MotorAPlus);
		::formatf(", MotorAMinus: %u ", (unsigned)MotorAMinus);
		::formatf(", MotorBPlus: %u ", (unsigned)MotorBPlus);
		::formatf(", MotorBMinus: %u ", (unsigned)MotorBMinus);
		
		::formatf(", Fault1V: %u ", (unsigned)Fault1V);
		::formatf(", Fault3V: %u ", (unsigned)Fault3V);
		::formatf(", Fault5V: %u ", (unsigned)Fault5V);
		::formatf(", PowernEn5V: %u ", (unsigned)PowernEn5V);
		::formatf(", PowerCycd: %u ", (unsigned)PowerCycd);
		::formatf(", LedR: %u ", (unsigned)LedR);
		::formatf(", LedG: %u ", (unsigned)LedG);
		::formatf(", LedB: %u ", (unsigned)LedB);
		
		::formatf(", Uart0OE: %u ", (unsigned)Uart0OE);
		::formatf(", Uart1OE: %u ", (unsigned)Uart1OE);
		::formatf(", Uart2OE: %u ", (unsigned)Uart2OE);
		::formatf(", Uart3OE: %u ", (unsigned)Uart3OE);
		::formatf(", Ux1SelJmp: %u ", (unsigned)Ux1SelJmp);
		::formatf(", Ux2SelJmp: %u ", (unsigned)Ux2SelJmp);
	}

} __attribute__((packed, aligned(4)));

union CGraphFWMotorControlStatusRegister
{
    uint32_t all;
    struct 
    {
        int16_t SeekStep; //rw; move the motor to here
        int16_t CurrentStep; //ro; where is motor now (note: if <> SeekStep, motor is probably moving right now, unless ((CGraphFWHardwareControlRegister::MotorEnable == 0) || (CGraphFWHardwareControlRegister::ResetSteps == 1)) )
        
    } __attribute__((packed, aligned(4)));

    CGraphFWMotorControlStatusRegister() { all = 0; }
	CGraphFWMotorControlStatusRegister(const uint32_t& a) { all = a; }

    void formatf() const { ::formatf("CGraphFWMotorControlStatusRegister: All: %.8lX ", (unsigned long)all); ::formatf(", SeekStep: %+d ", SeekStep);  ::formatf(", CurrentStep: %+d ", CurrentStep); }

} __attribute__((packed, aligned(4)));

union CGraphFWPositionSenseRegister
{
    uint32_t all;
    struct 
    {
        uint32_t PosSenseHomeA : 1; //b0; ro
        uint32_t PosSenseBit0A : 1; //b1; ro
        uint32_t PosSenseBit1A : 1; //b2; ro
		uint32_t PosSenseBit2A : 1; //b3; ro
        uint32_t PosSenseHomeB : 1; //b4; ro
        uint32_t PosSenseBit0B : 1; //b5; ro
        uint32_t PosSenseBit1B : 1; //b6; ro
        uint32_t PosSenseBit2B : 1; //b7; ro
		uint32_t PosSenseA : 4; //b8-11; ro
		uint32_t PosSenseB : 4; //b12-15; ro

    } __attribute__((packed, aligned(4)));

    CGraphFWPositionSenseRegister() { all = 0; }
	CGraphFWPositionSenseRegister(const uint32_t& a) { all = a; }

	void formatf() const 
	{ 
		::formatf("CGraphFWPositionSenseRegister: All: %.4X ", all); 
		::formatf(", PosSenseHomeA: %u ", (unsigned)PosSenseHomeA);
		::formatf(", PosSenseBit0A: %u ", (unsigned)PosSenseBit0A);
		::formatf(", PosSenseBit1A: %u ", (unsigned)PosSenseBit1A);
		::formatf(", PosSenseBit2A: %u ", (unsigned)PosSenseBit2A);
		::formatf(", PosSenseHomeB: %u ", (unsigned)PosSenseHomeB);
		::formatf(", PosSenseBit0B: %u ", (unsigned)PosSenseBit0B);
		::formatf(", PosSenseBit1B: %u ", (unsigned)PosSenseBit1B);
		::formatf(", PosSenseBit2B: %u ", (unsigned)PosSenseBit2B);
		::formatf(", PosSenseA: 0x%.1X ", (unsigned)PosSenseA);
		::formatf(", PosSenseA: 0x%.1X ", (unsigned)PosSenseB);
	}

} __attribute__((packed, aligned(4)));

union CGraphFWPositionStepRegister
{
    uint64_t all;
    struct 
    {
        int16_t OnStep;// : 16;
		uint16_t reserved1;// : 16;
        int16_t OffStep;// : 16; //Word offset reliably crashes uC
		uint16_t reserved2;// : 16;
        
    } __attribute__((packed, aligned(4)));

    CGraphFWPositionStepRegister() { all = 0; }
	CGraphFWPositionStepRegister(const uint64_t& a) { all = a; }
	
	int16_t MidStep() const { return(std::min(OnStep, OffStep) + (abs(OnStep - OffStep) / 2 )); }

	void formatf() const 
	{ 
		::formatf("StepRegister: All: %.8X ", all); 
		::formatf(", OnStep: %d ", OnStep);
		::formatf(", OffStep: %d ", OffStep);
		::formatf(", MidStep: %d ", MidStep());
	}

} __attribute__((packed, aligned(4)));

struct CGraphFWHardwareInterface
{
    uint32_t DeviceSerialNumber; //ro; FPGA manufacturer hardcoded device UUID
    uint32_t FpgaFirmwareBuildNumber; //ro; Auto-incremented firmware UUID
    
	uint32_t UnixSeconds; //rw; equivalent to time_t for 32b systems; low order bits of time_t on 64b systems; write to set/initialize FPGA clock
    uint32_t IdealTicksPerSecond; //ro; Target clock speed of FPGA device, approx 100M; likely 14.7456M * 7 = 103,219,200.
    uint32_t ActualTicksLastSecond; //ro; Count of clock ticks for entire last second; equal to IdealTicksPerSecond unless clock was set or GPS PPS signal is present
	uint32_t ClockTicksThisSecondAddr; //ro Running count of clock ticks since the start of the current second
    uint32_t ClockSteeringDacSetpoint; //rw; 
    int32_t PPSRtcPhaseComparator; //ro;
    
	//~ CGraphFWHardwareControlRegister ControlRegister; //rw; see definition above
    //~ CGraphFWMotorControlStatusRegister MotorControlStatus; //rw; motor settings
	//~ CGraphFWPositionSenseRegister PositionSensors; //ro; state of all the position sensor readouts
	uint32_t ControlRegister; //rw; see definition above
    uint32_t MotorControlStatus; //rw; motor settings
	uint32_t PositionSensors; //ro; state of all the position sensor readouts
    
	//~ AdcAccumulator MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
	uint32_t MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
	uint32_t MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
	uint32_t MonitorAdcSpiTransactionRegister;
	//~ CGraphMonitorAdcCommandStatusRegister MonitorAdcSpiCommandStatusRegister;
	uint32_t MonitorAdcSpiCommandStatusRegister;
	
	//~ CGraphBaudDividers BaudDividers; //rw; clock dividers for the configurable serial ports (0-3 RS-485 only)
	uint32_t BaudDividers; //rw; clocks dividers for the configurable serial ports (0-3 RS-485 only)
	
	uint32_t UartFifo0; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegister0; //ro; what state are the uart(s) in?
	uint32_t UartStatusRegister0; //ro; what state are the uart(s) in?
	uint32_t UartFifo0ReadData;
    
	uint32_t UartFifo1; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegister1; //ro; what state are the uart(s) in?
	uint32_t UartStatusRegister1; //ro; what state are the uart(s) in?
	uint32_t UartFifo1ReadData;
    
	uint32_t UartFifo2; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegister2; //ro; what state are the uart(s) in?
	uint32_t UartStatusRegister2; //ro; what state are the uart(s) in?
	uint32_t UartFifo2ReadData;
    
	uint32_t UartFifo3; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegister3; //ro; what state are the uart(s) in?
	uint32_t UartStatusRegister3; //ro; what state are the uart(s) in?
	uint32_t UartFifo3ReadData;
    
	uint32_t UartFifoUsb; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegisterUsb; //ro; what state are the uart(s) in?
	uint32_t UartStatusRegisterUsb; //ro; what state are the uart(s) in?
	uint32_t UartFifoUsbReadData;
    
	uint32_t UartFifoGps; //rw; send or read bytes from uart(s)
	//~ UartStatusRegister UartStatusRegisterGps; //ro; what state are the uart(s) in?
	uint32_t UartStatusRegisterGps; //ro; what state are the uart(s) in?
	uint32_t UartFifoGpsReadData;
    
	//~ CGraphFWPositionStepRegister PosDetHomeA; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetA0; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetA1; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetA2; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetHomeB; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetB0; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetB1; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDetB2; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet0A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet1A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet2A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet3A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet4A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet5A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet6A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet7A; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet0B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet1B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet2B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet3B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet4B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet5B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet6B; //ro; the step at which this signal toggled
	//~ CGraphFWPositionStepRegister PosDet7B; //ro; the step at which this signal toggled
	
	uint64_t PosDetHomeA; //ro; the step at which this signal toggled
	uint64_t PosDetA0; //ro; the step at which this signal toggled
	uint64_t PosDetA1; //ro; the step at which this signal toggled
	uint64_t PosDetA2; //ro; the step at which this signal toggled
	uint64_t PosDetHomeB; //ro; the step at which this signal toggled
	uint64_t PosDetB0; //ro; the step at which this signal toggled
	uint64_t PosDetB1; //ro; the step at which this signal toggled
	uint64_t PosDetB2; //ro; the step at which this signal toggled
	uint64_t PosDet0A; //ro; the step at which this signal toggled
	uint64_t PosDet1A; //ro; the step at which this signal toggled
	uint64_t PosDet2A; //ro; the step at which this signal toggled
	uint64_t PosDet3A; //ro; the step at which this signal toggled
	uint64_t PosDet4A; //ro; the step at which this signal toggled
	uint64_t PosDet5A; //ro; the step at which this signal toggled
	uint64_t PosDet6A; //ro; the step at which this signal toggled
	uint64_t PosDet7A; //ro; the step at which this signal toggled
	uint64_t PosDet0B; //ro; the step at which this signal toggled
	uint64_t PosDet1B; //ro; the step at which this signal toggled
	uint64_t PosDet2B; //ro; the step at which this signal toggled
	uint64_t PosDet3B; //ro; the step at which this signal toggled
	uint64_t PosDet4B; //ro; the step at which this signal toggled
	uint64_t PosDet5B; //ro; the step at which this signal toggled
	uint64_t PosDet6B; //ro; the step at which this signal toggled
	uint64_t PosDet7B; //ro; the step at which this signal toggled
	
	uint32_t Uart0RxFifoPeekReadAddr;
	uint32_t Uart0RxFifoPeekWriteAddr;
	uint32_t Uart0RxFifoPeekPeekAddr;
	uint32_t Uart0RxFifoPeekPeekData;
	uint32_t Uart0RxFifoPeekMultiPopAddr;
	uint32_t Uart0CrcStartAddr;
	uint32_t Uart0CrcEndAddr;
	//~ CGraphCrcCurrentAddr Uart0CrcCurrentAddr;
	uint32_t Uart0CrcCurrentAddr;
	uint32_t Uart0Crc;
	
	uint32_t Uart0HeaderEndPos;
	uint32_t Uart0FooterEndPos;
	uint32_t Uart0PayloadType;
	uint32_t Uart0PayloadLen;
	uint32_t Uart0PacketCrc;
	uint32_t Uart0CalcCrc;
	
} __attribute__((packed, aligned(4)));

extern CGraphFWHardwareInterface* volatile FW;

//EOF
