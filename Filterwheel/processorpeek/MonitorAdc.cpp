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

#include "MonitorAdc.hpp"

CGraphFWMonitorAdc MonitorAdc;

MonitorAdcCalibratedInput P1V2Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P2V2Calibrate(2.0, 0.0); //1:2
MonitorAdcCalibratedInput P28VCalibrate(16.0, 0.0); //1:16
MonitorAdcCalibratedInput P2V5Calibrate(2.0, 0.0); //1:2
MonitorAdcCalibratedInput P3V3DCalibrate(2.0, 0.0); //1:2
MonitorAdcCalibratedInput P6VCalibrate(4.922, 0.0); //2.55:12.55
MonitorAdcCalibratedInput P5VCalibrate(4.922, 0.0); //2.55:12.55
MonitorAdcCalibratedInput P4V3Calibrate(3.0, 0.0); //1:3
MonitorAdcCalibratedInput P2I2Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P4I3Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput P6ICalibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput Aux0Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput Aux1Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput Aux2Calibrate(1.0, 0.0); //1:1
MonitorAdcCalibratedInput AmbientLightCalibrate(1.0, 0.0); //1:1 301-ohm
MonitorAdcCalibratedInput TemperatureCalibrate(1.0, 0.0); //not actually connected on prototype pcb
//~ //Debug: Make all gains 1.0 so we get raw volts from the board...
//~ MonitorAdcCalibratedInput P1V2Calibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput P2V2Calibrate(1.0, 0.0); //1:2
//~ MonitorAdcCalibratedInput P28VCalibrate(1.0, 0.0); //1:16
//~ MonitorAdcCalibratedInput P2V5Calibrate(1.0, 0.0); //1:2
//~ MonitorAdcCalibratedInput P6VCalibrate(1.0, 0.0); //1:12.55
//~ MonitorAdcCalibratedInput P5VCalibrate(1.0, 0.0); //1:12.55
//~ MonitorAdcCalibratedInput P3V3DCalibrate(1.0, 0.0); //1:2
//~ MonitorAdcCalibratedInput P4V3Calibrate(1.0, 0.0); //1:3
//~ MonitorAdcCalibratedInput P2I2Calibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput P4I3Calibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput P6ICalibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput Aux0Calibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput Aux1Calibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput Aux2Calibrate(1.0, 0.0); //1:1
//~ MonitorAdcCalibratedInput AmbientLightCalibrate(1.0, 0.0); //1:1 301-ohm
//~ MonitorAdcCalibratedInput TemperatureCalibrate(1.0, 0.0); //not actually connected on prototype pcb
//~ //\Debug

const char ScanMonitorAdcCmdString[] = "SCANMONITORADC";
const char ScanMonitorAdcHelp[] = "\"ScanMonitorAdc\"; Show current input voltages...";
int8_t ScanMonitorAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
    formatf("\n\nScanMonitorAdc Command: Values with corrected units follow:\n");
	
	formatf("P1V2: %3.6lf V\n", MonitorAdc.GetP1V2());
	formatf("P2V2: %3.6lf V\n", MonitorAdc.GetP2V2());
	formatf("P28V: %3.6lf V\n", MonitorAdc.GetP28V());
	formatf("P2V5: %3.6lf V\n", MonitorAdc.GetP2V5());
	formatf("P6V: %3.6lf V\n", MonitorAdc.GetP6V());
	formatf("P5V: %3.6lf V\n", MonitorAdc.GetP5V());
	formatf("P3V3D: %3.6lf V\n", MonitorAdc.GetP3V3D());
	formatf("P4V3: %3.6lf V\n", MonitorAdc.GetP4V3());
	formatf("P2I2: %3.6lf V\n", MonitorAdc.GetP2I2());
	formatf("P4I3: %3.6lf V\n", MonitorAdc.GetP4I3());
	formatf("P6I: %3.6lf V\n", MonitorAdc.GetP6I());
	formatf("Aux0: %3.6lf V\n", MonitorAdc.GetAux0());
	formatf("Aux1: %3.6lf V\n", MonitorAdc.GetAux1());
	formatf("Aux2: %3.6lf V\n", MonitorAdc.GetAux2());
	formatf("AmbientLight: %3.6lf V\n", MonitorAdc.GetAmbientLight());
	formatf("Temperature: %3.6lf V\n", MonitorAdc.GetTemperature());
	
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
	
		formatf("\n\nTestMonitorAdc Command: Serial: Reading A/D's (raw values):\n");
		
		int32_t Sample;
		 
		MonitorAdc.GetP1V2Raw(Sample); formatf("\nP1V2: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP2V2Raw(Sample); formatf("\nP2V2: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP28VRaw(Sample); formatf("\nP28V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP2V5Raw(Sample); formatf("\nP2V5: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP6VRaw(Sample); formatf("\nP6V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP5VRaw(Sample); formatf("\nP5V: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP3V3DRaw(Sample); formatf("\nP3V3D: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP4V3Raw(Sample); formatf("\nP4V3: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP2I2Raw(Sample); formatf("\nP2I2: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP4I3Raw(Sample); formatf("\nP4I3: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetP6IRaw(Sample); formatf("\nP6I: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetAux0Raw(Sample); formatf("\nAux0: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetAux1Raw(Sample); formatf("\nAux1: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetAux2Raw(Sample); formatf("\nAux2: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetAmbientLightRaw(Sample); formatf("\nAmbientLight: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
		MonitorAdc.GetTemperatureRaw(Sample); formatf("\nTemperature: %+ld, 0x%.8lX", (signed long)Sample, (unsigned long)Sample);
	
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
	char* Gn = strtok((char*)nullptr," ,\t\r\n");
	char* Of = strtok((char*)nullptr," ,\t\r\n");
	double Gain = 1.0;
	double Offset = 0.0;
	
	if (nullptr == InputName)
	{
		formatf("\nMonitorAdcCalibrate: Invalid parameters; must give at least name of input calibration to query!\n\n");
		return(strlen(Params));
	}
	
	for (size_t i = 0; i < ParamsLen; i++)
	{
		if ('\0' == InputName[i]) { break; }
		InputName[i] = toupper(InputName[i]); //(1 to skip first whitespace)
	}
	
	if (nullptr != Gn)
	{
		Query = false;
		sscanf(Gn, "%le", &Gain);
	}
	
	if (nullptr != Of)
	{
		Query = false;
		sscanf(Of, "%le", &Offset);
	}
	
	if (0 == strncmp(InputName, "DEFAULTS", 8))
	{	
		P1V2Calibrate.Calibrate(1.0, 0.0);
		P2V2Calibrate.Calibrate(2.0, 0.0);
		P28VCalibrate.Calibrate(16.0, 0.0);
		P2V5Calibrate.Calibrate(2.0, 0.0);
		P6VCalibrate.Calibrate(4.922, 0.0);
		P5VCalibrate.Calibrate(4.922, 0.0);
		P3V3DCalibrate.Calibrate(2.0, 0.0);
		P4V3Calibrate.Calibrate(3.0, 0.0);
		P2I2Calibrate.Calibrate(1.0, 0.0);
		P4I3Calibrate.Calibrate(1.0, 0.0);
		P6ICalibrate.Calibrate(1.0, 0.0);
		Aux0Calibrate.Calibrate(1.0, 0.0);
		Aux1Calibrate.Calibrate(1.0, 0.0);
		Aux2Calibrate.Calibrate(1.0, 0.0);
		AmbientLightCalibrate.Calibrate(1.0, 0.0);
		TemperatureCalibrate.Calibrate(1.0, 0.0);
		formatf("\nMonitorAdcCalibrate: All calibrates set to defaults!\n\n");
		return(strlen(Params));
	}

	MonitorAdcCalibratedInput* CalibrateMe = nullptr;
	
	if (0 == strncmp(InputName, "P1V2", 8)) { CalibrateMe = &P1V2Calibrate; } 
	if (0 == strncmp(InputName, "P2V2", 8)) { CalibrateMe = &P2V2Calibrate; } 
	if (0 == strncmp(InputName, "P28V", 8)) { CalibrateMe = &P28VCalibrate; } 
	if (0 == strncmp(InputName, "P2V5", 8)) { CalibrateMe = &P2V5Calibrate; } 
	if (0 == strncmp(InputName, "P6V", 8)) { CalibrateMe = &P6VCalibrate; } 
	if (0 == strncmp(InputName, "P5V", 8)) { CalibrateMe = &P5VCalibrate; } 
	if (0 == strncmp(InputName, "P3V3D", 8)) { CalibrateMe = &P3V3DCalibrate; } 
	if (0 == strncmp(InputName, "P4V3", 8)) { CalibrateMe = &P4V3Calibrate; } 
	if (0 == strncmp(InputName, "P2I2", 8)) { CalibrateMe = &P2I2Calibrate; } 
	if (0 == strncmp(InputName, "P4I3", 8)) { CalibrateMe = &P4I3Calibrate; } 
	if (0 == strncmp(InputName, "P6I", 8)) { CalibrateMe = &P6ICalibrate; } 
	if (0 == strncmp(InputName, "AUX0", 8)) { CalibrateMe = &Aux0Calibrate; } 
	if (0 == strncmp(InputName, "AUX1", 8)) { CalibrateMe = &Aux1Calibrate; } 
	if (0 == strncmp(InputName, "AUX2", 8)) { CalibrateMe = &Aux2Calibrate; } 
	if (0 == strncmp(InputName, "AMBIENTLIGHT", 8)) { CalibrateMe = &AmbientLightCalibrate; } 
	if (0 == strncmp(InputName, "TEMPERATURE", 8)) { CalibrateMe = &TemperatureCalibrate; } 

	if (nullptr != CalibrateMe)
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
