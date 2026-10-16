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
	FilterwheelPos : out std_logic_vector(31 downto 0);
	--~ MoveFilterwheel : out std_logic;
	
	Dbg1 : out std_logic;
	Dbg2 : out std_logic;
	Dbg3 : out std_logic--;
  );
end PacketDecoder;

architecture PacketDecoderImplemenatation of PacketDecoder is

	constant PayloadTypeFilterwheelPos : std_logic_vector(15 downto 0) := x"4007";

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
	
	type States is (Idle, WhichPacket, ReadingFilterwheelPos);
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
			FilterwheelPos <= (others => '0');
			U32_0Start <= '0';
			StartResponseGenerator <= '0';
			ResponseGeneratorPayloadType <= (others => '0');
			ResponseGeneratorPayloadLen <= (others => '0');
			ResponseGeneratorPayloadField0 <= (others => '0');
			ResponseGeneratorPayloadField1 <= (others => '0');
			ResponseGeneratorPayloadField2 <= (others => '0');
			ResponseGeneratorPayloadField3 <= (others => '0');
			
		else
		
			if ( (clk'event) and (clk = '1') ) then
			  
				CurrentState <= NextState;
				
				LastPacketFound <= PacketFound;

				case CurrentState is
				
					when Idle =>
					
						Decoding <= '0';
					
						U32_0Start <= '0';
						
						StartResponseGenerator <= '0';
					
						if ( (LastPacketFound = '0') and (PacketFound = '1') ) then NextState <= WhichPacket; end if;
						
					when WhichPacket =>
					
						Decoding <= '1';
					
						case PayloadType is

							when PayloadTypeFilterwheelPos =>
							
								FilterwheelPos <= x"55555555";
								
								U32_0StartAddress <= HeaderEndPos + std_logic_vector(to_unsigned(5, PeekRamDepth));
								
								U32_0Start <= '1';
								
								NextState <= ReadingFilterwheelPos;
								
							when others =>
							
								FilterwheelPos <= x"AAAAAAAA";
								
								NextState <= Idle;
							
						end case;
						
					when ReadingFilterwheelPos =>		
					
						if (U32_0Done = '1') then
					
							U32_0Start <= '0';

							FilterwheelPos <= PayloadField3 & PayloadField2 & PayloadField1 & PayloadField0;
							--~ FilterwheelPos <= U32_0Out;
							--~ FilterwheelPos <= x"33333333";
							
							StartResponseGenerator <= '1';
							ResponseGeneratorPayloadType <= PayloadTypeFilterwheelPos;
							ResponseGeneratorPayloadLen <= x"0004";
							ResponseGeneratorPayloadField0 <= PayloadField0;
							ResponseGeneratorPayloadField1 <= PayloadField1;
							ResponseGeneratorPayloadField2 <= PayloadField2;
							ResponseGeneratorPayloadField3 <= PayloadField3;

							NextState <= Idle;
							
						else
						
							FilterwheelPos <= x"77777777";
							
						end if;				

					when others => -- ought never to get here...

						NextState <= Idle;
						
				end case;
				
			end if;
		  
		end if;
		
	  end process;

end PacketDecoderImplemenatation;

