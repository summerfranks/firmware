//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#pragma once

#include <stdint.h>

#include "uart/CmdSystem.hpp"

//Hardware Cmds
int8_t VersionCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t HelpCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t ReadFpgaCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t WriteFpgaCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FWStatusCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t SensorStepsCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t MotorCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FilterSelectCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t BISTCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t BaudDividersCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t PrintBuffersCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t MonitorSerialCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);
int8_t FpgaParserCommand(char const* Name, char const* Params, const size_t ParamsLen, const void* Argument);

///The actual table (array) of commands for the system - links with CmdSystem.cpp.o
extern const Cmd AsciiCmds[];
extern const uint8_t NumAsciiCmds;
