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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;
library work;
use work.CGraphTypes.all;

entity PacketDecoder is
  port (
    clk : in std_logic;
    rst : in std_logic;
		
    -- Bus:
	PeekRamAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
	PeekRamByteOut : in std_logic_vector(7 downto 0);
	Decoding : out std_logic;
    TxdByte : out std_logic_vector(7 downto 0);
	WriteTxd : out std_logic;
	Transmitting : out std_logic;
	
	--Packet 
	PacketFound : in std_logic;
	HeaderEndPos : in std_logic_vector(PeekRamDepth - 1 downto 0);
    PayloadType : in std_logic_vector(15 downto 0);
	PayloadLen : in std_logic_vector(15 downto 0);
	PayloadField0 : in std_logic_vector(7 downto 0);
	PayloadField1 : in std_logic_vector(7 downto 0);
	PayloadField2 : in std_logic_vector(7 downto 0);
	PayloadField3 : in std_logic_vector(7 downto 0);
	PayloadField4 : in std_logic_vector(7 downto 0);
	PayloadField5 : in std_logic_vector(7 downto 0);
	PayloadField6 : in std_logic_vector(7 downto 0);
	PayloadField7 : in std_logic_vector(7 downto 0);
	PayloadField8 : in std_logic_vector(7 downto 0);
	PayloadField9 : in std_logic_vector(7 downto 0);
	PayloadField10 : in std_logic_vector(7 downto 0);
	PayloadField11 : in std_logic_vector(7 downto 0);
	PayloadField12 : in std_logic_vector(7 downto 0);
	PayloadField13 : in std_logic_vector(7 downto 0);
	PayloadField14 : in std_logic_vector(7 downto 0);
	PayloadField15 : in std_logic_vector(7 downto 0);
	
	--Outputs
	DacSetpointA : out std_logic_vector(23 downto 0);
	DacSetpointB : out std_logic_vector(23 downto 0);
	DacSetpointC : out std_logic_vector(23 downto 0);
	SetDacs : out std_logic;
	
	--Inputs
	DacAReadback : in std_logic_vector(23 downto 0);
	DacBReadback : in std_logic_vector(23 downto 0);
	DacCReadback : in std_logic_vector(23 downto 0);
	AdcSampleA : in std_logic_vector(47 downto 0);
	AdcSampleB : in std_logic_vector(47 downto 0);
	AdcSampleC : in std_logic_vector(47 downto 0);
	AdcNumAccums : in std_logic_vector(15 downto 0);
	
	Dbg1 : out std_logic;
	Dbg2 : out std_logic;
	Dbg3 : out std_logic--;
  );
end PacketDecoder;

architecture PacketDecoderImplemenatation of PacketDecoder is

	constant PayloadTypeFSMDacs : std_logic_vector(15 downto 0) := x"2002";
	constant PayloadTypeFSMAdcs : std_logic_vector(15 downto 0) := x"2003";

	--~ signal LastHeaderFound : std_logic;
	signal LastPacketFound : std_logic;
	signal InPacket : std_logic;
	
	signal NotTransmitting : std_logic;

	signal U32_0StartAddress : std_logic_vector(PeekRamDepth - 1 downto 0);
	signal U32_0Start : std_logic;
	signal U32_0Done : std_logic;
	signal U32_0Out : std_logic_vector(31 downto 0);
	
	signal StartResponseGenerator : std_logic;
	signal ResponseGeneratorPayloadType : std_logic_vector(15 downto 0);
	signal ResponseGeneratorPayloadLen : std_logic_vector(15 downto 0);
	signal ResponseGeneratorPayloadField0 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField1 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField2 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField3 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField4 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField5 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField6 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField7 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField8 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField9 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField10 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField11 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField12 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField13 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField14 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField15 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField16 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField17 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField18 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField19 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField20 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField21 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField22 : std_logic_vector(7 downto 0);
	signal ResponseGeneratorPayloadField23 : std_logic_vector(7 downto 0);
	
	type States is (Idle, WhichPacket, ReadingDacs, WritingAdcs);
	signal NextState : States := Idle;
	signal CurrentState : States := Idle;

	
	component PeekRamReader is
	generic
	(
		NumBytes : natural := 4--,
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		PeekRamAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
		PeekRamByte : in std_logic_vector(7 downto 0);
		StartAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
		Start : in std_logic;
		Done : out std_logic;
		DataOut : out std_logic_vector((NumBytes * 8) - 1 downto 0)--;
	  );
	end component;
	
	component PacketGenerator is
	port (
		clk : in std_logic;
		rst : in std_logic;
			
		TxdByte : out std_logic_vector(7 downto 0);
		WriteTxd : out std_logic;

		Start : in std_logic;
		PayloadType : in std_logic_vector(15 downto 0);
		PayloadLen : in std_logic_vector(15 downto 0);
		PayloadField0 : in std_logic_vector(7 downto 0);
		PayloadField1 : in std_logic_vector(7 downto 0);
		PayloadField2 : in std_logic_vector(7 downto 0);
		PayloadField3 : in std_logic_vector(7 downto 0);
		PayloadField4 : in std_logic_vector(7 downto 0);
		PayloadField5 : in std_logic_vector(7 downto 0);
		PayloadField6 : in std_logic_vector(7 downto 0);
		PayloadField7 : in std_logic_vector(7 downto 0);
		PayloadField8 : in std_logic_vector(7 downto 0);
		PayloadField9 : in std_logic_vector(7 downto 0);
		PayloadField10 : in std_logic_vector(7 downto 0);
		PayloadField11 : in std_logic_vector(7 downto 0);
		PayloadField12 : in std_logic_vector(7 downto 0);
		PayloadField13 : in std_logic_vector(7 downto 0);
		PayloadField14 : in std_logic_vector(7 downto 0);
		PayloadField15 : in std_logic_vector(7 downto 0);
		PayloadField16 : in std_logic_vector(7 downto 0);
		PayloadField17 : in std_logic_vector(7 downto 0);
		PayloadField18 : in std_logic_vector(7 downto 0);
		PayloadField19 : in std_logic_vector(7 downto 0);
		PayloadField20 : in std_logic_vector(7 downto 0);
		PayloadField21 : in std_logic_vector(7 downto 0);
		PayloadField22 : in std_logic_vector(7 downto 0);
		PayloadField23 : in std_logic_vector(7 downto 0);
		Done : out std_logic--;
	); end component;

  begin
  
  	U32_0 : PeekRamReader
	generic map 
	(
		NumBytes => 4--,
	)
	port map
	(
		clk => clk,
		rst => rst,
		PeekRamAddress => PeekRamAddress,
		PeekRamByte => PeekRamByteOut,
		StartAddress => U32_0StartAddress,
		Start => U32_0Start,
		Done => U32_0Done,
		DataOut => U32_0Out--,
	);
	
	ResponseGenerator : PacketGenerator
	port map (
		clk => clk,
		rst => rst,
		TxdByte => TxdByte,
		WriteTxd => WriteTxd,
 		Start => StartResponseGenerator,
		PayloadType => ResponseGeneratorPayloadType,
		PayloadLen => ResponseGeneratorPayloadLen,
		PayloadField0 => ResponseGeneratorPayloadField0,
		PayloadField1 => ResponseGeneratorPayloadField1,
		PayloadField2 => ResponseGeneratorPayloadField2,
		PayloadField3 => ResponseGeneratorPayloadField3,
		PayloadField4 => x"00",
		PayloadField5 => x"00",
		PayloadField6 => x"00",
		PayloadField7 => x"00",
		PayloadField8 => x"00",
		PayloadField9 => x"00",
		PayloadField10 => x"00",
		PayloadField11 => x"00",
		PayloadField12 => x"00",
		PayloadField13 => x"00",
		PayloadField14 => x"00",
		PayloadField15 => x"00",
		PayloadField16 => x"00",
		PayloadField17 => x"00",
		PayloadField18 => x"00",
		PayloadField19 => x"00",
		PayloadField20 => x"00",
		PayloadField21 => x"00",
		PayloadField22 => x"00",
		PayloadField23 => x"00",
		Done => NotTransmitting--,
	);

	process (clk, rst, PacketFound, CurrentState)
	  begin
	  
		Dbg1 <= U32_0Start;
		Dbg2 <= U32_0Done;
		Dbg3 <= InPacket;
		
		Transmitting <= not(NotTransmitting);
		
		if (rst = '1') then
		  
			CurrentState <= Idle;
			NextState <= Idle;
			Decoding <= '0';
			LastPacketFound <= '0';
			InPacket <= '0';
			U32_0StartAddress <= (others => '0');
			U32_0Start <= '0';
			StartResponseGenerator <= '0';
			ResponseGeneratorPayloadType <= (others => '0');
			ResponseGeneratorPayloadLen <= (others => '0');
			ResponseGeneratorPayloadField0 <= (others => '0');
			ResponseGeneratorPayloadField1 <= (others => '0');
			ResponseGeneratorPayloadField2 <= (others => '0');
			ResponseGeneratorPayloadField3 <= (others => '0');
			DacSetpointA <= (others => '0');
			DacSetpointB <= (others => '0');
			DacSetpointC <= (others => '0');
			SetDacs <= '0';
			
		else
		
			if ( (clk'event) and (clk = '1') ) then
			  
				CurrentState <= NextState;
				
				LastPacketFound <= PacketFound;

				case CurrentState is
				
					when Idle =>
					
						Decoding <= '0';
					
						U32_0Start <= '0';
						
						StartResponseGenerator <= '0';
						
						SetDacs <= '0';
					
						if ( (LastPacketFound = '0') and (PacketFound = '1') ) then NextState <= WhichPacket; end if;
						
					when WhichPacket =>
					
						Decoding <= '1';
					
						case PayloadType is

							when PayloadTypeFSMDacs =>
							
								NextState <= ReadingDacs;
								
							when PayloadTypeFSMAdcs =>
							
								NextState <= WritingAdcs;
								
							when others =>
							
								NextState <= Idle;
							
						end case;
						
					when ReadingDacs =>		
					
						if (PayloadLen >= x"000C") then
							
							--~ DacSetpointA <= PayloadField3 & PayloadField2 & PayloadField1 & PayloadField0;
							--~ DacSetpointB <= PayloadField7 & PayloadField6 & PayloadField5 & PayloadField4;
							--~ DacSetpointC <= PayloadField11 & PayloadField10 & PayloadField9 & PayloadField8;
							DacSetpointA <= PayloadField2 & PayloadField1 & PayloadField0;
							DacSetpointB <= PayloadField6 & PayloadField5 & PayloadField4;
							DacSetpointC <= PayloadField10 & PayloadField9 & PayloadField8;
							SetDacs <= '1';
							
							ResponseGeneratorPayloadLen <= x"000C";
							ResponseGeneratorPayloadField0 <= DacAReadback(7 downto 0);
							ResponseGeneratorPayloadField1 <= DacAReadback(15 downto 8);
							ResponseGeneratorPayloadField2 <= DacAReadback(23 downto 16);
							ResponseGeneratorPayloadField3 <= x"00";
							ResponseGeneratorPayloadField4 <= DacBReadback(7 downto 0);
							ResponseGeneratorPayloadField5 <= DacBReadback(15 downto 8);
							ResponseGeneratorPayloadField6 <= DacBReadback(23 downto 16);
							ResponseGeneratorPayloadField7 <= x"00";
							ResponseGeneratorPayloadField8 <= DacCReadback(7 downto 0);
							ResponseGeneratorPayloadField9 <= DacCReadback(15 downto 8);
							ResponseGeneratorPayloadField10 <= DacCReadback(23 downto 16);
							ResponseGeneratorPayloadField11 <= x"00";
							
						else
						
							ResponseGeneratorPayloadLen <= x"0002";
							ResponseGeneratorPayloadField0 <= PayloadLen(7 downto 0);
							ResponseGeneratorPayloadField1 <= PayloadLen(15 downto 8);
							
						end if;
						
						StartResponseGenerator <= '1';
						ResponseGeneratorPayloadType <= PayloadTypeFSMDacs;
						
						NextState <= Idle;
							
					when WritingAdcs =>		
						
						StartResponseGenerator <= '1';
						ResponseGeneratorPayloadType <= PayloadTypeFSMDacs;
						ResponseGeneratorPayloadLen <= x"0018";
						
						ResponseGeneratorPayloadField0 <= AdcSampleA(7 downto 0);
						ResponseGeneratorPayloadField1 <= AdcSampleA(15 downto 8);
						ResponseGeneratorPayloadField2 <= AdcSampleA(23 downto 16);
						ResponseGeneratorPayloadField3 <= AdcSampleA(31 downto 24);
						ResponseGeneratorPayloadField4 <= AdcSampleA(39 downto 32);
						ResponseGeneratorPayloadField5 <= AdcSampleA(47 downto 40);
						ResponseGeneratorPayloadField6 <= AdcNumAccums(7 downto 0);
						ResponseGeneratorPayloadField7 <= AdcNumAccums(15 downto 8);
						
						ResponseGeneratorPayloadField8 <= AdcSampleB(7 downto 0);
						ResponseGeneratorPayloadField9 <= AdcSampleB(15 downto 8);
						ResponseGeneratorPayloadField10 <= AdcSampleB(23 downto 16);
						ResponseGeneratorPayloadField11 <= AdcSampleB(31 downto 24);
						ResponseGeneratorPayloadField12 <= AdcSampleB(39 downto 32);
						ResponseGeneratorPayloadField13 <= AdcSampleB(47 downto 40);
						ResponseGeneratorPayloadField14 <= AdcNumAccums(7 downto 0);
						ResponseGeneratorPayloadField15 <= AdcNumAccums(15 downto 8);
						
						ResponseGeneratorPayloadField16 <= AdcSampleC(7 downto 0);
						ResponseGeneratorPayloadField17 <= AdcSampleC(15 downto 8);
						ResponseGeneratorPayloadField18 <= AdcSampleC(23 downto 16);
						ResponseGeneratorPayloadField19 <= AdcSampleC(31 downto 24);
						ResponseGeneratorPayloadField20 <= AdcSampleC(39 downto 32);
						ResponseGeneratorPayloadField21 <= AdcSampleC(47 downto 40);
						ResponseGeneratorPayloadField22 <= AdcNumAccums(7 downto 0);
						ResponseGeneratorPayloadField23 <= AdcNumAccums(15 downto 8);
						
						NextState <= Idle;

					when others => -- ought never to get here...

						NextState <= Idle;
						
				end case;
				
			end if;
		  
		end if;
		
	  end process;

end PacketDecoderImplemenatation;

