--! \brief Testbench for UartRx.vhd
--! Basic decode, back-to-back bytes, and byte-range traffic.
--! Reset-during-reception and break-condition handling.
--! Checks completion signaling and output hold behavior.
--! Latest baud result: Baud range of 115200: 108828 - 121969 baud (-5.549864035191298% / +5.854925174715212%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartRx_tb is
end UartRx_tb;

architecture sim of UartRx_tb is

    constant BAUDRATE : natural := 115200;
    constant UART_FRAME_BITS : natural := 10;
    constant UART_SAMPLES_PER_BIT : natural := 16;
    constant BIT_PERIOD : time := 1 sec / BAUDRATE;
    constant SAMPLE_CLK_PERIOD : time := BIT_PERIOD / UART_SAMPLES_PER_BIT;
    constant SYS_CLK_PERIOD : time := SAMPLE_CLK_PERIOD / 2;
    constant BAUD_TOLERANCE_PCT : real := uart_baud_tolerance_pct(UART_FRAME_BITS);
    constant PREDICTED_SKEW_ALLOWANCE : time := predicted_skew_allowance(BIT_PERIOD, BAUD_TOLERANCE_PCT);

    signal sys_clk : std_logic;
    signal bit_clk : std_logic;

    signal rst : std_logic;
    signal UartClk : std_logic;
    signal Rxd : std_logic;
    signal RxComplete : std_logic;
    signal RxData : std_logic_vector(7 downto 0);
    signal tb_unused_parityerr : std_logic := '0';

    signal test_name_display : string(1 to 80);

begin

    sys_clk_process : process
    begin
        sys_clk <= '0';
        wait for SYS_CLK_PERIOD / 2;
        sys_clk <= '1';
        wait for SYS_CLK_PERIOD / 2;
    end process;

    bit_clk_process : process
    begin
        bit_clk <= '0';
        wait for BIT_PERIOD / 2;
        bit_clk <= '1';
        wait for BIT_PERIOD / 2;
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
        reset_dut(sys_clk, rst);
        wait until rising_edge(UartClk);
        assert_equal(RxComplete, '0', "RxComplete should be 0 after reset");
        assert_equal(RxData, x"00", "RxData should be 0 after reset");


        set_test_name(test_name_display, "Test 1: Basic operation");
        uart_rx_byte_cycles(bit_clk, Rxd, x"55", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after byte");
        assert_equal(RxData, x"55", "RxData should be 0x55 after byte");


        set_test_name(test_name_display, "Back-to-back bytes");
        uart_rx_byte_cycles(bit_clk, Rxd, x"55", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0x55");
        assert_equal(RxData, x"55", "RxData should be 0x55 after 0x55");
        uart_rx_byte_cycles(bit_clk, Rxd, x"AA", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0xAA");
        assert_equal(RxData, x"AA", "RxData should be 0xAA after 0xAA");
        uart_rx_byte_cycles(bit_clk, Rxd, x"FF", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0xFF");
        assert_equal(RxData, x"FF", "RxData should be 0xFF after 0xFF");
        uart_rx_byte_cycles(bit_clk, Rxd, x"00", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0x00");
        assert_equal(RxData, x"00", "RxData should be 0x00 after 0x00");


        set_test_name(test_name_display, "Stress Test: All Byte Values");
        for i in 0 to 255 loop
            uart_rx_byte_cycles(bit_clk, Rxd, std_logic_vector(to_unsigned(i, 8)), 1, 0, 1);
            assert_equal(RxComplete, '1', "RxComplete should be 1 during stress test");
            assert_equal(RxData, std_logic_vector(to_unsigned(i, 8)), "RxData should match stress-test byte");
        end loop;

        set_test_name(test_name_display, "Hold old RxData until new byte completes");
        uart_rx_byte_cycles(bit_clk, Rxd, x"FF", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should be 1 after 0xFF");
        assert_equal(RxData, x"FF", "RxData should hold previous byte");
        Rxd <= '0';
        wait until falling_edge(bit_clk);
        assert_equal(RxComplete, '0', "RxComplete should drop during next frame");
        assert_equal(RxData, x"FF", "RxData should still hold old byte before next completion");
        Rxd <= '1';
        wait until RxComplete = '1';


        set_test_name(test_name_display, "Reset during reception");
        Rxd <= '1';
        wait until falling_edge(bit_clk);
        Rxd <= '0';
        wait until falling_edge(bit_clk);
        Rxd <= '1';
        wait until falling_edge(bit_clk);
        Rxd <= '0';
        rst <= '1';
        wait until falling_edge(bit_clk);
        rst <= '0';

        cycle_clock(bit_clk, 5);
        assert_equal(RxComplete, '0', "RxComplete should be 0 after mid-byte reset");


        -- Assert while line still low!! release + reset avoids 0x00 complete from UartRxRaw
        set_test_name(test_name_display, "Break condition");
        Rxd <= '1';
        wait until falling_edge(bit_clk);
        cycle_clock(bit_clk, 2);
        Rxd <= '0';
        cycle_clock(bit_clk, 24);
        assert_equal(RxComplete, '0', "Break should not create valid byte (line still low)");
        assert_equal(RxData, x"00", "RxData should still be reset value during break");

        Rxd <= '1';
        cycle_clock(bit_clk, 2);
        reset_dut(sys_clk, rst);
        wait until rising_edge(UartClk);
        assert_equal(RxComplete, '0', "RxComplete clear after break cleanup reset");
        assert_equal(RxData, x"00", "RxData should be 0 after reset");


        set_test_name(test_name_display, "RxComplete should assert after byte");
        wait until falling_edge(bit_clk);
        uart_rx_byte_cycles(bit_clk, Rxd, x"55", 1, 0, 1);
        assert_equal(RxComplete, '1', "RxComplete should assert");
        assert_equal(RxData, x"55", "RxData should be 0x55 when RxComplete asserts");
        wait until rising_edge(UartClk);
        assert_equal(RxComplete, '1', "RxComplete should still be 1 after byte");

        set_test_name(test_name_display, "Start phase 0 ps");
        reset_dut(sys_clk, rst);
        Rxd <= '1';
        cycle_clock(UartClk, 2);
        uart_rx_byte_timed(UartClk, Rxd, x"55", BIT_PERIOD, 0 ps, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(RxData, x"55", "RxData = 0x55 with phase 0 ps");
        assert_equal(RxComplete, '1', "RxComplete asserted with phase 0 ps");

        set_test_name(test_name_display, "Start phase UartClk/2");
        reset_dut(sys_clk, rst);
        Rxd <= '1';
        cycle_clock(UartClk, 2);
        uart_rx_byte_timed(UartClk, Rxd, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(RxData, x"55", "RxData = 0x55 with phase UartClk/2");
        assert_equal(RxComplete, '1', "RxComplete asserted with phase UartClk/2");

        set_test_name(test_name_display, "Start phase UartClk-1sysclk");
        reset_dut(sys_clk, rst);
        Rxd <= '1';
        cycle_clock(UartClk, 2);
        uart_rx_byte_timed(UartClk, Rxd, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD - SYS_CLK_PERIOD, 0 ps);
        wait for BIT_PERIOD;
        assert_equal(RxData, x"55", "RxData = 0x55 with phase UartClk-1sysclk");
        assert_equal(RxComplete, '1', "RxComplete asserted with phase UartClk-1sysclk");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        uart_rx_sweep_baud_skew(sys_clk, UartClk, rst, Rxd, RxComplete, RxData, tb_unused_parityerr, '0', BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Early start phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        uart_rx_sweep_baud_skew(sys_clk, UartClk, rst, Rxd, RxComplete, RxData, tb_unused_parityerr, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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
        uart_rx_sweep_baud_skew(sys_clk, UartClk, rst, Rxd, RxComplete, RxData, tb_unused_parityerr, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD - SYS_CLK_PERIOD, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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

        dut : entity work.UartRx
        generic map (
            CLOCK_FREQHZ => BAUDRATE * UART_SAMPLES_PER_BIT * 2,
            BAUDRATE => BAUDRATE
        )
        port map (
            clk => sys_clk,
            rst => rst,
            UartClk => UartClk,
            Rxd => Rxd,
            RxComplete => RxComplete,
            RxData => RxData
        );

end architecture sim;
