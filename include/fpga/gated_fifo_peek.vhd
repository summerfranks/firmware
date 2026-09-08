--  fifo.vhd
--  Parametrizable FIFO with a single clock domain
--
--  Created by Wenzel Jakob on 08/08/06.
--  Copyright 2006. All rights reserved.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gated_fifo_peek is
	generic (
		WIDTH_BITS : natural := 32;
		DEPTH_BITS : natural := 9
	);
	port (
		
		clk		: in std_logic;
		rst		: in std_logic;
		wone_i	: in std_logic;
		data_i	: in std_logic_vector(WIDTH_BITS - 1 downto 0);
		rone_i	: in std_logic;
		full_o	: out std_logic;
		empty_o	: out std_logic;
		data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
		count_o	: out std_logic_vector(DEPTH_BITS - 1 downto 0);
		raddr_o : out std_logic_vector(DEPTH_BITS - 1 downto 0);
		waddr_o : out std_logic_vector(DEPTH_BITS - 1 downto 0);
		peekaddr_i : in std_logic_vector(DEPTH_BITS - 1 downto 0);
		peek_data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
		raddr_i : in std_logic_vector(DEPTH_BITS - 1 downto 0);
		multipop_e_i	: in std_logic;
		r_ack : out std_logic--;
	);
end gated_fifo_peek;

architecture rtl of gated_fifo_peek is

	component fifo_peek is
	generic (
		WIDTH_BITS : natural := 32;
		DEPTH_BITS : natural := 9
	);
	port (
		clk		: in std_logic;
		rst		: in std_logic;
		we_i	: in std_logic;
		data_i	: in std_logic_vector(WIDTH_BITS - 1 downto 0);
		re_i	: in std_logic;
		full_o	: out std_logic;
		empty_o	: out std_logic;
		data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
		count_o	: out std_logic_vector(DEPTH_BITS - 1 downto 0);
		raddr_o : out std_logic_vector(DEPTH_BITS - 1 downto 0);
		waddr_o : out std_logic_vector(DEPTH_BITS - 1 downto 0);
		peekaddr_i : in std_logic_vector(DEPTH_BITS - 1 downto 0);
		peek_data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
		raddr_i : in std_logic_vector(DEPTH_BITS - 1 downto 0);
		multipop_e_i	: in std_logic;
		r_ack : out std_logic--;
	);
	end component;

	signal we_i : std_logic;
	signal re_i : std_logic;
	signal r_ack_i : std_logic;
	--~ signal written : std_logic := '0';
	--~ signal readed : std_logic := '0';
	signal Last_wone_i : std_logic;
	signal Last_rone_i : std_logic;
	signal data_i_r : std_logic_vector(WIDTH_BITS - 1 downto 0);
	

begin

	fifo_i : fifo_peek
	generic map
	(
		WIDTH_BITS => WIDTH_BITS,
		DEPTH_BITS => DEPTH_BITS--,
	)
	port map
	(
		clk => clk,
		rst => rst,
		we_i => we_i,
		data_i => data_i_r,
		re_i => re_i,
		full_o => full_o,
		empty_o => empty_o,
		data_o => data_o,
		count_o => count_o,
		raddr_o => raddr_o,
		waddr_o => waddr_o,
		peekaddr_i => peekaddr_i,
		peek_data_o => peek_data_o,
		raddr_i => raddr_i,
		multipop_e_i => multipop_e_i,
		r_ack => r_ack_i--,
	);
	
	process(clk, rst)
	begin
	
		if (rst = '1') then
		
			we_i <= '0';
			re_i <= '0';
			--~ written <= '0';
			--~ readed <= '0';
			Last_wone_i <= '0';
			Last_rone_i <= '0';
			r_ack <= '0';
			data_i_r <= (others => '0');
		else
		
			if ( (clk'event) and (clk = '1') ) then
			
				--~ --make these a single clock
				--~ if (we_i = '1') then we_i <='0'; end if;				
				--~ if (re_i = '1') then re_i <='0'; end if;
				
				--~ --reset edge detectors on falling edge
				--~ if (wone_i = '0') then written <='0'; end if;				
				--~ if (rone_i = '0') then readed <='0'; end if;
				
				--~ --Generate the strobe on rising edge
				--~ if (wone_i = '1') then 
				
					--~ if (written = '0') then
					
						--~ written <= '1';
						--~ we_i <= '1';
					
					--~ end if;
					
				--~ end if;
				
				--~ --Generate the strobe on rising edge
				--~ if (rone_i = '1') then 
				
					--~ if (readed = '0') then
					
						--~ readed <= '1';
						--~ re_i <= '1';
						
					--~ end if;
					
				--~ else
				
					--~ r_ack <= '0';
					
				--~ end if;
				
				--~ if (r_ack_i = '1') then
				
					--~ r_ack <= '1';
					
				--~ end if;
				
				if (rone_i = '1') then
				
					--ReadReq Rising Edge
					if (Last_rone_i = '0') then
					
						Last_rone_i <= '1';
						
						re_i <= '1';
						
						--~ r_ack <= '1';
						
					else
					
						re_i <= '0';
					
					end if;
					
					if (r_ack_i = '1') then
				
						r_ack <= '1';
					
					end if;
					
				else
				
					Last_rone_i <= '0';
					
					re_i <= '0';
					
					r_ack <= '0';				
				
				end if;
				
				if (wone_i = '1') then
				
					--weadweq Rising Edge
					if (Last_wone_i = '0') then
					
						Last_wone_i <= '1';
						
						we_i <= '1';
						
						data_i_r <= data_i;

					else
					
						we_i <= '0';
					
					end if;
					
				else
				
					we_i <= '0';
				
					Last_wone_i <= '0';
					
				end if;
			
			end if;
			
		end if;
	
	end process;

end rtl;
