--! \brief Testbench for IOBufP3.vhd
--! Checks that O tracks the IO pad with a three-cycle delay in both input (T=0) and output (T=1) modes.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity IOBufP3_tb is
end IOBufP3_tb;

architecture sim of IOBufP3_tb is

    signal clk : std_logic;
    signal T : std_logic;
    signal I : std_logic;
    signal IO_drv : std_logic;
    signal IO : std_logic;
    signal O : std_logic;

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

    IO <= IO_drv when T = '0' else 'Z';

    test_process : process
    begin
        T <= '0';
        I <= '0';
        IO_drv <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);

        -- Input mode
        set_test_name(test_name_display, "input mode IO=0");
        IO_drv <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O, '0', "O should be 0 when IO is 0");

        set_test_name(test_name_display, "input mode IO=1");
        IO_drv <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O, '1', "O should be 1 when IO is 1");

        set_test_name(test_name_display, "input mode IO=0");
        IO_drv <= '0';
        I <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O, '0', "O should be 0 when IO is 0");

        -- Output mode
        set_test_name(test_name_display, "output mode I=0");
        T <= '1';
        I <= '0';
        IO_drv <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O, '0', "O should be 0 when I is 0");

        set_test_name(test_name_display, "output mode I=1");
        I <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O, '1', "O should be 1 when I is 1");

        set_test_name(test_name_display, "output mode I=0");
        I <= '0';
        IO_drv <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(O, '0', "O should be 0 when I is 0");

        finish;
    end process;

    dut : entity work.IOBufP3Ports
        port map (
            clk => clk,
            IO => IO,
            T => T,
            I => I,
            O => O
        );

end architecture;
