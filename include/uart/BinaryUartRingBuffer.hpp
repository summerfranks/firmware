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

#include "IBlockDevice.hpp"

#include "format/formatf.h"

#include "uart/CmdSystem.hpp"

#include "uart/IProtocol.hpp"
#include "uart/IPacket.hpp"
//~ #include "uart/IUartParser.hpp"

#include "IArray.hpp"

#include "BinaryUart.h"

/**
 * @struct BinaryUartRingBuffer
 *
 * BinaryUartRingBuffer manages a UART interface for binary packet communication.
 * It provides buffering for received bytes, detects packet boundaries, and processes
 * commands within received packets.
 *
 **/
struct BinaryUartRingBuffer// : IUartParser
{
    //~ IUart& Pinout;										///< UART interface for data input.
    IArray& Data;
	FpgaRingBufferCrcer& Crcer;
    IPacket& Packet;									///< Packet structure for defining headers, footers, etc.
	IBlockDevice& Pinout;
    const BinaryCmd* Cmds;								///< Array of commands
    size_t NumCmds;
    BinaryUartCallbacks& Callbacks;
    bool debug;
    bool InPacket;										///< Whether a packet is currently being processed.
    size_t PacketStartPos;
    size_t PacketLen;
    size_t PayloadLen;
    const size_t HeaderLen;
    const size_t FooterLen;
    uint64_t SerialNum;									///< Serial number for validating received packets.
    uint32_t LastDataPos;
    uint32_t PacketSearchedPos;
	static const uint64_t InvalidSerialNumber = 0xFFFFFFFFFFFFFFFFULL;
	static const size_t TxBufferLenBytes = 4096;
	//~ uint8_t TxBuffer[TxBufferLenBytes];

    /**
     * @brief Constructs a BinaryUartRingBuffer object and initializes with given parameters.
     *
     * @param pinout    UART interface to use for receiving data.
     * @param packet    Packet structure defining header, footer, and payload format.
     * @param cmds      Array of available commands.
     * @param numcmds   Number of commands in the cmds array.
     * @param callbacks Callback functions for handling packet events.
     * @param verbose   Enable or disable verbose debug mode.
     * @param serialnum Optional initial serial number, defaulting to InvalidSerialNumber.
     */
    BinaryUartRingBuffer(IArray& data, FpgaRingBufferCrcer& crcer, IPacket& packet, class IBlockDevice& pinout, const BinaryCmd* cmds, const size_t numcmds, struct BinaryUartCallbacks& callbacks, const bool verbose = true, const uint64_t serialnum = InvalidSerialNumber)
        :
        //~ Pinout(pinout),
        Data(data),
		Crcer(crcer),
        Packet(packet),
		Pinout(pinout),
        Cmds(cmds),
        NumCmds(numcmds),
        Callbacks(callbacks),
        debug(false),
        //~ debug(true),
        HeaderLen(packet.HeaderLen()),
        FooterLen(packet.FooterLen()),
        //~ Argument(argument),
        SerialNum(serialnum),
        LastDataPos(0)
    {

    }

    void Debug(bool dbg)
    {
        debug = dbg;
		Packet.Debug(dbg);
    }

	bool Debug() { return(debug); }

    /**
     * @brief Processes incoming data and checks for new packets.
     *
     * Reads a new character if available, adds it to the Rx buffer, and checks
     * for packet boundaries (start and end).
     *
     * @return bool Returns true if data was processed, false if no new data.
     */
    bool Process()// override
    {
		size_t PacketEndPos = 0;
		
		Packet.Debug(true);
		
        //Of note: the DataLen should only grow as we process, since there is no other consumer removing bytes from the buffer, and we're not going to remove any until it overflows or we find the end of a packet.

        //New char?
        size_t DataPos = Data.WritePos();
        if (LastDataPos == DataPos)
        {
			//~ ::formatf("\n\nBinaryUartRingBufferRingBuffer: N/D(%u, %u).\n\r", LastDataPos, DataPos);
            return(false);
        }
        int32_t UnprocessedDataLen = DataPos - LastDataPos;
        if (UnprocessedDataLen < 0)
        {
            UnprocessedDataLen = Data.MaxDepth() + UnprocessedDataLen;
        }

        //~ if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: GotData(LastPos:%u, Len:%u).\n\r", LastDataPos, UnprocessedDataLen); }
		//~ ::formatf("\n\nBinaryUartRingBufferRingBuffer: GotData(%u).\n\r", LastDataPos); 

        //Packet End?? We have nothing to do until we have the end of a packet!
        //Need at least a Footer's worth of data...
        if (UnprocessedDataLen >= (int)FooterLen)
        {
            if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: Searching for Packet End @ %d, Len:%d, Last:%d.\n\r", DataPos, UnprocessedDataLen, LastDataPos); }
			
			if (Packet.ReverseFindPacketEndPos(Data, DataPos, LastDataPos, PacketEndPos))
            {
                //Oh, things just got interesting!
				
				int32_t BufferStartPos = Data.ReadPos();
				if (BufferStartPos > (int32_t)PacketEndPos) { BufferStartPos -= Data.MaxDepth(); } //Make this a negative number so we wrap backwards (IArray is *supposed* to support this)
				
				if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: FoundPacketEnd; Searching for Packet Start @ %d, End: %d.\n\r", PacketEndPos, BufferStartPos); }
						
				bool PacketStartFound = Packet.ReverseFindPacketStartPos(Data, PacketEndPos, BufferStartPos, PacketStartPos);
				
				if (PacketStartFound)
				{
					if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: FoundPacketStart(%d).\n\r", PacketStartPos); }
					
					//Oh, now things just got really really interesting!!
					PayloadLen = Packet.PayloadLen(Data, PacketStartPos);
					
					//~ if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: PayloadLen(%u).\n\r", PayloadLen); }
					
					// Validate packet
					if (Packet.IsValid(Data, PacketStartPos, PacketEndPos, Crcer))
					{
						// Confirm that the serial number matches or is a broadcast
						//~ if ( (SerialNum == InvalidSerialNumber) || (Packet.IsBroadcastSerialNum(Data, PacketStartPos, PacketEndPos)) || (SerialNum == Packet.SerialNum(Data, PacketStartPos, PacketEndPos)) )
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
								if (Packet.DoesPayloadTypeMatch(Data, PacketStartPos, PacketEndPos, Cmds[i].Name))
								{
									//strip the part of the line with the arguments to this command (chars following command) for compatibility with the  parsing code, the "params" officially start with the s/n
									
									//**warning, if packet wraps the end of the ring buffer, and the cmd handler dereferences it, this is gonna overrun the buffer and crash**
									//(but we're supposed to just be passing the address of the data in the buffer back to the fpga to copy it to the d/a's, not playing with the data)
									//~ int warning_fix_copy_to_safe_buffer = 37;
									//~ const char* Params = (char*)(&(Data[PacketStartPos + HeaderLen]));
									const size_t TwiceMaxPacketLen = 16384;
									uint8_t Params[TwiceMaxPacketLen];
									size_t PayloadStartPos = PacketStartPos + HeaderLen;
									Data.CopyToFlatBuffer(PayloadStartPos, PayloadLen, Params, TwiceMaxPacketLen);
									
									// Execute the command's response function
									// We already figured out the payload length, so we don't need to call Packet.PayloadLen
									// to get it again.  Comment out and use simpler Cmds[i].Respons(...) below
									Cmds[i].Response(Cmds[i].Name, (char*)Params, PayloadLen, (void*)this);
									CmdFound = true;
									//~ Processed = true;
								}
							}

							// If no command was found, trigger the unhandled packet callback
							if (!CmdFound)
							{
								//~ if (debug) { ::formatf("\n\nBinaryUartRingBuffer: Unmatched command 0x%.8lX!\n", PacketHeader->PayloadTypeToken); }
								if (debug)
								{
									::formatf("\n\nBinaryUartRingBuffer: Unmatched command 0x%.8lX! NumCmds: %lu\n", Packet.PayloadType(Data, PacketStartPos, PacketEndPos), (unsigned long)NumCmds);
								}

								const size_t TwiceMaxPacketLen = 16384;
								uint8_t Pkt[TwiceMaxPacketLen];					
								size_t PktLen =  PacketEndPos - PacketStartPos;
								Data.CopyToFlatBuffer(PacketStartPos, PktLen, Pkt, TwiceMaxPacketLen);									
								Callbacks.UnHandledPacket((IPacket*)(Pkt), PacketEndPos - PacketStartPos);
							}
							else
							{
								if (debug)
								{
									//~ ::formatf("\n\nBinaryUartRingBuffer: Got Packet! \n");
									//~ PacketHeader->formatf();
									//~ ::formatf(" <");
									//~ for (size_t k = PacketStartPos; k < PacketEndPos; k++)
									//~ {
									//~ ::formatf(":%0.2X", Data.Data[k]);
									//~ }
									//~ ::formatf(">\n\n\n");
								}
							}
						}
						//~ else
							//~ // If serial number does not match, packet is unhandled
						//~ {
							//~ if (debug)
							//~ {
								//~ ::formatf("\n\nBinaryUartRingBuffer: Packet received, but SerialNumber comparison failed (expected: 0x%.8lX; got: 0x%.8lX).\n\r", SerialNum, Packet.SerialNum(Data.Data.asU32(), PacketStartPos, PacketEndPos));
							//~ }

							//~ Callbacks.UnHandledPacket((IPacket*)(&(const uint8_t*)(Data.Data)[PacketStartPos]), PacketEndPos - PacketStartPos);
						//~ }

						//This is hugely wasteful in the real-time case...
						//~ // Notify that every packet is processed, even if unmatched
						//~ const size_t TwiceMaxPacketLen = 16384;
						//~ uint8_t PacketBuf[TwiceMaxPacketLen];					
						//~ size_t PktLen =  PacketEndPos - PacketStartPos;
						//~ Data.CopyToFlatBuffer(PacketStartPos, PktLen, PacketBuf, TwiceMaxPacketLen);									
						//~ Callbacks.EveryPacket((IPacket*)(PacketBuf), PacketEndPos - PacketStartPos);
						
					}
					else //false start, keep looking backwards?
					{
						
					}
					
					PacketStartPos = PacketEndPos + Packet.EndTokenLen();
					PacketStartFound = false;

					if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: PopMany(%d).\n\r", PacketStartPos); }
			
					//Ok, now we have to figure out how to remove the packet from the buffer...
					Data.PopMany(PacketStartPos);
				}
				else
				{
					// If packet is invalid, trigger the invalid packet callback
					if (debug)
					{
						::formatf("\n\nBinaryUartRingBuffer: Packet end found, start not found.\n\r");
					}

					//~ // Notify that every packet is processed, even if unmatched
					//~ const size_t TwiceMaxPacketLen = 16384;
					//~ uint8_t PacketBuf[TwiceMaxPacketLen];					
					//~ size_t PktLen =  PacketEndPos - PacketStartPos;
					//~ Data.CopyToFlatBuffer(PacketStartPos, PktLen, PacketBuf, TwiceMaxPacketLen);									
					//~ Callbacks.InvalidPacket((const uint8_t*)(PacketBuf), PacketEndPos - PacketStartPos);
					
					
					if (debug) { ::formatf("\n\nBinaryUartRingBufferRingBuffer: PopMany(%d).\n\r", PacketEndPos + Packet.EndTokenLen()); }
			
					//Ok, now we have to figure out how to remove the packet from the buffer...
					Data.PopMany(PacketEndPos + Packet.EndTokenLen());
					//~ InitFast(SerialNum);

				}
			}
			
			LastDataPos = DataPos;
		}
			
		return(true); //We just want to know if there's chars in the buffer to put threads to sleep or not...
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
		//for (size_t i = 0; i < PktLen; i++)
		//{
			//Pinout.putcqq(TxBuffer[i]);
		//}
		Pinout.puts(TxBuffer, PktLen);

		// Debug output: log the packet type, length, and contents in hex format
		if (debug)
		{
			::formatf("\n\nBinary Uart: Sending packet(%u, %u): ", PayloadType, PayloadLength);
			for(size_t i = 0; i < PktLen; i++)
			{
				printf("%.2X:", TxBuffer[i]);
			}
			printf("\n\n");
		}
	}

	void formatf() const
	{
		Data.formatf();
		Crcer.formatf();
		::formatf("\n\nBinaryUartRingBuffer(%u, %c, %u): ", Data.WritePos(), InPacket?'Y':'N', PacketStartPos);
		for(size_t i = 0; i < Data.WritePos(); i++)
		{
			::formatf("(%u)%02X, ", i, Data[i]);
		}
		::formatf("\n\n");
	}
};
