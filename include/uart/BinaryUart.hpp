/** \file
 * \brief UART interface for binary packet communication
 *
 * \ingroup uart
 **/

#pragma once

#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>

#include "fixedqueue.hpp"
//~ #include <queue> //Using std::queue calls malloc and screws everything up....

#include "uart/IUart.h"

#include "format/formatf.h"

#include "uart/CmdSystem.hpp"

#include "uart/IProtocol.hpp"
#include "uart/IPacket.hpp"
#include "uart/IUartParser.hpp"

#include "BinaryUart.h"

/**
 * @struct BinaryUart
 *
 * BinaryUart manages a UART interface for binary packet communication.
 * It provides buffering for received bytes, detects packet boundaries, and processes
 * commands within received packets.
 *
 **/
struct BinaryUart : IUartParser
{
	// Constants for initial values
	static const uint16_t RxCountInit = 0; 				///< Initial count for received bytes.
	static const size_t PacketStartInit = 0;
	static const size_t PacketLenInit = 0;
        static const size_t PayloadLenInit = 0;
        static const size_t HeaderLenInit = 0;
        static const size_t FooterLenInit = 0;
	static const bool InPacketInit = false; 			///< Default in-packet status.
	static const bool debugDefault = false;
	static const char EmptyBufferChar = '\0'; 			///< Character to fill empty buffer space.
	static const size_t RxBufferLenBytes = 4096;
	static const size_t TxBufferLenBytes = 4096;
	static const uint64_t InvalidSerialNumber = 0xFFFFFFFFFFFFFFFFULL;

	size_t PacketEnd = 0; 								///< Position of the detected packet end.
    uint8_t RxBuffer[RxBufferLenBytes]; 				///< Buffer to store received characters.
    uint16_t RxCount;									///< Number of bytes currently in RxBuffer.

  //~ IUart& Pinout;										///< UART interface for data input.
  IPacket& Packet;									///< Packet structure for defining headers, footers, etc.
  const BinaryCmd* Cmds;								///< Array of commands
  size_t NumCmds;
  BinaryUartCallbacks& Callbacks;
  bool debug;
  bool InPacket;										///< Whether a packet is currently being processed.
  size_t PacketStart;
  size_t PacketLen;
  size_t PayloadLen;
  size_t HeaderLen;
  size_t FooterLen;
  uint64_t SerialNum;									///< Serial number for validating received packets.

    /**
     * @brief Constructs a BinaryUart object and initializes with given parameters.
     *
     * @param pinout    UART interface to use for receiving data.
     * @param packet    Packet structure defining header, footer, and payload format.
     * @param cmds      Array of available commands.
     * @param numcmds   Number of commands in the cmds array.
     * @param callbacks Callback functions for handling packet events.
     * @param verbose   Enable or disable verbose debug mode.
     * @param serialnum Optional initial serial number, defaulting to InvalidSerialNumber.
     */
    BinaryUart(class IUart& pinout, class IPacket& packet, const BinaryCmd* cmds, const size_t numcmds, struct BinaryUartCallbacks& callbacks, const bool verbose = true, const uint64_t serialnum = InvalidSerialNumber)
        :
		IUartParser(pinout),
		RxCount(RxCountInit),
        //~ Pinout(pinout),
		Packet(packet),
        Cmds(cmds),
        NumCmds(numcmds),
		Callbacks(callbacks),
		debug(debugDefault),
		//debug(true),
		InPacket(InPacketInit),
		PacketStart(PacketStartInit),
		PacketLen(PacketLenInit),
                PayloadLen(PayloadLenInit),
                HeaderLen(HeaderLenInit),
                FooterLen(FooterLenInit),
		//~ Argument(argument),
		SerialNum(serialnum)

    {
		Init(serialnum);
    }

    void Debug(bool dbg)
    {
        debug = dbg;
    }

    bool Debug() { return(debug); }

    /**
     * @brief Initializes the BinaryUart
     *
     * Initializes the BinaryUart with the specified serial number and
	 * resets the Rx buffer and other internal states. Called upon construction
     * and after buffer overflows or other packet error states.
     *
     * @param serialnum Serial number to initialize, used for packet validation.
     * @return int status code, 0 for success.
     */
    int Init(uint64_t serialnum = 0)
    {
		SerialNum = serialnum;
        RxCount = RxCountInit;
		PacketStart = PacketStartInit;
		PacketLen = PacketLenInit;
                PayloadLen = PayloadLenInit;
                HeaderLen = HeaderLenInit;
                FooterLen = FooterLenInit;
		InPacket = InPacketInit;
        memset(RxBuffer, EmptyBufferChar, RxBufferLenBytes);

		if (debug) { ::formatf("\n\nBinary Uart: Init(PktH %u, PktF %u).\n\r", Packet.HeaderLen(), Packet.FooterLen()); }

        return(0);
    }

  int InitFast(uint64_t serialnum = 0)
    {
		SerialNum = serialnum;
        RxCount = RxCountInit;
		PacketStart = PacketStartInit;
		PacketLen = PacketLenInit;
                PayloadLen = PayloadLenInit;
                HeaderLen = HeaderLenInit;
                FooterLen = FooterLenInit;
		InPacket = InPacketInit;
                //memset(RxBuffer, EmptyBufferChar, RxBufferLenBytes);

		//if (debug) { ::formatf("\n\nBinary Uart: Init(PktH %u, PktF %u).\n\r", Packet.HeaderLen(), Packet.FooterLen()); }

        return(0);
    }

    /**
     * @brief Reads all available bytes and checks for new packets.
     *
     * Bulk-reads all available data from the UART into a temporary buffer,
     * then feeds each byte through the packet parsing state machine, checking
     * for packet boundaries (start and end) after each byte.
     *
     * @return bool Returns true if data was processed, false if no new data.
     */
    bool Process() override
    {
      //~ uint32_t start=0;
      //~ uint32_t end=0;
      //~ uint32_t length=0;

	    //New char?
        if ( !(Pinout.dataready()) ) { return(false); }

		// Read all available bytes at once into a temporary buffer
		uint8_t tempBuffer[RxBufferLenBytes];
		int bytesRead = Pinout.read(tempBuffer, sizeof(tempBuffer));

		if (bytesRead <= 0) return(false);

		// Feed each byte through the existing packet parsing state machine
		for (int i = 0; i < bytesRead; i++)
		{
			if (debug) {
				printf(".%.2x", tempBuffer[i]);
			}

			ProcessByte(tempBuffer[i]);

			if (!InPacket) {
				bool gotStart = CheckPacketStart();
				if (gotStart) {
					PayloadLen = Packet.PayloadLen(RxBuffer, RxCount, PacketStart);
					HeaderLen = Packet.HeaderLen();
					FooterLen = Packet.FooterLen();
				}
			}
			else {
				if (!(RxCount < HeaderLen + FooterLen + PayloadLen)) {
					CheckPacketEnd();
				}
			}
		}

        return(true); //We just want to know if there's chars in the buffer to put threads to sleep or not...
    }

    /**
     * @brief Adds a byte to the Rx buffer and handles buffer overflow.
     *
     * @param c The character to add to the buffer.
     */
	void ProcessByte(const char c)
	{
		//Put the current character into the buffer
		if (RxCount < RxBufferLenBytes)
		{
                  //RxCount++;
                  //RxBuffer[RxCount - 1] = c;
                        RxBuffer[RxCount] = c;
                        RxCount++;
		}
		else
		{
			if (debug) { ::formatf("\n\nBinaryUart: Buffer(%p) overflow; this packet will not fit (%zub), flushing buffer.\n\r", RxBuffer, RxCount); }

			Callbacks.BufferOverflow(RxBuffer, RxCount);

			Init(SerialNum);
		}
	}

	bool CheckPacketStart()
	{
		//Packet Start?
		if ( (!InPacket) && (RxCount >= Packet.HeaderLen()) )
		{
			if (Packet.FindPacketStartPos(RxBuffer, RxCount, PacketStart)) //This is wasteful, we really only need to look at the 4 newest bytes every time...
			{
                          //	if (debug) { ::formatf("\n\nBinaryUart: Packet start detected! Buffering.\n\r"); }
                          InPacket = true;
                          return(true);
			}
                        return(false);
		}
                return(false);
	}

    /**
     * @brief Checks if a complete packet (with both header and footer) is present in the buffer.
     *
     * If a packet end is detected, verifies its validity and processes it. Handles incomplete
     * or corrupted packets, and clears the buffer appropriately after processing.
     *
     * @return bool Returns true if a packet was successfully processed, false otherwise.
     */
	bool CheckPacketEnd()
	{
          //~ uint32_t start=0;
          //~ uint32_t end=0;
          //~ uint32_t length=0;
		PacketEnd = 0;
		bool Processed = false;

		// Look for the packet footer within the buffer, exit if no valid footer found yet
		// This is wasteful, we really only need to look at the 4 newest bytes every time...
		if (!Packet.FindPacketEndPos(RxBuffer, RxCount, PacketEnd)) {
                  //if (debug) { ::formatf("\n\nBinaryUart: Still waiting for packet end...\n\r"); }
                  //Callbacks.InvalidPacket(reinterpret_cast<uint8_t*>(RxBuffer), RxCount);
                  //Init(SerialNum);
                  return false;
		}

		//const size_t payloadLen = Packet.PayloadLen(RxBuffer, RxCount, PacketStart);
                  

		// Validate packet
		if (Packet.IsValid(RxBuffer, RxCount, PacketStart, PacketEnd))
		{
			// Confirm that the serial number matches or is a broadcast
			if ( (SerialNum == InvalidSerialNumber) || (Packet.IsBroadcastSerialNum(RxBuffer, PacketStart, PacketEnd)) || (SerialNum == Packet.SerialNum(RxBuffer, PacketStart, PacketEnd)) )
			{
			  // Just look at each command, and exectute it if the input line matches.
			  bool CmdFound = false;

			  // Search for a matching command in the packet
			  // Inefficient to go through whole list of commands
			  // Idea: last nibble or byte (depending on number of commands) corresponds to position of command
			  // and can be used as index to Cmds[i].Response(...)
			  // This only happens once for each full packet, so might not be much time savings
			  for (size_t i = 0; i < NumCmds; i++)
			  {
				  // Check if command in buffer matches the defined command name
				  if (Packet.DoesPayloadTypeMatch(RxBuffer, RxCount, PacketStart, PacketEnd, Cmds[i].Name))
					{
					  //strip the part of the line with the arguments to this command (chars following command) for compatibility with the  parsing code, the "params" officially start with the s/n
					  //const char* Params = reinterpret_cast<char*>(&(RxBuffer[PacketStart + Packet.PayloadOffset()]));
					  const char* Params = reinterpret_cast<char*>(&(RxBuffer[PacketStart + HeaderLen]));
					  // Execute the command's response function
					  // We already figured out the payload length, so we don't need to call Packet.PayloadLen
					  // to get it again.  Comment out and use simpler Cmds[i].Respons(...) below
					  Cmds[i].Response(Cmds[i].Name, Params, Packet.PayloadLen(RxBuffer, RxCount, PacketStart), (void*)this);
					  CmdFound = true;
					  Processed = true;
					}
				}

				// If no command was found, trigger the unhandled packet callback
				if (!CmdFound)
				{
					//~ if (debug) { ::formatf("\n\nBinaryUart: Unmatched command 0x%.8lX!\n", PacketHeader->PayloadTypeToken); }
					if (debug) { ::formatf("\n\nBinaryUart: Unmatched command 0x%.8lX! NumCmds: %lu, Start: %lu, End: %lu\n", Packet.PayloadType(RxBuffer, PacketStart, PacketEnd), (unsigned long)NumCmds, (unsigned long)PacketStart, (unsigned long)PacketEnd); }

					Callbacks.UnHandledPacket(reinterpret_cast<IPacket*>(&RxBuffer[PacketStart]), PacketEnd - PacketStart);
				}
				else
				{
					if (debug)
					{
						//~ ::formatf("\n\nBinaryUart: Got Packet! \n");
						//~ PacketHeader->formatf();
						//~ ::formatf(" <");
						//~ for (size_t k = PacketStart; k < PacketEnd; k++)
						//~ {
							//~ ::formatf(":%0.2X", RxBuffer[k]);
						//~ }
						//~ ::formatf(">\n\n\n");
					}
				}
			}
			else
			// If serial number does not match, packet is unhandled
			{
				if (debug) { ::formatf("\n\nBinaryUart: Packet received, but SerialNumber comparison failed (expected: 0x%.8lX; got: 0x%.8lX).\n\r", SerialNum, Packet.SerialNum(RxBuffer, PacketStart, PacketEnd)); }

				Callbacks.UnHandledPacket(reinterpret_cast<IPacket*>(&RxBuffer[PacketStart]), PacketEnd - PacketStart);
			}

			// Notify that every packet is processed, even if unmatched
			Callbacks.EveryPacket(reinterpret_cast<IPacket*>(&RxBuffer[PacketStart]), PacketEnd - PacketStart);
		}
		else
		// If packet is invalid, trigger the invalid packet callback
		{
			if (debug) { ::formatf("\n\nBinaryUart: Packet received, but invalid.\n\r"); }

			Callbacks.InvalidPacket(reinterpret_cast<uint8_t*>(RxBuffer), RxCount);
		}

		// Reset InPacket flag after processing, ready for new packet
		InPacket = false;

		// Clear processed bytes from the buffer, preserving any unprocessed data
		//if (RxCount > (PacketEnd + 4) )
		//{
		//	size_t pos = 0;
		//	size_t clr = 0;
		//	// Shift unprocessed data to the start
		//	for (; pos < (RxCount - (PacketEnd + 4)); pos++)
		//	{
		//		RxBuffer[pos] = RxBuffer[(PacketEnd + 4) + pos];
		//	}
		//	// Clear remaining buffer space
		//	for (clr = pos; clr < RxCount; clr++)
		//	{
		//		RxBuffer[clr] = 0;
		//	}
		//	// Update RxCount to new length
		//	RxCount = pos;
		//}
		//else
		//// Reset if no unprocessed data remains
		//{
			InitFast(SerialNum);
                        //}

		// Return whether a packet was processed
		return(Processed);
    }

    /**
     * @brief Transmit a binary packet over UART.
     *
     * Constructs a binary packet using the specified payload type, serial number,
     * and payload data, and transmits it byte-by-byte over UART.
     *
     * @param PayloadType The type identifier for the packet. This distinguishes different commands in the packet.
     * @param SerialNumber The unique serial number for this packet.
     * @param PayloadData A pointer to the data to be transmitted as the packet payload.
     * @param PayloadLen The length of the payload data in bytes.
     */
	virtual void TxBinaryPacket(const uint16_t PayloadType, const uint32_t SerialNumber, const void* PayloadData, const size_t PayloadLength) const
	{
		uint8_t TxBuffer[TxBufferLenBytes]; ///< Temporary buffer to hold the constructed packet
		size_t PktLen = Packet.MakePacket(TxBuffer, TxBufferLenBytes, PayloadData, PayloadType, PayloadLength); ///< Build packet

		// Transmit each byte of the packet through the UART pinout
		for (size_t i = 0; i < PktLen; i++) { Pinout.putcqq(TxBuffer[i]); }

		// Debug output: log the packet type, length, and contents in hex format
		if (debug)
		{
			::formatf("\n\nBinary Uart: Sending packet(%u, %u): ", PayloadType, PayloadLength);
			for(size_t i = 0; i < PktLen; i++) { printf("%.2X:", TxBuffer[i]); }
			printf("\n\n");
		}
	}

	void formatf() const
	{
		::formatf("\n\nBinaryUart(%u, %c, %u): :", RxCount, InPacket?'Y':'N', PacketStart);
		for(size_t i = 0; i < RxCount; i++) { ::formatf("%2X:", RxBuffer[i]); }
		::formatf("\n\n");
	}
};

