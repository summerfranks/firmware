--! \brief Testbench for ClockDivider2X.vhd
--! Reset polarity and initial state checks across configs.
--! Confirms expected divide cadence div10 (low: 0,1,2,3,4, high: 5,6,7,8,9).
--! Also tests mid-run reset recovery and a long stress cadence.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity ClockDivider2X_tb is
end entity ClockDivider2X_tb;

architecture sim of ClockDivider2X_tb is

	signal clk : std_logic;
	signal rst : std_logic;

	constant CLK_PERIOD : time := 10 ns;

	signal div_cfg1 : std_logic;
	signal div_cfg2 : std_logic;
	signal div_cfg3 : std_logic;
	signal div_cfg4 : std_logic;
	signal div_cfg5 : std_logic;
	signal div_cfg6 : std_logic;
	signal div_stress : std_logic;

	signal test_name_display : string(1 to 80);

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
		set_test_name(test_name_display, "Reset states");
		reset_dut(clk, rst);
		assert_equal(div_cfg1, '0', "cfg1 reset state");
		assert_equal(div_cfg2, '0', "cfg2 reset state");
		assert_equal(div_cfg3, '1', "cfg3 reset state");
		assert_equal(div_cfg4, '0', "cfg4 reset state");
		assert_equal(div_cfg5, '0', "cfg5 reset state");
		assert_equal(div_cfg6, '0', "cfg6 reset state");

		set_test_name(test_name_display, "cfg1 div10 toggle period");
		expected := '0';
		for t in 1 to 36 loop
			expect_stable(div_cfg1, expected, 4, "cfg1 hold before toggle");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(div_cfg1, expected, "cfg1 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg2 div6 toggle period");
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 54 loop
			expect_stable(div_cfg2, expected, 2, "cfg2 hold before toggle");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(div_cfg2, expected, "cfg2 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg3 div10 inverted reset");
		reset_dut(clk, rst);
		expected := '1';
		for t in 1 to 30 loop
			expect_stable(div_cfg3, expected, 4, "cfg3 hold before toggle");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(div_cfg3, expected, "cfg3 toggle " & integer'image(t));
		end loop;

		-- Odd divider has a 3:2 duty cycle pattern, assuming this is not intended to be used for a clock output just verifying the pattern is consistent with the counter behavior
		set_test_name(test_name_display, "cfg4 odd divider decoded duty");
		reset_dut(clk, rst);
		for t in 1 to 60 loop
			wait until falling_edge(clk);
			if ((t mod 5) = 1 or (t mod 5) = 0) then
				assert_equal(div_cfg4, '0', "cfg4 odd pattern low " & integer'image(t));
			else
				assert_equal(div_cfg4, '1', "cfg4 odd pattern high " & integer'image(t));
			end if;
		end loop;

		set_test_name(test_name_display, "cfg5 divider=1 remains reset state");
		reset_dut(clk, rst);
		expect_stable(div_cfg5, '0', 120, "cfg5 constant low");

		set_test_name(test_name_display, "cfg6 divider=2 toggles each cycle");
		reset_dut(clk, rst);
		expected := '0';
		for t in 1 to 80 loop
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(div_cfg6, expected, "cfg6 toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "cfg1 mid-run reset from low phase");
		cycle_clock(clk, 3);
		rst <= '1';
		wait until falling_edge(clk);
		assert_equal(div_cfg1, '0', "cfg1 reset asserted");
		rst <= '0';
		expect_stable(div_cfg1, '0', 4, "cfg1 restarts after reset");
		wait until falling_edge(clk);
		assert_equal(div_cfg1, '1', "cfg1 toggles after restart");

		set_test_name(test_name_display, "cfg1 mid-run reset from high phase");
		cycle_clock(clk, 5);
		rst <= '1';
		wait until falling_edge(clk);
		assert_equal(div_cfg1, '0', "cfg1 forced to reset state");
		rst <= '0';
		expect_stable(div_cfg1, '0', 4, "cfg1 low hold after reset");
		wait until falling_edge(clk);
		assert_equal(div_cfg1, '1', "cfg1 resumes cadence after second reset");

		set_test_name(test_name_display, "cfg1 reset at counter terminal");
		reset_dut(clk, rst);
		expect_stable(div_cfg1, '0', 4, "cfg1 low phase before terminal");
		rst <= '1';
		wait until falling_edge(clk);
		assert_equal(div_cfg1, '0', "cfg1 reset at terminal count");
		rst <= '0';
		expect_stable(div_cfg1, '0', 4, "cfg1 restarts after terminal reset");
		wait until falling_edge(clk);
		assert_equal(div_cfg1, '1', "cfg1 toggles after terminal reset");

		set_test_name(test_name_display, "cfg1 long stress cadence");
		expected := div_cfg1;
		for t in 1 to 100 loop
			expect_stable(div_cfg1, expected, 4, "cfg1 stress hold");
			wait until falling_edge(clk);
			expected := not expected;
			assert_equal(div_cfg1, expected, "cfg1 stress toggle " & integer'image(t));
		end loop;

		set_test_name(test_name_display, "Large fixed divider count");
		reset_dut(clk, rst);
		expect_stable(div_stress, '0', 24999, "stress low half-period");
		wait until falling_edge(clk);
		assert_equal(div_stress, '1', "stress toggle after large count");
		expect_stable(div_stress, '1', 24999, "stress high half-period");
		wait until falling_edge(clk);
		assert_equal(div_stress, '0', "stress second toggle after large count");

		finish;
	end process;

	dut_cfg1: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 10,
			DIVOUT_RST_STATE => '0'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_cfg1
		);

	dut_cfg2: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 6,
			DIVOUT_RST_STATE => '0'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_cfg2
		);

	dut_cfg3: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 10,
			DIVOUT_RST_STATE => '1'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_cfg3
		);

	dut_cfg4: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 5,
			DIVOUT_RST_STATE => '0'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_cfg4
		);

	-- Not testing divider = 0 because then out of bounds

	dut_cfg5: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 1,
			DIVOUT_RST_STATE => '0'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_cfg5
		);

	dut_cfg6: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 2,
			DIVOUT_RST_STATE => '0'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_cfg6
		);

	dut_stress: entity work.ClockDivider2XPorts
		generic map (
			CLOCK_DIVIDER => 50000,
			DIVOUT_RST_STATE => '0'
		)
		port map (
			clk => clk,
			rst => rst,
			div => div_stress
		);

end architecture sim;
