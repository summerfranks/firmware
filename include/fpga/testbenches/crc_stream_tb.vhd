--! \brief Testbench for CrcStream.vhd
--! Stream CRC checks over reset, zero stream, and simple text payload cases.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity crc_stream_tb is
end crc_stream_tb;

architecture sim of crc_stream_tb is

    constant CRC32_POLY : std_logic_vector(31 downto 0) := x"04C11DB7";
    constant CRC_INIT_STATE : std_logic_vector(31 downto 0) := x"FFFFFFFF";
    constant CRC_INIT_STATE_ALT : std_logic_vector(31 downto 0) := x"00000000";

    signal clk  : std_logic;
    signal rst  : std_logic;
    signal data : std_logic_vector(7 downto 0);
    signal crc  : std_logic_vector(31 downto 0);
    signal crc_alt : std_logic_vector(31 downto 0);
    signal test_name_display : string(1 to 80);

    constant CLK_PERIOD : time := 10 ns;

    function crc_next_byte_ref(
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
        variable running : std_logic_vector(31 downto 0);
        variable running_alt : std_logic_vector(31 downto 0);
    begin
        set_test_name(test_name_display, "Reset + zeros");
        rst  <= '1';
        data <= x"00";
        wait until falling_edge(clk);
        assert_equal(crc, crc_next_byte_ref(CRC_INIT_STATE, x"00"), "reset: CRC should be crc_next_byte_ref(CRC_INIT_STATE, 00)");
        assert_equal(crc_alt, crc_next_byte_ref(CRC_INIT_STATE_ALT, x"00"), "reset alt: CRC should be crc_next_byte_ref(CRC_INIT_STATE_ALT, 00)");
        rst <= '0';
        
        set_test_name(test_name_display, "Zero Stream");
        running := CRC_INIT_STATE;
        running_alt := CRC_INIT_STATE_ALT;
        for i in 0 to 2 loop
            running := crc_next_byte_ref(running, x"00");
            running_alt := crc_next_byte_ref(running_alt, x"00");
            assert_equal(crc, running, "zero stream: after clk " & integer'image(i));
            assert_equal(crc_alt, running_alt, "zero stream alt: after clk " & integer'image(i));
            wait until falling_edge(clk);
        end loop;

        set_test_name(test_name_display, "HI!");
        rst  <= '1';
        data <= x"48";
        wait until falling_edge(clk);
        rst <= '0';
        assert_equal(crc, crc_next_byte_ref(CRC_INIT_STATE, x"48"), "reset with H on bus");
        assert_equal(crc_alt, crc_next_byte_ref(CRC_INIT_STATE_ALT, x"48"), "reset with H on bus alt");
        wait until rising_edge(clk);
        running := crc_next_byte_ref(CRC_INIT_STATE, x"48");
        running_alt := crc_next_byte_ref(CRC_INIT_STATE_ALT, x"48");
        data <= x"49";
        wait until falling_edge(clk);
        assert_equal(crc, crc_next_byte_ref(running, x"49"), "after H absorbed, I on bus");
        assert_equal(crc_alt, crc_next_byte_ref(running_alt, x"49"), "after H absorbed, I on bus alt");

        wait until rising_edge(clk);
        running := crc_next_byte_ref(running, x"49");
        running_alt := crc_next_byte_ref(running_alt, x"49");
        data <= x"21";
        wait until falling_edge(clk);
        assert_equal(crc, crc_next_byte_ref(running, x"21"), "after HI absorbed, ! on bus");
        assert_equal(crc_alt, crc_next_byte_ref(running_alt, x"21"), "after HI absorbed, ! on bus alt");


        set_test_name(test_name_display, "HI! via reset_dut");
        data <= x"48";
        wait until falling_edge(clk);
        reset_dut(clk, rst);
        -- rst=0, CrcIn=FFFFFFFF; do not advance clk with wrong data before checks. annoying rst interaction with clk
        wait until rising_edge(clk);
        running := crc_next_byte_ref(CRC_INIT_STATE, x"48");
        running_alt := crc_next_byte_ref(CRC_INIT_STATE_ALT, x"48");
        data <= x"49";
        wait until falling_edge(clk);
        assert_equal(crc, crc_next_byte_ref(running, x"49"), "reset_dut: after H, I on bus");
        assert_equal(crc_alt, crc_next_byte_ref(running_alt, x"49"), "reset_dut alt: after H, I on bus");

        wait until rising_edge(clk);
        running := crc_next_byte_ref(running, x"49");
        running_alt := crc_next_byte_ref(running_alt, x"49");
        data <= x"21";
        wait until falling_edge(clk);
        assert_equal(crc, crc_next_byte_ref(running, x"21"), "reset_dut: after HI, ! on bus");
        assert_equal(crc_alt, crc_next_byte_ref(running_alt, x"21"), "reset_dut alt: after HI, ! on bus");

        finish;
    end process;

    dut : entity work.CrcStream
        generic map (
            CRC_INIT_STATE => CRC_INIT_STATE
        )
        port map (
            clk  => clk,
            rst  => rst,
            data => data,
            crc  => crc
        );

    dut_alt : entity work.CrcStream
        generic map (
            CRC_INIT_STATE => CRC_INIT_STATE_ALT
        )
        port map (
            clk  => clk,
            rst  => rst,
            data => data,
            crc  => crc_alt
        );

end architecture sim;
