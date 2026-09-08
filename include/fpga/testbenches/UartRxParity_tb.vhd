--! \brief Testbench for UartRxParity.vhd
--! Parity mode matrix (odd/even), parity accumulation, and parity error signaling.
--! Stop-bit timing and baud mismatch cases.
--! Reset during active frame is covered too.
--! Latest baud result: Baud range of 115200: 109232 - 121259 baud (-4.996903999801856% / +5.4632451496476895%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartRXParity_tb is
end UartRXParity_tb;

architecture sim of UartRXParity_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal Enable : std_logic;
    signal RxD : std_logic;
    signal RxAv : std_logic;
    signal DataO : std_logic_vector(7 downto 0);
    signal ParityErr : std_logic;
    signal RxAv2 : std_logic;
    signal DataO2 : std_logic_vector(7 downto 0);
    signal ParityErr2 : std_logic;

    signal test_name_display : string(1 to 80);

    constant BAUDRATE : natural := 115200;
    constant UART_FRAME_BITS : natural := 11;
    constant UART_SAMPLES_PER_BIT : natural := 16;
    constant BIT_PERIOD : time := 1 sec / BAUDRATE;
    constant SAMPLE_CLK_PERIOD : time := BIT_PERIOD / UART_SAMPLES_PER_BIT;
    constant BAUD_TOLERANCE_PCT : real := uart_baud_tolerance_pct(UART_FRAME_BITS);
    constant PREDICTED_SKEW_ALLOWANCE : time := predicted_skew_allowance(BIT_PERIOD, BAUD_TOLERANCE_PCT);
    signal PARITY_EVEN : std_logic;

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
        PARITY_EVEN <= '0';
        Enable <= '0';
        RxD <= '1';
        reset_dut(clk, rst);
        assert_equal(RxAv, '0', "RxAv should be 0 after reset");
        assert_equal(DataO, x"00", "DataO should be 0 after reset");
        assert_equal(ParityErr, '0', "ParityErr should be 0 after reset");

        set_test_name(test_name_display, "Enable=0 ignores RxD");
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT * 8);
        assert_equal(RxAv, '0', "RxAv should remain 0 when disabled");
        assert_equal(DataO, x"00", "DataO should remain 0 when disabled");
        assert_equal(ParityErr, '0', "ParityErr should remain 0 when disabled");
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        set_test_name(test_name_display, "Odd parity (dut: generic 1)");
        PARITY_EVEN <= '0';
        reset_dut(clk, rst);
        Enable <= '1';
        assert_equal(RxAv, '0', "RxAv starts low");

        uart_rx_byte_cycles_parity(clk, RxD, x"55", uart_parity_bit(x"55", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"55", "DataO = 0x55 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive (sticky until next frame)");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        uart_rx_byte_cycles_parity(clk, RxD, x"FF", uart_parity_bit(x"FF", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"FF", "DataO = 0xFF after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        uart_rx_byte_cycles_parity(clk, RxD, x"01", uart_parity_bit(x"01", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"01", "DataO = 0x01 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        uart_rx_byte_cycles_parity(clk, RxD, x"80", uart_parity_bit(x"80", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"80", "DataO = 0x80 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        set_test_name(test_name_display, "Even parity (dut2: generic 0)");
        PARITY_EVEN <= '1';
        reset_dut(clk, rst);
        Enable <= '1';
        assert_equal(RxAv2, '0', "RxAv2 starts low");

        uart_rx_byte_cycles_parity(clk, RxD, x"55", uart_parity_bit(x"55", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO2, x"55", "DataO2 = 0x55 after receive");
        assert_equal(RxAv2, '1', "RxAv2 asserted after receive (sticky until next frame)");
        assert_equal(ParityErr2, '0', "ParityErr2 should be 0 for correct parity");

        uart_rx_byte_cycles_parity(clk, RxD, x"FF", uart_parity_bit(x"FF", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO2, x"FF", "DataO2 = 0xFF after receive");
        assert_equal(RxAv2, '1', "RxAv2 asserted after receive");
        assert_equal(ParityErr2, '0', "ParityErr2 should be 0 for correct parity");

        uart_rx_byte_cycles_parity(clk, RxD, x"01", uart_parity_bit(x"01", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO2, x"01", "DataO2 = 0x01 after receive");
        assert_equal(RxAv2, '1', "RxAv2 asserted after receive");
        assert_equal(ParityErr2, '0', "ParityErr2 should be 0 for correct parity");

        uart_rx_byte_cycles_parity(clk, RxD, x"80", uart_parity_bit(x"80", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO2, x"80", "DataO2 = 0x80 after receive");
        assert_equal(RxAv2, '1', "RxAv2 asserted after receive");
        assert_equal(ParityErr2, '0', "ParityErr2 should be 0 for correct parity");

        set_test_name(test_name_display, "Baud mismatch (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        uart_rx_byte_cycles_parity(clk, RxD, x"C3", uart_parity_bit(x"C3", PARITY_EVEN), cycles_per_bit => 15, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"C3", "DataO = 0xC3 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        reset_dut(clk, rst);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        uart_rx_byte_cycles_parity(clk, RxD, x"01", uart_parity_bit(x"01", PARITY_EVEN), cycles_per_bit => 17, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"01", "DataO = 0x01 after receive");
        assert_equal(RxAv, '1', "RxAv asserted after receive");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        reset_dut(clk, rst);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        -- the FF bits and long  cause it to end early (so FE)
        uart_rx_byte_cycles_parity(clk, RxD, x"FF", uart_parity_bit(x"FF", PARITY_EVEN), cycles_per_bit => 24, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"FE", "DataO = 0xFE (last bit sampled early under slow baud)");
        assert_equal(RxAv, '1', "RxAv asserted after receive");
        assert_equal(ParityErr, '1', "ParityErr set when parity bit mis-sampled (with framing error)");

        reset_dut(clk, rst);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        -- the clocks are too short so intentional no RxAv
        uart_rx_byte_cycles_parity(clk, RxD, x"FF", uart_parity_bit(x"FF", PARITY_EVEN), cycles_per_bit => 5, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"00", "DataO = 0x00 after receive");
        assert_equal(RxAv, '0', "RxAv should stay 0 when bit times too short");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        set_test_name(test_name_display, "Parity error flagged (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        for i in 0 to 7 loop
            RxD <= byte_bit(x"42", i);
            cycle_clock(clk, UART_SAMPLES_PER_BIT);
        end loop;
        RxD <= not uart_parity_bit(x"42", PARITY_EVEN);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"42", "DataO = 0x42 despite parity error");
        assert_equal(RxAv, '1', "RxAv asserted after frame with bad parity");
        assert_equal(ParityErr, '1', "ParityErr should be 1 when parity bit wrong");

        set_test_name(test_name_display, "SampleCnt=7 sampling point");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
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
        RxD <= uart_parity_bit(x"A5", PARITY_EVEN);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"A5", "Captured data matches value at SampleCnt=7");
        assert_equal(RxAv, '1', "RxAv asserted after SampleCnt=7 frame");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for SampleCnt=7 frame");

        set_test_name(test_name_display, "Reject start glitch not low at SampleCnt=7");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(clk, RxD, x"3C", uart_parity_bit(x"3C", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"3C", "DataO should capture the reference byte before glitch test");
        assert_equal(RxAv, '1', "RxAv should be high before the glitch test starts");
        assert_equal(ParityErr, '0', "ParityErr should be low before the glitch test starts");
        RxD <= '0';
        cycle_clock(clk, 2);
        assert_equal(RxAv, '0', "RxAv should clear immediately on candidate start");
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(RxAv, '0', "RxAv should remain low after rejected start glitch");
        assert_equal(DataO, x"3C", "DataO should not change after rejected start glitch");
        assert_equal(ParityErr, '0', "ParityErr should remain unchanged after rejected start glitch");
        uart_rx_byte_cycles_parity(clk, RxD, x"A6", uart_parity_bit(x"A6", PARITY_EVEN), UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"A6", "Receiver should recover after rejected start glitch");
        assert_equal(RxAv, '1', "RxAv should assert after the recovery byte");
        assert_equal(ParityErr, '0', "ParityErr should be 0 after the recovery byte");
   
        set_test_name(test_name_display, "Stop bit accept if high by SampleCnt>=3 (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        uart_rx_byte_cycles_parity(clk, RxD, x"3C", uart_parity_bit(x"3C", PARITY_EVEN), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, 3);
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT - 3);
        assert_equal(DataO, x"3C", "DataO updated when stop bit becomes high early");
        assert_equal(RxAv, '1', "RxAv asserted when stop bit becomes high early");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        set_test_name(test_name_display, "Stop bit reject if low through SampleCnt>=13 (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        uart_rx_byte_cycles_parity(clk, RxD, x"5A", uart_parity_bit(x"5A", PARITY_EVEN), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        assert_equal(RxAv, '0', "RxAv should stay 0 when stop bit missing too long");
        assert_equal(DataO, x"00", "DataO should not update when stop bit missing too long");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for correct parity");

        set_test_name(test_name_display, "Continuous low does not retrigger without edge");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(clk, RxD, x"5A", uart_parity_bit(x"5A", PARITY_EVEN), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT * 13);
        assert_equal(RxAv, '0', "RxAv should stay low during extended continuous low");
        assert_equal(DataO, x"00", "DataO should stay unchanged during extended continuous low");
        assert_equal(ParityErr, '0', "ParityErr should stay unchanged during extended continuous low");
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(clk, RxD, x"96", uart_parity_bit(x"96", PARITY_EVEN), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => 0, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"96", "Receiver should recover after continuous low ends");
        assert_equal(RxAv, '1', "RxAv should assert after recovery from continuous low");
        assert_equal(ParityErr, '0', "ParityErr should be 0 after recovery from continuous low");

        set_test_name(test_name_display, "Recover after missing stop bit with short idle gap");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(clk, RxD, x"A5", uart_parity_bit(x"A5", PARITY_EVEN), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => UART_SAMPLES_PER_BIT, stop_cycles => 0);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        assert_equal(RxAv, '0', "RxAv should stay 0 after bad frame with missing stop bit");
        assert_equal(DataO, x"00", "DataO should stay 0 after bad frame with missing stop bit");
        assert_equal(ParityErr, '0', "ParityErr should stay 0 after bad frame with missing stop bit");
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_cycles_parity(clk, RxD, x"96", uart_parity_bit(x"96", PARITY_EVEN), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => 0, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"96", "DataO should match valid frame after short idle gap");
        assert_equal(RxAv, '1', "RxAv should assert for valid frame after short idle gap");
        assert_equal(ParityErr, '0', "ParityErr should be 0 for valid frame after short idle gap");

        set_test_name(test_name_display, "Parity mode matrix on same wire");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);

        uart_rx_byte_cycles_parity(clk, RxD, x"69", uart_parity_bit(x"69", '0'), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"69", "Odd DUT data should update on odd-parity frame");
        assert_equal(DataO2, x"69", "Even DUT data should update on odd-parity frame");
        assert_equal(ParityErr, '0', "Odd DUT parity should pass on odd-parity frame");
        assert_equal(ParityErr2, '1', "Even DUT parity should fail on odd-parity frame");

        uart_rx_byte_cycles_parity(clk, RxD, x"96", uart_parity_bit(x"96", '1'), cycles_per_bit => UART_SAMPLES_PER_BIT, pre_idle_cycles => 0, stop_cycles => UART_SAMPLES_PER_BIT);
        assert_equal(DataO, x"96", "Odd DUT data should update on even-parity frame");
        assert_equal(DataO2, x"96", "Even DUT data should update on even-parity frame");
        assert_equal(ParityErr, '1', "Odd DUT parity should fail on even-parity frame");
        assert_equal(ParityErr2, '0', "Even DUT parity should pass on even-parity frame");

        set_test_name(test_name_display, "Reset during active frame");
        reset_dut(clk, rst);
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        RxD <= '0';
        cycle_clock(clk, UART_SAMPLES_PER_BIT);
        for i in 0 to 2 loop
            RxD <= byte_bit(x"B6", i);
            cycle_clock(clk, UART_SAMPLES_PER_BIT);
        end loop;
        reset_dut(clk, rst);
        assert_equal(RxAv, '0', "Odd DUT RxAv should clear on reset during frame");
        assert_equal(DataO, x"00", "Odd DUT DataO should clear on reset during frame");
        assert_equal(ParityErr, '0', "Odd DUT ParityErr should clear on reset during frame");
        assert_equal(RxAv2, '0', "Even DUT RxAv should clear on reset during frame");
        assert_equal(DataO2, x"00", "Even DUT DataO should clear on reset during frame");
        assert_equal(ParityErr2, '0', "Even DUT ParityErr should clear on reset during frame");

        set_test_name(test_name_display, "Start phase 0 ps (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_timed_parity(clk, RxD, x"55", uart_parity_bit(x"55", '0'), BIT_PERIOD, 0 ps, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(DataO, x"55", "DataO = 0x55 with phase 0 ps");
        assert_equal(RxAv, '1', "RxAv asserted with phase 0 ps");
        assert_equal(ParityErr, '0', "ParityErr should be 0 with phase 0 ps");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD/2 (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_timed_parity(clk, RxD, x"55", uart_parity_bit(x"55", '0'), BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(DataO, x"55", "DataO = 0x55 with phase SAMPLE_CLK_PERIOD/2");
        assert_equal(RxAv, '1', "RxAv asserted with phase SAMPLE_CLK_PERIOD/2");
        assert_equal(ParityErr, '0', "ParityErr should be 0 with phase SAMPLE_CLK_PERIOD/2");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD-1ns (odd / dut)");
        reset_dut(clk, rst);
        PARITY_EVEN <= '0';
        Enable <= '1';
        RxD <= '1';
        cycle_clock(clk, 2);
        uart_rx_byte_timed_parity(clk, RxD, x"55", uart_parity_bit(x"55", '0'), BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(DataO, x"55", "DataO = 0x55 with phase SAMPLE_CLK_PERIOD-1ns");
        assert_equal(RxAv, '1', "RxAv asserted with phase SAMPLE_CLK_PERIOD-1ns");
        assert_equal(ParityErr, '0', "ParityErr should be 0 with phase SAMPLE_CLK_PERIOD-1ns");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        PARITY_EVEN <= '1';
        uart_rx_sweep_baud_skew(clk, clk, rst, RxD, RxAv2, DataO2, ParityErr2, '1', BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Early start phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        PARITY_EVEN <= '1';
        uart_rx_sweep_baud_skew(clk, clk, rst, RxD, RxAv2, DataO2, ParityErr2, '1', BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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
        PARITY_EVEN <= '1';
        uart_rx_sweep_baud_skew(clk, clk, rst, RxD, RxAv2, DataO2, ParityErr2, '1', BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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

    dut : entity work.UartRxParity
        generic map (
            PARITY_EVEN => 1
        )
        port map (
            Clk => clk,
            Reset => rst,
            Enable => Enable,
            RxD => RxD,
            RxAv => RxAv,
            DataO => DataO,
            ParityErr => ParityErr
        );

    dut2 : entity work.UartRxParity
        generic map (
            PARITY_EVEN => 0
        )
        port map (
            Clk => clk,
            Reset => rst,
            Enable => Enable,
            RxD => RxD,
            RxAv => RxAv2,
            DataO => DataO2,
            ParityErr => ParityErr2
        );

end architecture;
