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

entity PeekRingBuffer is
  port (
    clk : in std_logic;
    rst : in std_logic;
		
    -- Bus:
    DataStartAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
	DataEndAddress : out std_logic_vector(PeekRamDepth - 1 downto 0);
    ByteIn : in std_logic_vector(7 downto 0);
    WriteReq : in std_logic;
	PeekAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
    ByteOut : out std_logic_vector(7 downto 0);
    PopAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
    PopReq : in std_logic;
	HeaderFound : out std_logic;
	FooterFound : out std_logic;
	HeaderEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
	FooterEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
    PayloadType : out std_logic_vector(15 downto 0);
	PayloadLen : out std_logic_vector(15 downto 0);
	PacketCrc : out std_logic_vector(31 downto 0);
	CalcCrc : out std_logic_vector(31 downto 0);
	Dbg1 : out std_logic;
	Dbg2 : out std_logic;
	Dbg3 : out std_logic;
	Empty : out std_logic;
	Full : out std_logic;
	Count : out std_logic_vector(PeekRamDepth - 1 downto 0)--;
  );
end PeekRingBuffer;


architecture PeekRingBufferImplemenatation of PeekRingBuffer is

	component PeekRam is
	  port (
		clk : in std_logic;
		rst : in std_logic;
			
		-- Bus:
		ReadAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
		WriteAddress : in std_logic_vector(PeekRamDepth - 1 downto 0);
		ByteIn : in std_logic_vector(7 downto 0);
		ByteOut : out std_logic_vector(7 downto 0);
		WriteReq : in std_logic--;
	  );
	end component;
	
	component PatternFinder is
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
	end component;
	
	component FieldLatcher is
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
	end component;

	component CrcStream is
	port (
	
		--Globals
		clk : in std_logic;
		rst : in std_logic;
		
		data : in std_logic_vector(7 downto 0);
		crc : out std_logic_vector(31 downto 0)
	
	); end component;

	signal DataStartAddress_i : std_logic_vector(PeekRamDepth - 1 downto 0);
	signal WriteAddress : std_logic_vector(PeekRamDepth - 1 downto 0);

	signal LastPopReq : std_logic;
	signal LastWriteReq : std_logic;

	--~ signal HeaderFound : std_logic;
	--~ signal FooterFound : std_logic;
	signal LastHeaderFound : std_logic;
	signal LastFooterFound : std_logic;
	--~ signal HeaderEndPos : std_logic_vector(PeekRamDepth - 1 downto 0);
	--~ signal FooterEndPos : std_logic_vector(PeekRamDepth - 1 downto 0);
	
	--~ signal PayloadType : std_logic_vector(15 downto 0);
	--~ signal PayloadLen : std_logic_vector(15 downto 0);
	signal CalcCrc_i : std_logic_vector(31 downto 0);
	signal CRC : std_logic_vector(31 downto 0);
	
	signal LatchPayloadType : std_logic;
	signal LatchPayloadLen : std_logic;
	signal LatchCrc : std_logic;	
	signal CrcRst : std_logic;
	
  begin
  
	PeekRam_i : PeekRam
	port map
	(
		clk => clk,
		rst => rst,
		ReadAddress => PeekAddress,
		WriteAddress => WriteAddress,
		ByteIn => ByteIn,
		ByteOut => ByteOut,
		WriteReq => WriteReq
	);
	
	HeaderFinder : PatternFinder
	generic map 
	(
		Byte0 => x"1B",
		Byte1 => x"AD",
		Byte2 => x"BA",
		Byte3 => x"BE"--,
	)
	port map
	(
		clk => clk,
		rst => rst,
		ByteIn => ByteIn,
		WriteReq => WriteReq,
		Found => HeaderFound--,
	);
	
	FooterFinder : PatternFinder
	generic map 
	(
		Byte0 => x"0A",
		Byte1 => x"0F",
		Byte2 => x"AD",
		Byte3 => x"ED"--,
	)
	port map
	(
		clk => clk,
		rst => rst,
		ByteIn => ByteIn,
		WriteReq => WriteReq,
		Found => FooterFound--,
	);
	
	PayloadTypeLatcher : FieldLatcher
	generic map 
	(
		NumBytes => 2--,
	)
	port map 
	(
		clk => clk,
		rst => rst,
		ByteIn => ByteIn,
		WriteReq => WriteReq,
		Latch => LatchPayloadType,
		FieldLatched => PayloadType--,
	);

	PayloadLenLatcher : FieldLatcher
	generic map 
	(
		NumBytes => 2--,
	)
	port map 
	(
		clk => clk,
		rst => rst,
		ByteIn => ByteIn,
		WriteReq => WriteReq,
		Latch => LatchPayloadLen,
		FieldLatched => PayloadLen--,
	);
	
	CRCLatcher : FieldLatcher
	generic map 
	(
		NumBytes => 4--,
	)
	port map 
	(
		clk => clk,
		rst => rst,
		ByteIn => ByteIn,
		WriteReq => WriteReq,
		Latch => LatchCRC,
		FieldLatched => PacketCrc--,
	);

	Crcer : CrcStream
	port map
	(
		clk => WriteReq,
		rst => CrcRst,
		data => ByteIn,
		crc => CalcCrc_i--,
	);

	process (clk, rst, PopReq, WriteReq, WriteAddress, HeaderEndPos, FooterEndPos, HeaderFound, FooterFound)
  begin
  
	Dbg2 <= LastWriteReq;
	Dbg3 <= WriteReq;
  
	DataStartAddress <= DataStartAddress_i;
	DataEndAddress <= WriteAddress;
	
	Empty <= '1' when (DataStartAddress_i = WriteAddress) else '0';

	Full <= '1' when ( 	( (DataStartAddress_i = 0) and (WriteAddress = ((2**PeekRamDepth) - 1)) ) or 
						( (DataStartAddress_i = 1) and (WriteAddress = 0) ) or
						( (DataStartAddress_i > 1) and (WriteAddress = (DataStartAddress_i - 1)) ) 
					 )
	else '0';
	
	Count <= (WriteAddress - DataStartAddress_i) when (WriteAddress >= DataStartAddress_i) else 
			 ( ((2**PeekRamDepth) - WriteAddress) - DataStartAddress_i);	
	
    if (rst = '1') then
      
		LastPopReq <= '0';
		LastWriteReq <= '0';
		DataStartAddress_i <= (others => '0');
		WriteAddress <= (others => '0');
		HeaderEndPos <= (others => '0');
		FooterEndPos <= (others => '0');
        
    else
      if ( (clk'event) and (clk = '1') ) then

	    LastPopReq <= PopReq;
	    LastWriteReq <= WriteReq;
		LastHeaderFound <= HeaderFound;
		LastFooterFound <= FooterFound;
	  
        if ( (LastPopReq = '0') and (PopReq = '1') ) then
		
			--~ --Do a pop
            --~ DataStartAddress_i <= PopAddress;
        
			--Instead let's just clear the whole damn buffer for now since we don't know how to wrap anyway!
			DataStartAddress_i <= (others => '0');
			WriteAddress <= (others => '0');
			HeaderEndPos <= (others => '0');
			FooterEndPos <= (others => '0');
			
		end if;

        if ( (LastWriteReq = '0') and (WriteReq = '1') ) then
		
			Dbg1 <= '1';
				
			if (WriteAddress < ( (2**PeekRamDepth) - 1) ) then
		
				WriteAddress <= WriteAddress + std_logic_vector(to_unsigned(1, PeekRamDepth));
				--~ WriteAddress <= WriteAddress + std_logic_vector(to_unsigned(1, PeekRamDepth));
				
			else --wrap
			
				WriteAddress <= (others => '0');
				
			end if;
			
			--If we wrap footer or header, clear!
			if (HeaderEndPos = WriteAddress + std_logic_vector(to_unsigned(1, PeekRamDepth))) then HeaderEndPos <= (others => '0'); end if;			
			if (FooterEndPos = WriteAddress + std_logic_vector(to_unsigned(1, PeekRamDepth))) then FooterEndPos <= (others => '0'); end if;
			
			--Grab the payload len?
			
			if (WriteAddress = HeaderEndPos + 2) then LatchPayloadType <= '1'; else LatchPayloadType <= '0'; end if;
			if (WriteAddress = HeaderEndPos + 4) then LatchPayloadLen <= '1'; else LatchPayloadLen <= '0'; end if;
			if (WriteAddress = HeaderEndPos + 4 + PayloadLen) then LatchCrc <= '1'; else LatchCrc <= '0'; CalcCrc <= CalcCrc_i; end if;
			
			--~ if (WriteAddress >= HeaderEndPos) then
			
				--~ if (WriteAddress = (HeaderEndPos + 3)) then PayloadLen <= MaybePayloadLen; end if;
			
			--~ else

				--~ if (WriteAddress = (HeaderEndPos + 3 - (2**PeekRamDepth))) then PayloadLen <= MaybePayloadLen; end if; --!!!this calc is WRONG!!! Needs to WRAP correctly...
			
			--~ end if;
			
		else
		
			Dbg1 <= '0';
			
		end if;

		--Update on the edge of found; can't put this on the writereq edge, because the flag will toggle on the next clock after, not synchrounously!
		if ( (LastHeaderFound = '0') and (HeaderFound = '1') ) then HeaderEndPos <= WriteAddress - std_logic_vector(to_unsigned(1, PeekRamDepth)); CrcRst <= '1'; else CrcRst <= '0'; end if;
		if ( (LastFooterFound = '0') and (FooterFound = '1') ) then FooterEndPos <= WriteAddress - std_logic_vector(to_unsigned(1, PeekRamDepth)); end if;
		
  	  end if;  
    end if;
  end process;

end PeekRingBufferImplemenatation;

