--! \brief Testbench for PPSCount.vhd
--! PPS/reset overlap, edge behavior, counter/accumulation, and PPSDetected.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity PPSCount_tb is
end entity PPSCount_tb;

architecture sim of PPSCount_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal PPS : std_logic;
    signal PPSDetected : std_logic;
    signal PPSCounter : std_logic_vector(31 downto 0);
    signal PPSAccum : std_logic_vector(31 downto 0);
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
        PPS <= '0';

        set_test_name(test_name_display, "Reset defaults");
        reset_dut(clk, rst);
        assert_equal(PPSDetected, '0', "PPSDetected 0 after reset");
        assert_equal(PPSCounter, x"00000000", "PPSCounter 0 after reset");
        assert_equal(PPSAccum, x"00000000", "PPSAccum 0 after reset");

        set_test_name(test_name_display, "Basic PPS count and interval latches");
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPSDetected stays low until two PPS edges are seen");
        assert_equal(PPSCounter, x"00000000", "PPSCounter reset on first rising edge");
        assert_equal(PPSAccum, x"00000000", "PPSAccum 0 after invalidated first rising edge");
        wait until falling_edge(clk);
        assert_equal(PPSCounter, x"00000001", "PPSCounter 1 one clock after rising edge");

        PPS <= '0';
        cycle_clock(clk, 10);
        assert_equal(PPSCounter, x"0000000A", "PPSCounter 10 after 10 low clocks");
        assert_equal(PPSAccum, x"00000000", "PPSAccum unchanged without rising edge");

        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '1', "PPSDetected after second rising edge");
        assert_equal(PPSCounter, x"00000000", "PPSCounter reset on second rising edge");
        assert_equal(PPSAccum, x"0000000C", "PPSAccum 12 (10 + 2) on first valid latch");
        wait until falling_edge(clk);

        PPS <= '0';
        cycle_clock(clk, 15);
        assert_equal(PPSAccum, x"0000000C", "PPSAccum holds latched value");
        assert_equal(PPSCounter, x"0000000F", "PPSCounter 15 during low interval");

        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000011", "PPSAccum 17 (15 + 2) on third rising edge");
        wait until falling_edge(clk);

        PPS <= '0';
        cycle_clock(clk, 20);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000016", "PPSAccum 22 (20 + 2) on fourth rising edge");

        set_test_name(test_name_display, "PPS and reset overlap");
        PPS <= '0';
        rst <= '1';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPSDetected cleared while reset asserted");
        rst <= '0';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "Synthetic rising counts as first edge only");
        assert_equal(PPSAccum, x"00000000", "PPSAccum discarded on synthetic rising edge");

        PPS <= '1';
        rst <= '1';
        wait until falling_edge(clk);
        PPS <= '0';
        wait until falling_edge(clk);
        rst <= '0';
        cycle_clock(clk, 5);
        assert_equal(PPSDetected, '0', "PPSDetected 0 after PPS falls during reset");
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPSDetected stays low on first edge after overlap");

        PPS <= '0';
        wait until falling_edge(clk);
        rst <= '1';
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "Reset dominates when rst and PPS rise together");
        rst <= '0';
        wait until falling_edge(clk);

        rst <= '1';
        PPS <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        PPS <= '0';
        wait until falling_edge(clk);
        cycle_clock(clk, 5);
        assert_equal(PPSDetected, '0', "No false detect when rst and PPS fall together");

        PPS <= '0';
        wait until falling_edge(clk);
        rst <= '1';
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000000", "Reset wins on PPS rising edge, no valid latch");
        rst <= '0';
        wait until falling_edge(clk);

        PPS <= '1';
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPSDetected stays low after reset release with PPS high");
        assert_equal(PPSCounter, x"00000000", "PPSCounter reset after release with PPS high");

        set_test_name(test_name_display, "Falling edge and PPS bounce"); -- Is this correct implementation, should it only be rising edge PPS
        PPS <= '1';
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        PPS <= '0';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '1', "Falling edge sets PPSDetected");
        assert_equal(PPSCounter, x"00000000", "Falling edge does not reset PPSCounter");
        assert_equal(PPSAccum, x"00000000", "Falling edge does not update PPSAccum");
        wait until falling_edge(clk);
        assert_equal(PPSCounter, x"00000001", "Counter resumes after falling-edge pause");

        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000002", "Bounce rise2 latches 0+2=2");
        PPS <= '0';
        wait until falling_edge(clk);
        cycle_clock(clk, 1);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000003", "Bounce rise3 latches 1+2=3");

        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        PPS <= '0';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000000", "Narrow high pulse: first rise discards latch");

        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        cycle_clock(clk, 4);
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"00000007", "Narrow low pulse: latch 5+2=7");

        set_test_name(test_name_display, "Counter and PPSAccum behavior");
        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        cycle_clock(clk, 7);
        assert_equal(PPSCounter, x"00000007", "PPSCounter increments while PPS high");
        assert_equal(PPSAccum, x"00000000", "PPSAccum unchanged without rising edge");

        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        PPS <= '0';
        cycle_clock(clk, 7);
        assert_equal(PPSCounter, x"00000007", "PPSCounter increments while PPS low");

        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        PPS <= '0';
        cycle_clock(clk, 10);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSAccum, x"0000000C", "PPSAccum latched at 12");
        wait until falling_edge(clk);
        cycle_clock(clk, 50);
        assert_equal(PPSAccum, x"0000000C", "PPSAccum stable over 50 clocks");
        assert_equal(PPSCounter, x"00000033", "PPSCounter still increments");

        set_test_name(test_name_display, "PPSDetected sticky, only reset clears");
        PPS <= '0';
        reset_dut(clk, rst);
        cycle_clock(clk, 5);
        assert_equal(PPSDetected, '0', "PPSDetected 0 with no PPS transitions");

        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        PPS <= '0';
        cycle_clock(clk, 10);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '1', "PPSDetected set after valid latch");
        cycle_clock(clk, 10);
        assert_equal(PPSDetected, '1', "PPSDetected sticky across edges");
        reset_dut(clk, rst);
        assert_equal(PPSDetected, '0', "Only reset clears PPSDetected");

        set_test_name(test_name_display, "Variable run variable PPS intervals");
        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        for i in 1 to 100 loop
            PPS <= '0';
            cycle_clock(clk, i mod 257);
            PPS <= '1';
            wait until falling_edge(clk);
            assert_equal(
                PPSAccum,
                std_logic_vector(to_unsigned((i mod 257) + 2, 32)),
                "Variable interval latch " & integer'image(i)
            );
            assert_equal(PPSDetected, '1', "PPSDetected sticky " & integer'image(i));
            wait until falling_edge(clk);
        end loop;
        assert_equal(PPSCounter, x"00000001", "PPSCounter 1 after last rising edge");

        set_test_name(test_name_display, "Long run variable PPS intervals");
        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        for i in 1 to 999 loop
            PPS <= '0';
            cycle_clock(clk, i mod 1000);
            PPS <= '1';
            wait until falling_edge(clk);
            assert_equal(
                PPSAccum,
                std_logic_vector(to_unsigned((i mod 1000) + 2, 32)),
                "Variable interval latch " & integer'image(i)
            );
            assert_equal(PPSDetected, '1', "PPSDetected sticky " & integer'image(i));
            wait until falling_edge(clk);
        end loop;
        assert_equal(PPSCounter, x"00000001", "PPSCounter 1 after last rising edge");

        set_test_name(test_name_display, "PPSDetected takes two PPS edges to set");
        reset_dut(clk, rst);
        PPS <= '1';
        wait until falling_edge(clk);
        PPS <= '0';
        assert_equal(PPSDetected, '0', "PPSDetected 0 after first rising edge");
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '1', "PPSDetected 1 after second rising edge");


        finish;
    end process;

    dut : entity work.PPSCountPorts
        port map (
            clk => clk,
            PPS => PPS,
            PPSReset => rst,
            PPSDetected => PPSDetected,
            PPSCounter => PPSCounter,
            PPSAccum => PPSAccum
        );

end architecture sim;
