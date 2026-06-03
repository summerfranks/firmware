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

entity PatternFinder is
  generic (
		Byte0 : std_logic_vector(7 downto 0) := x"00";
		Byte1 : std_logic_vector(7 downto 0) := x"00";
		Byte2 : std_logic_vector(7 downto 0) := x"00";
		Byte3 : std_logic_vector(7 downto 0) := x"00"--;
  );
  port (
		clk : in std_logic;
		rst : in std_logic;
			
		-- Bus:
		ByteIn : in std_logic_vector(7 downto 0);
		WriteReq : in std_logic;
		Found : out std_logic--;
  );
end PatternFinder;


architecture PatternFinderImplemenatation of PatternFinder is
	
	signal BytePos : std_logic_vector(1 downto 0);
	signal LastWriteReq : std_logic;
	
  begin
  process (clk, rst)
  begin
  	
    if (rst = '1') then
      
		BytePos <= "00";
		LastWriteReq <= '0';
		Found <= '0';
		
    else
      if ( (clk'event) and (clk = '1') ) then

	    LastWriteReq <= WriteReq;
	  
        if ( (LastWriteReq = '0') and (WriteReq = '1') ) then
		
			case BytePos is
			
				when "00" =>
				
					if (ByteIn = Byte0) then BytePos <= "01"; end if; Found <= '0';

				when "01" =>
				
					if (ByteIn = Byte1) then BytePos <= "10"; else BytePos <= "00"; end if; Found <= '0';

				when "10" =>
				
					if (ByteIn = Byte2) then BytePos <= "11"; else BytePos <= "00"; end if; Found <= '0';
					
				when "11" =>
				
					if (ByteIn = Byte3) then Found <= "1"; else Found <= "0"; end if; BytePos <= "00";

			end case;
			
		end if;
  	  end if;  
    end if;
  end process;

end PatternFinderImplemenatation;

