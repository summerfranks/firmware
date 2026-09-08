--! \brief Testbench for CrcFifo.vhd
--! CRC over varied patterns (zeros, ones, PRNG, address slices).
--! Full-range sweep plus back-to-back runs without reset.
--! Reset handling is tested, including reset during active CRC computation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity crc_fifo_tb is
end crc_fifo_tb;

architecture sim of crc_fifo_tb is

    constant DEPTH_BITS : natural := 10;
    constant DEPTH : natural := 2**DEPTH_BITS;

    constant CRC32_POLY : std_logic_vector(31 downto 0) := x"04C11DB7";
    constant CRC_INIT_STATE : std_logic_vector(31 downto 0) := x"FFFFFFFF";
    constant CRC_INIT_STATE_ALT : std_logic_vector(31 downto 0) := x"00000000";

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic;
    signal rst : std_logic;
    signal FifoStartAddr : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal FifoEndAddr : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal FifoPeekAddr : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal FifoPeekData : std_logic_vector(7 downto 0);
    signal StartCrc : std_logic;
    signal Crc : std_logic_vector(31 downto 0);
    signal CrcComplete : std_logic;
    signal FifoPeekAddr_alt : std_logic_vector(DEPTH_BITS - 1 downto 0);
    signal Crc_alt : std_logic_vector(31 downto 0);
    signal CrcComplete_alt : std_logic;

    signal test_name_display : string(1 to 80);

    function crc_next_byte(
        constant crc_in  : std_logic_vector(31 downto 0);
        constant data_in : std_logic_vector(7 downto 0)
    ) return std_logic_vector is
        variable crc_v : std_logic_vector(31 downto 0);
        variable fb    : std_logic;
    begin
        crc_v := crc_in;
        for i in 7 downto 0 loop
            fb := crc_v(31) xor data_in(i);
            crc_v := crc_v(30 downto 0) & '0';
            if fb = '1' then
                crc_v := crc_v xor CRC32_POLY;
            end if;
        end loop;
        return crc_v;
    end function;

begin

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    test_process : process
        variable expected_crc : std_logic_vector(31 downto 0);
        variable expected_crc_alt : std_logic_vector(31 downto 0);
    begin

        set_test_name(test_name_display, "Reset");
        rst <= '1';
        FifoStartAddr <= (others => '0');
        FifoEndAddr <= std_logic_vector(to_unsigned(DEPTH - 1, DEPTH_BITS));
        FifoPeekData <= (others => '0');
        StartCrc <= '0';
        rst <= '0';

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_equal(FifoPeekAddr, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "FifoPeekAddr should be 0 after reset");
        assert_equal(Crc, CRC_INIT_STATE, "Crc should match CRC_INIT_STATE after reset");
        assert_equal(CrcComplete, '1', "CrcComplete should be 1 after reset");
        assert_equal(FifoPeekAddr_alt, std_logic_vector(to_unsigned(0, DEPTH_BITS)), "FifoPeekAddr_alt should be 0 after reset");
        assert_equal(Crc_alt, CRC_INIT_STATE_ALT, "Crc_alt should match CRC_INIT_STATE_ALT after reset");
        assert_equal(CrcComplete_alt, '1', "CrcComplete_alt should be 1 after reset");

        set_test_name(test_name_display, "ALT init short CRC 0..1 addr mod");
        FifoStartAddr <= std_logic_vector(to_unsigned(0, DEPTH_BITS));
        FifoEndAddr <= std_logic_vector(to_unsigned(1, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"00";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        FifoPeekData <= std_logic_vector(to_unsigned(0, 8));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(1, 8));
        wait until falling_edge(clk);
        expected_crc_alt := CRC_INIT_STATE_ALT;
        expected_crc_alt := crc_next_byte(expected_crc_alt, x"00");
        expected_crc_alt := crc_next_byte(expected_crc_alt, x"01");
        assert_equal(Crc_alt, expected_crc_alt, "ALT CRC 0..1 addr mod");
        assert_equal(FifoPeekAddr_alt, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "ALT peek end 1");

        set_test_name(test_name_display, "ALT init single byte 42");
        FifoStartAddr <= std_logic_vector(to_unsigned(42, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(42, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"2A";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete_alt = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr_alt)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc_alt := CRC_INIT_STATE_ALT;
        expected_crc_alt := crc_next_byte(expected_crc_alt, x"2A");
        assert_equal(Crc_alt, expected_crc_alt, "ALT CRC single 42");


        set_test_name(test_name_display, "Short CRC 0..1 addr mod");
        FifoStartAddr <= std_logic_vector(to_unsigned(0, DEPTH_BITS));
        FifoEndAddr <= std_logic_vector(to_unsigned(1, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"00";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        FifoPeekData <= std_logic_vector(to_unsigned(0, 8));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(1, 8));
        wait until falling_edge(clk);
        expected_crc := CRC_INIT_STATE;
        expected_crc := crc_next_byte(expected_crc, x"00");
        expected_crc := crc_next_byte(expected_crc, x"01");
        assert_equal(Crc, expected_crc, "CRC 0..1 addr mod");
        assert_equal(FifoPeekAddr, std_logic_vector(to_unsigned(1, DEPTH_BITS)), "peek end 1");


        set_test_name(test_name_display, "Single byte 42..42 addr mod");
        FifoStartAddr <= std_logic_vector(to_unsigned(42, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(42, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"2A";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        expected_crc := crc_next_byte(expected_crc, x"2A");
        assert_equal(Crc, expected_crc, "CRC single 42");

        set_test_name(test_name_display, "Single byte 500..500 all zeros");
        FifoStartAddr <= std_logic_vector(to_unsigned(500, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(500, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"00";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= x"00";
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        expected_crc := crc_next_byte(expected_crc, x"00");
        assert_equal(Crc, expected_crc, "CRC single zero byte");


        set_test_name(test_name_display, "Middle slice 100..110 addr mod");
        FifoStartAddr <= std_logic_vector(to_unsigned(100, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(110, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(100 mod 256, 8));
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 100 to 110 loop
            expected_crc := crc_next_byte(expected_crc, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        assert_equal(Crc, expected_crc, "CRC 100..110");
        assert_equal(FifoPeekAddr, std_logic_vector(to_unsigned(110, DEPTH_BITS)), "peek 110");


        set_test_name(test_name_display, "Slice 200..205 incrementing relative");
        FifoStartAddr <= std_logic_vector(to_unsigned(200, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(205, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"00";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned((to_integer(unsigned(FifoPeekAddr)) - 200) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 0 to 5 loop
            expected_crc := crc_next_byte(expected_crc, std_logic_vector(to_unsigned(i, 8)));
        end loop;
        assert_equal(Crc, expected_crc, "CRC 200..205 seq");


        set_test_name(test_name_display, "All zeros 0..50");
        FifoStartAddr <= std_logic_vector(to_unsigned(0, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(50, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"00";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= x"00";
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 0 to 50 loop
            expected_crc := crc_next_byte(expected_crc, x"00");
        end loop;
        assert_equal(Crc, expected_crc, "CRC all zero run");


        set_test_name(test_name_display, "All ones 5..15");
        FifoStartAddr <= std_logic_vector(to_unsigned(5, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(15, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"FF";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= x"FF";
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for ai in 5 to 15 loop
            expected_crc := crc_next_byte(expected_crc, x"FF");
        end loop;
        assert_equal(Crc, expected_crc, "CRC all ones run");


        set_test_name(test_name_display, "PRNG 50..60");
        FifoStartAddr <= std_logic_vector(to_unsigned(50, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(60, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned((50 * 131 + 17) mod 256, 8));
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned((to_integer(unsigned(FifoPeekAddr)) * 131 + 17) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 50 to 60 loop
            expected_crc := crc_next_byte(
                expected_crc,
                std_logic_vector(to_unsigned((i * 131 + 17) mod 256, 8))
            );
        end loop;
        assert_equal(Crc, expected_crc, "CRC PRNG");


        set_test_name(test_name_display, "Full CRC 0..DEPTH-1 addr mod");
        reset_dut(clk, rst);
        wait until falling_edge(clk);
        FifoStartAddr <= std_logic_vector(to_unsigned(0, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(DEPTH - 1, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= x"00";
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 0 to DEPTH - 1 loop
            expected_crc := crc_next_byte(expected_crc, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        assert_equal(Crc, expected_crc, "CRC full range");
        assert_equal(FifoPeekAddr, std_logic_vector(to_unsigned(DEPTH - 1, DEPTH_BITS)), "peek DEPTH-1");


        set_test_name(test_name_display, "Back-to-back 10..12 then 20..22");
        FifoStartAddr <= std_logic_vector(to_unsigned(10, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(12, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(10 mod 256, 8));
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 10 to 12 loop
            expected_crc := crc_next_byte(expected_crc, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        assert_equal(Crc, expected_crc, "back-to-back first CRC");

        FifoStartAddr <= std_logic_vector(to_unsigned(20, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(22, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(20 mod 256, 8));
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 20 to 22 loop
            expected_crc := crc_next_byte(expected_crc, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        assert_equal(Crc, expected_crc, "back-to-back second CRC");

        set_test_name(test_name_display, "Reset in middle of CRC");
        FifoStartAddr <= std_logic_vector(to_unsigned(30, DEPTH_BITS));
        FifoEndAddr   <= std_logic_vector(to_unsigned(32, DEPTH_BITS));
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(30 mod 256, 8));
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        rst <= '1';
        wait until falling_edge(clk);
        rst <= '0';
        wait until falling_edge(clk);
        FifoPeekData <= std_logic_vector(to_unsigned(30 mod 256, 8));
        StartCrc     <= '1';
        wait until falling_edge(clk);
        StartCrc     <= '0';
        while CrcComplete = '0' loop
            FifoPeekData <= std_logic_vector(to_unsigned(to_integer(unsigned(FifoPeekAddr)) mod 256, 8));
            wait until falling_edge(clk);
        end loop;
        expected_crc := CRC_INIT_STATE;
        for i in 30 to 32 loop
            expected_crc := crc_next_byte(expected_crc, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        assert_equal(Crc, expected_crc, "reset in middle of CRC");

        finish;
    end process;

    dut : entity work.CrcFifo
        generic map (
            DEPTH_BITS => DEPTH_BITS,
            CRC_INIT_STATE => CRC_INIT_STATE
        )
        port map (
            clk => clk,
            rst => rst,
            FifoStartAddr => FifoStartAddr,
            FifoEndAddr => FifoEndAddr,
            FifoPeekAddr => FifoPeekAddr,
            FifoPeekData => FifoPeekData,
            StartCrc => StartCrc,
            Crc => Crc,
            CrcComplete => CrcComplete
        );

    dut_alt : entity work.CrcFifo
        generic map (
            DEPTH_BITS => DEPTH_BITS,
            CRC_INIT_STATE => CRC_INIT_STATE_ALT
        )
        port map (
            clk => clk,
            rst => rst,
            FifoStartAddr => FifoStartAddr,
            FifoEndAddr => FifoEndAddr,
            FifoPeekAddr => FifoPeekAddr_alt,
            FifoPeekData => FifoPeekData,
            StartCrc => StartCrc,
            Crc => Crc_alt,
            CrcComplete => CrcComplete_alt
        );

end architecture sim;