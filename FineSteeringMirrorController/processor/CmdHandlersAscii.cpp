//
///           Copyright (c) by Franks Development, LLC
//
// This software is copyrighted by and is the sole property of Franks
// Development, LLC. All rights, title, ownership, or other interests
// in the software remain the property of Franks Development, LLC. This
// software may only be used in accordance with the corresponding
// license agreement.  Any unauthorized use, duplication, transmission,
// distribution, or disclosure of this software is expressly forbidden.
//
// This Copyright notice may not be removed or modified without prior
// written consent of Franks Development, LLC.
//
// Franks Development, LLC. reserves the right to modify this software
// without notice.
//
// Franks Development, LLC            support@franks-development.com
// 500 N. Bahamas Dr. #101           http://www.franks-development.com
// Tucson, AZ 85710
// USA
//
/// \file
/// $Source: /raincloud/src/clients/UACGraph/Zeus/Zeus3/firmware/arm/main/CmdHandlersConfig.cpp,v $
/// $Revision: 1.7 $
/// $Date: 2010/06/08 23:51:10 $
/// $Author: summer $

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <inttypes.h>
//offsetof:
#include <cstddef>
#include <unordered_map>
using namespace std;

//~ #include <mcheck.h>
//~ #include "dbg/memwatch.h"

#include "uart/BinaryUart.hpp"

#include "uart/uart_pinout_fpga.hpp"

#include "cgraph/CGraphPacket.hpp"

#include "cgraph/CGraphFSMHardwareInterface.hpp"
extern CGraphFSMHardwareInterface* volatile FSM;	

#include "MonitorAdc.hpp"
extern CGraphFSMMonitorAdc MonitorAdc;

#include "MainBuildNum"

extern uart_pinout_fpga FPGAUartPinout0;
extern uart_pinout_fpga FPGAUartPinout1;
extern uart_pinout_fpga FPGAUartPinout2;
extern uart_pinout_fpga FPGAUartPinout3;
extern uart_pinout_fpga FPGAUartPinoutUsb;

//~ extern BinaryUart FpgaUartParser3;
//~ extern BinaryUart FpgaUartParser2;
//~ extern BinaryUart FpgaUartParser1;
//~ extern BinaryUart FpgaUartParser0; //using this one for ascii rn...

extern bool BISTModeEnabled;

char Buffer[4096];

int8_t VersionCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (NULL != FSM)
	{
		formatf("\n\nVersion: Serial Number: %.8lX, Global Revision: %s; build number: %u on: %s; fpga build: %lu.\n", FSM->DeviceSerialNumber, GITVERSION, BuildNum, BuildTimeStr, FSM->FpgaFirmwareBuildNumber);
	}
	else
	{
		formatf("\n\nVersion: Global Revision: %s; build number: %u on: %s.\n", GITVERSION, BuildNum, BuildTimeStr);
	}
	
    return(strlen(Params));
}

int8_t ReadFpgaCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	uint8_t FpgaRdBuf;

	//Convert parameter to an integer
    size_t addr = 0;
	int8_t numfound = sscanf(Params, "%zX", &addr);
    if (numfound < 1)
    {
		formatf("\nReadFpgaCommand: ");
		//~ for (addr = 0; addr <= 64; addr++)
		for (addr = 0; addr <= 128; addr++)
		{
			FpgaRdBuf = *(((uint8_t*)FSM)+addr);
			formatf("\n0x%.2zX: 0x%.2X ", addr, FpgaRdBuf);
			formatf("[%u]", FpgaRdBuf);
			//~ formatf(" ('%c')", FpgaRdBuf);
		}	
		formatf("\n\n");
    }
	else
	{
		FpgaRdBuf = *(((uint8_t*)FSM)+addr);
		formatf("\nReadFpgaCommand: ");
		//~ formatf("\n%zu: 0x%.2X ", addr, FpgaRdBuf);
		formatf("\n0x%.2zX: 0x%.2X ", addr, FpgaRdBuf);
		formatf("[%u]", FpgaRdBuf);
		formatf(" ('%c')\n\n", FpgaRdBuf);
	}
	
	return(ParamsLen);
}

int8_t WriteFpgaCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	//Convert parameter to an integer
	size_t addr = 0;
    unsigned long val = 0;
    int8_t numfound = sscanf(Params, "%zX %lu", &addr, &val);
    if (numfound < 2)
    {
		formatf("\nWriteFpgaCommand: need 2 numeric parameters (address and value), got \"%s\" (%d params).\n", Params, numfound);
        return(-1);
    }

	//Write data to fpga:
	*(((uint8_t*)FSM)+addr) = (uint8_t)val;

	formatf("\nWriteFpgaCommand: Wrote %lu to ", val);
	formatf("0x%.4zX.\n", addr);
	
	return(ParamsLen);
}


int8_t FSMDacsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
    unsigned long A = 0, B = 0, C = 0, D = 0;	
	if (NULL == FSM)
	{
		formatf("\n\nFSMDacs: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lx,%lx,%lx,%lx", &A, &B, &C, &D);
    if (numfound >= 4)
    {
		FSM->DacASetpoint = A;
		FSM->DacBSetpoint = B;
		FSM->DacCSetpoint = C;
		FSM->DacDSetpoint = D;
		formatf("\n\nFSMDacs: set to: %lx, %lx, %lx, %lx.\n", A, B, C, D);
		return(ParamsLen);
    }
	if (numfound >= 1)
    {
		FSM->DacASetpoint = A;
		FSM->DacBSetpoint = A;
		//~ FSM->DacBSetpoint = 0x006FFFFFUL; //Sometimes this is 100V
		//~ FSM->DacBSetpoint = 0x00CFFFFFUL; //Aaaaaand, sometimes this is 100V
		FSM->DacCSetpoint = A;
		FSM->DacDSetpoint = A;
		formatf("\n\nFSMDacs: set to: %lx, %lx, %lx, %lx.\n", A, A, A, A);
		return(ParamsLen);
    }

	A = FSM->DacASetpoint;
	B = FSM->DacBSetpoint;
	C = FSM->DacCSetpoint;
	D = FSM->DacDSetpoint;
	formatf("\n\nFSMDacs: current value: %lx, %lx, %lx, %lx.\n", A, B, C, D);
	
	//Show current A/D values:
	//~ {
		//~ //Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
		//~ *((uint8_t*)&(FSM->LatchAdcs)) = 1;
		
		//~ AdcAccumulator Aa, Ba, Ca;
		//~ Aa = FSM->AdcAAccumulator;
		//~ Ba = FSM->AdcBAccumulator;
		//~ Ca = FSM->AdcCAccumulator;

		//~ double Av, Bv, Cv;
		//~ Av = (4.096 * ((Aa.Samples - 0) / Aa.NumAccums)) / 8388608.0;
		//~ Bv = (4.096 * ((Ba.Samples - 0) / Ba.NumAccums)) / 8388608.0;
		//~ Cv = (4.096 * ((Ca.Samples - 0) / Ca.NumAccums)) / 8388608.0;
		
			
		//~ //formatf("\n\nFSMAdcs: current values: 0x%016llx, 0x%016llx, 0x%016llx; %+lld(%u), %+lld(%u), %+lld(%u), %+1.3lf, %+1.3lf, %+1.3lf\n", A.all, B.all, C.all, A.Samples, A.NumAccums, B.Samples, B.NumAccums, C.Samples, C.NumAccums, (4.096 * (A.Samples / A.NumAccums)) / 8388608.0, (4.096 * (B.Samples / B.NumAccums)) / 8388608.0, (4.096 * (C.Samples / C.NumAccums)) / 8388608.0);
		//~ formatf("\nFSMDacs: Sensor A/D's: %+d(%u), %+d(%u), %+d(%u), %+1.3lf, %+1.3lf, %+1.3lf\n", Aa.Samples, Aa.NumAccums, Ba.Samples, Ba.NumAccums, Ca.Samples, Ca.NumAccums, Av, Bv, Cv);
	//~ }
	
	//~ formatf("\n\nFSMdaca: D/A registers at: %u, %u, %u.\n", offsetof(CGraphFSMHardwareInterface, DacASetpoint), offsetof(CGraphFSMHardwareInterface, DacBSetpoint), offsetof(CGraphFSMHardwareInterface, DacCSetpoint));
	
    return(ParamsLen);
}

int8_t VoltageCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	double VA = 0.0, VB = 0.0, VC = 0.0, VD = 0.0;	
	unsigned long A = 0, B = 0, C = 0, D = 0;	
	
	if (NULL == FSM)
	{
		formatf("\n\nVoltage: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lf,%lf,%lf,%lf", &VA, &VB, &VC, &VD);
	
	A = (VA * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
	B = (VB * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
	C = (VC * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
	D = (VD * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
	
    if (numfound >= 4)
    {
		FSM->DacASetpoint = A;
		FSM->DacBSetpoint = B;
		FSM->DacCSetpoint = C;
		FSM->DacDSetpoint = D;
		formatf("\n\nVoltage: set to: %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx).\n", VA, A, VB, B, VC, C, VD, D);
		return(ParamsLen);
    }
	if (numfound >= 1)
    {
		FSM->DacASetpoint = A;
		FSM->DacBSetpoint = A;
		//~ FSM->DacBSetpoint = 0x006FFFFFUL; //Sometimes this is 100V
		//~ FSM->DacBSetpoint = 0x00CFFFFFUL; //Aaaaaand, sometimes this is 100V
		FSM->DacCSetpoint = A;
		FSM->DacDSetpoint = A;
		formatf("\n\nVoltage: set to: %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx).\n", VA, A, VB, B, VC, C, VD, D);
		return(ParamsLen);
    }

	A = FSM->DacASetpoint;
	B = FSM->DacBSetpoint;
	C = FSM->DacCSetpoint;
	D = FSM->DacDSetpoint;
	
	VA = 4.096 * (double)(A) / ((double)(0x00FFFFFFUL) * 60.0);
	VB = 4.096 * (double)(B) / ((double)(0x00FFFFFFUL) * 60.0);
	VC = 4.096 * (double)(C) / ((double)(0x00FFFFFFUL) * 60.0);
	VD = 4.096 * (double)(D) / ((double)(0x00FFFFFFUL) * 60.0);
	
	formatf("\n\nVoltage: current values: %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx).\n", VA, A, VB, B, VC, C, VD, D);
	
	return(ParamsLen);	
}

int8_t FSMAdcsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	size_t cycle = 0;
	//~ int key = 0;

	if (NULL == FSM)
	{
		formatf("\n\nFSMAdcs: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//~ while(true)
	//~ {
		cycle++;
		
		//Show current A/D values:
		{
			//Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
			*((uint8_t*)&(FSM->LatchAdcs)) = cycle | 1;
			
			//~ AdcAccumulator A, B, C, D;
			//~ A = FSM->AdcAAccumulator;
			//~ B = FSM->AdcBAccumulator;
			//~ C = FSM->AdcCAccumulator;
			//~ D = FSM->AdcDAccumulator;

			AdcAccumulator A, B, C, D;
			A.Samples = FSM->AdcAAccumulator;
			A.SetHiWord(FSM->AdcAAccumulatorHiandNumAccums);
			B.Samples = FSM->AdcBAccumulator;
			B.SetHiWord(FSM->AdcBAccumulatorHiandNumAccums);
			C.Samples = FSM->AdcCAccumulator;	
			C.SetHiWord(FSM->AdcCAccumulatorHiandNumAccums);
			D.Samples = FSM->AdcDAccumulator;	
			D.SetHiWord(FSM->AdcDAccumulatorHiandNumAccums);
			
			double Av, Bv, Cv, Dv;
			Av = (4.096 * (double)A.Samples) / (8388608.0 * (double)A.NumAccums);
			Bv = (4.096 * (double)B.Samples) / (8388608.0 * (double)B.NumAccums);
			Cv = (4.096 * (double)C.Samples) / (8388608.0 * (double)C.NumAccums);
			Dv = (4.096 * (double)D.Samples) / (8388608.0 * (double)D.NumAccums);
			//~ Av = (4.096 * ((A.Samples - 0) / 1)) / 8388608.0;
			//~ Bv = (4.096 * ((B.Samples - 0) / 1)) / 8388608.0;
			//~ Cv = (4.096 * ((C.Samples - 0) / 1)) / 8388608.0;
			//~ Dv = (4.096 * ((D.Samples - 0) / 1)) / 8388608.0;
			
				
			//~ formatf("\n\nFSMAdcs: current values: 0x%016llx, 0x%016llx, 0x%016llx; %+lld(%u), %+lld(%u), %+lld(%u), %+1.3lf, %+1.3lf, %+1.3lf\n", A.all, B.all, C.all, A.Samples, A.NumAccums, B.Samples, B.NumAccums, C.Samples, C.NumAccums, (4.096 * (A.Samples / A.NumAccums)) / 8388608.0, (4.096 * (B.Samples / B.NumAccums)) / 8388608.0, (4.096 * (C.Samples / C.NumAccums)) / 8388608.0);
			//~ formatf("\nFSMAdcs: current values: 0x%016llx, 0x%016llx, 0x%016llx, 0x%016llx; %+d(%u), %+d(%u), %+d(%u), %+d(%u), %+1.3lf, %+1.3lf, %+1.3lf, %+1.3lf\n", A.all, B.all, C.all, D.all, A.Samples, A.NumAccums, B.Samples, B.NumAccums, C.Samples, C.NumAccums, D.Samples, D.NumAccums, Av, Bv, Cv, Dv);
			//~ formatf("\nFSMAdcs: current values: Num: %5d, %+9d, %+9d, %+9d, %+9d, %+1.6lf, %+1.6lf, %+1.6lf, %+1.6lf\n", A.NumAccums, A.Samples, B.Samples, C.Samples, D.Samples, Av, Bv, Cv, Dv);
			formatf("\nFSMAdcs: current values: Num: %5d, 0x%016llx, 0x%016llx, 0x%016llx, 0x%016llx, %+1.6lf, %+1.6lf, %+1.6lf, %+1.6lf\n", A.NumAccums, A.Samples, B.Samples, C.Samples, D.Samples, Av, Bv, Cv, Dv);
			A.formatf();
			B.formatf();
			C.formatf();
			D.formatf();
		}
		
		//~ //Quit on any keypress
		//~ {
			//~ struct termios argin, argout;
			//~ tcgetattr(0,&argin);
			//~ argout = argin;
			//~ argout.c_lflag &= ~(ICANON);
			//~ argout.c_iflag &= ~(ICRNL);
			//~ argout.c_oflag &= ~(OPOST);
			//~ argout.c_cc[VMIN] = 1;
			//~ argout.c_cc[VTIME] = 0;
			//~ tcsetattr(0,TCSADRAIN,&argout);
			//~ //read(0, &key, 1);
			//~ ioctl(0, FIONREAD, &key);
			//~ tcsetattr(0,TCSADRAIN,&argin);
			//~ if (0 != key) 
			//~ { 
				//~ fflush(stdin);
				//~ formatf("\n\nFSMAdcs: Keypress(%d); exiting.\n", key);
				//~ break; 
			//~ }			
		//~ }

		//~ struct timespec sleeptime;
		//~ memset((char *)&sleeptime,0,sizeof(sleeptime));
		//~ sleeptime.tv_nsec = 100000000;
		//~ //sleeptime.tv_sec = 1;
		//~ nanosleep(&sleeptime, NULL);
	//~ }
	
	return(ParamsLen);
}

int8_t BISTCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	//~ size_t cycle = 0;
	//~ unsigned long daca = 0;
	//~ int key = 0;
	
	//~ while(true)
	//~ {
		//~ cycle++;
		
		//~ //Show current A/D values:
		//~ {
			//~ //Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
			//~ *((uint8_t*)&(FSM->LatchAdcs)) = cycle | 1;
			//~ AdcAccumulator A, B, C;
			//~ A = FSM->AdcAAccumulator;
			//~ B = FSM->AdcBAccumulator;
			//~ C = FSM->AdcCAccumulator;

			//~ double Av, Bv, Cv;
			//~ Av = (4.096 * ((A.Samples - 0) / A.NumAccums)) / 8388608.0;
			//~ Bv = (4.096 * ((B.Samples - 0) / B.NumAccums)) / 8388608.0;
			//~ Cv = (4.096 * ((C.Samples - 0) / C.NumAccums)) / 8388608.0;
			
			//~ formatf("\n\nBIST: current A/D values: 0x%016llx, 0x%016llx, 0x%016llx; %+lld(%u), %+lld(%u), %+lld(%u), %+1.3lf, %+1.3lf, %+1.3lf; %u, %u, %u.\n", A.all, B.all, C.all, A.Samples, A.NumAccums, B.Samples, B.NumAccums, C.Samples, C.NumAccums, Av, Bv, Cv, offsetof(CGraphFSMHardwareInterface, AdcAAccumulator), offsetof(CGraphFSMHardwareInterface, AdcBAccumulator), offsetof(CGraphFSMHardwareInterface, AdcCAccumulator));
		//~ }
		
		//~ //Update the D/A's every so often
		//~ if (0 == cycle % 4)
		//~ {
			//~ FSM->DacASetpoint = daca;
			//~ //FSM->DacBSetpoint = daca;
			//~ FSM->DacBSetpoint = 0x00CFFFFFUL;
			//~ FSM->DacCSetpoint = daca;
			//~ formatf("\n\nBIST: D/A's set to: %lx.\n", daca);	

			//~ switch(daca)
			//~ {
				//~ case 0x00000000UL: { daca = 0x002FFFFFUL; break; }
				//~ case 0x003FFFFFUL: { daca = 0x006FFFFFUL; break; }
				//~ case 0x007FFFFFUL: { daca = 0x009FFFFFUL; break; }
				//~ case 0x00BFFFFFUL: { daca = 0x00CFFFFFUL; break; }
				//~ default: { daca = 0; break; }
			//~ }
		//~ }
		
		//Show the monitor A/D
		//~ {
			//~ size_t j = cycle % 12;
			//~ MonitorAdc.Init();
			//~ switch(j)
			//~ {
				//~ case 0: { formatf("P1V2: %3.6lf V\n", MonitorAdc.GetP1V2()); break; }
				//~ case 1: { formatf("P2V2: %3.6lf V\n", MonitorAdc.GetP2V2()); break; }
				//~ case 2: { formatf("P28V: %3.6lf V\n", MonitorAdc.GetP28V()); break; }
				//~ case 3: { formatf("P2V5: %3.6lf V\n", MonitorAdc.GetP2V5()); break; }
				//case 4: { formatf("P3V3A: %3.6lf V\n", MonitorAdc.GetP3V3A()); break; }
				//~ case 5: { formatf("P6V: %3.6lf V\n", MonitorAdc.GetP6V()); break; }
				//~ case 6: { formatf("P5V: %3.6lf V\n", MonitorAdc.GetP5V()); break; }
				//~ case 7: { formatf("P3V3D: %3.6lf V\n", MonitorAdc.GetP3V3D()); break; }
				//~ case 8: { formatf("P4V3: %3.6lf V\n", MonitorAdc.GetP4V3()); break; }
				//case 9: { formatf("N5V: %3.6lf V\n", MonitorAdc.GetN5V()); break; }
				//case 10: { formatf("N6V: %3.6lf V\n", MonitorAdc.GetN6V()); break; }
				//case 11: { formatf("P150V: %3.6lf V\n\n\n", MonitorAdc.GetP150V()); break; }
				//~ default : { }
			//~ }
			
			//~ if ((cycle % 256) > 0x40)
			//~ {
				//~ const uint32_t zero = 0UL;			
				//~ const uint32_t one = 1UL;
				//~ //*(uint32_t*)(FSM+108UL) = zero;
				//~ *(uint8_t*)(&FSM->MonitorAdcSpiCommandStatusRegister.all) = zero;
				//~ FSM->MonitorAdcSpiTransactionRegister = (uint32_t)(cycle % 256); 
				//~ uint32_t out = FSM->MonitorAdcSpiTransactionRegister; 
				//~ *(uint8_t*)(&FSM->MonitorAdcSpiCommandStatusRegister.all) = one;
				//~ formatf("ads1258(%4ld): 0x%4lX\n", cycle % 256, out & 0xFFFFUL);
				//~ delayus(200);
			//~ }
		//~ }
		
		//Quit on any keypress
		//~ {
			//~ if (0 != key) 
			//~ if (cycle > 1000)
			//~ { 
				//~ fflush(stdin);
				//~ formatf("\n\nBIST: Keypress(%d); exiting.\n", key);
				//~ break; 
			//~ }			
		//~ }

		//~ DelayMs(10);
	//~ }
	
	char onoff;
    bool OnOff = false;

	//Convert parameters
    int8_t numfound = sscanf(Params, "[,\t ]%c", &onoff);
    if (numfound >= 1)
    {
		if ( ('Y' == onoff) || ('y' == onoff) || ('T' == onoff) || ('t' == onoff) || ('1' == onoff) ) { OnOff = true; }
		
		formatf("\n\nBISTCommand: Enabled: %c.\n", OnOff?'Y':'N');
		
		BISTModeEnabled = OnOff;
					
		return(strlen(Params));
    }
	
	formatf("\n\nBISTCommand: Enabled: %c.\n", BISTModeEnabled?'Y':'N');
			
	return(ParamsLen);
}

int8_t CirclesCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	size_t cycle = 0;
	unsigned long daca = 0;
	unsigned long dacb = 0;
	unsigned long dacc = 0;
	unsigned long dacd = 0;
	int key = 0;
	
	double radius = 1.0;
	double delayinms = 1.0; //1ms
	sscanf(Params, "%lf,%lf", &radius, &delayinms);
	if (radius < 0.0) { radius = 0.0; }
	if (radius > 1.0) { radius = 1.0; }
	if (delayinms < 0.001) { delayinms = 0.001; }
	if (delayinms > 10000) { delayinms = 10000; }
	
	formatf("\n\nCircles: RunCircle(%lf, %lfms)...\n", radius, delayinms);	
	    	
	while(true)
	{
		cycle++;
		
		//Update the D/A's every so often
		{
			FSM->DacASetpoint = daca;
			FSM->DacBSetpoint = dacb;
			//~ FSM->DacBSetpoint = 0x00AAAAAAUL;
			//~ FSM->DacBSetpoint = 0x006FFFFFUL;
			//~ FSM->DacBSetpoint = 0x00CFFFFFUL;
			FSM->DacCSetpoint = dacc;
			FSM->DacDSetpoint = dacd;
			//~ formatf("\n\nBIST: D/A's set to: %lx, %lx, %lx.\n", daca, 0x006FFFFFUL, dacc);	

			unsigned long rba = FSM->DacASetpoint;
			unsigned long rbb = FSM->DacBSetpoint;
			unsigned long rbc = FSM->DacCSetpoint;
			unsigned long rbd = FSM->DacDSetpoint;
			formatf("\n%lu, %lu, %lu, %lu", rba, rbb, rbc, rbd);
			//~ fflush(stdin);		
			
			//~ double ang = (double)(cycle % 360);
			double ang = (double)(cycle % 60) * 6.0;
			//~ double rad = (ang / 360.0) * 6.28;
			double rada = (ang / 360.0) * 6.28;
			double radb = ((ang + 120) / 360.0) * 6.28;
			double radc = ((ang + 240) / 360.0) * 6.28;
			//~ double carta = ((sin(rad) + 1.0) / 2.0) * radius;
			//~ double cartc = ((cos(rad) + 1.0) / 2.0) * radius;
			//~ formatf("\n\nBIST: Deg:%f, Rad:%f, Sin:%f, Cos:%f.\n", ang, rad, carta, cartb);	
			double carta = ((sin(rada) + 1.0) / 2.0) * radius;
			double cartb = ((sin(radb) + 1.0) / 2.0) * radius;
			double cartc = ((sin(radc) + 1.0) / 2.0) * radius;
			
			//~ daca = (unsigned long)(carta * 0x00CFFFFFUL);
			//~ dacb = (unsigned long)(cartb * 0x00CFFFFFUL);
			//~ dacc = (unsigned long)(cartc * 0x00CFFFFFUL);
			//~ dacd = (unsigned long)(cartc * 0x00CFFFFFUL);
			daca = (unsigned long)(carta * 0x0000FFFFUL);
			dacb = (unsigned long)(cartb * 0x0000FFFFUL);
			dacc = (unsigned long)(cartc * 0x0000FFFFUL);
			dacd = (unsigned long)(cartc * 0x0000FFFFUL);
			
			//~ formatf("\n%lu, %lu, %lu", daca, dacb, dacc);
		}
		
		//Quit on any keypress
		{
			//~ if (0 != key) 
			if (cycle > 1000)
			{ 
				//~ fflush(stdin);
				formatf("\n\nCircles: Keypress(%d); exiting.\n", key);
				break; 
			}			
		}

		delayus(delayinms * 1000);
	}
	
	return(ParamsLen);
}

int8_t GoXYCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
    unsigned long A = 0, B = 0, C = 0, D = 0;
	
	if (NULL == FSM)
	{
		formatf("\n\nGoXY: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
	double X = 0.0;
	double Y = 0.0;
    sscanf(Params, "%lf,%lf", &X, &Y);
	if (X < 0.0) { X = 0.0; }
	if (X > 1.0) { X = 1.0; }
	if (Y < 0.0) { Y = 0.0; }
	if (Y > 1.0) { Y = 1.0; }
	
	A = (unsigned long)(X * 0x00CFFFFFUL);
	C = (unsigned long)(Y * 0x00CFFFFFUL);
	
	FSM->DacASetpoint = A;
	//~ FSM->DacBSetpoint = 0x006FFFFFUL;
	FSM->DacBSetpoint = 0x00CFFFFFUL;
	FSM->DacCSetpoint = C;
	//~ FSM->DacDSetpoint = 0x006FFFFFUL;
	FSM->DacDSetpoint = 0x00CFFFFFUL;
	formatf("\n\nGoXY: set to: %lx, %lx, %lx, %lx.\n", A, 0x00CFFFFFUL, C, 0x00CFFFFFUL);


	A = FSM->DacASetpoint;
	B = FSM->DacBSetpoint;
	C = FSM->DacCSetpoint;
	D = FSM->DacDSetpoint;
	formatf("\n\nGoXY: current value: %lx, %lx, %lx, %lx (%lfV x %lfV).\n", A, B, C, D, X * 100.0, Y * 100.0);
	
	//~ //Show current A/D values:
	//~ {
		//~ //Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
		//~ FSM->InititateLatchAdcs();
		//~ AdcAccumulator Aa, Ba, Ca, Da;
		//~ Aa = FSM->AdcAAccumulator;
		//~ Ba = FSM->AdcBAccumulator;
		//~ Ca = FSM->AdcCAccumulator;
		//~ Da = FSM->AdcDAccumulator;

		//~ double Av, Bv, Cv, Dv;
		//~ Av = (4.096 * ((Aa.Samples - 0) / Aa.NumAccums)) / 8388608.0;
		//~ Bv = (4.096 * ((Ba.Samples - 0) / Ba.NumAccums)) / 8388608.0;
		//~ Cv = (4.096 * ((Ca.Samples - 0) / Ca.NumAccums)) / 8388608.0;
		//~ Dv = (4.096 * ((Da.Samples - 0) / Da.NumAccums)) / 8388608.0;
		
			
		//~ //formatf("\n\nFSMAdcs: current values: 0x%016llx, 0x%016llx, 0x%016llx; %+lld(%u), %+lld(%u), %+lld(%u), %+1.3lf, %+1.3lf, %+1.3lf\n", A.all, B.all, C.all, A.Samples, A.NumAccums, B.Samples, B.NumAccums, C.Samples, C.NumAccums, (4.096 * (A.Samples / A.NumAccums)) / 8388608.0, (4.096 * (B.Samples / B.NumAccums)) / 8388608.0, (4.096 * (C.Samples / C.NumAccums)) / 8388608.0);
		//~ formatf("\nFSMAdcs: current values: %+d(%u), %+d(%u), %+d(%u), %+d(%u), %+1.3lf, %+1.3lf, %+1.3lf, %+1.3lf\n", Aa.Samples, Aa.NumAccums, Ba.Samples, Ba.NumAccums, Ca.Samples, Ca.NumAccums, Da.Samples, Da.NumAccums, Av, Bv, Cv, Dv);
	//~ }
	
	//~ formatf("\n\nFSMdaca: D/A registers at: %u, %u, %u.\n", offsetof(CGraphFSMHardwareInterface, DacASetpoint), offsetof(CGraphFSMHardwareInterface, DacBSetpoint), offsetof(CGraphFSMHardwareInterface, DacCSetpoint));
	
    return(ParamsLen);
}

int8_t UartCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	struct timespec sleeptime;
	memset((char *)&sleeptime,0,sizeof(sleeptime));
	sleeptime.tv_nsec = 1000000;
	sleeptime.tv_sec = 0;
	int key = 0;
	
	//Convert parameter to an integer
	//~ size_t addr = 0;
    //~ unsigned long val = 0;
    //~ int8_t numfound = sscanf(Params, "%zX %lu", &addr, &val);
    //~ if (numfound < 2)
    //~ {
		//~ formatf("\nUartCommand: need 2 numeric parameters (address and value), got \"%s\" (%d params).\n", Params, numfound);
        //~ return(-1);
    //~ }
	//~ char* cmd = 0;
	//~ char* params = 0;
	//~ int8_t numfound = sscanf(Params, "%s %s", cmd, params);
	//~ if (numfound < 2)
    //~ {
		//~ formatf("\nUartCommand: need 2 numeric parameters (address and value), got \"%s\" (%d params).\n", Params, numfound);
        //~ return(-1);
    //~ }
	
	//~ formatf("\nUartCommand: FSM@0x%p, USR@%u, UF@%u, MAA@%u, ACF@%u, ACF is %u, ", (void*)FSM, offsetof(CGraphFSMHardwareInterface, UartStatusRegister), offsetof(CGraphFSMHardwareInterface, UartFifo), offsetof(CGraphFSMHardwareInterface, MonitorAdcAccumulator), offsetof(CGraphFSMHardwareInterface, AdcCFifo), sizeof(AdcFifo));
	formatf("\nUartCommand: %u, %u. ", offsetof(CGraphFSMHardwareInterface, UartFifo2), offsetof(CGraphFSMHardwareInterface, UartStatusRegister2));
	
	if (0 == strncmp(&(Params[1]), "loop", 4))
	{
		while(true)
		{
			//~ FSM->UartFifo0 = 0x55;
			//~ FSM->UartFifo1 = 0x55;	
			FSM->UartFifo2 = 0x55;
			
			//Quit on any keypress
			{
				//~ if (0 != key) 
				{ 
					fflush(stdin);
					formatf("\n\nCircles: Keypress(%d); exiting.\n", key);
					break; 
				}			
			}
		}
	}
	
	//~ CGraphFSMUartStatusRegister UartStatus = FSM->UartStatusRegister2;
	//~ UartStatus.formatf();	
	
	//~ formatf("; about to write to uart... ");	
	//~ FSM->UartFifo = 'H';
	//~ nanosleep(&sleeptime, NULL);
	//~ FSM->UartFifo = 'e';
	//~ nanosleep(&sleeptime, NULL);
	//~ FSM->UartFifo = 'l';
	//~ nanosleep(&sleeptime, NULL);
	//~ FSM->UartFifo = 'l';
	//~ nanosleep(&sleeptime, NULL);
	//~ FSM->UartFifo = 'o';
	//~ nanosleep(&sleeptime, NULL);
	//~ FSM->UartFifo = '!';
	//~ nanosleep(&sleeptime, NULL);
	
	//~ UartStatus = FSM->UartStatusRegister; 
	//~ formatf("; uart written; ");	
	//~ UartStatus.formatf();	
	
	//~ CGraphFSMUartStatusRegister UartStatus2;
	
	//~ for(size_t i = 0; i < 100000; i++)
	//~ { 
		//~ UartStatus = FSM->UartStatusRegister; 
		//~ if (0 == UartStatus.Uart2TxFifoEmpty) { break; }
	//~ }
	
	//~ formatf("\nUartCommand: about to read...");
	//~ UartStatus.formatf();	
	//~ formatf("; reading from uart... ");
	
	//~ for (size_t i = 0; i < 1024; i++)
	//~ {
		//~ FpgaUartParser.Process();
	//~ }
		
	
	//~ for(size_t i = 0; i < 128; i++)
	//~ for(size_t i = 0; i < 4096; i++)
	//~ {
		//~ if (0 != UartStatus.Uart2RxFifoEmpty) { break; }
		//~ formatf(":%.2X", FSM->UartFifo);
		//~ UartStatus = FSM->UartStatusRegister; 		
	//~ }
	
	//~ {
		//~ //clear buffer:
		//~ FSM->UartStatusRegister.all = 1;
	//~ }
	
	//~ formatf(":%.4X", FSM->UartFifo2);
	
	//~ formatf("\n");
	//~ UartStatus.formatf();	
	
	CGraphVersionPayload Version;
    Version.SerialNum = 0;
	Version.ProcessorFirmwareBuildNum = BuildNum;
	Version.FPGAFirmwareBuildNum = 0;
	if (FSM) 
	{ 
		Version.SerialNum = FSM->DeviceSerialNumber; 
		Version.FPGAFirmwareBuildNum = FSM->FpgaFirmwareBuildNumber; 
	}
    formatf("\nUartCommand: Sending response (%u bytes): ", sizeof(CGraphVersionPayload));
    Version.formatf();
    formatf("\n");
	//~ TxBinaryPacket(&FpgaUartParser0, CGraphPayloadTypeVersion, 0, &Version, sizeof(CGraphVersionPayload));
	//~ TxBinaryPacket(&FpgaUartParser1, CGraphPayloadTypeVersion, 0, &Version, sizeof(CGraphVersionPayload));
    //~ TxBinaryPacket(&FpgaUartParser2, CGraphPayloadTypeVersion, 0, &Version, sizeof(CGraphVersionPayload));
    //~ TxBinaryPacket(&FpgaUartParser3, CGraphPayloadTypeVersion, 0, &Version, sizeof(CGraphVersionPayload));
    
	formatf("\nUartCommand: complete.\n");

	return(ParamsLen);
}

int8_t BaudDividersCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	unsigned long A = 0, B = 0, C = 0, D = 0;
	
	if (NULL == FSM)
	{
		formatf("\n\nBaudDividers: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu,%lu,%lu,%lu", &A, &B, &C, &D);
    if (numfound >= 4)
    {
		FSM->BaudDividers.Divider0 = A;
		FSM->BaudDividers.Divider1 = B;
		FSM->BaudDividers.Divider2 = C;
		FSM->BaudDividers.Divider3 = D;
		formatf("\n\nBaudDividers: setting to: %lu, %lu, %lu, %lu.\n", A, B, C, D);
    }
	else
	{
		if (numfound >= 1)
		{
			FSM->BaudDividers.Divider0 = A;
			FSM->BaudDividers.Divider1 = A;
			FSM->BaudDividers.Divider2 = A;
			FSM->BaudDividers.Divider3 = A;
			formatf("\n\nBaudDividers: setting to: %lu, %lu, %lu, %lu.\n", A, A, A, A);
		}
	}
	
	A = FSM->BaudDividers.Divider0;
	B = FSM->BaudDividers.Divider1;
	C = FSM->BaudDividers.Divider2;
	D = FSM->BaudDividers.Divider3;
	formatf("\n\nBaudDividers: current values: %lu, %lu, %lu, %lu.\n", A, B, C, D);
	
	//~ formatf("\nBaudDividers: (331 = 9600, 83 = 38400, 55 = 57600, 27 = 115200, 13 = 230400, 7 = 460800, 3 = 921600)\n");
	
	double BaudClock = 102000000.0;
	//~ unsigned int ActualDividerA = (A + 1) * 2;
	//~ unsigned int ActualDividerB = (B + 1) * 2;
	//~ unsigned int ActualDividerC = (C + 1) * 2;
	//~ unsigned int ActualDividerD = (D + 1) * 2;
	unsigned int ActualDividerA = (A + 1);
	unsigned int ActualDividerB = (B + 1);
	unsigned int ActualDividerC = (C + 1);
	unsigned int ActualDividerD = (D + 1);
	double BaudRateA = (BaudClock / ActualDividerA) / 16;
	double BaudRateB = (BaudClock / ActualDividerB) / 16;
	double BaudRateC = (BaudClock / ActualDividerC) / 16;
	double BaudRateD = (BaudClock / ActualDividerD) / 16;
	
	formatf("\nBaudDividers: Port0 final division ratio: %u (/16); Actual baudrate: %.5lf", ActualDividerA, BaudRateA);
	formatf("\nBaudDividers: Port1 final division ratio: %u (/16); Actual baudrate: %.5lf", ActualDividerB, BaudRateB);
	formatf("\nBaudDividers: Port2 final division ratio: %u (/16); Actual baudrate: %.5lf\n", ActualDividerC, BaudRateC);
	formatf("\nBaudDividers: Port3 final division ratio: %u (/16); Actual baudrate: %.5lf\n", ActualDividerD, BaudRateD);
	
	return(ParamsLen);
}

int8_t ConfigAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	AdcConfigRegister cr;
	AccumulatorConfigRegister ar;
	unsigned long A = 0, B = 0, C, D;
	
	if (NULL == FSM)
	{
		formatf("\n\nConfigAdc: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu,%lu,%lu,%lu", &A, &B, &C, &D);
    if (numfound >= 2)
    {
		cr.AdcClkDivider = A;
		cr.AdcSamplesToAverage = B;
		formatf("\n\nConfigAdc: setting AdcConfig to: ");
		cr.formatf();
		formatf("\n");
		FSM->AdcConfig = cr;
    }
	if (numfound >= 4)
    {
		ar.ControlAdcMaxAccums = C;
		ar.MonitorAdcMaxAccums = D;
		formatf("\n\nConfigAdc: setting AccumConfig to: ");
		ar.formatf();
		formatf("\n");
		FSM->AccumConfig = ar;
    }
	
	cr = FSM->AdcConfig;
	ar = FSM->AccumConfig;
	formatf("\n\nConfigAdc: current values: ");
	cr.formatf();
	formatf("; ");
	ar.formatf();
	formatf("\n");
	
	return(ParamsLen);
}

int8_t PrintBuffersCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	formatf("\nShowBuffersCommand: FpgaUartParser: ");
	//~ FpgaUartParser0.formatf();
	//~ FpgaUartParser1.formatf();
	//~ FpgaUartParser2.formatf();
	//~ FpgaUartParser3.formatf();
	formatf("\n\n");
	return(ParamsLen);
}

int8_t MonitorSerialCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	unsigned long port = 0;
	char seperator[8];
	char onoff;
    bool OnOff = false;

	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu%2[,\t ] %c", &port, seperator, &onoff);
    if (numfound >= 4)
    {
		if ( ('Y' == onoff) || ('y' == onoff) || ('T' == onoff) || ('t' == onoff) || ('1' == onoff) ) { OnOff = true; }
		
		formatf("\n\nMonitorSerialCommand: Monitoring port %lu: %c.\n", port, OnOff?'Y':'N');
		
		switch(port)
		{
			case 0 : { FPGAUartPinout0.Monitor(OnOff); break; }			
			case 1 : { FPGAUartPinout1.Monitor(OnOff); break; }			
			case 2 : { FPGAUartPinout2.Monitor(OnOff); break; }			
			case 3 : { FPGAUartPinout3.Monitor(OnOff); break; }			
			default : 
			{ 
				formatf("\n\nMonitorSerialCommand: Invalid port %lu; max is #2.\n", port);
			}
		}
			
		return(strlen(Params));
    }
	
	formatf("\n\nMonitorSerialCommand: Insufficient parameters (%u; should be 2); querying...", numfound);

	formatf("\nMonitorSerialCommand: Monitoring port 0: %c.\n", FPGAUartPinout0.Monitor()?'Y':'N');
	formatf("\nMonitorSerialCommand: Monitoring port 1: %c.\n", FPGAUartPinout1.Monitor()?'Y':'N');
	formatf("\nMonitorSerialCommand: Monitoring port 2: %c.\n", FPGAUartPinout2.Monitor()?'Y':'N');	
	formatf("\nMonitorSerialCommand: Monitoring port 3: %c.\n", FPGAUartPinout3.Monitor()?'Y':'N');	
	
    return(strlen(Params));
}


int8_t ControlRegisterCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphFSMHardwareControlRegister cr;
	char c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17;
	bool o1=false, o2=false, o3=false, o4=false, o5=false, o6=false, o7=false, o8=false, o9=false, o10=false, o11=false, o12=false, o13=false, o14=false, o15=false, o16=false, o17=false;
    
	if (NULL == FSM)
	{
		formatf("\nControlRegisterCommand: Fpga interface is not initialized!");
		return(ParamsLen);
	}
	
    int8_t numfound = sscanf(Params, " %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c, %c", &c1, &c2, &c3, &c4, &c5, &c6, &c7, &c8, &c9, &c10, &c11, &c12, &c13, &c14, &c15, &c16, &c17);
    if (numfound >= 1)
    {
		if ( ('Y' == c1) || ('y' == c1) || ('T' == c1) || ('t' == c1) || ('1' == c1) ) { o1 = true; }
		if ( ('Y' == c2) || ('y' == c2) || ('T' == c2) || ('t' == c2) || ('1' == c2) ) { o2 = true; }
		if ( ('Y' == c3) || ('y' == c3) || ('T' == c3) || ('t' == c3) || ('1' == c3) ) { o3 = true; }
		if ( ('Y' == c4) || ('y' == c4) || ('T' == c4) || ('t' == c4) || ('1' == c4) ) { o4 = true; }
		if ( ('Y' == c5) || ('y' == c5) || ('T' == c5) || ('t' == c5) || ('1' == c5) ) { o5 = true; }
		if ( ('Y' == c6) || ('y' == c6) || ('T' == c6) || ('t' == c6) || ('1' == c6) ) { o6 = true; }
		if ( ('Y' == c7) || ('y' == c7) || ('T' == c7) || ('t' == c7) || ('1' == c7) ) { o7 = true; }
		if ( ('Y' == c8) || ('y' == c8) || ('T' == c8) || ('t' == c8) || ('1' == c8) ) { o8 = true; }
		if ( ('Y' == c9) || ('y' == c9) || ('T' == c9) || ('t' == c9) || ('1' == c9) ) { o9 = true; }
		if ( ('Y' == c10) || ('y' == c10) || ('T' == c10) || ('t' == c10) || ('1' == c10) ) { o10 = true; }
		if ( ('Y' == c11) || ('y' == c11) || ('T' == c11) || ('t' == c11) || ('1' == c11) ) { o11 = true; }
		if ( ('Y' == c12) || ('y' == c12) || ('T' == c12) || ('t' == c12) || ('1' == c12) ) { o12 = true; }
		if ( ('Y' == c13) || ('y' == c13) || ('T' == c13) || ('t' == c13) || ('1' == c13) ) { o13 = true; }
		if ( ('Y' == c14) || ('y' == c14) || ('T' == c14) || ('t' == c14) || ('1' == c14) ) { o14 = true; }
		if ( ('Y' == c15) || ('y' == c15) || ('T' == c15) || ('t' == c15) || ('1' == c15) ) { o15 = true; }
		if ( ('Y' == c16) || ('y' == c16) || ('T' == c16) || ('t' == c16) || ('1' == c16) ) { o16 = true; }
		if ( ('Y' == c17) || ('y' == c17) || ('T' == c17) || ('t' == c17) || ('1' == c17) ) { o17 = true; }

		cr.PowerCycdAndClr = o1;
		cr.PowernEn = o2;
		cr.ChopEn = o3;
		cr.ChopRefState = o4;
		cr.ChopAdcState = o5;
		cr.Uart0OE = o6;
		cr.Uart1OE = o7;
		cr.Uart2OE = o8;
		cr.Uart3OE = o9;
		cr.Ux1SelJmp = o10;
		cr.PPSDetectedAndRst = o11;
		cr.PowernEnHV = o12;
		cr.HVEn1 = o13;
		cr.HVEn2 = o14;
		cr.DacSelectMaxti = o15;
		cr.GlobalFaultInhibit = o16;
		cr.nFaultsClr = o17;
		
		FSM->ControlRegister = cr;
	}		
	
	cr = FSM->ControlRegister;

	formatf("\nControlRegisterCommand: Current values: ");
	cr.formatf();
	
    return(strlen(Params));
}

int8_t SelectDacCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphFSMHardwareControlRegister cr;
	
	if (NULL == FSM)
	{
		formatf("\nSelectDac: Fpga interface is not initialized!");
		return(ParamsLen);
	}

	char onoff;
    bool OnOff = false;

	//Convert parameters
    int8_t numfound = sscanf(Params, " %c", &onoff);
    if (numfound >= 1)
    {
		if ( ('Y' == onoff) || ('y' == onoff) || ('T' == onoff) || ('t' == onoff) || ('1' == onoff) ) { OnOff = true; }
		
		cr = FSM->ControlRegister;
		
		cr.DacSelectMaxti = OnOff;
		
		FSM->ControlRegister = cr;
		
		formatf("\n\nSelectDac: %c ('%c').\n", OnOff?'1':'0', onoff);
	}
	
	cr = FSM->ControlRegister;
	formatf("\nSelectDac: Current value: %lu.\n", (uint8_t)(cr.DacSelectMaxti));
	
    return(strlen(Params));
}

int8_t SelectOutputCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphFSMHardwareControlRegister cr;
	
	if (NULL == FSM)
	{
		formatf("\nSelectOutput: Fpga interface is not initialized!");
		return(ParamsLen);
	}

	char onoff;
    bool OnOff = false;

	//Convert parameters
    int8_t numfound = sscanf(Params, " %c", &onoff);
    if (numfound >= 1)
    {
		if ( ('Y' == onoff) || ('y' == onoff) || ('T' == onoff) || ('t' == onoff) || ('1' == onoff) ) { OnOff = true; }
		
		cr = FSM->ControlRegister;
		
		if (OnOff) { cr.HVEn1 = 0; cr.HVEn2 = 1; }
		else { cr.HVEn1 = 1; cr.HVEn2 = 0; }
		
		FSM->ControlRegister = cr;
		
		formatf("\n\nSelectOutput: %c ('%c').\n", OnOff?'1':'0', onoff);
	}
	
	cr = FSM->ControlRegister;
	formatf("\nSelectOutput: Current value: %lu.\n", (uint8_t)(cr.HVEn2));
	
    return(strlen(Params));
}

int8_t ClockDacCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	unsigned long A = 0;
	
	if (NULL == FSM)
	{
		formatf("\n\nClockDac: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu", &A);
    if (numfound >= 1)
    {
		formatf("\n\nClockDac: setting Clock D/A to: %lu (0x%lX).\n", A, A);
		FSM->ClockSteeringDacSetpoint = A;
    }
	
	A = FSM->ClockSteeringDacSetpoint;
	formatf("\n\nClockDac: current value: %lu (0x%lX)", A, A);
	
	return(ParamsLen);
}

int8_t ConfigDacCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	DacConfigRegister cr;
	unsigned long A = 0;
	
	if (NULL == FSM)
	{
		formatf("\n\nConfigDacCommand: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu", &A);
    if (numfound >= 1)
    {
		cr.DitherClkDivider = A;
		formatf("\n\nConfigDacCommand: setting DacConfig to: ");
		cr.formatf();
		formatf("\n");
		FSM->DacConfig = cr;
    }
	
	cr = FSM->DacConfig;
	formatf("\n\nConfigDacCommand: current values: ");
	cr.formatf();
	formatf("\n");
	
	return(ParamsLen);
}

//EOF

