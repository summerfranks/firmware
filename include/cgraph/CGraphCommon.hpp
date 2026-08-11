//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#pragma once
#include <stdint.h>

#include "uart/UartStatusRegister.hpp"

#include "format/formatf.h"

//~ union AdcAccumulator 		
//~ {
    //~ uint64_t all;
    //~ struct 
	struct AdcAccumulator
    {
        //~ int64_t Samples : 48;
		//~ int64_t Samples : 32;
		//~ int64_t reserved : 16;
		//~ int32_t Samples;
		//~ int16_t reserved;
        //~ uint16_t NumAccums;
		int64_t Samples : 32;
		int64_t reserved : 16;
		int64_t NumAccums : 16;
		

    //~ } __attribute__((packed, aligned(4)));

    //static const int32_t AdcFullScale = 0x7FFFFFFFL; //2^32 - 1; must divide accumulator by numaccums first obviously

    AdcAccumulator() { Samples = 0; reserved = 0; NumAccums = 0; }
	
	void SetHiWord(const uint32_t& hi) { reserved = hi & 0xFFFFU; NumAccums = hi >> 16; }

    //~ void formatf() const { ::formatf("AdcAccumulator: Samples: %+10.0lf ", (double)Samples); ::formatf("(0x%.8lX", (unsigned long)(all >> 32));  ::formatf("%.8lX)", (unsigned long)(all)); ::formatf(", Samples: %.8lX, reserved: %.8lX, NumAccums: %lu ", (unsigned long)Samples, (unsigned long)reserved, (unsigned long)NumAccums); ::formatf("(0x%lX)", (unsigned long)NumAccums); }
	void formatf() const { ::formatf("AdcAccumulator: Samples: %+10.0lf ", (double)Samples); ::formatf(", Samples: %.8lX, reserved: %.8lX, NumAccums: %lu ", (unsigned long)Samples, (unsigned long)reserved, (unsigned long)NumAccums); ::formatf("(0x%lX)", (unsigned long)NumAccums); }

} __attribute__((packed, aligned(4)));

union AdcTimestamp
{
    uint32_t all;
    struct 
    {
        uint32_t SubsecondTicks : 27; //Max FPGA clock rate for 27b is 134,217,728Hz (134MHz) works well for our target speed of 103MHz.
        uint32_t UnixTimeLsbs: 5; //We'd really like a little more granularity, but it's only ambiguous every 32 seconds I think we can deal with that...

    } __attribute__((packed, aligned(4)));

    //~ AdcTimestamp() { all = 0; }

    //~ void formatf() const { ::formatf("AdcTimestamp: SubsecondTicks: %+10.0lf ", (double)SubsecondTicks); ::formatf("(0x%.8lX", (unsigned long)(all >> 32));  ::formatf("%.8lX)", (unsigned long)(all)); ::formatf(", NumAccums: %lu ", (unsigned long)NumAccums); ::formatf("(0x%lX)", (unsigned long)NumAccums); }

} __attribute__((packed, aligned(4)));

union AdcFifo
{
    uint64_t all;
    struct 
    {
        int32_t Sample;
        AdcTimestamp Timestamp;
        //~ uint16_t NumSamplesInFifo; //this makes it 10 bytes instead of 8...which for some reason makes acessing uartstatusregister segfault

    } __attribute__((packed, aligned(4)));

    //~ static const int32_t AdcFullScale = 0x7FFFFFFFL; //2^32 - 1;
    //~ static const uint16_t FifoMaxDepth = 0x0FFFUL; //The FPGA doesn't actually have very much ram for fifos.

    AdcFifo() { all = 0; }

    //~ void formatf() const { ::formatf("AdcFifo: Sample: %+10.0lf ", (double)Sample); ::formatf("(0x%.8lX", (unsigned long)(all >> 32));  ::formatf("%.8lX)", (unsigned long)(all)); ::formatf(", NumAccums: %lu ", (unsigned long)NumAccums); ::formatf("(0x%lX)", (unsigned long)NumAccums); }

} __attribute__((packed, aligned(4)));

union AdcConfigRegister 		
{
    uint32_t all;
    struct 
    {
        uint16_t AdcClkDivider;
		uint16_t AdcSamplesToAverage;

    } __attribute__((packed, aligned(4)));

    AdcConfigRegister() { all = 0; }

    void formatf() const { ::formatf("AdcConfigRegister: AdcClkDivider: %u (0x%4X), AdcSamplesToAverage %u (0x%4X)", AdcClkDivider, AdcClkDivider, AdcSamplesToAverage, AdcSamplesToAverage); }

} __attribute__((packed, aligned(4)));

union AccumulatorConfigRegister 		
{
    uint32_t all;
    struct 
    {
        uint16_t ControlAdcMaxAccums;
		uint16_t MonitorAdcMaxAccums;

    } __attribute__((packed, aligned(4)));

    AccumulatorConfigRegister() { all = 0; }

    void formatf() const { ::formatf("AccumulatorConfigRegister: ControlAdcMaxAccums: %u (0x%4X), MonitorAdcMaxAccums %u (0x%4X)", ControlAdcMaxAccums, ControlAdcMaxAccums, MonitorAdcMaxAccums, MonitorAdcMaxAccums); }

} __attribute__((packed, aligned(4)));

union DacConfigRegister 		
{
    uint32_t all;
    struct 
    {
        uint16_t DitherClkDivider;
		uint16_t reserved;

    } __attribute__((packed, aligned(4)));

    DacConfigRegister() { all = 0; }

    void formatf() const { ::formatf("DacConfigRegister: DitherClkDivider: %u (0x%4X), reserved %u (0x%4X)", DitherClkDivider, DitherClkDivider, reserved, reserved); }

} __attribute__((packed, aligned(4)));

union CGraphBaudDividers
{
    uint32_t all;
    struct 
    {
        uint32_t Divider0 : 8;
		uint32_t Divider1 : 8;  //8b offsets reliably crash uC
		uint32_t Divider2 : 8;
		uint32_t Divider3 : 8;
        
    } __attribute__((packed, aligned(4)));

    CGraphBaudDividers() { all = 0; }
	
	void formatf() const 
	{ 
		::formatf("CGraphBaudDividers: All: %.4X ", all); 
		::formatf(", Divider0: %u ", (unsigned)Divider0);
		::formatf(", Divider1: %u ", (unsigned)Divider1);
		::formatf(", Divider2: %u ", (unsigned)Divider2);
		::formatf(", Divider3: %u ", (unsigned)Divider3);
	}

} __attribute__((packed, aligned(4)));

union CGraphMonitorAdcCommandStatusRegister
{
    uint32_t all;
    struct 
    {
        uint32_t FrameEnable : 1; //1=nCs asserted (0), 0=nCs clear (1)
        uint32_t TransactionComplete : 1; //Is the bus busy?
        uint32_t nDrdy : 1; //Samples ready?
        
    } __attribute__((packed, aligned(4)));

    CGraphMonitorAdcCommandStatusRegister() { all = 0; }

    void formatf() const { ::formatf("CGraphMonitorAdcCommandStatusRegister: FrameEnable:%c, TransactionComplete:%c, nDrdy:%c", FrameEnable?'1':'0', TransactionComplete?'1':'0', nDrdy?'1':'0'); }

} __attribute__((packed, aligned(4)));

union CGraphDualMonitorAdcCommandStatusRegister
{
    uint32_t all;
    struct 
    {
        uint32_t FrameEnable : 1; //1=nCs asserted (0), 0=nCs clear (1)
        uint32_t TransactionComplete : 1; //Is the bus busy?
        uint32_t nDrdy0 : 1; //Samples ready?
		uint32_t nDrdy1 : 1; //Samples ready?
        
    } __attribute__((packed, aligned(4)));

    CGraphDualMonitorAdcCommandStatusRegister() { all = 0; }

    void formatf() const { ::formatf("CGraphDualMonitorAdcCommandStatusRegister: FrameEnable:%c, TransactionComplete:%c, nDrdy0:%c, nDrdy1:%c", FrameEnable?'1':'0', TransactionComplete?'1':'0', nDrdy0?'1':'0', nDrdy1?'1':'0'); }

} __attribute__((packed, aligned(4)));

union CGraphCrcCurrentAddr
{
    uint32_t all;
    struct 
    {
        uint32_t CurrentAddr : 31;
		uint32_t CrcComplete : 1;
        
    } __attribute__((packed, aligned(4)));

    CGraphCrcCurrentAddr() { all = 0; }
    CGraphCrcCurrentAddr(volatile CGraphCrcCurrentAddr& c) { all = c.all; }
	CGraphCrcCurrentAddr& operator=(const CGraphCrcCurrentAddr& c)  { all = c.all; return(*this); }
	//~ CGraphCrcCurrentAddr& operator=(volatile CGraphCrcCurrentAddr& c)  { all = c.all; return(*this); }
	
	void formatf() const //note: using this function causes some major fuckery with the volatile qulifier in many places...
	{ 
		::formatf("CGraphCrcCurrentAddr: All: %.4X ", all); 
		::formatf(", CurrentAddr: %u ", (unsigned)CurrentAddr);
		::formatf(", CrcComplete: %c ", CrcComplete?'Y':'N');
	}

} __attribute__((packed, aligned(4)));

struct FpgaRingBufferCrcer
{
	FpgaRingBufferCrcer(volatile uint32_t* const crcstartaddr, volatile uint32_t* const crcendaddr, volatile CGraphCrcCurrentAddr* const crccurentaddr, volatile uint32_t* const crcresult) :
		CrcStartAddr(crcstartaddr),
		CrcEndAddr(crcendaddr),
		CrcCurrentAddr(crccurentaddr),
		CrcResult(crcresult)
	{ }
	
	public:
		
		volatile uint32_t* const CrcStartAddr;
		volatile uint32_t* const CrcEndAddr;
		volatile CGraphCrcCurrentAddr* const CrcCurrentAddr;
		volatile uint32_t* const CrcResult;
	
	void formatf() const //note: using this function causes some major fuckery with the volatile qulifier in many places...
	{ 
		::formatf("FpgaRingBufferCrcer: ");
		::formatf("CrcStartAddr: 0x%8lX, ", (unsigned long)CrcStartAddr);
		::formatf("CrcEndAddr: 0x%8lX, ", (unsigned long)CrcEndAddr);
		::formatf("CrcCurrentAddr: 0x%8lX, ", (unsigned long)CrcCurrentAddr);
		::formatf("CrcResult: 0x%8lX.", (unsigned long)CrcResult);		
	}

};

//EOF
