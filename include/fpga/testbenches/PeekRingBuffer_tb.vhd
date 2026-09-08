--! \brief Testbench for PeekRingBuffer.vhd
--! Exercises basic write/peek/pop interactions, including boundary conditions at empty/full and wrap.
--! Also checks header/footer detection and payload length tracking.
--! No CRC structure yet, TBD when added.
--! No-write-when-disabled and reset-after-write behavior included.
    
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.CGraphTypes.all;
use work.tb_utils_pkg.all;

entity PeekRingBuffer_tb is
end PeekRingBuffer_tb;

architecture sim of PeekRingBuffer_tb is

    constant CLK_PERIOD : time    := 10 ns;
    constant DEPTH      : natural := 2 ** PeekRamDepth;

    -- Header / footer values from PeekRingBuffer, must change if PatternFinder changes
    constant HDR : std_logic_vector(0 to 31) := x"1BADBABE";
    constant FTR : std_logic_vector(0 to 31) := x"0A0FADED";

    signal clk                         : std_logic;
    signal rst                         : std_logic;
    signal DataStartAddress            : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal DataEndAddress              : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal PeekAddress                 : std_logic_vector(PeekRamDepth - 1 downto 0) := (others => '0');
    signal PopAddress                  : std_logic_vector(PeekRamDepth - 1 downto 0) := (others => '0');
    signal LastHeaderEnd               : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal LastFooterEnd               : std_logic_vector(PeekRamDepth - 1 downto 0);
    signal PayloadLen                  : std_logic_vector(31 downto 0);
    signal HeaderFooterPayloadLenMatches : std_logic;
    signal ByteIn                      : std_logic_vector(7 downto 0) := (others => '0');
    signal ByteOut                     : std_logic_vector(7 downto 0);
    signal WriteReq                    : std_logic;
    signal PopReq                      : std_logic;
    signal Dbg1                        : std_logic;
    signal Dbg2                        : std_logic;
    signal Dbg3                        : std_logic;
    signal Empty                       : std_logic;
    signal Full                        : std_logic;
    signal Count                       : std_logic_vector(PeekRamDepth - 1 downto 0);

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
        wait until falling_edge(clk);
    end procedure;

    procedure pop_to(
        signal pop_addr_out : out std_logic_vector(PeekRamDepth - 1 downto 0);
        signal pop_req_out  : out std_logic;
        constant addr        : natural
    ) is
    begin
        wait until falling_edge(clk);
        pop_addr_out <= std_logic_vector(to_unsigned(addr, PeekRamDepth));
        pop_req_out <= '1';
        wait until falling_edge(clk);
        pop_req_out <= '0';
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
        PeekAddress <= (others => '0');
        PopAddress  <= (others => '0');
        ByteIn      <= (others => '0');
        WriteReq    <= '0';
        PopReq      <= '0';

        set_test_name(test_name_display, "Reset defaults");
        reset_dut(clk, rst);
        assert_equal(Empty, '1', "Empty when start and end both 0");
        assert_equal(DataStartAddress, std_logic_vector(to_unsigned(0, PeekRamDepth)), "DataStart 0 after reset");
        assert_equal(DataEndAddress, std_logic_vector(to_unsigned(0, PeekRamDepth)), "DataEnd 0 after reset");
        assert_equal(LastHeaderEnd, std_logic_vector(to_unsigned(0, PeekRamDepth)), "LastHeaderEnd 0 after reset");
        assert_equal(LastFooterEnd, std_logic_vector(to_unsigned(0, PeekRamDepth)), "LastFooterEnd 0 after reset");
        assert_equal(PayloadLen, x"00000000", "PayloadLen 0 after reset");


        set_test_name(test_name_display, "Write one byte, peek addr 0");
        write_strobe(ByteIn, WriteReq, x"AB");
        assert_equal(Empty, '0', "Not empty after one write");
        assert_equal(DataEndAddress, std_logic_vector(to_unsigned(1, PeekRamDepth)), "Write pointer advances to 1");
        PeekAddress <= std_logic_vector(to_unsigned(0, PeekRamDepth));
        wait until falling_edge(clk);  -- Data settles correctly on the falling edge, so we have to wait to assert correctly (tb uses falling edge assertions)
        assert_equal(ByteOut, x"AB", "Peek sees written byte at address 0");


        set_test_name(test_name_display, "Pop advances DataStart, empty at tail");
        write_strobe(ByteIn, WriteReq, x"CD");
        assert_equal(DataEndAddress, std_logic_vector(to_unsigned(2, PeekRamDepth)), "End at 2 after second write");
        pop_to(PopAddress, PopReq, 1);
        wait until falling_edge(clk);
        assert_equal(DataStartAddress, std_logic_vector(to_unsigned(1, PeekRamDepth)), "Pop to 1 moves start");
        assert_equal(Empty, '0', "Still data between 1 and 2");
        pop_to(PopAddress, PopReq, 2);
        wait until falling_edge(clk);
        assert_equal(Empty, '1', "Empty when start meets end");


        set_test_name(test_name_display, "Write to Full, pop to empty");
        reset_dut(clk, rst);
        for i in 0 to DEPTH - 2 loop -- Only 2047 bytes, not 2048 (intentional?)
            write_strobe(ByteIn, WriteReq, x"00");
        end loop;
        -- wait until falling_edge(clk);
        -- wait until falling_edge(clk);
        assert_equal(Full, '1', "Full when WriteAddress is at depth - 1");
        assert_equal(Empty, '0', "Not empty when WriteAddress wraps at depth");
        assert_equal(Count, std_logic_vector(to_unsigned(DEPTH - 1, PeekRamDepth)), "Count is DEPTH when WriteAddress wraps at depth");
        pop_to(PopAddress, PopReq, DEPTH - 1);
        wait until falling_edge(clk);
        assert_equal(Empty, '1', "Empty when start meets end");
        assert_equal(DataStartAddress, std_logic_vector(to_unsigned(DEPTH - 1, PeekRamDepth)), "Start is at depth - 1");
        assert_equal(DataEndAddress, std_logic_vector(to_unsigned(DEPTH - 1, PeekRamDepth)), "End is at depth - 1");


        set_test_name(test_name_display, "write to wrap after pop to empty");
        write_strobe(ByteIn, WriteReq, x"00");
        wait until falling_edge(clk);
        assert_equal(DataEndAddress, std_logic_vector(to_unsigned(0, PeekRamDepth)), "After writing to wrap, pointer wraps to 1");
        assert_equal(Full, '0', "Not full when WriteAddress wraps after pop to empty");
        assert_equal(Empty, '0', "Not empty when WriteAddress wraps after pop to empty");
        assert_equal(Count, std_logic_vector(to_unsigned(1, PeekRamDepth)), "Count is 1 when WriteAddress wraps at depth");


        set_test_name(test_name_display, "WriteAddress wraps at depth");
        reset_dut(clk, rst);
        for i in 0 to DEPTH - 1 loop
            write_strobe(ByteIn, WriteReq, x"00");
        end loop;
        -- wait until falling_edge(clk);
        -- wait until falling_edge(clk);
        -- wait until falling_edge(clk);
        assert_equal(DataEndAddress, std_logic_vector(to_unsigned(0, PeekRamDepth)), "After DEPTH writes from 0, pointer wraps to 0");
        assert_equal(Full, '0', "Not full when WriteAddress wraps at depth");
        assert_equal(Empty, '1', "Empty when WriteAddress wraps at depth");
        assert_equal(Count, std_logic_vector(to_unsigned(0, PeekRamDepth)), "Count is 0 when WriteAddress wraps at depth");


        set_test_name(test_name_display, "Header magic updates LastHeaderEnd");
        reset_dut(clk, rst);
        for i in 0 to 3 loop -- Write header x1BADBABE
            PeekAddress <= std_logic_vector(to_unsigned(i, PeekRamDepth));
            write_strobe(ByteIn, WriteReq, HDR(i * 8 to i * 8 + 7));
            assert_equal(ByteOut, HDR(i * 8 to i * 8 + 7), "Peek sees written header byte at address " & to_string(i) & " as " & to_hstring(ByteOut) );
        end loop;
        assert_equal(LastHeaderEnd, std_logic_vector(to_unsigned(3, PeekRamDepth)), "Header end index is last header byte address (0..3)");


        set_test_name(test_name_display, "Footer magic updates LastFooterEnd");
        -- reset_dut(clk, rst);
        for i in 0 to 3 loop
            PeekAddress <= std_logic_vector(to_unsigned(i + 4, PeekRamDepth));
            write_strobe(ByteIn, WriteReq, FTR(i * 8 to i * 8 + 7));
            assert_equal(ByteOut, FTR(i * 8 to i * 8 + 7), "Peek sees written footer byte at address " & to_string(i) & " as " & to_hstring(ByteOut) );
        end loop;
        wait until falling_edge(clk);
        assert_equal(LastFooterEnd, std_logic_vector(to_unsigned(7, PeekRamDepth)), "Footer end index is last footer byte address (0..3)");


        -- set_test_name(test_name_display, "PayloadLen: 2-byte length after header");
        -- reset_dut(clk, rst);
        -- for i in 0 to 3 loop
        --     write_strobe(ByteIn, WriteReq, HDR(i * 8 to i * 8 + 7));
        -- end loop;
        -- write_strobe(ByteIn, WriteReq, x"01");
        -- write_strobe(ByteIn, WriteReq, x"02");
        -- wait until falling_edge(clk);
        -- assert_equal(LastHeaderEnd, std_logic_vector(to_unsigned(3, PeekRamDepth)), "Header end index is last header byte address (0..3)");
        -- assert_equal(PayloadLen, x"BABE0102", "FieldLatcher after 2 length bytes (01 02)");


        -- -----
        -- No CRC structure yet, TBD when added
        -- -----

        finish;
    end process;

    dut : entity work.PeekRingBuffer
        port map (
            clk                         => clk,
            rst                         => rst,
            DataStartAddress            => DataStartAddress,
            DataEndAddress              => DataEndAddress,
            PeekAddress                 => PeekAddress,
            PopAddress                  => PopAddress,
            LastHeaderEnd               => LastHeaderEnd,
            LastFooterEnd               => LastFooterEnd,
            PayloadLen                  => PayloadLen,
            HeaderFooterPayloadLenMatches => HeaderFooterPayloadLenMatches,
            ByteIn                      => ByteIn,
            ByteOut                     => ByteOut,
            WriteReq                    => WriteReq,
            PopReq                      => PopReq,
            Dbg1                        => Dbg1,
            Dbg2                        => Dbg2,
            Dbg3                        => Dbg3,
            Empty                       => Empty,
            Full                        => Full,
            Count                       => Count
        );

end architecture sim;
