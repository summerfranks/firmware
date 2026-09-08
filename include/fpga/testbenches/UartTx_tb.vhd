--! \brief Testbench for UartTx.vhd
--! Reset/idle and normal TX data transmission.
--! Go/Busy interaction (no accidental retrigger while busy).
--! Reset during transmission is covered.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartTx_tb is
end UartTx_tb;

architecture sim of UartTx_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal Go : std_logic;
    signal TxD : std_logic;
    signal Busy : std_logic;
    signal BitCountOut : std_logic_vector(3 downto 0);
    signal Data : std_logic_vector(7 downto 0);

    signal test_name_display : string(1 to 80);

    constant CLK_PERIOD : time := 10 ns;

    procedure assert_idle(
        signal TxD_i : in std_logic;
        signal Busy_i : in std_logic;
        signal BitCountOut_i : in std_logic_vector(3 downto 0)
    ) is
    begin
        assert_equal(TxD_i, '1', "Idle: TxD should be 1");
        assert_equal(Busy_i, '0', "Idle: Busy should be 0");
        assert_equal(BitCountOut_i, "1001", "Idle: BitCountOut should be 1001");
    end procedure;

    procedure transmit_byte(
        signal Data_o : out std_logic_vector(7 downto 0);
        signal Go_o : out std_logic;
        signal TxD_i : in std_logic;
        signal BitCountOut_i : in std_logic_vector(3 downto 0);
        signal Busy_i : in std_logic;
        constant data_i : in std_logic_vector(7 downto 0)
    ) is
    begin
        Data_o <= data_i;
        report COLOR_YELLOW & "Transmitting data: " & to_hstring(data_i) & COLOR_RESET;
        wait until falling_edge(clk);
        Go_o <= '1';
        wait until falling_edge(clk);
        Go_o <= '0';
        assert_equal(Busy_i, '0', "Busy should be 0 after Go=0");
        assert_equal(TxD_i, '1', "TxD should be 1 after Go=0 (before start bit)");
        assert_equal(BitCountOut_i, "1111", "BitCountOut should be 1111 after Go=0");
        wait until falling_edge(clk);
        assert_equal(TxD_i, '0', "Start bit should be 0");
        assert_equal(BitCountOut_i, "0000", "Start bit count should be 0");
        assert_equal(Busy_i, '1', "Busy should be 1 after start bit");
        for i in 0 to 7 loop
            wait until falling_edge(clk);
            assert_equal(TxD_i, data_i(i), "TxD should be the data bit for the current bit count");
            assert_equal(BitCountOut_i, std_logic_vector(to_unsigned(i + 1, 4)), "BitCountOut should be the current bit count");
            assert_equal(Busy_i, '1', "Busy should be 1 after data bit");
        end loop;
        wait until falling_edge(clk);
        assert_equal(TxD_i, '1', "Stop bit should be 1");
        assert_equal(BitCountOut_i, "1001", "Stop bit count should be 1001");
        assert_equal(Busy_i, '1', "Busy should be 1 after stop bit");

        wait until falling_edge(clk);
        assert_equal(TxD_i, '1', "Idle bit should be 1");
        assert_equal(BitCountOut_i, "1001", "Idle bit count should be 1001");
        assert_equal(Busy_i, '0', "Busy should be 0 after idle bit");
    end procedure;

    procedure pulse_go(signal Go_o : out std_logic) is
    begin
        wait until falling_edge(clk);
        Go_o <= '1';
        wait until falling_edge(clk);
        Go_o <= '0';
    end procedure;

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
        Go <= '0';
        Data <= (others => '0');

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_idle(TxD, Busy, BitCountOut);

        set_test_name(test_name_display, "Data patterns general");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"55");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"00");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"FF");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"01");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"80");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"A3");
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"96");

        set_test_name(test_name_display, "Go held high: single frame, retrigger after Go change");
        reset_dut(clk, rst);
        Data <= x"55";
        wait until falling_edge(clk);
        Go <= '1';
        wait until Busy = '1';
        wait until Busy = '0';
        assert_equal(Go, '1', "Go still high after first frame");
        assert_idle(TxD, Busy, BitCountOut);
        for k in 1 to 20 loop
            wait until falling_edge(clk);
            assert_idle(TxD, Busy, BitCountOut);
        end loop;
        Go <= '0';
        wait until falling_edge(clk);
        assert_idle(TxD, Busy, BitCountOut);
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"3C");

        set_test_name(test_name_display, "Go toggles while Busy: frame not corrupted");
        reset_dut(clk, rst);
        Data <= x"A3";
        pulse_go(Go);
        wait until falling_edge(clk);
        assert_equal(TxD, '0', "Start bit");
        assert_equal(BitCountOut, "0000", "BitCountOut should be 0 after start bit");
        assert_equal(Busy, '1', "Busy should be 1 after start bit");
        pulse_go(Go);
        wait until falling_edge(clk);
        for i in 3 to 7 loop -- Skip the first two bits because Go toggles shouldn't start fresh transfer
            wait until falling_edge(clk);
            assert_equal(TxD, byte_bit(x"A3", i), "Data bit");
            assert_equal(BitCountOut, std_logic_vector(to_unsigned(i + 1, 4)), "BitCountOut should be the current bit count");
            assert_equal(Busy, '1', "Busy should be 1 after data bit");
        end loop;
        wait until falling_edge(clk);
        assert_equal(TxD, '1', "Stop bit");
        wait until falling_edge(clk);
        assert_idle(TxD, Busy, BitCountOut);

        set_test_name(test_name_display, "Reset during transmission");
        reset_dut(clk, rst);
        Data <= x"6E";
        pulse_go(Go);
        wait until falling_edge(clk);
        assert_equal(TxD, '0', "Start bit before reset");
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until BitCountOut = "0011" and Busy = '1';
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(TxD, '1', "TxD idle immediately after async reset");
        assert_equal(Busy, '0', "Busy low after reset");
        assert_equal(BitCountOut, "1001", "BitCountOut 1001 after reset");
        rst <= '0';
        wait until falling_edge(clk);
        assert_idle(TxD, Busy, BitCountOut);

        set_test_name(test_name_display, "Idle stability over many clocks");
        reset_dut(clk, rst);
        for m in 1 to 32 loop
            wait until falling_edge(clk);
            assert_idle(TxD, Busy, BitCountOut);
        end loop;

        -- Chaning data halfway through changes it transmission. Should this be latched?
        set_test_name(test_name_display, "Data held constant vs mid-frame change (non-latched)");
        reset_dut(clk, rst);
        Data <= x"55";
        transmit_byte(Data, Go, TxD, BitCountOut, Busy, x"55");

        reset_dut(clk, rst);
        Data <= x"55";
        pulse_go(Go);
        wait until falling_edge(clk);
        assert_equal(TxD, '0', "Start bit");
        wait until falling_edge(clk);
        assert_equal(TxD, byte_bit(x"55", 0), "Bit 0 from initial Data");
        wait until falling_edge(clk);
        assert_equal(TxD, byte_bit(x"55", 1), "Bit 1 from initial Data");
        Data <= x"AA";
        for i in 2 to 7 loop
            wait until falling_edge(clk);
            assert_equal(TxD, byte_bit(x"AA", i), "TxD follows updated Data (not latched)");
        end loop;
        wait until falling_edge(clk);
        assert_equal(TxD, '1', "Stop bit");
        wait until falling_edge(clk);
        assert_idle(TxD, Busy, BitCountOut);

        finish;

    end process;

    dut : entity work.UartTx
        port map (
            Clk => clk,
            Reset => rst,
            Go => Go,
            TxD => TxD,
            Busy => Busy,
            BitCountOut => BitCountOut,
            Data => Data
        );

end architecture sim;
