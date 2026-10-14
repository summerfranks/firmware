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

entity PacketGenerator is
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
  );
end PacketGenerator;


architecture PacketGeneratorImplemenatation of PacketGenerator is

	signal BytePos : natural range 0 to (4 + 4 + 24 + 4 + 4);
	signal LastStart : std_logic;	
	signal WriteTxd_i : std_logic;	
	signal TxdByte_i : std_logic_vector(7 downto 0);
	signal CrcRst : std_logic;	
	signal CalcCrc_i : std_logic_vector(31 downto 0);
	signal CalcCrc : std_logic_vector(31 downto 0);
	
	component CrcStream is
	port (
	
		--Globals
		clk : in std_logic;
		rst : in std_logic;
		
		data : in std_logic_vector(7 downto 0);
		crc : out std_logic_vector(31 downto 0)
	
	); end component;

  begin
  
	Crcer : CrcStream
	port map
	(
		clk => WriteTxd_i,
		rst => CrcRst,
		data => TxdByte_i,
		crc => CalcCrc_i--,
	);

  process (clk, rst)
  begin
  
	WriteTxd <= WriteTxd_i;
	TxdByte <= TxdByte_i;
	
	--~ Dbg1 <= LatchCrc;
	--~ Dbg2 <= LatchPayloadType;
	--~ Dbg3 <= LatchPayloadLen;
	
	if (rst = '1') then

		BytePos <= 0;
		WriteTxd_i <= '0';
		CrcRst <= '1';
		TxdByte_i <= (others => '0');
		CalcCrc <= (others => '0');
		Done <= '1';

	else
	      if ( (clk'event) and (clk = '1') ) then

		    LastStart <= Start;
		    
		if ( (LastStart = '0') and (Start = '1') ) then
			
				Done <= '0';
				BytePos <= 0;
				WriteTxd_i <= '0';
				CrcRst <= '1';
				CalcCrc <= (others => '0'); --Just so we can catch bugs
				
			else
			
				if (Done = '0') then
				
					--Strobe write signal
					WriteTxd_i <= not(WriteTxd_i);
					
					--Do all calc's on setup of write signal
					if (WriteTxd_i = '0') then
					
						--Done?
						if (BytePos > 15 + PayloadLen) then Done <= '1'; WriteTxd_i <= '0'; end if;
						
						--Move to next byte
						BytePos <= BytePos + 1;
						
						--Header
						if (BytePos = 0) then TxdByte_i <= x"BE"; end if;
						if (BytePos = 1) then TxdByte_i <= x"BA"; end if;
						if (BytePos = 2) then TxdByte_i <= x"AD"; end if;
						if (BytePos = 3) then TxdByte_i <= x"1B"; end if;
						
						--PayloadType
						if (BytePos = 4) then TxdByte_i <= PayloadType(7 downto 0); CrcRst <= '0'; end if;
						if (BytePos = 5) then TxdByte_i <= PayloadType(15 downto 8); end if;
						
						--PayloadLen
						if (BytePos = 6) then TxdByte_i <= PayloadLen(7 downto 0); end if;
						if (BytePos = 7) then TxdByte_i <= PayloadLen(15 downto 8); end if;
						
						--Payload (24 bytes allows for 3 channels of FSM A/D data...)
						if ( (BytePos = 8) and (PayloadLen >= 1) ) then TxdByte_i <= PayloadField0; end if;
						if ( (BytePos = 9) and (PayloadLen >= 2) ) then TxdByte_i <= PayloadField1; end if;
						if ( (BytePos = 10) and (PayloadLen >= 3) ) then TxdByte_i <= PayloadField2; end if;
						if ( (BytePos = 11) and (PayloadLen >= 4) ) then TxdByte_i <= PayloadField3; end if;
						if ( (BytePos = 12) and (PayloadLen >= 5) ) then TxdByte_i <= PayloadField4; end if;
						if ( (BytePos = 13) and (PayloadLen >= 6) ) then TxdByte_i <= PayloadField5; end if;
						if ( (BytePos = 14) and (PayloadLen >= 7) ) then TxdByte_i <= PayloadField6; end if;
						if ( (BytePos = 15) and (PayloadLen >= 8) ) then TxdByte_i <= PayloadField7; end if;
						if ( (BytePos = 16) and (PayloadLen >= 9) ) then TxdByte_i <= PayloadField8; end if;
						if ( (BytePos = 17) and (PayloadLen >= 10) ) then TxdByte_i <= PayloadField9; end if;
						if ( (BytePos = 18) and (PayloadLen >= 11) ) then TxdByte_i <= PayloadField10; end if;
						if ( (BytePos = 19) and (PayloadLen >= 12) ) then TxdByte_i <= PayloadField11; end if;
						if ( (BytePos = 20) and (PayloadLen >= 13) ) then TxdByte_i <= PayloadField12; end if;
						if ( (BytePos = 21) and (PayloadLen >= 14) ) then TxdByte_i <= PayloadField13; end if;
						if ( (BytePos = 22) and (PayloadLen >= 15) ) then TxdByte_i <= PayloadField14; end if;
						if ( (BytePos = 23) and (PayloadLen >= 16) ) then TxdByte_i <= PayloadField15; end if;
						if ( (BytePos = 24) and (PayloadLen >= 17) ) then TxdByte_i <= PayloadField16; end if;
						if ( (BytePos = 25) and (PayloadLen >= 18) ) then TxdByte_i <= PayloadField17; end if;
						if ( (BytePos = 26) and (PayloadLen >= 19) ) then TxdByte_i <= PayloadField18; end if;
						if ( (BytePos = 27) and (PayloadLen >= 20) ) then TxdByte_i <= PayloadField19; end if;
						if ( (BytePos = 28) and (PayloadLen >= 21) ) then TxdByte_i <= PayloadField20; end if;
						if ( (BytePos = 29) and (PayloadLen >= 22) ) then TxdByte_i <= PayloadField21; end if;
						if ( (BytePos = 30) and (PayloadLen >= 23) ) then TxdByte_i <= PayloadField22; end if;
						if ( (BytePos = 31) and (PayloadLen >= 24) ) then TxdByte_i <= PayloadField23; end if;
											
						--Crc
						if (BytePos = 8 + PayloadLen) then TxdByte_i <= CalcCrc_i(7 downto 0); CalcCrc <= CalcCrc_i; CrcRst <= '1'; end if;
						if (BytePos = 9 + PayloadLen) then TxdByte_i <= CalcCrc(15 downto 8); end if;
						if (BytePos = 10 + PayloadLen) then TxdByte_i <= CalcCrc(23 downto 16); end if;
						if (BytePos = 11 + PayloadLen) then TxdByte_i <= CalcCrc(31 downto 24); end if;
						
						--Footer
						if (BytePos = 12 + PayloadLen) then TxdByte_i <= x"ED"; end if;
						if (BytePos = 13 + PayloadLen) then TxdByte_i <= x"AD"; end if;
						if (BytePos = 14 + PayloadLen) then TxdByte_i <= x"0F"; end if;
						if (BytePos = 15 + PayloadLen) then TxdByte_i <= x"0A"; end if;
					
					end if;

				end if;
				
			end if;

		end if;
		
	end if;
	
  end process;

end PacketGeneratorImplemenatation;

