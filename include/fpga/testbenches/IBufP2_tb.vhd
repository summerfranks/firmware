--! \brief Testbench for IBufP2.vhd
--! Checks reset behavior and that O1/O2 track I with the 2 cycle delay.
--! Also confirms that reset clears the pipeline and sets outputs to the configured reset value.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity IBufP2_tb is
end IBufP2_tb;

architecture sim of IBufP2_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal I : std_logic;
    signal O1 : std_logic;
    signal O2 : std_logic;

    signal test_name_display : string(1 to 80);

    constant CLK_PERIOD : time := 10 ns;

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
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        assert_equal(O1, '0', "O1 should be 0 after reset");
        assert_equal(O2, '1', "O2 should be 1 after reset");

        set_test_name(test_name_display, "I=0");
        I <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O1, '0', "O1 should be 0 when I is 0");
        assert_equal(O2, '0', "O2 should be 0 when I is 0");

        set_test_name(test_name_display, "I=1");
        I <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O1, '1', "O1 should be 1 when I is 1");
        assert_equal(O2, '1', "O2 should be 1 when I is 1");

        set_test_name(test_name_display, "I=0");
        I <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O1, '0', "O1 should be 0 when I is 0");
        assert_equal(O2, '0', "O2 should be 0 when I is 0");

        set_test_name(test_name_display, "I=1");
        I <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O1, '1', "O1 should be 1 when I is 1");
        assert_equal(O2, '1', "O2 should be 1 when I is 1");

        set_test_name(test_name_display, "Check Pipeline is fully reset");
        reset_dut(clk, rst);
        assert_equal(O1, '0', "O1 should be 0 after reset");
        assert_equal(O2, '1', "O2 should be 1 after reset");
        wait until falling_edge(clk);
        assert_equal(O1, '0', "O1 should be 0 after reset");
        assert_equal(O2, '1', "O2 should be 1 after reset");
        wait until falling_edge(clk); -- at this point the previous I <= 1 has moved through
        assert_equal(O1, '1', "O1 should be 1 after reset");
        assert_equal(O2, '1', "O2 should be 1 after reset");


        finish;
    end process;

    dut1 : entity work.IBufP2Ports
        generic map (
            RESET_VALUE => '0'
        )
        port map (
            clk => clk,
            rst => rst,
            I => I,
            O => O1
        );

    dut2 : entity work.IBufP2Ports
        generic map (
            RESET_VALUE => '1'
        )
        port map (
            clk => clk,
            rst => rst,
            I => I,
            O => O2
        );

end architecture;