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

entity PacketValidator is
  port (
    clk : in std_logic;
    rst : in std_logic;
	
	PacketFound : out std_logic;
	HeaderFound : in std_logic;
	FooterFound : in std_logic;
	HeaderEndPos : in std_logic_vector(PeekRamDepth - 1 downto 0);
	FooterEndPos : in std_logic_vector(PeekRamDepth - 1 downto 0);
    PayloadLen : in std_logic_vector(15 downto 0);
	PacketCrc : in std_logic_vector(31 downto 0);
	CalcCrc : in std_logic_vector(31 downto 0);
	
	Dbg1 : out std_logic;
	Dbg2 : out std_logic;
	Dbg3 : out std_logic--;
  );
end PacketValidator;


architecture PacketValidatorImplemenatation of PacketValidator is

	constant PayloadTypeFilterwheelPos : std_logic_vector(15 downto 0) := x"4006";

	--~ signal LastHeaderFound : std_logic;
	signal LastFooterFound : std_logic;
	
  begin
  
  	process (clk, rst, FooterFound)
	  begin
	  
		--~ Dbg1 <= LatchCrc;
		--~ Dbg2 <= LatchPayloadType;
		--~ Dbg3 <= LatchPayloadLen;
		
		if (rst = '1') then
		  
			LastFooterFound <= '0';
			PacketFound <= '0';
			
		else
		
		  if ( (clk'event) and (clk = '1') ) then
		  
			LastFooterFound <= FooterFound;

			if ( (LastFooterFound = '0') and (FooterFound = '1') ) then
			
				if ( (HeaderEndPos + std_logic_vector(to_unsigned(16, PeekRamDepth)) + PayloadLen) = FooterEndPos) then
				
					--~ --Crc calc isn't right yet...if (PacketCrc = CalcCrc) then 

						PacketFound <= '1'; 
					
					--~ end if;
					
				end if;
				
			else
			
				if (LastFooterFound = '0') then 
				
					PacketFound <= '0'; 
					
				end if;
			
			end if;
			
		  end if;  
		  
		end if;
		
	  end process;

end PacketValidatorImplemenatation;

