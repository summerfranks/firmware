//
///           University of Arizona
///           Steward Observatory
///           UASAL - UA Space Astrophysics Usbratory
///           CAAO - Center for Astronomical Adaptive Optics
///           MagAOX
//

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <sys/types.h>
#include <algorithm>

#include "Delay.h"

#include "arm/BuildParameters.h"

#include "cgraph/CGraphPacket.hpp"

#include "cgraph/CGraphFWHardwareInterface.hpp"
extern CGraphFWHardwareInterface* volatile FW;

#include "format/formatf.h"

#include "CmdTableAscii.hpp"

#include "CmdTableBinary.hpp"

#include "uart/BinaryUart.hpp"

#include "eeprom/CircularFifoFlattenedFpga.hpp"
#include "uart/BinaryUartRingBuffer.hpp"

#include "uart/uart_pinout_fpga.hpp"

struct FPGABinaryUartCallbacks : public BinaryUartCallbacks
{
	FPGABinaryUartCallbacks() { }
	virtual ~FPGABinaryUartCallbacks() { }
	
	//Malformed/corrupted packet handler:
	virtual void InvalidPacket(const uint8_t* Buffer, const size_t& BufferLen)
	{ 
		if ( (NULL == Buffer) || (BufferLen < 1) ) { formatf("\nFPGAUartCallbacks: NULL(%u) InvalidPacket!\n\n", BufferLen); return; }
	
		size_t len = BufferLen;
		if (len > 32) { len = 32; }
		formatf("\nFPGAUartCallbacks: InvalidPacket! contents: :");
		for(size_t i = 0; i < len; i++) { formatf("%.2X:", Buffer[i]); }
		formatf("\n\n");
	}
	
	//Packet with no matching command handler:
	virtual void UnHandledPacket(const IPacket* Packet, const size_t& PacketLen)
	{ 
		if ( (NULL == Packet) || (PacketLen < sizeof(CGraphPacketHeader)) ) { formatf("\nFPGABinaryUartCallbacks: NULL(%u) UnHandledPacket!\n\n", PacketLen); return; }
		
		const CGraphPacketHeader* Header = reinterpret_cast<const CGraphPacketHeader*>(Packet);
		formatf("\nFPGAUartCallbacks: Unhandled packet(%u): ", PacketLen);
		Header->formatf();
		formatf("\n\n");
	}
	
	//In case we need to look at every packet that goes by...
	//~ virtual void EveryPacket(const IPacket& Packet, const size_t& PacketLen) { }
	
	//We just wanna see if this is happening, not much to do about it
	virtual void BufferOverflow(const uint8_t* Buffer, const size_t& BufferLen) 
	{ 
		//~ formatf("\nFPGABinaryUartCallbacks: BufferOverflow(%zu)!\n", BufferLen);
	}

} BinaryPacketCallbacks;

CGraphPacket FPGAUartProtocol;
uart_pinout_fpga FPGAUartPinout0(&(FW->UartStatusRegister0), &(FW->UartFifo0), &(FW->UartFifo0ReadData), &(FW->UartFifo0), '~');
uart_pinout_fpga FPGAUartPinout1(&(FW->UartStatusRegister1), &(FW->UartFifo1), &(FW->UartFifo1ReadData), &(FW->UartFifo1), '!');
uart_pinout_fpga FPGAUartPinout2(&(FW->UartStatusRegister2), &(FW->UartFifo2), &(FW->UartFifo2ReadData), &(FW->UartFifo2), '@');
uart_pinout_fpga FPGAUartPinout3(&(FW->UartStatusRegister3), &(FW->UartFifo3), &(FW->UartFifo3ReadData), &(FW->UartFifo3), '#');
uart_pinout_fpga FPGAUartPinoutUsb(&(FW->UartStatusRegisterUsb), &(FW->UartFifoUsb), &(FW->UartFifoUsbReadData), &(FW->UartFifoUsb), '$');

//~ BinaryUart(struct IUart& pinout, struct IPacket& packet, const Cmd* cmds, const size_t numcmds, struct BinaryUartCallbacks& callbacks, const bool verbose = true, const uint64_t serialnum = InvalidSerialNumber);
BinaryUart FpgaUartParser3(FPGAUartPinout1, FPGAUartProtocol, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);
BinaryUart FpgaUartParser2(FPGAUartPinout2, FPGAUartProtocol, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);
BinaryUart FpgaUartParser1(FPGAUartPinout1, FPGAUartProtocol, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);
//~ (ascii instead) BinaryUart FpgaUartParser0(FPGAUartPinout1, FPGAUartProtocol, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);
//~ (ascii instead) BinaryUart FpgaUartParserUsb(FPGAUartPinoutUsb, FPGAUartProtocol, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);

FpgaRingBufferCrcer FpgaCrc0(&(FW->Uart0CrcStartAddr), &(FW->Uart0CrcEndAddr), &(FW->Uart0CrcCurrentAddr), &(FW->Uart0Crc));
CircularFifoFlattenedFpga FifoFlattener(&(FW->Uart0RxFifoPeekPeekAddr), (uint8_t*)&(FW->Uart0RxFifoPeekPeekData), &(FW->Uart0RxFifoPeekReadAddr), &(FW->Uart0RxFifoPeekWriteAddr), 1024, &(FW->Uart0RxFifoPeekMultiPopAddr));
BinaryUartRingBuffer FpgaUartParser0(FifoFlattener, FpgaCrc0, FPGAUartProtocol, FPGAUartPinout0, BinaryCmds, NumBinaryCmds, BinaryPacketCallbacks, false);

#include "uart/TerminalUart.hpp"
char prompt[] = "\n\nESC-FW> ";
const char* TerminalUartPrompt()
{
    return(prompt);
}
//Handle incoming ascii cmds & binary packets from the usb
TerminalUart<16, 4096> DbgUartUsb(FPGAUartPinoutUsb, AsciiCmds, NumAsciiCmds, &TerminalUartPrompt, NoRTS, NoPrefix, false);
//~ TerminalUart<16, 4096> DbgUart485_0(FPGAUartPinout0, AsciiCmds, NumAsciiCmds, &TerminalUartPrompt, NoRTS, NoPrefix, false);

#include "MonitorAdc.hpp"
extern CGraphFWMonitorAdc MonitorAdc;

//Enable this if malloc problems occur (!!we shouldn't be using malloc, but c-libraries sometimes link it in!!)
//~ class MTracer
//~ {
//~ public:

//~ MTracer()
//~ {
//~ putenv("MALLOC_TRACE=/home/root/FWTrace.txt");
//~ mtrace(); /* Starts the recording of memory allocations and releases */
//~ }
//~ } mtracer;

extern "C"
{	
	unsigned long long fclk_for_delay_loops = 102000000;

	//This code is to make "syscalls.c" replace vendor's "newlib_stubs.c" and make printf() and friends connect to a real serial port in our actual hardware! Only useful if we can compile our own code from makefile and replace vendor's "softconsole" version...
	int stdio_hook_putc(int c) 
	{ 
		FPGAUartPinout0.putcqq(c); 
		FPGAUartPinoutUsb.putcqq(c);
		return(c);
	}

    void wooinit(void) __attribute__((constructor));

	//Does the current clib need this?
    void AtExit()
    {
        //~ mwTerm();
    }

	//Does the current clib need this?
    void mwOutFunc(int c)
    {
        putchar(c);
    }
};

bool Process()
{
    bool Bored = true;
	
	MonitorAdc.Process();
	
	//Enable this if we need to debug ascii and binary on the same uart (note: madness ensues!)
	//~ {
		//~ if (FPGAUartPinoutUsb.dataready())
		//~ {
			//~ Bored = false;
			
			//~ char c = FPGAUartPinoutUsb.getcqq();
			
			//~ UsbUartAscii.remoteputcqq(c);
			//~ UsbUartBinary.remoteputcqq(c);
		//~ }
		//~ if (UsbUartAscii.remotedataready()) { FPGAUartPinoutUsb.putcqq(UsbUartAscii.remotegetcqq()); }
		//~ if (UsbUartBinary.remotedataready()) { FPGAUartPinoutUsb.putcqq(UsbUartBinary.remotegetcqq()); }
	//~ }
	
    //~ if (FpgaUartParser3.Process()) { Bored = false; }    
	//~ if (FpgaUartParser2.Process()) { Bored = false; }    
	//~ if (FpgaUartParser1.Process()) { Bored = false; }    
	//~ if (FpgaUartParser0.Process()) { Bored = false; }    
	//~ if (FpgaUartParserUsb.Process()) { Bored = false; }    
	if (DbgUartUsb.Process()) { Bored = false; }    
    //~ if (DbgUart485_0.Process()) { Bored = false; }
	
    return(Bored);
}

void ProcessAllUarts()
{
	//~ FpgaUartParser3.Process();
	//~ FpgaUartParser2.Process();
	//~ FpgaUartParser1.Process();
	//~ FpgaUartParser0.Process();
	//~ FpgaUartParserUsb.Process();
	DbgUartUsb.Process();
	//~ DbgUart485_0.Process();
}

int main(int argc, char *argv[])
{	
    //Tell C lib (stdio.h) not to buffer output, so we can ditch all the fflush(stdout) calls...
    //~ setvbuf(stdout, NULL, _IONBF, 0);

    //~ if (argc > 2)

	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('\n');
	FPGAUartPinoutUsb.putcqq('H');
	FPGAUartPinoutUsb.putcqq('e');
	FPGAUartPinoutUsb.putcqq('l');
	FPGAUartPinoutUsb.putcqq('l');
	FPGAUartPinoutUsb.putcqq('o');
	FPGAUartPinoutUsb.putcqq(' ');
	FPGAUartPinoutUsb.putcqq('E');
    FPGAUartPinoutUsb.putcqq('S');
    FPGAUartPinoutUsb.putcqq('C');
    FPGAUartPinoutUsb.putcqq('-');
    FPGAUartPinoutUsb.putcqq('F');
    FPGAUartPinoutUsb.putcqq('W');
	FPGAUartPinoutUsb.putcqq('\n');

	//~ formatf("\n\nESC-FW: v%s.b%s; Offset of ControlRegister: 0x%.2lX, expected: 0x%.2lX.", GITVERSION, BUILDNUM, (unsigned long)offsetof(CGraphFWHardwareInterface, ControlRegister), 32UL);
	
	//~ ShowBuildParameters();

	//~ formatf("\nOffset of UartFifoUsb: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, UartFifoUsb), 116UL);
	//~ formatf("\nOffset of UartFifoUsbReadData: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, UartFifoUsbReadData), 172UL);
	//~ formatf("\nOffset of Uart0RxFifoPeekReadAddr: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, Uart0RxFifoPeekReadAddr), 332UL);
	//~ formatf("\nOffset of BaudDividers: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, BaudDividers), 64UL);
	//~ formatf("\nOffset of Uart0RxFifoPeekPeekData: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, Uart0RxFifoPeekPeekData), 344UL);
	//~ formatf("\nOffset of Uart0RxFifoPeekPeekAddr: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, Uart0RxFifoPeekPeekAddr), 340UL);
	formatf("\nOffset of Uart0CalcCrc: 0x%.2lX, expected: 0x%.2lX.", (unsigned long)offsetof(CGraphFWHardwareInterface, Uart0CalcCrc), 388UL);

	//~ FpgaUartParser0.Init();
	//~ FpgaUartParser1.Init();
	//~ FpgaUartParser2.Init();
	//~ FpgaUartParser3.Init();

	//~ FpgaUartParser0.Debug(true);
	//~ FpgaUartParser1.Debug(true);
	//~ FpgaUartParser2.Debug(true);
	//~ FpgaUartParser3.Debug(true);

	DbgUartUsb.Init();
	//~ DbgUart485_0.Init();

    DbgUartUsb.SetEcho(false);
    //~ DbgUart485_0.SetEcho(false);
	
	//~ MonitorAdc.SetMonitor(true);
	//~ MonitorAdc.SetMonitor(false);
	//~ MonitorAdc.Init();
	
	//~ uint8_t i = 0;
    while(true)
    {
		Process();
    }

    return(0);
}

//EOF
