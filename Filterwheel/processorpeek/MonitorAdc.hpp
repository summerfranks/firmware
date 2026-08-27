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
#define DEBUG_ADC
#include "adc/ads1258.h"
#include "temp/TempLM35.hpp"
#include "format/formatf.h"
#include "cgraph/CGraphFWHardwareInterface.hpp"
#include "Uarts.hpp"

//Note: if any offsets are not 4-byte aligned, the M3 processor WILL crash:
const size_t MonitorAdcFpgaAdcSampleAddr = 104;
const size_t MonitorAdcFpgaAdcChannelAddr = 112;
const size_t MonitorAdcFpgaSpiXferAddr = 348;
const size_t MonitorAdcSpiCommandStatusRegister = 352;

struct PinoutMonitorAdc
{
	PinoutMonitorAdc() { }
	virtual ~PinoutMonitorAdc() { }
	static uint8_t GetAdcReadChannel()								{ uint8_t val = *(((uint8_t*)FW)+MonitorAdcFpgaAdcChannelAddr); return(val); }
	static void SetAdcReadChannel(const uint8_t val) 					{ *(((uint8_t*)FW)+MonitorAdcFpgaAdcChannelAddr) = (uint8_t)val; }
	//~ old way to hopefully implement later: static void GetAdcSample(Ltc244xAccumulator& val) 				{ val = *((Ltc244xAccumulator*)(((uint8_t*)FW)+MonitorAdcFpgaAdcSampleAddr)); }		
	
	static const size_t spi_timeout = 100;
	
	static bool busy() { CGraphMonitorAdcCommandStatusRegister ACSR; ACSR.all = FW->MonitorAdcSpiCommandStatusRegister; return(0 == (ACSR.TransactionComplete) ); }
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
	
	static void enable(const bool en) { FW->MonitorAdcSpiCommandStatusRegister = (uint32_t)en; }
	
	static void transmit(const uint8_t val) 					
	{ 
		waitbusytimeout();
		FW->MonitorAdcSpiTransactionRegister = (uint32_t)val; 
	}
	
	static uint8_t receive(uint8_t val) 				
	{ 
		uint32_t out = 0;
		
		//Do the xfer
		waitbusytimeout();
		FW->MonitorAdcSpiTransactionRegister = (uint32_t)val; 
		
		//readback
		waitbusytimeout();
		out = FW->MonitorAdcSpiTransactionRegister; 
		
		return(out);
	}		
	
	static bool nDrdy() 				
	{ 
		CGraphMonitorAdcCommandStatusRegister ACSR; ACSR.all = FW->MonitorAdcSpiCommandStatusRegister; 
		return(0 == (ACSR.nDrdy) );
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

extern MonitorAdcCalibratedInput P1V2Calibrate;
extern MonitorAdcCalibratedInput P2V2Calibrate;
extern MonitorAdcCalibratedInput P28VCalibrate;
extern MonitorAdcCalibratedInput P2V5Calibrate;
extern MonitorAdcCalibratedInput P6VCalibrate;
extern MonitorAdcCalibratedInput P5VCalibrate;
extern MonitorAdcCalibratedInput P3V3DCalibrate;
extern MonitorAdcCalibratedInput P4V3Calibrate;
extern MonitorAdcCalibratedInput P2I2Calibrate;
extern MonitorAdcCalibratedInput P4I3Calibrate;
extern MonitorAdcCalibratedInput P6ICalibrate;
extern MonitorAdcCalibratedInput Aux0Calibrate;
extern MonitorAdcCalibratedInput Aux1Calibrate;
extern MonitorAdcCalibratedInput Aux2Calibrate;
extern MonitorAdcCalibratedInput AmbientLightCalibrate;
extern MonitorAdcCalibratedInput TemperatureCalibrate;

//~ template <class spi, class adcpinout, unsigned int spiclkdivider = 39>
struct CGraphFWMonitorAdc
{
	
private:
			
	//~ lt244x_accum<PinoutMonitorAdc> Adc;
	//~ ads1258<PinoutMonitorAdc> Adc;

	bool AdcFound;
	bool Monitor;
	
    //~ static const uint8_t GpioDirections = 0xEF; //0111:1111 - bit 7 is output
	static const uint8_t GpioDirections = 0x00; //All outputs (unused should be outputs according to datasheet)
    static const uint8_t StartPinMask = 0x80; //Gpio7

	int32_t P1V2; //chan_se1
	int32_t P2V2; //chan_se2
	int32_t P28V; //chan_se0
	int32_t P2V5; //chan_se7
	int32_t P6V; //chan_se10
	int32_t P5V; //chan_se11
	int32_t P3V3D; //chan_se6
	int32_t P4V3; //chan_se8
	int32_t P2I2; //chan_se3
	int32_t P4I3; //chan_se9
	int32_t P6I; //chan_se12
	int32_t Aux0; //chan_se14
	int32_t Aux1; //chan_se5
	int32_t Aux2; //chan_se4
	int32_t AmbientLight; //chan_se13
	int32_t Temperature; //chan_se15
	

public:
	
	CGraphFWMonitorAdc() :  AdcFound(false), Monitor(false),
							P1V2(0), P2V2(0), P28V(0), P2V5(0), P6V(0), P5V(0), P3V3D(0), P4V3(0), P2I2(0), P4I3(0), P6I(0), Aux0(0), Aux1(0), Aux2(0), AmbientLight(0), Temperature(0),
							Adc(4.096) //,
	{ }
	
	~CGraphFWMonitorAdc() { }
	
	ads1258<PinoutMonitorAdc> Adc;
	
	//~ static uint8_t GetAdcReadChannel()								{ uint8_t val = *(((uint8_t*)FW)+MonitorAdcFpgaAdcChannelAddr); return(val); }
	//~ static void SetAdcReadChannel(const uint8_t val) 					{ *(((uint8_t*)FW)+MonitorAdcFpgaAdcChannelAddr) = (uint8_t)val; }
	//~ static void GetAdcSample(Ltc244xAccumulator& val) 				{ val = *((Ltc244xAccumulator*)(((uint8_t*)FW)+MonitorAdcFpgaAdcSampleAddr)); }		
	
	//Adc channels:
	#define P1V2Channel ads1258details::chan_se1
	#define P2V2Channel ads1258details::chan_se2
	#define P28VChannel ads1258details::chan_se0
	#define P2V5Channel ads1258details::chan_se7
	#define P6VChannel ads1258details::chan_se10
	#define P5VChannel ads1258details::chan_se11
	#define P3V3DChannel ads1258details::chan_se6
	#define P4V3Channel ads1258details::chan_se8
	#define P2I2Channel ads1258details::chan_se3
	#define P4I3Channel ads1258details::chan_se9
	#define P6IChannel ads1258details::chan_se12
	#define Aux0Channel ads1258details::chan_se14
	#define Aux1Channel ads1258details::chan_se5
	#define Aux2Channel ads1258details::chan_se4
	#define AmbientLightChannel ads1258details::chan_se13
	#define TemperatureChannel ads1258details::chan_se15
	
	bool GetMonitor() const { return(Monitor); }
	void SetMonitor(bool monitor) { Monitor = monitor; }
	
	void Init()
	{
		for (uint8_t i = 0; i < 10; i++)
        {
            uint8_t AdcInit = Adc.Init(GpioDirections);
            if (Adc.InitOK == AdcInit)
            {
                AdcFound = true;
                break;
            }
            else
            {
                formatf("\nMonitorAdc: Error initializing Adc: %u [0x%.2X].\n", AdcInit, AdcInit);
            }
        }
        if (AdcFound)
        {
			Adc.ClearScanChannels();
			Adc.AddScanChannel(P1V2Channel);
			Adc.AddScanChannel(P2V2Channel);
			Adc.AddScanChannel(P28VChannel);
			Adc.AddScanChannel(P2V5Channel);
			Adc.AddScanChannel(P6VChannel);
			Adc.AddScanChannel(P5VChannel);
			Adc.AddScanChannel(P3V3DChannel);
			Adc.AddScanChannel(P4V3Channel);
			Adc.AddScanChannel(P2I2Channel);
			Adc.AddScanChannel(P4I3Channel);
			Adc.AddScanChannel(P6IChannel);
			Adc.AddScanChannel(Aux0Channel);
			Adc.AddScanChannel(Aux1Channel);
			Adc.AddScanChannel(Aux2Channel);
			Adc.AddScanChannel(AmbientLightChannel);
			Adc.AddScanChannel(TemperatureChannel);
			Adc.CommitScanChannels();
			Adc.StartChannelScan();
			//Take start pin high to initiate auto-scan
			{
				Adc.WriteRegister(ads1258details::register_gpiod, StartPinMask);
				//~ if (Monitor)
				{
					formatf("\nMonitorAdc: Starting A/D auto-scan; wrote 0x%.2X to gpio's, readback: 0x%.2X\n", StartPinMask, Adc.ReadRegister(ads1258details::register_gpiod));
					fflush(stdout);
				}
			}
		}
		else
        {
            formatf("\nMonitorAdc: No Adc found!\n");
        }
	}
	
	void Process()
    {
		if (AdcFound)
		{
			//~ we don't have anything connected to gpios but might in the future, and dm does if this code gets cut&pasted: GpioInputs = Adc.ReadRegister(ads1258details::register_gpiod);
			
			ads1258details::ads1258sample sample;
			
			for(size_t CurrentChan = 0; CurrentChan < ads1258details::ads1258numchannels; CurrentChan++)
			{
				ProcessAllUarts();
				
				Adc.AutoScan();
			
				if (Adc.IsScanChannel(CurrentChan))
				{
					ProcessAllUarts();
				
					Adc.GetLastSample(CurrentChan, sample);
					
					ProcessAllUarts();
									
					if ( (sample.status.isbrownout) || (sample.status.isclipped) )
					{ 
						if (Monitor) { ::formatf("\nMonitorAdc: ch %u bad status: 0x%.2X\n", sample.status.channel, sample.status.all); }
					}					
					else
					{
						if (sample.status.isnew)
						{
							if (Monitor) { ::formatf("\nMonitorAdc: ch %u reads: %lf Volts [%lu lsb's]\n", sample.status.channel, Adc.CountsToVolts(sample.sample), sample.sample); }

							switch(sample.status.channel)
							{
								case P1V2Channel : { P1V2 = (sample.sample); break; } 
								case P2V2Channel : { P2V2 = (sample.sample); break; } 
								case P28VChannel : { P28V = (sample.sample); break; } 
								case P2V5Channel : { P2V5 = (sample.sample); break; } 
								case P6VChannel : { P6V = (sample.sample); break; } 
								case P5VChannel : { P5V = (sample.sample); break; } 
								case P3V3DChannel : { P3V3D = (sample.sample); break; } 
								case P4V3Channel : { P4V3 = (sample.sample); break; } 
								case P2I2Channel : { P2I2 = (sample.sample); break; } 
								case P4I3Channel : { P4I3 = (sample.sample); break; } 
								case P6IChannel : { P6I = (sample.sample); break; } 
								case Aux0Channel : { Aux0 = (sample.sample); break; } 
								case Aux1Channel : { Aux1 = (sample.sample); break; } 
								case Aux2Channel : { Aux2 = (sample.sample); break; } 
								case AmbientLightChannel : { AmbientLight = (sample.sample); break; } 
								case TemperatureChannel : { Temperature = (sample.sample); break; } 
								
								default: { break; } //do nothing; we can scan all 16 channels and discard the unused ones.
							}
						}
						else
						{
							if (Monitor) { ::formatf("\nMonitorAdc: ch %u no new sample this scan.\n", sample.status.channel); }
						}						
					}
				}
			}
		}
	}
	
	double GetP1V2() { return(P1V2Calibrate.ReadCalibrated(P1V2)); }
	double GetP2V2() { return(P2V2Calibrate.ReadCalibrated(P2V2)); }
	double GetP28V() { return(P28VCalibrate.ReadCalibrated(P28V)); }
	double GetP2V5() { return(P2V5Calibrate.ReadCalibrated(P2V5)); }
	double GetP6V() { return(P6VCalibrate.ReadCalibrated(P6V)); }
	double GetP5V() { return(P5VCalibrate.ReadCalibrated(P5V)); }
	double GetP3V3D() { return(P3V3DCalibrate.ReadCalibrated(P3V3D)); }
	double GetP4V3() { return(P4V3Calibrate.ReadCalibrated(P4V3)); }
	double GetP2I2() { return(P2I2Calibrate.ReadCalibrated(P2I2)); }
	double GetP4I3() { return(P4I3Calibrate.ReadCalibrated(P4I3)); }
	double GetP6I() { return(P6ICalibrate.ReadCalibrated(P6I)); }
	double GetAux0() { return(Aux0Calibrate.ReadCalibrated(Aux0)); }
	double GetAux1() { return(Aux1Calibrate.ReadCalibrated(Aux1)); }
	double GetAux2() { return(Aux1Calibrate.ReadCalibrated(Aux2)); }
	double GetAmbientLight() { return(AmbientLightCalibrate.ReadCalibrated(AmbientLight)); }
	double GetTemperature() { return(TemperatureCalibrate.ReadCalibrated(Temperature)); }
	
	void GetP1V2Raw(int32_t& val) { val = (P1V2); }
	void GetP2V2Raw(int32_t& val) { val = (P2V2); }
	void GetP28VRaw(int32_t& val) { val = (P28V); }
	void GetP2V5Raw(int32_t& val) { val = (P2V5); }
	void GetP6VRaw(int32_t& val) { val = (P6V); }
	void GetP5VRaw(int32_t& val) { val = (P5V); }
	void GetP3V3DRaw(int32_t& val) { val = (P3V3D); }
	void GetP4V3Raw(int32_t& val) { val = (P4V3); }
	void GetP2I2Raw(int32_t& val) { val = (P2I2); }
	void GetP4I3Raw(int32_t& val) { val = (P4I3); }
	void GetP6IRaw(int32_t& val) { val = (P6I); }
	void GetAux0Raw(int32_t& val) { val = (Aux0); }
	void GetAux1Raw(int32_t& val) { val = (Aux1); }
	void GetAux2Raw(int32_t& val) { val = (Aux2); }
	void GetAmbientLightRaw(int32_t& val) { val = (AmbientLight); }
	void GetTemperatureRaw(int32_t& val) { val = (Temperature); }
	
	void SaveCals(double* const Buffer, size_t& BufferMaxInBufferUsedOut)
	{
		if ( (nullptr == Buffer) || (BufferMaxInBufferUsedOut < (32 * sizeof(double))) )
		{ 
			formatf("\nMonitorAdc: Insufficient Buffer to save Calibrates! Given: %zu, required: %zu\n\n", BufferMaxInBufferUsedOut, (32 * sizeof(double)));
			return; 
		}
				
		//~ Buffer[0] = P1V2Calibrate.GetGain();
		//~ Buffer[1] = P2V2Calibrate.GetGain();
		//~ Buffer[2] = P24VCalibrate.GetGain();
		//~ Buffer[3] = P2V5Calibrate.GetGain();
		//~ Buffer[4] = P3V3ACalibrate.GetGain();
		//~ Buffer[5] = P6VCalibrate.GetGain();
		//~ Buffer[6] = P5VCalibrate.GetGain();
		//~ Buffer[7] = P3V3DCalibrate.GetGain();
		//~ Buffer[8] = P4V3Calibrate.GetGain();
		//~ Buffer[9] = N5VCalibrate.GetGain();
		//~ Buffer[10] = N6VCalibrate.GetGain();
		//~ Buffer[11] = P150VCalibrate.GetGain();	
		//~ Buffer[12] = Aux0Calibrate.GetGain();
		//~ Buffer[13] = Aux1Calibrate.GetGain();
		//~ Buffer[14] = AmbientLightCalibrate.GetGain();
		//~ Buffer[15] = TemperatureCalibrate.GetGain();	
		
		//~ Buffer[16] = P1V2Calibrate.GetOffset();
		//~ Buffer[17] = P2V2Calibrate.GetOffset();
		//~ Buffer[18] = P24VCalibrate.GetOffset();
		//~ Buffer[19] = P2V5Calibrate.GetOffset();
		//~ Buffer[20] = P3V3ACalibrate.GetOffset();
		//~ Buffer[21] = P6VCalibrate.GetOffset();
		//~ Buffer[22] = P5VCalibrate.GetOffset();
		//~ Buffer[23] = P3V3DCalibrate.GetOffset();
		//~ Buffer[24] = P4V3Calibrate.GetOffset();
		//~ Buffer[25] = N5VCalibrate.GetOffset();
		//~ Buffer[26] = N6VCalibrate.GetOffset();
		//~ Buffer[27] = P150VCalibrate.GetOffset();	
		//~ Buffer[28] = Aux0Calibrate.GetOffset();
		//~ Buffer[29] = Aux1Calibrate.GetOffset();
		//~ Buffer[30] = AmbientLightCalibrate.GetOffset();
		//~ Buffer[31] = TemperatureCalibrate.GetOffset();	
		
		BufferMaxInBufferUsedOut = (32 * sizeof(double));
	}

	void RestoreCals(const double* Buffer, size_t& BufferMaxInBufferUsedOut)	
	{
		if ( (nullptr == Buffer) || ((BufferMaxInBufferUsedOut < (32 * sizeof(double)))) )
		{ 
			formatf("\nMonitorAdc: Insufficient Buffer to restore Calibrates! Given: %zu, required: %zu\n\n", BufferMaxInBufferUsedOut, (32 * sizeof(double)));
			return; 
		}
		
		//~ P1V2Calibrate.Calibrate(Buffer[0], Buffer[16]);
		//~ P2V2Calibrate.Calibrate(Buffer[1], Buffer[17]);
		//~ P24VCalibrate.Calibrate(Buffer[2], Buffer[18]);
		//~ P2V5Calibrate.Calibrate(Buffer[3], Buffer[19]);
		//~ P3V3ACalibrate.Calibrate(Buffer[4], Buffer[20]);
		//~ P6VCalibrate.Calibrate(Buffer[5], Buffer[21]);
		//~ P5VCalibrate.Calibrate(Buffer[6], Buffer[22]);
		//~ P3V3DCalibrate.Calibrate(Buffer[7], Buffer[23]);
		//~ P4V3Calibrate.Calibrate(Buffer[8], Buffer[24]);
		//~ N5VCalibrate.Calibrate(Buffer[9], Buffer[25]);
		//~ N6VCalibrate.Calibrate(Buffer[10], Buffer[26]);
		//~ P150VCalibrate.Calibrate(Buffer[11], Buffer[27]);	
		//~ Aux0Calibrate.Calibrate(Buffer[12], Buffer[28]);
		//~ Aux1Calibrate.Calibrate(Buffer[13], Buffer[29]);
		//~ AmbientLightCalibrate.Calibrate(Buffer[14], Buffer[30]);
		//~ TemperatureCalibrate.Calibrate(Buffer[15], Buffer[31]);	
		
		BufferMaxInBufferUsedOut = (32 * sizeof(double));
	}
};

extern CGraphFWMonitorAdc MonitorAdc;

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
