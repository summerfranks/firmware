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
#include "cgraph/CGraphPacket.hpp"
//#include "CGraphFSMHardwareInterface.hpp" //AdcAccumulator definition

union CGraphDMHardwareControlRegister
{
    uint32_t all;
    struct 
    {
        uint16_t HighVoltageEnable : 1; //b0; Turn on the +150V supply
        uint16_t PowerEnable : 1; //b2; Turn on the secondary supplies

    } __attribute__((packed, aligned(4)));

    CGraphDMHardwareControlRegister() { all = 0; }

    //~ void formatf() const { ::formatf("CGraphDMHardwareControlRegister: Sample: %+10.0lf ", (double)Sample); ::formatf("(0x%.8lX", (unsigned long)(all >> 32));  ::formatf("%.8lX)", (unsigned long)(all)); ::formatf(", NumAccums: %lu ", (unsigned long)NumAccums); ::formatf("(0x%lX)", (unsigned long)NumAccums); }

} __attribute__((packed, aligned(4)));

union CGraphDMHardwareStatusRegister
{
    uint32_t all;
    struct 
    {
        uint32_t PPSDetected : 1; //b0; Is there toggling on the PPS input?
        uint32_t HVFault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t VNegFault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V1Fault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V3DmFault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V3FpgaFault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V3AuxFault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V5Fault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V6Fault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
		uint32_t V9Fault : 1; //b1; Overtemperature or overcurrent on first high voltage output driver
        
    } __attribute__((packed, aligned(4)));

    CGraphDMHardwareStatusRegister() { all = 0; }

    //~ void formatf() const { ::formatf("CGraphDMHardwareStatusRegister: Sample: %+10.0lf ", (double)Sample); ::formatf("(0x%.8lX", (uint32_t)(all >> 32));  ::formatf("%.8lX)", (uint32_t)(all)); ::formatf(", NumAccums: %lu ", (uint32_t)NumAccums); ::formatf("(0x%lX)", (uint32_t)NumAccums); }

} __attribute__((packed, aligned(4)));

//union CGraphDMUartStatusRegister
//{
//    uint32_t all;
//    struct 
//    {
//        uint32_t UartRxFifoEmpty : 1;
//        uint32_t UartRxFifoFull : 1;
//        uint32_t UartTxFifoEmpty : 1;
//        uint32_t UartTxFifoFull : 1;
//		uint32_t reserved1 : 4;
//		uint32_t UartRxFifoCount : 8;
//		uint32_t UartTxFifoCount : 8;
//		uint32_t UartRxFifoCountHi : 2;
//		uint32_t UartTxFifoCountHi : 2;
//		uint32_t reserved2 : 4;
//
//    } __attribute__((packed, aligned(4)));
//
//    CGraphDMUartStatusRegister() { all = 0; }
//
//    //~ void formatf() const { ::formatf("CGraphDMUartStatusRegister: RxE:%c, RxF:%c, TxE:%c, TxF:%c, RxC:%u, TxC:%u", UartRxFifoEmpty?'Y':'N', UartRxFifoFull?'Y':'N', UartTxFifoEmpty?'Y':'N', UartTxFifoFull?'Y':'N', UartRxFifoCount + (UartRxFifoCountHi << 8), UartTxFifoCount + (UartTxFifoCountHi << 8)); }
//	void formatf() const { ::formatf("CGraphDMUartStatusRegister: RxE:%c, RxF:%c, TxE:%c, TxF:%c, RxC:%u, TxC:%u", UartRxFifoEmpty?'Y':'N', UartRxFifoFull?'Y':'N', UartTxFifoEmpty?'Y':'N', UartTxFifoFull?'Y':'N', UartRxFifoCount, UartTxFifoCount); }
//
//} __attribute__((packed, aligned(4)));

struct CGraphDMHardwareInterface
{
  uint32_t DeviceSerialNumber; //ro; FPGA manufacturer hardcoded device UUID 0
  uint32_t FpgaFirmwareBuildNumber; //ro; Auto-incremented firmware UUID     4
  uint32_t UnixSeconds; //rw; equivalent to time_t for 32b systems; low order bits of time_t on 64b systems; write to set/initialize FPGA clock 8
  uint32_t IdealTicksPerSecond; //ro; Target clock speed of FPGA device, approx 100M; likely 14.7456M * 7 = 103,219,200. 12
  uint32_t ActualTicksLastSecond; //ro; Count of clock ticks for entire last second; equal to IdealTicksPerSecond unless clock was set or GPS PPS signal is present 16
  uint32_t ClockTicksThisSecondAddr; //ro Running count of clock ticks since the start of the current second
  uint32_t ClockSteeringDacSetpointAddr; //rw; 24
  uint32_t ControlRegisterAddr; // 28 either this way of setting Dac's or the flat model, below...
  uint32_t DacSetpointBdAAddr; // 32 either this way of setting Dac's or the flat model, below...
  uint32_t DacSetpointBdBAddr; // 36 either this way of setting Dac's or the flat model, below...
  uint32_t DacSetpointBdCAddr; // 40 either this way of setting Dac's or the flat model, below...
  uint32_t DacSetpointBdDAddr; // 44 either this way of setting Dac's or the flat model, below...
  uint32_t DacSetpointBdEAddr; // 48 either this way of setting Dac's or the flat model, below...
  uint32_t DacSetpointBdFAddr; // 52 either this way of setting Dac's or the flat model, below...
  AdcAccumulator MonitorAdcAAccumulator; //ro; 56 Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  AdcAccumulator MonitorAdcBAccumulator; //ro; 64 Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  AdcAccumulator MonitorAdcCAccumulator; //ro; 72 Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  AdcAccumulator MonitorAdcDAccumulator; //ro; 80 Monitor A/D samples for channel specififed in MonitorAdcReadChannel

  CGraphDMHardwareControlRegister ControlRegister; //rw; 88 see definition above
  CGraphDMHardwareStatusRegister StatusRegister;   //ro; 92 see definition above
  //  int32_t PPSRtcPhaseComparator; //44 ro;
  //int32_t PPSAdcPhaseComparator; //48 ro;
  //AdcAccumulator MonitorAdc0Accumulator; //ro; 52 Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t MonitorAdc0ReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator MonitorAdc1Accumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t MonitorAdc1ReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator DMController0MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t DMController0MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator DMController1MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t DMController1MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator DMController2MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t DMController2MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator DMController3MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t DMController3MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator DMController4MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t DMController4MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
  //AdcAccumulator DMController5MonitorAdcAccumulator; //ro; Monitor A/D samples for channel specififed in MonitorAdcReadChannel
  //uint32_t DMController5MonitorAdcReadChannel; //rw; which channel to read for MonitorA/D
  CGraphBaudDividers BaudDividers;  // ; 96 32 bits
  uint32_t UartFifo0; //rw; 100 send or read bytes from uart(s)
  UartStatusRegister UartStatusRegister0; //ro; 104 what state are the uart(s) in?
  uint32_t UartFifo0ReadData; // 108
  uint32_t UartFifo1; //rw; 112 send or read bytes from uart(s)
  UartStatusRegister UartStatusRegister1; //ro; 116 what state are the uart(s) in?
  uint32_t UartFifo1ReadData; // 120
  uint32_t UartFifo2; //rw; 124 send or read bytes from uart(s)
  UartStatusRegister UartStatusRegister2; //ro; 128 what state are the uart(s) in?
  uint32_t UartFifo2ReadData; // 132
  uint32_t UartFifo3; //rw; 136 send or read bytes from uart(s)
  UartStatusRegister UartStatusRegister3; //ro; 140 what state are the uart(s) in?
  uint32_t UartFifo3ReadData; // 144

  uint32_t StartMachine; // 148
  uint32_t GetTimer; // 152
//  uint8_t BaudDivider0; //rw; clock divider for the first serial port
//  uint8_t BaudDivider1;
//  uint8_t BaudDivider2;
//  uint8_t BaudDivider3;
//  uint16_t SpiExtBusAddrOut;
//  uint16_t SpiExtBusAddrIn;
//  uint16_t SpiExtBusDataOut;
//  uint16_t SpiExtBusDataIn;
  //uint32_t reserved[217]; //if we counted correctly there's 48 4-byte registers preceeding this padding...
  //uint32_t DacSetpoints[DMMaxControllerBoards][DMMDacsPerControllerBoard][DMActuatorsPerDac];
  uint32_t DacSetpointMappingIndex; //set this first to what mapping we want to change (can readback for debugging)(0...959)
  uint32_t DacSetpointMappings; //then write to this to update mapping at that index (can readback for debugging)
  
  static const uint32_t DacFullScale;
  static const double DacDriverFullScaleOutputVoltage; //150 Volts, don't get your fingers near this thing!
  static const double DMDriverFullScaleOutputTravel; //Meters; note our granularity is this / DacFullScale which is approx 10pm

    //~ void formatf() const { ::formatf("CGraphDMHardwareInterface: Sample: %+10.0lf ", (double)Sample); ::formatf("(0x%.8lX", (uint32_t)(all >> 32));  ::formatf("%.8lX)", (uint32_t)(all)); ::formatf(", NumAccums: %lu ", (uint32_t)NumAccums); ::formatf("(0x%lX)", (uint32_t)NumAccums); }

} __attribute__((packed, aligned(4)));

extern CGraphDMHardwareInterface* DM;

struct CGraphDMRamInterface
{
  uint32_t DacSetpoints[DMMaxControllerBoards][DMMDacsPerControllerBoard][DMActuatorsPerDac];
} __attribute__((packed, aligned(4)));

extern CGraphDMRamInterface* dRAM;

class CGraphDMProtoHardwareMmapper
{
public:

    static const off_t FpgaMmapAdress;
    static const off_t FpgaMmapMask;
    static const char FpgaBusEmulationPathName[];

    //~ int FpgaHandle;
    //~ void* FpgaBus;

    //~ CGraphDMHardwareMmapper(const bool OpenOnConstruct = false) :

    //~ FpgaHandle(0),
    //~ FpgaBus(MAP_FAILED)//,

    //~ { if (OpenOnConstruct) { open(); } }

    //~ ~CGraphDMHardwareMmapper() { close(); }

    static int open(int& FpgaHandle, CGraphDMHardwareInterface*& FpgaBus);
    static int close(int& FpgaHandle, CGraphDMHardwareInterface*& FpgaBus);
    static int read(const CGraphDMHardwareInterface* FpgaBus, const size_t Address, void* Buffer, const size_t Len);
    static int write(CGraphDMHardwareInterface* FpgaBus, const size_t Address, const void* Buffer, const size_t Len);
};

//EOF
