//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
///
///           based on a framework Copyright (c) 2009 by Franks Development, LLC, used with permission
//

#include <time.h>
#include <ctype.h> //tolower

#include "Delay.h"

#include "Uarts.hpp"

#include "MonitorAdc.hpp"

CGraphFSMMonitorAdc MonitorAdc;

//Debug: Make all gains 1.0 so we get raw volts from the board...
//~ MonitorAdcCalibratedInput IHVCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se0
//~ MonitorAdcCalibratedInput INVCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se1
//~ MonitorAdcCalibratedInput I6VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se2
//~ MonitorAdcCalibratedInput I3VDCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se3
//~ MonitorAdcCalibratedInput I2VDCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se4
//~ MonitorAdcCalibratedInput I1VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se5
//~ MonitorAdcCalibratedInput StrainBPCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se6
//~ MonitorAdcCalibratedInput StrainBMCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se7
//~ MonitorAdcCalibratedInput StrainBCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_diff3
//~ MonitorAdcCalibratedInput StrainDPCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se8
//~ MonitorAdcCalibratedInput StrainDMCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se9
//~ MonitorAdcCalibratedInput StrainDCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_diff4
//~ MonitorAdcCalibratedInput StrainCMCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se10
//~ MonitorAdcCalibratedInput StrainCPCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se11
//~ MonitorAdcCalibratedInput StrainCCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_diff5
//~ MonitorAdcCalibratedInput StrainAMCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se12
//~ MonitorAdcCalibratedInput StrainAPCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se13
//~ MonitorAdcCalibratedInput StrainACalibrate(1.0, 0.0); //1:1 // ads1258details::chan_diff6
//~ MonitorAdcCalibratedInput P5VDCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se14
//~ MonitorAdcCalibratedInput I2VACalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se15
//~ MonitorAdcCalibratedInput TempCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se0
//~ MonitorAdcCalibratedInput P3V3DCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se1
//~ MonitorAdcCalibratedInput P28VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se2
//~ MonitorAdcCalibratedInput P2V2Calibrate(1.0, 0.0); //1:1 // ads1258details::chan_se3
//~ MonitorAdcCalibratedInput P2V5DCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se4
//~ MonitorAdcCalibratedInput P1V2Calibrate(1.0, 0.0); //1:1 // ads1258details::chan_se5
//~ MonitorAdcCalibratedInput P2V5ACalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se6
//~ MonitorAdcCalibratedInput P4V3Calibrate(1.0, 0.0); //1:1 // ads1258details::chan_se7
//~ MonitorAdcCalibratedInput I3VACalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se8
//~ MonitorAdcCalibratedInput P3V3ACalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se9
//~ MonitorAdcCalibratedInput P6VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se10
//~ MonitorAdcCalibratedInput P5VACalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se11
//~ MonitorAdcCalibratedInput LuxRadsCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se12
//~ MonitorAdcCalibratedInput N18VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se13
//~ MonitorAdcCalibratedInput N20VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se14
//~ MonitorAdcCalibratedInput P125VCalibrate(1.0, 0.0); //1:1 // ads1258details::chan_se15
//\Debug

//The real ideal cals:
MonitorAdcCalibratedInput IHVCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput INVCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput I6VCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput I3VDCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput I2VDCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput I1VCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainBPCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainBMCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainBCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainDPCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainDMCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainDCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainCMCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainCPCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainCCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainAMCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainAPCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput StrainACalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P5VDCalibrate(2.0, 0.0); //2:1
MonitorAdcCalibratedInput I2VACalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput TempCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P3V3DCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P28VCalibrate(7.667, 0.0); //11.5:1.5
MonitorAdcCalibratedInput P2V2Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P2V5DCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P1V2Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P2V5ACalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P4V3Calibrate(2.0, 0.0); //2:1
MonitorAdcCalibratedInput I3VACalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P3V3ACalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P6VCalibrate(2.0, 0.0); //2:1
MonitorAdcCalibratedInput P5VACalibrate(2.0, 0.0); //2:1
MonitorAdcCalibratedInput LuxRadsCalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput N18VCalibrate(7.667, 0.0); //11.5:1.5
MonitorAdcCalibratedInput N20VCalibrate(7.667, 0.0); //11.5:1.5
MonitorAdcCalibratedInput P125VCalibrate(101.0, 0.0); //101:1

void CGraphFSMMonitorAdc::Init()
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
		
		//Adc0 channels:
		Adc.AddScanChannel(IHVChannel);
		Adc.AddScanChannel(INVChannel);
		Adc.AddScanChannel(I6VChannel);
		Adc.AddScanChannel(I3VDChannel);
		Adc.AddScanChannel(I2VDChannel);
		Adc.AddScanChannel(I1VChannel);
		Adc.AddScanChannel(StrainBPChannel);
		Adc.AddScanChannel(StrainBMChannel);
		Adc.AddScanChannel(StrainBChannel);
		Adc.AddScanChannel(StrainDPChannel);
		Adc.AddScanChannel(StrainDMChannel);
		Adc.AddScanChannel(StrainDChannel);
		Adc.AddScanChannel(StrainCMChannel);
		Adc.AddScanChannel(StrainCPChannel);
		Adc.AddScanChannel(StrainCChannel);
		Adc.AddScanChannel(StrainAMChannel);
		Adc.AddScanChannel(StrainAPChannel);
		Adc.AddScanChannel(StrainAChannel);
		Adc.AddScanChannel(P5VDChannel);
		Adc.AddScanChannel(I2VAChannel);

		//Adc1 channels:
		Adc.AddScanChannel(TempChannel);
		Adc.AddScanChannel(P3V3DChannel);
		Adc.AddScanChannel(P28VChannel);
		Adc.AddScanChannel(P2V2Channel);
		Adc.AddScanChannel(P2V5DChannel);
		Adc.AddScanChannel(P1V2Channel);
		Adc.AddScanChannel(P2V5AChannel);
		Adc.AddScanChannel(P4V3Channel);
		Adc.AddScanChannel(I3VAChannel);
		Adc.AddScanChannel(P3V3AChannel);
		Adc.AddScanChannel(P6VChannel);
		Adc.AddScanChannel(P5VAChannel);
		Adc.AddScanChannel(LuxRadsChannel);
		Adc.AddScanChannel(N18VChannel);
		Adc.AddScanChannel(N20VChannel);
		Adc.AddScanChannel(P125VChannel);
		
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
};
	
void CGraphFSMMonitorAdc::Process()
{
	if (AdcFound)
	{
		//~ we don't have anything connected to gpios but might in the future, and dm does if this code gets cut&pasted: GpioInputs = Adc.ReadRegister(ads1258details::register_gpiod);
		
		ads1258details::ads1258sample sample0;
		ads1258details::ads1258sample sample1;
		
		for(size_t CurrentChan = 0; CurrentChan < ads1258details::ads1258numchannels; CurrentChan++)
		{
			ProcessAllUarts();
			
			Adc.AutoScan();
		
			if (Adc.IsScanChannel(CurrentChan))
			{
				ProcessAllUarts();
			
				Adc.GetLastSample(CurrentChan, sample0, sample1);
				
				ProcessAllUarts();
								
				if ( (sample0.status.isbrownout) || (sample0.status.isclipped) || (sample1.status.isbrownout) || (sample1.status.isclipped) )
				{ 
					if (Monitor) { ::formatf("\nMonitorAdc: bad status: Adc0: ch %u: 0x%.2X, Adc1: ch %u: 0x%.2X\n", sample0.status.channel, sample0.status.all, sample1.status.channel, sample1.status.all); }
				}					
				else
				{
					if ( (sample0.status.isnew) || (sample1.status.isnew) )
					{
						if (Monitor) { ::formatf("\nMonitorAdc: Adc0: ch %u reads: %lf Volts [%lu lsb's]; Adc1: ch %u reads: %lf Volts [%lu lsb's]\n", sample0.status.channel, Adc.CountsToVolts(sample0.sample), sample0.sample, sample1.status.channel, Adc.CountsToVolts(sample1.sample), sample1.sample); }

						switch(sample0.status.channel)
						{
							//Adc0 channels:
							case IHVChannel : { IHV = (sample0.sample); break; } 
							case INVChannel : { INV = (sample0.sample); break; } 
							case I6VChannel : { I6V = (sample0.sample); break; } 
							case I3VDChannel : { I3VD = (sample0.sample); break; } 
							case I2VDChannel : { I2VD = (sample0.sample); break; } 
							case I1VChannel : { I1V = (sample0.sample); break; } 
							case StrainBPChannel : { StrainBP = (sample0.sample); break; } 
							case StrainBMChannel : { StrainBM = (sample0.sample); break; } 
							case StrainBChannel : { StrainB = (sample0.sample); break; } 
							case StrainDPChannel : { StrainDP = (sample0.sample); break; } 
							case StrainDMChannel : { StrainDM = (sample0.sample); break; } 
							case StrainDChannel : { StrainD = (sample0.sample); break; } 
							case StrainCMChannel : { StrainCM = (sample0.sample); break; } 
							case StrainCPChannel : { StrainCP = (sample0.sample); break; } 
							case StrainCChannel : { StrainC = (sample0.sample); break; } 
							case StrainAMChannel : { StrainAM = (sample0.sample); break; } 
							case StrainAPChannel : { StrainAP = (sample0.sample); break; } 
							case StrainAChannel : { StrainA = (sample0.sample); break; } 
							case P5VDChannel : { P5VD = (sample0.sample); break; } 
							case I2VAChannel : { I2VA = (sample0.sample); break; } 
							default: { break; } //do nothing; we can scan all 16 channels and discard the unused ones.
						}
						
						switch(sample1.status.channel)
						{
							//Adc1 channels:
							case TempChannel : { Temp = (sample1.sample); break; } 
							case P3V3DChannel : { P3V3D = (sample1.sample); break; } 
							case P28VChannel : { P28V = (sample1.sample); break; } 
							case P2V2Channel : { P2V2 = (sample1.sample); break; } 
							case P2V5DChannel : { P2V5D = (sample1.sample); break; } 
							case P1V2Channel : { P1V2 = (sample1.sample); break; } 
							case P2V5AChannel : { P2V5A = (sample1.sample); break; } 
							case P4V3Channel : { P4V3 = (sample1.sample); break; } 
							case I3VAChannel : { I3VA = (sample1.sample); break; } 
							case P3V3AChannel : { P3V3A = (sample1.sample); break; } 
							case P6VChannel : { P6V = (sample1.sample); break; } 
							case P5VAChannel : { P5VA = (sample1.sample); break; } 
							case LuxRadsChannel : { LuxRads = (sample1.sample); break; } 
							case N18VChannel : { N18V = (sample1.sample); break; } 
							case N20VChannel : { N20V = (sample1.sample); break; } 
							case P125VChannel : { P125V = (sample1.sample); break; } 
							default: { break; } //do nothing; we can scan all 16 channels and discard the unused ones.
						}
					}
					else
					{
						if (Monitor) { ::formatf("\nMonitorAdc: ch %u no new sample this scan.\n", sample0.status.channel); }
					}						
				}
			}
		}
	}
};
	
const char ScanMonitorAdcCmdString[] = "SCANMONITORADC";
const char ScanMonitorAdcHelp[] = "\"ScanMonitorAdc\"; Show current input voltages...";
int8_t ScanMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
    formatf("\n\nScanMonitorAdc Command: Values with corrected units follow:\n");
	
	formatf("IHV: %3.6lf V\n", MonitorAdc.GetIHV());
	formatf("INV: %3.6lf V\n", MonitorAdc.GetINV());
	formatf("I6V: %3.6lf V\n", MonitorAdc.GetI6V());
	formatf("I3VD: %3.6lf V\n", MonitorAdc.GetI3VD());
	formatf("I2VD: %3.6lf V\n", MonitorAdc.GetI2VD());
	formatf("I1V: %3.6lf V\n", MonitorAdc.GetI1V());
	formatf("StrainBP: %3.6lf V\n", MonitorAdc.GetStrainBP());
	formatf("StrainBM: %3.6lf V\n", MonitorAdc.GetStrainBM());
	formatf("StrainB: %3.6lf V\n", MonitorAdc.GetStrainB());
	formatf("StrainDP: %3.6lf V\n", MonitorAdc.GetStrainDP());
	formatf("StrainDM: %3.6lf V\n", MonitorAdc.GetStrainDM());
	formatf("StrainD: %3.6lf V\n", MonitorAdc.GetStrainD());
	formatf("StrainCM: %3.6lf V\n", MonitorAdc.GetStrainCM());
	formatf("StrainCP: %3.6lf V\n", MonitorAdc.GetStrainCP());
	formatf("StrainC: %3.6lf V\n", MonitorAdc.GetStrainC());
	formatf("StrainAM: %3.6lf V\n", MonitorAdc.GetStrainAM());
	formatf("StrainAP: %3.6lf V\n", MonitorAdc.GetStrainAP());
	formatf("StrainA: %3.6lf V\n", MonitorAdc.GetStrainA());
	formatf("P5VD: %3.6lf V\n", MonitorAdc.GetP5VD());
	formatf("I2VA: %3.6lf V\n", MonitorAdc.GetI2VA());
	formatf("Temp: %3.6lf V\n", MonitorAdc.GetTemp());
	formatf("P3V3D: %3.6lf V\n", MonitorAdc.GetP3V3D());
	formatf("P28V: %3.6lf V\n", MonitorAdc.GetP28V());
	formatf("P2V2: %3.6lf V\n", MonitorAdc.GetP2V2());
	formatf("P2V5D: %3.6lf V\n", MonitorAdc.GetP2V5D());
	formatf("P1V2: %3.6lf V\n", MonitorAdc.GetP1V2());
	formatf("P2V5A: %3.6lf V\n", MonitorAdc.GetP2V5A());
	formatf("P4V3: %3.6lf V\n", MonitorAdc.GetP4V3());
	formatf("I3VA: %3.6lf V\n", MonitorAdc.GetI3VA());
	formatf("P3V3A: %3.6lf V\n", MonitorAdc.GetP3V3A());
	formatf("P6V: %3.6lf V\n", MonitorAdc.GetP6V());
	formatf("P5VA: %3.6lf V\n", MonitorAdc.GetP5VA());
	formatf("LuxRads: %3.6lf V\n", MonitorAdc.GetLuxRads());
	formatf("N18V: %3.6lf V\n", MonitorAdc.GetN18V());
	formatf("N20V: %3.6lf V\n", MonitorAdc.GetN20V());
	formatf("P125V: %3.6lf V\n", MonitorAdc.GetP125V());
	
    formatf("\nScanMonitorAdc Command: Complete.\n\n");
    return(strlen(Params));
}

const char TestMonitorAdcCmdString[] = "TESTMONITORADC";
const char TestMonitorAdcHelp[] = "\"TestMonitorAdc\"; Show raw A/D counts...";
int8_t TestMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	//~ size_t cycle = 0;
	//~ int key = 1;
	
	{
		//~ cycle++;
		
		MonitorAdc.Init();
		MonitorAdc.Dump();
	
		formatf("\n\nTestMonitorAdc Command: Serial: Reading A/D's (raw values):\n");
		
		int32_t Sample;
			
		MonitorAdc.GetIHVRaw(Sample); formatf("\nIHV: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetINVRaw(Sample); formatf("\nINV: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetI6VRaw(Sample); formatf("\nI6V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetI3VDRaw(Sample); formatf("\nI3VD: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetI2VDRaw(Sample); formatf("\nI2VD: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetI1VRaw(Sample); formatf("\nI1V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainBPRaw(Sample); formatf("\nStrainBP: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainBMRaw(Sample); formatf("\nStrainBM: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainBRaw(Sample); formatf("\nStrainB: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainDPRaw(Sample); formatf("\nStrainDP: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainDMRaw(Sample); formatf("\nStrainDM: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainDRaw(Sample); formatf("\nStrainD: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainCMRaw(Sample); formatf("\nStrainCM: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainCPRaw(Sample); formatf("\nStrainCP: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainCRaw(Sample); formatf("\nStrainC: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainAMRaw(Sample); formatf("\nStrainAM: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainAPRaw(Sample); formatf("\nStrainAP: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetStrainARaw(Sample); formatf("\nStrainA: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP5VDRaw(Sample); formatf("\nP5VD: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetI2VARaw(Sample); formatf("\nI2VA: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);

		MonitorAdc.GetTempRaw(Sample); formatf("\nTemp: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP3V3DRaw(Sample); formatf("\nP3V3D: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP28VRaw(Sample); formatf("\nP28V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP2V2Raw(Sample); formatf("\nP2V2: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP2V5DRaw(Sample); formatf("\nP2V5D: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP1V2Raw(Sample); formatf("\nP1V2: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP2V5ARaw(Sample); formatf("\nP2V5A: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP4V3Raw(Sample); formatf("\nP4V3: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetI3VARaw(Sample); formatf("\nI3VA: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP3V3ARaw(Sample); formatf("\nP3V3A: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP6VRaw(Sample); formatf("\nP6V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP5VARaw(Sample); formatf("\nP5VA: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetLuxRadsRaw(Sample); formatf("\nLuxRads: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetN18VRaw(Sample); formatf("\nN18V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetN20VRaw(Sample); formatf("\nN20V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP125VRaw(Sample); formatf("\nP125V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);

		//~ //Read raw from fpga:
		//~ for(size_t i = 0; i < 32; i++)
		//~ {
			//~ MonitorAdc.SetAdcReadChannel(i);
			//~ MonitorAdc.GetAdcSample(Sample);
			//~ formatf("\nCh%2u : ", i);
			//~ Sample.formatf();
			//~ double Volts = ((double)(0-(int32_t)Sample.Sample) * (double)8.192) / (1.0 * ((double)lt244xdetails::CountPosVRef - (double)lt244xdetails::CountNegVRef));
			//~ formatf("; %lfV.", Volts);
			
		//~ }
	}
	
    formatf("\nTestMonitorAdc Command: Complete.\n\n");
    return(strlen(Params));
}

const char CalibrateMonitorAdcCmdString[] = "CALIBRATEMONITORADC";
const char CalibrateMonitorAdcHelp[] = "\"CalibrateMonitorAdc <readout>,<gain>(optional),<offset>(optional)\"; Calibrate (or query) the given readout";
int8_t CalibrateMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	bool Query = true;
	
	char* InputName = strtok(const_cast<char*>(Params)," ,\t\r\n");
	char* Gn = strtok((char*)NULL," ,\t\r\n");
	char* Of = strtok((char*)NULL," ,\t\r\n");
	double Gain = 1.0;
	double Offset = 0.0;
	
	if (NULL == InputName)
	{
		formatf("\nMonitorAdcCalibrate: Invalid parameters; must give at least name of input calibration to query!\n\n");
		return(strlen(Params));
	}
	
	for (size_t i = 0; i < ParamsLen; i++)
	{
		if ('\0' == InputName[i]) { break; }
		InputName[i] = toupper(InputName[i]); //(1 to skip first whitespace)
	}
	
	if (NULL != Gn)
	{
		Query = false;
		sscanf(Gn, "%le", &Gain);
	}
	
	if (NULL != Of)
	{
		Query = false;
		sscanf(Of, "%le", &Offset);
	}
	
	if (0 == strncmp(InputName, "DEFAULTS", 8))
	{	
		P1V2Calibrate.Calibrate(1.0, 0.0);
		//etc......
		formatf("\nMonitorAdcCalibrate: All calibrates set to defaults!\n\n");
		return(strlen(Params));
	}

	MonitorAdcCalibratedInput* CalibrateMe = NULL;
	
	if (0 == strncmp(InputName, "P1V2", 8)) { CalibrateMe = &P1V2Calibrate; } 
	//etc......

	if (NULL != CalibrateMe)
	{
		if (!Query)
		{
			CalibrateMe->Calibrate(Gain, Offset);
			formatf("\nMonitorAdcCalibrate: Set Gain: %le (\"%s\"), Set Offset: %le (\"%s\")\n", Gain, Gn, Offset, Of);
		}
		
		formatf("\nMonitorAdcCalibrate: Gain: %le, Offset: %le\n", CalibrateMe->GetGain(), CalibrateMe->GetOffset());
	}
	else
	{
		formatf("\nMonitorAdcCalibrate: Unable to locate input matching \"%s\"!\n", InputName);
	}
	
	formatf("\nMonitorAdcCalibrate: Complete.\n\n");
	
	return(strlen(Params));
}

//EOF
