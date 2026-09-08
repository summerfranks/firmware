--! \brief Testbench for PatternFinder.vhd
--! Steps through match/mismatch cases for the pattern detector.
--! Makes sure it recovers correctly after a bad sequence.
--! Also checks reset behavior mid-stream.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
library work;
use work.tb_utils_pkg.all;

entity PatternFinder_tb is
end PatternFinder_tb;

architecture sim of PatternFinder_tb is

    constant CLK_PERIOD : time := 10 ns;

    constant PAT0 : std_logic_vector(7 downto 0) := x"AA";
    constant PAT1 : std_logic_vector(7 downto 0) := x"BB";
    constant PAT2 : std_logic_vector(7 downto 0) := x"CC";
    constant PAT3 : std_logic_vector(7 downto 0) := x"DD";

    signal clk      : std_logic;
    signal rst      : std_logic;
    signal ByteIn   : std_logic_vector(7 downto 0);
    signal WriteReq : std_logic;
    signal Found    : std_logic;

    signal test_name_display : string(1 to 80);

    procedure write_strobe(
        signal byte_in_out  : out std_logic_vector(7 downto 0);
        signal write_req_out : out std_logic;
        constant data        : std_logic_vector(7 downto 0)
    ) is
    begin
        wait until falling_edge(clk);
        byte_in_out <= data;
        write_req_out <= '1';
        wait until falling_edge(clk);
        write_req_out <= '0';
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
        ByteIn   <= (others => '0');
        WriteReq <= '0';

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_equal(Found, '0', "Found should be 0 after reset");

        set_test_name(test_name_display, "Full pattern match");
        write_strobe(ByteIn, WriteReq, PAT0);
        write_strobe(ByteIn, WriteReq, PAT1);
        write_strobe(ByteIn, WriteReq, PAT2);
        write_strobe(ByteIn, WriteReq, PAT3);
        assert_equal(Found, '1', "Found should assert after full sequence");

        set_test_name(test_name_display, "Next strobe clears Found in state 00");
        write_strobe(ByteIn, WriteReq, x"00");
        assert_equal(Found, '0', "Found should clear on next write in idle state");

        set_test_name(test_name_display, "Wrong second byte");
        write_strobe(ByteIn, WriteReq, PAT0);
        write_strobe(ByteIn, WriteReq, x"FF");
        write_strobe(ByteIn, WriteReq, PAT2);
        write_strobe(ByteIn, WriteReq, PAT3);
        assert_equal(Found, '0', "Found should stay 0 when sequence breaks");

        set_test_name(test_name_display, "Recover after break");
        write_strobe(ByteIn, WriteReq, PAT0);
        write_strobe(ByteIn, WriteReq, PAT1);
        write_strobe(ByteIn, WriteReq, PAT2);
        write_strobe(ByteIn, WriteReq, PAT3);
        assert_equal(Found, '1', "Found after valid sequence following bad run");

        set_test_name(test_name_display, "Reset during sequence");
        write_strobe(ByteIn, WriteReq, PAT0);
        write_strobe(ByteIn, WriteReq, PAT1);
        write_strobe(ByteIn, WriteReq, PAT2);
        write_strobe(ByteIn, WriteReq, PAT3);
        reset_dut(clk, rst);
        assert_equal(Found, '0', "Found should stay 0 after reset during sequence");
        
        set_test_name(test_name_display, "non strobe writes should not affect Found");
        write_strobe(ByteIn, WriteReq, PAT0);
        write_strobe(ByteIn, WriteReq, PAT1);
        write_strobe(ByteIn, WriteReq, PAT2);
        wait until falling_edge(clk);
        ByteIn <= PAT3;
        WriteReq <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(Found, '1', "Found should assert after non strobe write");

        finish;
    end process;

    dut : entity work.PatternFinder
        generic map (
            Byte0 => PAT0,
            Byte1 => PAT1,
            Byte2 => PAT2,
            Byte3 => PAT3
        )
        port map (
            clk      => clk,
            rst      => rst,
            ByteIn   => ByteIn,
            WriteReq => WriteReq,
            Found    => Found
        );

end architecture sim;
