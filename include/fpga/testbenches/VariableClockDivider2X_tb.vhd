--! \brief Testbench for VariableClockDivider2X.vhd
--! Same idea as VariableClockDivider_tb.vhd, applied to the 2X implementation.
--! Checks dynamic terminal-count changes and reset recovery.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity VariableClockDivider2X_tb is
end entity VariableClockDivider2X_tb;

architecture sim of VariableClockDivider2X_tb is

	constant WIDTH_BITS : natural := 8;

	signal clk : std_logic;
	signal rst : std_logic;

	constant CLK_PERIOD : time := 10 ns;

	signal rst_count : std_logic_vector(WIDTH_BITS - 1 downto 0);
	signal terminal_count : std_logic_vector(WIDTH_BITS - 1 downto 0);

	signal clko_cfg1 : std_logic;
	signal clko_cfg2 : std_logic;

	signal test_name_display : string(1 to 80);

	constant RST_HIGH : std_logic := '1';
	constant RST_LOW : std_logic := '0';

	procedure expect_stable(
		signal observed : in std_logic;
		constant expected : std_logic;
		constant cycles : natural;
		constant check_name : string
	) is
	begin
		for i in 0 to cycles loop
			assert_equal(observed, expected, check_name & " cycle " & integer'image(i));
			if (i < cycles) then
				wait until falling_edge(clk);
			end if;
		end loop;
	end procedure;

begin

	clk_process : process
	begin
		clk <= '0';
		wait for CLK_PERIOD / 2;
		clk <= '1';
		wait for CLK_PERIOD / 2;
	end process;

	test_process : process
		variable expected : std_logic;
	begin
		rst_count <= (others => '0');
		terminal_count <= (others => '0');

		set_test_name(test_name_display, "Reset states");
		reset_dut(clk, rst);
		assert_equal(clko_cfg1, '0', "cfg1 reset state");
		assert_equal(clko_cfg2, '1', "cfg2 reset state");

		set_test_name(test_name_display, "cfg1 TC=0 holds reset state");
		terminal_count <= std_logic_vector(to_unsigned(0, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 120, "cfg1 tc0 constant");

		-- low: 0,1,2,3,4 high: 5,6,7,8,9
		set_test_name(test_name_display, "cfg1 div10 toggle period");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 30 loop
			expect_stable(clko_cfg1, expected, 4, "cfg1 hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 div6 toggle period");
		terminal_count <= std_logic_vector(to_unsigned(6 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 36 loop
			expect_stable(clko_cfg1, expected, 2, "cfg1 hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 runtime retune without reset");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 2, "cfg1 before live retune");
		terminal_count <= std_logic_vector(to_unsigned(4 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 toggles after live retune");
		expect_stable(clko_cfg1, '1', 0, "cfg1 hold high after retune");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 retuned next toggle");

		set_test_name(test_name_display, "cfg1 runtime TC decrease mid-count");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 3, "cfg1 partway through div10 low");
		terminal_count <= std_logic_vector(to_unsigned(6 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		expected := clko_cfg1;
		expect_stable(clko_cfg1, expected, 1, "cfg1 shortened high after TC drop");
		wait until falling_edge(clk);
		expected := not expected;
		assert_equal(clko_cfg1, expected, "cfg1 wraps low at new TC");
		for t in 1 to 3 loop
			expect_stable(clko_cfg1, expected, 2, "cfg1 div6 half");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 div6 after TC drop " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 runtime TC at terminal count");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 4, "cfg1 low phase before terminal");
		wait until falling_edge(clk);
		expect_stable(clko_cfg1, '1', 4, "cfg1 high phase before terminal");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 same TC at terminal wraps low");
		reset_dut(clk, rst);
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		expect_stable(clko_cfg1, '0', 4, "cfg1 low before lower TC at terminal");
		wait until falling_edge(clk);
		expect_stable(clko_cfg1, '1', 4, "cfg1 high before lower TC at terminal");
		terminal_count <= std_logic_vector(to_unsigned(4 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 lower TC at terminal wraps low");
		reset_dut(clk, rst);
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		expect_stable(clko_cfg1, '0', 4, "cfg1 low before higher TC at terminal");
		wait until falling_edge(clk);
		expect_stable(clko_cfg1, '1', 4, "cfg1 high before higher TC at terminal");
		terminal_count <= std_logic_vector(to_unsigned(16 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 higher TC at terminal stays high");
		expect_stable(clko_cfg1, '1', 5, "cfg1 counts high to new TC");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 wraps low at raised TC");

		set_test_name(test_name_display, "cfg1 runtime TC increase mid-count");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 2, "cfg1 partway through div10 low");
		terminal_count <= std_logic_vector(to_unsigned(20 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 still low after mid-count TC raise");
		expect_stable(clko_cfg1, '0', 6, "cfg1 counts to raised TC low phase");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 enters high at raised TC");
		expect_stable(clko_cfg1, '1', 9, "cfg1 holds high for div20");

		set_test_name(test_name_display, "cfg1 TC change mid high phase");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 4, "cfg1 low before mid-high retune");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 enters high phase");
		expect_stable(clko_cfg1, '1', 4, "cfg1 at terminal count in high");
		terminal_count <= std_logic_vector(to_unsigned(4 - 1, WIDTH_BITS));
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 wraps low when TC drops below count in high");

		set_test_name(test_name_display, "cfg2 div10 inverted reset");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expected := '1';
		for t in 1 to 30 loop
			expect_stable(clko_cfg2, expected, 4, "cfg2 hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg2, expected, "cfg2 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 div2 toggle period");
		terminal_count <= std_logic_vector(to_unsigned(2 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 80 loop
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 max terminal count");
		terminal_count <= std_logic_vector(to_unsigned((2**WIDTH_BITS) - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 127, "cfg1 max low half-window");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 max enters high half-window");
		expect_stable(clko_cfg1, '1', 127, "cfg1 max high half-window");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 max completes full period");

		set_test_name(test_name_display, "cfg1 rst_count shifts phase");
		rst_count <= std_logic_vector(to_unsigned(3, WIDTH_BITS));
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 1, "cfg1 rst_count hold");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 first toggle after rst_count");

		set_test_name(test_name_display, "cfg1 rst_count >= terminal_count wraps counter");
		rst_count <= std_logic_vector(to_unsigned(10, WIDTH_BITS));
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		reset_dut(clk, rst);
		expect_stable(clko_cfg1, '0', 5, "cfg1 low phase after rst_count preload");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '1', "cfg1 high phase after preload wraps");
		expect_stable(clko_cfg1, '1', 4, "cfg1 hold high after preload wrap");
		wait until falling_edge(clk);
		assert_equal(clko_cfg1, '0', "cfg1 next toggle after full interval");

		set_test_name(test_name_display, "cfg1 long stress cadence");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 120 loop
			expect_stable(clko_cfg1, expected, 4, "cfg1 stress hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 stress toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 retune TC between stable phases");
		terminal_count <= std_logic_vector(to_unsigned(10 - 1, WIDTH_BITS));
		rst_count <= (others => '0');
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 12 loop
			expect_stable(clko_cfg1, expected, 4, "cfg1 div10 hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 div10 toggle " & integer'image(t));
		end loop;
		terminal_count <= std_logic_vector(to_unsigned(4 - 1, WIDTH_BITS));
		expected := '0';
		for t in 1 to 12 loop
			expect_stable(clko_cfg1, expected, 1, "cfg1 div4 hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 div4 toggle " & integer'image(t));
		end loop;
		terminal_count <= std_logic_vector(to_unsigned(2 - 1, WIDTH_BITS));
		expected := '0';
		for t in 1 to 12 loop
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(clko_cfg1, expected, "cfg1 div2 toggle " & integer'image(t));
		end loop;

		finish;
	end process;

	dut_cfg1 : entity work.VariableClockDivider2XPorts
		generic map (
			WIDTH_BITS => WIDTH_BITS,
			DIVOUT_RST_STATE => RST_LOW
		)
		port map (
			clki => clk,
			rst => rst,
			rst_count => rst_count,
			terminal_count => terminal_count,
			clko => clko_cfg1
		);

	dut_cfg2 : entity work.VariableClockDivider2XPorts
		generic map (
			WIDTH_BITS => WIDTH_BITS,
			DIVOUT_RST_STATE => RST_HIGH
		)
		port map (
			clki => clk,
			rst => rst,
			rst_count => rst_count,
			terminal_count => terminal_count,
			clko => clko_cfg2
		);

end architecture sim;
