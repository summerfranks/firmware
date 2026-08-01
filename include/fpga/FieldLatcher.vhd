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

entity FieldLatcher is
  generic (
		NumBytes : natural := 4--;
  );
  port (
		clk : in std_logic;
		rst : in std_logic;
			
		-- Bus:
		ByteIn : in std_logic_vector(7 downto 0);
		WriteReq : in std_logic;
		Latch : in std_logic;
		FieldLatched : out std_logic_vector((NumBytes * 8) - 1 downto 0)--;
  );
end FieldLatcher;


architecture FieldLatcherImplemenatation of FieldLatcher is
	
	signal LastWriteReq : std_logic;
	signal LastLatch : std_logic;
	signal FieldLatched_i : std_logic_vector((NumBytes * 8) - 1 downto 0);

  begin
  process (clk, rst)
  begin
  	
    if (rst = '1') then
      
		LastWriteReq <= '0';
		LastLatch <= '0';
		FieldLatched_i <= (others => '0');
		
    else
	
      if ( (clk'event) and (clk = '1') ) then

	    LastWriteReq <= WriteReq;
		LastLatch <= Latch;
	  		
		if ( (LastWriteReq = '0') and (WriteReq = '1') ) then
		
			--~ FieldLatched_i(31 downto 24) <= FieldLatched_i(23 downto 16);
			--~ FieldLatched_i(23 downto 16) <= FieldLatched_i(15 downto 8);
			--~ FieldLatched_i(15 downto 8) <= FieldLatched_i(7 downto 0);
			--~ FieldLatched_i(7 downto 0) <= ByteIn;
			
			ByteShifter : for j in NumBytes downto 2 loop
				
				FieldLatched_i( (j * 8) - 1 downto (j - 1) * 8) <= FieldLatched_i( ((j - 1) * 8) - 1 downto (j - 2) * 8);
			
			end loop ByteShifter;

			FieldLatched_i(7 downto 0) <= ByteIn;
						
		else
		
			if ( (LastLatch = '0') and (Latch = '1') ) then 
			
				--FieldLatched <= FieldLatched_i; 
				
				--Our serial stream is byte-swapped:
				OutputEndian : for k in NumBytes downto 1 loop
				
					FieldLatched( (k * 8) - 1 downto (k - 1) * 8) <= FieldLatched_i( (((NumBytes - k) + 1) * 8) - 1 downto (NumBytes - k) * 8);
				
				end loop OutputEndian;
			
			end if;
			
		end if;

  	  end if;  
    end if;
  end process;

end FieldLatcherImplemenatation;

