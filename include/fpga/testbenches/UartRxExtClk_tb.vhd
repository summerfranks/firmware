--! \brief Testbench for UartRxExtClk.vhd
--! Same coverage style as UartRx_tb.vhd, but with external clocking.
--! Also checks ext-clock-specific stop-bit timing thresholds.
--! Latest baud result: Baud range of 115200: 109232 - 121969 baud (-5.549864035191298% / +5.4632451496476895%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartRxExtClk_tb is
end UartRxExtClk_tb;

architecture sim of UartRxExtClk_tb is

    signal uclk : std_logic;
    signal rst : std_logic;
    signal UartClk : std_logic;
    signal Rxd : std_logic;
    signal RxComplete : std_logic;
    signal RxData : std_logic_vector(7 downto 0);
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

    uclk_process : process
    begin
        uclk <= '0';
        wait for SAMPLE_CLK_PERIOD / 2;
        uclk <= '1';
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
        Rxd <= '1';
        reset_dut(uclk, rst);
        assert_equal(RxComplete, '0', "RxComplete should be 0 after reset");
        assert_equal(RxData, x"00", "RxData should be 0 after reset");


        set_test_name(test_name_display, "Test 1: Basic operation");
        uart_rx_byte_cycles(uclk, Rxd, x"55", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after byte");
        assert_equal(RxData, x"55", "RxData should be 0x55 after byte");


        set_test_name(test_name_display, "Back-to-back bytes");
        uart_rx_byte_cycles(uclk, Rxd, x"55", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0x55");
        assert_equal(RxData, x"55", "RxData should be 0x55 after 0x55");
        uart_rx_byte_cycles(uclk, Rxd, x"AA", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0xAA");
        assert_equal(RxData, x"AA", "RxData should be 0xAA after 0xAA");
        uart_rx_byte_cycles(uclk, Rxd, x"FF", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0xFF");
        assert_equal(RxData, x"FF", "RxData should be 0xFF after 0xFF");
        uart_rx_byte_cycles(uclk, Rxd, x"00", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0x00");
        assert_equal(RxData, x"00", "RxData should be 0x00 after 0x00");


        set_test_name(test_name_display, "Stress Test: All Byte Values");
        for i in 0 to 255 loop
            uart_rx_byte_cycles(uclk, Rxd, std_logic_vector(to_unsigned(i, 8)), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
            assert_equal(RxComplete, '1', "RxComplete should be 1 during stress test");
            assert_equal(RxData, std_logic_vector(to_unsigned(i, 8)), "RxData should match stress-test byte");
        end loop;


        set_test_name(test_name_display, "Hold old RxData until new byte completes");
        uart_rx_byte_cycles(uclk, Rxd, x"FF", UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0xFF");
        assert_equal(RxData, x"FF", "RxData should hold previous byte");
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '0', "RxComplete should drop during next frame");
        assert_equal(RxData, x"FF", "RxData should still hold old byte before next completion");
        Rxd <= '1';
        cycle_clock(uclk, 200);

                
        set_test_name(test_name_display, "Reset during reception");
        Rxd <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '1'; -- Rxd must go low before reset so it isn't fed into the IBuf2 which could mimic a RX start bit
        reset_dut(uclk, rst);
        assert_equal(RxComplete, '0', "RxComplete should be 0 after mid-byte reset");


        set_test_name(test_name_display, "Break condition");
        Rxd <= '0';
        cycle_clock(uclk, 9 * UART_SAMPLES_PER_BIT);
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT); -- finish stop bit without it showing
        assert_equal(RxComplete, '0', "RxComplete should be 0 after break condition");
        assert_equal(RxData, x"00", "RxData should be 0 after sending byte");

        set_test_name(test_name_display, "Early stop-bit (SampleCnt >= 3)");
        reset_dut(uclk, rst);
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        for i in 0 to 7 loop
            Rxd <= byte_bit(x"A5", i);
            cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        end loop;
        Rxd <= '1';
        cycle_clock(uclk, 3);
        assert_equal(RxComplete, '0', "RxComplete should be 0 during early stop bit");
        assert_equal(RxData, x"00", "RxData should not update during early stop bit");
        Rxd <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT - 3);
        assert_equal(RxComplete, '1', "RxComplete should assert after stop window");
        assert_equal(RxData, x"A5", "RxData should be 0xA5");


        set_test_name(test_name_display, "Stop-bit reject if low through SampleCnt >= 13");
        reset_dut(uclk, rst);
        Rxd <= '1';

        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        for i in 0 to 7 loop
            Rxd <= byte_bit(x"5A", i);
            cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        end loop;
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(RxComplete, '0', "RxComplete should stay 0 when stop bit is missing too long");
        assert_equal(RxData, x"00", "RxData should not update when stop bit is missing too long");

        set_test_name(test_name_display, "Start phase 0 ps");
        reset_dut(uclk, rst);
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed(uclk, Rxd, x"55", BIT_PERIOD, 0 ps, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(RxData, x"55", "RxData = 0x55 with phase 0 ps");
        assert_equal(RxComplete, '1', "RxComplete asserted with phase 0 ps");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD/2");
        reset_dut(uclk, rst);
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed(uclk, Rxd, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(RxData, x"55", "RxData = 0x55 with phase SAMPLE_CLK_PERIOD/2");
        assert_equal(RxComplete, '1', "RxComplete asserted with phase SAMPLE_CLK_PERIOD/2");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD-1ns");
        reset_dut(uclk, rst);
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed(uclk, Rxd, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(RxData, x"55", "RxData = 0x55 with phase SAMPLE_CLK_PERIOD-1ns");
        assert_equal(RxComplete, '1', "RxComplete asserted with phase SAMPLE_CLK_PERIOD-1ns");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        uart_rx_sweep_baud_skew(uclk, uclk, rst, Rxd, RxComplete, RxData, tb_unused_parityerr, '0', BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Early start phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        uart_rx_sweep_baud_skew(uclk, uclk, rst, Rxd, RxComplete, RxData, tb_unused_parityerr, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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
        uart_rx_sweep_baud_skew(uclk, uclk, rst, Rxd, RxComplete, RxData, tb_unused_parityerr, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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

    dut : entity work.UartRxExtClk
        port map (
            uclk => uclk,
            rst => rst,
            UartClk => UartClk,
            Rxd => Rxd,
            RxComplete => RxComplete,
            RxData => RxData
        );

end architecture sim;
