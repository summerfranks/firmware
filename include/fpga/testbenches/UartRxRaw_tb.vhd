--! \brief Testbench for UartRxRaw.vhd
--! Make sure sampling/enable gating and stop-bit timing rules hold.
--! Basic decode, full byte range, completion signals (normal behavior)
--! Includes baud mismatch, back-to-back frames, and reset mid-frame.
--! Latest baud result: Baud range of 115200: 109232 - 121969 baud (-5.549864035191298% / +5.4632451496476895%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartRXRaw_tb is
end UartRXRaw_tb;

architecture sim of UartRXRaw_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal Enable : std_logic;
    signal RxD : std_logic;
    signal RxAv : std_logic;
    signal DataO : std_logic_vector(7 downto 0);
    signal tb_unused_parityerr : std_logic := '0';

    signal test_name_display : string(1 to 80);

    constant BAUDRATE : natural := 115200;
    constant UART_FRAME_BITS : natural := 10;
    constant UART_SAMPLES_PER_BIT : natural := 16;
    constant BIT_PERIOD : time := 1 sec / BAUDRATE;
    constant SAMPLE_CLK_PERIOD : time := BIT_PERIOD / UART_SAMPLES_PER_BIT;
    constant BAUD_TOLERANCE_PCT : real := uart_baud_tolerance_pct(UART_FRAME_BITS);
    constant PREDICTED_SKEW_ALLOWANCE : time := predicted_skew_allowance(BIT_PERIOD, BAUD_TOLERANCE_PCT);

begin

    clk_process : process
    begin
        clk <= '0';
        wait for SAMPLE_CLK_PERIOD / 2;
        clk <= '1';
        wait for SAMPLE_CLK_PERIOD / 2;
    end process;

    test_process : process
        variable pass_found : boolean;
        variable neg_pass_limit : time;
        variable pos_pass_limit : time;
        variable worst_neg_pass_limit : time;
        variable worst_pos_pass_limit : time;
    begin
        set_test_name(test_name_display, "Reset");
        Enable <= '0';
        RxD <= '1';
        reset_dut(clk, rst);
        assert_equal(RxAv, '0', "RxAv should be 0 after reset");
        assert_equal(DataO, x"00", "DataO should be 0 after reset");

        set_test_name(test_name_display, "Enable=0 ignores RxD");
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT * 8);
        assert_equal(RxAv, '0', "RxAv should remain 0 when disabled");
        assert_equal(DataO, x"00", "DataO should remain 0 when disabled");
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        set_test_name(test_name_display, "Receive bytes (basic patterns)");
        Enable <= '1';
        assert_equal(RxAv, '0', "RxAv starts low");

        uart_rx_byte_cycles(clk, RxD, x"55", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"55", "DataO = 0x55 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive (sticky until next frame)");

        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '0';
        cycle_clock(clk, 2);
        assert_equal(RxAv, '0', "RxAv clears quickly after byte begins");
        cycle_clock(clk, UART_SAMPLES_PER_BIT - 2);
        for i in 0 to 7 loop
            RxD <= byte_bit(x"00", i);
            cycle_clock(clk, UART_SAMPLES_PER_BIT);
        end loop;
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"00", "DataO = 0x00 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        uart_rx_byte_cycles(clk, RxD, x"FF", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"FF", "DataO = 0xFF after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        uart_rx_byte_cycles(clk, RxD, x"01", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"01", "DataO = 0x01 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        uart_rx_byte_cycles(clk, RxD, x"80", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"80", "DataO = 0x80 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        set_test_name(test_name_display, "Baud mismatch");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        uart_rx_byte_cycles(clk, RxD, x"C3", cycles_per_bit => 15, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"C3", "DataO = 0xC3 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        reset_dut(clk, rst);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        uart_rx_byte_cycles(clk, RxD, x"3C", cycles_per_bit => 17, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"3C", "DataO = 0x3C after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        reset_dut(clk, rst);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        -- the FF bits and long  cause it to end early (so FE)
        uart_rx_byte_cycles(clk, RxD, x"FF", cycles_per_bit => 24, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"FE", "DataO = 0x00 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        reset_dut(clk, rst);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        -- the clocks are too short so intentional no RxAv
        uart_rx_byte_cycles(clk, RxD, x"FF", cycles_per_bit => 5, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"00", "DataO = 0x00 after receive");
        assert_equal(RxAv, '0', "RxAv asserted after receive");

        set_test_name(test_name_display, "SampleCnt=7 sampling point");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        assert_equal(RxAv, '0', "RxAv low after reset");
        -- each data bit is wrong except around the SampleCnt=7 instant.
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        for i in 0 to 7 loop
            RxD <= not byte_bit(x"A5", i);
            cycle_clock(clk, 7);
            RxD <= byte_bit(x"A5", i);
            cycle_clock(clk, 2);
            RxD <= not byte_bit(x"A5", i);
            cycle_clock(clk, 7);
        end loop;
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"A5", "Captured data matches value at SampleCnt=7");
        assert_equal(RxAv, '1', "RxAv asserted after receive");

        set_test_name(test_name_display, "Reject start glitch not low at SampleCnt=7");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(clk, RxD, x"3C", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"3C", "DataO should capture the reference byte before glitch test");
        assert_equal(RxAv, '1', "RxAv should be high before the glitch test starts");
        RxD <= '0';
        cycle_clock(clk, 2);
        assert_equal(RxAv, '0', "RxAv should clear immediately on candidate start");
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(RxAv, '0', "RxAv should remain low after rejected start glitch");
        assert_equal(DataO, x"3C", "DataO should not change after rejected start glitch");
        uart_rx_byte_cycles(clk, RxD, x"A6", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"A6", "Receiver should recover after rejected start glitch");
        assert_equal(RxAv, '1', "RxAv should assert after the recovery byte");

        set_test_name(test_name_display, "Stop bit accept if high by SampleCnt>=3");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        uart_rx_byte_cycles(clk, RxD, x"3C", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, 3);
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT - 3);
        assert_equal(DataO, x"3C", "DataO updated when stop bit becomes high early");
        assert_equal(RxAv, '1', "RxAv asserted when stop bit becomes high early");

        set_test_name(test_name_display, "Stop bit reject if low through SampleCnt>=13");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        uart_rx_byte_cycles(clk, RxD, x"5A", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        assert_equal(RxAv, '0', "RxAv should stay 0 when stop bit missing too long");
        assert_equal(DataO, x"00", "DataO should not update when stop bit missing too long");

        set_test_name(test_name_display, "Continuous low does not retrigger without edge");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(clk, RxD, x"5A", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT * 12);
        assert_equal(RxAv, '0', "RxAv should stay low during extended continuous low");
        assert_equal(DataO, x"00", "DataO should stay unchanged during extended continuous low");
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(clk, RxD, x"96", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => 0, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"96", "Receiver should recover after continuous low ends");
        assert_equal(RxAv, '1', "RxAv should assert after recovery from continuous low");

        set_test_name(test_name_display, "Recover after missing stop bit with short idle gap");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(clk, RxD, x"A5", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0'; -- this is overriding the previous stop bit to force a bad frame
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(RxAv, '0', "RxAv should stay 0 after bad frame with missing stop bit");
        assert_equal(DataO, x"00", "DataO should stay 0 after bad frame with missing stop bit");
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_cycles(clk, RxD, x"96", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => 0, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"96", "DataO should match valid frame after short idle gap");
        assert_equal(RxAv, '1', "RxAv should assert for valid frame after short idle gap");

        set_test_name(test_name_display, "Back-to-back bytes with minimal legal gap");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(clk, RxD, x"12", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(clk, RxD, x"34", cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => 0, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"34", "DataO should match second tightly packed byte");
        assert_equal(RxAv, '1', "RxAv should assert after second tightly packed byte");

        set_test_name(test_name_display, "Reset during active frame");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        for i in 0 to 2 loop
            RxD <= byte_bit(x"A9", i);
            cycle_clock(clk, UART_SAMPLES_PER_BIT);
        end loop;
        reset_dut(clk, rst);
        assert_equal(RxAv, '0', "RxAv should clear on reset during frame");
        assert_equal(DataO, x"00", "DataO should clear on reset during frame");

        set_test_name(test_name_display, "Start phase 0 ps");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_timed(clk, RxD, x"55", BIT_PERIOD, 0 ps, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(DataO, x"55", "DataO = 0x55 with phase 0 ps");
        assert_equal(RxAv, '1', "RxAv asserted with phase 0 ps");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD/2");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_timed(clk, RxD, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(DataO, x"55", "DataO = 0x55 with phase SAMPLE_CLK_PERIOD/2");
        assert_equal(RxAv, '1', "RxAv asserted with phase SAMPLE_CLK_PERIOD/2");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD-1ns");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_timed(clk, RxD, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(DataO, x"55", "DataO = 0x55 with phase SAMPLE_CLK_PERIOD-1ns");
        assert_equal(RxAv, '1', "RxAv asserted with phase SAMPLE_CLK_PERIOD-1ns");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        uart_rx_sweep_baud_skew(clk, clk, rst, RxD, RxAv, DataO, tb_unused_parityerr, '0', BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Early start phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        uart_rx_sweep_baud_skew(clk, clk, rst, RxD, RxAv, DataO, tb_unused_parityerr, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Balanced phase sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Balanced phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Balanced phase positive skew should reach predicted allowance");
        if neg_pass_limit > worst_neg_pass_limit then
            worst_neg_pass_limit := neg_pass_limit;
        end if;
        if pos_pass_limit < worst_pos_pass_limit then
            worst_pos_pass_limit := pos_pass_limit;
        end if;

        set_test_name(test_name_display, "Timed baud skew sweep late start phase");
        uart_rx_sweep_baud_skew(clk, clk, rst, RxD, RxAv, DataO, tb_unused_parityerr, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Late start phase sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Late start phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Late start phase positive skew should reach predicted allowance");
        if neg_pass_limit > worst_neg_pass_limit then
            worst_neg_pass_limit := neg_pass_limit;
        end if;
        if pos_pass_limit < worst_pos_pass_limit then
            worst_pos_pass_limit := pos_pass_limit;
        end if;

        report_baud_range_summary(
            baud_from_period(BIT_PERIOD),
            baud_from_skew(BIT_PERIOD, worst_pos_pass_limit),
            baud_from_skew(BIT_PERIOD, worst_neg_pass_limit),
            time_to_percent_of_bit(-worst_neg_pass_limit, BIT_PERIOD),
            time_to_percent_of_bit(worst_pos_pass_limit, BIT_PERIOD)
        );
        
        finish;
    end process;

    dut : entity work.UartRxRaw
        port map (
            Clk => clk,
            Reset => rst,
            Enable => Enable,
            RxD => RxD,
            RxAv => RxAv,
            DataO => DataO
        );
end architecture;
