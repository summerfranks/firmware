--  fifo.vhd
--  Parametrizable FIFO with a single clock domain
--
--  Created by Wenzel Jakob on 08/08/06.
--  Copyright 2006. All rights reserved.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo is
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
		--allows one to wait until lastest data is read from ram:
		r_ack : out std_logic--;
	);
end fifo;

architecture rtl of fifo is
	constant DEPTH : natural := 2**DEPTH_BITS;
	-- Declare a RAM array data type
	type ram_type is array (0 to DEPTH - 1) of std_logic_vector(WIDTH_BITS - 1 downto 0);
	-- Shared variable to infer block ram
	-- ~ shared variable RAM		: ram_type := (others => (others => '0'));
	shared variable RAM		: ram_type;
	-- signal RAM : ram_type;
	-- Read/Write address pointers
	signal raddr_r, waddr_r	: unsigned(DEPTH_BITS - 1 downto 0);
	-- Async. counter change/Read/Write flag
	signal do_count			: std_logic;
	signal do_write			: std_logic;
	signal do_read			: std_logic;
	-- Fill counter
	signal counter_r		: natural range 0 to DEPTH;
	signal empty_r			: std_logic;
	signal full_r			: std_logic;
	signal data_r			: std_logic_vector(WIDTH_BITS - 1 downto 0);
begin
	do_read <= '1' when (re_i = '1' and empty_r = '0') else '0';
	do_write <= '1' when (we_i = '1' and full_r = '0') else '0';
	do_count <= '1' when do_read /= do_write else '0';
	empty_o <= empty_r;
	full_o <= full_r;
	data_o <= data_r;
	count_o <= std_logic_vector(to_unsigned(DEPTH - 1, DEPTH_BITS)) when full_r = '1'
           else std_logic_vector(to_unsigned(counter_r, DEPTH_BITS));

	update: process(rst, clk)
	begin
		if rst = '1' then
			counter_r <= 0;
			-- count_o <= (others => '0');
			raddr_r <= (others => '0');
			waddr_r <= (others => '0');
			full_r <= '0';
			empty_r <= '1';
		elsif rising_edge(clk) then
		
			-- if (full_r = '0') then
			-- 	count_o <= std_logic_vector(to_unsigned(counter_r, DEPTH_BITS));
			-- else 
			-- 	count_o <= std_logic_vector(to_unsigned((2**DEPTH_BITS) - 1, DEPTH_BITS));
			-- end if;
				
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

			if do_read = '1' then
				raddr_r <= raddr_r + 1;
			end if;

			if do_write = '1' then
				waddr_r <= waddr_r + 1;
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

	dpram_porta: process(clk, do_write)
	begin
		   if rising_edge(clk) and do_write = '1' then
			   RAM(to_integer(waddr_r)) := data_i;
		   end if;
	end process dpram_porta;

	dpram_portb: process(clk, rst)
	begin
		if (rst = '1') then
			data_r <= (others => '0');
			r_ack <= '0';
		elsif rising_edge(clk) then
			if do_read = '1' then
				data_r <= RAM(to_integer(raddr_r));
				r_ack <= '1';
			else
				r_ack <= '0';
			end if;
		end if;
	end process dpram_portb;
end rtl;
