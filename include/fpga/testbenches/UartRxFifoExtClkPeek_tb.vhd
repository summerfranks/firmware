--! \brief Testbench for UartRxFifoExtClkPeek.vhd
--! Adds peek + multipop coverage on top of RX FIFO behavior.
--! Pop-to-empty/refill/full-to-empty sequences are included.
--! Also checks simultaneous pop+write and skip/address edge cases.
--! Latest baud result: Baud range of 115200: 109232 - 121969 baud (-5.549864035191298% / +5.4632451496476895%)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;
use work.CGraphTypes.all;

entity UartRxFifoExtClkPeek_tb is
end UartRxFifoExtClkPeek_tb;

architecture sim of UartRxFifoExtClkPeek_tb is

    constant BAUDRATE : natural := 115200;
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
    signal Dbg2 : std_logic;
    signal Dbg3 : std_logic;

    signal RxComplete : std_logic;
    signal ReadFifo : std_logic;
    signal FifoReadAck : std_logic;
    signal FifoReadData : std_logic_vector(7 downto 0);

    signal FifoFull : std_logic;
    signal FifoEmpty : std_logic;
    signal FifoCount : std_logic_vector(PeekRamDepth - 1 downto 0);

    signal FifoReadAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal FifoWriteAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal FifoPeekAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal FifoPeekData : std_logic_vector(7 downto 0);
    signal FifoMultiPopAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal FifoMultiPopStrobe : std_logic;

    signal test_name_display : string(1 to 80);

    procedure sweep_baud_skew_peek(
        signal reset_clk_i : in std_logic;
        signal sample_clk_i : in std_logic;
        signal fifo_clk_i : in std_logic;
        signal rst_o : out std_logic;
        signal rxd_o : out std_logic;
        signal peek_addr_o : out std_logic_vector(PeekRamDepth - 1 downto 0);
        signal peek_data_i : in std_logic_vector(7 downto 0);
        signal read_addr_i : in std_logic_vector(PeekRamDepth - 1 downto 0);
        signal empty_i : in std_logic;
        signal count_i : in std_logic_vector(PeekRamDepth - 1 downto 0);
        constant bit_period_i : in time;
        constant phase_offset : in time;
        constant pattern : in std_logic_vector(7 downto 0);
        variable pass_found_o : out boolean;
        variable neg_pass_limit_o : out time;
        variable pos_pass_limit_o : out time
    ) is
        variable skew_offset : time;
        variable max_skew_magnitude : time;
        constant STEP_TIME : time := 1 ns;
        constant REQUIRED_PASSES : natural := 3;
        variable pass_counter : natural;
        variable in_pass_window : boolean;
    begin
        pass_found_o := false;
        neg_pass_limit_o := 0 ps;
        pos_pass_limit_o := 0 ps;
        max_skew_magnitude := bit_period_i / 6;
        skew_offset := -max_skew_magnitude;
        pass_counter := 0;
        in_pass_window := false;

        while skew_offset <= max_skew_magnitude loop
            reset_dut(reset_clk_i, rst_o);
            rxd_o <= '1';
            cycle_clock(sample_clk_i, 2);

            uart_rx_byte_timed(sample_clk_i, rxd_o, pattern, bit_period_i, phase_offset, skew_offset);
            cycle_clock(fifo_clk_i, 4);
            peek_addr_o <= read_addr_i;
            wait until falling_edge(fifo_clk_i);

            if (empty_i = '0') and (count_i = std_logic_vector(to_unsigned(1, PeekRamDepth))) and (peek_data_i = pattern) then
                pass_counter := pass_counter + 1;
                if (not in_pass_window) and (pass_counter >= REQUIRED_PASSES) then
                    neg_pass_limit_o := skew_offset - (STEP_TIME * (REQUIRED_PASSES - 1));
                    pass_found_o := true;
                    in_pass_window := true;
                end if;
            else
                pass_counter := 0;
                if in_pass_window then
                    pos_pass_limit_o := skew_offset - STEP_TIME;
                    exit;
                end if;
            end if;

            skew_offset := skew_offset + STEP_TIME;
        end loop;
        if in_pass_window and (pos_pass_limit_o = 0 ps) then
            pos_pass_limit_o := skew_offset - STEP_TIME;
        end if;
    end procedure;

    procedure pop_to(
        signal addr_out : out std_logic_vector(PeekRamDepth - 1 downto 0);
        signal strobe_out : out std_logic;
        constant addr : in natural
    ) is
    begin
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        addr_out <= std_logic_vector(to_unsigned(addr, PeekRamDepth));
        strobe_out <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        strobe_out <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
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
        FifoPeekAddr <= (others => '0');
        FifoMultiPopAddr <= (others => '0');
        FifoMultiPopStrobe <= '0';

        set_test_name(test_name_display, "Reset");
        reset_dut(uclk, rst);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after reset");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, PeekRamDepth)), "FifoCount should be 0 after reset");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(0, PeekRamDepth)), "FifoReadAddr should be 0 after reset");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(0, PeekRamDepth)), "FifoWriteAddr should be 0 after reset");

        set_test_name(test_name_display, "Receive 3 bytes and peek");
        uart_rx_byte_cycles(uclk, Rxd, x"A5", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(uclk, Rxd, x"5A", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(uclk, Rxd, x"33", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        wait until falling_edge(clk);
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after three receives");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after three receives");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(3, PeekRamDepth)), "FifoCount should be 3 after three receives");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(0, PeekRamDepth)), "FifoReadAddr should stay at 0 before pop");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(3, PeekRamDepth)), "FifoWriteAddr should advance to 3 after three receives");

        FifoPeekAddr <= std_logic_vector(to_unsigned(0, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"A5", "Peek addr 0 should be first byte");
        FifoPeekAddr <= std_logic_vector(to_unsigned(1, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"5A", "Peek addr 1 should be second byte");
        FifoPeekAddr <= std_logic_vector(to_unsigned(2, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"33", "Peek addr 2 should be third byte");

        set_test_name(test_name_display, "Multi-pop to address 1");
        pop_to(FifoMultiPopAddr, FifoMultiPopStrobe, 1);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, PeekRamDepth)), "FifoCount should drop to 2 after pop-to-1");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(1, PeekRamDepth)), "FifoReadAddr should move to 1 after pop-to-1");
        assert_equal(FifoEmpty, '0', "FifoEmpty should stay 0 after pop-to-1");
        FifoPeekAddr <= std_logic_vector(to_unsigned(1, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"5A", "Peek addr 1 should now be oldest byte");
        FifoPeekAddr <= std_logic_vector(to_unsigned(2, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"33", "Peek addr 2 should still hold last byte");

        set_test_name(test_name_display, "Multi-pop to write address (empty)");
        pop_to(FifoMultiPopAddr, FifoMultiPopStrobe, 3);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, PeekRamDepth)), "FifoCount should be 0 after pop to write addr");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(3, PeekRamDepth)), "FifoReadAddr should match write addr when empty");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(3, PeekRamDepth)), "FifoWriteAddr should remain 3 after pop-only");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after pop to write addr");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after pop to write addr");

        set_test_name(test_name_display, "Receive after pop/empty");
        uart_rx_byte_cycles(uclk, Rxd, x"7E", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        wait until falling_edge(clk);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, PeekRamDepth)), "FifoCount should be 1 after post-pop receive");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(3, PeekRamDepth)), "FifoReadAddr should stay at 3 until pop");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(4, PeekRamDepth)), "FifoWriteAddr should advance to 4");
        FifoPeekAddr <= std_logic_vector(to_unsigned(3, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"7E", "Peek addr 3 should show post-pop byte");

        set_test_name(test_name_display, "Pop while UART write is in progress");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopAddr <= FifoWriteAddr;
        FifoMultiPopStrobe <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopStrobe <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 before overlap setup");

        uart_rx_byte_cycles(uclk, Rxd, x"10", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        uart_rx_byte_cycles(uclk, Rxd, x"20", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        wait until falling_edge(clk);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, PeekRamDepth)), "FifoCount should be 2 before pop/write overlap");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(4, PeekRamDepth)), "FifoReadAddr should be 4 before pop/write overlap");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(6, PeekRamDepth)), "FifoWriteAddr should be 6 before pop/write overlap");

        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopAddr <= std_logic_vector(to_unsigned(5, PeekRamDepth));
        FifoMultiPopStrobe <= '1';
        uart_rx_byte_cycles(uclk, Rxd, x"30", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopStrobe <= '0';
        wait until falling_edge(clk);
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(5, PeekRamDepth)), "FifoReadAddr should advance once during overlap");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(7, PeekRamDepth)), "FifoWriteAddr should advance by one during overlap");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, PeekRamDepth)), "FifoCount should remain 2 after one pop and one write overlap");
        FifoPeekAddr <= std_logic_vector(to_unsigned(5, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"20", "Peek oldest should be 0x20 after overlap");
        FifoPeekAddr <= std_logic_vector(to_unsigned(6, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"30", "Peek next should be 0x30 after overlap");

        set_test_name(test_name_display, "Write and pop at same time");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopAddr <= FifoWriteAddr;
        FifoMultiPopStrobe <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopStrobe <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 before simultaneous high test");

        uart_rx_byte_cycles(uclk, Rxd, x"AA", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        wait until falling_edge(clk);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, PeekRamDepth)), "FifoCount should be 1 before write/pop test");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(7, PeekRamDepth)), "FifoReadAddr should be 7 before write/pop test");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(8, PeekRamDepth)), "FifoWriteAddr should be 8 before write/pop test");

        -- do a write, then pop immediately (no settle_after_uart). A pop and a write are happening at the same time here
        uart_rx_byte_cycles(uclk, Rxd, x"DD", UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopAddr <= std_logic_vector(to_unsigned(8, PeekRamDepth));
        FifoMultiPopStrobe <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopStrobe <= '0';
        wait until falling_edge(clk);

        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(8, PeekRamDepth)), "FifoReadAddr should advance by one due to pop");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(9, PeekRamDepth)), "FifoWriteAddr should advance by one due to write");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, PeekRamDepth)), "FifoCount should stay the same when pop and write overlap");
        FifoPeekAddr <= FifoReadAddr;
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"DD", "Oldest byte should be the newly written byte after overlap");

        set_test_name(test_name_display, "Fill to full then pop to empty with peeks");
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopAddr <= FifoWriteAddr;
        FifoMultiPopStrobe <= '1';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        FifoMultiPopStrobe <= '0';
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 before full-fill test");
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(9, PeekRamDepth)), "FifoReadAddr should be 9 before fill");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(9, PeekRamDepth)), "FifoWriteAddr should be 9 before fill");

        for wi in 0 to (2 ** PeekRamDepth) - 2 loop
            uart_rx_byte_cycles(uclk, Rxd, std_logic_vector(to_unsigned(wi mod 256, 8)), UART_SAMPLES_PER_BIT, 0, UART_SAMPLES_PER_BIT);
        end loop;
        wait until falling_edge(clk);
        assert_equal(FifoFull, '1', "FifoFull should be 1 after fill");
        assert_equal(FifoEmpty, '0', "FifoEmpty should be 0 after fill");
        -- near full wrap
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(9, PeekRamDepth)), "FifoReadAddr should stay at start after fill");
        assert_equal(FifoWriteAddr, std_logic_vector(to_unsigned(8, PeekRamDepth)), "FifoWriteAddr should be start+DEPTH-1 after fill");

        FifoPeekAddr <= std_logic_vector(to_unsigned(9, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"00", "Peek addr 9 should be 0x00 after fill");
        FifoPeekAddr <= std_logic_vector(to_unsigned(10, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"01", "Peek addr 10 should be 0x01 after fill");
        FifoPeekAddr <= std_logic_vector(to_unsigned(7, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"FE", "Peek tail addr 7 should be 0xFE after fill");

        pop_to(FifoMultiPopAddr, FifoMultiPopStrobe, 7);
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(7, PeekRamDepth)), "FifoReadAddr should move to midpoint pop");
        assert_equal(FifoEmpty, '0', "FifoEmpty should stay 0 after midpoint pop");
        FifoPeekAddr <= std_logic_vector(to_unsigned(7, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"FE", "Peek at midpoint addr 7 should be 0xFE");
        FifoPeekAddr <= std_logic_vector(to_unsigned(6, PeekRamDepth));
        cycle_clock(uclk, UART_SAMPLES_PER_BIT);
        assert_equal(FifoPeekData, x"FD", "Peek near tail addr 6 should be 0xFD");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, PeekRamDepth)), "FifoCount should be 1 before final pop-to-empty");

        pop_to(FifoMultiPopAddr, FifoMultiPopStrobe, 8);
        assert_equal(FifoReadAddr, std_logic_vector(to_unsigned(8, PeekRamDepth)), "FifoReadAddr should move to write boundary after final pop");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, PeekRamDepth)), "FifoCount should be 0 after final pop-to-empty");
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after final pop-to-empty");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after final pop-to-empty");

        set_test_name(test_name_display, "Timed baud skew sweep early start phase");
        sweep_baud_skew_peek(uclk, uclk, clk, rst, Rxd, FifoPeekAddr, FifoPeekData, FifoReadAddr, FifoEmpty, FifoCount, BIT_PERIOD, 0 ps, x"55", pass_found, neg_pass_limit, pos_pass_limit);
        assert_equal(pass_found, true, "Early start phase FIFO sweep should find at least one passing point");
        assert_equal(neg_pass_limit < 0 ps, true, "Early start phase should tolerate some negative skew");
        assert_equal(pos_pass_limit >= PREDICTED_SKEW_ALLOWANCE, true, "Early start phase positive skew should reach predicted allowance");
        worst_neg_pass_limit := neg_pass_limit;
        worst_pos_pass_limit := pos_pass_limit;

        set_test_name(test_name_display, "Timed baud skew sweep balanced phase");
        sweep_baud_skew_peek(uclk, uclk, clk, rst, Rxd, FifoPeekAddr, FifoPeekData, FifoReadAddr, FifoEmpty, FifoCount, BIT_PERIOD, SAMPLE_CLK_PERIOD / 2, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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
        sweep_baud_skew_peek(uclk, uclk, clk, rst, Rxd, FifoPeekAddr, FifoPeekData, FifoReadAddr, FifoEmpty, FifoCount, BIT_PERIOD, SAMPLE_CLK_PERIOD - 1 ns, x"55", pass_found, neg_pass_limit, pos_pass_limit);
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

    dut : entity work.UartRxFifoExtClkPeek
        port map (
            clk => clk,
            uclk => uclk,
            rst => rst,
            Rxd => Rxd,
            Dbg1 => Dbg1,
            Dbg2 => Dbg2,
            Dbg3 => Dbg3,
            RxComplete => RxComplete,
            ReadFifo => ReadFifo,
            FifoReadAck => FifoReadAck,
            FifoReadData => FifoReadData,
            FifoFull => FifoFull,
            FifoEmpty => FifoEmpty,
            FifoCount => FifoCount,
            FifoReadAddr => FifoReadAddr,
            FifoWriteAddr => FifoWriteAddr,
            FifoPeekAddr => FifoPeekAddr,
            FifoPeekData => FifoPeekData,
            FifoMultiPopAddr => FifoMultiPopAddr,
            FifoMultiPopStrobe => FifoMultiPopStrobe
        );

end architecture sim;
