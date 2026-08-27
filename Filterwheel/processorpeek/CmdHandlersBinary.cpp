//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <inttypes.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <unordered_map>
using namespace std;

#include "format/formatf.h"

#include "uart/BinaryUart.hpp"

#include "cgraph/CGraphPacket.hpp"

#include "cgraph/CGraphFWHardwareInterface.hpp"
extern CGraphFWHardwareInterface* volatile FW;	

#include "MonitorAdc.hpp"

#include "FilterWheel.hpp"

#include "MainBuildNum"

#include "CmdTableBinary.hpp"

int8_t BinaryVersionCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	//(Don't validate version; always reply, even though it will cause a mess, so everyone knows we're here!)
	
    CGraphVersionPayload Version;
    Version.SerialNum = 0;
	Version.ProcessorFirmwareBuildNum = BuildNum;
	Version.FPGAFirmwareBuildNum = 0;
	if (FW) 
	{ 
		Version.SerialNum = FW->DeviceSerialNumber; 
		Version.FPGAFirmwareBuildNum = FW->FpgaFirmwareBuildNumber; 
	}
    formatf("\nBinaryVersionCommand: Sending response (%u bytes): ", sizeof(CGraphVersionPayload));
    CGraphVersionPayload(Version).formatf();
    formatf("\n");
    TxBinaryPacket(Argument, CGraphPayloadTypeVersion, 0, &Version, sizeof(CGraphVersionPayload));
    return(ParamsLen);
}

int8_t BinaryFWHardwareControlStatusCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	formatf("\nBinaryFWHardwareControlStatusCommand: processing(%u)...\n\n", ParamsLen);
	
	if ( (nullptr != Params) && (ParamsLen >= (sizeof(CGraphFWHardwareControlRegister))) )
	{
		const CGraphFWHardwareControlRegister* HCR = reinterpret_cast<const CGraphFWHardwareControlRegister*>(Params);
		
		formatf("\nBinaryFWHardwareControlStatusCommand: Setting to ");
		HCR->formatf();
		formatf("\n");
		
		FW->ControlRegister = (*HCR).all;	
	}
	
	formatf("\nBinaryFWHardwareControlStatusCommand: Replying: ");
	CGraphFWHardwareControlRegister(FW->ControlRegister).formatf();
	formatf("\n");
		
	TxBinaryPacket(Argument, CGraphPayloadTypeFWHardwareControlStatus, 0, &(FW->ControlRegister), sizeof(CGraphFWHardwareControlRegister));

    return(ParamsLen);
}

int8_t BinaryFWMotorControlStatusCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	formatf("\nBinaryFWMotorControlStatusCommand: processing(%u)...\n\n", ParamsLen);
	
	if ( (nullptr != Params) && (ParamsLen >= (sizeof(CGraphFWMotorControlStatusRegister))) )
	{
		const CGraphFWMotorControlStatusRegister* MCSR = reinterpret_cast<const CGraphFWMotorControlStatusRegister*>(Params);
		
		formatf("\nBinaryFWMotorControlStatusCommand: Setting to ");
		MCSR->formatf();
		formatf("\n");
		
		FW->MotorControlStatus = (*MCSR).all;	
	}
	
	formatf("\nBinaryFWMotorControlStatusCommand: Replying: ");
	CGraphFWMotorControlStatusRegister(FW->MotorControlStatus).formatf();
	formatf("\n");
		
	TxBinaryPacket(Argument, CGraphPayloadTypeFWMotorControlStatus, 0, &(FW->MotorControlStatus), sizeof(CGraphFWMotorControlStatusRegister));

    return(ParamsLen);
}
	
int8_t BinaryFWPositionSenseControlStatusCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	formatf("\nBinaryFWPositionSenseControlStatusCommand: processing(%u)...\n\n", ParamsLen);
	
	formatf("\nBinaryFWPositionSenseControlStatusCommand: Replying: ");
	CGraphFWPositionSenseRegister(FW->PositionSensors).formatf();
	formatf("\n");
		
	TxBinaryPacket(Argument, CGraphPayloadTypeFWPositionSenseControlStatus, 0, &(FW->PositionSensors), sizeof(CGraphFWPositionSenseRegister));

    return(ParamsLen);
}

int8_t BinaryFWPositionStepsCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	uint16_t PosSteps[48];
	
	formatf("\nBinaryFWPositionStepsCommand: processing(%u)...\n\n", ParamsLen);
	
	formatf("\nBinaryFWPositionStepsCommand: Replying: ");

	formatf("\nPosDetHomeA: "); CGraphFWPositionStepRegister(FW->PosDetHomeA).formatf(); PosSteps[0] = CGraphFWPositionStepRegister(FW->PosDetHomeA).OnStep; PosSteps[1] = CGraphFWPositionStepRegister(FW->PosDetHomeA).OffStep;
	formatf("\nPosDetA0: "); CGraphFWPositionStepRegister(FW->PosDetA0).formatf(); PosSteps[2] = CGraphFWPositionStepRegister(FW->PosDetA0).OnStep; PosSteps[3] = CGraphFWPositionStepRegister(FW->PosDetA0).OffStep;
	formatf("\nPosDetA1: "); CGraphFWPositionStepRegister(FW->PosDetA1).formatf(); PosSteps[4] = CGraphFWPositionStepRegister(FW->PosDetA1).OnStep; PosSteps[5] = CGraphFWPositionStepRegister(FW->PosDetA1).OffStep;
	formatf("\nPosDetA2: "); CGraphFWPositionStepRegister(FW->PosDetA2).formatf(); PosSteps[6] = CGraphFWPositionStepRegister(FW->PosDetA2).OnStep; PosSteps[7] = CGraphFWPositionStepRegister(FW->PosDetA2).OffStep;
	
	formatf("\nPosDetHomeB: "); CGraphFWPositionStepRegister(FW->PosDetHomeB).formatf(); PosSteps[8] = CGraphFWPositionStepRegister(FW->PosDetHomeB).OnStep; PosSteps[9] = CGraphFWPositionStepRegister(FW->PosDetHomeB).OffStep;
	formatf("\nPosDetB0: "); CGraphFWPositionStepRegister(FW->PosDetB0).formatf(); PosSteps[10] = CGraphFWPositionStepRegister(FW->PosDetB0).OnStep; PosSteps[11] = CGraphFWPositionStepRegister(FW->PosDetB0).OffStep;
	formatf("\nPosDetB1: "); CGraphFWPositionStepRegister(FW->PosDetB1).formatf(); PosSteps[12] = CGraphFWPositionStepRegister(FW->PosDetB1).OnStep; PosSteps[13] = CGraphFWPositionStepRegister(FW->PosDetB1).OffStep;
	formatf("\nPosDetB2: "); CGraphFWPositionStepRegister(FW->PosDetB2).formatf(); PosSteps[14] = CGraphFWPositionStepRegister(FW->PosDetB2).OnStep; PosSteps[15] = CGraphFWPositionStepRegister(FW->PosDetB2).OffStep;
	
	formatf("\nPosDet0A: "); CGraphFWPositionStepRegister(FW->PosDet0A).formatf(); PosSteps[16] = CGraphFWPositionStepRegister(FW->PosDet0A).OnStep; PosSteps[17] = CGraphFWPositionStepRegister(FW->PosDet0A).OffStep;
	formatf("\nPosDet1A: "); CGraphFWPositionStepRegister(FW->PosDet1A).formatf(); PosSteps[18] = CGraphFWPositionStepRegister(FW->PosDet1A).OnStep; PosSteps[19] = CGraphFWPositionStepRegister(FW->PosDet1A).OffStep;
	formatf("\nPosDet2A: "); CGraphFWPositionStepRegister(FW->PosDet2A).formatf(); PosSteps[20] = CGraphFWPositionStepRegister(FW->PosDet2A).OnStep; PosSteps[21] = CGraphFWPositionStepRegister(FW->PosDet2A).OffStep;
	formatf("\nPosDet3A: "); CGraphFWPositionStepRegister(FW->PosDet3A).formatf(); PosSteps[22] = CGraphFWPositionStepRegister(FW->PosDet3A).OnStep; PosSteps[23] = CGraphFWPositionStepRegister(FW->PosDet3A).OffStep;
	formatf("\nPosDet4A: "); CGraphFWPositionStepRegister(FW->PosDet4A).formatf(); PosSteps[24] = CGraphFWPositionStepRegister(FW->PosDet4A).OnStep; PosSteps[25] = CGraphFWPositionStepRegister(FW->PosDet4A).OffStep;
	formatf("\nPosDet5A: "); CGraphFWPositionStepRegister(FW->PosDet5A).formatf(); PosSteps[26] = CGraphFWPositionStepRegister(FW->PosDet5A).OnStep; PosSteps[27] = CGraphFWPositionStepRegister(FW->PosDet5A).OffStep;
	formatf("\nPosDet6A: "); CGraphFWPositionStepRegister(FW->PosDet6A).formatf(); PosSteps[28] = CGraphFWPositionStepRegister(FW->PosDet6A).OnStep; PosSteps[29] = CGraphFWPositionStepRegister(FW->PosDet6A).OffStep;
	formatf("\nPosDet7A: "); CGraphFWPositionStepRegister(FW->PosDet7A).formatf(); PosSteps[30] = CGraphFWPositionStepRegister(FW->PosDet7A).OnStep; PosSteps[31] = CGraphFWPositionStepRegister(FW->PosDet7A).OffStep;
	
	formatf("\nPosDet0B: "); CGraphFWPositionStepRegister(FW->PosDet0B).formatf(); PosSteps[32] = CGraphFWPositionStepRegister(FW->PosDet0B).OnStep; PosSteps[33] = CGraphFWPositionStepRegister(FW->PosDet0B).OffStep;
	formatf("\nPosDet1B: "); CGraphFWPositionStepRegister(FW->PosDet1B).formatf(); PosSteps[34] = CGraphFWPositionStepRegister(FW->PosDet1B).OnStep; PosSteps[35] = CGraphFWPositionStepRegister(FW->PosDet1B).OffStep;
	formatf("\nPosDet2B: "); CGraphFWPositionStepRegister(FW->PosDet2B).formatf(); PosSteps[36] = CGraphFWPositionStepRegister(FW->PosDet2B).OnStep; PosSteps[37] = CGraphFWPositionStepRegister(FW->PosDet2B).OffStep;
	formatf("\nPosDet3B: "); CGraphFWPositionStepRegister(FW->PosDet3B).formatf(); PosSteps[38] = CGraphFWPositionStepRegister(FW->PosDet3B).OnStep; PosSteps[39] = CGraphFWPositionStepRegister(FW->PosDet3B).OffStep;
	formatf("\nPosDet4B: "); CGraphFWPositionStepRegister(FW->PosDet4B).formatf(); PosSteps[40] = CGraphFWPositionStepRegister(FW->PosDet4B).OnStep; PosSteps[41] = CGraphFWPositionStepRegister(FW->PosDet4B).OffStep;
	formatf("\nPosDet5B: "); CGraphFWPositionStepRegister(FW->PosDet5B).formatf(); PosSteps[42] = CGraphFWPositionStepRegister(FW->PosDet5B).OnStep; PosSteps[43] = CGraphFWPositionStepRegister(FW->PosDet5B).OffStep;
	formatf("\nPosDet6B: "); CGraphFWPositionStepRegister(FW->PosDet6B).formatf(); PosSteps[44] = CGraphFWPositionStepRegister(FW->PosDet6B).OnStep; PosSteps[45] = CGraphFWPositionStepRegister(FW->PosDet6B).OffStep;
	formatf("\nPosDet7B: "); CGraphFWPositionStepRegister(FW->PosDet7B).formatf(); PosSteps[46] = CGraphFWPositionStepRegister(FW->PosDet7B).OnStep; PosSteps[47] = CGraphFWPositionStepRegister(FW->PosDet7B).OffStep;
	
	TxBinaryPacket(Argument, CGraphPayloadTypeFWPositionSteps, 0, PosSteps, 48 * sizeof(uint16_t));

    return(ParamsLen);
}

int8_t BinaryFWTelemetryADCCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	formatf("\nBinaryFWTelemetryADCCommand: processing(%u)...\n\n", ParamsLen);

	CGraphFWTelemetryPayload Status;
	
	Status.P1V2 = MonitorAdc.GetP1V2();
	Status.P2V2 = MonitorAdc.GetP2V2();
	Status.P28V = MonitorAdc.GetP28V();
	Status.P2V5 = MonitorAdc.GetP2V5();
	Status.P6V = MonitorAdc.GetP6V();
	Status.P5V = MonitorAdc.GetP5V();
	Status.P3V3D = MonitorAdc.GetP3V3D();
	Status.P4V3 = MonitorAdc.GetP4V3();
	Status.P2I2 = MonitorAdc.GetP2I2();
	Status.P4I3 = MonitorAdc.GetP4I3();
	Status.P6I = MonitorAdc.GetP6I();

	formatf("\n\nBinaryFWTelemetryADCCommand: CurrentValues:\n\n");
	
	formatf("P1V2: %3.6lf V\n", Status.P1V2);
	formatf("P2V2: %3.6lf V\n", Status.P2V2);
	formatf("P28V: %3.6lf V\n", Status.P28V);
	formatf("P2V5: %3.6lf V\n", Status.P2V5);
	formatf("P6V: %3.6lf V\n", Status.P6V);
	formatf("P5V: %3.6lf V\n", Status.P5V);
	formatf("P3V3D: %3.6lf V\n", Status.P3V3D);
	formatf("P4V3: %3.6lf V\n", Status.P4V3);
	formatf("P2I2: %3.6lf V\n", Status.P2I2);
	formatf("P4I3: %3.6lf V\n", Status.P4I3);
	formatf("P6I: %3.6lf V\n", Status.P6I);

	
	formatf("\nBinaryFWTelemetryADCCommand: Replying...\n");
	TxBinaryPacket(Argument, CGraphPayloadTypeFWTelemetry, 0, &Status, sizeof(CGraphFWTelemetryPayload));

	return(ParamsLen);
}

int8_t BinaryFWFilterSelectCommand(const uint32_t Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	uint32_t FilterSelect = 0;
	
	formatf("\nBinaryFWFilterSelectCommand: processing(%u)...\n\n", ParamsLen);
	
	if ( (nullptr != Params) && (ParamsLen >= (sizeof(uint32_t))) )
	{
		FilterSelect = *(const uint32_t*)Params;
		
		if (FilterSelect > FWMaxPosition)
		{
			formatf("\nBinaryFWFilterSelectCommand: Invalid position requested: %lu; max valid position: %lu; assuming we've been requested to re-home wheel\n", FilterSelect, FWMaxPosition);
			FWHome();
			FilterSelect = (uint32_t)-1; //-1 means we're in motion
			TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &FilterSelect, sizeof(uint32_t));
			return(ParamsLen);
		}
		
		uint32_t response = (uint32_t)-1; //-1 means we're in motion
		TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &response, sizeof(uint32_t));
		formatf("\nBinaryFWFilterSelectCommand: moving to: %lu\n", FilterSelect);
		FWSeekPosition(FilterSelect);
		if (!ValidateFWPosition())
		{
			response = (uint32_t)-2; //-2 means invalid position
			TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &response, sizeof(uint32_t));		
			formatf("\n\nBinaryFWFilterSelectCommand: move failed!\n");
			FWHome();
			formatf("\n\nBinaryFWFilterSelectCommand: moving to: %lu\n", FilterSelect);
			FWSeekPosition(FilterSelect);		
			//sure hope it worked the second time, cause I'm not sure we have the werewithal to try recursively...
		}
		response = (uint32_t)FilterSelect; //-1 means we're in motion
		TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &response, sizeof(uint32_t));
		return(ParamsLen);
	}
	
	//if we get here they must've wanted to know where we are
	formatf("\n\nBinaryFWFilterSelectCommand: querying current position...\n");
	
	//Is motor moving?
	CGraphFWMotorControlStatusRegister MCSR;
	MCSR = FW->MotorControlStatus;
	if (MCSR.SeekStep != MCSR.CurrentStep) 
	{
		formatf("\n\nBinaryFWFilterSelectCommand: motor is in motion to target position: %lu\n", FWPosition);
		FilterSelect = (uint32_t)-1; //-1 means we're in motion
		TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &FilterSelect, sizeof(uint32_t));
		return(ParamsLen);
	}
	
	//If not, do we have any idea where we are?
	if (!ValidateFWPosition())
	{
		formatf("\n\nBinaryFWFilterSelectCommand: current position invalid!!\n");
		FilterSelect = (uint32_t)-2; //-2 means we have no idea where we are!
		TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &FilterSelect, sizeof(uint32_t));
		FWHome();
		return(ParamsLen);
	}
	
	//If we get here we are where we say we are, and it's all shiny, cap'n!
	formatf("\n\nBinaryFWFilterSelectCommand: current position: %lu\n", FWPosition);
	FilterSelect = FWPosition;
	TxBinaryPacket(Argument, CGraphPayloadTypeFWFilterSelect, 0, &FilterSelect, sizeof(uint32_t));
		
    return(ParamsLen);
}

