--! \brief Basic testbench for SpiDeviceDual.vhd
--! Covers reset/idle behavior, dual-lane send/receive, chip-select control,
--! readback capture, TransferComplete timing, Transfer edge-trigger behavior,
--! and CPOL/CPHA mode coverage.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity SpiDeviceDual_tb is
end SpiDeviceDual_tb;

architecture sim of SpiDeviceDual_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant TRANSFER_COMPLETE_TIMEOUT_CYCLES : natural := 5000;

    type spi_tb_out_t is record
        rst      : std_logic;
        miso_a   : std_logic;
        miso_b   : std_logic;
        transfer : std_logic;
    end record;

    type spi_dut_out_t is record
        ncs               : std_logic;
        sck               : std_logic;
        mosi_a            : std_logic;
        mosi_b            : std_logic;
        transfer_complete : std_logic;
    end record;

    type spi_if_t is record
        tb  : spi_tb_out_t;
        dut : spi_dut_out_t;
    end record;

    signal clk : std_logic := '0';
    signal test_name_display : string(1 to 80);

    signal spi_mode0, spi_mode1, spi_mode2, spi_mode3 : spi_if_t;
    signal spi_bw16 : spi_if_t;
    signal spi_clk2 : spi_if_t;

    signal write_out_a_mode0, readback_a_mode0 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_b_mode0, readback_b_mode0 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_a_mode1, readback_a_mode1 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_b_mode1, readback_b_mode1 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_a_mode2, readback_a_mode2 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_b_mode2, readback_b_mode2 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_a_mode3, readback_a_mode3 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_b_mode3, readback_b_mode3 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_a_bw16, readback_a_bw16 : std_logic_vector(15 downto 0) := (others => '0');
    signal write_out_b_bw16, readback_b_bw16 : std_logic_vector(15 downto 0) := (others => '0');
    signal write_out_a_clk2, readback_a_clk2 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_b_clk2, readback_b_clk2 : std_logic_vector(7 downto 0) := (others => '0');

    procedure send_receive_transaction(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal write_out_a_sig : out std_logic_vector;
        signal write_out_b_sig : out std_logic_vector;
        signal readback_a_in : in std_logic_vector;
        signal readback_b_in : in std_logic_vector;
        constant cpol : std_logic;
        constant cpha : std_logic;
        constant tx_data_a : std_logic_vector;
        constant tx_data_b : std_logic_vector;
        constant rx_data_a : std_logic_vector;
        constant rx_data_b : std_logic_vector
    ) is
        variable tx_vec_a : std_logic_vector(write_out_a_sig'range);
        variable tx_vec_b : std_logic_vector(write_out_b_sig'range);
        variable rx_vec_a : std_logic_vector(readback_a_in'range);
        variable rx_vec_b : std_logic_vector(readback_b_in'range);
    begin
        tx_vec_a := tx_data_a;
        tx_vec_b := tx_data_b;
        rx_vec_a := rx_data_a;
        rx_vec_b := rx_data_b;

        spi_tb.transfer <= '0';
        write_out_a_sig <= tx_vec_a;
        write_out_b_sig <= tx_vec_b;
        spi_tb.miso_a <= rx_vec_a(rx_vec_a'high);
        spi_tb.miso_b <= rx_vec_b(rx_vec_b'high);

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', "nCs high while idle before transfer");
        assert_equal(spi_dut.sck, not cpol, "Sck idle before transfer");

        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '0', "nCs low once transfer starts");
        assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low while transfer starts");

        for bit_num in tx_vec_a'high downto tx_vec_a'low loop
            if cpha = '1' then
                wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
                assert_equal(spi_dut.sck, not(cpol xor cpha), "Sck at sample point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Slave sampled MOSI A bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_a));
                assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Slave sampled MOSI B bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_b));
                assert_equal(spi_dut.ncs, '0', "nCs stays low during sample of bit " & integer'image(bit_num));
                assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low during sample of bit " & integer'image(bit_num));

                if bit_num > tx_vec_a'low then
                    wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
                    spi_tb.miso_a <= rx_vec_a(bit_num - 1);
                    spi_tb.miso_b <= rx_vec_b(bit_num - 1);
                    assert_equal(spi_dut.sck, cpol xor cpha, "Sck at shift point for bit " & integer'image(bit_num - 1));
                    assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num - 1), "Master shifted MOSI A bit " & integer'image(bit_num - 1) & " during transfer");
                    assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num - 1), "Master shifted MOSI B bit " & integer'image(bit_num - 1) & " during transfer");
                    assert_equal(spi_dut.ncs, '0', "nCs stays low during shift of bit " & integer'image(bit_num - 1));
                    assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low during shift of bit " & integer'image(bit_num - 1));
                end if;
            else
                wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
                assert_equal(spi_dut.sck, cpol xor cpha, "Sck at shift point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Master shifted MOSI A bit " & integer'image(bit_num) & " during transfer");
                assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Master shifted MOSI B bit " & integer'image(bit_num) & " during transfer");
                assert_equal(spi_dut.ncs, '0', "nCs stays low during shift of bit " & integer'image(bit_num));
                assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low during shift of bit " & integer'image(bit_num));

                if bit_num /= tx_vec_a'high then
                    spi_tb.miso_a <= rx_vec_a(bit_num);
                    spi_tb.miso_b <= rx_vec_b(bit_num);
                end if;

                wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
                assert_equal(spi_dut.sck, not(cpol xor cpha), "Sck at sample point for bit " & integer'image(bit_num));
                assert_equal(spi_dut.mosi_a, tx_vec_a(bit_num), "Slave sampled MOSI A bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_a));
                assert_equal(spi_dut.mosi_b, tx_vec_b(bit_num), "Slave sampled MOSI B bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec_b));
                assert_equal(spi_dut.ncs, '0', "nCs stays low during sample of bit " & integer'image(bit_num));
                assert_equal(spi_dut.transfer_complete, '0', "TransferComplete low during sample of bit " & integer'image(bit_num));
            end if;
        end loop;

        wait_until_value(clk_in, spi_dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, "Timed out waiting for TransferComplete after transaction");

        assert_equal(readback_a_in, rx_vec_a, "Readback A captured expected RX data");
        assert_equal(readback_b_in, rx_vec_b, "Readback B captured expected RX data");
        assert_equal(spi_dut.ncs, '1', "nCs released after transfer completes");
        assert_equal(spi_dut.transfer_complete, '1', "TransferComplete high after transfer completes");

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.transfer_complete, '1', "TransferComplete high after transfer completes and before next request");
        assert_equal(readback_a_in, rx_vec_a, "Readback A stable after transfer completes");
        assert_equal(readback_b_in, rx_vec_b, "Readback B stable after transfer completes");
        assert_equal(spi_dut.ncs, '1', "nCs stays high after transfer completes and before next request");
        assert_equal(spi_dut.sck, not cpol, "Sck returns to idle after transfer completes");
    end procedure;

    procedure run_mode_tests(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal write_out_a_sig : out std_logic_vector(7 downto 0);
        signal write_out_b_sig : out std_logic_vector(7 downto 0);
        signal readback_a_in : in std_logic_vector(7 downto 0);
        signal readback_b_in : in std_logic_vector(7 downto 0);
        signal test_name_sig : out string;
        constant mode_label : string;
        constant cpol : std_logic;
        constant cpha : std_logic
    ) is
    begin
        spi_tb.transfer <= '0';
        write_out_a_sig <= (others => '0');
        write_out_b_sig <= (others => '0');
        spi_tb.miso_a <= '0';
        spi_tb.miso_b <= '0';
        spi_tb.rst <= '1';

        set_test_name(test_name_sig, mode_label & " reset and idle");
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs high in reset");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck idle in reset");
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete low in reset");
        assert_equal(readback_a_in, x"00", mode_label & " Readback A zero in reset");
        assert_equal(readback_b_in, x"00", mode_label & " Readback B zero in reset");

        spi_tb.rst <= '0';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs high after reset");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck idle after reset");
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete low after reset");

        cycle_clock(clk_in, 10);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs stays high after clocking");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck stays idle after clocking");
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete stays low after clocking");

        set_test_name(test_name_sig, mode_label & " send only");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_a_sig, write_out_b_sig, readback_a_in, readback_b_in, cpol, cpha, x"A5", x"3C", x"00", x"00");

        set_test_name(test_name_sig, mode_label & " send ignores mid-transfer WriteOut change");
        spi_tb.transfer <= '0';
        spi_tb.miso_a <= '0';
        spi_tb.miso_b <= '0';
        write_out_a_sig <= x"A5";
        write_out_b_sig <= x"3C";
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        write_out_a_sig <= x"5A";
        write_out_b_sig <= x"C3";

        wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
        assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 7 before data change");
        assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 7 before data change");
        wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
        assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 6 after data change");
        assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 6 after data change");
        wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
        assert_equal(spi_dut.mosi_a, '1', mode_label & " kept latched MOSI A bit 5 after data change");
        assert_equal(spi_dut.mosi_b, '1', mode_label & " kept latched MOSI B bit 5 after data change");

        wait_until_value(clk_in, spi_dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, mode_label & " timed out waiting for completion after mid-transfer WriteOut change");
        assert_equal(readback_a_in, x"00", mode_label & " mid-transfer data change kept transaction A intact");
        assert_equal(readback_b_in, x"00", mode_label & " mid-transfer data change kept transaction B intact");

        set_test_name(test_name_sig, mode_label & " hold Transfer high does not restart");
        cycle_clock(clk_in, 10);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs stays high when Transfer remains high");
        assert_equal(spi_dut.transfer_complete, '1', mode_label & " TransferComplete stays high when Transfer remains high");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck stays idle when Transfer remains high");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', mode_label & " dropping Transfer low does not start transfer");
        assert_equal(spi_dut.transfer_complete, '1', mode_label & " TransferComplete unchanged after dropping Transfer low");

        set_test_name(test_name_sig, mode_label & " busy Transfer toggles do not corrupt transfer");
        spi_tb.transfer <= '0';
        spi_tb.miso_a <= '0';
        spi_tb.miso_b <= '0';
        write_out_a_sig <= x"A5";
        write_out_b_sig <= x"3C";
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);

        spi_tb.transfer <= '0';

        if cpha = '1' then
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 7 before busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 7 before busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 6 before busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 6 before busy toggle");
            spi_tb.transfer <= '1';
            wait until rising_edge(clk_in);
            assert_equal(spi_dut.ncs, '0', mode_label & " nCs stays low during busy Transfer pulse");
            assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete stays low during busy Transfer pulse");
            spi_tb.transfer <= '0';

            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 6 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 6 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 5 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 5 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 5 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 5 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 4 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 4 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 4 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 4 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 3 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 3 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 3 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 3 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 2 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 2 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 2 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 2 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 1 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 1 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 1 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 1 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 0 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 0 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 0 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 0 after busy toggle");
        else
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 7 before busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 7 before busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 7 before busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 7 before busy toggle");

            spi_tb.transfer <= '1';
            wait until rising_edge(clk_in);
            assert_equal(spi_dut.ncs, '0', mode_label & " nCs stays low during busy Transfer pulse");
            assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete stays low during busy Transfer pulse");
            spi_tb.transfer <= '0';

            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 6 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 6 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 6 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 6 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 5 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 5 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 5 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 5 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 4 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 4 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 4 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 4 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 3 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 3 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 3 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 3 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 2 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " shifted original MOSI B bit 2 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 2 after busy toggle");
            assert_equal(spi_dut.mosi_b, '1', mode_label & " sampled original MOSI B bit 2 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " shifted original MOSI A bit 1 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 1 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '0', mode_label & " sampled original MOSI A bit 1 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 1 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 0 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 0 after busy toggle");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 0 after busy toggle");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 0 after busy toggle");
        end if;

        cycle_clock(clk_in, 10);
        assert_equal(spi_dut.transfer_complete, '1', mode_label & " busy Transfer toggle kept original transaction intact");
        assert_equal(readback_a_in, x"00", mode_label & " busy Transfer toggle kept original transaction A intact");
        assert_equal(readback_b_in, x"00", mode_label & " busy Transfer toggle kept original transaction B intact");

        set_test_name(test_name_sig, mode_label & " receive only");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_a_sig, write_out_b_sig, readback_a_in, readback_b_in, cpol, cpha, x"00", x"00", x"3C", x"C3");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);

        set_test_name(test_name_sig, mode_label & " send and receive");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_a_sig, write_out_b_sig, readback_a_in, readback_b_in, cpol, cpha, x"96", x"69", x"70", x"0F");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);

        set_test_name(test_name_sig, mode_label & " new transfer clears completion");
        write_out_a_sig <= x"F0";
        write_out_b_sig <= x"0F";
        spi_tb.miso_a <= '1';
        spi_tb.miso_b <= '1';
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " new Transfer rising edge clears TransferComplete");
        assert_equal(spi_dut.ncs, '0', mode_label & " nCs low during new transfer");

        spi_tb.transfer <= '0';
        wait_until_value(clk_in, spi_dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, mode_label & " timed out waiting for completion after final transaction");
        assert_equal(readback_a_in, x"FF", mode_label & " Readback A captured final transaction pattern");
        assert_equal(readback_b_in, x"FF", mode_label & " Readback B captured final transaction pattern");
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs high after final transaction");
        cycle_clock(clk_in, 8);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs stays high after completion");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck stays idle after completion");
        assert_equal(spi_dut.transfer_complete, '1', mode_label & " TransferComplete stays high after completion");

        set_test_name(test_name_sig, mode_label & " completion handshake shape");
        cycle_clock(clk_in, 12);
        assert_equal(spi_dut.transfer_complete, '1', mode_label & " TransferComplete stays high while idle");
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs stays high while completion is held");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck stays idle while completion is held");
        assert_equal(readback_a_in, x"FF", mode_label & " Readback A stays stable while completion is held");
        assert_equal(readback_b_in, x"FF", mode_label & " Readback B stays stable while completion is held");

        write_out_a_sig <= x"3C";
        write_out_b_sig <= x"C3";
        spi_tb.miso_a <= '1';
        spi_tb.miso_b <= '1';
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete clears only when a new transfer starts");
        assert_equal(spi_dut.ncs, '0', mode_label & " nCs goes low when completion clears for a new transfer");
        assert_equal(readback_a_in, x"FF", mode_label & " Readback A holds previous completed value during new transfer");
        assert_equal(readback_b_in, x"FF", mode_label & " Readback B holds previous completed value during new transfer");

        spi_tb.transfer <= '0';
        cycle_clock(clk_in, 4);
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete stays low during active transfer");

        wait_until_value(clk_in, spi_dut.transfer_complete, '1', TRANSFER_COMPLETE_TIMEOUT_CYCLES, mode_label & " timed out waiting for completion during handshake-shape test");
        assert_equal(readback_a_in, x"FF", mode_label & " Readback A captured expected data after completion handshake test");
        assert_equal(readback_b_in, x"FF", mode_label & " Readback B captured expected data after completion handshake test");
        cycle_clock(clk_in, 4);
        assert_equal(spi_dut.transfer_complete, '1', mode_label & " TransferComplete returns high and stays high after completion");

        set_test_name(test_name_sig, mode_label & " quick back-to-back requests");
        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_a_sig, write_out_b_sig, readback_a_in, readback_b_in, cpol, cpha, x"12", x"34", x"34", x"12");
        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_a_sig, write_out_b_sig, readback_a_in, readback_b_in, cpol, cpha, x"56", x"78", x"78", x"56");

        set_test_name(test_name_sig, mode_label & " reset during active transfer");
        spi_tb.transfer <= '0';
        spi_tb.miso_a <= '0';
        spi_tb.miso_b <= '0';
        write_out_a_sig <= x"C3";
        write_out_b_sig <= x"3C";
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);

        if cpha = '1' then
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 7 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 7 before reset");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 6 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 6 before reset");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 6 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 6 before reset");
        else
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 7 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 7 before reset");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 7 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 7 before reset");
            wait until (spi_dut.sck'event and (spi_dut.sck = (cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " shifted original MOSI A bit 6 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " shifted original MOSI B bit 6 before reset");
            wait until (spi_dut.sck'event and (spi_dut.sck = not(cpol xor cpha)));
            assert_equal(spi_dut.mosi_a, '1', mode_label & " sampled original MOSI A bit 6 before reset");
            assert_equal(spi_dut.mosi_b, '0', mode_label & " sampled original MOSI B bit 6 before reset");
        end if;

        assert_equal(spi_dut.ncs, '0', mode_label & " nCs low before reset during transfer");

        spi_tb.rst <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs high after reset during transfer");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck idle after reset during transfer");
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete low after reset during transfer");
        assert_equal(readback_a_in, x"00", mode_label & " reset during transfer does not overwrite last completed Readback A");
        assert_equal(readback_b_in, x"00", mode_label & " reset during transfer does not overwrite last completed Readback B");

        spi_tb.transfer <= '0';
        spi_tb.rst <= '0';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs stays high after releasing reset");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck stays idle after releasing reset");

        spi_tb.rst <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete low after final reset");
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck returns to idle after final reset");

        cycle_clock(clk_in, 100);
        assert_equal(spi_dut.sck, not cpol, mode_label & " Sck stays idle after clocking");
        assert_equal(spi_dut.ncs, '1', mode_label & " nCs stays high after clocking");
        assert_equal(spi_dut.transfer_complete, '0', mode_label & " TransferComplete stays low after clocking");
    end procedure;

    procedure run_width16_test(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal write_out_a_sig : out std_logic_vector(15 downto 0);
        signal write_out_b_sig : out std_logic_vector(15 downto 0);
        signal readback_a_in : in std_logic_vector(15 downto 0);
        signal readback_b_in : in std_logic_vector(15 downto 0);
        signal test_name_sig : out string
    ) is
    begin
        spi_tb.transfer <= '0';
        spi_tb.miso_a <= '0';
        spi_tb.miso_b <= '0';
        spi_tb.rst <= '1';
        write_out_a_sig <= (others => '0');
        write_out_b_sig <= (others => '0');

        set_test_name(test_name_sig, "BIT_WIDTH 16 reset and idle");
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', "BIT_WIDTH 16 nCs high in reset");
        assert_equal(spi_dut.sck, '1', "BIT_WIDTH 16 Sck idle in reset");
        assert_equal(spi_dut.transfer_complete, '0', "BIT_WIDTH 16 TransferComplete low in reset");

        spi_tb.rst <= '0';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', "BIT_WIDTH 16 nCs high after reset");
        assert_equal(spi_dut.sck, '1', "BIT_WIDTH 16 Sck idle after reset");

        set_test_name(test_name_sig, "BIT_WIDTH 16 send and receive");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_a_sig, write_out_b_sig, readback_a_in, readback_b_in, '0', '0', x"A55A", x"5AA5", x"3CC3", x"C33C");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', "BIT_WIDTH 16 nCs idle after transfer");
        assert_equal(spi_dut.sck, '1', "BIT_WIDTH 16 Sck idle after transfer");
        assert_equal(spi_dut.transfer_complete, '1', "BIT_WIDTH 16 TransferComplete high after transfer");

        spi_tb.rst <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.transfer_complete, '0', "BIT_WIDTH 16 TransferComplete low after reset");
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
        run_mode_tests(clk, spi_mode0.tb, spi_mode0.dut, write_out_a_mode0, write_out_b_mode0, readback_a_mode0, readback_b_mode0, test_name_display, "Mode 0", '0', '0');
        run_mode_tests(clk, spi_mode2.tb, spi_mode2.dut, write_out_a_mode2, write_out_b_mode2, readback_a_mode2, readback_b_mode2, test_name_display, "Mode 2", '1', '0');
        run_mode_tests(clk, spi_mode1.tb, spi_mode1.dut, write_out_a_mode1, write_out_b_mode1, readback_a_mode1, readback_b_mode1, test_name_display, "Mode 1", '0', '1');
        run_mode_tests(clk, spi_mode3.tb, spi_mode3.dut, write_out_a_mode3, write_out_b_mode3, readback_a_mode3, readback_b_mode3, test_name_display, "Mode 3", '1', '1');
        run_mode_tests(clk, spi_clk2.tb, spi_clk2.dut, write_out_a_clk2, write_out_b_clk2, readback_a_clk2, readback_b_clk2, test_name_display, "Clock Divider 2", '0', '0');
        run_width16_test(clk, spi_bw16.tb, spi_bw16.dut, write_out_a_bw16, write_out_b_bw16, readback_a_bw16, readback_b_bw16, test_name_display);
        finish;
    end process;

    dut_mode0 : entity work.SpiDeviceDualPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BIT_WIDTH => 8,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_mode0.tb.rst,
        nCs => spi_mode0.dut.ncs,
        Sck => spi_mode0.dut.sck,
        MosiA => spi_mode0.dut.mosi_a,
        MosiB => spi_mode0.dut.mosi_b,
        MisoA => spi_mode0.tb.miso_a,
        MisoB => spi_mode0.tb.miso_b,
        WriteOutA => write_out_a_mode0,
        WriteOutB => write_out_b_mode0,
        Transfer => spi_mode0.tb.transfer,
        ReadbackA => readback_a_mode0,
        ReadbackB => readback_b_mode0,
        TransferComplete => spi_mode0.dut.transfer_complete
    );

    dut_mode2 : entity work.SpiDeviceDualPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BIT_WIDTH => 8,
        CPOL => '1',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_mode2.tb.rst,
        nCs => spi_mode2.dut.ncs,
        Sck => spi_mode2.dut.sck,
        MosiA => spi_mode2.dut.mosi_a,
        MosiB => spi_mode2.dut.mosi_b,
        MisoA => spi_mode2.tb.miso_a,
        MisoB => spi_mode2.tb.miso_b,
        WriteOutA => write_out_a_mode2,
        WriteOutB => write_out_b_mode2,
        Transfer => spi_mode2.tb.transfer,
        ReadbackA => readback_a_mode2,
        ReadbackB => readback_b_mode2,
        TransferComplete => spi_mode2.dut.transfer_complete
    );

    dut_mode1 : entity work.SpiDeviceDualPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BIT_WIDTH => 8,
        CPOL => '0',
        CPHA => '1'
    )
    port map (
        clk => clk,
        rst => spi_mode1.tb.rst,
        nCs => spi_mode1.dut.ncs,
        Sck => spi_mode1.dut.sck,
        MosiA => spi_mode1.dut.mosi_a,
        MosiB => spi_mode1.dut.mosi_b,
        MisoA => spi_mode1.tb.miso_a,
        MisoB => spi_mode1.tb.miso_b,
        WriteOutA => write_out_a_mode1,
        WriteOutB => write_out_b_mode1,
        Transfer => spi_mode1.tb.transfer,
        ReadbackA => readback_a_mode1,
        ReadbackB => readback_b_mode1,
        TransferComplete => spi_mode1.dut.transfer_complete
    );

    dut_mode3 : entity work.SpiDeviceDualPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BIT_WIDTH => 8,
        CPOL => '1',
        CPHA => '1'
    )
    port map (
        clk => clk,
        rst => spi_mode3.tb.rst,
        nCs => spi_mode3.dut.ncs,
        Sck => spi_mode3.dut.sck,
        MosiA => spi_mode3.dut.mosi_a,
        MosiB => spi_mode3.dut.mosi_b,
        MisoA => spi_mode3.tb.miso_a,
        MisoB => spi_mode3.tb.miso_b,
        WriteOutA => write_out_a_mode3,
        WriteOutB => write_out_b_mode3,
        Transfer => spi_mode3.tb.transfer,
        ReadbackA => readback_a_mode3,
        ReadbackB => readback_b_mode3,
        TransferComplete => spi_mode3.dut.transfer_complete
    );

    dut_bw16 : entity work.SpiDeviceDualPorts
    generic map (
        CLOCK_DIVIDER => 10,
        BIT_WIDTH => 16,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_bw16.tb.rst,
        nCs => spi_bw16.dut.ncs,
        Sck => spi_bw16.dut.sck,
        MosiA => spi_bw16.dut.mosi_a,
        MosiB => spi_bw16.dut.mosi_b,
        MisoA => spi_bw16.tb.miso_a,
        MisoB => spi_bw16.tb.miso_b,
        WriteOutA => write_out_a_bw16,
        WriteOutB => write_out_b_bw16,
        Transfer => spi_bw16.tb.transfer,
        ReadbackA => readback_a_bw16,
        ReadbackB => readback_b_bw16,
        TransferComplete => spi_bw16.dut.transfer_complete
    );

    dut_clk2 : entity work.SpiDeviceDualPorts
    generic map (
        CLOCK_DIVIDER => 2,
        BIT_WIDTH => 8,
        CPOL => '0',
        CPHA => '0'
    )
    port map (
        clk => clk,
        rst => spi_clk2.tb.rst,
        nCs => spi_clk2.dut.ncs,
        Sck => spi_clk2.dut.sck,
        MosiA => spi_clk2.dut.mosi_a,
        MosiB => spi_clk2.dut.mosi_b,
        MisoA => spi_clk2.tb.miso_a,
        MisoB => spi_clk2.tb.miso_b,
        WriteOutA => write_out_a_clk2,
        WriteOutB => write_out_b_clk2,
        Transfer => spi_clk2.tb.transfer,
        ReadbackA => readback_a_clk2,
        ReadbackB => readback_b_clk2,
        TransferComplete => spi_clk2.dut.transfer_complete
    );

end architecture sim;
