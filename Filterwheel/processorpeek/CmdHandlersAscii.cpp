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
//offsetof:
#include <cstddef>

#include <unordered_map>
using namespace std;

#include "Delay.h"

#include "cgraph/CGraphFWHardwareInterface.hpp"
extern CGraphFWHardwareInterface* volatile FW;	

#include "format/formatf.h"

#include "uart/BinaryUart.hpp"

#include "cgraph/CGraphPacket.hpp"

#include "MonitorAdc.hpp"

#include "FilterWheel.hpp"

#include "MainBuildNum"

#include "CmdTableAscii.hpp"

extern BinaryUart FpgaUartParser3;
extern BinaryUart FpgaUartParser2;
extern BinaryUart FpgaUartParser1;
//~ extern BinaryUart FpgaUartParser0;

#include "uart/uart_pinout_fpga.hpp"

extern uart_pinout_fpga FPGAUartPinout0;
extern uart_pinout_fpga FPGAUartPinout1;
extern uart_pinout_fpga FPGAUartPinout2;
extern uart_pinout_fpga FPGAUartPinout3;
extern uart_pinout_fpga FPGAUartPinoutUsb;

char Buffer[4096];

//Show user firmware version info
int8_t VersionCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (nullptr != FW)
	{
		//formatf("\n\nVersion: Serial Number: %.8X, Global Revision: %s; build number: %u on: %s; fpga build: %u.\n", FW->DeviceSerialNumber, GITVERSION, BuildNum, BuildTimeStr, FW->FpgaFirmwareBuildNumber);
		formatf("\n\nVersion: Serial Number: %.8X, Global Revision: %s; build number: %u on: %s; fpga build: %u.\n", FW->DeviceSerialNumber, "n/a", BuildNum, BuildTimeStr, FW->FpgaFirmwareBuildNumber);
	}
	else
	{
		//formatf("\n\nVersion: Global Revision: %s; build number: %u on: %s.\n", GITVERSION, BuildNum, BuildTimeStr);
	    formatf("\n\nVersion: Global Revision: %s; build number: %u on: %s.\n", "n/a", BuildNum, BuildTimeStr);
	}
	
    return(strlen(Params));
}

//Debug coommand - read raw address from fpga without regard to data type or contents
int8_t ReadFpgaCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	uint32_t RdFpgaBuf;

	//Convert parameter to an integer
    size_t addr = 0;
	int8_t numfound = sscanf(Params, "%zX", &addr);
    if (numfound < 1)
    {
		formatf("\nReadFpgaCommand: ");
		//~ for (addr = 0; addr <= 64; addr++)
		//~ for (addr = 0; addr <= sizeof(CGraphFWHardwareInterface); addr+=4)
		{
			RdFpgaBuf = *(((uint8_t*)FW)+addr);
			formatf("\n0x%.2zX: 0x%.2X ", addr, RdFpgaBuf);
			formatf("[%u]", RdFpgaBuf);
			//~ formatf(" ('%c')", RdFpgaBuf);
		}	
		formatf("\n\n");
    }
	else
	{
		addr -= (addr%4);
		RdFpgaBuf = *(((uint8_t*)FW)+addr);
		formatf("\nReadFpgaCommand: ");
		//~ formatf("\n%zu: 0x%.2X ", addr, RdFpgaBuf);
		formatf("\n0x%.2zX: 0x%.8lX ", addr, (unsigned long)RdFpgaBuf);
		formatf("[%lu]", (unsigned long)RdFpgaBuf);
		formatf(" ('%c')\n\n", RdFpgaBuf);
	}
	
	return(ParamsLen);
}

//Debug coommand - Write raw address to fpga without regard to data type or contents
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
	*(((uint8_t*)FW)+addr) = (uint32_t)val;

	formatf("\nWriteFpgaCommand: Wrote %lu to ", val);
	formatf("0x%.4zX.\n", addr);
	
	return(ParamsLen);
}

//Show all FPGA registers
int8_t FWStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphFWHardwareControlRegister HCR;
	CGraphFWMotorControlStatusRegister MCSR;
	CGraphFWPositionSenseRegister PSR;
	
	if (nullptr == FW)
	{
		formatf("\n\nFWStatusCommand: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	formatf("\n\nFWStatusCommand: Offset of MotorControlStatus: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, MotorControlStatus), 36UL);
	formatf("\nFWStatusCommand: Offset of PositionSensors: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, PositionSensors), 40UL);
	formatf("\nFWStatusCommand: Offset of ControlRegister: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, ControlRegister), 32UL);
	
	HCR = FW->ControlRegister;
	MCSR = FW->MotorControlStatus;
	PSR = FW->PositionSensors;
    
	formatf("\n\nFWStatusCommand: current values:\n");
	HCR.formatf();
	formatf("\n");
	MCSR.formatf();
	formatf("\n");
	PSR.formatf();
	formatf("\n");
	formatf("\n");
	
    return(ParamsLen);
}

//Show sensor step registers
int8_t SensorStepsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	if (nullptr == FW)
	{
		formatf("\n\nSensorStepsCommand: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	formatf("\n\nSensorStepsCommand: Offset of first Sensor Step: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, PosDetHomeA), 140UL);
	formatf("\nSensorStepsCommand: Offset of last Sensor Step: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, PosDet7B), 328UL);
	
	formatf("\n\nSensorStepsCommand: current values:\n");
	
	formatf("\nPosDetHomeA: \t"); FW->PosDetHomeA.formatf();
	formatf("\nPosDetA0:    \t"); FW->PosDetA0.formatf();
	formatf("\nPosDetA1:    \t"); FW->PosDetA1.formatf();
	formatf("\nPosDetA2:    \t"); FW->PosDetA2.formatf();
	
	formatf("\nPosDetHomeB: \t"); FW->PosDetHomeB.formatf();
	formatf("\nPosDetB0:    \t"); FW->PosDetB0.formatf();
	formatf("\nPosDetB1:    \t"); FW->PosDetB1.formatf();
	formatf("\nPosDetB2:    \t"); FW->PosDetB2.formatf();
	
	for(size_t i = 0; i < 4096; i++) { ProcessAllUarts(); }
	formatf("\n");
	formatf("\nPosDet0A: "); FW->PosDet0A.formatf();
	formatf("\nPosDet1A: "); FW->PosDet1A.formatf();
	formatf("\nPosDet2A: "); FW->PosDet2A.formatf();
	formatf("\nPosDet3A: "); FW->PosDet3A.formatf();
	formatf("\nPosDet4A: "); FW->PosDet4A.formatf();
	formatf("\nPosDet5A: "); FW->PosDet5A.formatf();
	formatf("\nPosDet6A: "); FW->PosDet6A.formatf();
	formatf("\nPosDet7A: "); FW->PosDet7A.formatf();
	
	for(size_t i = 0; i < 4096; i++) { ProcessAllUarts(); }
	formatf("\n");
	formatf("\nPosDet0B: "); FW->PosDet0B.formatf();
	formatf("\nPosDet1B: "); FW->PosDet1B.formatf();
	formatf("\nPosDet2B: "); FW->PosDet2B.formatf();
	formatf("\nPosDet3B: "); FW->PosDet3B.formatf();
	formatf("\nPosDet4B: "); FW->PosDet4B.formatf();
	formatf("\nPosDet5B: "); FW->PosDet5B.formatf();
	formatf("\nPosDet6B: "); FW->PosDet6B.formatf();
	formatf("\nPosDet7B: "); FW->PosDet7B.formatf();
	
	return(ParamsLen);	
}

//Query/Move motor position
int8_t MotorCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphFWMotorControlStatusRegister MCSR;
	unsigned long SeekStep;
	
	if (nullptr == FW)
	{
		formatf("\n\nMotorCommand: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu", &SeekStep);
    if (numfound >= 1)
    {
		//Turn things on
		CGraphFWHardwareControlRegister HCR;
		HCR.PosLedsEnA = 1;
		HCR.PosLedsEnB = 1;
		HCR.MotorEnable = 1;
		FW->ControlRegister = HCR;		
		
		MCSR.SeekStep = SeekStep;
		FW->MotorControlStatus = MCSR;		
		
		//Wait for it to move
		for (size_t i = 0; i < MotorFindHomeTimeoutMs; i++)
		{
			MCSR = FW->MotorControlStatus;
			if (MCSR.SeekStep == MCSR.CurrentStep) { break; }
			if (0 == (MCSR.CurrentStep % 25))
			{
				formatf("\n\nMotorCommand: moving:\n");
				MCSR.formatf();
				formatf("\n");	
			}
			delayms(1);
		}	

		formatf("\n\nMotorCommand: set to: %lu\n", SeekStep);
		
		//Turn things off
		HCR.PosLedsEnA = 0;
		HCR.PosLedsEnB = 0;
		HCR.MotorEnable = 0;
		FW->ControlRegister = HCR;		
    }
	
	MCSR = FW->MotorControlStatus;
	
	formatf("\n\nMotorCommand: current values:\n");
	MCSR.formatf();
	formatf("\n");
	
	return(ParamsLen);
}

//Change to a specific filter (0=sunsafe)
int8_t FilterSelectCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	unsigned long FilterSelect = 0;
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu", &FilterSelect);
    if (numfound >= 1)
    {
		if (FilterSelect > FWMaxPosition)
		{
			formatf("\n\nFilterSelectCommand: Invalid position requested: %lu; max valid position: %lu; assuming we've been requested to re-home wheel\n", FilterSelect, FWMaxPosition);
			FWHome();
			return(ParamsLen);
		}
		
		formatf("\n\nFilterSelectCommand: moving to: %lu\n", FilterSelect);
		FWSeekPosition(FilterSelect);
		if (!ValidateFWPosition())
		{
			formatf("\n\nFilterSelectCommand: move failed!\n");
			FWHome();
			formatf("\n\nFilterSelectCommand: moving to: %lu\n", FilterSelect);
			FWSeekPosition(FilterSelect);		
			//sure hope it worked the second time, cause I'm not sure we have the werewithal to try recursively...
		}
		return(ParamsLen);
    }
	
	//if we get here they must've wanted to know where we are
	formatf("\n\nFilterSelectCommand: querying current position...\n");
	
	//Is motor moving?
	CGraphFWMotorControlStatusRegister MCSR;
	MCSR = FW->MotorControlStatus;
	if (MCSR.SeekStep != MCSR.CurrentStep) 
	{
		formatf("\n\nFilterSelectCommand: motor is in motion to target position: %lu\n", FWPosition);
		return(ParamsLen);
	}
	
	//If not, do we have any idea where we are?
	if (!ValidateFWPosition())
	{
		formatf("\n\nFilterSelectCommand: current position invalid!! Re-homing wheel...\n");
		FWHome();
		return(ParamsLen);
	}
	
	//If we get here we are where we say we are, and it's all shiny, cap'n!
	formatf("\n\nFilterSelectCommand: current position: %lu\n", FWPosition);
	
	return(ParamsLen);
}

//Debug command - "Built In Safe Test"- contemnts/functiuonality may change without warning
int8_t BISTCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	{
		//Show the monitor A/D
		{
			//~ CGraphFWHardwareControlRegister HCR;
			//~ HCR.PosLedsEnA = 1;
			//~ HCR.PosLedsEnB = 1;
			//~ HCR.MotorEnable = 1;
			//~ HCR.ResetSteps = 1;
			//~ FW->ControlRegister = HCR;		
			//~ HCR.ResetSteps = 0;
			//~ FW->ControlRegister = HCR;		
			
			//~ CGraphFWMotorControlStatusRegister MCSR;
			//~ MCSR.SeekStep = 730;
			//~ FW->MotorControlStatus = MCSR;		
		}
		
		//~ //Test hardfault handler:
		//~ unsigned long key = 0;

		//~ //Convert parameters
		//~ int8_t numfound = sscanf(Params, "%lu", &key);
		//~ if ((numfound >= 1) && (key = 0xBAADC0DE) )
		//~ {

			//int* a = (int*)0x00000003;
			//(*a)++;
			//~ formatf("\n\nBIST: Magic key match! About to crash!!");
			//~ for (size_t i = 0; i < 4096; i++) { ProcessAllUarts(); }		
			//~ formatf("%d", *(((char*)FW)+3));
		//~ }
		//~ else
		//~ {
			//~ formatf("\n\nBIST: Magic key not found / incorrect; not testing crash handlers...\n");
		//~ }
		
		//~ FpgaRingBufferCrcer FpgaCrc0(&(FW->Uart0CrcStartAddr), &(FW->Uart0CrcEndAddr), &(FW->Uart0CrcCurrentAddr), &(FW->Uart0Crc));
		//~ CircularFifoFlattenedFpga FifoFlattener(&(FW->Uart0RxFifoPeekPeekAddr), (uint8_t*)&(FW->Uart0RxFifoPeekPeekData), &(FW->Uart0RxFifoPeekReadAddr), &(FW->Uart0RxFifoPeekWriteAddr), 1024, &(FW->Uart0RxFifoPeekMultiPopAddr));
		//~ BinaryUartRingBuffer FpgaUartParser0(FifoFlattener, FpgaCrc0, FPGAUartProtocol, FPGAUartPinout0, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);

		::formatf("\n\nBISTCommand: :");
		for(uint32_t i = 0; i < 64; i++)
		{
			FW->Uart0RxFifoPeekPeekAddr = i;
			uint32_t j = FW->Uart0RxFifoPeekPeekData;
			//~ uint32_t j = FW->Uart0RxFifoPeekPeekAddr;
			::formatf("%02X:", j);
		}
		::formatf("\n\n");

	}
	
	return(ParamsLen);
}

//Change hardware dividers for uarts; aka change the baud rate.
int8_t BaudDividersCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	CGraphBaudDividers iDividers;
	unsigned long A = 0, B = 0, C = 0, D = 0;
	
	if (nullptr == FW)
	{
		formatf("\n\nBaudDividers: Fpga interface is not initialized! Please call InitFpga first!.");
		return(ParamsLen);
	}
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu,%lu,%lu,%lu", &A, &B, &C, &D);
    if (numfound >= 4)
    {
		iDividers.Divider0 = A;
		iDividers.Divider1 = B;
		iDividers.Divider2 = C;
		iDividers.Divider3 = D;
		formatf("\n\nBaudDividers: setting to: %lu, %lu, %lu, %lu.\n", A, B, C, D);
		FW->BaudDividers = iDividers;
    }
	else
	{
		if (numfound >= 1)
		{
			iDividers.Divider0 = A;
			iDividers.Divider1 = A;
			iDividers.Divider2 = A;
			iDividers.Divider3 = A;
			formatf("\n\nBaudDividers: setting to: %lu, %lu, %lu, %lu.\n", A, A, A, A);
			FW->BaudDividers = iDividers;
		}
	}

	iDividers = FW->BaudDividers;
	A = iDividers.Divider0;
	B = iDividers.Divider1;
	C = iDividers.Divider2;
	D = iDividers.Divider3;
	formatf("\n\nBaudDividers: current values: %lu, %lu, %lu.\n", A, B, C, D);
	
	//~ formatf("\nBaudDividers: (331 = 9600, 83 = 38400, 55 = 57600, 27 = 115200, 13 = 230400, 7 = 460800, 3 = 921600)\n");
	
	double BaudClock = 102000000.0;
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

//Show current uart buffer contents
int8_t PrintBuffersCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	formatf("\nShowBuffersCommand: FpgaUartParser: ");
	FpgaUartParser3.formatf();
	FpgaUartParser2.formatf();
	FpgaUartParser1.formatf();
	FpgaUartParser0.formatf();
	//FpgaUartParserUsb.formatf();
	formatf("\n\n");
	return(ParamsLen);
}

//Show each raw byte from uarts as they are parsed
int8_t MonitorSerialCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	unsigned long port = 0;
	char seperator[8];
	char onoff;

	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu%2[,\t ]%c", &port, seperator, &onoff);
    if (numfound >= 4)
	{
	    bool OnOff = false;

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

int8_t FpgaParserCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	char onoff;

	//Convert parameters
    int8_t numfound = sscanf(Params, "[,\t ]%c", &onoff);
    if (numfound >= 1)
	{
	    bool OnOff = false;

		if ( ('C' == onoff) || ('c' == onoff) || ('T' == onoff) || ('t' == onoff) || ('1' == onoff) ) { OnOff = true; }
		
		formatf("\n\nFpgaParserCommand: Clearing parser pipeline: %c.\n", OnOff?'Y':'N');
		if (OnOff) { FW->Uart0RxFifoPeekMultiPopAddr = FW->Uart0RxFifoPeekWriteAddr; }
	}

	formatf("\n\nFpgaParserCommand: Pipeline: HeaderEnd(0x%lX), FooterEnd(0x%lX), PayloadType(0x%lX), PayloadLen(%lu), PacketCrc(0x%lX), CalcCrc(0x%lX)\n", (unsigned long)FW->Uart0HeaderEndPos, (unsigned long)FW->Uart0FooterEndPos, (unsigned long)FW->Uart0PayloadType, (unsigned long)FW->Uart0PayloadLen, (unsigned long)FW->Uart0PacketCrc, (unsigned long)FW->Uart0CalcCrc);

	return(strlen(Params));
}


//EOF

