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
	
	--Packet 
	PacketFound : in std_logic;
	HeaderEndPos : in std_logic_vector(PeekRamDepth - 1 downto 0);
    PayloadType : in std_logic_vector(15 downto 0);
	PayloadLen : in std_logic_vector(15 downto 0);
	
	--Outputs
	FilterwheelPos : out std_logic_vector(3 downto 0);
	--~ MoveFilterwheel : out std_logic;
	
	Dbg1 : out std_logic;
	Dbg2 : out std_logic;
	Dbg3 : out std_logic--;
  );
end PacketDecoder;

architecture PacketDecoderImplemenatation of PacketDecoder is

	constant PayloadTypeFilterwheelPos : std_logic_vector(15 downto 0) := x"4006";

	--~ signal LastHeaderFound : std_logic;
	signal LastPacketFound : std_logic;
	signal InPacket : std_logic;
	
	signal U32_0StartAddress : std_logic_vector(PeekRamDepth - 1 downto 0);
	signal U32_0Start : std_logic;
	signal U32_0Done : std_logic;
	signal U32_0Out : std_logic_vector(31 downto 0);
	
	component PeekRamReader is
	generic
	(
		NumBytes : natural := 4--,
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		PeekRamAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
		PeekRamByteOut : in std_logic_vector(7 downto 0);
		StartAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
		Start : in std_logic;
		Done : out std_logic;
		DataOut : out std_logic_vector((NumBytes * 8) - 1 downto 0)--;
	  );
	end component;
	
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
		PeekRamByteOut => PeekRamByteOut,
		StartAddress => U32_0StartAddress,
		Start => U32_0Start,
		Done => U32_0Done,
		DataOut => U32_0Out--,
	);

	process (clk, rst, PacketFound)
	  begin
	  
		--~ Dbg1 <= LatchCrc;
		--~ Dbg2 <= LatchPayloadType;
		--~ Dbg3 <= LatchPayloadLen;
		
		if (rst = '1') then
		  
			Decoding <= '0';
			LastPacketFound <= '0';
			InPacket <= '0';
			U32_0StartAddress <= (others => '0');
			U32_0Start <= '0';
			
		else
		
		  if ( (clk'event) and (clk = '1') ) then

			LastPacketFound <= PacketFound;
		  
			if ( (LastPacketFound = '0') and (PacketFound = '1') ) then InPacket <= '1'; end if;
			
			if (InPacket = '1') then
			
				case PayloadType is

					when PayloadTypeFilterwheelPos =>
					
						if (U32_0Done = '0') then
				
							U32_0StartAddress <= HeaderEndPos + std_logic_vector(to_unsigned(4, PeekRamDepth));
							U32_0Start <= '1';
							Decoding <= '1';
							
						else
							
							FilterwheelPos <= U32_0Out(3 downto 0);
							U32_0Start <= '0';
							InPacket <= '0';
							Decoding <= '0';
							
						end if;

					when others =>

					--We just let the processor handle everything else...
					InPacket <= '0';
					Decoding <= '0';
					
				end case;
			
			end if;
			
		  end if;  
		  
		end if;
		
	  end process;

end PacketDecoderImplemenatation;

