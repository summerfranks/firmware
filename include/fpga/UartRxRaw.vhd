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

library ieee;
   use ieee.std_logic_1164.all;
   
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- !NOTE: this questionable code from the internet will rx an endless stream of zeros during a break condition (input held low) which is not proper uart opertation and is deprecated!
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
entity UartRxRaw is
  --~ generic (
		--~ PARITY : natural := 0--; --Implement parity bit, otherwise, only decode NO parity (i.e. 9600,N,8,1)
	--~ );
  port (
     Clk    : in  std_logic;  -- system clock signal
     Reset  : in  std_logic;  -- Reset input
     Enable : in  std_logic;  -- Enable input
     RxD    : in  std_logic;  -- RS-232 data input
     RxAv   : out std_logic;  -- Byte available
     DataO  : out std_logic_vector(7 downto 0)--; -- Byte received
	 --~ Samp   : out std_logic;
	 --~ Start   : out std_logic
	 );
end UartRxRaw;

architecture Behaviour of UartRxRaw is
  
  signal RReg    : std_logic_vector(7 downto 0); -- receive register  
  signal RxDPrev : std_logic := '1';
  
begin
  
  -- Rx Process
  RxProc : process(Clk,Reset,Enable,RxD,RReg)
  
	  variable BitPos : INTEGER range 0 to 10;   -- Position of the bit in the frame
	  variable SampleCnt : INTEGER range 0 to 15; -- Count from 0 to 3 in each bit 
	  
  begin
     if Reset = '1' then -- Reset
        BitPos := 0;
		SampleCnt := 0;
		RxAv <= '0';
		RReg <= x"00";
		DataO <= x"00";
		RxDPrev <= '1';
     elsif Rising_Edge(Clk) then
        if Enable = '1' then
           case BitPos is
              when 0 => -- idle
				 if (RxDPrev = '1') and (RxD = '0') then -- Start bit falling edge
                    RxAv <= '0';
                    SampleCnt := 0;
                    BitPos := 1;
					--~ Start <= '1';
                 end if;
              when 1 => -- Start Bit
                 if SampleCnt = 7 then
                    if RxD = '0' then
                    else
                       BitPos := 0;   -- Glitch: abandon frame and return idle
                    end if;
                 elsif SampleCnt = 15 then
                    BitPos := 2;
                 end if;
			--~ parityimplementaion : if (PARITY) generate
			  --~ when 10 => -- Parity
				 --~ Samp <= '0';
				 --~ DataO <= RReg;  -- Store received byte
				 --~ if SampleCnt = 15 then -- Increment BitPos on 3
                    --~ BitPos := BitPos + 1;
                 --~ end if;
			--~ end generate;
              when 10 => -- + integer(PARITY) => -- Stop Bit
				if (SampleCnt >= 3) then
				  if (Rxd = '1') then --stop bit
					 BitPos := 0;    -- next is idle
					 RxAv <= '1';
					 DataO <= RReg;  -- Store received byte
				  end if;
				end if;
				if (SampleCnt >= 13) then --no stop bit
					BitPos := 0;    -- next is idle
				end if;
              when others =>
				RxAv <= '0';
				--~ Start <= '0';
				--~ if (SampleCnt = 1 and BitPos >= 2) then -- Sample RxD on 2/4
                 --~ if (SampleCnt = 3 and BitPos >= 2) then -- Sample RxD on 4/16
				 if (SampleCnt = 7 and BitPos >= 2) then -- Sample RxD on 4/16
                    RReg(BitPos-2) <= RxD; -- Deserialisation
					--~ Samp <= '1';
				else 
					--~ Samp <= '0';
                 end if;
                 if SampleCnt = 15 then -- Increment BitPos on 3
                    BitPos := BitPos + 1;
                 end if;
           end case;
           if SampleCnt = 15 then
		   --~ if SampleCnt = 3 then
              SampleCnt := 0;
           else
              sampleCnt := SampleCnt + 1;
           end if;
           RxDPrev <= RxD;
        end if;
     end if;
  end process;
end Behaviour;

--~ The generate statement combined with generic parameters or constants may be used to achieve a behavior similar to "conditional compilation" in C. An example is:
        --~ entity test is
          --~ generic (switch : boolean);
        --~ end if;

        --~ architecture struct of test is
        --~ begin
           --~ -- instantiate "adder1" if "switch" is true
           --~ First: if switch generate
               --~ Q: adder1 port map (...);
           --~ end generate;
           --~ -- instantiate "adder2" if "switch" is false
           --~ Second: if not switch generate
               --~ Q: adder2 port map (...);
           --~ end generate;
	--~ end behave; 
--~ Component "adder1" will be included into the design only if the generic parameter "switch" is true. Otherwise, "adder2" is instantiated. 
--~ Note that the generate statement is "executed" at elaboration time (see FAQ Part 4 - B.81), 
--~ the entire architecture has to be analyzed by the compiler regardless of the generate parameter value 
--~ (note that the values of generic parameters are unknown at compile time). 
--~ Thus, syntactically or semantically incorrect code inside of generate statements will be flagged, 
--~ regardless of whether the statements are ever elaborated. (As a consequence, both instantiation statements in the example above must be legal.) 
--~ Further, the generate statement cannot be used to configure the interface of an entity; i.e., 
--~ to add or remove ports depending on the value of a generic parameter. However, the sizes of array ports can be controlled through the use of generics.

