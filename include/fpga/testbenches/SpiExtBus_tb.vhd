--! \brief Basic testbench for SpiExtBus.vhd
--! Covers reset/idle behavior, 8-bit send/receive behavior, read-ready timing,
--! latched-write behavior, edge-trigger behavior, and reset during transfer.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity SpiExtBus_tb is
end SpiExtBus_tb;

architecture sim of SpiExtBus_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant READ_READY_TIMEOUT_CYCLES : natural := 5000;
    constant MASTER_CLOCK_FREQHZ_FOR_DIV10 : natural := 5000000;
    constant MASTER_CLOCK_FREQHZ_FOR_DIV2 : natural := 1000000;

    type spi_tb_out_t is record
        rst      : std_logic;
        miso     : std_logic;
        transfer : std_logic;
    end record;

    type spi_dut_out_t is record
        ncs        : std_logic;
        sck        : std_logic;
        mosi       : std_logic;
        read_ready : std_logic;
    end record;

    type spi_if_t is record
        tb  : spi_tb_out_t;
        dut : spi_dut_out_t;
    end record;

    signal clk : std_logic := '0';
    signal test_name_display : string(1 to 80);

    signal spi_div10 : spi_if_t;
    signal spi_div2 : spi_if_t;

    signal write_out_div10, readback_div10 : std_logic_vector(7 downto 0) := (others => '0');
    signal write_out_div2, readback_div2 : std_logic_vector(7 downto 0) := (others => '0');

    procedure send_receive_transaction( -- hardcoded for cpol=0, cpha=0, 8-bit transfers
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal write_out_sig : out std_logic_vector;
        signal readback_in : in std_logic_vector;
        constant tx_data : std_logic_vector;
        constant rx_data : std_logic_vector
    ) is
        variable tx_vec : std_logic_vector(write_out_sig'range);
        variable rx_vec : std_logic_vector(readback_in'range);
    begin
        tx_vec := tx_data;
        rx_vec := rx_data;

        spi_tb.transfer <= '0';
        write_out_sig <= tx_vec;
        spi_tb.miso <= rx_vec(rx_vec'high);

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', "nCs high while idle before transfer");
        assert_equal(spi_dut.sck, '1', "Sck idle while waiting for transfer");

        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '0', "nCs low once transfer starts");
        assert_equal(spi_dut.read_ready, '0', "ReadReady low while transfer starts");

        for bit_num in tx_vec'high downto tx_vec'low loop
            wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
            assert_equal(spi_dut.mosi, tx_vec(bit_num), "Master shifted MOSI bit " & integer'image(bit_num) & " during transfer");
            assert_equal(spi_dut.ncs, '0', "nCs stays low during shift of bit " & integer'image(bit_num));
            assert_equal(spi_dut.read_ready, '0', "ReadReady low during shift of bit " & integer'image(bit_num));

            if bit_num /= tx_vec'high then
                spi_tb.miso <= rx_vec(bit_num);
            end if;

            wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
            assert_equal(spi_dut.mosi, tx_vec(bit_num), "Slave sampled MOSI bit " & integer'image(bit_num) & " of TX 0x" & to_hstring(tx_vec));
            assert_equal(spi_dut.ncs, '0', "nCs stays low during sample of bit " & integer'image(bit_num));
            assert_equal(spi_dut.read_ready, '0', "ReadReady low during sample of bit " & integer'image(bit_num));
        end loop;

        wait_until_value(clk_in, spi_dut.read_ready, '1', READ_READY_TIMEOUT_CYCLES, "Timed out waiting for ReadReady after transaction");

        assert_equal(readback_in, rx_vec, "Readback captured expected RX data");
        assert_equal(spi_dut.ncs, '1', "nCs released after transfer completes");
        assert_equal(spi_dut.read_ready, '1', "ReadReady high after transfer completes");
        assert_equal(spi_dut.sck, '1', "Sck returns to idle after transfer completes");

        wait until falling_edge(clk_in);
        assert_equal(spi_dut.read_ready, '1', "ReadReady held high after transfer completes");
        assert_equal(readback_in, rx_vec, "Readback stable after transfer completes");
        assert_equal(spi_dut.ncs, '1', "nCs stays high after transfer completes");
    end procedure;

    procedure run_tests(
        signal clk_in : in std_logic;
        signal spi_tb : out spi_tb_out_t;
        signal spi_dut : in spi_dut_out_t;
        signal write_out_sig : out std_logic_vector;
        signal readback_in : in std_logic_vector;
        signal test_name_sig : out string;
        constant instance_label : string
    ) is
        variable zero_vec : std_logic_vector(write_out_sig'range);
        variable ones_vec : std_logic_vector(readback_in'range);
    begin
        zero_vec := (others => '0');
        ones_vec := (others => '1');

        spi_tb.transfer <= '0';
        spi_tb.rst <= '1';
        spi_tb.miso <= '0';
        write_out_sig <= zero_vec;

        set_test_name(test_name_sig, instance_label & " reset and idle");
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs high in reset");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck idle in reset");

        spi_tb.rst <= '0';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs high after reset");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck idle after reset");

        cycle_clock(clk_in, 10);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs stays high after clocking");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck stays idle after clocking");

        set_test_name(test_name_sig, instance_label & " send only");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_sig, readback_in, x"A5", x"00");

        set_test_name(test_name_sig, instance_label & " send ignores mid-transfer WriteOut change");
        spi_tb.transfer <= '0';
        spi_tb.miso <= '0';
        write_out_sig <= x"A5";
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        write_out_sig <= x"5A";

        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " shifted original MOSI bit 7 before data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled original MOSI bit 7 before data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '0', instance_label & " shifted original MOSI bit 6 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '0', instance_label & " sampled original MOSI bit 6 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " kept latched MOSI bit 5 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled latched MOSI bit 5 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '0', instance_label & " kept latched MOSI bit 4 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '0', instance_label & " sampled latched MOSI bit 4 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '0', instance_label & " kept latched MOSI bit 3 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '0', instance_label & " sampled latched MOSI bit 3 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " kept latched MOSI bit 2 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled latched MOSI bit 2 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '0', instance_label & " kept latched MOSI bit 1 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '0', instance_label & " sampled latched MOSI bit 1 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " kept latched MOSI bit 0 after data change");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled latched MOSI bit 0 after data change");

        spi_tb.transfer <= '0';
        wait_until_value(clk_in, spi_dut.read_ready, '1', READ_READY_TIMEOUT_CYCLES, instance_label & " timed out waiting for ReadReady after mid-transfer WriteOut change");
        assert_equal(readback_in, x"00", instance_label & " mid-transfer data change kept transaction intact");

        set_test_name(test_name_sig, instance_label & " hold Transfer high does not restart");
        cycle_clock(clk_in, 10);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs stays high when Transfer remains high");
        assert_equal(spi_dut.read_ready, '1', instance_label & " ReadReady stays high when Transfer remains high");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck stays idle when Transfer remains high");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', instance_label & " dropping Transfer low does not start transfer");
        assert_equal(spi_dut.read_ready, '1', instance_label & " ReadReady unchanged after dropping Transfer low");

        set_test_name(test_name_sig, instance_label & " busy Transfer toggles do not corrupt transfer");
        spi_tb.transfer <= '0';
        spi_tb.miso <= '0';
        write_out_sig <= x"A5";
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '0';

        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " shifted original MOSI bit 7 before busy toggle");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled original MOSI bit 7 before busy toggle");

        spi_tb.transfer <= '1';
        wait until rising_edge(clk_in);
        assert_equal(spi_dut.ncs, '0', instance_label & " nCs stays low during busy Transfer pulse");
        assert_equal(spi_dut.read_ready, '0', instance_label & " ReadReady stays low during busy Transfer pulse");
        spi_tb.transfer <= '0';

        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '0', instance_label & " shifted original MOSI bit 6 after busy toggle");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '0', instance_label & " sampled original MOSI bit 6 after busy toggle");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " shifted original MOSI bit 5 after busy toggle");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled original MOSI bit 5 after busy toggle");

        wait_until_value(clk_in, spi_dut.read_ready, '1', READ_READY_TIMEOUT_CYCLES, instance_label & " timed out waiting for ReadReady after busy Transfer toggle");
        assert_equal(readback_in, x"00", instance_label & " busy Transfer toggle kept original transaction intact");

        set_test_name(test_name_sig, instance_label & " receive only");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_sig, readback_in, x"00", x"3C");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);

        set_test_name(test_name_sig, instance_label & " send and receive");
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_sig, readback_in, x"96", x"70");

        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);

        set_test_name(test_name_sig, instance_label & " new transfer clears completion");
        write_out_sig <= x"F0";
        spi_tb.miso <= '1';
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.read_ready, '0', instance_label & " new Transfer rising edge clears ReadReady");
        assert_equal(spi_dut.ncs, '0', instance_label & " nCs low during new transfer");

        spi_tb.transfer <= '0';
        wait_until_value(clk_in, spi_dut.read_ready, '1', READ_READY_TIMEOUT_CYCLES, instance_label & " timed out waiting for ReadReady after final transaction");
        assert_equal(readback_in, x"FF", instance_label & " Readback captured final transaction pattern");
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs high after final transaction");
        cycle_clock(clk_in, 8);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs stays high after completion");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck stays idle after completion");
        assert_equal(spi_dut.read_ready, '1', instance_label & " ReadReady stays high after completion");

        set_test_name(test_name_sig, instance_label & " completion handshake shape");
        cycle_clock(clk_in, 12);
        assert_equal(spi_dut.read_ready, '1', instance_label & " ReadReady stays high while idle");
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs stays high while ReadReady is held");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck stays idle while ReadReady is held");
        assert_equal(readback_in, x"FF", instance_label & " Readback stays stable while ReadReady is held");

        write_out_sig <= x"3C";
        spi_tb.miso <= '1';
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.read_ready, '0', instance_label & " ReadReady clears only when a new transfer starts");
        assert_equal(spi_dut.ncs, '0', instance_label & " nCs goes low when ReadReady clears for a new transfer");
        assert_equal(readback_in, x"FF", instance_label & " Readback holds previous completed value during new transfer");

        spi_tb.transfer <= '0';
        cycle_clock(clk_in, 4);
        assert_equal(spi_dut.read_ready, '0', instance_label & " ReadReady stays low during active transfer");

        wait_until_value(clk_in, spi_dut.read_ready, '1', READ_READY_TIMEOUT_CYCLES, instance_label & " timed out waiting for ReadReady during handshake-shape test");
        assert_equal(readback_in, x"FF", instance_label & " Readback captured expected data after completion handshake test");
        cycle_clock(clk_in, 4);
        assert_equal(spi_dut.read_ready, '1', instance_label & " ReadReady returns high and stays high after completion");

        set_test_name(test_name_sig, instance_label & " quick back-to-back requests");
        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_sig, readback_in, x"12", x"34");
        spi_tb.transfer <= '0';
        wait until rising_edge(clk_in);
        send_receive_transaction(clk_in, spi_tb, spi_dut, write_out_sig, readback_in, x"56", x"78");

        set_test_name(test_name_sig, instance_label & " reset during active transfer");
        spi_tb.transfer <= '0';
        spi_tb.miso <= '0';
        write_out_sig <= x"C3";
        wait until falling_edge(clk_in);
        spi_tb.transfer <= '1';
        wait until falling_edge(clk_in);

        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " shifted original MOSI bit 7 before reset");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled original MOSI bit 7 before reset");
        wait until(spi_dut.sck'event and (spi_dut.sck = '0'));
        assert_equal(spi_dut.mosi, '1', instance_label & " shifted original MOSI bit 6 before reset");
        wait until(spi_dut.sck'event and (spi_dut.sck = '1'));
        assert_equal(spi_dut.mosi, '1', instance_label & " sampled original MOSI bit 6 before reset");
        assert_equal(spi_dut.ncs, '0', instance_label & " nCs low before reset during transfer");

        spi_tb.rst <= '1';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs high after reset during transfer");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck idle after reset during transfer");
        assert_equal(spi_dut.read_ready, '0', instance_label & " ReadReady stays low after reset during active transfer");
        assert_equal(readback_in, x"78", instance_label & " reset during transfer does not overwrite last completed Readback");

        spi_tb.transfer <= '0';
        spi_tb.rst <= '0';
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs stays high after releasing reset");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck stays idle after releasing reset");

        reset_dut(clk_in, spi_tb.rst);
        wait until falling_edge(clk_in);
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs high after final reset");
        assert_equal(spi_dut.sck, '1', instance_label & " Sck idle after final reset");

        cycle_clock(clk_in, 40);
        assert_equal(spi_dut.sck, '1', instance_label & " Sck stays idle after clocking");
        assert_equal(spi_dut.ncs, '1', instance_label & " nCs stays high after clocking");
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
        run_tests(clk, spi_div10.tb, spi_div10.dut, write_out_div10, readback_div10, test_name_display, "Divider 10");
        run_tests(clk, spi_div2.tb, spi_div2.dut, write_out_div2, readback_div2, test_name_display, "Divider 2");
        finish;
    end process;

    dut_div10 : entity work.SpiExtBusPorts
    generic map (
        MASTER_CLOCK_FREQHZ => MASTER_CLOCK_FREQHZ_FOR_DIV10
    )
    port map (
        clk => clk,
        rst => spi_div10.tb.rst,
        nCs => spi_div10.dut.ncs,
        Sck => spi_div10.dut.sck,
        Mosi => spi_div10.dut.mosi,
        Miso => spi_div10.tb.miso,
        SpiExtBusWriteOut => write_out_div10,
        WriteSpiExtBus => spi_div10.tb.transfer,
        SpiExtBusReadback => readback_div10,
        SpiExtBusReadReady => spi_div10.dut.read_ready
    );

    dut_div2 : entity work.SpiExtBusPorts
    generic map (
        MASTER_CLOCK_FREQHZ => MASTER_CLOCK_FREQHZ_FOR_DIV2
    )
    port map (
        clk => clk,
        rst => spi_div2.tb.rst,
        nCs => spi_div2.dut.ncs,
        Sck => spi_div2.dut.sck,
        Mosi => spi_div2.dut.mosi,
        Miso => spi_div2.tb.miso,
        SpiExtBusWriteOut => write_out_div2,
        WriteSpiExtBus => spi_div2.tb.transfer,
        SpiExtBusReadback => readback_div2,
        SpiExtBusReadReady => spi_div2.dut.read_ready
    );

end architecture sim;
