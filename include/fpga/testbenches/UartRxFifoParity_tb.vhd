--! \brief Testbench for UartRxFifoParity.vhd
--! Main check here: bad parity frames do not get written into FIFO.
--! Includes good/bad mixed streams, read timing overlap, boundaries, and reset recovery.
--! Latest baud result: Baud range of 115200: 109030 - 121465 baud (-5.158184010123777% / +5.659085162181451%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartRxFifoParity_tb is
end UartRxFifoParity_tb;

architecture sim of UartRxFifoParity_tb is

    constant BAUDRATE : natural := 115200;
    constant FIFO_BITS : natural := 10;
    constant UART_FRAME_BITS : natural := 11;
    constant UART_SAMPLES_PER_BIT : natural := 16;
    constant BIT_PERIOD : time := 1 sec / BAUDRATE;
    constant SAMPLE_CLK_PERIOD : time := BIT_PERIOD / UART_SAMPLES_PER_BIT;
    constant FIFO_CLK_PERIOD : time := SAMPLE_CLK_PERIOD / 2;
    constant BAUD_TOLERANCE_PCT : real := uart_baud_tolerance_pct(UART_FRAME_BITS);
    constant PREDICTED_SKEW_ALLOWANCE : time := predicted_skew_allowance(BIT_PERIOD, BAUD_TOLERANCE_PCT);

    signal clk : std_logic;
    signal uclk : std_logic;
    signal rst : std_logic;
    signal Rxd : std_logic;

    signal ReadFifo : std_logic;
    signal FifoReadAck : std_logic;
    signal FifoReadData : std_logic_vector(7 downto 0);
    signal FifoFull : std_logic;
    signal FifoEmpty : std_logic;
    signal FifoCount : std_logic_vector(FIFO_BITS - 1 downto 0);

    signal test_name_display : string(1 to 80);

    signal PARITY_EVEN : std_logic;

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
        PARITY_EVEN <= '1';
        ReadFifo <= '0';
        Rxd <= '1';

        set_test_name(test_name_display, "Reset");
        reset_dut(uclk, rst);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after reset");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after reset");
        assert_equal(FifoReadAck, '0', "FifoReadAck should be 0 after reset");
        assert_equal(FifoReadData, x"00", "FifoReadData should be 0 after reset");

        set_test_name(test_name_display, "Receive good parity byte");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"A5", uart_parity_bit(x"A5", PARITY_EVEN), UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        wait until falling_edge(clk);
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after receiving byte");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after receiving one byte");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 after receiving one byte");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"A5", "FifoReadData should be 0xA5 after read");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after read");

        set_test_name(test_name_display, "Back-to-back good parity receives");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"11", uart_parity_bit(x"11", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(uclk, Rxd, x"22", uart_parity_bit(x"22", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(uclk, Rxd, x"33", uart_parity_bit(x"33", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(3, FIFO_BITS)), "FifoCount should be 3 after three receives");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after three receives");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after three receives");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"11", "FifoReadData should be 0x11 after first read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, FIFO_BITS)), "FifoCount should be 2 after first read");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"22", "FifoReadData should be 0x22 after second read");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 after second read");

        set_test_name(test_name_display, "Read while good frame is in progress");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '1';
        uart_rx_byte_cycles_parity(uclk, Rxd, x"44", uart_parity_bit(x"44", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
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
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after overlap follow-up read");

        set_test_name(test_name_display, "Bad parity frame is dropped");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"5A", not uart_parity_bit(x"5A", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoEmpty, '1', "FifoEmpty should remain 1 after bad parity frame");
        assert_equal(FifoFull, '0', "FifoFull should remain 0 after bad parity frame");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should stay 0 after bad parity frame");
        assert_equal(FifoReadAck, '0', "FifoReadAck should remain 0 after bad parity frame");

        set_test_name(test_name_display, "Good-bad-good parity sequence");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"AA", uart_parity_bit(x"AA", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(uclk, Rxd, x"BB", not uart_parity_bit(x"BB", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(uclk, Rxd, x"CC", uart_parity_bit(x"CC", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(uclk, Rxd, x"DD", not uart_parity_bit(x"DD", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, FIFO_BITS)), "FifoCount should only include good-parity frames");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after good-bad-good sequence");

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"AA", "First read should return first good frame");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"CC", "Second read should return second good frame");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reading only good-parity frames");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after reading only good-parity frames");

        set_test_name(test_name_display, "Read while bad frame is in progress");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"D1", uart_parity_bit(x"D1", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 before bad-frame overlap");

        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '1';
        uart_rx_byte_cycles_parity(uclk, Rxd, x"E2", not uart_parity_bit(x"E2", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        cycle_clock(uclk, 2 * UART_SAMPLES_PER_BIT);
        while (FifoReadAck /= '1') loop
            cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        end loop;
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '0';
        assert_equal(FifoReadData, x"D1", "Read should pop existing byte during bad-frame overlap");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 because bad frame was dropped");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after read overlaps dropped bad frame");

        set_test_name(test_name_display, "Simultaneous FIFO read/write");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"55", uart_parity_bit(x"55", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 before simultaneous FIFO read/write");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);

        rxd <= '0'; -- this is my lazy way of building a frame with the right parity bit so we can read at the same time as the write
        cycle_clock(uclk, 2 * UART_SAMPLES_PER_BIT);
        rxd <= '1';
        cycle_clock(uclk, 8 * UART_SAMPLES_PER_BIT);
        cycle_clock(clk, 10);

        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 after simultaneous FIFO read/write");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after simultaneous FIFO read/write");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after simultaneous FIFO read/write");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "FifoCount should be 1 after simultaneous FIFO read/write");

        set_test_name(test_name_display, "Read when empty");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 1 when reading empty FIFO");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        ReadFifo <= '1';
        cycle_clock(uclk, 2 * UART_SAMPLES_PER_BIT);
        assert_equal(FifoReadAck, '0', "FifoReadAck should stay 0 when reading empty FIFO");
        ReadFifo <= '0';
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should stay 0 when reading empty FIFO");
        assert_equal(FifoEmpty, '1', "FifoEmpty should stay 1 when reading empty FIFO");

        set_test_name(test_name_display, "Reset while FIFO has data");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"66", uart_parity_bit(x"66", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles_parity(uclk, Rxd, x"77", uart_parity_bit(x"77", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, FIFO_BITS)), "FifoCount should be 2 before reset");
        reset_dut(uclk, rst);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after reset");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after reset");
        assert_equal(FifoReadAck, '0', "FifoReadAck should be 0 after reset");

        set_test_name(test_name_display, "Write full with good parity");
        for i in 0 to (2 ** FIFO_BITS) - 1 loop
            uart_rx_byte_cycles_parity(
                uclk,
                Rxd,
                std_logic_vector(to_unsigned(i mod 256, 8)),
                uart_parity_bit(std_logic_vector(to_unsigned(i mod 256, 8)), PARITY_EVEN),
                UART_SAMPLES_PER_BIT,
                UART_SAMPLES_PER_BIT,
                UART_SAMPLES_PER_BIT
            );
        end loop;
        assert_equal(FifoFull, '1', "FifoFull should be 1 after writing full");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after writing full");
        assert_equal(FifoCount, std_logic_vector(to_unsigned((2 ** FIFO_BITS) - 1, FIFO_BITS)), "FifoCount should be DEPTH-1 after writing full");

        set_test_name(test_name_display, "Write while full with good parity");
        uart_rx_byte_cycles_parity(uclk, Rxd, x"88", uart_parity_bit(x"88", PARITY_EVEN), UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT, UART_SAMPLES_PER_BIT);
        assert_equal(FifoFull, '1', "FifoFull should stay 1 after writing while full");
        assert_equal(FifoCount, std_logic_vector(to_unsigned((2 ** FIFO_BITS) - 1, FIFO_BITS)), "FifoCount should not grow when writing while full");

        set_test_name(test_name_display, "Drain full FIFO in order");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"00", "First drained byte should be 0x00");
        while (FifoEmpty = '0') loop
            read_fifo(ReadFifo, FifoReadAck);
        end loop;

        set_test_name(test_name_display, "Write full with bad parity");
        for i in 0 to (2 ** FIFO_BITS) - 1 loop
            uart_rx_byte_cycles_parity(
                uclk,
                Rxd,
                std_logic_vector(to_unsigned(i mod 256, 8)),
                not uart_parity_bit(std_logic_vector(to_unsigned(i mod 256, 8)), PARITY_EVEN),
                UART_SAMPLES_PER_BIT,
                UART_SAMPLES_PER_BIT,
                UART_SAMPLES_PER_BIT
            );
        end loop;
        assert_equal(FifoFull, '0', "FifoFull should be 0 after writing full");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after writing full");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after writing full");

        set_test_name(test_name_display, "Start phase 0 ps");
        PARITY_EVEN <= '1';
        reset_dut(uclk, rst);
        ReadFifo <= '0';
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed_parity(uclk, Rxd, x"55", uart_parity_bit(x"55", '1'), BIT_PERIOD, 0 ps, 0 ps);
        cycle_clock(clk, 4);
        assert_equal(FifoEmpty, '0', "Fifo should capture 0x55 with phase 0 ps");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 with phase 0 ps");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD/2");
        PARITY_EVEN <= '1';
        reset_dut(uclk, rst);
        ReadFifo <= '0';
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed_parity(uclk, Rxd, x"55", uart_parity_bit(x"55", '1'), BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, 0 ps);
        cycle_clock(clk, 4);
        assert_equal(FifoEmpty, '0', "Fifo should capture 0x55 with phase SAMPLE_CLK_PERIOD/2");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 with phase SAMPLE_CLK_PERIOD/2");

        set_test_name(test_name_display, "Start phase SAMPLE_CLK_PERIOD-1ns");
        PARITY_EVEN <= '1';
        reset_dut(uclk, rst);
        ReadFifo <= '0';
        Rxd <= '1';
        cycle_clock(uclk, 2);
        uart_rx_byte_timed_parity(uclk, Rxd, x"55", uart_parity_bit(x"55", '1'), BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, 0 ps);
        cycle_clock(clk, 4);
        assert_equal(FifoEmpty, '0', "Fifo should capture 0x55 with phase SAMPLE_CLK_PERIOD-1ns");
        read_fifo(ReadFifo, FifoReadAck);
        assert_equal(FifoReadData, x"55", "FifoReadData should be 0x55 with phase SAMPLE_CLK_PERIOD-1ns");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        uart_rx_fifo_sweep_baud_skew(uclk, uclk, clk, rst, ReadFifo, Rxd, FifoReadAck, FifoReadData, '1', BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase FIFO sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Early start phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        uart_rx_fifo_sweep_baud_skew(uclk, uclk, clk, rst, ReadFifo, Rxd, FifoReadAck, FifoReadData, '1', BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Balanced phase FIFO sweep should find at least one passing point");
        assert_equal(neg_pass_limit <= -PREDICTED_SKEW_ALLOWANCE, true, "Balanced phase negative skew should reach predicted allowance");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Balanced phase positive skew should reach predicted allowance");
        if neg_pass_limit > worst_neg_pass_limit then
            worst_neg_pass_limit := neg_pass_limit;
        end if;
        if pos_pass_limit < worst_pos_pass_limit then
            worst_pos_pass_limit := pos_pass_limit;
        end if;

        set_test_name(test_name_display, "Timed baud skew sweep late start phase");
        uart_rx_fifo_sweep_baud_skew(uclk, uclk, clk, rst, ReadFifo, Rxd, FifoReadAck, FifoReadData, '1', BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Late start phase FIFO sweep should find at least one passing point");
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

    dut : entity work.UartRxFifoParity
        generic map (
            FIFO_BITS => FIFO_BITS
        )
        port map (
            clk => clk,
            uclk => uclk,
            rst => rst,
            Rxd => Rxd,
            ReadFifo => ReadFifo,
            FifoReadAck => FifoReadAck,
            FifoReadData => FifoReadData,
            FifoFull => FifoFull,
            FifoEmpty => FifoEmpty,
            FifoCount => FifoCount
        );

end architecture sim;
