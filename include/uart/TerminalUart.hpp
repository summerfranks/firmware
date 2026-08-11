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
// Permission granted for perpetual non-exclusive end-use by the University of Arizona August 1, 2020
//


#pragma once
#ifndef _TerminalUart_H_
#define _TerminalUart_H_

#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <string>
#include <cstring>

using namespace std;

#include "fixedqueue.hpp"
//~ #include <queue> //Using std::queue calls malloc and screws everything up....

#include "uart/IUart.h"
#include "uart/IUartParser.hpp"

#include "format/formatf.h"

#include "uart/CmdSystem.hpp"

//#include "rf/IPktSender.h"

extern "C"
{
  extern int stdio_hook_putc(int ch);
};

const char CHAR_BAK = 0x08;
const char CHAR_DEL = 0x7F;
const char CHAR_ESC = 0x1B;
const char CHAR_TAB = 0x09;

struct RTSCallback
{
	virtual bool RTS() { return(true); }
	virtual ~RTSCallback() { }
};

static RTSCallback NoRTS;

static const char* NoPrefix = (const char*)(0);

static const char* (*NoPrompt)() __attribute__ ((used)) = 0;

template<uint16_t txbufferlenbytes, uint16_t rxbufferlenbytes> struct TerminalUart : IUartParser //, public IPktSender
{
	//This is where the received characters go while we are building a line up from the input
	char RxBuffer[rxbufferlenbytes] __attribute__((aligned(4)));
	fixedqueue<char, txbufferlenbytes> TxBuffer;
	//~ std::queue<char> TxBuffer; //Using std::queue calls malloc and screws everything up....
	uint16_t RxCount;
	uint16_t TxCount;
	bool Echo;
	bool StdEcho;
	char LastC;
	bool UseCrLf;
	bool BlockOnTxBuffFull;
	//~ IUart& Pinout;
	const Cmd* Cmds;
	size_t NumCmds;
	const char* (*TerminalUartPrompt)();
	RTSCallback& RTSPinout;
	const char* Prefix;
	uint16_t StrlenPrefix;
	bool Verbose;
	
	TerminalUart(class IUart& pinout, const Cmd* cmds, const size_t numcmds, const char* (*terminaluartprompt)() = 0, struct RTSCallback& rts = NoRTS, const char* prefix = NoPrefix, const uint16_t strlenprefix = 0, const bool verbose = true)
		:
			IUartParser(pinout),
		    TxBuffer(),
			RxCount(0),
			TxCount(0),
			Echo(true),
			StdEcho(false),
			LastC('\0'),
			UseCrLf(false),
			BlockOnTxBuffFull(true),
			//~ Pinout(pinout),
			Cmds(cmds),
			NumCmds(numcmds),
			TerminalUartPrompt(terminaluartprompt),
			RTSPinout(rts),
			Prefix(prefix),
			StrlenPrefix(strlenprefix),
			Verbose(verbose)			
	{
		
	}

	int Init()
	{
		RxCount = 0;
		TxCount = 0;
		memset(RxBuffer, '\0', rxbufferlenbytes);
		TxBuffer.clear();
		return(0);
	}

	void Prompt()
	{
		if (0 != TerminalUartPrompt)
		{
			this->puts((*TerminalUartPrompt)());
		}
	}

	//Set a new prompt...
	void Prompt(const char* (*terminaluartprompt)()) { TerminalUartPrompt = terminaluartprompt; }
	
	void SetVerbose(const bool verbose) { Verbose = verbose; }

	void SetEcho(bool echostate)
	{
		Echo=echostate;
	}
	
	void StdOutEcho(bool echostate)
	{
		StdEcho=echostate;
	}

	void SetCrLfOrLf(bool crlf)
	{
		UseCrLf = crlf;
	}

	void SetBlockOnTxBuffFull(bool block)
	{
		BlockOnTxBuffFull = block;
	}

	void SetPrefix(const char* prefix)
	{
		Prefix = prefix;
	}

	//Warning! Warning!  As currently incarnated, Flush() has been shown to take 12mS to complete...
	void Flush()
	{
		//This effectively clears the RxBuffer
		RxCount = 0;
		memset(RxBuffer, '\0', rxbufferlenbytes);
		
		for(uint16_t i = 0; i < (txbufferlenbytes); i++)  //ok, so tx + rx is usually double, but no max() defined...
		{
			ProcessTx();
		}
	}

	char put(char c)
	{
		if ('\r' == c) { return(c); }

		//~ if (BlockOnTxBuffFull)
		//~ {
			//~ while (TxBuffer.full()) { ProcessTx(); }
		//~ }

		//~ if ( (UseCrLf) && ('\n' == c) ) { TxBuffer.push('\r'); } //actually buffering this causes messages from terminal uart and stdlib putc hook to interleave, leading to mishmash...
		if ( (UseCrLf) && ('\n' == c) ) { Pinout.putcqq('\r'); }

		//~ if (BlockOnTxBuffFull)
		//~ {
			//~ while (TxBuffer.full()) { ProcessTx(); }
		//~ }

		//~ TxBuffer.push(c);
		Pinout.putcqq(c);

		return(c);
	}

	void puts(const char*s, unsigned int maxlen = (unsigned int)(-1))
	{
		for(unsigned int pos = 0; ((pos < maxlen) && (TxCount < txbufferlenbytes) ); pos++)
		{
			if ('\0' == s[pos]) { break; }
			this->put(s[pos]);
		}
	}

	void formatf(const char *format, ...)
	{
		char s[txbufferlenbytes];
		va_list arg;
		va_start (arg, format);
		::sformatf(s, format, arg);
		this->puts(s);
		va_end (arg);
	}

	bool ProcessTx()
	{
		bool Processed = false;
		
		if (RTSPinout.RTS())
		{
			if (!(TxBuffer.empty()))
			{
				char c = '\0';

				Processed = true;
				//~ c = TxBuffer.front(); //old way
				//~ TxBuffer.pop(); //old way
				TxBuffer.pop(c); //new way
				Pinout.putcqq(c);
			}
		}
		
		return(Processed);
	}

	bool ProcessRx()
	{
		bool Parsed = false;

		//Talk to the debug DbgUart & do commands...
        unsigned int len = maybegetline(); //checks and buffers current string
        if (len > 0)
        {			
			if (RxCount >= rxbufferlenbytes) { RxCount = rxbufferlenbytes - 1; }
			
			RxBuffer[RxCount] = '\0';
			
			//~ if (Verbose) 
			//~ { 
			//~ //formatf seems not to work within TerminalUart...
				//~ formatf("\n\nTerminalUart::ProcessRx(): Line: \"%s\"\n", RxBuffer); 
			//~ }
			
            //See if the line contains anything useful
			if (Verbose)
			{
				Parsed = ParseCmd(RxBuffer, RxCount, Cmds, NumCmds, false, Prefix, StrlenPrefix, false, this);
			}
			else
			{
				Parsed = ParseCmd(RxBuffer, RxCount, Cmds, NumCmds, true, Prefix, StrlenPrefix, false, this);
			}

			RxCount = 0;  //empty the linebuffer

            //print new prompt...
			if ( (Parsed) && (0 != TerminalUartPrompt) )
			{
            	this->puts((*TerminalUartPrompt)());
			}
        }
		
		return(Parsed);
	}

	bool Process() override
	{
		ProcessTx();
		return(ProcessRx());
	}

	bool eof()
	{
		if (0 != RxCount) { return(false); }

		char c = maybegetc();
		if ((char)(-2) != c)
		{
			if (RxCount >= rxbufferlenbytes) { RxCount = rxbufferlenbytes - 1; }
			RxBuffer[RxCount] = c; //move to the next char in the buffer
			RxCount++;
			return(false);
		}

		return(true);
	}

	char get()
	{
		if (RxCount >= rxbufferlenbytes) { RxCount = rxbufferlenbytes - 1; }
		if (RxCount > 0)
		{
			RxCount--;
			return(RxBuffer[RxCount]);
		}

		char c = Pinout.getcqq();
		LastC = c;

		if ('\r' == c) { UseCrLf = true; }
		if ( ('\n' == c) && ('\r' != LastC) ) { UseCrLf = false; }

		return(c);
	}

	char maybegetc()
	{
		if ( !(Pinout.dataready()) ) return -2;

		char c = Pinout.getcqq();
		
		if (c < 8) return -2;
		if (c > 127) return -2;
		
		LastC = c;

		if ('\r' == c) { UseCrLf = true; }
		if ( ('\n' == c) && ('\r' != LastC) ) { UseCrLf = false; }

		//local Echo...
		if ( (Echo == true) && (CHAR_TAB != c) ) //local Echo on
		{
			Pinout.putcqq(c);
		}
		if (StdEcho == true) //local Echo on
		{
			stdio_hook_putc(c);
		}

		return ( c );
	}

	int maybegetline()
	{
		char ch = maybegetc();

		if ( ((char)-2) == ch) { return(0); }
		
		if (RxCount >= rxbufferlenbytes) { RxCount = rxbufferlenbytes - 1; }

		//EOL (\r\n or \n)
		if ('\n' == ch)
		{
			RxBuffer[RxCount] = '\0'; //terminate the string correctly
			return(RxCount);
		}

		//Backsp/del - remove a character
		if ( (CHAR_BAK == ch) || (CHAR_DEL == ch) )
		{
			//just delete the last character
			--RxCount;
			if (RxCount >= rxbufferlenbytes) { RxCount = 0; }
			RxBuffer[RxCount] = '\0'; //terminate the string correctly
			return(0);
		}

		//Esc - delete the current line
		if (CHAR_ESC == ch)
		{
			//just delete the line
			RxCount = 0;
			RxBuffer[RxCount] = '\0'; //terminate the string correctly
			return(0);
		}

		//tab - re-input the last line
		if (CHAR_TAB == ch) {

			RxCount = strnlen(RxBuffer, rxbufferlenbytes);

			//get rid of eol
			if ('\n' == RxBuffer[RxCount]) { RxCount--; }
			if ('\r' == RxBuffer[RxCount]) { RxCount--; }
			
			if (RxCount >= rxbufferlenbytes) { RxCount = rxbufferlenbytes - 1; }

			RxBuffer[RxCount] = '\0'; //terminate the string correctly

			//let the user see what they wrote
			for (size_t i = 0; i < RxCount; i++) { Pinout.putcqq(RxBuffer[i]); }

			return(0); //so the user can edit the line
		}

		RxBuffer[RxCount] = ch; //move to the next char in the buffer
		RxCount++;

		//taking care of when the buffer overflows by just throwing chars away - if this is undesirable, set blockontxbufferfull() to true.
		if (RxCount >= rxbufferlenbytes) { RxCount = rxbufferlenbytes - 1; }

		return(0);
	}
	
	//~ virtual void SendPacket(const uint8_t* Packet, const size_t len) const
	//~ {
		//~ //formatf("\n\nTerminalUart::SendPacket()\n");
		
		//~ for (size_t i = 0; i < len; i++) { Pinout.putcqq(Packet[i]); }
	//~ }
};

#endif // _TerminalUart_H_
