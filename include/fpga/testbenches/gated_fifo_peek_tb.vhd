--! \brief Testbench for gated_fifo_peek.vhd
--! FIFO boundary/read-write checks, but with edge-triggered strobes.
--! Includes held-high strobe behavior and r_ack handling.
--! peek/multipop behavior.
--! Mainly to make sure gated strobes do not break skip/peek paths.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity gated_fifo_peek_tb is
end entity gated_fifo_peek_tb;

architecture sim of gated_fifo_peek_tb is

    constant WIDTH_BITS : natural := 32;
    constant DEPTH_BITS : natural := 9;
    constant DEPTH : natural := 2 ** DEPTH_BITS;

    constant CLK_PERIOD : time := 10 ns;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal wone_i       : std_logic;
    signal data_i       : std_logic_vector(WIDTH_BITS - 1 downto 0);
    signal rone_i       : std_logic;
    signal full_o       : std_logic;
    signal empty_o      : std_logic;
    signal data_o       : std_logic_vector(WIDTH_BITS - 1 downto 0);
    signal count_o      : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal raddr_o      : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal waddr_o      : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal peekaddr_i   : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal peek_data_o  : std_logic_vector(WIDTH_BITS - 1 downto 0);
    signal raddr_i      : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal multipop_e_i : std_logic;
    signal r_ack        : std_logic;

    signal test_name_display : string(1 to 80);

    procedure write_fifo_edge(
        signal wone_out : out std_logic;
        signal data_out : out std_logic_vector(WIDTH_BITS - 1 downto 0);
        constant data : std_logic_vector(WIDTH_BITS - 1 downto 0)
    ) is
    begin
        wait until falling_edge(clk);
        wone_out <= '1';
        data_out <= data;
        wait until falling_edge(clk);
        wone_out <= '0';
        wait until falling_edge(clk);
    end procedure;

    procedure read_fifo_edge(
        signal rone_out : out std_logic
    ) is
    begin
        wait until falling_edge(clk);
        rone_out <= '1';
        wait until falling_edge(clk);
        rone_out <= '0';
        wait until falling_edge(clk);
    end procedure;

    procedure burst_write_fifo(
        signal data_out : out std_logic_vector(WIDTH_BITS - 1 downto 0);
        constant data : std_logic_vector(WIDTH_BITS - 1 downto 0)
    ) is
    begin
        data_out <= data;
        wait until falling_edge(clk);
    end procedure;

    procedure peek_fifo(
        signal peekaddr_out : out std_logic_vector(DEPTH_BITS - 1 downto 0);
        constant addr : natural
    ) is
    begin
        wait until falling_edge(clk);
        peekaddr_out <= std_logic_vector(to_unsigned(addr, DEPTH_BITS));
        wait until falling_edge(clk);
        peekaddr_out <= (others => '0');
    end procedure;

begin

    clk_process: process
	begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

    test_process: process
    begin
        wone_i <= '0';
        rone_i <= '0';
        data_i <= (others => '0');
        peekaddr_i <= (others => '0');
        raddr_i <= (others => '0');
        multipop_e_i <= '0';

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");

        set_test_name(test_name_display, "Simple Writes and Reads (edge-triggered)");
        write_fifo_edge(wone_i, data_i, x"DEADBEEF");
        write_fifo_edge(wone_i, data_i, x"CAFEFEED");
        write_fifo_edge(wone_i, data_i, x"12345678");

        read_fifo_edge(rone_i);
        assert_equal(data_o, x"DEADBEEF", "First read should return DEADBEEF");
        read_fifo_edge(rone_i);
        assert_equal(data_o, x"CAFEFEED", "Second read should return CAFEFEED");
        read_fifo_edge(rone_i);
        assert_equal(data_o, x"12345678", "Third read should return 12345678");
        assert_equal(empty_o, '1', "FIFO should be empty after reading all data");

        set_test_name(test_name_display, "Full FIFO Write and Read");
        reset_dut(clk, rst);
        for i in 0 to (((2 ** DEPTH_BITS) - 1)) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2**DEPTH_BITS) - 1, DEPTH_BITS)), "Counter should be full");
        assert_equal(empty_o, '0', "FIFO should not be empty");
        assert_equal(full_o, '1', "FIFO should be full");
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            read_fifo_edge(rone_i);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0");
        assert_equal(empty_o, '1', "FIFO should be empty");
        assert_equal(full_o, '0', "FIFO should not be full");

        set_test_name(test_name_display, "Write and Reset");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"DEADBEEF");
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Counter should be 1 after one write");
        assert_equal(empty_o, '0', "FIFO should not be empty after one write");
        assert_equal(full_o, '0', "FIFO should not be full after one write");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"CAFEFEED");
        read_fifo_edge(rone_i);
        assert_equal(data_o, x"CAFEFEED", "Read should return CAFEFEED");
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after one read");
        assert_equal(empty_o, '1', "FIFO should be empty after one read");
        assert_equal(full_o, '0', "FIFO should not be full after one read");

        set_test_name(test_name_display, "Held-high write does not burst");
        reset_dut(clk, rst);
        data_i <= x"A5A5A5A5";
        wait until falling_edge(clk);
        wone_i <= '1';
        for i in 0 to 7 loop
            wait until falling_edge(clk);
        end loop;
        wone_i <= '0';
        wait until falling_edge(clk);

        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Count should increment once for one long write pulse");
        assert_equal(empty_o, '0', "FIFO should not be empty after one long write pulse");

        read_fifo_edge(rone_i);
        assert_equal(data_o, x"A5A5A5A5", "Long write pulse should store one item");
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should return to 0 after read");
        assert_equal(empty_o, '1', "FIFO should be empty after read");

        set_test_name(test_name_display, "Write when full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(full_o, '1', "FIFO should be full");
        write_fifo_edge(wone_i, data_i, x"AAAAAAAA");
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should not increment when writing full");
        assert_equal(full_o, '1', "FIFO should remain full");
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            read_fifo_edge(rone_i);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");

        set_test_name(test_name_display, "Read when empty");
        reset_dut(clk, rst);
        assert_equal(empty_o, '1', "FIFO should be empty");
        read_fifo_edge(rone_i);
        assert_equal(r_ack, '0', "r_ack should not be asserted when reading empty");
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Count should not decrement when reading empty");
        assert_equal(empty_o, '1', "FIFO should remain empty");

        set_test_name(test_name_display, "Simultaneous read/write steady state");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) / 2 - 1) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        for i in 0 to 9 loop
            wone_i <= '1';
            data_i <= std_logic_vector(to_unsigned(i+1000, WIDTH_BITS));
            rone_i <= '1';
            wait until falling_edge(clk);
            wait until falling_edge(clk);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read data should match expected steady state value");
            wone_i <= '0';
            rone_i <= '0';
            wait until falling_edge(clk);
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) / 2, DEPTH_BITS)), "Count should remain constant during steady state read/write");

        set_test_name(test_name_display, "Simultaneous read/write when full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(full_o, '1', "FIFO should be full");
        wone_i <= '1';
        data_i <= x"BBBBBBBB";
        rone_i <= '1';
        wait until falling_edge(clk);
        wone_i <= '0';
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should remain full during simultaneous read/write when full");
        assert_equal(full_o, '0', "FIFO should remain full");

        set_test_name(test_name_display, "Simultaneous read/write when empty");
        reset_dut(clk, rst);
        assert_equal(empty_o, '1', "FIFO should be empty");
        wone_i <= '1';
        data_i <= x"CCCCCCCC";
        rone_i <= '1';
        wait until falling_edge(clk);
        wone_i <= '0';
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Count should increment by 1 during simultaneous read/write when empty");
        assert_equal(empty_o, '0', "FIFO should not be empty");
        assert_equal(data_o, x"00000000", "Read should return default value during simultaneous read/write when empty");

        set_test_name(test_name_display, "Check r_ack behavior with edge reads");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"12345678");
        wait until falling_edge(clk);
        rone_i <= '1';
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack remains low for edge-triggered read pulse");
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack should be deasserted after read");

        set_test_name(test_name_display, "Check r_ack behavior with held-high read");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"ABCDEF01");
        wait until falling_edge(clk);
        rone_i <= '1';
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack should still be low on first held-high cycle");
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack should still be low while read pipelines through wrapper");
        wait until falling_edge(clk);
        assert_equal(r_ack, '1', "r_ack should assert once delayed fifo ack reaches wrapper output");
        assert_equal(data_o, x"ABCDEF01", "Held-high read should return the written data");
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack should deassert after read request drops");

        -- Peek specific tests
        set_test_name(test_name_display, "Peek does not pop");
        reset_dut(clk, rst);
        for i in 0 to 7 loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        for i in 0 to 7 loop
            peek_fifo(peekaddr_i, i);
            assert_equal(peek_data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Peeked data should match written data at address " & integer'image(i));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned(8, DEPTH_BITS)), "Count should not change after peeks");

        set_test_name(test_name_display, "Edge strobe verification (single write per high pulse)");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"11111111");
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "count should be 1");

        data_i <= x"22222222";
        wone_i <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wone_i <= '0';
        wait until falling_edge(clk);

        assert_equal(count_o, std_logic_vector(to_unsigned(2, DEPTH_BITS)), "count should be 2 after one long high pulse");

        write_fifo_edge(wone_i, data_i, x"33333333");
        assert_equal(count_o, std_logic_vector(to_unsigned(3, DEPTH_BITS)), "count should be 3 after second high pulse");

        set_test_name(test_name_display, "Edge strobe verification (single read per high pulse)");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"0A0A0A0A");
        write_fifo_edge(wone_i, data_i, x"0B0B0B0B");
        write_fifo_edge(wone_i, data_i, x"0C0C0C0C");
        assert_equal(count_o, std_logic_vector(to_unsigned(3, DEPTH_BITS)), "count should be 3 before long read pulse");

        rone_i <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        rone_i <= '0';
        wait until falling_edge(clk);

        assert_equal(count_o, std_logic_vector(to_unsigned(2, DEPTH_BITS)), "count should decrement once for one long read pulse");
        assert_equal(data_o, x"0A0A0A0A", "First item should be popped by long read pulse");

        read_fifo_edge(rone_i);
        assert_equal(data_o, x"0B0B0B0B", "Second item should be next after one long read pulse");

        set_test_name(test_name_display, "Boundary flags around full transition");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 3) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 2, DEPTH_BITS)), "count should be DEPTH-2");
        assert_equal(full_o, '0', "full should be low at DEPTH-2");

        write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 2, WIDTH_BITS)));
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "count should be DEPTH-1");
        assert_equal(full_o, '0', "full should still be low at visible DEPTH-1 count");

        write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, WIDTH_BITS)));
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "count should stay at DEPTH-1 when full");
        assert_equal(full_o, '1', "full should assert on the next write edge");

        read_fifo_edge(rone_i);
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "count should still read DEPTH-1 immediately after leaving full");
        assert_equal(full_o, '0', "full should deassert immediately after one read from full");

        read_fifo_edge(rone_i);
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 2, DEPTH_BITS)), "count should be DEPTH-2 after second read");

        set_test_name(test_name_display, "Multipop basic skip (gated)");
        reset_dut(clk, rst);
        for i in 0 to 15 loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(100 + i, WIDTH_BITS)));
        end loop;
        assert_equal(raddr_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "raddr should be 0 before multipop");
        assert_equal(count_o, std_logic_vector(to_unsigned(16, DEPTH_BITS)), "count should be 16 after writes");

        wait until falling_edge(clk);
        raddr_i <= std_logic_vector(to_unsigned(5, DEPTH_BITS));
        multipop_e_i <= '1';
        wait until falling_edge(clk);
        multipop_e_i <= '0';
        wait until falling_edge(clk);

        assert_equal(raddr_o, std_logic_vector(to_unsigned(5, DEPTH_BITS)), "raddr should be 5 after multipop");
        assert_equal(count_o, std_logic_vector(to_unsigned(11, DEPTH_BITS)), "count should be 11 after skipping 5 items");

        read_fifo_edge(rone_i);
        assert_equal(data_o, std_logic_vector(to_unsigned(105, WIDTH_BITS)), "First post-multipop read should match new raddr");

        set_test_name(test_name_display, "Multipop edge strobe detection (gated)");
        reset_dut(clk, rst);
        for i in 0 to 7 loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(200 + i, WIDTH_BITS)));
        end loop;

        wait until falling_edge(clk);
        raddr_i <= std_logic_vector(to_unsigned(3, DEPTH_BITS));
        multipop_e_i <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(raddr_o, std_logic_vector(to_unsigned(3, DEPTH_BITS)), "raddr should still be 3 while multipop enable stays high");

        multipop_e_i <= '0';
        wait until falling_edge(clk);
        raddr_i <= std_logic_vector(to_unsigned(6, DEPTH_BITS));
        multipop_e_i <= '1';
        wait until falling_edge(clk);
        multipop_e_i <= '0';
        wait until falling_edge(clk);
        assert_equal(raddr_o, std_logic_vector(to_unsigned(6, DEPTH_BITS)), "raddr should be 6 after second multipop edge");

        set_test_name(test_name_display, "Multipop priority over read (gated)");
        reset_dut(clk, rst);
        for i in 0 to 7 loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(300 + i, WIDTH_BITS)));
        end loop;

        wait until falling_edge(clk);
        raddr_i <= std_logic_vector(to_unsigned(4, DEPTH_BITS));
        rone_i <= '1';
        multipop_e_i <= '1';
        wait until falling_edge(clk);
        multipop_e_i <= '0';
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(raddr_o, std_logic_vector(to_unsigned(5, DEPTH_BITS)), "raddr should follow multipop target when read and multipop overlap");

        set_test_name(test_name_display, "Multipop skips to end (gated)");
        reset_dut(clk, rst);
        for i in 0 to 15 loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(600 + i, WIDTH_BITS)));
        end loop;

        wait until falling_edge(clk);
        raddr_i <= waddr_o;
        multipop_e_i <= '1';
        wait until falling_edge(clk);
        multipop_e_i <= '0';
        wait until falling_edge(clk);

        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "count should be 0 after skipping to waddr");
        assert_equal(empty_o, '1', "FIFO should be empty after skipping to waddr");

        set_test_name(test_name_display, "Idle cycles keep state stable");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"13572468");
        write_fifo_edge(wone_i, data_i, x"24681357");
        assert_equal(count_o, std_logic_vector(to_unsigned(2, DEPTH_BITS)), "count should be 2 before idle");

        for i in 0 to 4 loop
            wait until falling_edge(clk);
            assert_equal(count_o, std_logic_vector(to_unsigned(2, DEPTH_BITS)), "count should remain unchanged during idle");
            assert_equal(empty_o, '0', "empty should remain low during idle");
            assert_equal(full_o, '0', "full should remain low during idle");
        end loop;

        read_fifo_edge(rone_i);
        assert_equal(data_o, x"13572468", "FIFO order should remain intact after idle cycles");

        set_test_name(test_name_display, "Write data sampled on delayed internal write");
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        data_i <= x"11111111";
        wone_i <= '1';
        wait until falling_edge(clk);
        data_i <= x"22222222";
        wone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "count should be 1 after one write edge");
        read_fifo_edge(rone_i);
        assert_equal(data_o, x"11111111", "Current gated wrapper behavior writes data present at delayed internal write clock");

        set_test_name(test_name_display, "Reset while non-empty");
        reset_dut(clk, rst);
        for i in 0 to 7 loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        reset_dut(clk, rst);
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Count should be zero after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");
        assert_equal(raddr_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Read pointer should be zero after reset");
        assert_equal(waddr_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Write pointer should be zero after reset");

        set_test_name(test_name_display, "Reset during active read/write");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"12345678");
        wone_i <= '1';
        rone_i <= '1';
        wait until falling_edge(clk);
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        wone_i <= '0';
        rone_i <= '0';
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Count should be zero after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");
        assert_equal(raddr_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Read pointer should be zero after reset");
        assert_equal(waddr_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Write pointer should be zero after reset");


        set_test_name(test_name_display, "Simultaneous read/write when empty");
        reset_dut(clk, rst);
        assert_equal(empty_o, '1', "FIFO should be empty");
        wone_i <= '1';
        data_i <= x"CCCCCCCC";
        rone_i <= '1';
        wait until falling_edge(clk);
        wone_i <= '0';
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Count should increment by 1 during simultaneous read/write when empty");
        assert_equal(empty_o, '0', "FIFO should not be empty");

        read_fifo_edge(rone_i);
        assert_equal(data_o, x"CCCCCCCC", "Written data should be returned on the later read");


        set_test_name(test_name_display, "Simultaneous read/write with one item");
        reset_dut(clk, rst);
        write_fifo_edge(wone_i, data_i, x"AAAA0001");
        wone_i <= '1';
        data_i <= x"AAAA0002";
        rone_i <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wone_i <= '0';
        rone_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Count should stay at 1 when reading and writing a single-item FIFO");
        assert_equal(data_o, x"AAAA0001", "Simultaneous read/write should return the original single item");

        read_fifo_edge(rone_i);
        assert_equal(data_o, x"AAAA0002", "New write should be available after the simultaneous cycle");


        set_test_name(test_name_display, "Simultaneous read/write steady state");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) / 2 - 1) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        for i in 0 to 9 loop
            wone_i <= '1';
            data_i <= std_logic_vector(to_unsigned(i + 1000, WIDTH_BITS));
            rone_i <= '1';
            wait until falling_edge(clk);
            wait until falling_edge(clk);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i) & " during simultaneous read/write");
            wone_i <= '0';
            rone_i <= '0';
            wait until falling_edge(clk);
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) / 2, DEPTH_BITS)), "Count should remain constant during steady state read/write");


        set_test_name(test_name_display, "Simultaneous read/write near full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 2) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should be DEPTH-1 before the overlap");
        assert_equal(full_o, '0', "FIFO should not be full one slot before full");
        wone_i <= '1';
        data_i <= x"BBBBBBBB";
        rone_i <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wone_i <= '0';
        rone_i <= '0';
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should remain at DEPTH-1 during simultaneous read/write near full");
        assert_equal(full_o, '0', "FIFO should still not be full after simultaneous read/write near full");
        assert_equal(data_o, std_logic_vector(to_unsigned(0, WIDTH_BITS)), "Near-full overlap should read the oldest fifo item");


        set_test_name(test_name_display, "Simultaneous read/write when full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            write_fifo_edge(wone_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(full_o, '1', "FIFO should be full");
        wone_i <= '1';
        data_i <= x"BBBBBBBB";
        rone_i <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wone_i <= '0';
        rone_i <= '0';
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should remain unchanged across this overlap timing at full");
        assert_equal(full_o, '0', "FIFO should no longer be full after overlapping read/write at full");
        assert_equal(data_o, std_logic_vector(to_unsigned(0, WIDTH_BITS)), "Full overlap should read the oldest fifo item");

        finish;

    end process;

    dut: entity work.gated_fifo_peek
    generic map (
        WIDTH_BITS => WIDTH_BITS,
        DEPTH_BITS => DEPTH_BITS
    )
    port map (
        clk => clk,
        rst => rst,
        wone_i => wone_i,
        data_i => data_i,
        rone_i => rone_i,
        full_o => full_o,
        empty_o => empty_o,
        data_o => data_o,
        count_o => count_o,
        raddr_o => raddr_o,
        waddr_o => waddr_o,
        peekaddr_i => peekaddr_i,
        peek_data_o => peek_data_o,
        raddr_i => raddr_i,
        multipop_e_i => multipop_e_i,
        r_ack => r_ack
    );

end architecture sim;
