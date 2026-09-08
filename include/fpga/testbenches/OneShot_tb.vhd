--! \brief Testbench for OneShot.vhd
--! Exercises multiple one-shot configurations with different delays and reset states.
--! Checks that shots trigger at the expected delay and remain latched until reset.
--! Also covers reset behavior during pre-trigger and post-trigger states.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity OneShot_tb is
end entity OneShot_tb;

architecture sim of OneShot_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal shot_cfg1 : std_logic;
    signal shot_cfg2 : std_logic;
    signal shot_cfg3 : std_logic;
    signal shot_cfg4 : std_logic;
    signal shot_cfg5 : std_logic;
    signal shot_cfg6 : std_logic;
    signal shot_stress : std_logic;
    signal test_name_display : string(1 to 80);
    constant CLK_PERIOD : time := 10 ns;

    constant CFG1_DELAY : natural := natural(real(10000000) * 0.001);
    constant CFG2_DELAY : natural := natural(real(20000000) * 0.0005);
    constant CFG3_DELAY : natural := natural(real(5000000) * 0.002);
    constant CFG4_DELAY : natural := natural(real(10000000) * 0.001);
    constant CFG5_DELAY : natural := natural(real(1000) * 0.001);
    constant CFG6_DELAY : natural := natural(real(1000) * 0.002);

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
        reset_dut(clk, rst);
        assert_equal(shot_cfg1, '0', "cfg1 reset state");
        assert_equal(shot_cfg2, '0', "cfg2 reset state");
        assert_equal(shot_cfg3, '0', "cfg3 reset state");
        assert_equal(shot_cfg4, '1', "cfg4 reset state");
        assert_equal(shot_cfg5, '0', "cfg5 reset state");
        assert_equal(shot_cfg6, '0', "cfg6 reset state");

        set_test_name(test_name_display, "cfg5 minimum delay (1 cycle)");
        reset_dut(clk, rst);
        expect_stable(shot_cfg5, '0', CFG5_DELAY - 1, "cfg5 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg5, '1', "cfg5 trigger");
        expect_stable(shot_cfg5, '1', 20, "cfg5 latched");

        set_test_name(test_name_display, "cfg6 two-cycle delay");
        reset_dut(clk, rst);
        expect_stable(shot_cfg6, '0', CFG6_DELAY - 1, "cfg6 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg6, '1', "cfg6 trigger");
        expect_stable(shot_cfg6, '1', 20, "cfg6 latched");

        set_test_name(test_name_display, "cfg1 pretrigger boundary then latch");
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', CFG1_DELAY - 2, "cfg1 pretrigger window");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 one cycle before trigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 shot asserts at delay");
        expect_stable(shot_cfg1, '1', 64, "cfg1 latched post trigger");

        set_test_name(test_name_display, "cfg2 alternate delay");
        reset_dut(clk, rst);
        expect_stable(shot_cfg2, '0', CFG2_DELAY - 1, "cfg2 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg2, '1', "cfg2 shot asserts at delay");
        expect_stable(shot_cfg2, '1', 40, "cfg2 latched post trigger");

        set_test_name(test_name_display, "cfg3 long delay");
        reset_dut(clk, rst);
        expect_stable(shot_cfg3, '0', CFG3_DELAY - 1, "cfg3 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg3, '1', "cfg3 shot asserts at delay");
        expect_stable(shot_cfg3, '1', 40, "cfg3 latched post trigger");

        set_test_name(test_name_display, "cfg4 inverted pretrigger");
        reset_dut(clk, rst);
        expect_stable(shot_cfg4, '1', CFG4_DELAY - 1, "cfg4 pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg4, '0', "cfg4 shot asserts at delay");
        expect_stable(shot_cfg4, '0', 64, "cfg4 latched post trigger");

        set_test_name(test_name_display, "Reset before trigger restarts countdown");
        reset_dut(clk, rst);
        cycle_clock(clk, 150);
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 reset asserted while pretrigger");
        rst <= '0';
        expect_stable(shot_cfg1, '0', CFG1_DELAY - 1, "cfg1 restarted pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 re-triggers after full delay");

        set_test_name(test_name_display, "Reset after trigger clears latch");
        reset_dut(clk, rst);
        expect_stable(shot_cfg1, '0', CFG1_DELAY - 1, "cfg1 pretrigger for reset-after-trigger");
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '1', "cfg1 triggered before reset-after-trigger");
        cycle_clock(clk, 30);
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(shot_cfg1, '0', "cfg1 reset clears latched shot");
        rst <= '0';
        expect_stable(shot_cfg1, '0', 20, "cfg1 remains pretrigger after reset release");

        set_test_name(test_name_display, "Reset restores one-shot");
        reset_dut(clk, rst);
        assert_equal(shot_cfg1, '0', "cfg1 back to reset state");

        set_test_name(test_name_display, "Large fixed delay count");
        reset_dut(clk, rst);
        expect_stable(shot_stress, '0', 49999, "stress pretrigger");
        wait until falling_edge(clk);
        assert_equal(shot_stress, '1', "stress shot at large delay");
        expect_stable(shot_stress, '1', 32, "stress latched post trigger");

        finish;

    end process;

    dut_cfg1: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 10000000,
            DELAY_SECONDS => 0.001,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_cfg1
        );

    dut_cfg2: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 20000000,
            DELAY_SECONDS => 0.0005,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_cfg2
        );

    dut_cfg3: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 5000000,
            DELAY_SECONDS => 0.002,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_cfg3
        );

    dut_cfg4: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 10000000,
            DELAY_SECONDS => 0.001,
            SHOT_RST_STATE => '1',
            SHOT_PRETRIGGER_STATE => '1'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_cfg4
        );

    dut_cfg5: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 1000,
            DELAY_SECONDS => 0.001,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_cfg5
        );

    dut_cfg6: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 1000,
            DELAY_SECONDS => 0.002,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_cfg6
        );

    dut_stress: entity work.OneShotPorts
        generic map (
            CLOCK_FREQHZ => 50000,
            DELAY_SECONDS => 1.0,
            SHOT_RST_STATE => '0',
            SHOT_PRETRIGGER_STATE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            shot => shot_stress
        );

end architecture sim;