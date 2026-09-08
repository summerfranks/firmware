--! \brief Testbench for UartTxFifoExtClk.vhd
--! Covers FIFO fed TX flow from empty to queued multi-byte sends under external clk.
--! Verifies CTS blocking/unblocking behavior and handoff timing.
--! Includes full-queue boundaries and reset during queued/active transmission.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartTxFifoExtClk_tb is
end UartTxFifoExtClk_tb;

architecture sim of UartTxFifoExtClk_tb is

    constant CLOCK_FREQHZ : natural := 16000000;
    constant BAUDRATE : natural := 1000000;
    constant FIFO_BITS : natural := 10;

    constant CLK_PERIOD : time := 1 sec / CLOCK_FREQHZ;
    constant BIT_CLK_PERIOD : time := 1 sec / BAUDRATE;
    constant UCLK_PERIOD : time := 1 sec / BAUDRATE;

    signal clk : std_logic;
    signal bit_clk : std_logic;
    signal uclk : std_logic;
    signal rst : std_logic;

    signal WriteStrobe : std_logic;
    signal WriteData : std_logic_vector(7 downto 0);
    signal FifoFull : std_logic;
    signal FifoEmpty : std_logic;
    signal FifoCount : std_logic_vector(FIFO_BITS - 1 downto 0);
    signal BitClockOut : std_logic;
    signal BitCountOut : std_logic_vector(3 downto 0);
    signal TxInProgress : std_logic;
    signal Cts : std_logic;
    signal Txd : std_logic;

    signal test_name_display : string(1 to 80);

    procedure write_fifo_byte(
        signal WriteStrobe_o : out std_logic;
        signal WriteData_o : out std_logic_vector(7 downto 0);
        constant b : in std_logic_vector(7 downto 0)
    ) is
    begin
        WriteData_o <= b;
        WriteStrobe_o <= '1';
        wait until falling_edge(clk);
        WriteStrobe_o <= '0';
        wait until falling_edge(clk);
    end procedure;

    procedure wait_for_tx_start(
        signal TxInProgress_i : in std_logic
    ) is
    begin
        while (TxInProgress_i /= '1') loop
            wait until falling_edge(clk);
        end loop;
        assert_equal(TxInProgress_i, '1', "TxInProgress should go high");
    end procedure;

    procedure wait_for_tx_done(
        signal TxInProgress_i : in std_logic
    ) is
    begin
        while (TxInProgress_i /= '0') loop
            wait until falling_edge(clk);
        end loop;
        assert_equal(TxInProgress_i, '0', "TxInProgress should return low");
    end procedure;

    procedure assert_uart_tx_byte(
        signal BitClock_i : in std_logic;
        signal Txd_i : in std_logic;
        constant b : in std_logic_vector(7 downto 0)
    ) is
    begin
        wait until falling_edge(BitClock_i);
        assert_equal(Txd_i, '0', "UART start bit should be 0");
        for i in 0 to 7 loop
            wait until falling_edge(BitClock_i);
            assert_equal(Txd_i, byte_bit(b, i), "UART data bit should match expected byte");
        end loop;
        wait until falling_edge(BitClock_i);
        assert_equal(Txd_i, '1', "UART stop bit should be 1");
    end procedure;

begin

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    bit_clk_process : process
    begin
        bit_clk <= '0';
        wait for BIT_CLK_PERIOD / 2;
        bit_clk <= '1';
        wait for BIT_CLK_PERIOD / 2;
    end process;

    uclk_process : process
    begin
        uclk <= '0';
        wait for UCLK_PERIOD / 2;
        uclk <= '1';
        wait for UCLK_PERIOD / 2;
    end process;

    test_process : process
    begin
        WriteStrobe <= '0';
        WriteData <= (others => '0');
        Cts <= '0';

        set_test_name(test_name_display, "Reset and idle");
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after reset");
        assert_equal(FifoFull, '0', "FifoFull should be 0 after reset");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should be 0 after reset");
        assert_equal(TxInProgress, '0', "TxInProgress should be 0 after reset");
        assert_equal(Txd, '1', "Txd should idle high after reset");

        set_test_name(test_name_display, "Single byte write transmits");
        write_fifo_byte(WriteStrobe, WriteData, x"A5");
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"A5");
        wait_for_tx_done(TxInProgress);
        assert_equal(FifoEmpty, '1', "FifoEmpty should be 1 after one byte transmits");

        set_test_name(test_name_display, "Two-byte queue transmits both");
        write_fifo_byte(WriteStrobe, WriteData, x"11");
        write_fifo_byte(WriteStrobe, WriteData, x"22");
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"11");
        wait_for_tx_done(TxInProgress);
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"22");
        wait_for_tx_done(TxInProgress);
        assert_equal(FifoEmpty, '1', "Fifo should be empty after two transmissions");

        set_test_name(test_name_display, "Not ready (CTS high) blocks transmission");
        Cts <= '1';
        write_fifo_byte(WriteStrobe, WriteData, x"33");
        for i in 0 to 40 loop
            wait until falling_edge(clk);
        end loop;
        assert_equal(TxInProgress, '0', "Tx should not start while CTS is high");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "Queued byte should stay in fifo while CTS is high");
        Cts <= '0';
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"33");
        wait_for_tx_done(TxInProgress);

        set_test_name(test_name_display, "Write while tx in progress and CTS ready");
        reset_dut(clk, rst);
        Cts <= '0';
        write_fifo_byte(WriteStrobe, WriteData, x"77");
        wait_for_tx_start(TxInProgress);
        WriteData <= x"88";
        wait until falling_edge(clk);
        WriteStrobe <= '1';
        wait until falling_edge(clk);
        WriteStrobe <= '0';
        assert_uart_tx_byte(BitClockOut, Txd, x"77");
        wait_for_tx_done(TxInProgress);
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"88");
        wait_for_tx_done(TxInProgress);
        assert_equal(FifoEmpty, '1', "Fifo should be empty after second byte transmits");

        set_test_name(test_name_display, "Write overlaps fifo read-to-tx handoff");
        reset_dut(clk, rst);
        write_fifo_byte(WriteStrobe, WriteData, x"A1");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(1, FIFO_BITS)), "One byte should be queued before overlap");
        -- Write and read at same clk pulse for the FIFO
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        WriteData <= x"B2";
        WriteStrobe <= '1';
        wait until falling_edge(clk);
        WriteStrobe <= '0';
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"A1");
        wait_for_tx_done(TxInProgress);
        wait_for_tx_start(TxInProgress);
        assert_uart_tx_byte(BitClockOut, Txd, x"B2");
        wait_for_tx_done(TxInProgress);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should return to 0 after overlap read/write case");
        assert_equal(FifoEmpty, '1', "Fifo should be empty after overlap read/write case");

        set_test_name(test_name_display, "Reset while queued and CTS blocked");
        reset_dut(clk, rst);
        Cts <= '1';
        write_fifo_byte(WriteStrobe, WriteData, x"99");
        write_fifo_byte(WriteStrobe, WriteData, x"AA");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(2, FIFO_BITS)), "Two bytes should queue while CTS blocked");
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        wait until falling_edge(clk);
        assert_equal(FifoEmpty, '1', "Reset should clear queued data while CTS blocked");
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should clear on reset");
        Cts <= '0';

        set_test_name(test_name_display, "Fill fifo to full then drain");
        reset_dut(clk, rst);
        Cts <= '1';
        for i in 0 to (2 ** FIFO_BITS) - 1 loop
            write_fifo_byte(WriteStrobe, WriteData, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        assert_equal(FifoCount, std_logic_vector(to_unsigned((2 ** FIFO_BITS) - 1, FIFO_BITS)), "FifoCount should be DEPTH-1 at full");
        Cts <= '0';
        wait_for_tx_start(TxInProgress);
        for i in 0 to (2 ** FIFO_BITS) - 1 loop
            assert_uart_tx_byte(BitClockOut, Txd, std_logic_vector(to_unsigned(i mod 256, 8)));
            wait_for_tx_done(TxInProgress);
            if (i < (2 ** FIFO_BITS) - 1) then
                wait_for_tx_start(TxInProgress);
            end if;
        end loop;
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "FifoCount should return to 0 after drain");

        set_test_name(test_name_display, "Reset during transmission");
        reset_dut(clk, rst);
        Cts <= '0';
        write_fifo_byte(WriteStrobe, WriteData, x"66");
        wait_for_tx_start(TxInProgress);
        wait until falling_edge(clk);
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(Txd, '1', "Txd should return high on reset");
        -- assert_equal(TxInProgress, '0', "TxInProgress should drop after reset"); -- with Ibuff2 this will stay high for a bit
        assert_equal(FifoEmpty, '1', "Fifo should be empty after reset");
        rst <= '0';
        for i in 0 to 6 loop
            wait until falling_edge(clk);
            assert_equal(Txd, '1', "No additional bits should be transmitted after reset");
        end loop;
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(TxInProgress, '0', "TxInProgress should drop after reset");
        wait until falling_edge(clk);
        assert_equal(FifoEmpty, '1', "Fifo should be empty after reset");

        set_test_name(test_name_display, "Reset while WriteStrobe high");
        WriteData <= x"00";
        wait until falling_edge(clk);
        WriteStrobe <= '1';
        rst <= '1';
        wait until falling_edge(clk);
        WriteStrobe <= '0';
        rst <= '0';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(FifoCount, std_logic_vector(to_unsigned(0, FIFO_BITS)), "Reset during WriteStrobe should not leave a phantom write");
        assert_equal(FifoEmpty, '1', "Fifo should stay empty after reset-during-write edge case");

        finish;
    end process;

    dut : entity work.UartTxFifoExtClk
        generic map (
            FIFO_BITS => FIFO_BITS
        )
        port map (
            clk => clk,
            uclk => uclk,
            rst => rst,
            WriteStrobe => WriteStrobe,
            WriteData => WriteData,
            FifoFull => FifoFull,
            FifoEmpty => FifoEmpty,
            FifoCount => FifoCount,
            BitClockOut => BitClockOut,
            BitCountOut => BitCountOut,
            TxInProgress => TxInProgress,
            Cts => Cts,
            Txd => Txd
        );

end architecture sim;
