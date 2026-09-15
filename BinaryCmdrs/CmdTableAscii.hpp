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
/// $Source: /raincloud/src/clients/UACGraph/Zeus/Zeus3/firmware/arm/main/CmdTable.hpp,v $
/// $Revision: 1.27 $
/// $Date: 2010/06/08 23:54:01 $
/// $Author: summer $

#include <stdint.h>

#include "uart/CmdSystem.hpp"

//App Cmds
int8_t ExitCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t HelpCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DebugCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FloodCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

//General Cmds
int8_t VersionCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

//FSM Cmds
int8_t FSMDacsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMAdcsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMTelemetryCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMCirclesCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMGoXYCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMControlRegisterCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMConfigAdcCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FSMConfigDacCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

//DM Cmds
int8_t DMDacCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMTelemetryCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMHVSwitchCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMDacConfigCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMMappingCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMShortPixelsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMDitherCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMLongPixelsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t DMAllPixelsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

//FW Cmds
int8_t FWHardwareControlStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWMotorControlStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWPositionSenseControlStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWPositionStepsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWTelemetryCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWFilterSelectCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWFilterTestCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

///The actual table (array) of commands for the system - links with CmdSystem.cpp.o
extern const Cmd AsciiCmds[];
extern const uint8_t NumAsciiCmds;
