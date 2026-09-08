--  fifo.vhd
--  Parametrizable FIFO with a single clock domain
--
--  Created by Wenzel Jakob on 08/08/06.
--  Copyright 2006. All rights reserved.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

entity fifo_peek is
	generic (
		WIDTH_BITS : natural := 32;
		DEPTH_BITS : natural := 9
	);
	port (
		-- Clock input
		clk		: in std_logic;
		-- Asynchronous reset
		rst		: in std_logic;
		-- Write enable flag
		we_i	: in std_logic;
		-- Write data input
		data_i	: in std_logic_vector(WIDTH_BITS - 1 downto 0);
		-- Read enable flag
		re_i	: in std_logic;
		-- FIFO full flag
		full_o	: out std_logic;
		-- FIFO empty flag
		empty_o	: out std_logic;
		-- Read data output
		data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
		--current number of items
		count_o	: out std_logic_vector(DEPTH_BITS - 1 downto 0);
		--read pointer: allows shadow of fifo from c++ code
		raddr_o : out std_logic_vector(DEPTH_BITS - 1 downto 0);
		--write pointer: allows shadow of fifo from c++ code
		waddr_o : out std_logic_vector(DEPTH_BITS - 1 downto 0);
		--peek pointer: allows digging around inside fifo from c++ code without popping 
		peekaddr_i : in std_logic_vector(DEPTH_BITS - 1 downto 0);
		--peek value: this is whatever's in the fifo at the peekaddr
		peek_data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
		--read pointer override: allows one to smash forward a big chunk after we're done digging around in the fifo
		raddr_i : in std_logic_vector(DEPTH_BITS - 1 downto 0);
		-- multipop_en: initiates the smash-forward
		multipop_e_i	: in std_logic;
		--allows one to wait until lastest data is read from ram:
		r_ack : out std_logic--;
	);
end fifo_peek;

architecture rtl of fifo_peek is
	constant DEPTH : natural := 2**DEPTH_BITS;
	-- Declare a RAM array data type
	type ram_type is array (0 to DEPTH - 1) of std_logic_vector(WIDTH_BITS - 1 downto 0);
	-- Shared variable to infer block ram
	--~ shared variable RAM		: ram_type := (others => (others => '0'));
	shared variable RAM		: ram_type;
	-- signal RAM : ram_type;
	-- Read/Write address pointers
	signal raddr_r, waddr_r	: std_logic_vector(DEPTH_BITS - 1 downto 0);
	-- Async. counter change/Read/Write flag
	signal do_count			: std_logic;
	signal do_write			: std_logic;
	signal do_read			: std_logic;
	-- Fill counter
	signal counter_r		: natural range 0 to DEPTH;
	signal empty_r			: std_logic;
	signal full_r			: std_logic;
	signal data_r			: std_logic_vector(WIDTH_BITS - 1 downto 0);
	signal lastmultipop_e_i	: std_logic;
begin
	do_read <= re_i and not empty_r;
	do_write <= we_i and not full_r;
	do_count <= '1' when (do_read /= do_write) else '0';
	-- do_count <= '1' when do_write = '1' else '0';
	empty_o <= empty_r;
	full_o <= full_r;
	data_o <= data_r;
	raddr_o <= raddr_r;
	waddr_o <= waddr_r;

	count_o <= std_logic_vector(to_unsigned(DEPTH - 1, DEPTH_BITS)) when full_r = '1'
           else std_logic_vector(to_unsigned(counter_r, DEPTH_BITS));

	update: process(rst, clk)
	begin
		if rst = '1' then
			counter_r <= 0;
			raddr_r <= (others => '0');
			waddr_r <= (others => '0');
			full_r <= '0';
			empty_r <= '1';
			lastmultipop_e_i <= '0';

		elsif rising_edge(clk) then

			if ((counter_r = 0) and (do_write = '0')) or (counter_r = 1 and do_read = '1' and 
				do_write = '0') then
				empty_r <= '1';
			else
				empty_r <= '0';
			end if;

			if (counter_r = DEPTH and do_read = '0') or (counter_r = DEPTH - 1
				and do_write = '1' and do_read = '0') then
				full_r <= '1';
			else
				full_r <= '0';
			end if;

			lastmultipop_e_i <= multipop_e_i;

			if do_read = '1' then
				raddr_r <= std_logic_vector(unsigned(raddr_r) + 1);
			else
				if ((multipop_e_i = '1') and (lastmultipop_e_i = '0')) then --edge strobe
					raddr_r <= raddr_i;
					counter_r <= counter_r - (to_integer(unsigned(raddr_i)) - to_integer(unsigned(raddr_r)));
				end if;
			end if;

			if do_write = '1' then
				waddr_r <= std_logic_vector(unsigned(waddr_r) + 1);
			end if;

			if do_count = '1' then
				if do_read = '1' then
					counter_r <= counter_r - 1;
				else
					counter_r <= counter_r + 1;
				end if;
				
			end if;
		end if;
	end process update;

	dpram_porta: process(clk, rst)
	begin
		if rising_edge(clk) then
		
			if do_write = '1' then
				RAM(to_integer(unsigned(waddr_r))) := data_i;
			end if;
			
		end if;
	end process dpram_porta;

	dpram_portb: process(clk, rst)
	begin
		if (rst = '1') then
			data_r <= (others => '0');
			r_ack <= '0';
			peek_data_o <= (others => '0');
		elsif rising_edge(clk) then
			if do_read = '1' then
				data_r <= RAM(to_integer(unsigned(raddr_r)));
				r_ack <= '1';
			else
				r_ack <= '0';
			end if;

			peek_data_o <= RAM(to_integer(unsigned(peekaddr_i)));
		end if;
	end process dpram_portb;
end rtl;
