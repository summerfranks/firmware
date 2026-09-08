--! \brief Testbench for crc_byte.vhd
--! Quick check that byte-wise CRC combinational logic matches reference vectors.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity crc_byte_tb is
end crc_byte_tb;

architecture sim of crc_byte_tb is

    constant CRC32_POLY : std_logic_vector(31 downto 0) := x"04C11DB7";

    signal crcIn  : std_logic_vector(31 downto 0) := (others => '0');
    signal data   : std_logic_vector(7 downto 0) := (others => '0');
    signal crcOut : std_logic_vector(31 downto 0);

    function crc_next_byte_ref(
        constant crc_in  : std_logic_vector(31 downto 0);
        constant data_in : std_logic_vector(7 downto 0)
    ) return std_logic_vector is
        variable crc_v : std_logic_vector(31 downto 0);
        variable fb    : std_logic;
    begin
        -- Big-endian, left-shifting CRC-32 update for one byte.
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

    procedure check_case(
        signal crc_in_sig   : out std_logic_vector(31 downto 0);
        signal data_in_sig  : out std_logic_vector(7 downto 0);
        signal crc_out_sig  : in std_logic_vector(31 downto 0);
        constant crc_in  : in std_logic_vector(31 downto 0);
        constant data_in : in std_logic_vector(7 downto 0);
        constant msg     : in string
    ) is
        variable expected_crc : std_logic_vector(31 downto 0);
    begin
        expected_crc := crc_next_byte_ref(crc_in, data_in);
        crc_in_sig <= crc_in;
        data_in_sig <= data_in;
        wait for 1 ns;
        assert_equal(crc_out_sig, expected_crc, msg);
    end procedure;

begin

    test_process : process
        variable running_crc : std_logic_vector(31 downto 0);
    begin
        check_case(crcIn, data, crcOut, x"00000000", x"00", "CRC(0x00000000, 0x00)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"00", "CRC(0xFFFFFFFF, 0x00)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"FF", "CRC(0xFFFFFFFF, 0xFF)");
        check_case(crcIn, data, crcOut, x"12345678", x"9A", "CRC(0x12345678, 0x9A)");
        check_case(crcIn, data, crcOut, x"A5A5A5A5", x"5A", "CRC(0xA5A5A5A5, 0x5A)");

        -- Edge cases and weird stuff
        check_case(crcIn, data, crcOut, x"00000000", x"FF", "CRC(0x00000000, 0xFF)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"01", "CRC(0xFFFFFFFF, 0x01)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"80", "CRC(0xFFFFFFFF, 0x80)");
        check_case(crcIn, data, crcOut, x"80000000", x"00", "CRC(0x80000000, 0x00)");
        check_case(crcIn, data, crcOut, x"00000001", x"00", "CRC(0x00000001, 0x00)");
        check_case(crcIn, data, crcOut, x"7FFFFFFF", x"AA", "CRC(0x7FFFFFFF, 0xAA)");
        check_case(crcIn, data, crcOut, x"80000001", x"55", "CRC(0x80000001, 0x55)");
        check_case(crcIn, data, crcOut, x"AAAAAAAA", x"AA", "CRC(0xAAAAAAAA, 0xAA)");
        check_case(crcIn, data, crcOut, x"55555555", x"55", "CRC(0x55555555, 0x55)");
        check_case(crcIn, data, crcOut, x"AAAAAAAA", x"55", "CRC(0xAAAAAAAA, 0x55)");
        check_case(crcIn, data, crcOut, x"55555555", x"AA", "CRC(0x55555555, 0xAA)");
        check_case(crcIn, data, crcOut, x"F0F0F0F0", x"0F", "CRC(0xF0F0F0F0, 0x0F)");
        check_case(crcIn, data, crcOut, x"0F0F0F0F", x"F0", "CRC(0x0F0F0F0F, 0xF0)");

        -- 1 Inch right
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"01", "CRC(0xFFFFFFFF, walking-1 bit0)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"02", "CRC(0xFFFFFFFF, walking-1 bit1)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"04", "CRC(0xFFFFFFFF, walking-1 bit2)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"08", "CRC(0xFFFFFFFF, walking-1 bit3)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"10", "CRC(0xFFFFFFFF, walking-1 bit4)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"20", "CRC(0xFFFFFFFF, walking-1 bit5)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"40", "CRC(0xFFFFFFFF, walking-1 bit6)");
        check_case(crcIn, data, crcOut, x"FFFFFFFF", x"80", "CRC(0xFFFFFFFF, walking-1 bit7)");

        -- 0 inch right
        check_case(crcIn, data, crcOut, x"00000000", x"FE", "CRC(0x00000000, walking-0 bit0)");
        check_case(crcIn, data, crcOut, x"00000000", x"FD", "CRC(0x00000000, walking-0 bit1)");
        check_case(crcIn, data, crcOut, x"00000000", x"FB", "CRC(0x00000000, walking-0 bit2)");
        check_case(crcIn, data, crcOut, x"00000000", x"F7", "CRC(0x00000000, walking-0 bit3)");
        check_case(crcIn, data, crcOut, x"00000000", x"EF", "CRC(0x00000000, walking-0 bit4)");
        check_case(crcIn, data, crcOut, x"00000000", x"DF", "CRC(0x00000000, walking-0 bit5)");
        check_case(crcIn, data, crcOut, x"00000000", x"BF", "CRC(0x00000000, walking-0 bit6)");
        check_case(crcIn, data, crcOut, x"00000000", x"7F", "CRC(0x00000000, walking-0 bit7)");

        -- Real Streaming data
        running_crc := x"FFFFFFFF";
        check_case(crcIn, data, crcOut, running_crc, x"48", "Stream byte 'H'");
        running_crc := crc_next_byte_ref(running_crc, x"48");
        check_case(crcIn, data, crcOut, running_crc, x"49", "Stream byte 'I'");
        running_crc := crc_next_byte_ref(running_crc, x"49");
        check_case(crcIn, data, crcOut, running_crc, x"21", "Stream byte '!'");
        running_crc := crc_next_byte_ref(running_crc, x"21");

        running_crc := x"FFFFFFFF";
        check_case(crcIn, data, crcOut, running_crc, x"31", "Stream byte '1'");
        running_crc := crc_next_byte_ref(running_crc, x"31");
        check_case(crcIn, data, crcOut, running_crc, x"32", "Stream byte '2'");
        running_crc := crc_next_byte_ref(running_crc, x"32");
        check_case(crcIn, data, crcOut, running_crc, x"33", "Stream byte '3'");
        running_crc := crc_next_byte_ref(running_crc, x"33");
        check_case(crcIn, data, crcOut, running_crc, x"34", "Stream byte '4'");
        running_crc := crc_next_byte_ref(running_crc, x"34");
        check_case(crcIn, data, crcOut, running_crc, x"35", "Stream byte '5'");
        running_crc := crc_next_byte_ref(running_crc, x"35");
        check_case(crcIn, data, crcOut, running_crc, x"36", "Stream byte '6'");
        running_crc := crc_next_byte_ref(running_crc, x"36");
        check_case(crcIn, data, crcOut, running_crc, x"37", "Stream byte '7'");
        running_crc := crc_next_byte_ref(running_crc, x"37");
        check_case(crcIn, data, crcOut, running_crc, x"38", "Stream byte '8'");
        running_crc := crc_next_byte_ref(running_crc, x"38");
        check_case(crcIn, data, crcOut, running_crc, x"39", "Stream byte '9'");
        running_crc := crc_next_byte_ref(running_crc, x"39");

        running_crc := x"FFFFFFFF";
        check_case(crcIn, data, crcOut, running_crc, x"00", "Zero stream byte 0");
        running_crc := crc_next_byte_ref(running_crc, x"00");
        check_case(crcIn, data, crcOut, running_crc, x"00", "Zero stream byte 1");
        running_crc := crc_next_byte_ref(running_crc, x"00");
        check_case(crcIn, data, crcOut, running_crc, x"00", "Zero stream byte 2");
        running_crc := crc_next_byte_ref(running_crc, x"00");
        check_case(crcIn, data, crcOut, running_crc, x"00", "Zero stream byte 3");
        running_crc := crc_next_byte_ref(running_crc, x"00");

        running_crc := x"00000000";
        check_case(crcIn, data, crcOut, running_crc, x"FF", "Ones stream byte 0");
        running_crc := crc_next_byte_ref(running_crc, x"FF");
        check_case(crcIn, data, crcOut, running_crc, x"FF", "Ones stream byte 1");
        running_crc := crc_next_byte_ref(running_crc, x"FF");
        check_case(crcIn, data, crcOut, running_crc, x"FF", "Ones stream byte 2");
        running_crc := crc_next_byte_ref(running_crc, x"FF");
        check_case(crcIn, data, crcOut, running_crc, x"FF", "Ones stream byte 3");
        running_crc := crc_next_byte_ref(running_crc, x"FF");

        running_crc := x"A5A5A5A5";
        check_case(crcIn, data, crcOut, running_crc, x"AA", "Alt stream byte 0");
        running_crc := crc_next_byte_ref(running_crc, x"AA");
        check_case(crcIn, data, crcOut, running_crc, x"55", "Alt stream byte 1");
        running_crc := crc_next_byte_ref(running_crc, x"55");
        check_case(crcIn, data, crcOut, running_crc, x"AA", "Alt stream byte 2");
        running_crc := crc_next_byte_ref(running_crc, x"AA");
        check_case(crcIn, data, crcOut, running_crc, x"55", "Alt stream byte 3");
        running_crc := crc_next_byte_ref(running_crc, x"55");
        finish;
    end process;

    dut : entity work.crc_byte
        port map (
            crcIn  => crcIn,
            data   => data,
            crcOut => crcOut
        );
end architecture sim;
