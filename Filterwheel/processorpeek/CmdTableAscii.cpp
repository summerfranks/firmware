//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Labratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#include <stdint.h>

#include "uart/CmdSystem.hpp"

#include "MonitorAdc.hpp"

#include "CmdTableAscii.hpp"

///The actual table (array) of commands for the system - links with CmdSystem.cpp.o
const Cmd AsciiCmds[] =
{
	Cmd(
        "VERSION",
		"\"Version\": Shows hardware and firmware version info.",
		VersionCommand
    ),
    
	Cmd (
        "READFPGA",
        "ReadFpga <address>",
        ReadFpgaCommand
    ),

	Cmd (
        "WRITEFPGA",
        "WriteFpga <address>,<value>",
        WriteFpgaCommand
    ),
	
	Cmd (
        "R",
        "R(eadFpga) <address>",
        ReadFpgaCommand
    ),

	Cmd (
        "W",
        "W(riteFpga) <address>,<value>",
        WriteFpgaCommand
    ),

    Cmd(
        "FWSTATUS",
        "\"FWStatus <A>,<B>,<C>\": Sets/queries the FW D/A's (hexadecimal lsb units).",
        FWStatusCommand
    ),
	
	Cmd(
        "SENSORSTEPS",
        "\"SensorSteps <A>,<B>,<C>\": Sets/queries the FW D/A's (decimal voltage units).",
        SensorStepsCommand
    ),
	
	Cmd(
        "MOTOR",
        "\"Motor <A>,<B>,<C>\": Sets/queries the FW A/D's.",
        MotorCommand
    ),
	
	Cmd(
        "FILTERSELECT",
        "\"FilterSelect <1-8>\": Sets/queries the currently loaded filter; respose of 0 means wheel is in motion/currently seeking a position.",
        FilterSelectCommand
    ),
	
	Cmd(
        ScanMonitorAdcCmdString,
        ScanMonitorAdcHelp,
        ScanMonitorAdcCommand
    ),
	
	Cmd(
        "S",
        ScanMonitorAdcHelp,
        ScanMonitorAdcCommand
    ),
	
	Cmd(
        TestMonitorAdcCmdString,
        TestMonitorAdcHelp,
        TestMonitorAdcCommand
    ),
	
	Cmd(
        "T",
        TestMonitorAdcHelp,
        TestMonitorAdcCommand
    ),
	
	Cmd(
        CalibrateMonitorAdcCmdString,
        CalibrateMonitorAdcHelp,
        CalibrateMonitorAdcCommand
    ),
	
	Cmd(
        "BIST",
        "\"BIST\": Runs a self-test, logs values to terminal.",
        BISTCommand
    ),
		
	Cmd(
        "BAUDDIVIDERS",
        "\"BaudDividers < W | W, X, Y, Z >\": Set/query the divider to change the baudrate for each port...",
        BaudDividersCommand
    ),
	
	Cmd(
        "PRINTBUFFERS",
        "\"PrintBuffers\": Dump current contents of parsers for debug...",
        PrintBuffersCommand
    ),
	
	Cmd(
        "MONITORSERIAL",
        "\"MonitorSerial < 0 | 1 | 2 | 3 > <Y | N>\": Show/hide incoming serial bytes.",
        MonitorSerialCommand
    ),
	
	
	Cmd(
        "FPGAPARSER",
        "\"FpgaParser\": Debug Fpga Parsing Pipeline.",
        FpgaParserCommand
    ),
};

//Calculate the number of commands instanciated in the system - links with CmdSystem.cpp.o
const uint8_t NumAsciiCmds = sizeof(AsciiCmds) / sizeof(AsciiCmds[0]);
