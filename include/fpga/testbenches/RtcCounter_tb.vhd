--! \brief Testbench for RtcCounter.vhd
--! Free-run ms/sec progression and rollover checks.
--! PPS sync/grace timing, SetTime handling, and generated PPS behavior.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.tb_utils_pkg.all;

entity RtcCounter_tb is
end entity RtcCounter_tb;

architecture sim of RtcCounter_tb is

    constant CLOCK_FREQ  : natural := 10000;
    constant CLK_PERIOD  : time    := 100 us;
    constant CLKS_PER_MS : natural := CLOCK_FREQ / 1000; -- 10

    signal clk            : std_logic;
    signal rst            : std_logic;
    signal PPS            : std_logic;
    signal PPSDetected    : std_logic;
    signal Sync           : std_logic; -- unused
    signal GeneratePPS    : std_logic;
    signal GeneratedPPS   : std_logic;
    signal SetTimeSeconds : std_logic_vector(21 downto 0);
    signal SetTime        : std_logic;
    signal SetChangedTime : std_logic;
    signal Seconds        : std_logic_vector(21 downto 0);
    signal Milliseconds   : std_logic_vector(9 downto 0);

    signal test_name_display : string(1 to 80);

    procedure wait_clks(n : natural) is
    begin
        for i in 1 to n loop
            wait until falling_edge(clk);
        end loop;
    end procedure;

    procedure wait_ms(n : natural) is
    begin
        wait_clks(n * CLKS_PER_MS);
    end procedure;

    procedure reset_dut(signal rst_out : out std_logic) is
    begin
        rst_out <= '1';
        wait until falling_edge(clk);
        rst_out <= '0';
        wait until falling_edge(clk);
    end procedure;

begin

    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    test_process : process
    begin
        PPS <= '1';
        Sync <= '0';
        GeneratePPS <= '0';
        SetTimeSeconds <= (others => '0');
        SetTime <= '0';

        set_test_name(test_name_display, "Reset");
        report COLOR_YELLOW & "Testing: Reset" & COLOR_RESET;
        rst <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPS Detected should be 0 after reset");
        assert_equal(Seconds, std_logic_vector(to_unsigned(0, 22)), "Seconds should be 0 after reset");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should be 0 after reset");
        assert_equal(GeneratedPPS, '1', "GeneratedPPS should be 1 after reset (ms=0 < 64)");
        assert_equal(SetChangedTime, '0', "SetChangedTime should be 0 after reset");
        rst <= '0';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPS Detected should remain 0 after releasing reset");
        assert_equal(Seconds, std_logic_vector(to_unsigned(0, 22)), "Seconds should remain 0 after releasing reset");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should remain 0 after releasing reset");


        set_test_name(test_name_display, "Free-run ms increment");
        report COLOR_YELLOW & "Testing: Free-run ms increment" & COLOR_RESET;
        wait_ms(10);
        assert_equal(Seconds, std_logic_vector(to_unsigned(0, 22)), "Seconds should remain 0 during free-run ms increment");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(10, 10)), "Milliseconds should be 10 after 10 ms of free-run increment");


        set_test_name(test_name_display, "Free-run second rollover");
        report COLOR_YELLOW & "Testing: Free-run second rollover" & COLOR_RESET;
        wait_ms(990);
        assert_equal(Seconds, std_logic_vector(to_unsigned(1, 22)), "Seconds should rollover to 1 after 1000 ms of free-run increment");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should rollover to 0 after 1000 ms of free-run increment");


        set_test_name(test_name_display, "PPS rising edge sync");
        report COLOR_YELLOW & "Testing: PPS rising edge sync" & COLOR_RESET;
        reset_dut(rst);
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '1', "PPS Detected should be 1 after rising edge of PPS");
        assert_equal(Seconds, std_logic_vector(to_unsigned(1, 22)), "Seconds should remain 1 immediately after PPS rising edge");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should remain 0 immediately after PPS rising edge");


        set_test_name(test_name_display, "PPS grace period ms=1000");
        report COLOR_YELLOW & "Testing: PPS grace period ms=1000" & COLOR_RESET;
        reset_dut(rst);
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        wait_ms(999);
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(999, 10)), "Milliseconds should be 999 before grace period");
        assert_equal(Seconds, std_logic_vector(to_unsigned(1, 22)), "Seconds should be 1 before grace period");
        wait_ms(1);
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(1000, 10)), "Milliseconds should be 1000 during PPS grace period");
        assert_equal(Seconds, std_logic_vector(to_unsigned(1, 22)), "Seconds should remain 1 during grace period");
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should rollover to 0 after PPS edge");
        assert_equal(Seconds, std_logic_vector(to_unsigned(2, 22)), "Seconds should rollover to 2 after PPS edge");
        wait_ms(1);
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(1, 10)), "Milliseconds should increment after rollover");
        assert_equal(Seconds, std_logic_vector(to_unsigned(2, 22)), "Seconds should remain 2 after ms increment");

        set_test_name(test_name_display, "SetTime");
        report COLOR_YELLOW & "Testing: SetTime" & COLOR_RESET;
        reset_dut(rst);
        SetTimeSeconds <= std_logic_vector(to_unsigned(12345, 22));
        SetTime <= '1';
        wait until falling_edge(clk);
        SetTime <= '0';
        wait until falling_edge(clk);
        assert_equal(Seconds, std_logic_vector(to_unsigned(12345, 22)), "Seconds should update to SetTimeSeconds after SetTime pulse");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should reset to 0 after SetTime pulse");
        assert_equal(SetChangedTime, '1', "SetChangedTime should be 1 after SetTime pulse");
        wait until falling_edge(clk);
        assert_equal(SetChangedTime, '1', "SetChangedTime should remain 1 after one clock");

        set_test_name(test_name_display, "GeneratePPS disables external PPS");
        report COLOR_YELLOW & "Testing: GeneratePPS disables external PPS" & COLOR_RESET;
        reset_dut(rst);
        GeneratePPS <= '1';
        wait until falling_edge(clk);
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '0', "PPS Detected should remain 0 when GeneratePPS is enabled, ignoring external PPS edges");
        assert_equal(Seconds, std_logic_vector(to_unsigned(0, 22)), "Seconds should remain 0 when GeneratePPS is enabled, ignoring external PPS edges");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should remain 0 when GeneratePPS is enabled, ignoring external PPS edges");
        GeneratePPS <= '0';
        wait until falling_edge(clk);
        PPS <= '0';
        wait until falling_edge(clk);
        PPS <= '1';
        wait until falling_edge(clk);
        assert_equal(PPSDetected, '1', "PPS Detected should be 1 after re-enabling external PPS and receiving rising edge");
        assert_equal(Seconds, std_logic_vector(to_unsigned(1, 22)), "Seconds should increment to 1 after re-enabling external PPS and receiving rising edge");
        assert_equal(Milliseconds, std_logic_vector(to_unsigned(0, 10)), "Milliseconds should reset to 0 after re-enabling external PPS and receiving rising edge");

        set_test_name(test_name_display, "GeneratedPPS output window");
        report COLOR_YELLOW & "Testing: GeneratedPPS output window" & COLOR_RESET;
        reset_dut(rst);
        wait_ms(63);
        assert_equal(GeneratedPPS, '1', "GeneratedPPS should be 1 when ms < 64");
        wait_ms(1);
        assert_equal(GeneratedPPS, '0', "GeneratedPPS should be 0 when ms >= 64");
        wait_ms(935);
        assert_equal(GeneratedPPS, '0', "GeneratedPPS should remain 0 until ms rolls over");
        wait_ms(1);
        assert_equal(GeneratedPPS, '1', "GeneratedPPS should return to 1 when ms rolls over to 0");

        report COLOR_GREEN & "All tests complete." & COLOR_RESET;
        finish;

    end process;

    dut : entity work.RtcCounterPorts
        generic map (
            CLOCK_FREQ => CLOCK_FREQ
        )
        port map (
            clk            => clk,
            rst            => rst,
            PPS            => PPS,
            PPSDetected    => PPSDetected,
            Sync           => Sync,
            GeneratePPS    => GeneratePPS,
            GeneratedPPS   => GeneratedPPS,
            SetTimeSeconds => SetTimeSeconds,
            SetTime        => SetTime,
            SetChangedTime => SetChangedTime,
            Seconds        => Seconds,
            Milliseconds   => Milliseconds
        );

end architecture sim;
