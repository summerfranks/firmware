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

entity ClockDivider2XPorts is
	generic (
		CLOCK_DIVIDER : natural := 10;
		DIVOUT_RST_STATE : std_logic := '0'--;
	);
	port (
	
		clk : in std_logic;
		rst : in std_logic;
		div : out std_logic
	);
end ClockDivider2XPorts;

architecture ClockDivider2X of ClockDivider2XPorts is

	signal ClkDiv : natural range 0 to (CLOCK_DIVIDER - 1);
	signal div_i : std_logic;	

begin

	div <= div_i;
	
	process (clk, rst)
	begin
	
		if (rst = '1') then
		
			ClkDiv <= 0;
			div_i <= DIVOUT_RST_STATE;
			
		else
			
			if ( (clk'event) and (clk = '1') ) then
			
				--Generate the master DE-sampling clock
				if (ClkDiv < (CLOCK_DIVIDER - 1)) then -- "-1" because we count 0 too...
						
						ClkDiv <= ClkDiv + 1;
						
					else
					
						ClkDiv <= 0;

				end if;
				
				if (ClkDiv < ((CLOCK_DIVIDER / 2) - 1)) then
				
						div_i <= DIVOUT_RST_STATE;
						
					else
					
						div_i <= not(DIVOUT_RST_STATE);

				end if;
				
			end if;
			
		end if;

	end process;

end ClockDivider2X;
