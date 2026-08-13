//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
///
///           based on a framework Copyright (c) 2009 by Franks Development, LLC, used with permission
//

#pragma once

#include <stdint.h>
#include <string.h>

#include "Delay.h"
//~ #include "adc/lt244x_accum.h"
//~ #include "adc/lt244x.h"
#define DEBUGADC
#include "adc/ads1258dual.h"
#include "temp/TempLM35.hpp"
#include "format/formatf.h"

#include "cgraph/CGraphFSMHardwareInterface.hpp"
extern CGraphFSMHardwareInterface* volatile FSM;	

//Note: if any offsets are not 4-byte aligned, the M3 processor WILL crash:
const size_t MonitorAdcFpgaAdcSampleAddr = 92;
const size_t MonitorAdcFpgaAdcChannelAddr = 100;
const size_t MonitorAdcFpgaSpiXferAddr = 104;
const size_t MonitorAdcSpiCommandStatusRegister = 108;

struct PinoutMonitorAdc
{
	PinoutMonitorAdc() { }
	virtual ~PinoutMonitorAdc() { }
	static uint8_t GetAdcReadChannel()								{ uint8_t val = *(((uint8_t*)FSM)+MonitorAdcFpgaAdcChannelAddr); return(val); }
	static void SetAdcReadChannel(const uint8_t val) 					{ *(((uint8_t*)FSM)+MonitorAdcFpgaAdcChannelAddr) = (uint8_t)val; }
	//~ old way to hopefully implement later: static void GetAdcSample(Ltc244xAccumulator& val) { val = *((Ltc244xAccumulator*)(((uint8_t*)FSM)+MonitorAdcFpgaAdcSampleAddr)); }		
	
	static const size_t spi_timeout = 100;
	
	static bool busy() { return(0 == (CGraphDualMonitorAdcCommandStatusRegister(FSM->MonitorAdcSpiCommandStatusRegister).TransactionComplete) ); }
	static void waitbusytimeout()
	{
		size_t i = 0;
		for(i = 0; i < spi_timeout; i++) 
		{ 
			if (!busy()) { break; } 
			delayus(1);
		}
		if (i >= spi_timeout - 2) { formatf("\nPinoutMonitorAdc: T/O."); }
	}
	
	//~ static void enable(const bool en) { FSM->MonitorAdcSpiCommandStatusRegister.all = (uint32_t)en; }
	static void enable(const bool en) { CGraphDualMonitorAdcCommandStatusRegister fe; fe.FrameEnable = en; FSM->MonitorAdcSpiCommandStatusRegister = fe.all; } //If frame enable isn't in the zero offset byte this is gonna do a big ol memory protection fault, cause our compiler is stupid...
	
	static void transmit(const uint32_t val) 					
	{ 
		waitbusytimeout();
		FSM->MonitorAdcSpiTransactionRegister = val; 
	}
	
	static uint32_t receive(uint32_t val) 				
	{ 
		uint32_t out = 0;
		
		//Do the xfer
		waitbusytimeout();
		FSM->MonitorAdcSpiTransactionRegister = val; 
		
		//readback
		waitbusytimeout();
		out = FSM->MonitorAdcSpiTransactionRegister; 
		
		//~ return(out & 0x0000FFFFUL);
		return(out);
	}		
	
	static bool nDrdy() 				
	{ 
		return( (0 == (CGraphDualMonitorAdcCommandStatusRegister(FSM->MonitorAdcSpiCommandStatusRegister).nDrdy0) ) || (0 == (CGraphDualMonitorAdcCommandStatusRegister(FSM->MonitorAdcSpiCommandStatusRegister).nDrdy1) ) );
	}		
	
	static void setclkpolarity(const bool en) { } //handled by fpga
	static void setclkphase(const bool en) { } //handled by fpga
};
	
struct MonitorAdcCalibratedInput
{
	private:
		
		double Gain;
		double Offset;
		
	public:
		
	MonitorAdcCalibratedInput(double gain, double offset) : Gain(gain), Offset(offset) { }
	MonitorAdcCalibratedInput() : Gain(1.0), Offset(0.0) { }
	MonitorAdcCalibratedInput(const MonitorAdcCalibratedInput& a) : Gain(a.Gain), Offset(a.Offset) { }
	
	void Calibrate(double gain, double offset) { Gain = gain; Offset = offset; }
	
	double ReadCalibrated(const int32_t& RawInput) const { return(((ads1258details::CountsToVolts(RawInput, 4.096)) * Gain) + Offset); }
	//~ old way to hopefully re-implment in future: double ReadCalibrated(const Ltc244xAccumulator& RawInput) const { return( (RawInput.CountsToVolts() * Gain) + Offset); }
	
	double GetGain() const { return(Gain); }
	double GetOffset() const { return(Offset); }
};

//Adc0 Calibrates
extern MonitorAdcCalibratedInput IHVCalibrate; // ads1258details::chan_se0
extern MonitorAdcCalibratedInput INVCalibrate; // ads1258details::chan_se1
extern MonitorAdcCalibratedInput I6VCalibrate; // ads1258details::chan_se2
extern MonitorAdcCalibratedInput I3VDCalibrate; // ads1258details::chan_se3
extern MonitorAdcCalibratedInput I2VDCalibrate; // ads1258details::chan_se4
extern MonitorAdcCalibratedInput I1VCalibrate; // ads1258details::chan_se5
extern MonitorAdcCalibratedInput StrainBPCalibrate; // ads1258details::chan_se6
extern MonitorAdcCalibratedInput StrainBMCalibrate; // ads1258details::chan_se7
extern MonitorAdcCalibratedInput StrainBCalibrate; // ads1258details::chan_diff3
extern MonitorAdcCalibratedInput StrainDPCalibrate; // ads1258details::chan_se8
extern MonitorAdcCalibratedInput StrainDMCalibrate; // ads1258details::chan_se9
extern MonitorAdcCalibratedInput StrainDCalibrate; // ads1258details::chan_diff4
extern MonitorAdcCalibratedInput StrainCMCalibrate; // ads1258details::chan_se10
extern MonitorAdcCalibratedInput StrainCPCalibrate; // ads1258details::chan_se11
extern MonitorAdcCalibratedInput StrainCCalibrate; // ads1258details::chan_diff5
extern MonitorAdcCalibratedInput StrainAMCalibrate; // ads1258details::chan_se12
extern MonitorAdcCalibratedInput StrainAPCalibrate; // ads1258details::chan_se13
extern MonitorAdcCalibratedInput StrainACalibrate; // ads1258details::chan_diff6
extern MonitorAdcCalibratedInput P5VDCalibrate; // ads1258details::chan_se14
extern MonitorAdcCalibratedInput I2VACalibrate; // ads1258details::chan_se15

//Adc1 Calibrates
extern MonitorAdcCalibratedInput TempCalibrate; // ads1258details::chan_se0
extern MonitorAdcCalibratedInput P3V3DCalibrate; // ads1258details::chan_se1
extern MonitorAdcCalibratedInput P28VCalibrate; // ads1258details::chan_se2
extern MonitorAdcCalibratedInput P2V2Calibrate; // ads1258details::chan_se3
extern MonitorAdcCalibratedInput P2V5DCalibrate; // ads1258details::chan_se4
extern MonitorAdcCalibratedInput P1V2Calibrate; // ads1258details::chan_se5
extern MonitorAdcCalibratedInput P2V5ACalibrate; // ads1258details::chan_se6
extern MonitorAdcCalibratedInput P4V3Calibrate; // ads1258details::chan_se7
extern MonitorAdcCalibratedInput I3VACalibrate; // ads1258details::chan_se8
extern MonitorAdcCalibratedInput P3V3ACalibrate; // ads1258details::chan_se9
extern MonitorAdcCalibratedInput P6VCalibrate; // ads1258details::chan_se10
extern MonitorAdcCalibratedInput P5VACalibrate; // ads1258details::chan_se11
extern MonitorAdcCalibratedInput LuxRadsCalibrate; // ads1258details::chan_se12
extern MonitorAdcCalibratedInput N18VCalibrate; // ads1258details::chan_se13
extern MonitorAdcCalibratedInput N20VCalibrate; // ads1258details::chan_se14
extern MonitorAdcCalibratedInput P125VCalibrate; // ads1258details::chan_se15


//~ template <class spi, class adcpinout, unsigned int spiclkdivider = 39>
struct CGraphFSMMonitorAdc
{
	
private:
			
	//~ lt244x_accum<PinoutMonitorAdc> Adc;
	//~ ads1258<PinoutMonitorAdc> Adc;

	bool AdcFound;
	bool Monitor;
	
    //~ static const uint8_t GpioDirections = 0xEF; //0111:1111 - bit 7 is output
	static const uint8_t GpioDirections = 0x00; //All outputs (unused should be outputs according to datasheet)
    static const uint8_t StartPinMask = 0x80; //Gpio7

	//Adc0
	int32_t IHV; // ads1258details::chan_se0
	int32_t INV; // ads1258details::chan_se1
	int32_t I6V; // ads1258details::chan_se2
	int32_t I3VD; // ads1258details::chan_se3
	int32_t I2VD; // ads1258details::chan_se4
	int32_t I1V; // ads1258details::chan_se5
	int32_t StrainBP; // ads1258details::chan_se6
	int32_t StrainBM; // ads1258details::chan_se7
	int32_t StrainB; // ads1258details::chan_diff3
	int32_t StrainDP; // ads1258details::chan_se8
	int32_t StrainDM; // ads1258details::chan_se9
	int32_t StrainD; // ads1258details::chan_diff4
	int32_t StrainCM; // ads1258details::chan_se10
	int32_t StrainCP; // ads1258details::chan_se11
	int32_t StrainC; // ads1258details::chan_diff5
	int32_t StrainAM; // ads1258details::chan_se12
	int32_t StrainAP; // ads1258details::chan_se13
	int32_t StrainA; // ads1258details::chan_diff6
	int32_t P5VD; // ads1258details::chan_se14
	int32_t I2VA; // ads1258details::chan_se15
	
	//Adc1
	int32_t Temp; // ads1258details::chan_se0
	int32_t P3V3D; // ads1258details::chan_se1
	int32_t P28V; // ads1258details::chan_se2
	int32_t P2V2; // ads1258details::chan_se3
	int32_t P2V5D; // ads1258details::chan_se4
	int32_t P1V2; // ads1258details::chan_se5
	int32_t P2V5A; // ads1258details::chan_se6
	int32_t P4V3; // ads1258details::chan_se7
	int32_t I3VA; // ads1258details::chan_se8
	int32_t P3V3A; // ads1258details::chan_se9
	int32_t P6V; // ads1258details::chan_se10
	int32_t P5VA; // ads1258details::chan_se11
	int32_t LuxRads; // ads1258details::chan_se12
	int32_t N18V; // ads1258details::chan_se13
	int32_t N20V; // ads1258details::chan_se14
	int32_t P125V; // ads1258details::chan_se15

public:
	
	CGraphFSMMonitorAdc() : AdcFound(false), Monitor(false),
							//set all to 1.024V (could be ambiguous if things are actually dead): IHV(0x1E0000UL), 	INV(0x1E0000UL), 	I6V(0x1E0000UL), 	I3VD(0x1E0000UL), 	I2VD(0x1E0000UL), 	I1V(0x1E0000UL), 	StrainBP(0x1E0000UL), 	StrainBM(0x1E0000UL), 	StrainB(0x1E0000UL), 	StrainDP(0x1E0000UL), 	StrainDM(0x1E0000UL), 	StrainD(0x1E0000UL), 	StrainCM(0x1E0000UL), 	StrainCP(0x1E0000UL), 	StrainC(0x1E0000UL), 	StrainAM(0x1E0000UL), 	StrainAP(0x1E0000UL), 	StrainA(0x1E0000UL), 	P5VD(0x1E0000UL), 	I2VA(0x1E0000UL), 	Temp(0x1E0000UL), 	P3V3D(0x1E0000UL), 	P28V(0x1E0000UL), 	P2V2(0x1E0000UL), 	P2V5D(0x1E0000UL), 	P1V2(0x1E0000UL), 	P2V5A(0x1E0000UL), 	P4V3(0x1E0000UL), 	I3VA(0x1E0000UL), 	P3V3A(0x1E0000UL), 	P6V(0x1E0000UL), 	P5VA(0x1E0000UL), 	LuxRads(0x1E0000UL), 	N18V(0x1E0000UL), 	N20V(0x1E0000UL), 	P125V(0x1E0000UL),
							IHV(0UL), 	INV(0UL), 	I6V(0UL), 	I3VD(0UL), 	I2VD(0UL), 	I1V(0UL), 	StrainBP(0UL), 	StrainBM(0UL), 	StrainB(0UL), 	StrainDP(0UL), 	StrainDM(0UL), 	StrainD(0UL), 	StrainCM(0UL), 	StrainCP(0UL), 	StrainC(0UL), 	StrainAM(0UL), 	StrainAP(0UL), 	StrainA(0UL), 	P5VD(0UL), 	I2VA(0UL), 	Temp(0UL), 	P3V3D(0UL), 	P28V(0UL), 	P2V2(0UL), 	P2V5D(0UL), 	P1V2(0UL), 	P2V5A(0UL), 	P4V3(0UL), 	I3VA(0UL), 	P3V3A(0UL), 	P6V(0UL), 	P5VA(0UL), 	LuxRads(0UL), 	N18V(0UL), 	N20V(0UL), 	P125V(0UL),
							Adc(4.096)//,
	{ }
	
	~CGraphFSMMonitorAdc() { }
	
	ads1258dual<PinoutMonitorAdc> Adc;
	
	//~ static uint8_t GetAdcReadChannel()								{ uint8_t val = *(((uint8_t*)FSM)+MonitorAdcFpgaAdcChannelAddr); return(val); }
	//~ static void SetAdcReadChannel(const uint8_t val) 					{ *(((uint8_t*)FSM)+MonitorAdcFpgaAdcChannelAddr) = (uint8_t)val; }
	//~ static void GetAdcSample(Ltc244xAccumulator& val) 				{ val = *((Ltc244xAccumulator*)(((uint8_t*)FSM)+MonitorAdcFpgaAdcSampleAddr)); }		
	
	//Adc0 channels:
	#define IHVChannel ads1258details::chan_se0
	#define INVChannel ads1258details::chan_se1
	#define I6VChannel ads1258details::chan_se2
	#define I3VDChannel ads1258details::chan_se3
	#define I2VDChannel ads1258details::chan_se4
	#define I1VChannel ads1258details::chan_se5
	#define StrainBPChannel ads1258details::chan_se6
	#define StrainBMChannel ads1258details::chan_se7
	#define StrainBChannel ads1258details::chan_diff3
	#define StrainDPChannel ads1258details::chan_se8
	#define StrainDMChannel ads1258details::chan_se9
	#define StrainDChannel ads1258details::chan_diff4
	#define StrainCMChannel ads1258details::chan_se10
	#define StrainCPChannel ads1258details::chan_se11
	#define StrainCChannel ads1258details::chan_diff5
	#define StrainAMChannel ads1258details::chan_se12
	#define StrainAPChannel ads1258details::chan_se13
	#define StrainAChannel ads1258details::chan_diff6
	#define P5VDChannel ads1258details::chan_se14
	#define I2VAChannel ads1258details::chan_se15

	//Let's also plan on reading the internal registers!
	//Note that it is required to disable chopping (CHOP = 0) prior to taking this reading
	//~ const uint8_t chan_offset = 0x18; //24d
	//~ const uint8_t chan_zeroed = 0x19;
	//~ const uint8_t chan_vcc = 0x1A; //err?  skips 0x19 in datasheet!
	//~ const uint8_t chan_temp = 0x1B;
	//~ const uint8_t chan_gain = 0x1C; //28d
	//~ const uint8_t chan_ref = 0x1D;

	
	//Adc1 channels:
	#define TempChannel ads1258details::chan_se0
	#define P3V3DChannel ads1258details::chan_se1
	#define P28VChannel ads1258details::chan_se2
	#define P2V2Channel ads1258details::chan_se3
	#define P2V5DChannel ads1258details::chan_se4
	#define P1V2Channel ads1258details::chan_se5
	#define P2V5AChannel ads1258details::chan_se6
	#define P4V3Channel ads1258details::chan_se7
	#define I3VAChannel ads1258details::chan_se8
	#define P3V3AChannel ads1258details::chan_se9
	#define P6VChannel ads1258details::chan_se10
	#define P5VAChannel ads1258details::chan_se11
	#define LuxRadsChannel ads1258details::chan_se12
	#define N18VChannel ads1258details::chan_se13
	#define N20VChannel ads1258details::chan_se14
	#define P125VChannel ads1258details::chan_se15
	
	bool GetMonitor() const { return(Monitor); }
	void SetMonitor(bool monitor) { Monitor = monitor; }
	
	void Init();
	void Process();
	
	void Dump() { Adc.Dump(); }
	
	//Adc0
	double GetIHV() { return(IHVCalibrate.ReadCalibrated(IHV)); } // ads1258details::chan_se0
	double GetINV() { return(INVCalibrate.ReadCalibrated(INV)); } // ads1258details::chan_se1
	double GetI6V() { return(I6VCalibrate.ReadCalibrated(I6V)); } // ads1258details::chan_se2
	double GetI3VD() { return(I3VDCalibrate.ReadCalibrated(I3VD)); } // ads1258details::chan_se3
	double GetI2VD() { return(I2VDCalibrate.ReadCalibrated(I2VD)); } // ads1258details::chan_se4
	double GetI1V() { return(I1VCalibrate.ReadCalibrated(I1V)); } // ads1258details::chan_se5
	double GetStrainBP() { return(StrainBPCalibrate.ReadCalibrated(StrainBP)); } // ads1258details::chan_se6
	double GetStrainBM() { return(StrainBMCalibrate.ReadCalibrated(StrainBM)); } // ads1258details::chan_se7
	double GetStrainB() { return(StrainBCalibrate.ReadCalibrated(StrainB)); } // ads1258details::chan_diff3
	double GetStrainDP() { return(StrainDPCalibrate.ReadCalibrated(StrainDP)); } // ads1258details::chan_se8
	double GetStrainDM() { return(StrainDMCalibrate.ReadCalibrated(StrainDM)); } // ads1258details::chan_se9
	double GetStrainD() { return(StrainDCalibrate.ReadCalibrated(StrainD)); } // ads1258details::chan_diff4
	double GetStrainCM() { return(StrainCMCalibrate.ReadCalibrated(StrainCM)); } // ads1258details::chan_se10
	double GetStrainCP() { return(StrainCPCalibrate.ReadCalibrated(StrainCP)); } // ads1258details::chan_se11
	double GetStrainC() { return(StrainCCalibrate.ReadCalibrated(StrainC)); } // ads1258details::chan_diff5
	double GetStrainAM() { return(StrainAMCalibrate.ReadCalibrated(StrainAM)); } // ads1258details::chan_se12
	double GetStrainAP() { return(StrainAPCalibrate.ReadCalibrated(StrainAP)); } // ads1258details::chan_se13
	double GetStrainA() { return(StrainACalibrate.ReadCalibrated(StrainA)); } // ads1258details::chan_diff6
	double GetP5VD() { return(P5VDCalibrate.ReadCalibrated(P5VD)); } // ads1258details::chan_se14
	double GetI2VA() { return(I2VACalibrate.ReadCalibrated(I2VA)); } // ads1258details::chan_se15
	
	//Adc1
	double GetTemp() { return(TempCalibrate.ReadCalibrated(Temp)); } // ads1258details::chan_se0
	double GetP3V3D() { return(P3V3DCalibrate.ReadCalibrated(P3V3D)); } // ads1258details::chan_se1
	double GetP28V() { return(P28VCalibrate.ReadCalibrated(P28V)); } // ads1258details::chan_se2
	double GetP2V2() { return(P2V2Calibrate.ReadCalibrated(P2V2)); } // ads1258details::chan_se3
	double GetP2V5D() { return(P2V5DCalibrate.ReadCalibrated(P2V5D)); } // ads1258details::chan_se4
	double GetP1V2() { return(P1V2Calibrate.ReadCalibrated(P1V2)); } // ads1258details::chan_se5
	double GetP2V5A() { return(P2V5ACalibrate.ReadCalibrated(P2V5A)); } // ads1258details::chan_se6
	double GetP4V3() { return(P4V3Calibrate.ReadCalibrated(P4V3)); } // ads1258details::chan_se7
	double GetI3VA() { return(I3VACalibrate.ReadCalibrated(I3VA)); } // ads1258details::chan_se8
	double GetP3V3A() { return(P3V3ACalibrate.ReadCalibrated(P3V3A)); } // ads1258details::chan_se9
	double GetP6V() { return(P6VCalibrate.ReadCalibrated(P6V)); } // ads1258details::chan_se10
	double GetP5VA() { return(P5VACalibrate.ReadCalibrated(P5VA)); } // ads1258details::chan_se11
	double GetLuxRads() { return(LuxRadsCalibrate.ReadCalibrated(LuxRads)); } // ads1258details::chan_se12
	double GetN18V() { return(N18VCalibrate.ReadCalibrated(N18V)); } // ads1258details::chan_se13
	double GetN20V() { return(N20VCalibrate.ReadCalibrated(N20V)); } // ads1258details::chan_se14
	double GetP125V() { return(P125VCalibrate.ReadCalibrated(P125V)); } // ads1258details::chan_se15
	
	//Adc0
	void GetIHVRaw(int32_t& val) { val = (IHV); } // ads1258details::chan_se0
	void GetINVRaw(int32_t& val) { val = (INV); } // ads1258details::chan_se1
	void GetI6VRaw(int32_t& val) { val = (I6V); } // ads1258details::chan_se2
	void GetI3VDRaw(int32_t& val) { val = (I3VD); } // ads1258details::chan_se3
	void GetI2VDRaw(int32_t& val) { val = (I2VD); } // ads1258details::chan_se4
	void GetI1VRaw(int32_t& val) { val = (I1V); } // ads1258details::chan_se5
	void GetStrainBPRaw(int32_t& val) { val = (StrainBP); } // ads1258details::chan_se6
	void GetStrainBMRaw(int32_t& val) { val = (StrainBM); } // ads1258details::chan_se7
	void GetStrainBRaw(int32_t& val) { val = (StrainB); } // ads1258details::chan_diff3
	void GetStrainDPRaw(int32_t& val) { val = (StrainDP); } // ads1258details::chan_se8
	void GetStrainDMRaw(int32_t& val) { val = (StrainDM); } // ads1258details::chan_se9
	void GetStrainDRaw(int32_t& val) { val = (StrainD); } // ads1258details::chan_diff4
	void GetStrainCMRaw(int32_t& val) { val = (StrainCM); } // ads1258details::chan_se10
	void GetStrainCPRaw(int32_t& val) { val = (StrainCP); } // ads1258details::chan_se11
	void GetStrainCRaw(int32_t& val) { val = (StrainC); } // ads1258details::chan_diff5
	void GetStrainAMRaw(int32_t& val) { val = (StrainAM); } // ads1258details::chan_se12
	void GetStrainAPRaw(int32_t& val) { val = (StrainAP); } // ads1258details::chan_se13
	void GetStrainARaw(int32_t& val) { val = (StrainA); } // ads1258details::chan_diff6
	void GetP5VDRaw(int32_t& val) { val = (P5VD); } // ads1258details::chan_se14
	void GetI2VARaw(int32_t& val) { val = (I2VA); } // ads1258details::chan_se15
	
	//Adc1
	void GetTempRaw(int32_t& val) { val = (Temp); } // ads1258details::chan_se0
	void GetP3V3DRaw(int32_t& val) { val = (P3V3D); } // ads1258details::chan_se1
	void GetP28VRaw(int32_t& val) { val = (P28V); } // ads1258details::chan_se2
	void GetP2V2Raw(int32_t& val) { val = (P2V2); } // ads1258details::chan_se3
	void GetP2V5DRaw(int32_t& val) { val = (P2V5D); } // ads1258details::chan_se4
	void GetP1V2Raw(int32_t& val) { val = (P1V2); } // ads1258details::chan_se5
	void GetP2V5ARaw(int32_t& val) { val = (P2V5A); } // ads1258details::chan_se6
	void GetP4V3Raw(int32_t& val) { val = (P4V3); } // ads1258details::chan_se7
	void GetI3VARaw(int32_t& val) { val = (I3VA); } // ads1258details::chan_se8
	void GetP3V3ARaw(int32_t& val) { val = (P3V3A); } // ads1258details::chan_se9
	void GetP6VRaw(int32_t& val) { val = (P6V); } // ads1258details::chan_se10
	void GetP5VARaw(int32_t& val) { val = (P5VA); } // ads1258details::chan_se11
	void GetLuxRadsRaw(int32_t& val) { val = (LuxRads); } // ads1258details::chan_se12
	void GetN18VRaw(int32_t& val) { val = (N18V); } // ads1258details::chan_se13
	void GetN20VRaw(int32_t& val) { val = (N20V); } // ads1258details::chan_se14
	void GetP125VRaw(int32_t& val) { val = (P125V); } // ads1258details::chan_se15
	
	//This presumes some form of storage media; best to have science computers do this on orbit?
	void SaveCals(double* Buffer, size_t& BufferMaxInBufferUsedOut)
	{
		if ( (NULL == Buffer) || (BufferMaxInBufferUsedOut < (32 * sizeof(double))) )
		{ 
			formatf("\nMonitorAdc: Insufficient Buffer to save Calibrates! Given: %zu, required: %zu\n\n", BufferMaxInBufferUsedOut, (32 * sizeof(double)));
			return; 
		}
				
		//~ Buffer[0] = P1V2Calibrate.GetGain();
		//etc
		
		BufferMaxInBufferUsedOut = (32 * sizeof(double));
	}

	//This presumes some form of storage media; best to have science computers do this on orbit?
	void RestoreCals(const double* Buffer, size_t& BufferMaxInBufferUsedOut)	
	{
		if ( (NULL == Buffer) || ((BufferMaxInBufferUsedOut < (32 * sizeof(double)))) )
		{ 
			formatf("\nMonitorAdc: Insufficient Buffer to restore Calibrates! Given: %zu, required: %zu\n\n", BufferMaxInBufferUsedOut, (32 * sizeof(double)));
			return; 
		}
		
		//~ P1V2Calibrate.Calibrate(Buffer[0], Buffer[16]);
		//etc
		
		BufferMaxInBufferUsedOut = (32 * sizeof(double));
	}
};

//Command Parser interface:
extern const char ScanMonitorAdcCmdString[];
extern const char ScanMonitorAdcHelp[];
int8_t ScanMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

extern const char TestMonitorAdcCmdString[];
extern const char TestMonitorAdcHelp[];
int8_t TestMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

extern const char CalibrateMonitorAdcCmdString[];
extern const char CalibrateMonitorAdcHelp[];
int8_t CalibrateMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

//EOF
