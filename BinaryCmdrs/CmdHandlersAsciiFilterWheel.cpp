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
//kbhit
//~ #include <termios.h>

#include <sys/types.h>
#include <sys/stat.h>
//~ #include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
//~ #include <sys/mman.h>
#include <errno.h>
#include <unordered_map>
using namespace std;

//~ #include <mcheck.h>
#include "dbg/memwatch.h"

#include "uart/AsciiCmdUserInterfaceLinux.h"

//~ #include "../MonitorAdc.hpp"
//~ extern CGraphFSMMonitorAdc MonitorAdc;

#include "cgraph/CGraphPacket.hpp"

#include "uart/BinaryUart.hpp"
extern BinaryUart UartParser;

int8_t FWHardwareControlStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	printf("\n\nHardwareControlStatusCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWHardwareControlStatus, 0, NULL, 0);
    return(ParamsLen);
}
int8_t FWMotorControlStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	printf("\n\nMotorControlStatusCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWMotorControlStatus, 0, NULL, 0);
    return(ParamsLen);
}
int8_t FWPositionSenseControlStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	printf("\n\nPositionSenseControlStatusCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWPositionSenseControlStatus, 0, NULL, 0);
    return(ParamsLen);
}
int8_t FWPositionStepsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	printf("\n\nPositionStepsCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWPositionSteps, 0, NULL, 0);
    return(ParamsLen);
}
int8_t FWTelemetryCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
	printf("\n\nTelemetryCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWTelemetry, 0, NULL, 0);
    return(ParamsLen);
}

int8_t FWFilterSelectCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
    unsigned long A = 0;
	uint32_t FilterSelect;
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu", &A);
    if (numfound >= 1)
    {
		FilterSelect = A;
		TxBinaryPacket(&UartParser, CGraphPayloadTypeFWFilterSelect, 0, &FilterSelect, sizeof(uint32_t));
		
		printf("\n\nFilterSelectCommand: set to: %lu\n", A);
		return(ParamsLen);
    }

	//No params? Just query it...
	printf("\n\nFilterSelectCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWFilterSelect, 0, NULL, 0);
    return(ParamsLen);
}

int8_t FWFilterTestCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument)
{
    unsigned long A = 0;
	uint32_t FilterSelect;
	
	//Convert parameters
    int8_t numfound = sscanf(Params, "%lu", &A);
    if (numfound >= 1)
    {
		FilterSelect = A;
		TxBinaryPacket(&UartParser, CGraphPayloadTypeFWFilterTest, 0, &FilterSelect, sizeof(uint32_t));
		
		printf("\n\nFilterTestCommand: set to: %lu\n", A);
		return(ParamsLen);
    }

	//No params? Just query it...
	printf("\n\nFilterTestCommand: Querying...\n");
	TxBinaryPacket(&UartParser, CGraphPayloadTypeFWFilterTest, 0, NULL, 0);
    return(ParamsLen);
}
