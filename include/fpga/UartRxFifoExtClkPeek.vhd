--
--           Copyright (c) by Franks Development, LLC
--
-- This software is copyrighted by and is the sole property of Franks
-- Development, LLC. All rights, title, ownership, or other interests
-- in the software remain the property of Franks Development, LLC. This
-- software may only be used in accordance with the corresponding
-- license agreement.  Any unauthorized use, duplication, transmission,
-- distribution, or disclosure of this software is expressly forbidden.
--
-- This Copyright notice may not be removed or modified without prior
-- written consent of Franks Development, LLC.
--
-- Franks Development, LLC. reserves the right to modify this software
-- without notice.
--
-- Franks Development, LLC            support@franks-development.com
-- 500 N. Bahamas Dr. #101           http:--www.franks-development.com
-- Tucson, AZ 85710
-- USA
--
-- Permission granted for perpetual non-exclusive end-use by the University of Arizona August 1, 2020
--

--------------------------------------------------------------------------------
--UartRxFifo: a uart reciever with clocks and such built-in
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;
library work;
use work.CGraphTypes.all;

entity UartRxFifoExtClkPeek is
	port 
	(
		--Outside world:
		clk : in std_logic;
		uclk : in std_logic;
		rst : in std_logic;
		
		--External (async) uart data input pin
		Rxd : in std_logic; 
		
		Dbg1 : out std_logic; 
		Dbg2 : out std_logic; 
		Dbg3 : out std_logic; 
		
		--debug
		RxComplete : out std_logic;
		
		--Read from fifo:
		ReadFifo	: in std_logic;
		FifoReadAck : out std_logic;
		FifoReadData : out std_logic_vector(7 downto 0);

		--Packet decodes:
		HeaderFound : out std_logic;
		FooterFound : out std_logic;
		HeaderEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
		FooterEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
		PayloadType : out std_logic_vector(15 downto 0);
		PayloadLen : out std_logic_vector(15 downto 0);
		PacketCrc : out std_logic_vector(31 downto 0);
		CalcCrc : out std_logic_vector(31 downto 0);
		
		--Fifo status:
		FifoFull	: out std_logic;
		FifoEmpty	: out std_logic;
		FifoCount	: out std_logic_vector(PeekRamDepth - 1 downto 0);		
		
		--Fifo peeking:
		FifoReadAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
		FifoWriteAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
		FifoPeekAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
		FifoPeekData : out std_logic_vector(7 downto 0);
		FifoMultiPopAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
		FifoMultiPopStrobe : in std_logic--;		
	);
end UartRxFifoExtClkPeek;

architecture implementation of UartRxFifoExtClkPeek is

		component IBufP2Ports is
		port 
		(
			clk : in std_logic;
			I : in std_logic;
			O : out std_logic--;
		);
		end component;

		component PeekRingBuffer is
		port (
			clk : in std_logic;
			rst : in std_logic;
				
			-- Bus:
			DataStartAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
			DataEndAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
			ByteIn : in std_logic_vector(7 downto 0);
			WriteReq : in std_logic;
			PeekAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
			ByteOut : out std_logic_vector(7 downto 0);
			PopAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
			PopReq : in std_logic;
			HeaderFound : out std_logic;
			FooterFound : out std_logic;
			HeaderEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
			FooterEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
			PayloadType : out std_logic_vector(15 downto 0);
			PayloadLen : out std_logic_vector(15 downto 0);
			PacketCrc : out std_logic_vector(31 downto 0);
			CalcCrc : out std_logic_vector(31 downto 0);
			PacketFound : out std_logic;
			Dbg1 : out std_logic;
			Dbg2 : out std_logic;
			Dbg3 : out std_logic;
			Empty : out std_logic;
			Full : out std_logic;
			Count : out std_logic_vector(PeekRamDepth - 1 downto 0)--;
		);
		end component;
		
		component UartRxExtClk is
		port 
		(
			uclk : in std_logic;
			rst : in std_logic;
            UartClk : out std_logic; --debug
			Rxd : in std_logic; --external (async) uart data input pin
			RxComplete : out std_logic; --Just got a byte
			RxData : out std_logic_vector(7 downto 0) --The byte we just got		
		);
		end component;

	signal RxComplete_i : std_logic; --Just got a byte
	signal RxData : std_logic_vector(7 downto 0); --The byte we just got		
	signal ReadFifo_i : std_logic; --Sync ReadFifo to clock domain
	signal WriteFifo_i : std_logic; --Sync WriteFifo to clock domain	
	
begin

	--~ --Just sync the Txd to the UartClock
	--~ ClkSyncRead : IBufP2Ports
	--~ port map
	--~ (
		--~ clk => clk,
		--~ I => ReadFifo,
		--~ O => ReadFifo_i
	--~ );
	
	--~ Dbg1 <= RxComplete_i;
	--~ Dbg1 <= WriteFifo_i;	
	
	ReadFifo_i <= ReadFifo;
	
	--The actual uart to grab data
	Uart : UartRxExtClk
	port map (						
		uclk => uclk,
        UartClk => open,
		rst => rst,
		Rxd => Rxd,
		RxComplete => RxComplete_i,
		RxData => RxData
	);
	
	RxComplete <= RxComplete_i;
	
	--Just sync the fifo write from the usbclk to the MasterClock
	ClkSyncWrite : IBufP2Ports
	port map
	(
		clk => clk,
		I => RxComplete_i,
		O => WriteFifo_i
	);
	
	--Fifo holds bytes after we get them
	UartFifo : PeekRingBuffer
	port map
	(
		clk => clk,
		rst => rst,
		DataStartAddress => FifoReadAddr,
		DataEndAddress => FifoWriteAddr,
		PeekAddress => FifoPeekAddr,
		PopAddress => FifoMultiPopAddr,
		HeaderFound => HeaderFound,
		FooterFound => FooterFound,
		HeaderEndPos => HeaderEndPos,
		FooterEndPos => FooterEndPos,
		PayloadType => PayloadType,
		PayloadLen => PayloadLen,
		PacketCrc => PacketCrc,
		CalcCrc => CalcCrc,
    	ByteIn => RxData,
		ByteOut => FifoPeekData,
		WriteReq => WriteFifo_i,
		PopReq => FifoMultiPopStrobe,
		Dbg1 => Dbg1,
		Dbg2 => Dbg2,
		Dbg3 => Dbg3,
		Empty => FifoEmpty,
		Full => FifoFull,
		Count => FifoCount--,
	);
	
end implementation;
