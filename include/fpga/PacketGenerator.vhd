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
	PayloadType : out std_logic_vector(15 downto 0);
	PayloadLen : out std_logic_vector(15 downto 0);
	PayloadField0 : out std_logic_vector(7 downto 0);
	PayloadField1 : out std_logic_vector(7 downto 0);
	PayloadField2 : out std_logic_vector(7 downto 0);
	PayloadField3 : out std_logic_vector(7 downto 0);
	PayloadField4 : out std_logic_vector(7 downto 0);
	PayloadField5 : out std_logic_vector(7 downto 0);
	PayloadField6 : out std_logic_vector(7 downto 0);
	PayloadField7 : out std_logic_vector(7 downto 0);
	PayloadField8 : out std_logic_vector(7 downto 0);
	PayloadField9 : out std_logic_vector(7 downto 0);
	PayloadField10 : out std_logic_vector(7 downto 0);
	PayloadField11 : out std_logic_vector(7 downto 0);
	PayloadField12 : out std_logic_vector(7 downto 0);
	PayloadField13 : out std_logic_vector(7 downto 0);
	PayloadField14 : out std_logic_vector(7 downto 0);
	PayloadField15 : out std_logic_vector(7 downto 0);
	Done : out std_logic--;
  );
end PacketGenerator;


architecture PacketGeneratorImplemenatation of PacketGenerator is

	signal BytePos : natural range 0 to 4 + 4 + 16 + 4 + 4 - 1);
	signal LastStart : std_logic;	
	signal WriteTxd_i : std_logic;	
	signal TxdByte_i : out std_logic_vector(7 downto 0);
	signal CrcRst : std_logic;	
	signal CalcCrc_i : out std_logic_vector(31 downto 0);
	signal CalcCrc : out std_logic_vector(31 downto 0);


	Crcer : CrcStream
	port map
	(
		clk => WriteTxd_i,
		rst => CrcRst,
		data => TxdByte_i,
		crc => CalcCrc_i--,
	);

	process (clk, rst, PopReq, WriteReq, WriteAddress, HeaderEndPos, FooterEndPos, HeaderFound, FooterFound_i, latchcrc, latchpayloadlen, latchpayloadtype)
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
			CalcCrc <= (others => '0'); --Just so we can catch bugs
			
		else
		
			if (Done = '0') then
			
				--Strobe write signal
				WriteTxd_i <= not(WriteTxd_i);
				
				--Do all calc's on setup of write signal
				if (WriteTxd_i = '0') then
				
					--Done?
					if (BytePos >= ) then Done <= '1'; WriteTxd_i <= '0'; end if;
					
					--Move to next byte
					BytePos <= BytePos + 1;
					
					--Header
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 1) then TxdByte_i <= x"BA" end if;
					if (BytePos = 2) then TxdByte_i <= x"AD" end if;
					if (BytePos = 3) then TxdByte_i <= x"1B" end if;
					
					--PayloadType
					if (BytePos = 4) then TxdByte_i <= PayloadType(15 downto 8); end if;
					if (BytePos = 5) then TxdByte_i <= PayloadType(7 downto 0); end if;
					
					--PayloadLen
					if (BytePos = 6) then TxdByte_i <= PayloadType(15 downto 8); end if;
					if (BytePos = 7) then TxdByte_i <= PayloadType(7 downto 0); end if;
					
					--Payload
					if (BytePos = 8) then TxdByte_i <= x"BE" end if;
					if (BytePos = 9) then TxdByte_i <= x"BE" end if;
					if (BytePos = 10) then TxdByte_i <= x"BE" end if;
					if (BytePos = 11) then TxdByte_i <= x"BE" end if;
					if (BytePos = 12) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					if (BytePos = 0) then TxdByte_i <= x"BE" end if;
					
					if (BytePos = 0) then CalcCrc <= CalcCrc_i; CrcRst <= '1'; end if;
					
					--Crc
					if (BytePos = 0) then TxdByte_i <= CalcCrc(31 downto 24); end if;
					if (BytePos = 0) then TxdByte_i <= CalcCrc(23 downto 16); end if;
					if (BytePos = 0) then TxdByte_i <= CalcCrc(15 downto 8); end if;
					if (BytePos = 0) then TxdByte_i <= CalcCrc(7 downto 0); end if;
					
					--Footer
					if (BytePos = 0) then TxdByte_i <= x"ED" end if;
					if (BytePos = 0) then TxdByte_i <= x"AD" end if;
					if (BytePos = 0) then TxdByte_i <= x"0F" end if;
					if (BytePos = 0) then TxdByte_i <= x"0A" end if;
				
				end if;

			end if;
			
		end if;

	end if;
  end process;

end PacketGeneratorImplemenatation;

