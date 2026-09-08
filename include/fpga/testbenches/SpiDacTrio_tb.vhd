--! \brief Basic testbench for SpiDacTrio.vhd
--! Mirrors SpiDac_tb.vhd as closely as practical for the trio-lane variant.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity SpiDacTrio_tb is
end SpiDacTrio_tb;

architecture sim of SpiDacTrio_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant TRANSFER_COMPLETE_TIMEOUT_CYCLES : natural := 5000;

    type spi_tb_out_t is record
        rst       : std_logic;
        miso_a    : std_logic;
        miso_b    : std_logic;
        miso_c    : std_logic;
        write_dac : std_logic;
    end record;

    type spi_dut_out_t is record
        ncs_a             : std_logic;
        ncs_b             : std_logic;
        ncs_c             : std_logic;
        sck               : std_logic;
        mosi_a            : std_logic;
        mosi_b            : std_logic;
        mosi_c            : std_logic;
        transfer_complete : std_logic;
    end record;

    type spi_if_t is record
        tb  : spi_tb_out_t;
        dut : spi_dut_out_t;
    end record;

    signal clk : std_logic := '0';
    signal test_name_display : string(1 to 80);
    signal spi : spi_if_t;

    signal dac_write_out_a, dac_readback_a : std_logic_vector(23 downto 0) := (others => '0');
    signal dac_write_out_b, dac_readback_b : std_logic_vector(23 downto 0) := (others => '0');
    signal dac_write_out_c, dac_readback_c : std_logic_vector(23 downto 0) := (others => '0');

    procedure send_receive_transaction(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal dac_write_out_a_sig : out std_logic_vector;
        signal dac_write_out_b_sig : out std_logic_vector;
        signal dac_write_out_c_sig : out std_logic_vector;
        signal dac_readback_a_in : in std_logic_vector;
        signal dac_readback_b_in : in std_logic_vector;
        signal dac_readback_c_in : in std_logic_vector;
        constant tx_data_a : std_logic_vector;
        constant tx_data_b : std_logic_vector;
        constant tx_data_c : std_logic_vector;
        constant rx_data_a : std_logic_vector;
        constant rx_data_b : std_logic_vector;
        constant rx_data_c : std_logic_vector
    ) is
        variable tx_vec_a : std_logic_vector(dac_write_out_a_sig'range);
        variable tx_vec_b : std_logic_vector(dac_write_out_b_sig'range);
        variable tx_vec_c : std_logic_vector(dac_write_out_c_sig'range);
        variable rx_vec_a : std_logic_vector(dac_readback_a_in'range);
        variable rx_vec_b : std_logic_vector(dac_readback_b_in'range);
        variable rx_vec_c : std_logic_vector(dac_readback_c_in'range);
    begin
        tx_vec_a := tx_data_a;
        tx_vec_b := tx_data_b;
        tx_vec_c := tx_data_c;
        rx_vec_a := rx_data_a;
        rx_vec_b := rx_data_b;
        rx_vec_c := rx_data_c;

        spi_tb.write_dac <= '0';
        dac_write_out_a_sig <= tx_vec_a;
        dac_write_out_b_sig <= tx_vec_b;
        dac_write_out_c_sig <= tx_vec_c;
        spi_tb.miso_a <= rx_vec_a(rx_vec_a'high);
        spi_tb.miso_b <= rx_vec_b(rx_vec_b'high);
        spi_tb.miso_c <= rx_vec_c(rx_vec_c'high);

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs_a, '1', "nCsA high while idle before transfer");
        assert_equal(spi_dut.ncs_b, '1', "nCsB high while idle before transfer");
        assert_equal(spi_dut.ncs_c, '1', "nCsC high while idle before transfer");
        assert_equal(spi_dut.sck, '1', "Sck idle before transfer");

        spi_tb.write_dac <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs_a, '0', "nCsA low once transfer starts");
        assert_equal(spi_dut.ncs_b, '0', "nCsB low once transfer starts");
        assert_equal(spi_dut.ncs_c, '0', "nCsC low once transfer starts");
        assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low while transfer starts");

        for bit_num in tx_vec_a'high downto tx_vec_a'low loop
            wait until (spi_dut.sck'event and (spi_dut.sck = '0'));
            assert_equal(spi_dut.sck, '0', "Sck at shift point for bit " & integer'image(bit_num));
            assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Master shifted MOSI A bit " & integer'image(bit_num) & " during transfer");
            assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Master shifted MOSI B bit " & integer'image(bit_num) & " during transfer");
            assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num), "Master shifted MOSI C bit " & integer'image(bit_num) & " during transfer");
            assert_equal(spi_dut.ncs_a, '0', "nCsA stays low during shift of bit " & integer'image(bit_num));
            assert_equal(spi_dut.ncs_b, '0', "nCsB stays low during shift of bit " & integer'image(bit_num));
            assert_equal(spi_dut.ncs_c, '0', "nCsC stays low during shift of bit " & integer'image(bit_num));
            assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low during shift of bit " & integer'image(bit_num));

            if bit_num /= tx_vec_a'high then
                spi_tb.miso_a <= rx_vec_a(bit_num);
                spi_tb.miso_b <= rx_vec_b(bit_num);
                spi_tb.miso_c <= rx_vec_c(bit_num);
            end if;

            wait until (spi_dut.sck'event and (spi_dut.sck = '1'));
            assert_equal(spi_dut.sck, '1', "Sck at sample point for bit " & integer'image(bit_num));
            assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Slave sampled MOSI A bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_a));
            assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Slave sampled MOSI B bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_b));
            assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num), "Slave sampled MOSI C bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_c));
            assert_equal(spi_dut.ncs_a, '0', "nCsA stays low during sample of bit " & integer'image(bit_num));
            assert_equal(spi_dut.ncs_b, '0', "nCsB stays low during sample of bit " & integer'image(bit_num));
            assert_equal(spi_dut.ncs_c, '0', "nCsC stays low during sample of bit " & integer'image(bit_num));
            assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low during sample of bit " & integer'image(bit_num));

            wait until falling_edge(clk_in);
            assert_equal(spi_dut.sck, '1', "Sck at falling edge of clk after sample of bit " & integer'image(bit_num));
            assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Slave sampled MOSI A bit " & integer'image(bit_num) & " after falling edge of clk");
            assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Slave sampled MOSI B bit " & integer'image(bit_num) & " after falling edge of clk");
            assert_equal(spi_dut.mosi_c, tx_vec_c(bit_num), "Slave sampled MOSI C bit " & integer'image(bit_num) & " after falling edge of clk");
            assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low after falling edge of clk during sample of bit " & integer'image(bit_num));
        end loop;

        wait_until_value(clk_in, spi_dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, "Timed out waiting for TransferComplete after transaction");

        assert_equal(dac_readback_a_in, rx_vec_a, "Readback A captured expected RX data");
        assert_equal(dac_readback_b_in, rx_vec_b, "Readback B captured expected RX data");
        assert_equal(dac_readback_c_in, rx_vec_c, "Readback C captured expected RX data");
        assert_equal(spi_dut.ncs_a, '1', "nCsA released after transfer completes");
        assert_equal(spi_dut.ncs_b, '1', "nCsB released after transfer completes");
        assert_equal(spi_dut.ncs_c, '1', "nCsC released after transfer completes");
        assert_equal(spi_dut.transfer_complete, '1', "TransferComplete high after transfer completes");

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.transfer_complete, '1', "TransferComplete high after transfer completes and before next request");
        assert_equal(dac_readback_a_in, rx_vec_a, "Readback A stable after transfer completes");
        assert_equal(dac_readback_b_in, rx_vec_b, "Readback B stable after transfer completes");
        assert_equal(dac_readback_c_in, rx_vec_c, "Readback C stable after transfer completes");
        assert_equal(spi_dut.ncs_a, '1', "nCsA stays high after transfer completes and before next request");
        assert_equal(spi_dut.ncs_b, '1', "nCsB stays high after transfer completes and before next request");
        assert_equal(spi_dut.ncs_c, '1', "nCsC stays high after transfer completes and before next request");
        assert_equal(spi_dut.sck, '1', "Sck returns to idle after transfer completes");
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
        spi.tb.write_dac <= '0';
        spi.tb.rst <= '1';
        spi.tb.miso_a <= '0';
        spi.tb.miso_b <= '0';
        spi.tb.miso_c <= '0';
        dac_write_out_a <= (others => '0');
        dac_write_out_b <= (others => '0');
        dac_write_out_c <= (others => '0');

        set_test_name(test_name_display, "reset and idle");
        wait until falling_edge(clk);
        assert_equal(spi.dut.ncs_a, '1', "nCsA high in reset");
        assert_equal(spi.dut.ncs_b, '1', "nCsB high in reset");
        assert_equal(spi.dut.ncs_c, '1', "nCsC high in reset");
        assert_equal(spi.dut.sck, '1', "Sck idle in reset");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete low in reset");
        assert_equal(dac_readback_a, x"000000", "Readback A zero in reset");
        assert_equal(dac_readback_b, x"000000", "Readback B zero in reset");
        assert_equal(dac_readback_c, x"000000", "Readback C zero in reset");

        spi.tb.rst <= '0';
        wait until falling_edge(clk);
        assert_equal(spi.dut.ncs_a, '1', "nCsA high after reset");
        assert_equal(spi.dut.ncs_b, '1', "nCsB high after reset");
        assert_equal(spi.dut.ncs_c, '1', "nCsC high after reset");
        assert_equal(spi.dut.sck, '1', "Sck idle after reset");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete low after reset");

        cycle_clock(clk, 10);
        assert_equal(spi.dut.ncs_a, '1', "nCsA stays high after clocking");
        assert_equal(spi.dut.ncs_b, '1', "nCsB stays high after clocking");
        assert_equal(spi.dut.ncs_c, '1', "nCsC stays high after clocking");
        assert_equal(spi.dut.sck, '1', "Sck stays idle after clocking");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete stays low after clocking");

        set_test_name(test_name_display, "send only");
        send_receive_transaction(clk, spi.tb, spi.dut, dac_write_out_a, dac_write_out_b, dac_write_out_c, dac_readback_a, dac_readback_b, dac_readback_c, x"ABCDEF", x"13579B", x"2468AC", x"000000", x"000000", x"000000");

        set_test_name(test_name_display, "send ignores mid-transfer WriteOut change");
        spi.tb.write_dac <= '0';
        spi.tb.miso_a <= '0';
        spi.tb.miso_b <= '0';
        spi.tb.miso_c <= '0';
        dac_write_out_a <= x"ABCDEF";
        dac_write_out_b <= x"13579B";
        dac_write_out_c <= x"2468AC";
        wait until falling_edge(clk);
        spi.tb.write_dac <= '1';
        wait until falling_edge(clk);
        dac_write_out_a <= x"123456";
        dac_write_out_b <= x"654321";
        dac_write_out_c <= x"F0F0F0";

        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '1', "sampled original MOSI A bit 23 before data change");
        assert_equal(spi.dut.mosi_b, '0', "sampled original MOSI B bit 23 before data change");
        assert_equal(spi.dut.mosi_c, '0', "sampled original MOSI C bit 23 before data change");
        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '0', "sampled original MOSI A bit 22 after data change");
        assert_equal(spi.dut.mosi_b, '0', "sampled original MOSI B bit 22 after data change");
        assert_equal(spi.dut.mosi_c, '0', "sampled original MOSI C bit 22 after data change");
        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '1', "kept latched MOSI A bit 21 after data change");
        assert_equal(spi.dut.mosi_b, '0', "kept latched MOSI B bit 21 after data change");
        assert_equal(spi.dut.mosi_c, '1', "kept latched MOSI C bit 21 after data change");

        wait_until_value(clk, spi.dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, "Timed out waiting for completion after mid-transfer WriteOut change");
        assert_equal(dac_readback_a, x"000000", "mid-transfer data change kept transaction A intact");
        assert_equal(dac_readback_b, x"000000", "mid-transfer data change kept transaction B intact");
        assert_equal(dac_readback_c, x"000000", "mid-transfer data change kept transaction C intact");

        set_test_name(test_name_display, "hold WriteDac high does not restart");
        cycle_clock(clk, 10);
        assert_equal(spi.dut.ncs_a, '1', "nCsA stays high when WriteDac remains high");
        assert_equal(spi.dut.ncs_b, '1', "nCsB stays high when WriteDac remains high");
        assert_equal(spi.dut.ncs_c, '1', "nCsC stays high when WriteDac remains high");
        assert_equal(spi.dut.transfer_complete, '1', "TransferComplete stays high when WriteDac remains high");
        assert_equal(spi.dut.sck, '1', "Sck stays idle when WriteDac remains high");

        spi.tb.write_dac <= '0';
        wait until falling_edge(clk);
        assert_equal(spi.dut.ncs_a, '1', "dropping WriteDac low does not start transfer A");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete clears after dropping WriteDac low");

        set_test_name(test_name_display, "busy WriteDac toggles do not corrupt transfer");
        spi.tb.write_dac <= '0';
        spi.tb.miso_a <= '0';
        spi.tb.miso_b <= '0';
        spi.tb.miso_c <= '0';
        dac_write_out_a <= x"ABCDEF";
        dac_write_out_b <= x"13579B";
        dac_write_out_c <= x"2468AC";
        wait until falling_edge(clk);
        spi.tb.write_dac <= '1';
        wait until falling_edge(clk);

        spi.tb.write_dac <= '0';
        wait until(spi.dut.sck'event and (spi.dut.sck = '0'));
        assert_equal(spi.dut.mosi_a, '1', "shifted original MOSI A bit 23 before busy toggle");
        assert_equal(spi.dut.mosi_b, '0', "shifted original MOSI B bit 23 before busy toggle");
        assert_equal(spi.dut.mosi_c, '0', "shifted original MOSI C bit 23 before busy toggle");
        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '1', "sampled original MOSI A bit 23 before busy toggle");
        assert_equal(spi.dut.mosi_b, '0', "sampled original MOSI B bit 23 before busy toggle");
        assert_equal(spi.dut.mosi_c, '0', "sampled original MOSI C bit 23 before busy toggle");

        spi.tb.write_dac <= '1';
        wait until rising_edge(clk);
        assert_equal(spi.dut.ncs_a, '0', "nCsA stays low during busy WriteDac pulse");
        assert_equal(spi.dut.ncs_b, '0', "nCsB stays low during busy WriteDac pulse");
        assert_equal(spi.dut.ncs_c, '0', "nCsC stays low during busy WriteDac pulse");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete stays low during busy WriteDac pulse");

        wait until(spi.dut.sck'event and (spi.dut.sck = '0'));
        assert_equal(spi.dut.mosi_a, '0', "shifted original MOSI A bit 22 after busy toggle");
        assert_equal(spi.dut.mosi_b, '0', "shifted original MOSI B bit 22 after busy toggle");
        assert_equal(spi.dut.mosi_c, '0', "shifted original MOSI C bit 22 after busy toggle");
        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '0', "sampled original MOSI A bit 22 after busy toggle");
        assert_equal(spi.dut.mosi_b, '0', "sampled original MOSI B bit 22 after busy toggle");
        assert_equal(spi.dut.mosi_c, '0', "sampled original MOSI C bit 22 after busy toggle");
        wait until(spi.dut.sck'event and (spi.dut.sck = '0'));
        assert_equal(spi.dut.mosi_a, '1', "shifted original MOSI A bit 21 after busy toggle");
        assert_equal(spi.dut.mosi_b, '0', "shifted original MOSI B bit 21 after busy toggle");
        assert_equal(spi.dut.mosi_c, '1', "shifted original MOSI C bit 21 after busy toggle");

        spi.tb.write_dac <= '0';
        reset_dut(clk, spi.tb.rst);
        wait until falling_edge(clk);
        assert_equal(spi.dut.ncs_a, '1', "nCsA high after releasing busy-toggle reset");
        assert_equal(spi.dut.ncs_b, '1', "nCsB high after releasing busy-toggle reset");
        assert_equal(spi.dut.ncs_c, '1', "nCsC high after releasing busy-toggle reset");
        assert_equal(spi.dut.sck, '1', "Sck idle after releasing busy-toggle reset");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete low after releasing busy-toggle reset");

        set_test_name(test_name_display, "receive only");
        send_receive_transaction(clk, spi.tb, spi.dut, dac_write_out_a, dac_write_out_b, dac_write_out_c, dac_readback_a, dac_readback_b, dac_readback_c, x"000000", x"000000", x"000000", x"55AA33", x"AA55CC", x"3CC33C");

        spi.tb.write_dac <= '0';
        wait until rising_edge(clk);

        set_test_name(test_name_display, "send and receive");
        send_receive_transaction(clk, spi.tb, spi.dut, dac_write_out_a, dac_write_out_b, dac_write_out_c, dac_readback_a, dac_readback_b, dac_readback_c, x"FEDCBA", x"89ABCD", x"102938", x"A5A5A5", x"5A5A5A", x"C33CC3");

        spi.tb.write_dac <= '0';
        wait until rising_edge(clk);

        set_test_name(test_name_display, "write_dac going low clear TransferComplete and nCs");
        dac_write_out_a <= x"F0F0F0";
        dac_write_out_b <= x"0F0F0F";
        dac_write_out_c <= x"AAAAAA";
        spi.tb.miso_a <= '1';
        spi.tb.miso_b <= '1';
        spi.tb.miso_c <= '1';
        wait until falling_edge(clk);
        spi.tb.write_dac <= '1';
        wait until falling_edge(clk);
        assert_equal(spi.dut.transfer_complete, '0', "new WriteDac rising edge clears TransferComplete");
        assert_equal(spi.dut.ncs_a, '0', "nCsA low during new transfer");
        assert_equal(spi.dut.ncs_b, '0', "nCsB low during new transfer");
        assert_equal(spi.dut.ncs_c, '0', "nCsC low during new transfer");

        wait_until_value(clk, spi.dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, "timed out waiting for completion after final transaction");
        assert_equal(dac_readback_a, x"FFFFFF", "Readback A captured final transaction pattern");
        assert_equal(dac_readback_b, x"FFFFFF", "Readback B captured final transaction pattern");
        assert_equal(dac_readback_c, x"FFFFFF", "Readback C captured final transaction pattern");
        assert_equal(spi.dut.ncs_a, '1', "nCsA high after final transaction");
        assert_equal(spi.dut.ncs_b, '1', "nCsB high after final transaction");
        assert_equal(spi.dut.ncs_c, '1', "nCsC high after final transaction");
        cycle_clock(clk, 8);
        assert_equal(spi.dut.ncs_a, '1', "nCsA stays high after completion");
        assert_equal(spi.dut.ncs_b, '1', "nCsB stays high after completion");
        assert_equal(spi.dut.ncs_c, '1', "nCsC stays high after completion");
        assert_equal(spi.dut.sck, '1', "Sck stays idle after completion");
        assert_equal(spi.dut.transfer_complete, '1', "TransferComplete stays high after completion");
        assert_equal(dac_readback_a, x"FFFFFF", "Readback A stays stable after dropping WriteDac low");
        assert_equal(dac_readback_b, x"FFFFFF", "Readback B stays stable after dropping WriteDac low");
        assert_equal(dac_readback_c, x"FFFFFF", "Readback C stays stable after dropping WriteDac low");

        set_test_name(test_name_display, "completion handshake shape");
        spi.tb.write_dac <= '0';
        cycle_clock(clk, 4);
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete stays low while idle and dac_write low");
        assert_equal(spi.dut.ncs_a, '1', "nCsA stays high while completion is held");
        assert_equal(spi.dut.ncs_b, '1', "nCsB stays high while completion is held");
        assert_equal(spi.dut.ncs_c, '1', "nCsC stays high while completion is held");
        assert_equal(spi.dut.sck, '1', "Sck stays idle while completion is held");
        assert_equal(dac_readback_a, x"FFFFFF", "Readback A stays stable while completion is held");
        assert_equal(dac_readback_b, x"FFFFFF", "Readback B stays stable while completion is held");
        assert_equal(dac_readback_c, x"FFFFFF", "Readback C stays stable while completion is held");

        dac_write_out_a <= x"3C3C3C";
        dac_write_out_b <= x"C3C3C3";
        dac_write_out_c <= x"5A5A5A";
        spi.tb.miso_a <= '1';
        spi.tb.miso_b <= '1';
        spi.tb.miso_c <= '1';
        wait until falling_edge(clk);
        spi.tb.write_dac <= '1';
        wait until falling_edge(clk);
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete clears only when a new transfer starts");
        assert_equal(spi.dut.ncs_a, '0', "nCsA goes low when completion clears for a new transfer");
        assert_equal(spi.dut.ncs_b, '0', "nCsB goes low when completion clears for a new transfer");
        assert_equal(spi.dut.ncs_c, '0', "nCsC goes low when completion clears for a new transfer");
        assert_equal(dac_readback_a, x"FFFFFF", "Readback A holds previous completed value during new transfer");
        assert_equal(dac_readback_b, x"FFFFFF", "Readback B holds previous completed value during new transfer");
        assert_equal(dac_readback_c, x"FFFFFF", "Readback C holds previous completed value during new transfer");

        cycle_clock(clk, 4);
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete stays low during active transfer");
        wait_until_value(clk, spi.dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, "timed out waiting for completion during handshake-shape test");
        assert_equal(dac_readback_a, x"FFFFFF", "Readback A captured expected data after completion handshake test");
        assert_equal(dac_readback_b, x"FFFFFF", "Readback B captured expected data after completion handshake test");
        assert_equal(dac_readback_c, x"FFFFFF", "Readback C captured expected data after completion handshake test");
        cycle_clock(clk, 4);
        assert_equal(spi.dut.transfer_complete, '1', "TransferComplete returns high and stays high after completion with dac write still high");

        set_test_name(test_name_display, "quick back-to-back requests");
        spi.tb.write_dac <= '0';
        wait until rising_edge(clk);
        send_receive_transaction(clk, spi.tb, spi.dut, dac_write_out_a, dac_write_out_b, dac_write_out_c, dac_readback_a, dac_readback_b, dac_readback_c, x"121212", x"343434", x"565656", x"787878", x"9A9A9A", x"BCBCBC");
        spi.tb.write_dac <= '0';
        wait until rising_edge(clk);
        send_receive_transaction(clk, spi.tb, spi.dut, dac_write_out_a, dac_write_out_b, dac_write_out_c, dac_readback_a, dac_readback_b, dac_readback_c, x"DEDEDE", x"F0F0F0", x"111111", x"222222", x"333333", x"444444");

        set_test_name(test_name_display, "reset during active transfer");
        spi.tb.write_dac <= '0';
        spi.tb.miso_a <= '0';
        spi.tb.miso_b <= '0';
        spi.tb.miso_c <= '0';
        dac_write_out_a <= x"C3C3C3";
        dac_write_out_b <= x"3C3C3C";
        dac_write_out_c <= x"5A5A5A";
        wait until falling_edge(clk);
        spi.tb.write_dac <= '1';
        wait until falling_edge(clk);

        wait until(spi.dut.sck'event and (spi.dut.sck = '0'));
        assert_equal(spi.dut.mosi_a, '1', "shifted original MOSI A bit 23 before reset");
        assert_equal(spi.dut.mosi_b, '0', "shifted original MOSI B bit 23 before reset");
        assert_equal(spi.dut.mosi_c, '0', "shifted original MOSI C bit 23 before reset");
        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '1', "sampled original MOSI A bit 23 before reset");
        assert_equal(spi.dut.mosi_b, '0', "sampled original MOSI B bit 23 before reset");
        assert_equal(spi.dut.mosi_c, '0', "sampled original MOSI C bit 23 before reset");
        wait until(spi.dut.sck'event and (spi.dut.sck = '0'));
        assert_equal(spi.dut.mosi_a, '1', "shifted original MOSI A bit 22 before reset");
        assert_equal(spi.dut.mosi_b, '0', "shifted original MOSI B bit 22 before reset");
        assert_equal(spi.dut.mosi_c, '1', "shifted original MOSI C bit 22 before reset");
        wait until(spi.dut.sck'event and (spi.dut.sck = '1'));
        assert_equal(spi.dut.mosi_a, '1', "sampled original MOSI A bit 22 before reset");
        assert_equal(spi.dut.mosi_b, '0', "sampled original MOSI B bit 22 before reset");
        assert_equal(spi.dut.mosi_c, '1', "sampled original MOSI C bit 22 before reset");

        assert_equal(spi.dut.ncs_a, '0', "nCsA low before reset during transfer");
        assert_equal(spi.dut.ncs_b, '0', "nCsB low before reset during transfer");
        assert_equal(spi.dut.ncs_c, '0', "nCsC low before reset during transfer");

        spi.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi.dut.ncs_a, '1', "nCsA high after reset during transfer");
        assert_equal(spi.dut.ncs_b, '1', "nCsB high after reset during transfer");
        assert_equal(spi.dut.ncs_c, '1', "nCsC high after reset during transfer");
        assert_equal(spi.dut.sck, '1', "Sck idle after reset during transfer");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete low after reset during transfer");
        assert_equal(dac_readback_a, x"000000", "reset during transfer does not overwrite last completed Readback A");
        assert_equal(dac_readback_b, x"000000", "reset during transfer does not overwrite last completed Readback B");
        assert_equal(dac_readback_c, x"000000", "reset during transfer does not overwrite last completed Readback C");

        spi.tb.write_dac <= '0';
        spi.tb.rst <= '0';
        wait until falling_edge(clk);
        assert_equal(spi.dut.ncs_a, '1', "nCsA stays high after releasing reset");
        assert_equal(spi.dut.ncs_b, '1', "nCsB stays high after releasing reset");
        assert_equal(spi.dut.ncs_c, '1', "nCsC stays high after releasing reset");
        assert_equal(spi.dut.sck, '1', "Sck stays idle after releasing reset");

        spi.tb.rst <= '1';
        wait until falling_edge(clk);
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete low after final reset");
        assert_equal(spi.dut.sck, '1', "Sck returns to idle after final reset");

        cycle_clock(clk, 100);
        assert_equal(spi.dut.sck, '1', "Sck stays idle after clocking");
        assert_equal(spi.dut.ncs_a, '1', "nCsA stays high after clocking");
        assert_equal(spi.dut.ncs_b, '1', "nCsB stays high after clocking");
        assert_equal(spi.dut.ncs_c, '1', "nCsC stays high after clocking");
        assert_equal(spi.dut.transfer_complete, '0', "TransferComplete stays low after clocking");
        finish;
    end process;

    dut : entity work.SpiDacTrioPorts
    generic map (
        MASTER_CLOCK_FREQHZ => 1000000
    )
    port map (
        clk => clk,
        rst => spi.tb.rst,
        nCsA => spi.dut.ncs_a,
        nCsB => spi.dut.ncs_b,
        nCsC => spi.dut.ncs_c,
        Sck => spi.dut.sck,
        MosiA => spi.dut.mosi_a,
        MosiB => spi.dut.mosi_b,
        MosiC => spi.dut.mosi_c,
        MisoA => spi.tb.miso_a,
        MisoB => spi.tb.miso_b,
        MisoC => spi.tb.miso_c,
        WriteDac => spi.tb.write_dac,
        DacWriteOutA => dac_write_out_a,
        DacWriteOutB => dac_write_out_b,
        DacWriteOutC => dac_write_out_c,
        DacReadbackA => dac_readback_a,
        DacReadbackB => dac_readback_b,
        DacReadbackC => dac_readback_c,
        TransferComplete => spi.dut.transfer_complete
    );

end architecture sim;
