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

entity PeekRamReader is
    generic 
	(
		NumBytes : natural := 4--,
    )
    port 
	(
		clk : in std_logic;
		rst : in std_logic;
		PeekRamAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
		PeekRamByte : in std_logic_vector(7 downto 0);
		StartAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
		Start : in std_logic;
		Done : out std_logic;
		DataOut : out std_logic_vector((NumBytes * 8) - 1 downto 0)--;
	);
end PeekRamReader;


architecture PeekRamReaderImplemenatation of PeekRamReader is

	--~ constant PayloadTypeFilterwheelPos : std_logic_vector(15 downto 0) := x"4006";

	signal CurrentByte : natural range 0 to NumBytes;
	signal LastStart : std_logic;
	signal Done_i : std_logic;
	signal DataOut_i : out std_logic_vector((NumBytes * 8) - 1 downto 0);
	
  begin
  
	Done <= Done_i;
  
	process (clk, rst, Start)
	  begin
	  
		--~ Dbg1 <= LatchCrc;
		--~ Dbg2 <= LatchPayloadType;
		--~ Dbg3 <= LatchPayloadLen;
		
		if (rst = '1') then
		  
			DataOut <= (others => '0');
			CurrentByte <= NumBytes;
			LastStart <= (others => '0');
			Done_i <= (others => '1');
			DataOut_i <= (others => '0');
		
		else
		
		  if ( (clk'event) and (clk = '1') ) then

			LastStart <= Start;
		  
			if ( (LastStart = '0') and (Start = '1') ) then 
			
				PeekRamAddress <= StartAddress; 
				CurrentByte <= 0;
				Done_i <= '0';
			
			else
			
				if (CurrentByte < NumBytes) then
				
					DataOut_i((((CurrentByte + 1) * 8) - 1) downto (CurrentByte * 8)) <= PeekRamByte;
					CurrentByte <= CurrentByte + 1;
					PeekRamAddress <= StartAddress + std_logic_vector(to_unsigned(CurrentByte + 1, PeekRamDepth))
					
				else
				
					Done_i <= '1';
					DataOut <= DataOut_i;
					
				end if;
				
			end if;
				
		  end if;  
		  
		end if;
		
	  end process;

end PeekRamReaderImplemenatation;

