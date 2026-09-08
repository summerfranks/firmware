--! \brief Testbench for UartRxFifoExtClk.vhd
--! FIFO integration after the interface swap.
--! Single/burst/overlap traffic, read-while-write behavior, and drain ordering.
--! Full/empty boundaries plus resets with buffered data and active frames.
--! Latest baud result: Baud range of 115200: 109232 - 121969 baud (-5.549864035191298% / +5.4632451496476895%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartRxFifoExtClk_tb is
end UartRxFifoExtClk_tb;

architecture sim of UartRxFifoExtClk_tb is

    constant BAUDRATE : natural := 115200;
    constant FIFO_BITS : natural := 10; -- match UartRxFifoExtClk default
    constant UART_FRAME_BITS : natural := 10;
    constant UART_SAMPLES_PER_BIT : natural := 16;
    constant BIT_PERIOD : time := 1 sec / BAUDRATE; -- UART bit period.
    constant SAMPLE_CLK_PERIOD : time := BIT_PERIOD / UART_SAMPLES_PER_BIT; -- UART sample clock period (baud*16).
    constant FIFO_CLK_PERIOD : time := SAMPLE_CLK_PERIOD / 2; -- FIFO/read clock period, run at x2 over the UART sample clock.
    constant BAUD_TOLERANCE_PCT : real := uart_baud_tolerance_pct(UART_FRAME_BITS);
    constant PREDICTED_SKEW_ALLOWANCE : time := predicted_skew_allowance(BIT_PERIOD, BAUD_TOLERANCE_PCT);

    signal clk : std_logic;
    signal uclk : std_logic;

    signal rst : std_logic;
    signal Rxd : std_logic;
    signal Dbg1 : std_logic;

    signal RxComplete : std_logic;
    signal ReadFifo : std_logic;
    signal FifoReadAck : std_logic;
    signal FifoReadData : std_logic_vector(7 downto 0);
    signal FifoFull : std_logic;
    signal FifoEmpty : std_logic;
    signal FifoCount : std_logic_vector(FIFO_BITS - 1 downto 0);

    signal test_name_display : string(1 to 80);

    procedure read_fifo(
        signal re_out : out std_logic;
        signal ack_in : in std_logic
    ) is
    begin
        wait until falling_edge(clk);
        re_out <= '1';
        while (ack_in /= '1') loop
            wait until falling_edge(clk);
        end loop;
        assert_equal(ack_in, '1', "FifoReadAck should be 1 when FIFO read is acknowledged");
        re_out <= '0';
        wait until falling_edge(clk);
    end procedure;

begin

    clk_process : process
    begin
        clk <= '0';
        wait for FIFO_CLK_PERIOD / 2;
        clk <= '1';
        wait for FIFO_CLK_PERIOD / 2;
    end process;

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
        ReadFifo <= '0';
        Rxd <= '1';

        set_test_name(test_name_display, "Reset");
        reset_dut(uclk, rst);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after reset");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after reset");
        assert_equal(RxComplete, '0', "RxComplete should be 0 after reset");
        assert_equal(FifoReadAck, '0', "FifoReadAck should be 0 after reset");
        assert_equal(FifoReadData, x"00", "FifoReadData should be 0 after reset");

        set_test_name(test_name_display, "Receive Byte 0xA5");
        uart_rx_byte_cycles(uclk, Rxd, x"A5", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after receiving byte");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after receiving one byte");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 after receiving one byte");
        assert_equal(FifoReadData, x"00", "FifoReadData should still be 0 before reading from FIFO");
        assert_equal(FifoReadAck, '0', "FifoReadAck should be 0 before reading from FIFO");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"A5", "FifoReadData should be 0xA5 after read");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after read");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after read");

        set_test_name(test_name_display, "Back-to-back receives");
        uart_rx_byte_cycles(uclk, Rxd, x"11", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(uclk, Rxd, x"22", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(uclk, Rxd, x"33", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        
        assert_equal(FifoCount, std_logic_vector(to_unsigned(3, FIFO_BITS)), "FifoCount should be 3 after three receives");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after three receives");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after three receives");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"11", "FifoReadData should be 0x11 after first read");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after first read");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after first read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, FIFO_BITS)), "FifoCount should be 2 after first read");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"22", "FifoReadData should be 0x22 after second read");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after second read");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after second read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 after second read");

        set_test_name(test_name_display, "Read while send is in progress");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '1';
        uart_rx_byte_cycles(uclk, Rxd, x"44", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        cycle_clock(uclk, 2 * UART_SAMPLES_PER_BIT);
        while (FifoReadAck /= '1') loop
            cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        end loop;
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '0';
        assert_equal(FifoReadData, x"33", "FifoReadData should pop oldest byte during overlap");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should remain 1 after overlap read/write");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after overlap read/write");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"44", "FifoReadData should be 0x44 after overlap follow-up read");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after overlap follow-up read");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after overlap follow-up read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after overlap follow-up read");

        set_test_name(test_name_display, "Simultaneous FIFO read/write");
        uart_rx_byte_cycles(uclk, Rxd, x"55", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 before simultaneous FIFO read/write");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        rxd <= '1';
        wait until rising_edge(rxComplete);
        wait until falling_edge(clk); --have to wait for rxComplete to go through buffer to get to fifo write
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 after simultaneous FIFO read/write");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after simultaneous FIFO read/write");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after simultaneous FIFO read/write");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 after simultaneous FIFO read/write");

        set_test_name(test_name_display, "Read when empty");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 when reading empty FIFO");
        ReadFifo <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '1';
        cycle_clock(uclk, 2 * UART_SAMPLES_PER_BIT);
        assert_equal(FifoReadAck, '0', "FifoReadAck should stay 0 when reading empty FIFO");
        ReadFifo <= '0';
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should stay 0 when reading empty FIFO");
        assert_equal(FifoEmpty, '1', "FifoEmpty should stay 1 when reading empty FIFO");

        set_test_name(test_name_display, "Reset while FIFO has data");
        uart_rx_byte_cycles(uclk, Rxd, x"66", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(uclk, Rxd, x"77", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, FIFO_BITS)), "FifoCount should be 2 before reset");
        reset_dut(uclk, rst);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after reset");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after reset");
        assert_equal(FifoReadAck, '0', "FifoReadAck should be 0 after reset");

        set_test_name(test_name_display, "Receive after mid reset");
        uart_rx_byte_cycles(uclk, Rxd, x"99", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"99", "FifoReadData should be 0x99 after post-reset read");
        for i in 0 to 100 loop
            cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        end loop;
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after post-reset read");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after post-reset read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after post-reset read");

        set_test_name(test_name_display, "Fill FIFO to full then drain");
        reset_dut(uclk, rst);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 before full-fill burst");
        for wi in 0 to (2 ** FIFO_BITS) - 1 loop
            uart_rx_byte_cycles(uclk, Rxd, std_logic_vector(to_unsigned(wi mod 256, 8)), UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        end loop;
        assert_equal(FifoFull, '1', "FifoFull should be 1 when FIFO is full");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 when FIFO is full");
        assert_equal(FifoCount, std_logic_vector(to_unsigned((2 ** FIFO_BITS) - 1, FIFO_BITS)), "FifoCount should be DEPTH-1 when FIFO is full");

        set_test_name(test_name_display, "Receive when FIFO full (extra byte dropped)");
        uart_rx_byte_cycles(uclk, Rxd, x"AB", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        assert_equal(FifoFull, '1', "FifoFull should stay 1 after write while full");
        assert_equal(FifoCount, std_logic_vector(to_unsigned((2 ** FIFO_BITS) - 1, FIFO_BITS)), "FifoCount should not grow when writing while full");

        set_test_name(test_name_display, "Drain full FIFO in order");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"00", "First drained byte should be 0x00");
        while (FifoEmpty = '0') loop
            read_fifo(ReadFifo, FifoReadAck);
        end loop;
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after draining full FIFO");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after draining full FIFO");

        set_test_name(test_name_display, "Reset during UART frame");
        Rxd <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        Rxd <= '1';
        reset_dut(uclk, rst);
        assert_equal(RxComplete, '0', "RxComplete should be 0 after reset during frame");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset during frame");

        set_test_name(test_name_display, "Start phase 0 ps");
        reset_dut(uclk, rst);
        ReadFifo <= '0';
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed(uclk, Rxd, x"55", BIT_PERIOD, 0 ps, 0 ps);
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 with phase 0 ps");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD/2");
        reset_dut(uclk, rst);
        ReadFifo <= '0';
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed(uclk, Rxd, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, 0 ps);
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 with phase SAMPLE_CLK_PERIOD/2");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD-1ns");
        reset_dut(uclk, rst);
        ReadFifo <= '0';
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed(uclk, Rxd, x"55", BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, 0 ps);
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 with phase SAMPLE_CLK_PERIOD-1ns");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        uart_rx_fifo_sweep_baud_skew(uclk, uclk, clk, rst, ReadFifo, Rxd, FifoReadAck, FifoReadData, '0', BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase FIFO sweep should find at least one passing point");
        assert_equal(neg_pass_limit < 0 ps, true, "Early start phase should tolerate some negative skew");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        uart_rx_fifo_sweep_baud_skew(uclk, uclk, clk, rst, ReadFifo, Rxd, FifoReadAck, FifoReadData, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Balanced phase FIFO sweep should find at least one passing point");
        assert_equal(neg_pass_limit < 0 ps, true, "Balanced phase should tolerate some negative skew");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Balanced phase positive skew should reach predicted allowance");
        if neg_pass_limit > worst_neg_pass_limit then
            worst_neg_pass_limit := neg_pass_limit;
        end if;
        if pos_pass_limit < worst_pos_pass_limit then
            worst_pos_pass_limit := pos_pass_limit;
        end if;

        set_test_name(test_name_display, "Timed baud skew sweep late start phase");
        uart_rx_fifo_sweep_baud_skew(uclk, uclk, clk, rst, ReadFifo, Rxd, FifoReadAck, FifoReadData, '0', BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Late start phase FIFO sweep should find at least one passing point");
        assert_equal(neg_pass_limit < 0 ps, true, "Late start phase should tolerate some negative skew");
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

    dut : entity work.UartRxFifoExtClk
        generic map (
            FIFO_BITS => FIFO_BITS
        )
        port map (
            clk => clk,
            uclk => uclk,
            rst => rst,
            Rxd => Rxd,
            Dbg1 => Dbg1,
            RxComplete => RxComplete,
            ReadFifo => ReadFifo,
            FifoReadAck => FifoReadAck,
            FifoReadData => FifoReadData,
            FifoFull => FifoFull,
            FifoEmpty => FifoEmpty,
            FifoCount => FifoCount
        );

end architecture sim;
