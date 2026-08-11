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
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <inttypes.h>
#include <unordered_map>
using namespace std;

#include "uart/BinaryUart.hpp"

#include "cgraph/CGraphPacket.hpp"

#include "cgraph/CGraphFSMHardwareInterface.hpp"
extern CGraphFSMHardwareInterface* volatile FSM;	

#include "MonitorAdc.hpp"
extern CGraphFSMMonitorAdc MonitorAdc;

#include "MainBuildNum"

#include "CmdTableBinary.hpp"

int8_t BinaryVersionCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	//(Don't validate version; always reply, even though it will cause a mess, so everyone knows we're here!)
	
    CGraphVersionPayload Version;
    Version.SerialNum = 0;
	Version.ProcessorFirmwareBuildNum = BuildNum;
	Version.FPGAFirmwareBuildNum = 0;
	if (FSM) 
	{ 
		Version.SerialNum = FSM->DeviceSerialNumber; 
		Version.FPGAFirmwareBuildNum = FSM->FpgaFirmwareBuildNumber; 
	}
    printf("\nBinaryVersionCommand: Sending response (%u bytes): ", sizeof(CGraphVersionPayload));
    Version.formatf();
    printf("\n");
    TxBinaryPacket(Argument, CGraphPayloadTypeVersion, 0, &Version, sizeof(CGraphVersionPayload));
    return(ParamsLen);
}

int8_t BinaryFSMDacsCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (ParamsLen >= (3 * sizeof(uint32_t)))
	{
		const uint32_t* DacSetpoints = (const uint32_t*)Params;
		printf("\nBinaryFSMDacsCommand Setting to (0x%lX, 0x%lX, 0x%lX).\n\n", (unsigned long)DacSetpoints[0], (unsigned long)DacSetpoints[1], (unsigned long)DacSetpoints[2]);
		FSM->DacASetpoint = DacSetpoints[0];
		FSM->DacBSetpoint = DacSetpoints[1];
		FSM->DacCSetpoint = DacSetpoints[2];		
	}
	uint32_t DacSetpoints[3];
	DacSetpoints[0] = FSM->DacASetpoint;
	DacSetpoints[1] = FSM->DacBSetpoint;
	DacSetpoints[2] = FSM->DacCSetpoint;	
	printf("\nBinaryFSMDacsCommand  Replying (0x%lX, 0x%lX, 0x%lX)...\n\n", (unsigned long)DacSetpoints[0], (unsigned long)DacSetpoints[1], (unsigned long)DacSetpoints[2]);
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMDacs, 0, DacSetpoints, 3 * sizeof(uint32_t));

    return(ParamsLen);
}

int8_t BinaryFSMAdcsCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	AdcAccumulator AdcVals[3];	
	//Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
	*((uint8_t*)&(FSM->LatchAdcs)) = 1;
	AdcVals[0].Samples = FSM->AdcAAccumulator;
	AdcVals[0].SetHiWord(FSM->AdcAAccumulatorHiandNumAccums);
	AdcVals[1].Samples = FSM->AdcBAccumulator;
	AdcVals[1].SetHiWord(FSM->AdcBAccumulatorHiandNumAccums);
	AdcVals[2].Samples = FSM->AdcCAccumulator;	
	AdcVals[2].SetHiWord(FSM->AdcCAccumulatorHiandNumAccums);
	printf("\nBinaryFSMAdcsCommand  Replying (%d, %d, %d)...\n\n", AdcVals[0].Samples, AdcVals[1].Samples, AdcVals[2].Samples);
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMAdcs, 0, AdcVals, 3 * sizeof(AdcAccumulator));
    return(ParamsLen);
}
	
int8_t BinaryFSMAdcsFloatingPointCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	printf("\nBinaryFSMAdcsCommand processing(%u)...\n\n", ParamsLen);
	
	double AdcVals[3];
	//Prepare for atomic read of samples (do as an 8-bit pointer so the processor doesn't crash !#@$%#!):
	*((uint8_t*)&(FSM->LatchAdcs)) = 1;
	AdcAccumulator A, B, C;
	//~ A = FSM->AdcAAccumulator;
	//~ B = FSM->AdcBAccumulator;
	//~ C = FSM->AdcCAccumulator;
	A.Samples = FSM->AdcAAccumulator;
	A.SetHiWord(FSM->AdcAAccumulatorHiandNumAccums);
	B.Samples = FSM->AdcBAccumulator;
	B.SetHiWord(FSM->AdcBAccumulatorHiandNumAccums);
	C.Samples = FSM->AdcCAccumulator;	
	C.SetHiWord(FSM->AdcCAccumulatorHiandNumAccums);
	AdcVals[0] = (4.096 * (((double)A.Samples - 0) / (double)A.NumAccums)) / 8388608.0;
	AdcVals[1] = (4.096 * (((double)B.Samples - 0) / (double)B.NumAccums)) / 8388608.0;
	AdcVals[2] = (4.096 * (((double)C.Samples - 0) / (double)C.NumAccums)) / 8388608.0;
	printf("\nBinaryFSMAdcsFloatingPointCommand  Replying (%lf, %lf, %lf)...\n\n", AdcVals[0], AdcVals[1], AdcVals[2]);
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMAdcsFloatingPoint, 0, AdcVals, 3 * sizeof(double));

    return(ParamsLen);
}

int8_t BinaryFSMDacsFloatingPointCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	double VA = 0.0, VB = 0.0, VC = 0.0;	
	unsigned long A = 0, B = 0, C = 0;	
	
	if (ParamsLen >= (3 * sizeof(double)))
	{
		const double* DacSetpoints = (const double*)Params;
		
		VA = DacSetpoints[0];
		VB = DacSetpoints[1];
		VC = DacSetpoints[2];
		
		A = (VA * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
		B = (VB * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
		C = (VC * (double)(0x00FFFFFFUL) * 60.0) / 4.096;
		
		printf("\n\nBinaryFSMDacsCommand: Setting to: %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx).\n", VA, A, VB, B, VC, C);
		
		FSM->DacASetpoint = DacSetpoints[0];
		FSM->DacBSetpoint = DacSetpoints[1];
		FSM->DacCSetpoint = DacSetpoints[2];		
	}
	
	uint32_t DacSetpoints[3];
	
	A = FSM->DacASetpoint;
	B = FSM->DacBSetpoint;
	C = FSM->DacCSetpoint;	
	
	VA = 4.096 * (double)(A) / ((double)(0x00FFFFFFUL) * 60.0);
	VB = 4.096 * (double)(B) / ((double)(0x00FFFFFFUL) * 60.0);
	VC = 4.096 * (double)(C) / ((double)(0x00FFFFFFUL) * 60.0);
	
	DacSetpoints[0] = VA;
	DacSetpoints[1] = VB;
	DacSetpoints[2] = VC;	
	
	printf("\n\nBinaryFSMDacsCommand: Replying: %3.1lf (%lx), %3.1lf (%lx), %3.1lf (%lx).\n", VA, A, VB, B, VC, C);
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMDacsFloatingPoint, 0, DacSetpoints, 3 * sizeof(double));

    return(ParamsLen);
}

int8_t BinaryFSMStatusCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphFSMTelemetryPayload Status;
	
	Status.IHV = MonitorAdc.GetIHV();
	Status.INV = MonitorAdc.GetINV();
	Status.I6V = MonitorAdc.GetI6V();
	Status.I3VD = MonitorAdc.GetI3VD();
	Status.I2VD = MonitorAdc.GetI2VD();
	Status.I1V = MonitorAdc.GetI1V();
	Status.StrainBP = MonitorAdc.GetStrainBP();
	Status.StrainBM = MonitorAdc.GetStrainBM();
	Status.StrainB = MonitorAdc.GetStrainB();
	Status.StrainDP = MonitorAdc.GetStrainDP();
	Status.StrainDM = MonitorAdc.GetStrainDM();
	Status.StrainD = MonitorAdc.GetStrainD();
	Status.StrainCM = MonitorAdc.GetStrainCM();
	Status.StrainCP = MonitorAdc.GetStrainCP();
	Status.StrainC = MonitorAdc.GetStrainC();
	Status.StrainAM = MonitorAdc.GetStrainAM();
	Status.StrainAP = MonitorAdc.GetStrainAP();
	Status.StrainA = MonitorAdc.GetStrainA();
	Status.P5VD = MonitorAdc.GetP5VD();
	Status.I2VA = MonitorAdc.GetI2VA();
	Status.Temp = MonitorAdc.GetTemp();
	Status.P3V3D = MonitorAdc.GetP3V3D();
	Status.P28V = MonitorAdc.GetP28V();
	Status.P2V2 = MonitorAdc.GetP2V2();
	Status.P2V5D = MonitorAdc.GetP2V5D();
	Status.P1V2 = MonitorAdc.GetP1V2();
	Status.P2V5A = MonitorAdc.GetP2V5A();
	Status.P4V3 = MonitorAdc.GetP4V3();
	Status.I3VA = MonitorAdc.GetI3VA();
	Status.P3V3A = MonitorAdc.GetP3V3A();
	Status.P6V = MonitorAdc.GetP6V();
	Status.P5VA = MonitorAdc.GetP5VA();
	Status.LuxRads = MonitorAdc.GetLuxRads();
	Status.N18V = MonitorAdc.GetN18V();
	Status.N20V = MonitorAdc.GetN20V();
	Status.P125V = MonitorAdc.GetP125V();

	printf("\n\nBinaryFSMStatusCommand: CurrentValues:\n\n");
	
	formatf("IHV: %3.6lf V\n", Status.IHV);
	formatf("INV: %3.6lf V\n", Status.INV);
	formatf("I6V: %3.6lf V\n", Status.I6V);
	formatf("I3VD: %3.6lf V\n", Status.I3VD);
	formatf("I2VD: %3.6lf V\n", Status.I2VD);
	formatf("I1V: %3.6lf V\n", Status.I1V);
	formatf("StrainBP: %3.6lf V\n", Status.StrainBP);
	formatf("StrainBM: %3.6lf V\n", Status.StrainBM);
	formatf("StrainB: %3.6lf V\n", Status.StrainB);
	formatf("StrainDP: %3.6lf V\n", Status.StrainDP);
	formatf("StrainDM: %3.6lf V\n", Status.StrainDM);
	formatf("StrainD: %3.6lf V\n", Status.StrainD);
	formatf("StrainCM: %3.6lf V\n", Status.StrainCM);
	formatf("StrainCP: %3.6lf V\n", Status.StrainCP);
	formatf("StrainC: %3.6lf V\n", Status.StrainC);
	formatf("StrainAM: %3.6lf V\n", Status.StrainAM);
	formatf("StrainAP: %3.6lf V\n", Status.StrainAP);
	formatf("StrainA: %3.6lf V\n", Status.StrainA);
	formatf("P5VD: %3.6lf V\n", Status.P5VD);
	formatf("I2VA: %3.6lf V\n", Status.I2VA);
	formatf("Temp: %3.6lf V\n", Status.Temp);
	formatf("P3V3D: %3.6lf V\n", Status.P3V3D);
	formatf("P28V: %3.6lf V\n", Status.P28V);
	formatf("P2V2: %3.6lf V\n", Status.P2V2);
	formatf("P2V5D: %3.6lf V\n", Status.P2V5D);
	formatf("P1V2: %3.6lf V\n", Status.P1V2);
	formatf("P2V5A: %3.6lf V\n", Status.P2V5A);
	formatf("P4V3: %3.6lf V\n", Status.P4V3);
	formatf("I3VA: %3.6lf V\n", Status.I3VA);
	formatf("P3V3A: %3.6lf V\n", Status.P3V3A);
	formatf("P6V: %3.6lf V\n", Status.P6V);
	formatf("P5VA: %3.6lf V\n", Status.P5VA);
	formatf("LuxRads: %3.6lf V\n", Status.LuxRads);
	formatf("N18V: %3.6lf V\n", Status.N18V);
	formatf("N20V: %3.6lf V\n", Status.N20V);
	formatf("P125V: %3.6lf V\n", Status.P125V);
	
	printf("\nBinaryFSMStatusCommand: Replying...\n");
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMTelemetry, 0, &Status, sizeof(CGraphFSMTelemetryPayload));

	return(ParamsLen);
}

int8_t BinaryFSMHardwareConfigCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (ParamsLen >= sizeof(CGraphFSMHardwareControlRegister))
	{
		const CGraphFSMHardwareControlRegister* val = (const CGraphFSMHardwareControlRegister*)Params;
		printf("\nBinaryFSMHardwareConfigCommand Setting to:");
		val->formatf();
		printf(".\n\n");
		FSM->ControlRegister = *val;
	}
	CGraphFSMHardwareControlRegister read = FSM->ControlRegister;
	printf("\nBinaryFSMHardwareConfigCommand Replying:");
	read.formatf();
	printf(".\n\n");	
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMHardwareConfigRegister, 0, &read, sizeof(CGraphFSMHardwareControlRegister));
    return(ParamsLen);
}

int8_t BinaryFSMAdcConfigCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (ParamsLen >= sizeof(AdcConfigRegister))
	{
		const AdcConfigRegister* val = (const AdcConfigRegister*)Params;
		printf("\nBinaryFSMAdcConfigCommand Setting to:");
		val->formatf();
		printf(".\n\n");
		FSM->AdcConfig = *val;
	}
	AdcConfigRegister read = FSM->AdcConfig;
	printf("\nBinaryFSMAdcConfigCommand Replying:");
	read.formatf();
	printf(".\n\n");	
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMAdcConfigRegister, 0, &read, sizeof(AdcConfigRegister));
    return(ParamsLen);
}

int8_t BinaryFSMAccumConfigCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (ParamsLen >= sizeof(AccumulatorConfigRegister))
	{
		const AccumulatorConfigRegister* val = (const AccumulatorConfigRegister*)Params;
		printf("\nBinaryFSMAccumConfigCommand Setting to:");
		val->formatf();
		printf(".\n\n");
		FSM->AccumConfig = *val;
	}
	AccumulatorConfigRegister read = FSM->AccumConfig;
	printf("\nBinaryFSMAccumConfigCommand Replying:");
	read.formatf();
	printf(".\n\n");	
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMAccumulatorConfigRegister, 0, &read, sizeof(AccumulatorConfigRegister));
    return(ParamsLen);
}

int8_t BinaryFSMDacConfigCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (ParamsLen >= sizeof(DacConfigRegister))
	{
		const DacConfigRegister* val = (const DacConfigRegister*)Params;
		printf("\nBinaryFSMDacConfigCommand Setting to:");
		val->formatf();
		printf(".\n\n");
		FSM->DacConfig = *val;
	}
	DacConfigRegister read = FSM->DacConfig;
	printf("\nBinaryFSMDacConfigCommand Replying:");
	read.formatf();
	printf(".\n\n");	
	TxBinaryPacket(Argument, CGraphPayloadTypeFSMDacConfigRegister, 0, &read, sizeof(DacConfigRegister));
    return(ParamsLen);
}
