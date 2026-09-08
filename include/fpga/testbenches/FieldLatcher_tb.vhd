--! \brief Testbench for FieldLatcher.vhd
--! Byte capture and shift sequencing checks across multi-byte fields.
--! Also covers held write-request behavior and reset timing cases.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
library work;
use work.tb_utils_pkg.all;

entity FieldLatcher_tb is
end FieldLatcher_tb;

architecture sim of FieldLatcher_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk           : std_logic;
    signal rst           : std_logic;
    signal ByteIn        : std_logic_vector(7 downto 0);
    signal WriteReq      : std_logic;
    signal FieldLatched  : std_logic_vector(31 downto 0);

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
        assert_equal(FieldLatched, x"00000000", "Field should be zero after reset");

        set_test_name(test_name_display, "First byte");
        write_strobe(ByteIn, WriteReq, x"11");
        assert_equal(FieldLatched, x"00000011", "LSB should hold first byte");

        set_test_name(test_name_display, "Shift four bytes");
        write_strobe(ByteIn, WriteReq, x"22");
        write_strobe(ByteIn, WriteReq, x"33");
        write_strobe(ByteIn, WriteReq, x"44");
        assert_equal(FieldLatched, x"11223344", "Field should shift MSB first");

        set_test_name(test_name_display, "WriteReq held high does not double-latch");
        wait until falling_edge(clk);
        ByteIn <= x"FF";
        WriteReq <= '1';
        wait until falling_edge(clk);
        wait until falling_edge(clk);
        assert_equal(FieldLatched, x"223344FF", "Only one shift while WriteReq stays high");

        set_test_name(test_name_display, "Reset after data");
        ByteIn <= x"00";
        WriteReq <= '0';
        reset_dut(clk, rst);
        assert_equal(FieldLatched, x"00000000", "Field should clear on reset");

        set_test_name(test_name_display, "reset during data");
        write_strobe(ByteIn, WriteReq, x"11");
        assert_equal(FieldLatched, x"00000011", "Field should hold first byte");
        write_strobe(ByteIn, WriteReq, x"22");
        assert_equal(FieldLatched, x"00001122", "Field should shift first byte");
        write_strobe(ByteIn, WriteReq, x"33");
        assert_equal(FieldLatched, x"00112233", "Field should hold data on reset during data");
        reset_dut(clk, rst);
        assert_equal(FieldLatched, x"00000000", "Field should clear on reset during data");

        finish;
    end process;

    dut : entity work.FieldLatcher
        port map (
            clk          => clk,
            rst          => rst,
            ByteIn       => ByteIn,
            WriteReq     => WriteReq,
            FieldLatched => FieldLatched
        );

end architecture sim;
