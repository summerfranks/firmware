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

entity VariableClockDivider2XPorts is
	generic (
		WIDTH_BITS : natural := 8;
		DIVOUT_RST_STATE : std_logic := '0'--;
	);
	port (
	
		clki : in std_logic;
		rst : in std_logic;
		rst_count : in std_logic_vector(WIDTH_BITS - 1 downto 0); --typically zero; if >= terminal_count, it will flip on the first clock after reset!
		terminal_count : in std_logic_vector(WIDTH_BITS - 1 downto 0); --a t/c of zero results in clko = clki / 2
		clko : out std_logic
	);
end VariableClockDivider2XPorts;

architecture VariableClockDivider2X of VariableClockDivider2XPorts is

	signal ClkDiv : natural range 0 to ((2**WIDTH_BITS) - 1);
	signal clko_i : std_logic;	

begin

	clko <= clko_i;
	
	process (clki, rst, rst_count)
	begin
	
		if (rst = '1') then
		
			ClkDiv <= to_integer(unsigned(rst_count));
			clko_i <= DIVOUT_RST_STATE;
			
		else
			
			if ( (clki'event) and (clki = '1') ) then
			
				--Generate the master DE-sampling clock
				if (ClkDiv < terminal_count) then
						
						ClkDiv <= ClkDiv + 1;
						
					else
					
						ClkDiv <= 0;

				end if;
				
				if (ClkDiv < ( (shift_right(unsigned(terminal_count),1)) - 1)) then
						
						clko_i <= DIVOUT_RST_STATE;
						
					else
					
						clko_i <= not(DIVOUT_RST_STATE);

				end if;
				
			end if;
			
		end if;

	end process;

end VariableClockDivider2X;
