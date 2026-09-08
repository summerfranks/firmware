--! \brief Testbench for SpiMaster.vhd
--! MOSI/MISO transfers, latch behavior, reset gating, and multi-byte widths
--! Important note: CPOL and CPHA are inverted from standard use - CPHA=0 means sampling is done on second edge, CPHA=1 means sampling is done on the first edge

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity SpiMaster_tb is
end SpiMaster_tb;

architecture sim of SpiMaster_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant DEFAULT_BIT_CYCLES : natural := 1000;
    constant XFER_COMPLETE_TIMEOUT_CYCLES : natural := 200000;

    type spi_tb_out_t is record
        rst           : std_logic;
        miso          : std_logic;
    end record;

    type spi_dut_out_t is record
        mosi          : std_logic;
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

    signal data_to_mosi_1, data_from_miso_1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_mode1, data_from_miso_mode1 : std_logic_vector(7 downto 0);
    signal data_to_mosi_mode2, data_from_miso_mode2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_mode3, data_from_miso_mode3 : std_logic_vector(7 downto 0);
    signal data_to_mosi_4, data_from_miso_4 : std_logic_vector(31 downto 0);
    signal data_to_mosi_16, data_from_miso_16 : std_logic_vector(127 downto 0);
    signal data_to_mosi_clk2, data_from_miso_clk2 : std_logic_vector(7 downto 0);
    signal data_to_mosi_clk10, data_from_miso_clk10 : std_logic_vector(7 downto 0);
    signal data_to_mosi_2_10, data_from_miso_2_10 : std_logic_vector(15 downto 0);

    -- This is a fake SPI Slave implementation 
    procedure send_receive_transfer(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal data_to_mosi : out std_logic_vector;
        signal data_from_miso : in std_logic_vector;
        constant cpol : in std_logic;
        constant cpha : in std_logic;
        constant tx_data : std_logic_vector;
        constant rx_data : std_logic_vector
    ) is
        variable tx_vec : std_logic_vector(data_to_mosi'range);
        variable rx_vec : std_logic_vector(data_to_mosi'range);
    begin
        tx_vec := tx_data;
        rx_vec := rx_data;
        spi_tb.rst <= '1';


        wait until falling_edge(clk_in);
        data_to_mosi <= tx_vec;
        spi_tb.miso <= rx_vec(rx_vec'high);

        assert_equal(spi_dut.xfer_complete, '0', "XferComplete low while idle");
        assert_equal(spi_dut.sck, not(cpol), "Sck idle level");

        spi_tb.rst <= '0';
        -- assert_equal(spi_dut.mosi, tx_vec(tx_vec'high), "MOSI MSB preloaded before full-duplex transfer");

        for bit_num in tx_vec'high downto tx_vec'low loop
            if cpha = '1' then -- sample then shift
                wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha))); -- sample
                assert_equal(spi_dut.sck, not(cpol xor cpha), "Sck at full-duplex sample point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi, tx_vec(bit_num), "Slave sampled MOSI bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec));
                assert_equal(data_from_miso(bit_num), rx_vec(bit_num), "Master captured MISO bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex sample of bit " & integer'image(bit_num));

                if bit_num > tx_vec'low then -- if sample then shift, last shift doesn't do anything 
                    wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha))); -- shift
                    spi_tb.miso <= rx_vec(bit_num - 1);
                    assert_equal(spi_dut.sck, cpol xor cpha, "Sck at full-duplex shift point for bit " & integer'image(bit_num - 1));
                    assert_equal(spi_dut.mosi, tx_vec(bit_num - 1), "Master shifted MOSI bit " & integer'image(bit_num - 1) & " during full-duplex transfer");
                    assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex shift of bit " & integer'image(bit_num - 1));
                end if;
            else -- shift then sample
                wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha))); -- shift
                assert_equal(spi_dut.sck, cpol xor cpha, "Sck at full-duplex shift point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi, tx_vec(bit_num), "Master shifted MOSI bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex shift of bit " & integer'image(bit_num));

                if bit_num /= tx_vec'high then
                    spi_tb.miso <= rx_vec(bit_num);
                end if;

                wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha))); -- sample
                assert_equal(spi_dut.sck, not(cpol xor cpha), "Sck at full-duplex sample point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi, tx_vec(bit_num), "Slave sampled MOSI bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec));
                assert_equal(data_from_miso(bit_num), rx_vec(bit_num), "Master captured MISO bit " & integer'image(bit_num) & " during full-duplex transfer");
                assert_equal(spi_dut.xfer_complete, '0', "XferComplete low during full-duplex sample of bit " & integer'image(bit_num));
            end if;
        end loop;

        wait_until_value(clk_in, spi_dut.xfer_complete, '1', XFER_COMPLETE_TIMEOUT_CYCLES, "Timed out waiting for XferComplete after full-duplex transfer");
        assert_equal(data_from_miso, rx_vec, "DataFromMiso after RX 0x" & to_hstring(rx_vec));
        assert_equal(spi_dut.xfer_complete, '1', "XferComplete after full-duplex xfer");

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.xfer_complete, '1', "XferComplete high after transfer completes and before reset");
        assert_equal(data_from_miso, rx_vec, "DataFromMiso stable after transfer completes and before reset");
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

        spi_mode0.tb.miso <= '0';
        spi_mode1.tb.miso <= '0';
        spi_mode2.tb.miso <= '0';
        spi_mode3.tb.miso <= '0';
        spi_bw4.tb.miso <= '0';
        spi_bw16.tb.miso <= '0';
        spi_bwclk2.tb.miso <= '0';
        spi_bwclk10.tb.miso <= '0';
        spi_bw2_clk10.tb.miso <= '0';

        -- CPOL=0, CPHA=0 but this behaves like CPOL=1, CPHA=1 for standard
        -- SCK begins high, and samples on rising edge
        set_test_name(test_name_display, "Mode 0 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.xfer_complete, '0', "Mode 0 XferComplete low in idle");
        assert_equal(spi_mode0.dut.sck, '1', "Mode 0 Sck idle level");

        set_test_name(test_name_display, "Mode 0 send");
        send_receive_transfer(clk, spi_mode0.tb, spi_mode0.dut, data_to_mosi_1, data_from_miso_1, '0', '0', x"AB", x"00");

        set_test_name(test_name_display, "Mode 0 receive");
        send_receive_transfer(clk, spi_mode0.tb, spi_mode0.dut, data_to_mosi_1, data_from_miso_1, '0', '0', x"00", x"55");

        set_test_name(test_name_display, "Mode 0 send and receive");
        send_receive_transfer(clk, spi_mode0.tb, spi_mode0.dut, data_to_mosi_1, data_from_miso_1, '0', '0', x"AB", x"55");

        set_test_name(test_name_display, "Mode 0 active MOSI follows pre-latch input");
        spi_mode0.tb.rst <= '1';
        data_to_mosi_1 <= x"80";
        wait until falling_edge(clk);
        spi_mode0.tb.rst <= '0';
        data_to_mosi_1 <= x"40";
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.mosi, '0', "MOSI picks up updated MSB before the first SPI clock edge");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi, '0', "First shifted bit uses updated pre-latch input");
        spi_mode0.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.xfer_complete, '0', "Active MOSI test XferComplete low after reset");

        set_test_name(test_name_display, "Mode 0 send data latch mid-transfer");
        spi_mode0.tb.rst <= '1';
        data_to_mosi_1 <= x"AB";
        wait until falling_edge(clk);
        spi_mode0.tb.rst <= '0';
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '1'));
        assert_equal(spi_mode0.dut.mosi, '1', "Slave sampled original MOSI bit 7 before data change");
        data_to_mosi_1 <= x"54";
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi, '0', "Master keeps latched MOSI bit 6 after data change");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '1'));
        assert_equal(spi_mode0.dut.mosi, '0', "Slave samples original MOSI bit 6 after data change");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi, '1', "Master keeps latched MOSI bit 5 after data change");
        wait until (spi_mode0.dut.sck'event and (spi_mode0.dut.sck = '0'));
        assert_equal(spi_mode0.dut.mosi, '0', "Master keeps original latched MOSI bit 4 late in transfer");
        wait_until_value(clk, spi_mode0.dut.xfer_complete, '1', XFER_COMPLETE_TIMEOUT_CYCLES, "Mode 0 latch test timed out waiting for XferComplete");
        assert_equal(spi_mode0.dut.xfer_complete, '1', "Mode 0 latch test completes original transfer");
        spi_mode0.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_mode0.dut.xfer_complete, '0', "Mode 0 latch test XferComplete low after reset");
        assert_equal(spi_mode0.dut.sck, '1', "Mode 0 latch test Sck idle after reset");
        assert_equal(spi_mode0.dut.mosi, '0', "Mode 0 latch test MOSI follows new MSB after reset");

        -- CPOL=1, CPHA=0 but this behaves like CPOL=0, CPHA=1 for standard
        -- SCK begins low, and samples on falling edge
        set_test_name(test_name_display, "Mode 2 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode2.dut.xfer_complete, '0', "Mode 2 XferComplete low in idle");
        assert_equal(spi_mode2.dut.sck, '0', "Mode 2 Sck idle level");

        set_test_name(test_name_display, "Mode 2 send");
        send_receive_transfer(clk, spi_mode2.tb, spi_mode2.dut, data_to_mosi_mode2, data_from_miso_mode2, '1', '0', x"AB", x"00");

        set_test_name(test_name_display, "Mode 2 receive");
        send_receive_transfer(clk, spi_mode2.tb, spi_mode2.dut, data_to_mosi_mode2, data_from_miso_mode2, '1', '0', x"00", x"55");

        set_test_name(test_name_display, "Mode 2 send and receive");
        send_receive_transfer(clk, spi_mode2.tb, spi_mode2.dut, data_to_mosi_mode2, data_from_miso_mode2, '1', '0', x"AB", x"55");


        -- CPOL=0, CPHA=1 but this behaves like CPOL=1, CPHA=0 for standard
        -- SCK begins high, and samples on falling edge
        set_test_name(test_name_display, "Mode 1 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode1.dut.xfer_complete, '0', "Mode 1 XferComplete low in idle");
        assert_equal(spi_mode1.dut.sck, '1', "Mode 1 Sck idle level");

        set_test_name(test_name_display, "Mode 1 send");
        send_receive_transfer(clk, spi_mode1.tb, spi_mode1.dut, data_to_mosi_mode1, data_from_miso_mode1, '0', '1', x"AB", x"00");

        set_test_name(test_name_display, "Mode 1 receive");
        send_receive_transfer(clk, spi_mode1.tb, spi_mode1.dut, data_to_mosi_mode1, data_from_miso_mode1, '0', '1', x"00", x"55");

        set_test_name(test_name_display, "Mode 1 send and receive");
        send_receive_transfer(clk, spi_mode1.tb, spi_mode1.dut, data_to_mosi_mode1, data_from_miso_mode1, '0', '1', x"AB", x"55");

        -- CPOL=1, CPHA=1 but this behaves like CPOL=0, CPHA=0 for standard
        -- SCK begins low, and samples on rising edge
        set_test_name(test_name_display, "Mode 3 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_mode3.dut.xfer_complete, '0', "Mode 3 XferComplete low in idle");
        assert_equal(spi_mode3.dut.sck, '0', "Mode 3 Sck idle level");

        set_test_name(test_name_display, "Mode 3 send");
        send_receive_transfer(clk, spi_mode3.tb, spi_mode3.dut, data_to_mosi_mode3, data_from_miso_mode3, '1', '1', x"AB", x"00");

        set_test_name(test_name_display, "Mode 3 receive");
        send_receive_transfer(clk, spi_mode3.tb, spi_mode3.dut, data_to_mosi_mode3, data_from_miso_mode3, '1', '1', x"00", x"55");

        set_test_name(test_name_display, "Mode 3 send and receive");
        send_receive_transfer(clk, spi_mode3.tb, spi_mode3.dut, data_to_mosi_mode3, data_from_miso_mode3, '1', '1', x"AB", x"55");

        -- Byte width = 4
        set_test_name(test_name_display, "Byte width 4 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_bw4.dut.xfer_complete, '0', "Byte width 4 XferComplete low in idle");
        assert_equal(spi_bw4.dut.sck, '1', "Byte width 4 Sck idle level"); 

        set_test_name(test_name_display, "Byte width 4 send");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"ABCD1234", x"00000000");

        set_test_name(test_name_display, "Byte width 4 receive");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"00000000", x"55555555");

        set_test_name(test_name_display, "Byte width 4 send and receive");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"ABCD1234", x"55555555");

        set_test_name(test_name_display, "Byte width 4 no back-to-back send without reset");
        spi_bw4.tb.rst <= '1';
        data_to_mosi_4 <= x"11112222";
        wait until falling_edge(clk);
        spi_bw4.tb.rst <= '0';
        wait until falling_edge(clk);
        wait_until_value(clk, spi_bw4.dut.xfer_complete, '1', XFER_COMPLETE_TIMEOUT_CYCLES, "Byte width 4 no-back-to-back test timed out waiting for XferComplete");
        data_to_mosi_4 <= x"33334444";
        cycle_clock(clk, DEFAULT_BIT_CYCLES * 2);
        assert_equal(spi_bw4.dut.xfer_complete, '1', "Byte width 4 stays complete without reset");

        set_test_name(test_name_display, "Byte width 4 data change without reset does not restart");
        data_to_mosi_4 <= x"DEADBEEF";
        cycle_clock(clk, DEFAULT_BIT_CYCLES * 2);
        assert_equal(spi_bw4.dut.xfer_complete, '1', "Byte width 4 ignores new data without reset");

        set_test_name(test_name_display, "Byte width 4 reset required for next send");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"DEADBEEF", x"00000000");

        set_test_name(test_name_display, "Byte width 4 rapid back-to-back sends");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"00000000", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"FFFFFFFF", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"12345678", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"87654321", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"A5A55A5A", x"00000000");
        send_receive_transfer(clk, spi_bw4.tb, spi_bw4.dut, data_to_mosi_4, data_from_miso_4, '0', '0', x"0F0FF0F0", x"00000000");

        -- Byte width = 16
        set_test_name(test_name_display, "Byte width 16 reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi_bw16.dut.xfer_complete, '0', "Byte width 16 XferComplete low in idle");
        assert_equal(spi_bw16.dut.sck, '1', "Byte width 16 Sck idle level");

        set_test_name(test_name_display, "Byte width 16 send");
        send_receive_transfer(clk, spi_bw16.tb, spi_bw16.dut, data_to_mosi_16, data_from_miso_16, '0', '0', x"ABCD12345555AAAAFFFF000000001111", x"00000000000000000000000000000000");

        set_test_name(test_name_display, "Byte width 16 receive");
        send_receive_transfer(clk, spi_bw16.tb, spi_bw16.dut, data_to_mosi_16, data_from_miso_16, '0', '0', x"00000000000000000000000000000000", x"5555555555555555AAAAAAAAFFFFFFFF");

        set_test_name(test_name_display, "Byte width 16 send and receive");
        send_receive_transfer(clk, spi_bw16.tb, spi_bw16.dut, data_to_mosi_16, data_from_miso_16, '0', '0', x"ABCD12345555AAAAFFFF000000001111", x"5555555555555555AAAAAAAAFFFFFFFF");

        -- CLOCK_DIVIDER=1 is currently unsupported by SpiMaster because ClkDiv becomes 0 to -1.
        set_test_name(test_name_display, "Clock divider 2 send");
        send_receive_transfer(clk, spi_bwclk2.tb, spi_bwclk2.dut, data_to_mosi_clk2, data_from_miso_clk2, '0', '0', x"AB", x"00");

        set_test_name(test_name_display, "Clock divider 2 receive");
        send_receive_transfer(clk, spi_bwclk2.tb, spi_bwclk2.dut, data_to_mosi_clk2, data_from_miso_clk2, '0', '0', x"00", x"55");

        set_test_name(test_name_display, "Clock divider 10 send");
        send_receive_transfer(clk, spi_bwclk10.tb, spi_bwclk10.dut, data_to_mosi_clk10, data_from_miso_clk10, '0', '0', x"AB", x"00");

        set_test_name(test_name_display, "Clock divider 10 receive");
        send_receive_transfer(clk, spi_bwclk10.tb, spi_bwclk10.dut, data_to_mosi_clk10, data_from_miso_clk10, '0', '0', x"00", x"55");
        
        set_test_name(test_name_display, "Clock divider 10 send and receive");
        send_receive_transfer(clk, spi_bwclk10.tb, spi_bwclk10.dut, data_to_mosi_clk10, data_from_miso_clk10, '0', '0', x"55", x"AA");

        set_test_name(test_name_display, "Clock divider timing");
        spi_mode0.tb.rst <= '1';
        data_to_mosi_1 <= x"AA";
        wait until falling_edge(clk);
        spi_mode0.tb.rst <= '0';
        cycle_clock(clk, (DEFAULT_BIT_CYCLES / 2) - 1);
        assert_equal(spi_mode0.dut.sck, '1', "Clock divider 1000 holds idle before first edge");
        cycle_clock(clk, 1);
        assert_equal(spi_mode0.dut.sck, '0', "Clock divider 1000 toggles at half period");
        spi_mode0.tb.rst <= '1';
        wait until falling_edge(clk);

        spi_bwclk10.tb.rst <= '1';
        data_to_mosi_clk10 <= x"AA";
        wait until falling_edge(clk);
        spi_bwclk10.tb.rst <= '0';
        cycle_clock(clk, 4);
        assert_equal(spi_bwclk10.dut.sck, '1', "Clock divider 10 holds idle before first edge");
        cycle_clock(clk, 1);
        assert_equal(spi_bwclk10.dut.sck, '0', "Clock divider 10 toggles at half period");
        spi_bwclk10.tb.rst <= '1';
        wait until falling_edge(clk);

        spi_bwclk2.tb.rst <= '1';
        data_to_mosi_clk2 <= x"AA";
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
            send_receive_transfer(clk, spi_bwclk2.tb, spi_bwclk2.dut, data_to_mosi_clk2, data_from_miso_clk2, '0', '0', value_vec, value_vec);
        end loop;
        spi_bwclk2.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_bwclk2.dut.xfer_complete, '0', "Clock divider 2 XferComplete low after final reset");
        assert_equal(spi_bwclk2.dut.sck, '1', "Clock divider 2 Sck returns to idle after final reset");
        assert_equal(spi_bwclk2.dut.mosi, value_vec(7), "Clock divider 2 MOSI shows last byte MSB after final reset");

        set_test_name(test_name_display, "BYTE_WIDTH = 2 with CLOCK_DIVIDER = 10");
        send_receive_transfer(clk, spi_bw2_clk10.tb, spi_bw2_clk10.dut, data_to_mosi_2_10, data_from_miso_2_10, '0', '0', x"ABCD", x"1234");
        spi_bw2_clk10.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_bw2_clk10.dut.xfer_complete, '0', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 XferComplete low after reset");
        assert_equal(spi_bw2_clk10.dut.sck, '1', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 Sck returns to idle after reset");

        set_test_name(test_name_display, "Burst transfer with BYTE_WIDTH = 2 and CLOCK_DIVIDER = 10");
        for value in 0 to 255 loop
            value_vec := std_logic_vector(to_unsigned(value, 8));
            send_receive_transfer(clk, spi_bw2_clk10.tb, spi_bw2_clk10.dut, data_to_mosi_2_10, data_from_miso_2_10, '0', '0', value_vec & value_vec, value_vec & value_vec);
        end loop;
        spi_bw2_clk10.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi_bw2_clk10.dut.xfer_complete, '0', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 XferComplete low after final reset");
        assert_equal(spi_bw2_clk10.dut.sck, '1', "BYTE_WIDTH=2 CLOCK_DIVIDER=10 Sck returns to idle after final reset");
        
        finish;
    end process;

    dut_mode0 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_mode0.tb.rst,
        Mosi => spi_mode0.dut.mosi,
        Sck => spi_mode0.dut.sck,
        Miso => spi_mode0.tb.miso,
        DataToMosi => data_to_mosi_1,
        DataFromMiso => data_from_miso_1,
        XferComplete => spi_mode0.dut.xfer_complete
    );

    dut_mode2 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '1',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_mode2.tb.rst,
        Mosi => spi_mode2.dut.mosi,
        Sck => spi_mode2.dut.sck,
        Miso => spi_mode2.tb.miso,
        DataToMosi => data_to_mosi_mode2,
        DataFromMiso => data_from_miso_mode2,
        XferComplete => spi_mode2.dut.xfer_complete
    );

    dut_mode1 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '1'
    )
    port map (
        clk => clk,
        rst => spi_mode1.tb.rst,
        Mosi => spi_mode1.dut.mosi,
        Sck => spi_mode1.dut.sck,
        Miso => spi_mode1.tb.miso,
        DataToMosi => data_to_mosi_mode1,
        DataFromMiso => data_from_miso_mode1,
        XferComplete => spi_mode1.dut.xfer_complete
    );

    dut_mode3 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 1,
        CPOL => '1',
        CPHA => '1'
    )
    port map (
        clk => clk,
        rst => spi_mode3.tb.rst,
        Mosi => spi_mode3.dut.mosi,
        Sck => spi_mode3.dut.sck,
        Miso => spi_mode3.tb.miso,
        DataToMosi => data_to_mosi_mode3,
        DataFromMiso => data_from_miso_mode3,
        XferComplete => spi_mode3.dut.xfer_complete
    );

    dut_bw4 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 4,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw4.tb.rst,
        Mosi => spi_bw4.dut.mosi,
        Sck => spi_bw4.dut.sck,
        Miso => spi_bw4.tb.miso,
        DataToMosi => data_to_mosi_4,
        DataFromMiso => data_from_miso_4,
        XferComplete => spi_bw4.dut.xfer_complete
    );

    dut_bw16 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 1000,
        BYTE_WIDTH => 16,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw16.tb.rst,
        Mosi => spi_bw16.dut.mosi,
        Sck => spi_bw16.dut.sck,
        Miso => spi_bw16.tb.miso,
        DataToMosi => data_to_mosi_16,
        DataFromMiso => data_from_miso_16,
        XferComplete => spi_bw16.dut.xfer_complete
    );

    -- NOTE: CLOCK_DIVIDER=1 is currently unsupported by SpiMaster because ClkDiv becomes 0 to -1, so use 2 and 10 for testing instead

    dut_bwclk2 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 2,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bwclk2.tb.rst,
        Mosi => spi_bwclk2.dut.mosi,
        Sck => spi_bwclk2.dut.sck,
        Miso => spi_bwclk2.tb.miso,
        DataToMosi => data_to_mosi_clk2,
        DataFromMiso => data_from_miso_clk2,
        XferComplete => spi_bwclk2.dut.xfer_complete
    );

    dut_bwclk10 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BYTE_WIDTH => 1,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bwclk10.tb.rst,
        Mosi => spi_bwclk10.dut.mosi,
        Sck => spi_bwclk10.dut.sck,
        Miso => spi_bwclk10.tb.miso,
        DataToMosi => data_to_mosi_clk10,
        DataFromMiso => data_from_miso_clk10,
        XferComplete => spi_bwclk10.dut.xfer_complete
    );

    dut_bw2_clk10 : entity work.SpiMasterPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BYTE_WIDTH => 2,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw2_clk10.tb.rst,
        Mosi => spi_bw2_clk10.dut.mosi,
        Sck => spi_bw2_clk10.dut.sck,
        Miso => spi_bw2_clk10.tb.miso,
        DataToMosi => data_to_mosi_2_10,
        DataFromMiso => data_from_miso_2_10,
        XferComplete => spi_bw2_clk10.dut.xfer_complete
    );

end architecture sim;
