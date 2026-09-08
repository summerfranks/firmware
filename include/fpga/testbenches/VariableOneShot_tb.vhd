--! \brief Testbench for VariableOneShot.vhd
--! Programmable delay values (small/normal/large).
--! Covers delay changes before trigger, pretrigger variants, and reset recovery.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity VariableOneShot_tb is
end entity VariableOneShot_tb;

architecture sim of VariableOneShot_tb is

    signal clk : std_logic;
    signal rst : std_logic;

    signal shot_cfg1 : std_logic;
    signal shot_cfg2 : std_logic;
    signal shot_cfg3 : std_logic;
    signal shot_cfg4 : std_logic;

    constant DEFAULT_WIDTH_BITS : natural := 8;
    constant MAX_DELAY_CYCLES : natural := (2**DEFAULT_WIDTH_BITS) - 1;

    signal test_name_display : string(1 to 80);
    constant CLK_PERIOD : time := 10 ns;
    signal delay_clks : std_logic_vector(DEFAULT_WIDTH_BITS - 1 downto 0);

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
    begin
        set_test_name(test_name_display, "Reset states");
        delay_clks <= (others => '0');
        reset_dut(clk, rst);
        assert_equal(shot_cfg1, '0', "cfg1 reset state");
        assert_equal(shot_cfg2, '1', "cfg2 reset state");
        assert_equal(shot_cfg3, '0', "cfg3 reset state");
        assert_equal(shot_cfg4, '1', "cfg4 reset state");

        set_test_name(test_name_display, "cfg1 delay=0 immediate trigger");
        delay_clks <= std_logic_vector(to_unsigned(0, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 immediate trigger");
        expect_stable(shot_cfg1, '1', 40, "cfg1 latched");

        set_test_name(test_name_display, "cfg1 delay=10 nominal");
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 10, "cfg1 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 trigger");
        expect_stable(shot_cfg1, '1', 40, "cfg1 post-trigger hold");

        set_test_name(test_name_display, "cfg1 delay=1 edge case");
        delay_clks <= std_logic_vector(to_unsigned(1, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 1, "cfg1 delay1 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 delay1 trigger");
        expect_stable(shot_cfg1, '1', 20, "cfg1 delay1 latched");

        set_test_name(test_name_display, "cfg1 runtime delay change without reset");
        delay_clks <= std_logic_vector(to_unsigned(20, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 4, "cfg1 long-delay pretrigger");
        delay_clks <= std_logic_vector(to_unsigned(6, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 still pretrigger on retune cycle");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 still pretrigger one more cycle after retune");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 triggers after shortened runtime delay");

        set_test_name(test_name_display, "cfg1 runtime delay decrease mid-count");
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 7, "cfg1 counting to 10 at 7");
        delay_clks <= std_logic_vector(to_unsigned(5, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 triggers when delay lowered below count");

        set_test_name(test_name_display, "cfg1 runtime delay at terminal count");
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 10, "cfg1 at terminal delay");
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 same delay at terminal still triggers");
        reset_dut(clk, rst);
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        expect_stable(shot_cfg1, '0', 10, "cfg1 at terminal before lower");
        delay_clks <= std_logic_vector(to_unsigned(5, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 lower delay at terminal triggers");
        reset_dut(clk, rst);
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        expect_stable(shot_cfg1, '0', 10, "cfg1 at terminal before higher");
        delay_clks <= std_logic_vector(to_unsigned(15, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 higher delay at terminal extends wait");
        expect_stable(shot_cfg1, '0', 4, "cfg1 counts to new delay");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 triggers at raised delay");

        set_test_name(test_name_display, "cfg1 runtime delay increase mid-count");
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 7, "cfg1 partway through delay");
        delay_clks <= std_logic_vector(to_unsigned(20, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 still pretrigger after mid-count raise");
        expect_stable(shot_cfg1, '0', 12, "cfg1 counts to raised delay");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 triggers at raised delay");
        expect_stable(shot_cfg1, '1', 20, "cfg1 latched after raised delay");

        set_test_name(test_name_display, "cfg2 delay=6 with rst high");
        delay_clks <= std_logic_vector(to_unsigned(6, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        expect_stable(shot_cfg2, '0', 5, "cfg2 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg2, '1', "cfg2 trigger");
        expect_stable(shot_cfg2, '1', 40, "cfg2 latched");

        set_test_name(test_name_display, "cfg3 pretrigger-high behavior");
        delay_clks <= std_logic_vector(to_unsigned(12, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        expect_stable(shot_cfg3, '1', 11, "cfg3 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg3, '0', "cfg3 trigger");
        expect_stable(shot_cfg3, '0', 40, "cfg3 latched");

        set_test_name(test_name_display, "cfg4 max delay and reset recovery");
        delay_clks <= std_logic_vector(to_unsigned(MAX_DELAY_CYCLES, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg4, '1', MAX_DELAY_CYCLES, "cfg4 max pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg4, '0', "cfg4 max trigger");
        expect_stable(shot_cfg4, '0', 32, "cfg4 max latched");
        reset_dut(clk, rst);
        assert_equal(shot_cfg4, '1', "cfg4 reset recovery");

        set_test_name(test_name_display, "cfg1 reset before trigger restarts countdown");
        delay_clks <= std_logic_vector(to_unsigned(15, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 10, "cfg1 pretrigger before reset");
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 reset while pretrigger");
        rst <= '0';
        expect_stable(shot_cfg1, '0', 15, "cfg1 restarted pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 retrigger after full restarted delay");

        set_test_name(test_name_display, "cfg1 reset after trigger clears latch");
        delay_clks <= std_logic_vector(to_unsigned(10, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', 10, "cfg1 pretrigger for reset-after-trigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 triggered before reset-after-trigger");
        cycle_clock(clk, 20);
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 reset clears latched shot");
        rst <= '0';
        expect_stable(shot_cfg1, '0', 10, "cfg1 remains pretrigger after reset release");

        set_test_name(test_name_display, "cfg3 runtime delay change while pretrigger-high");
        delay_clks <= std_logic_vector(to_unsigned(20, DEFAULT_WIDTH_BITS));
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        expect_stable(shot_cfg3, '1', 4, "cfg3 long pretrigger");
        delay_clks <= std_logic_vector(to_unsigned(6, DEFAULT_WIDTH_BITS));
        wait until falling_edge(clk);
        assert_equal(shot_cfg3, '1', "cfg3 still pretrigger on retune cycle");
        wait until falling_edge(clk);
        assert_equal(shot_cfg3, '0', "cfg3 fires after shortened delay");

        finish;
    end process;

    dut_cfg1 : entity work.VariableOneShotPorts
        generic map (
            WIDTH_BITS => DEFAULT_WIDTH_BITS,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            delay_clks => delay_clks,
            shot => shot_cfg1
        );

    dut_cfg2 : entity work.VariableOneShotPorts
        generic map (
            WIDTH_BITS => DEFAULT_WIDTH_BITS,
            SHOT_RST_STATE => '1',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            delay_clks => delay_clks,
            shot => shot_cfg2
        );

    dut_cfg3 : entity work.VariableOneShotPorts
        generic map (
            WIDTH_BITS => DEFAULT_WIDTH_BITS,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '1'
        )
        port map (
            clk => clk,
            rst => rst,
            delay_clks => delay_clks,
            shot => shot_cfg3
        );

    dut_cfg4 : entity work.VariableOneShotPorts
        generic map (
            WIDTH_BITS => DEFAULT_WIDTH_BITS,
            SHOT_RST_STATE => '1',
            SHOT_PRETRIGGER_STATE => '1'
        )
        port map (
            clk => clk,
            rst => rst,
            delay_clks => delay_clks,
            shot => shot_cfg4
        );

end architecture sim;