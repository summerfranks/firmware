--! \brief Testbench for PeekRam.vhd
--! Straightforward RAM checks: write/read/overwrite/same-cycle interactions.
--! No-write-when-disabled and reset-after-write behavior included.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.CGraphTypes.all;
use work.tb_utils_pkg.all;

entity PeekRam_tb is
end PeekRam_tb;

architecture sim of PeekRam_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic;
    signal rst : std_logic;

    signal ReadAddress  : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal WriteAddress : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal ByteIn       : std_logic_vector(7 downto 0);
    signal ByteOut      : std_logic_vector(7 downto 0);
    signal WriteReq     : std_logic;

    signal test_name_display : string(1 to 80);

    procedure write_ram(
        signal write_addr_out : out std_logic_vector(PeekRamDepth - 1 downto 0);
        signal byte_in_out    : out std_logic_vector(7 downto 0);
        signal write_req_out  : out std_logic;
        constant addr         : natural;
        constant data         : std_logic_vector(7 downto 0)
    ) is
    begin
        wait until falling_edge(clk);
        write_addr_out <= std_logic_vector(to_unsigned(addr, PeekRamDepth));
        byte_in_out <= data;
        write_req_out <= '1';
        wait until falling_edge(clk);
        write_req_out <= '0';
    end procedure;

    procedure read_ram(
        signal read_addr_out : out std_logic_vector(PeekRamDepth - 1 downto 0);
        constant addr        : natural
    ) is
    begin
        wait until falling_edge(clk);
        read_addr_out <= std_logic_vector(to_unsigned(addr, PeekRamDepth));
        wait until falling_edge(clk);
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
        -- wait until falling_edge(clk);
        ReadAddress  <= (others => '0');
        WriteAddress <= (others => '0');
        ByteIn       <= (others => '0');
        WriteReq     <= '0';

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_equal(ByteOut, x"FF", "ByteOut should be FF during reset");

        set_test_name(test_name_display, "Write and read address 0");
        write_ram(WriteAddress, ByteIn, WriteReq, 0, x"00");
        read_ram(ReadAddress, 0);
        assert_equal(ByteOut, x"00", "Read should return written value at address 0");

        set_test_name(test_name_display, "Single Write and Read");
        write_ram(WriteAddress, ByteIn, WriteReq, 5, x"AB");
        read_ram(ReadAddress, 5);
        assert_equal(ByteOut, x"AB", "Read should return AB from address 5");

        set_test_name(test_name_display, "Write different address");
        write_ram(WriteAddress, ByteIn, WriteReq, 12, x"34");
        read_ram(ReadAddress, 12);
        assert_equal(ByteOut, x"34", "Read should return 34 from address 12");

        set_test_name(test_name_display, "Original address unchanged");
        read_ram(ReadAddress, 5);
        assert_equal(ByteOut, x"AB", "Address 5 should still contain AB");

        set_test_name(test_name_display, "Overwrite address");
        write_ram(WriteAddress, ByteIn, WriteReq, 5, x"CD");
        read_ram(ReadAddress, 5);
        assert_equal(ByteOut, x"CD", "Address 5 should contain overwritten value CD");

        set_test_name(test_name_display, "No write when WriteReq low");
        write_ram(WriteAddress, ByteIn, WriteReq, 20, x"00");
        wait until falling_edge(clk);
        WriteAddress <= std_logic_vector(to_unsigned(20, PeekRamDepth));
        ByteIn <= x"77";
        WriteReq <= '0';
        wait until falling_edge(clk);
        read_ram(ReadAddress, 20);
        assert_equal(ByteOut, x"00", "Address 20 should still be 00 when WriteReq is low");

        set_test_name(test_name_display, "Read and write same cycle");
        wait until falling_edge(clk);
        ReadAddress <= std_logic_vector(to_unsigned(30, PeekRamDepth));
        WriteAddress <= std_logic_vector(to_unsigned(30, PeekRamDepth));
        ByteIn <= x"55";
        WriteReq <= '1';
        wait until falling_edge(clk);
        WriteReq <= '0';
        wait until falling_edge(clk);
        assert_equal(ByteOut, x"55", "Read should return 55 after writing address 30");

        set_test_name(test_name_display, "Full address space");
        for i in 0 to (2 ** PeekRamDepth - 1) loop
            write_ram(WriteAddress, ByteIn, WriteReq, i, std_logic_vector(to_unsigned(i mod 256, 8)));
        end loop;
        for i in 0 to (2 ** PeekRamDepth - 1) loop
            read_ram(ReadAddress, i);
            assert_equal(ByteOut, std_logic_vector(to_unsigned(i mod 256, 8)), "Read should return " & to_string(i) & " from address " & to_string(i));
        end loop;

        set_test_name(test_name_display, "Reset after writes");
        reset_dut(clk, rst);
        assert_equal(ByteOut, x"FF", "ByteOut should return to FF after reset");

        finish;
    end process;

    dut : entity work.PeekRam
    port map (
        clk => clk,
        rst => rst,
        ReadAddress => ReadAddress,
        WriteAddress => WriteAddress,
        ByteIn => ByteIn,
        ByteOut => ByteOut,
        WriteReq => WriteReq
    );

end architecture sim;