--! \brief Helpful utlity functions/procedures for testbenches

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_utils_pkg is

	-- Reporting helpers
	constant COLOR_GREEN : string := character'val(27) & "[32m";
	constant COLOR_RED : string := character'val(27) & "[31m";
	constant COLOR_YELLOW : string := character'val(27) & "[33m";
	constant COLOR_RESET : string := character'val(27) & "[0m";

	-- Bit / vector helpers
	function byte_bit(constant b : std_logic_vector(7 downto 0); constant idx : integer) return std_logic;
	function vector_bit(constant v : std_logic_vector; constant idx : integer) return std_logic;

	-- UART math helpers
	function uart_parity_bit(
		constant data_i : std_logic_vector(7 downto 0);
		constant parity_even_i : std_logic
	) return std_logic;
	function baud_from_period(
		constant bit_period_i : time
	) return real;
	function baud_from_skew(
		constant bit_period_i : time;
		constant bit_skew : time
	) return real;
	function uart_baud_tolerance_pct(
		constant frame_bits_i : natural
	) return real;
	function predicted_skew_allowance(
		constant bit_period_i : time;
		constant baud_tolerance_pct : real
	) return time;
	function time_to_percent_of_bit(
		constant period_delta : time;
		constant bit_period_i : time
	) return real;
	procedure report_baud_range_summary(
		constant nominal_baud_i : real;
		constant min_baud_i : real;
		constant max_baud_i : real;
		constant neg_tolerance_pct_i : real;
		constant pos_tolerance_pct_i : real
	);

	-- Generic testbench helpers
	procedure cycle_clock(
		signal clk : in std_logic;
		constant cycles : natural
	);

	procedure wait_until_value(
		signal clk : in std_logic;
		signal observed : in std_logic;
		constant expected : std_logic;
		constant timeout_cycles : natural;
		constant msg : string
	);

	procedure assert_equal(
		constant actual : std_logic;
		constant expected : std_logic;
		constant msg : string
	);

	procedure assert_equal(
		constant actual : std_logic_vector;
		constant expected : std_logic_vector;
		constant msg : string
	);

	procedure assert_equal(
		constant actual : boolean;
		constant expected : boolean;
		constant msg : string
	);

	procedure assert_equal(
		constant actual : time;
		constant expected : time;
		constant msg : string
	);

	procedure reset_dut(
		signal clk : in std_logic;
		signal rst_out : out std_logic
	);

	-- UART stimulus helpers
	procedure uart_rx_byte_timed(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant bit_period : in time;
		constant phase_offset : in time;
		constant bit_skew : in time
	);

	procedure uart_rx_byte_timed_parity(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant parity_bit : in std_logic;
		constant bit_period : in time;
		constant phase_offset : in time;
		constant bit_skew : in time
	);

	procedure uart_rx_byte_cycles(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant cycles_per_bit : in natural := 1;
		constant pre_idle_cycles : in natural := 1;
		constant stop_cycles : in natural := 1
	);

	procedure uart_rx_byte_cycles_parity(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant parity_bit : in std_logic;
		constant cycles_per_bit : in natural := 1;
		constant pre_idle_cycles : in natural := 1;
		constant stop_cycles : in natural := 1
	);

	-- UART tolerance sweeps
	procedure uart_rx_sweep_baud_skew(
		signal reset_clk_i : in std_logic;
		signal clk_i : in std_logic;
		signal rst_o : out std_logic;
		signal rxd_o : out std_logic;
		signal rxav_i : in std_logic;
		signal datao_i : in std_logic_vector(7 downto 0);
		signal parityerr_i : in std_logic;
		constant use_parity_i : in std_logic;
		constant bit_period : in time;
		constant phase_offset : in time;
		constant pattern : in std_logic_vector(7 downto 0);
		variable pass_found_o : out boolean;
		variable neg_pass_limit_o : out time;
		variable pos_pass_limit_o : out time
	);

	procedure uart_rx_fifo_sweep_baud_skew(
		signal reset_clk_i : in std_logic;
		signal sample_clk_i : in std_logic;
		signal fifo_clk_i : in std_logic;
		signal rst_o : out std_logic;
		signal readfifo_o : out std_logic;
		signal rxd_o : out std_logic;
		signal fifo_readack_i : in std_logic;
		signal fifo_readdata_i : in std_logic_vector(7 downto 0);
		constant use_parity_i : in std_logic;
		constant bit_period : in time;
		constant phase_offset : in time;
		constant pattern : in std_logic_vector(7 downto 0);
		variable pass_found_o : out boolean;
		variable neg_pass_limit_o : out time;
		variable pos_pass_limit_o : out time
	);

	-- Test naming / progress output
	procedure set_test_name(
		signal dst : out string;
		constant src : in string
	);

end package tb_utils_pkg;

package body tb_utils_pkg is

	-- Bit / vector helpers
	function byte_bit(constant b : std_logic_vector(7 downto 0); constant idx : integer) return std_logic is
	begin
		return b(idx);
	end function;

	function vector_bit(constant v : std_logic_vector; constant idx : integer) return std_logic is
	begin
		return v(idx);
	end function;

	-- UART math helpers
	function uart_parity_bit(
		constant data_i : std_logic_vector(7 downto 0);
		constant parity_even_i : std_logic
	) return std_logic is
		variable parity_bit : std_logic := '0';
	begin
		for i in 0 to 7 loop
			parity_bit := parity_bit xor data_i(i);
		end loop;
		if (parity_even_i = '1') then
			return parity_bit;
		else
			return not(parity_bit);
		end if;
	end function;

	function baud_from_period(
		constant bit_period_i : time
	) return real is
	begin
		return 1.0e12 / real(bit_period_i / 1 ps);
	end function;

	function baud_from_skew(
		constant bit_period_i : time;
		constant bit_skew : time
	) return real is
	begin
		return baud_from_period(bit_period_i + bit_skew);
	end function;

	function uart_baud_tolerance_pct(
		constant frame_bits_i : natural
	) return real is
		constant IDEAL_MARGIN_PCT : real := 50.0;
		constant START_SYNC_ERR_PCT : real := 6.25;
		constant EDGE_ERR_PCT : real := 2.0;
	begin
		return (IDEAL_MARGIN_PCT - START_SYNC_ERR_PCT - EDGE_ERR_PCT) / real(frame_bits_i);
	end function;

	function predicted_skew_allowance(
		constant bit_period_i : time;
		constant baud_tolerance_pct : real
	) return time is
	begin
		return bit_period_i * baud_tolerance_pct / 100.0;
	end function;

	function time_to_percent_of_bit(
		constant period_delta : time;
		constant bit_period_i : time
	) return real is
	begin
		return (real(period_delta / 1 ps) / real(bit_period_i / 1 ps)) * 100.0;
	end function;

	procedure report_baud_range_summary(
		constant nominal_baud_i : real;
		constant min_baud_i : real;
		constant max_baud_i : real;
		constant neg_tolerance_pct_i : real;
		constant pos_tolerance_pct_i : real
	) is
	begin
		report "Baud range of " &
			integer'image(integer(nominal_baud_i)) & ": " &
			integer'image(integer(min_baud_i)) & " - " &
			integer'image(integer(max_baud_i)) & " baud (-" &
			real'image(neg_tolerance_pct_i) & "% / +" &
			real'image(pos_tolerance_pct_i) & "%)";
	end procedure;

	-- Generic testbench helpers
	procedure cycle_clock(
		signal clk : in std_logic;
		constant cycles : natural
	) is
	begin
		for i in 1 to cycles loop
			wait until falling_edge(clk);
		end loop;
	end procedure;

	procedure wait_until_value(
		signal clk : in std_logic;
		signal observed : in std_logic;
		constant expected : std_logic;
		constant timeout_cycles : natural;
		constant msg : string
	) is
	begin
		for i in 0 to timeout_cycles loop
			if (observed = expected) then
				return;
			end if;

			if (i < timeout_cycles) then
				wait until rising_edge(clk);
			end if;
		end loop;

		report COLOR_RED & "  FAIL: " & msg & " - timed out after " &
			integer'image(timeout_cycles) & " rising edges waiting for '" &
			std_logic'image(expected) & "', got '" & std_logic'image(observed) & "'" &
			COLOR_RESET
			severity error;
	end procedure;

	procedure assert_equal(
		constant actual : std_logic;
		constant expected : std_logic;
		constant msg : string
	) is
	begin
		if (actual = expected) then
			report COLOR_GREEN & "  PASS: " & " - got '" & std_logic'image(actual) & "' " & msg & COLOR_RESET;
		else
			report COLOR_RED & "  FAIL: " & msg & " - got '" & std_logic'image(actual) & "' expected '" & std_logic'image(expected) & "'" & COLOR_RESET 
				severity error;
		end if;
	end procedure;

	procedure assert_equal(
		constant actual : std_logic_vector;
		constant expected : std_logic_vector;
		constant msg : string
	) is
	begin
		if (actual = expected) then
			report COLOR_GREEN & "  PASS: " & " - got '" & to_hstring(actual) & "' " & msg & COLOR_RESET;
		else
			report COLOR_RED & "  FAIL: " & msg & " - got 0x" & to_hstring(actual) & " expected 0x" & to_hstring(expected) & COLOR_RESET
				severity error;
		end if;
	end procedure;

	procedure assert_equal(
		constant actual : boolean;
		constant expected : boolean;
		constant msg : string
	) is
	begin
		if (actual = expected) then
			report COLOR_GREEN & "  PASS: " & " - got " & boolean'image(actual) & " " & msg & COLOR_RESET;
		else
			report COLOR_RED & "  FAIL: " & msg & " - got " & boolean'image(actual) & " expected " & boolean'image(expected) & COLOR_RESET
				severity error;
		end if;
	end procedure;

	procedure assert_equal(
		constant actual : time;
		constant expected : time;
		constant msg : string
	) is
	begin
		if (actual = expected) then
			report COLOR_GREEN & "  PASS: " & " - got " & time'image(actual) & " " & msg & COLOR_RESET;
		else
			report COLOR_RED & "  FAIL: " & msg & " - got " & time'image(actual) & " expected " & time'image(expected) & COLOR_RESET
				severity error;
		end if;
	end procedure;

	procedure reset_dut(
		signal clk : in std_logic;
		signal rst_out : out std_logic
	) is
	begin
		rst_out <= '1';
		wait until falling_edge(clk);
		rst_out <= '0';
		wait for 0 ns;
	end procedure;

	-- UART stimulus helpers
	procedure uart_rx_byte_timed(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant bit_period : in time;
		constant phase_offset : in time;
		constant bit_skew : in time
	) is
		variable tx_bit_period : time;
	begin
		tx_bit_period := bit_period + bit_skew;

		rxd_o <= '1';
		wait for bit_period;
		wait until rising_edge(clk_i);
		wait for phase_offset;

		rxd_o <= '0';
		wait for tx_bit_period;

		for i in 0 to 7 loop
			rxd_o <= byte_bit(b, i);
			wait for tx_bit_period;
		end loop;

		rxd_o <= '1';
		wait for tx_bit_period;
	end procedure;

	procedure uart_rx_byte_timed_parity(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant parity_bit : in std_logic;
		constant bit_period : in time;
		constant phase_offset : in time;
		constant bit_skew : in time
	) is
		variable tx_bit_period : time;
	begin
		tx_bit_period := bit_period + bit_skew;

		rxd_o <= '1';
		wait for bit_period;
		wait until rising_edge(clk_i);
		wait for phase_offset;

		rxd_o <= '0';
		wait for tx_bit_period;

		for i in 0 to 7 loop
			rxd_o <= byte_bit(b, i);
			wait for tx_bit_period;
		end loop;

		rxd_o <= parity_bit;
		wait for tx_bit_period;

		rxd_o <= '1';
		wait for tx_bit_period;
	end procedure;

	procedure uart_rx_byte_cycles(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant cycles_per_bit : in natural := 1;
		constant pre_idle_cycles : in natural := 1;
		constant stop_cycles : in natural := 1
	) is
	begin
		rxd_o <= '1';
		cycle_clock(clk_i, pre_idle_cycles);

		rxd_o <= '0';
		cycle_clock(clk_i, cycles_per_bit);

		for i in 0 to 7 loop
			rxd_o <= byte_bit(b, i);
			cycle_clock(clk_i, cycles_per_bit);
		end loop;

		rxd_o <= '1';
		cycle_clock(clk_i, stop_cycles);
	end procedure;

	procedure uart_rx_byte_cycles_parity(
		signal clk_i : in std_logic;
		signal rxd_o : out std_logic;
		constant b : in std_logic_vector(7 downto 0);
		constant parity_bit : in std_logic;
		constant cycles_per_bit : in natural := 1;
		constant pre_idle_cycles : in natural := 1;
		constant stop_cycles : in natural := 1
	) is
	begin
		rxd_o <= '1';
		cycle_clock(clk_i, pre_idle_cycles);

		rxd_o <= '0';
		cycle_clock(clk_i, cycles_per_bit);

		for i in 0 to 7 loop
			rxd_o <= byte_bit(b, i);
			cycle_clock(clk_i, cycles_per_bit);
		end loop;

		rxd_o <= parity_bit;
		cycle_clock(clk_i, cycles_per_bit);

		rxd_o <= '1';
		cycle_clock(clk_i, stop_cycles);
	end procedure;

	-- UART tolerance sweeps
	procedure uart_rx_sweep_baud_skew(
		signal reset_clk_i : in std_logic;
		signal clk_i : in std_logic;
		signal rst_o : out std_logic;
		signal rxd_o : out std_logic;
		signal rxav_i : in std_logic;
		signal datao_i : in std_logic_vector(7 downto 0);
		signal parityerr_i : in std_logic;
		constant use_parity_i : in std_logic;
		constant bit_period : in time;
		constant phase_offset : in time;
		constant pattern : in std_logic_vector(7 downto 0);
		variable pass_found_o : out boolean;
		variable neg_pass_limit_o : out time;
		variable pos_pass_limit_o : out time
	) is
		variable skew_offset : time;
		variable max_skew_magnitude : time;
		constant STEP_TIME : time := 1 ns;
		constant REQUIRED_PASSES : natural := 3;
		variable pass_counter : natural;
		variable in_pass_window : boolean;
	begin
		pass_found_o := false;
		neg_pass_limit_o := 0 ps;
		pos_pass_limit_o := 0 ps;
		max_skew_magnitude := bit_period / 6;
		skew_offset := -max_skew_magnitude;
		pass_counter := 0;
		in_pass_window := false;

		while skew_offset <= max_skew_magnitude loop
			reset_dut(reset_clk_i, rst_o);
			rxd_o <= '1';
			cycle_clock(clk_i, 2);

			if (use_parity_i = '1') then
				uart_rx_byte_timed_parity(
					clk_i,
					rxd_o,
					pattern,
					uart_parity_bit(pattern, '1'),
					bit_period,
					phase_offset,
					skew_offset
				);
			else
				uart_rx_byte_timed(clk_i, rxd_o, pattern, bit_period, phase_offset, skew_offset);
			end if;
			wait for bit_period;

			if (rxav_i = '1') and (datao_i = pattern) and ((use_parity_i = '0') or (parityerr_i = '0')) then
				pass_counter := pass_counter + 1;
				if (not in_pass_window) and (pass_counter >= REQUIRED_PASSES) then
					neg_pass_limit_o := skew_offset - (STEP_TIME * (REQUIRED_PASSES - 1));
					pass_found_o := true;
					in_pass_window := true;
				end if;
			else
				pass_counter := 0;
				if in_pass_window then
					pos_pass_limit_o := skew_offset - STEP_TIME;
					exit;
				end if;
			end if;

			skew_offset := skew_offset + STEP_TIME;
		end loop;
		if in_pass_window and (pos_pass_limit_o = 0 ps) then
			pos_pass_limit_o := skew_offset - STEP_TIME;
		end if;
	end procedure;

	procedure uart_rx_fifo_sweep_baud_skew(
		signal reset_clk_i : in std_logic;
		signal sample_clk_i : in std_logic;
		signal fifo_clk_i : in std_logic;
		signal rst_o : out std_logic;
		signal readfifo_o : out std_logic;
		signal rxd_o : out std_logic;
		signal fifo_readack_i : in std_logic;
		signal fifo_readdata_i : in std_logic_vector(7 downto 0);
		constant use_parity_i : in std_logic;
		constant bit_period : in time;
		constant phase_offset : in time;
		constant pattern : in std_logic_vector(7 downto 0);
		variable pass_found_o : out boolean;
		variable neg_pass_limit_o : out time;
		variable pos_pass_limit_o : out time
	) is
		variable skew_offset : time;
		variable max_skew_magnitude : time;
		variable guard_cycles : natural;
		constant STEP_TIME : time := 1 ns;
		constant REQUIRED_PASSES : natural := 3;
		variable pass_counter : natural;
		variable in_pass_window : boolean;
	begin
		pass_found_o := false;
		neg_pass_limit_o := 0 ps;
		pos_pass_limit_o := 0 ps;
		max_skew_magnitude := bit_period / 6;
		skew_offset := -max_skew_magnitude;
		pass_counter := 0;
		in_pass_window := false;

		while skew_offset <= max_skew_magnitude loop
			reset_dut(reset_clk_i, rst_o);
			readfifo_o <= '0';
			rxd_o <= '1';
			cycle_clock(sample_clk_i, 2);

			if (use_parity_i = '1') then
				uart_rx_byte_timed_parity(
					sample_clk_i,
					rxd_o,
					pattern,
					uart_parity_bit(pattern, '1'),
					bit_period,
					phase_offset,
					skew_offset
				);
			else
				uart_rx_byte_timed(sample_clk_i, rxd_o, pattern, bit_period, phase_offset, skew_offset);
			end if;
			cycle_clock(fifo_clk_i, 4);

			wait until falling_edge(fifo_clk_i);
			readfifo_o <= '1';
			guard_cycles := 0;
			while fifo_readack_i /= '1' loop
				wait until falling_edge(fifo_clk_i);
				guard_cycles := guard_cycles + 1;
				exit when guard_cycles > 2; -- takes two cycles to go through FIFO
			end loop;
			if (fifo_readack_i = '1') and (fifo_readdata_i = pattern) then
				pass_counter := pass_counter + 1;
				if (not in_pass_window) and (pass_counter >= REQUIRED_PASSES) then
					neg_pass_limit_o := skew_offset - (STEP_TIME * (REQUIRED_PASSES - 1));
					pass_found_o := true;
					in_pass_window := true;
				end if;
			else
				pass_counter := 0;
				if in_pass_window then
					pos_pass_limit_o := skew_offset - STEP_TIME;
					readfifo_o <= '0';
					exit;
				end if;
			end if;
			readfifo_o <= '0';
			wait until falling_edge(fifo_clk_i);

			skew_offset := skew_offset + STEP_TIME;
		end loop;
		if in_pass_window and (pos_pass_limit_o = 0 ps) then
			pos_pass_limit_o := skew_offset - STEP_TIME;
		end if;
	end procedure;

	-- Test naming / progress output
	procedure set_test_name(
		signal dst : out string;
		constant src : in string
	) is
		variable copy_len : natural;
	begin
		for i in dst'range loop
			dst(i) <= ' ';
		end loop;
		copy_len := src'length;
		if (copy_len > dst'length) then
			copy_len := dst'length;
		end if;
		dst(1 to copy_len) <= src(src'low to src'low + integer(copy_len) - 1);
		wait for 0 ns;
		report COLOR_YELLOW & "TEST: " & src & COLOR_RESET;
	end procedure;

end package body tb_utils_pkg;
