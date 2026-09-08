--! \brief Testbench for SpiMasterQuad.vhd
--! Quad MOSI/MISO transfers, latch behavior, reset gating, and multi-byte widths.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity SpiMasterQuad_tb is
end SpiMasterQuad_tb;

architecture sim of SpiMasterQuad_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant DEFAULT_BIT_CYCLES : natural := 1000;
    constant XFER_COMPLETE_TIMEOUT_CYCLES : natural := 200000;

    type spi_tb_out_t is record
        rst           : std_logic;
        miso_a        : std_logic;
        miso_b        : std_logic;
        miso_c        : std_logic;
        miso_d        : std_logic;
    end record;

    type spi_dut_out_t is record
        mosi_a        : std_logic;
        mosi_b        : std_logic;
        mosi_c        : std_logic;
        mosi_d        : std_logic;
        sck           : std_logic;
        xfer_complete : std_logic;
    end record;

    type spi_if_t is record
        tb  : spi_tb_out_t;
        dut : spi_dut_out_t;
    end record;

    signal clk : std_logic;
    signal test_name_display : string(1 to 80);

    signal spi_mode0, spi_mode1, spi_mode2, spi_mode3 : spi_if_t;
    signal spi_bw4, spi_bw16 : spi_if_t;
    signal spi_bwclk2, spi_bwclk10 : spi_if_t;
    signal spi_bw2_clk10 : spi_if_t;

    signal data_to_mosi_a_1, data_from_miso_a_1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_b_1, data_from_miso_b_1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_c_1, data_from_miso_c_1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_d_1, data_from_miso_d_1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_a_mode1, data_from_miso_a_mode1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_b_mode1, data_from_miso_b_mode1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_c_mode1, data_from_miso_c_mode1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_d_mode1, data_from_miso_d_mode1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_a_mode2, data_from_miso_a_mode2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_b_mode2, data_from_miso_b_mode2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_c_mode2, data_from_miso_c_mode2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_d_mode2, data_from_miso_d_mode2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_a_mode3, data_from_miso_a_mode3 : std_logic_vector(7 downto 0);
    signal data_to_mosi_b_mode3, data_from_miso_b_mode3 : std_logic_vector(7 downto 0);
    signal data_to_mosi_c_mode3, data_from_miso_c_mode3 : std_logic_vector(7 downto 0);
    signal data_to_mosi_d_mode3, data_from_miso_d_mode3 : std_logic_vector(7 downto 0);
    signal data_to_mosi_a_4, data_from_miso_a_4 : std_logic_vector(31 downto 0);
    signal data_to_mosi_b_4, data_from_miso_b_4 : std_logic_vector(31 downto 0);
    signal data_to_mosi_c_4, data_from_miso_c_4 : std_logic_vector(31 downto 0);
    signal data_to_mosi_d_4, data_from_miso_d_4 : std_logic_vector(31 downto 0);
    signal data_to_mosi_a_16, data_from_miso_a_16 : std_logic_vector(127 downto 0);
    signal data_to_mosi_b_16, data_from_miso_b_16 : std_logic_vector(127 downto 0);
    signal data_to_mosi_c_16, data_from_miso_c_16 : std_logic_vector(127 downto 0);
    signal data_to_mosi_d_16, data_from_miso_d_16 : std_logic_vector(127 downto 0);
    signal data_to_mosi_a_clk2, data_from_miso_a_clk2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_b_clk2, data_from_miso_b_clk2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_c_clk2, data_from_miso_c_clk2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_d_clk2, data_from_miso_d_clk2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_a_clk10, data_from_miso_a_clk10 : std_logic_vector(7 downto 0);
    signal data_to_mosi_b_clk10, data_from_miso_b_clk10 : std_logic_vector(7 downto 0);
    signal data_to_mosi_c_clk10, data_from_miso_c_clk10 : std_logic_vector(7 downto 0);
    signal data_to_mosi_d_clk10, data_from_miso_d_clk10 : std_logic_vector(7 downto 0);
    signal data_to_mosi_a_2_10, data_from_miso_a_2_10 : std_logic_vector(15 downto 0);
    signal data_to_mosi_b_2_10, data_from_miso_b_2_10 : std_logic_vector(15 downto 0);
    signal data_to_mosi_c_2_10, data_from_miso_c_2_10 : std_logic_vector(15 downto 0);
    signal data_to_mosi_d_2_10, data_from_miso_d_2_10 : std_logic_vector(15 downto 0);

    procedure send_receive_transfer(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal data_to_mosi_a : out std_logic_vector;
        signal data_to_mosi_b : out std_logic_vector;
        signal data_to_mosi_c : out std_logic_vector;
        signal data_to_mosi_d : out std_logic_vector;
        signal data_from_miso_a : in std_logic_vector;
        signal data_from_miso_b : in std_logic_vector;
        signal data_from_miso_c : in std_logic_vector;
        signal data_from_miso_d : in std_logic_vector;
        constant cpol : in std_logic;
        constant cpha : in std_logic;
        constant tx_data_a : std_logic_vector;
        constant tx_data_b : std_logic_vector;
        constant tx_data_c : std_logic_vector;
        constant tx_data_d : std_logic_vector;
        constant rx_data_a : std_logic_vector;
        constant rx_data_b : std_logic_vector;
        constant rx_data_c : std_logic_vector;
        constant rx_data_d : std_logic_vector
    ) is
        variable tx_vec_a : std_logic_vector(data_to_mosi_a'range);
        variable tx_vec_b : std_logic_vector(data_to_mosi_b'range);
        variable tx_vec_c : std_logic_vector(data_to_mosi_c'range);
        variable tx_vec_d : std_logic_vector(data_to_mosi_d'range);
        variable rx_vec_a : std_logic_vector(data_to_mosi_a'range);
        variable rx_vec_b : std_logic_vector(data_to_mosi_b'range);
        variable rx_vec_c : std_logic_vector(data_to_mosi_c'range);
        variable rx_vec_d : std_logic_vector(data_to_mosi_d'range);
    begin
        tx_vec_a := tx_data_a;
        tx_vec_b := tx_data_b;
        tx_vec_c := tx_data_c;
        tx_vec_d := tx_data_d;
        rx_vec_a := rx_data_a;
        rx_vec_b := rx_data_b;
        rx_vec_c := rx_data_c;
        rx_vec_d := rx_data_d;
        spi_tb.rst <= '1';
        
        wait until falling_edge(clk_in);

        data_to_mosi_a <= tx_vec_a;
        data_to_mosi_b <= tx_vec_b;
        data_to_mosi_c <= tx_vec_c;
        data_to_mosi_d <= tx_vec_d;
        spi_tb.miso_a <= rx_vec_a(rx_vec_a'high);
        spi_tb.miso_b <= rx_vec_b(rx_vec_b'high);
        spi_tb.miso_c <= rx_vec_c(rx_vec_c'high);
        spi_tb.miso_d <= rx_vec_d(rx_vec_d'high);

        assert_equal(spi_dut.xfer_complete, '0', "XferComplete low while idle");
        assert_equal(spi_dut.sck, not(cpol), "Sck idle level");

        spi_tb.rst <= '0';
        
        for bit_num in tx_vec_a'high downto tx_vec_a'low loop
            if cpha = '1' then
                wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
                assert_equal(spi_dut.sck, not(cpol xor cpha), "Sck at full-duplex sample point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Slave sampled MOSI A bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_a));
                assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Slave sampled MOSI B bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_b));
                assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num), "Slave sampled MOSI C bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_c));
                assert_equal(spi_dut.mosi_d, tx_vec_d(bit_num), "Slave sampled MOSI D bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_d));
                assert_equal(data_from_miso_a(bit_num), rx_vec_a(bit_num), "Master captured MISO A bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(data_from_miso_b(bit_num), rx_vec_b(bit_num), "Master captured MISO B bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(data_from_miso_c(bit_num), rx_vec_c(bit_num), "Master captured MISO C bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(data_from_miso_d(bit_num), rx_vec_d(bit_num), "Master captured MISO D bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex sample of bit " & integer'image(bit_num));

                if bit_num > tx_vec_a'low then
                    wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
                    spi_tb.miso_a <= rx_vec_a(bit_num - 1);
                    spi_tb.miso_b <= rx_vec_b(bit_num - 1);
                    spi_tb.miso_c <= rx_vec_c(bit_num - 1);
                    spi_tb.miso_d <= rx_vec_d(bit_num - 1);
                    assert_equal(spi_dut.sck, cpol xor cpha, "Sck at full-duplex shift point for bit " & integer'image(bit_num - 1));
                    assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num - 1), "Master shifted MOSI A bit " & integer'image(bit_num - 1) & " during full-duplex transfer");
                    assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num - 1), "Master shifted MOSI B bit " & integer'image(bit_num - 1) & " during full-duplex transfer");
                    assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num - 1), "Master shifted MOSI C bit " & integer'image(bit_num - 1) & " during full-duplex transfer");
                    assert_equal(spi_dut.mosi_d, tx_vec_d(bit_num - 1), "Master shifted MOSI D bit " & integer'image(bit_num - 1) & " during full-duplex transfer");
                    assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex shift of bit " & integer'image(bit_num - 1));
                end if;
            else
                wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
                assert_equal(spi_dut.sck, cpol xor cpha, "Sck at full-duplex shift point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Master shifted MOSI A bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Master shifted MOSI B bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num), "Master shifted MOSI C bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.mosi_d, tx_vec_d(bit_num), "Master shifted MOSI D bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex shift of bit " & integer'image(bit_num));

                if bit_num /= tx_vec_a'high then
                    spi_tb.miso_a <= rx_vec_a(bit_num);
                    spi_tb.miso_b <= rx_vec_b(bit_num);
                    spi_tb.miso_c <= rx_vec_c(bit_num);
                    spi_tb.miso_d <= rx_vec_d(bit_num);
                end if;

                wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
                assert_equal(spi_dut.sck, not(cpol xor cpha), "Sck at full-duplex sample point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Slave sampled MOSI A bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_a));
                assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Slave sampled MOSI B bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_b));
                assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num), "Slave sampled MOSI C bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_c));
                assert_equal(spi_dut.mosi_d, tx_vec_d(bit_num), "Slave sampled MOSI D bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_d));
                assert_equal(data_from_miso_a(bit_num), rx_vec_a(bit_num), "Master captured MISO A bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(data_from_miso_b(bit_num), rx_vec_b(bit_num), "Master captured MISO B bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(data_from_miso_c(bit_num), rx_vec_c(bit_num), "Master captured MISO C bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(data_from_miso_d(bit_num), rx_vec_d(bit_num), "Master captured MISO D bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex sample of bit " & integer'image(bit_num));
            end if;
        end loop;

        wait_until_value(clk_in, spi_dut.xfer_complete, '1', XFER_COMPLETE_TIMEOUT_CYCLES, "Timed out waiting for XferComplete after full-duplex transfer");
        assert_equal(data_from_miso_a, rx_vec_a, "DataFromMisoA after RX 0x" & to_hstring(rx_vec_a));
        assert_equal(data_from_miso_b, rx_vec_b, "DataFromMisoB after RX 0x" & to_hstring(rx_vec_b));
        assert_equal(data_from_miso_c, rx_vec_c, "DataFromMisoC after RX 0x" & to_hstring(rx_vec_c));
        assert_equal(data_from_miso_d, rx_vec_d, "DataFromMisoD after RX 0x" & to_hstring(rx_vec_d));
        assert_equal(spi_dut.xfer_complete, '1', "XferComplete after full-duplex xfer");

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.xfer_complete, '1', "XferComplete high after transfer completes and before reset");
        assert_equal(data_from_miso_a, rx_vec_a, "DataFromMisoA stable after transfer completes and before reset");
        assert_equal(data_from_miso_b, rx_vec_b, "DataFromMisoB stable after transfer completes and before reset");
        assert_equal(data_from_miso_c, rx_vec_c, "DataFromMisoC stable after transfer completes and before reset");
        assert_equal(data_from_miso_d, rx_vec_d, "DataFromMisoD stable after transfer completes and before reset");
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
        variable value_vec : std_logic_vector(7 downto 0);
        variable inv_value_vec : std_logic_vector(7 downto 0);
        variable xor_value_vec : std_logic_vector(7 downto 0);
        variable xnor_value_vec : std_logic_vector(7 downto 0);
    begin
        spi_mode0.tb.rst <= '1';
        spi_mode1.tb.rst <= '1';
        spi_mode2.tb.rst <= '1';
        spi_mode3.tb.rst <= '1';
        spi_bw4.tb.rst <= '1';
        spi_bw16.tb.rst <= '1';
        spi_bwclk2.tb.rst <= '1';
        spi_bwclk10.tb.rst <= '1';
        spi_bw2_clk10.tb.rst <= '1';

        spi_mode0.tb.miso_a <= '0';
        spi_mode0.tb.miso_b <= '0';
        spi_mode0.tb.miso_c <= '0';
        spi_mode0.tb.miso_d <= '0';
        spi_mode1.tb.miso_a <= '0';
        spi_mode1.tb.miso_b <= '0';
        spi_mode1.tb.miso_c <= '0';
        spi_mode1.tb.miso_d <= '0';
        spi_mode2.tb.miso_a <= '0';
        spi_mode2.tb.miso_b <= '0';
        spi_mode2.tb.miso_c <= '0';
        spi_mode2.tb.miso_d <= '0';
        spi_mode3.tb.miso_a <= '0';
        spi_mode3.tb.miso_b <= '0';
        spi_mode3.tb.miso_c <= '0';
        spi_mode3.tb.miso_d <= '0';
        spi_bw4.tb.miso_a <= '0';
        spi_bw4.tb.miso_b <= '0';
        spi_bw4.tb.miso_c <= '0';
        spi_bw4.tb.miso_d <= '0';
        spi_bw16.tb.miso_a <= '0';
        spi_bw16.tb.miso_b <= '0';
        spi_bw16.tb.miso_c <= '0';
        spi_bw16.tb.miso_d <= '0';
        spi_bwclk2.tb.miso_a <= '0';
        spi_bwclk2.tb.miso_b <= '0';
        spi_bwclk2.tb.miso_c <= '0';
        spi_bwclk2.tb.miso_d <= '0';
        spi_bwclk10.tb.miso_a <= '0';
        spi_bwclk10.tb.miso_b <= '0';
        spi_bwclk10.tb.miso_c <= '0';
        spi_bwclk10.tb.miso_d <= '0';
        spi_bw2_clk10.tb.miso_a <= '0';
        spi_bw2_clk10.tb.miso_b <= '0';
        spi_bw2_clk10.tb.miso_c <= '0';
        spi_bw2_clk10.tb.miso_d <= '0';

        set_test_name(test_name_display, "Mode 0 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.xfer_complete, '0', "Mode 0 XferComplete low in idle");
        assert_equal(spi_mode0.dut.sck, '1', "Mode 0 Sck idle level");

        set_test_name(test_name_display, "Mode 0 send");
        send_receive_transfer(clk, spi_mode0.tb, spi_mode0.dut, data_to_mosi_a_1, data_to_mosi_b_1, data_to_mosi_c_1, data_to_mosi_d_1, data_from_miso_a_1, data_from_miso_b_1, data_from_miso_c_1, data_from_miso_d_1, '0', '0', x"AB", x"CD", x"96", x"5A", x"00", x"00", x"00", x"00");

        set_test_name(test_name_display, "Mode 0 receive");
        send_receive_transfer(clk, spi_mode0.tb, spi_mode0.dut, data_to_mosi_a_1, data_to_mosi_b_1, data_to_mosi_c_1, data_to_mosi_d_1, data_from_miso_a_1, data_from_miso_b_1, data_from_miso_c_1, data_from_miso_d_1, '0', '0', x"00", x"00", x"00", x"00", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 0 send and receive");
        send_receive_transfer(clk, spi_mode0.tb, spi_mode0.dut, data_to_mosi_a_1, data_to_mosi_b_1, data_to_mosi_c_1, data_to_mosi_d_1, data_from_miso_a_1, data_from_miso_b_1, data_from_miso_c_1, data_from_miso_d_1, '0', '0', x"AB", x"CD", x"96", x"5A", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 0 active MOSI follows pre-latch input");
        spi_mode0.tb.rst <= '1';
        data_to_mosi_a_1 <= x"80";
        data_to_mosi_b_1 <= x"40";
        data_to_mosi_c_1 <= x"20";
        data_to_mosi_d_1 <= x"10";
        wait until falling_edge(clk);
        spi_mode0.tb.rst <= '0';
        data_to_mosi_a_1 <= x"40";
        data_to_mosi_b_1 <= x"80";
        data_to_mosi_c_1 <= x"10";
        data_to_mosi_d_1 <= x"20";
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.mosi_a, '0', "MOSI A picks up updated MSB before the first SPI clock edge");
        assert_equal(spi_mode0.dut.mosi_b, '1', "MOSI B picks up updated MSB before the first SPI clock edge");
        assert_equal(spi_mode0.dut.mosi_c, '0', "MOSI C picks up updated MSB before the first SPI clock edge");
        assert_equal(spi_mode0.dut.mosi_d, '0', "MOSI D picks up updated MSB before the first SPI clock edge");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi_a, '0', "First shifted MOSI A bit uses updated pre-latch input");
        assert_equal(spi_mode0.dut.mosi_b, '1', "First shifted MOSI B bit uses updated pre-latch input");
        assert_equal(spi_mode0.dut.mosi_c, '0', "First shifted MOSI C bit uses updated pre-latch input");
        assert_equal(spi_mode0.dut.mosi_d, '0', "First shifted MOSI D bit uses updated pre-latch input");
        spi_mode0.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.xfer_complete, '0', "Active MOSI test XferComplete low after reset");

        set_test_name(test_name_display, "Mode 0 send data latch mid-transfer");
        spi_mode0.tb.rst <= '1';
        data_to_mosi_a_1 <= x"AB";
        data_to_mosi_b_1 <= x"CD";
        data_to_mosi_c_1 <= x"96";
        data_to_mosi_d_1 <= x"5A";
        wait until falling_edge(clk);
        spi_mode0.tb.rst <= '0';
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '1'));
        assert_equal(spi_mode0.dut.mosi_a, '1', "Slave sampled original MOSI A bit 7 before data change");
        assert_equal(spi_mode0.dut.mosi_b, '1', "Slave sampled original MOSI B bit 7 before data change");
        assert_equal(spi_mode0.dut.mosi_c, '1', "Slave sampled original MOSI C bit 7 before data change");
        assert_equal(spi_mode0.dut.mosi_d, '0', "Slave sampled original MOSI D bit 7 before data change");
        data_to_mosi_a_1 <= x"54";
        data_to_mosi_b_1 <= x"32";
        data_to_mosi_c_1 <= x"69";
        data_to_mosi_d_1 <= x"A5";
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi_a, '0', "Master keeps latched MOSI A bit 6 after data change");
        assert_equal(spi_mode0.dut.mosi_b, '1', "Master keeps latched MOSI B bit 6 after data change");
        assert_equal(spi_mode0.dut.mosi_c, '0', "Master keeps latched MOSI C bit 6 after data change");
        assert_equal(spi_mode0.dut.mosi_d, '1', "Master keeps latched MOSI D bit 6 after data change");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '1'));
        assert_equal(spi_mode0.dut.mosi_a, '0', "Slave samples original MOSI A bit 6 after data change");
        assert_equal(spi_mode0.dut.mosi_b, '1', "Slave samples original MOSI B bit 6 after data change");
        assert_equal(spi_mode0.dut.mosi_c, '0', "Slave samples original MOSI C bit 6 after data change");
        assert_equal(spi_mode0.dut.mosi_d, '1', "Slave samples original MOSI D bit 6 after data change");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi_a, '1', "Master keeps latched MOSI A bit 5 after data change");
        assert_equal(spi_mode0.dut.mosi_b, '0', "Master keeps latched MOSI B bit 5 after data change");
        assert_equal(spi_mode0.dut.mosi_c, '0', "Master keeps latched MOSI C bit 5 after data change");
        assert_equal(spi_mode0.dut.mosi_d, '0', "Master keeps latched MOSI D bit 5 after data change");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi_a, '0', "Master keeps original latched MOSI A bit 4 late in transfer");
        assert_equal(spi_mode0.dut.mosi_b, '0', "Master keeps original latched MOSI B bit 4 late in transfer");
        assert_equal(spi_mode0.dut.mosi_c, '1', "Master keeps original latched MOSI C bit 4 late in transfer");
        assert_equal(spi_mode0.dut.mosi_d, '1', "Master keeps original latched MOSI D bit 4 late in transfer");
        wait_until_value(clk, spi_mode0.dut.xfer_complete, '1', XFER_COMPLETE_TIMEOUT_CYCLES, "Mode 0 latch test timed out waiting for XferComplete");
        assert_equal(spi_mode0.dut.xfer_complete, '1', "Mode 0 latch test completes original transfer");
        spi_mode0.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.xfer_complete, '0', "Mode 0 latch test XferComplete low after reset");
        assert_equal(spi_mode0.dut.sck, '1', "Mode 0 latch test Sck idle after reset");
        assert_equal(spi_mode0.dut.mosi_a, '0', "Mode 0 latch test MOSI A follows new MSB after reset");
        assert_equal(spi_mode0.dut.mosi_b, '0', "Mode 0 latch test MOSI B follows new MSB after reset");
        assert_equal(spi_mode0.dut.mosi_c, '0', "Mode 0 latch test MOSI C follows new MSB after reset");
        assert_equal(spi_mode0.dut.mosi_d, '1', "Mode 0 latch test MOSI D follows new MSB after reset");

        set_test_name(test_name_display, "Mode 2 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode2.dut.xfer_complete, '0', "Mode 2 XferComplete low in idle");
        assert_equal(spi_mode2.dut.sck, '0', "Mode 2 Sck idle level");

        set_test_name(test_name_display, "Mode 2 send");
        send_receive_transfer(clk, spi_mode2.tb, spi_mode2.dut, data_to_mosi_a_mode2, data_to_mosi_b_mode2, data_to_mosi_c_mode2, data_to_mosi_d_mode2, data_from_miso_a_mode2, data_from_miso_b_mode2, data_from_miso_c_mode2, data_from_miso_d_mode2, '1', '0', x"AB", x"CD", x"96", x"5A", x"00", x"00", x"00", x"00");

        set_test_name(test_name_display, "Mode 2 receive");
        send_receive_transfer(clk, spi_mode2.tb, spi_mode2.dut, data_to_mosi_a_mode2, data_to_mosi_b_mode2, data_to_mosi_c_mode2, data_to_mosi_d_mode2, data_from_miso_a_mode2, data_from_miso_b_mode2, data_from_miso_c_mode2, data_from_miso_d_mode2, '1', '0', x"00", x"00", x"00", x"00", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 2 send and receive");
        send_receive_transfer(clk, spi_mode2.tb, spi_mode2.dut, data_to_mosi_a_mode2, data_to_mosi_b_mode2, data_to_mosi_c_mode2, data_to_mosi_d_mode2, data_from_miso_a_mode2, data_from_miso_b_mode2, data_from_miso_c_mode2, data_from_miso_d_mode2, '1', '0', x"AB", x"CD", x"96", x"5A", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 1 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode1.dut.xfer_complete, '0', "Mode 1 XferComplete low in idle");
        assert_equal(spi_mode1.dut.sck, '1', "Mode 1 Sck idle level");

        set_test_name(test_name_display, "Mode 1 send");
        send_receive_transfer(clk, spi_mode1.tb, spi_mode1.dut, data_to_mosi_a_mode1, data_to_mosi_b_mode1, data_to_mosi_c_mode1, data_to_mosi_d_mode1, data_from_miso_a_mode1, data_from_miso_b_mode1, data_from_miso_c_mode1, data_from_miso_d_mode1, '0', '1', x"AB", x"CD", x"96", x"5A", x"00", x"00", x"00", x"00");

        set_test_name(test_name_display, "Mode 1 receive");
        send_receive_transfer(clk, spi_mode1.tb, spi_mode1.dut, data_to_mosi_a_mode1, data_to_mosi_b_mode1, data_to_mosi_c_mode1, data_to_mosi_d_mode1, data_from_miso_a_mode1, data_from_miso_b_mode1, data_from_miso_c_mode1, data_from_miso_d_mode1, '0', '1', x"00", x"00", x"00", x"00", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 1 send and receive");
        send_receive_transfer(clk, spi_mode1.tb, spi_mode1.dut, data_to_mosi_a_mode1, data_to_mosi_b_mode1, data_to_mosi_c_mode1, data_to_mosi_d_mode1, data_from_miso_a_mode1, data_from_miso_b_mode1, data_from_miso_c_mode1, data_from_miso_d_mode1, '0', '1', x"AB", x"CD", x"96", x"5A", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 3 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode3.dut.xfer_complete, '0', "Mode 3 XferComplete low in idle");
        assert_equal(spi_mode3.dut.sck, '0', "Mode 3 Sck idle level");

        set_test_name(test_name_display, "Mode 3 send");
        send_receive_transfer(clk, spi_mode3.tb, spi_mode3.dut, data_to_mosi_a_mode3, data_to_mosi_b_mode3, data_to_mosi_c_mode3, data_to_mosi_d_mode3, data_from_miso_a_mode3, data_from_miso_b_mode3, data_from_miso_c_mode3, data_from_miso_d_mode3, '1', '1', x"AB", x"CD", x"96", x"5A", x"00", x"00", x"00", x"00");

        set_test_name(test_name_display, "Mode 3 receive");
        send_receive_transfer(clk, spi_mode3.tb, spi_mode3.dut, data_to_mosi_a_mode3, data_to_mosi_b_mode3, data_to_mosi_c_mode3, data_to_mosi_d_mode3, data_from_miso_a_mode3, data_from_miso_b_mode3, data_from_miso_c_mode3, data_from_miso_d_mode3, '1', '1', x"00", x"00", x"00", x"00", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Mode 3 send and receive");
        send_receive_transfer(clk, spi_mode3.tb, spi_mode3.dut, data_to_mosi_a_mode3, data_to_mosi_b_mode3, data_to_mosi_c_mode3, data_to_mosi_d_mode3, data_from_miso_a_mode3, data_from_miso_b_mode3, data_from_miso_c_mode3, data_from_miso_d_mode3, '1', '1', x"AB", x"CD", x"96", x"5A", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Byte width 4 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_bw4.dut.xfer_complete, '0', "Byte width 4 XferComplete low in idle");
        assert_equal(spi_bw4.dut.sck, '1', "Byte width 4 Sck idle level");

        set_test_name(test_name_display, "Byte width 4 send");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"ABCD1234", x"13579BDF", x"2468ACE0", x"55AA33CC", x"00000000", x"00000000", x"00000000", x"00000000");

        set_test_name(test_name_display, "Byte width 4 receive");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"00000000", x"00000000", x"00000000", x"00000000", x"55555555", x"AAAAAAAA", x"3333CCCC", x"0F0FF0F0");

        set_test_name(test_name_display, "Byte width 4 send and receive");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"ABCD1234", x"13579BDF", x"2468ACE0", x"55AA33CC", x"55555555", x"AAAAAAAA", x"3333CCCC", x"0F0FF0F0");

        set_test_name(test_name_display, "Byte width 4 no back-to-back send without reset");
        spi_bw4.tb.rst <= '1';
        data_to_mosi_a_4 <= x"11112222";
        data_to_mosi_b_4 <= x"33334444";
        data_to_mosi_c_4 <= x"55556666";
        data_to_mosi_d_4 <= x"77778888";
        wait until falling_edge(clk);
        spi_bw4.tb.rst <= '0';
        wait until falling_edge(clk);
        wait_until_value(clk, spi_bw4.dut.xfer_complete, '1', XFER_COMPLETE_TIMEOUT_CYCLES, "Byte width 4 no-back-to-back test timed out waiting for XferComplete");
        data_to_mosi_a_4 <= x"9999AAAA";
        data_to_mosi_b_4 <= x"BBBBCCCC";
        data_to_mosi_c_4 <= x"DDDDEEEE";
        data_to_mosi_d_4 <= x"FFFF0000";
        cycle_clock(clk, DEFAULT_BIT_CYCLES * 2);
        assert_equal(spi_bw4.dut.xfer_complete, '1', "Byte width 4 stays complete without reset");

        set_test_name(test_name_display, "Byte width 4 data change without reset does not restart");
        data_to_mosi_a_4 <= x"DEADBEEF";
        data_to_mosi_b_4 <= x"CAFEBABE";
        data_to_mosi_c_4 <= x"FACEFEED";
        data_to_mosi_d_4 <= x"1234ABCD";
        cycle_clock(clk, DEFAULT_BIT_CYCLES * 2);
        assert_equal(spi_bw4.dut.xfer_complete, '1', "Byte width 4 ignores new data without reset");

        set_test_name(test_name_display, "Byte width 4 reset required for next send");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"DEADBEEF", x"CAFEBABE", x"FACEFEED", x"1234ABCD", x"00000000", x"00000000", x"00000000", x"00000000");

        set_test_name(test_name_display, "Byte width 4 rapid back-to-back sends");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"00000000", x"FFFFFFFF", x"5555AAAA", x"A5A55A5A", x"00000000", x"00000000", x"00000000", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"FFFFFFFF", x"00000000", x"AAAA5555", x"5A5AA5A5", x"00000000", x"00000000", x"00000000", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"12345678", x"87654321", x"0F0FF0F0", x"F0F00F0F", x"00000000", x"00000000", x"00000000", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"87654321", x"12345678", x"F0F00F0F", x"0F0FF0F0", x"00000000", x"00000000", x"00000000", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"A5A55A5A", x"5A5AA5A5", x"3C3CC3C3", x"C3C33C3C", x"00000000", x"00000000", x"00000000", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_a_4, data_to_mosi_b_4, data_to_mosi_c_4, data_to_mosi_d_4, data_from_miso_a_4, data_from_miso_b_4, data_from_miso_c_4, data_from_miso_d_4, '0', '0', x"0F0FF0F0", x"F0F00F0F", x"C3C33C3C", x"33CC55AA", x"00000000", x"00000000", x"00000000", x"00000000");

        set_test_name(test_name_display, "Byte width 16 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_bw16.dut.xfer_complete, '0', "Byte width 16 XferComplete low in idle");
        assert_equal(spi_bw16.dut.sck, '1', "Byte width 16 Sck idle level");

        set_test_name(test_name_display, "Byte width 16 send");
        send_receive_transfer(clk, spi_bw16.tb, spi_bw16.dut, data_to_mosi_a_16, data_to_mosi_b_16, data_to_mosi_c_16, data_to_mosi_d_16, data_from_miso_a_16, data_from_miso_b_16, data_from_miso_c_16, data_from_miso_d_16, '0', '0', x"ABCD12345555AAAAFFFF000000001111", x"13579BDF2468ACE0FEDCBA9876543210", x"0123456789ABCDEFFEDCBA9876543210", x"89ABCDEF01234567FEDCBA9876543210", x"00000000000000000000000000000000", x"00000000000000000000000000000000", x"00000000000000000000000000000000", x"00000000000000000000000000000000");

        set_test_name(test_name_display, "Byte width 16 receive");
        send_receive_transfer(clk, spi_bw16.tb, spi_bw16.dut, data_to_mosi_a_16, data_to_mosi_b_16, data_to_mosi_c_16, data_to_mosi_d_16, data_from_miso_a_16, data_from_miso_b_16, data_from_miso_c_16, data_from_miso_d_16, '0', '0', x"00000000000000000000000000000000", x"00000000000000000000000000000000", x"00000000000000000000000000000000", x"00000000000000000000000000000000", x"5555555555555555AAAAAAAAFFFFFFFF", x"AAAAAAAA55555555FFFFFFFF00000000", x"0F0F0F0FF0F0F0F03333CCCCAAAA5555", x"1234567890ABCDEF55AA33CC0F0FF0F0");

        set_test_name(test_name_display, "Byte width 16 send and receive");
        send_receive_transfer(clk, spi_bw16.tb, spi_bw16.dut, data_to_mosi_a_16, data_to_mosi_b_16, data_to_mosi_c_16, data_to_mosi_d_16, data_from_miso_a_16, data_from_miso_b_16, data_from_miso_c_16, data_from_miso_d_16, '0', '0', x"ABCD12345555AAAAFFFF000000001111", x"13579BDF2468ACE0FEDCBA9876543210", x"0123456789ABCDEFFEDCBA9876543210", x"89ABCDEF01234567FEDCBA9876543210", x"5555555555555555AAAAAAAAFFFFFFFF", x"AAAAAAAA55555555FFFFFFFF00000000", x"0F0F0F0FF0F0F0F03333CCCCAAAA5555", x"1234567890ABCDEF55AA33CC0F0FF0F0");

        set_test_name(test_name_display, "Clock divider 2 send");
        send_receive_transfer(clk, spi_bwclk2.tb, spi_bwclk2.dut, data_to_mosi_a_clk2, data_to_mosi_b_clk2, data_to_mosi_c_clk2, data_to_mosi_d_clk2, data_from_miso_a_clk2, data_from_miso_b_clk2, data_from_miso_c_clk2, data_from_miso_d_clk2, '0', '0', x"AB", x"CD", x"96", x"5A", x"00", x"00", x"00", x"00");

        set_test_name(test_name_display, "Clock divider 2 receive");
        send_receive_transfer(clk, spi_bwclk2.tb, spi_bwclk2.dut, data_to_mosi_a_clk2, data_to_mosi_b_clk2, data_to_mosi_c_clk2, data_to_mosi_d_clk2, data_from_miso_a_clk2, data_from_miso_b_clk2, data_from_miso_c_clk2, data_from_miso_d_clk2, '0', '0', x"00", x"00", x"00", x"00", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Clock divider 10 send");
        send_receive_transfer(clk, spi_bwclk10.tb, spi_bwclk10.dut, data_to_mosi_a_clk10, data_to_mosi_b_clk10, data_to_mosi_c_clk10, data_to_mosi_d_clk10, data_from_miso_a_clk10, data_from_miso_b_clk10, data_from_miso_c_clk10, data_from_miso_d_clk10, '0', '0', x"AB", x"CD", x"96", x"5A", x"00", x"00", x"00", x"00");

        set_test_name(test_name_display, "Clock divider 10 receive");
        send_receive_transfer(clk, spi_bwclk10.tb, spi_bwclk10.dut, data_to_mosi_a_clk10, data_to_mosi_b_clk10, data_to_mosi_c_clk10, data_to_mosi_d_clk10, data_from_miso_a_clk10, data_from_miso_b_clk10, data_from_miso_c_clk10, data_from_miso_d_clk10, '0', '0', x"00", x"00", x"00", x"00", x"55", x"AA", x"3C", x"C3");

        set_test_name(test_name_display, "Clock divider 10 send and receive");
        send_receive_transfer(clk, spi_bwclk10.tb, spi_bwclk10.dut, data_to_mosi_a_clk10, data_to_mosi_b_clk10, data_to_mosi_c_clk10, data_to_mosi_d_clk10, data_from_miso_a_clk10, data_from_miso_b_clk10, data_from_miso_c_clk10, data_from_miso_d_clk10, '0', '0', x"55", x"AA", x"3C", x"C3", x"AA", x"55", x"C3", x"3C");

        set_test_name(test_name_display, "Clock divider timing");
        spi_mode0.tb.rst <= '1';
        data_to_mosi_a_1 <= x"AA";
        data_to_mosi_b_1 <= x"55";
        data_to_mosi_c_1 <= x"3C";
        data_to_mosi_d_1 <= x"C3";
        wait until falling_edge(clk);
        spi_mode0.tb.rst <= '0';
        cycle_clock(clk, (DEFAULT_BIT_CYCLES / 2) - 1);
        assert_equal(spi_mode0.dut.sck, '1', "Clock divider 1000 holds idle before first edge");
        cycle_clock(clk, 1);
        assert_equal(spi_mode0.dut.sck, '0', "Clock divider 1000 toggles at half period");
        spi_mode0.tb.rst <= '1';
        wait until falling_edge(clk);

        spi_bwclk10.tb.rst <= '1';
        data_to_mosi_a_clk10 <= x"AA";
        data_to_mosi_b_clk10 <= x"55";
        data_to_mosi_c_clk10 <= x"3C";
        data_to_mosi_d_clk10 <= x"C3";
        wait until falling_edge(clk);
        spi_bwclk10.tb.rst <= '0';
        cycle_clock(clk, 4);
        assert_equal(spi_bwclk10.dut.sck, '1', "Clock divider 10 holds idle before first edge");
        cycle_clock(clk, 1);
        assert_equal(spi_bwclk10.dut.sck, '0', "Clock divider 10 toggles at half period");
        spi_bwclk10.tb.rst <= '1';
        wait until falling_edge(clk);

        spi_bwclk2.tb.rst <= '1';
        data_to_mosi_a_clk2 <= x"AA";
        data_to_mosi_b_clk2 <= x"55";
        data_to_mosi_c_clk2 <= x"3C";
        data_to_mosi_d_clk2 <= x"C3";
        wait until falling_edge(clk);
        spi_bwclk2.tb.rst <= '0';
        assert_equal(spi_bwclk2.dut.sck, '1', "Clock divider 2 starts idle");
        cycle_clock(clk, 1);
        assert_equal(spi_bwclk2.dut.sck, '0', "Clock divider 2 toggles after one cycle");
        spi_bwclk2.tb.rst <= '1';
        wait until falling_edge(clk);

        set_test_name(test_name_display, "Clock divider 2 all byte values");
        for value in 0 to 255 loop
            value_vec := std_logic_vector(to_unsigned(value, 8));
            inv_value_vec := not value_vec;
            xor_value_vec := value_vec xor x"5A";
            xnor_value_vec := value_vec xnor x"A5";
            send_receive_transfer(clk, spi_bwclk2.tb, spi_bwclk2.dut, data_to_mosi_a_clk2, data_to_mosi_b_clk2, data_to_mosi_c_clk2, data_to_mosi_d_clk2, data_from_miso_a_clk2, data_from_miso_b_clk2, data_from_miso_c_clk2, data_from_miso_d_clk2, '0', '0', value_vec, inv_value_vec, xor_value_vec, xnor_value_vec, value_vec, inv_value_vec, xor_value_vec, xnor_value_vec);
        end loop;
        spi_bwclk2.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_bwclk2.dut.xfer_complete, '0', "Clock divider 2 XferComplete low after final reset");
        assert_equal(spi_bwclk2.dut.sck, '1', "Clock divider 2 Sck returns to idle after final reset");
        assert_equal(spi_bwclk2.dut.mosi_a, value_vec(7), "Clock divider 2 MOSI A shows last byte MSB after final reset");
        assert_equal(spi_bwclk2.dut.mosi_b, inv_value_vec(7), "Clock divider 2 MOSI B shows last byte MSB after final reset");
        assert_equal(spi_bwclk2.dut.mosi_c, xor_value_vec(7), "Clock divider 2 MOSI C shows last byte MSB after final reset");
        assert_equal(spi_bwclk2.dut.mosi_d, xnor_value_vec(7), "Clock divider 2 MOSI D shows last byte MSB after final reset");

        set_test_name(test_name_display, "BYTE_WIDTH = 2 with CLOCK_DIVIDER = 10");
        send_receive_transfer(clk, spi_bw2_clk10.tb, spi_bw2_clk10.dut, data_to_mosi_a_2_10, data_to_mosi_b_2_10, data_to_mosi_c_2_10, data_to_mosi_d_2_10, data_from_miso_a_2_10, data_from_miso_b_2_10, data_from_miso_c_2_10, data_from_miso_d_2_10, '0', '0', x"ABCD", x"1357", x"2468", x"369C", x"1234", x"2468", x"369C", x"48C0");
        spi_bw2_clk10.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_bw2_clk10.dut.xfer_complete, '0', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 XferComplete low after reset");
        assert_equal(spi_bw2_clk10.dut.sck, '1', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 Sck returns to idle after reset");

        set_test_name(test_name_display, "Burst transfer with BYTE_WIDTH = 2 and CLOCK_DIVIDER = 10");
        for value in 0 to 255 loop
            value_vec := std_logic_vector(to_unsigned(value, 8));
            inv_value_vec := not value_vec;
            xor_value_vec := value_vec xor x"5A";
            xnor_value_vec := value_vec xnor x"A5";
            send_receive_transfer(clk, spi_bw2_clk10.tb, spi_bw2_clk10.dut, data_to_mosi_a_2_10, data_to_mosi_b_2_10, data_to_mosi_c_2_10, data_to_mosi_d_2_10, data_from_miso_a_2_10, data_from_miso_b_2_10, data_from_miso_c_2_10, data_from_miso_d_2_10, '0', '0', value_vec & value_vec, inv_value_vec & inv_value_vec, xor_value_vec & xor_value_vec, xnor_value_vec & xnor_value_vec, value_vec & value_vec, inv_value_vec & inv_value_vec, xor_value_vec & xor_value_vec, xnor_value_vec & xnor_value_vec);
        end loop;
        spi_bw2_clk10.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_bw2_clk10.dut.xfer_complete, '0', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 XferComplete low after final reset");
        assert_equal(spi_bw2_clk10.dut.sck, '1', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 Sck returns to idle after final reset");

        finish;
    end process;

    dut_mode0 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_mode0.tb.rst,
        MosiA => spi_mode0.dut.mosi_a,
        MosiB => spi_mode0.dut.mosi_b,
        MosiC => spi_mode0.dut.mosi_c,
        MosiD => spi_mode0.dut.mosi_d,
        Sck => spi_mode0.dut.sck,
        MisoA => spi_mode0.tb.miso_a,
        MisoB => spi_mode0.tb.miso_b,
        MisoC => spi_mode0.tb.miso_c,
        MisoD => spi_mode0.tb.miso_d,
        DataToMosiA => data_to_mosi_a_1,
        DataToMosiB => data_to_mosi_b_1,
        DataToMosiC => data_to_mosi_c_1,
        DataToMosiD => data_to_mosi_d_1,
        DataFromMisoA => data_from_miso_a_1,
        DataFromMisoB => data_from_miso_b_1,
        DataFromMisoC => data_from_miso_c_1,
        DataFromMisoD => data_from_miso_d_1,
        XferComplete => spi_mode0.dut.xfer_complete
    );

    dut_mode2 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '1',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_mode2.tb.rst,
        MosiA => spi_mode2.dut.mosi_a,
        MosiB => spi_mode2.dut.mosi_b,
        MosiC => spi_mode2.dut.mosi_c,
        MosiD => spi_mode2.dut.mosi_d,
        Sck => spi_mode2.dut.sck,
        MisoA => spi_mode2.tb.miso_a,
        MisoB => spi_mode2.tb.miso_b,
        MisoC => spi_mode2.tb.miso_c,
        MisoD => spi_mode2.tb.miso_d,
        DataToMosiA => data_to_mosi_a_mode2,
        DataToMosiB => data_to_mosi_b_mode2,
        DataToMosiC => data_to_mosi_c_mode2,
        DataToMosiD => data_to_mosi_d_mode2,
        DataFromMisoA => data_from_miso_a_mode2,
        DataFromMisoB => data_from_miso_b_mode2,
        DataFromMisoC => data_from_miso_c_mode2,
        DataFromMisoD => data_from_miso_d_mode2,
        XferComplete => spi_mode2.dut.xfer_complete
    );

    dut_mode1 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '1'
    )
    port map (
        clk => clk,
        rst => spi_mode1.tb.rst,
        MosiA => spi_mode1.dut.mosi_a,
        MosiB => spi_mode1.dut.mosi_b,
        MosiC => spi_mode1.dut.mosi_c,
        MosiD => spi_mode1.dut.mosi_d,
        Sck => spi_mode1.dut.sck,
        MisoA => spi_mode1.tb.miso_a,
        MisoB => spi_mode1.tb.miso_b,
        MisoC => spi_mode1.tb.miso_c,
        MisoD => spi_mode1.tb.miso_d,
        DataToMosiA => data_to_mosi_a_mode1,
        DataToMosiB => data_to_mosi_b_mode1,
        DataToMosiC => data_to_mosi_c_mode1,
        DataToMosiD => data_to_mosi_d_mode1,
        DataFromMisoA => data_from_miso_a_mode1,
        DataFromMisoB => data_from_miso_b_mode1,
        DataFromMisoC => data_from_miso_c_mode1,
        DataFromMisoD => data_from_miso_d_mode1,
        XferComplete => spi_mode1.dut.xfer_complete
    );

    dut_mode3 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '1',
        CPHA => '1'
    )
    port map (
        clk => clk,
        rst => spi_mode3.tb.rst,
        MosiA => spi_mode3.dut.mosi_a,
        MosiB => spi_mode3.dut.mosi_b,
        MosiC => spi_mode3.dut.mosi_c,
        MosiD => spi_mode3.dut.mosi_d,
        Sck => spi_mode3.dut.sck,
        MisoA => spi_mode3.tb.miso_a,
        MisoB => spi_mode3.tb.miso_b,
        MisoC => spi_mode3.tb.miso_c,
        MisoD => spi_mode3.tb.miso_d,
        DataToMosiA => data_to_mosi_a_mode3,
        DataToMosiB => data_to_mosi_b_mode3,
        DataToMosiC => data_to_mosi_c_mode3,
        DataToMosiD => data_to_mosi_d_mode3,
        DataFromMisoA => data_from_miso_a_mode3,
        DataFromMisoB => data_from_miso_b_mode3,
        DataFromMisoC => data_from_miso_c_mode3,
        DataFromMisoD => data_from_miso_d_mode3,
        XferComplete => spi_mode3.dut.xfer_complete
    );

    dut_bw4 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 4,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw4.tb.rst,
        MosiA => spi_bw4.dut.mosi_a,
        MosiB => spi_bw4.dut.mosi_b,
        MosiC => spi_bw4.dut.mosi_c,
        MosiD => spi_bw4.dut.mosi_d,
        Sck => spi_bw4.dut.sck,
        MisoA => spi_bw4.tb.miso_a,
        MisoB => spi_bw4.tb.miso_b,
        MisoC => spi_bw4.tb.miso_c,
        MisoD => spi_bw4.tb.miso_d,
        DataToMosiA => data_to_mosi_a_4,
        DataToMosiB => data_to_mosi_b_4,
        DataToMosiC => data_to_mosi_c_4,
        DataToMosiD => data_to_mosi_d_4,
        DataFromMisoA => data_from_miso_a_4,
        DataFromMisoB => data_from_miso_b_4,
        DataFromMisoC => data_from_miso_c_4,
        DataFromMisoD => data_from_miso_d_4,
        XferComplete => spi_bw4.dut.xfer_complete
    );

    dut_bw16 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 16,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw16.tb.rst,
        MosiA => spi_bw16.dut.mosi_a,
        MosiB => spi_bw16.dut.mosi_b,
        MosiC => spi_bw16.dut.mosi_c,
        MosiD => spi_bw16.dut.mosi_d,
        Sck => spi_bw16.dut.sck,
        MisoA => spi_bw16.tb.miso_a,
        MisoB => spi_bw16.tb.miso_b,
        MisoC => spi_bw16.tb.miso_c,
        MisoD => spi_bw16.tb.miso_d,
        DataToMosiA => data_to_mosi_a_16,
        DataToMosiB => data_to_mosi_b_16,
        DataToMosiC => data_to_mosi_c_16,
        DataToMosiD => data_to_mosi_d_16,
        DataFromMisoA => data_from_miso_a_16,
        DataFromMisoB => data_from_miso_b_16,
        DataFromMisoC => data_from_miso_c_16,
        DataFromMisoD => data_from_miso_d_16,
        XferComplete => spi_bw16.dut.xfer_complete
    );

    dut_bwclk2 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 2,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bwclk2.tb.rst,
        MosiA => spi_bwclk2.dut.mosi_a,
        MosiB => spi_bwclk2.dut.mosi_b,
        MosiC => spi_bwclk2.dut.mosi_c,
        MosiD => spi_bwclk2.dut.mosi_d,
        Sck => spi_bwclk2.dut.sck,
        MisoA => spi_bwclk2.tb.miso_a,
        MisoB => spi_bwclk2.tb.miso_b,
        MisoC => spi_bwclk2.tb.miso_c,
        MisoD => spi_bwclk2.tb.miso_d,
        DataToMosiA => data_to_mosi_a_clk2,
        DataToMosiB => data_to_mosi_b_clk2,
        DataToMosiC => data_to_mosi_c_clk2,
        DataToMosiD => data_to_mosi_d_clk2,
        DataFromMisoA => data_from_miso_a_clk2,
        DataFromMisoB => data_from_miso_b_clk2,
        DataFromMisoC => data_from_miso_c_clk2,
        DataFromMisoD => data_from_miso_d_clk2,
        XferComplete => spi_bwclk2.dut.xfer_complete
    );

    dut_bwclk10 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bwclk10.tb.rst,
        MosiA => spi_bwclk10.dut.mosi_a,
        MosiB => spi_bwclk10.dut.mosi_b,
        MosiC => spi_bwclk10.dut.mosi_c,
        MosiD => spi_bwclk10.dut.mosi_d,
        Sck => spi_bwclk10.dut.sck,
        MisoA => spi_bwclk10.tb.miso_a,
        MisoB => spi_bwclk10.tb.miso_b,
        MisoC => spi_bwclk10.tb.miso_c,
        MisoD => spi_bwclk10.tb.miso_d,
        DataToMosiA => data_to_mosi_a_clk10,
        DataToMosiB => data_to_mosi_b_clk10,
        DataToMosiC => data_to_mosi_c_clk10,
        DataToMosiD => data_to_mosi_d_clk10,
        DataFromMisoA => data_from_miso_a_clk10,
        DataFromMisoB => data_from_miso_b_clk10,
        DataFromMisoC => data_from_miso_c_clk10,
        DataFromMisoD => data_from_miso_d_clk10,
        XferComplete => spi_bwclk10.dut.xfer_complete
    );

    dut_bw2_clk10 : entity work.SpiMasterQuadPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BYTE_WIDTH => 2,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw2_clk10.tb.rst,
        MosiA => spi_bw2_clk10.dut.mosi_a,
        MosiB => spi_bw2_clk10.dut.mosi_b,
        MosiC => spi_bw2_clk10.dut.mosi_c,
        MosiD => spi_bw2_clk10.dut.mosi_d,
        Sck => spi_bw2_clk10.dut.sck,
        MisoA => spi_bw2_clk10.tb.miso_a,
        MisoB => spi_bw2_clk10.tb.miso_b,
        MisoC => spi_bw2_clk10.tb.miso_c,
        MisoD => spi_bw2_clk10.tb.miso_d,
        DataToMosiA => data_to_mosi_a_2_10,
        DataToMosiB => data_to_mosi_b_2_10,
        DataToMosiC => data_to_mosi_c_2_10,
        DataToMosiD => data_to_mosi_d_2_10,
        DataFromMisoA => data_from_miso_a_2_10,
        DataFromMisoB => data_from_miso_b_2_10,
        DataFromMisoC => data_from_miso_c_2_10,
        DataFromMisoD => data_from_miso_d_2_10,
        XferComplete => spi_bw2_clk10.dut.xfer_complete
    );

end architecture sim;
