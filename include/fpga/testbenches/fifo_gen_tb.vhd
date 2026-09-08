--! \brief Testbench for fifo_gen.vhd
--! Core FIFO baseline: reset, normal read/write, burst traffic, and boundaries.
--! Simultaneous read/write is exercised across empty, steady-state, near-full, and full.
--! r_ack timing and reset behavior during active traffic are checked.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity fifo_gen_tb is
end entity fifo_gen_tb;

architecture sim of fifo_gen_tb is

    constant WIDTH_BITS : natural := 32;
    constant DEPTH_BITS : natural := 9;
    constant DEPTH : natural := 2**DEPTH_BITS;

    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic;
    signal rst      : std_logic;
    signal we_i     : std_logic;
    signal data_i   : std_logic_vector(WIDTH_BITS - 1 downto 0);
    signal re_i     : std_logic;
    signal full_o   : std_logic;
    signal empty_o  : std_logic;
    signal data_o   : std_logic_vector(WIDTH_BITS - 1 downto 0);
    signal count_o  : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal r_ack    : std_logic;
    
    signal test_name_display : string(1 to 80);

    procedure read_fifo(
        signal re_out : out std_logic
    ) is
    begin
        wait until falling_edge(clk);
        re_out <= '1';
        wait until falling_edge(clk);
        re_out <= '0';
    end procedure;

    procedure write_fifo(
        signal we_out : out std_logic;
        signal data_out : out std_logic_vector(WIDTH_BITS - 1 downto 0);
        constant data : std_logic_vector(WIDTH_BITS - 1 downto 0)
    ) is
    begin
        wait until falling_edge(clk);
        we_out <= '1';
        data_out <= data;
        wait until falling_edge(clk);
        we_out <= '0';
    end procedure;

    procedure burst_write_fifo(
        signal data_out : out std_logic_vector(WIDTH_BITS - 1 downto 0);
        constant data : std_logic_vector(WIDTH_BITS - 1 downto 0)
    ) is
    begin
        data_out <= data;
        wait until falling_edge(clk);
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
        we_i <= '0';
        re_i <= '0';
        data_i <= (others => '0');

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");
        assert_equal(r_ack, '0', "r_ack should be 0 after reset");


        set_test_name(test_name_display, "Simple Writes and Reads");
        write_fifo(we_i, data_i, x"DEADBEEF");
        write_fifo(we_i, data_i, x"CAFEFEED");
        write_fifo(we_i, data_i, x"12345678");

        read_fifo(re_i);
        assert_equal(data_o, x"DEADBEEF", "First read should return DEADBEEF");
        
        read_fifo(re_i);
        assert_equal(data_o, x"CAFEFEED", "Second read should return CAFEFEED");
        
        read_fifo(re_i);
        assert_equal(data_o, x"12345678", "Third read should return 12345678");

        assert_equal(empty_o, '1', "FIFO should be empty after reading all data");


        set_test_name(test_name_display, "Full FIFO Write and Read");
        for i in 0 to (((2 ** DEPTH_BITS) - 1)) loop
            write_fifo(we_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;

        assert_equal(count_o, std_logic_vector(to_unsigned((2**DEPTH_BITS) - 1, DEPTH_BITS)), "Counter should be 0 after reset");
        assert_equal(empty_o, '0', "FIFO should be empty after reset");
        assert_equal(full_o, '1', "FIFO should not be full after reset");

        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            read_fifo(re_i);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i));
        end loop;

        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");


        set_test_name(test_name_display, "Write and Reset");
        write_fifo(we_i, data_i, x"DEADBEEF");
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Counter should be 1 after one write");
        assert_equal(empty_o, '0', "FIFO should not be empty after one write");
        assert_equal(full_o, '0', "FIFO should not be full after one write");

        reset_dut(clk, rst);

        write_fifo(we_i, data_i, x"CAFEFEED");

        read_fifo(re_i);
        assert_equal(data_o, x"CAFEFEED", "Read should return CAFEFEED");
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after one read");
        assert_equal(empty_o, '1', "FIFO should be empty after one read");
        assert_equal(full_o, '0', "FIFO should not be full after one read");

        set_test_name(test_name_display, "Burst Write and Read");
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        we_i <= '1';
        for i in 0 to (((2 ** DEPTH_BITS) - 1)) loop
            burst_write_fifo(data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        we_i <= '0';

        assert_equal(count_o, std_logic_vector(to_unsigned((2**DEPTH_BITS) - 1, DEPTH_BITS)), "Counter should be full after burst writing");
        assert_equal(empty_o, '0', "FIFO should be not empty after burst writing");
        assert_equal(full_o, '1', "FIFO should be full after burst writing");
        wait until falling_edge(clk);

        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            re_i <= '1';
            wait until falling_edge(clk);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i));
        end loop;
        wait until falling_edge(clk);
        re_i <= '0';

        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 burst reading");
        assert_equal(empty_o, '1', "FIFO should be empty after burst reading");
        assert_equal(full_o, '0', "FIFO should not be full burst reset");


        wait until falling_edge(clk);
        set_test_name(test_name_display, "Write when full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            write_fifo(we_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(full_o, '1', "FIFO should be full");
        write_fifo(we_i, data_i, x"AAAAAAAA");
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should not increment when writing full");
        assert_equal(full_o, '1', "FIFO should remain full");

        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            read_fifo(re_i);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i));
        end loop;

        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Counter should be 0 after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");


        set_test_name(test_name_display, "Read when empty");
        reset_dut(clk, rst);
        assert_equal(empty_o, '1', "FIFO should be empty");
        read_fifo(re_i);
        assert_equal(r_ack, '0', "r_ack should not be asserted when reading empty");
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Count should not decrement when reading empty");
        assert_equal(empty_o, '1', "FIFO should remain empty");


        set_test_name(test_name_display, "Check r_ack timing");
        reset_dut(clk, rst);
        write_fifo(we_i, data_i, x"12345678");
        assert_equal(r_ack, '0', "r_ack should stay low before read");
        wait until falling_edge(clk);
        re_i <= '1';
        wait until falling_edge(clk);
        assert_equal(r_ack, '1', "r_ack should be asserted for one cycle after read");
        re_i <= '0';
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack should be deasserted after read");


        set_test_name(test_name_display, "Check r_ack on back-to-back reads");
        reset_dut(clk, rst);
        write_fifo(we_i, data_i, x"11111111");
        write_fifo(we_i, data_i, x"22222222");
        wait until falling_edge(clk);
        re_i <= '1';
        wait until falling_edge(clk);
        assert_equal(r_ack, '1', "r_ack should assert on first read");
        wait until falling_edge(clk);
        assert_equal(r_ack, '1', "r_ack should stay asserted while second read is accepted");
        wait until falling_edge(clk);
        assert_equal(r_ack, '0', "r_ack should drop once fifo is empty");
        re_i <= '0';


        set_test_name(test_name_display, "Reset while non-empty");
        reset_dut(clk, rst);
        for i in 0 to 7 loop
            write_fifo(we_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        reset_dut(clk, rst);
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Count should be zero after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");


        set_test_name(test_name_display, "Reset during active read/write");
        reset_dut(clk, rst);
        write_fifo(we_i, data_i, x"12345678");
        we_i <= '1';
        re_i <= '1';
        wait until falling_edge(clk);
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        we_i <= '0';
        re_i <= '0';
        assert_equal(count_o, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "Count should be zero after reset");
        assert_equal(empty_o, '1', "FIFO should be empty after reset");
        assert_equal(full_o, '0', "FIFO should not be full after reset");


        set_test_name(test_name_display, "Simultaneous read/write when empty");
        reset_dut(clk, rst);
        assert_equal(empty_o, '1', "FIFO should be empty");
        we_i <= '1';
        data_i <= x"CCCCCCCC";
        re_i <= '1';
        wait until falling_edge(clk);
        we_i <= '0';
        re_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Count should increment by 1 during simultaneous read/write when empty");
        assert_equal(empty_o, '0', "FIFO should not be empty");
        assert_equal(data_o, x"00000000", "Read should return default value during simultaneous read/write when empty");

        read_fifo(re_i);
        assert_equal(data_o, x"CCCCCCCC", "Simultaneous empty overlap should retain the written data");


        set_test_name(test_name_display, "Simultaneous read/write with one item");
        reset_dut(clk, rst);
        write_fifo(we_i, data_i, x"AAAA0001");
        we_i <= '1';
        data_i <= x"AAAA0002";
        re_i <= '1';
        wait until falling_edge(clk);
        we_i <= '0';
        re_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "Count should stay at 1 when reading and writing a single-item FIFO");
        assert_equal(data_o, x"AAAA0001", "Simultaneous read/write should return the original single item");

        read_fifo(re_i);
        assert_equal(data_o, x"AAAA0002", "New write should be available after the simultaneous cycle");


        set_test_name(test_name_display, "Simultaneous read/write steady state");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) / 2 - 1) loop
            write_fifo(we_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        for i in 0 to 9 loop
            we_i <= '1';
            data_i <= std_logic_vector(to_unsigned(i+1000, WIDTH_BITS));
            re_i <= '1';
            wait until falling_edge(clk);
            assert_equal(data_o, std_logic_vector(to_unsigned(i, WIDTH_BITS)), "Read fifo " & integer'image(i) & " during simultaneous read/write");
            we_i <= '0';
            re_i <= '0';
            wait until falling_edge(clk);
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) / 2, DEPTH_BITS)), "Count should remain constant during steady state read/write");


        set_test_name(test_name_display, "Simultaneous read/write near full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 2) loop
            write_fifo(we_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should be DEPTH-1 before the overlap");
        assert_equal(full_o, '0', "FIFO should not be full one slot before full");
        we_i <= '1';
        data_i <= x"BBBBBBBB";
        re_i <= '1';
        wait until falling_edge(clk);
        we_i <= '0';
        re_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should remain at DEPTH-1 during simultaneous read/write near full");
        assert_equal(full_o, '0', "FIFO should still not be full after simultaneous read/write near full");
        assert_equal(data_o, std_logic_vector(to_unsigned(0, WIDTH_BITS)), "Near-full overlap should read the oldest fifo item");


        set_test_name(test_name_display, "Simultaneous read/write when full");
        reset_dut(clk, rst);
        for i in 0 to ((2 ** DEPTH_BITS) - 1) loop
            write_fifo(we_i, data_i, std_logic_vector(to_unsigned(i, WIDTH_BITS)));
        end loop;
        assert_equal(full_o, '1', "FIFO should be full");
        we_i <= '1';
        data_i <= x"BBBBBBBB";
        re_i <= '1';
        wait until falling_edge(clk);
        we_i <= '0';
        re_i <= '0';
        wait until falling_edge(clk);
        assert_equal(count_o, std_logic_vector(to_unsigned((2 ** DEPTH_BITS) - 1, DEPTH_BITS)), "Count should remain unchanged across this overlap timing at full");
        assert_equal(full_o, '0', "FIFO should no longer be full after overlapping read/write at full");
        assert_equal(data_o, std_logic_vector(to_unsigned(0, WIDTH_BITS)), "Full overlap should read the oldest fifo item");
    
        finish;

    end process;

    dut: entity work.fifo
    generic map (
        WIDTH_BITS => WIDTH_BITS,
        DEPTH_BITS => DEPTH_BITS
    )
    port map (
        clk => clk,
        rst => rst,
        we_i => we_i,
        data_i => data_i,
        re_i => re_i,
        full_o => full_o,
        empty_o => empty_o,
        data_o => data_o,
        count_o => count_o,
        r_ack => r_ack
    );


end architecture sim;