--! \brief Testbench for UartTxParity.vhd
--! Same core TX checks as UartTx_tb.vhd, with parity framing enabled.
--! Mainly to confirm Busy-gated Go behavior stays solid with parity enabled.
--! Sending correct Parity bit under heavy load.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity UartTxParity_tb is
end UartTxParity_tb;

architecture sim of UartTxParity_tb is

    signal clk : std_logic;
    signal rst : std_logic;
    signal Go : std_logic;
    signal TxD : std_logic;
    signal TxD_odd : std_logic;
    signal Busy : std_logic;
    signal Busy_odd : std_logic;
    signal Data : std_logic_vector(7 downto 0);

    signal test_name_display : string(1 to 80);

    constant CLK_PERIOD : time := 10 ns;

    signal PARITY_EVEN : std_logic := '1';

    function parity(data_i : std_logic_vector(7 downto 0); parity_even_i : std_logic) return std_logic is
        variable parity_bit : std_logic := '0';
        begin
            for i in 0 to 7 loop
                parity_bit := parity_bit xor data_i(i);
            end loop;
            if (parity_even_i = '1') then
                return (parity_bit);
            else
                return not(parity_bit);
            end if;
    end function;

    procedure assert_idle(
        signal TxD_i : in std_logic;
        signal Busy_i : in std_logic
    ) is
    begin
        assert_equal(TxD_i, '1', "Idle: TxD should be 1");
        assert_equal(Busy_i, '0', "Idle: Busy should be 0");
    end procedure;

    procedure transmit_byte(
        signal Data_o : out std_logic_vector(7 downto 0);
        signal Go_o : out std_logic;
        signal TxD_i : in std_logic;
        signal Busy_i : in std_logic;
        signal ParityEven_i : in std_logic;
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
        wait until falling_edge(clk);
        assert_equal(TxD_i, '0', "Start bit should be 0");
        assert_equal(Busy_i, '1', "Busy should be 1 after start bit");
        for i in 0 to 7 loop
            wait until falling_edge(clk);
            assert_equal(TxD_i, data_i(i), "TxD should be the data bit for the current bit count");
            assert_equal(Busy_i, '1', "Busy should be 1 after data bit");
        end loop;
        wait until falling_edge(clk);
        assert_equal(TxD_i, parity(data_i, ParityEven_i), "Parity bit should be the parity bit for the data");

        wait until falling_edge(clk);
        assert_equal(TxD_i, '1', "Stop bit should be 1");
        assert_equal(Busy_i, '1', "Busy should be 1 after stop bit");

        wait until falling_edge(clk);
        assert_equal(TxD_i, '1', "Idle bit should be 1");
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
        PARITY_EVEN <= '1';
        Go <= '0';
        Data <= (others => '0');

        set_test_name(test_name_display, "Reset");
        report COLOR_YELLOW & "Test: Reset" & COLOR_RESET;
        reset_dut(clk, rst);
        assert_idle(TxD, Busy);

        set_test_name(test_name_display, "Data patterns general");
        report COLOR_YELLOW & "Test: Data patterns general" & COLOR_RESET;
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"55");
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"00");
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"FF");
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"01");
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"80");
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"A3");
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"96");

        set_test_name(test_name_display, "Data patterns general (odd parity)");
        report COLOR_YELLOW & "Test: Data patterns general (odd parity)" & COLOR_RESET;
        PARITY_EVEN <= '0';
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"55");
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"00");
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"FF");
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"01");
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"80");
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"A3");
        transmit_byte(Data, Go, TxD_odd, Busy_odd, PARITY_EVEN, x"96");
        PARITY_EVEN <= '1';

        set_test_name(test_name_display, "Go held high: single frame, retrigger after Go change");
        report COLOR_YELLOW & "Test: Go held high: single frame, retrigger after Go change" & COLOR_RESET;
        reset_dut(clk, rst);
        Data <= x"55";
        wait until falling_edge(clk);
        Go <= '1';
        wait until Busy = '1';
        wait until Busy = '0';
        assert_equal(Go, '1', "Go still high after first frame");
        assert_idle(TxD, Busy);
        for k in 1 to 20 loop
            wait until falling_edge(clk);
            assert_idle(TxD, Busy);
        end loop;
        Go <= '0';
        wait until falling_edge(clk);
        assert_idle(TxD, Busy);
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"3C");

        set_test_name(test_name_display, "Go toggles while Busy: frame not corrupted");
        report COLOR_YELLOW & "Test: Go toggles while Busy: frame not corrupted" & COLOR_RESET;
        reset_dut(clk, rst);
        Data <= x"00";
        pulse_go(Go);
        wait until falling_edge(clk);
        assert_equal(TxD, '0', "Start bit");
        assert_equal(Busy, '1', "Busy should be 1 after start bit");
        pulse_go(Go);
        pulse_go(Go);
        wait until falling_edge(clk);
        for i in 5 to 7 loop -- Skip the first two bits because Go toggles shouldn't start fresh transfer
            wait until falling_edge(clk);
            assert_equal(TxD, byte_bit(x"00", i), "Data bit");
            assert_equal(Busy, '1', "Busy should be 1 after data bit");
        end loop;
        wait until falling_edge(clk);
        assert_equal(TxD, parity(x"00", PARITY_EVEN), "Parity bit");
        wait until falling_edge(clk);
        assert_equal(TxD, '1', "Stop bit");
        wait until falling_edge(clk);
        assert_idle(TxD, Busy);
        wait until falling_edge(clk);
        assert_idle(TxD, Busy);
        wait until falling_edge(clk);
        assert_idle(TxD, Busy);

        set_test_name(test_name_display, "Reset during transmission");
        report COLOR_YELLOW & "Test: Reset during transmission" & COLOR_RESET;
        reset_dut(clk, rst);
        Data <= x"6E";
        pulse_go(Go);
        wait until falling_edge(clk);
        assert_equal(TxD, '0', "Start bit before reset");
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(TxD, '1', "TxD idle immediately after async reset");
        assert_equal(Busy, '0', "Busy low after reset");
        rst <= '0';
        wait until falling_edge(clk);
        assert_idle(TxD, Busy);

        set_test_name(test_name_display, "Idle stability over many clocks");
        report COLOR_YELLOW & "Test: Idle stability over many clocks" & COLOR_RESET;
        reset_dut(clk, rst);
        for m in 1 to 32 loop
            wait until falling_edge(clk);
            assert_idle(TxD, Busy);
        end loop;

        -- Chaning data halfway through changes it transmission. Should this be latched?
        set_test_name(test_name_display, "Data held constant vs mid-frame change (non-latched)");
        report COLOR_YELLOW & "Test: Data held constant vs mid-frame change (non-latched)" & COLOR_RESET;
        reset_dut(clk, rst);
        Data <= x"55";
        transmit_byte(Data, Go, TxD, Busy, PARITY_EVEN, x"55");

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
        assert_equal(TxD, parity(x"AA", PARITY_EVEN), "Parity bit");
        wait until falling_edge(clk);
        assert_equal(TxD, '1', "Stop bit");
        wait until falling_edge(clk);
        assert_idle(TxD, Busy);

        finish;

    end process;

    dut_even : entity work.UartTxParity
        generic map (
            PARITY_EVEN => '1'
        )
        port map (
            Clk => clk,
            Reset => rst,
            Go => Go,
            TxD => TxD,
            Busy => Busy,
            Data => Data
        );

    dut_odd : entity work.UartTxParity
        generic map (
            PARITY_EVEN => '0'
        )
        port map (
            Clk => clk,
            Reset => rst,
            Go => Go,
            TxD => TxD_odd,
            Busy => Busy_odd,
            Data => Data
        );

end architecture sim;
