--! \brief Testbench for PhaseComparator.vhd
--! Covers reset, zero/signed measurements, latch behavior, low-low rearming,
--! saturation boundaries, reset after saturation, and repeated measurements.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
library work;
use work.tb_utils_pkg.all;

entity PhaseComparator_tb is
end PhaseComparator_tb;

architecture sim of PhaseComparator_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant DELTA_BITS : natural := 16;
    constant EDGE_GUARD : time := CLK_PERIOD / 4;

    signal clk : std_logic;
    signal rst : std_logic;
    signal InA : std_logic;
    signal InB : std_logic;
    signal Delta : std_logic_vector(DELTA_BITS - 1 downto 0);
    signal test_name_display : string(1 to 80);

    constant POS_MAX : signed(DELTA_BITS - 1 downto 0) := to_signed((2 ** (DELTA_BITS - 1)) - 1, DELTA_BITS);
    constant NEG_MIN : signed(DELTA_BITS - 1 downto 0) := to_signed(-(2 ** (DELTA_BITS - 1)), DELTA_BITS);
    
    function expected_delta_value(
        constant a_rise_offset : in time;
        constant b_rise_offset : in time
    ) return std_logic_vector is
        variable delta_clocks : integer;
    begin
        delta_clocks := (b_rise_offset - a_rise_offset) / CLK_PERIOD;
        return std_logic_vector(to_signed(delta_clocks, DELTA_BITS));
    end function;

    procedure drive_phase_cycles(
        signal a_out : out std_logic;
        signal b_out : out std_logic;
        signal clk_in : in std_logic;
        constant period : in time;
        constant a_rise_offset : in time;
        constant b_rise_offset : in time;
        constant cycles : in natural
    ) is
        variable early_offset : time;
        variable late_offset : time;
    begin

        assert (a_rise_offset >= 0 ns) and (a_rise_offset < period)
            report "A phase offset must fall within the waveform period"
            severity failure;
        assert (b_rise_offset >= 0 ns) and (b_rise_offset < period)
            report "B phase offset must fall within the waveform period"
            severity failure;

        wait until falling_edge(clk_in);
        wait for EDGE_GUARD;

        if (a_rise_offset <= b_rise_offset) then
            early_offset := a_rise_offset;
            late_offset := b_rise_offset;
        else
            early_offset := b_rise_offset;
            late_offset := a_rise_offset;
        end if;

        for i in 1 to cycles loop
            a_out <= '0';
            b_out <= '0';
            wait for early_offset;

            if (a_rise_offset <= b_rise_offset) then
                a_out <= '1';
            else
                b_out <= '1';
            end if;

            wait for late_offset - early_offset;

            if (a_rise_offset <= b_rise_offset) then
                b_out <= '1';
            else
                a_out <= '1';
            end if;

            wait for period - late_offset;
        end loop;
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
        variable phase_a_lead : time;
        variable phase_b_lead : time;
        variable phase_period : time;
    begin
        InA <= '0';
        InB <= '0';

        set_test_name(test_name_display, "Reset");
        reset_dut(clk, rst);
        assert_equal(Delta, std_logic_vector(to_unsigned(0, DELTA_BITS)), "Delta should be zero after reset");

        set_test_name(test_name_display, "Zero Delta");
        phase_a_lead := 2 * CLK_PERIOD;
        phase_b_lead := 2 * CLK_PERIOD;
        phase_period := 5 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(to_signed(0, DELTA_BITS)),
            "Delta should be zero when A and B rise simultaneously"
        );

        set_test_name(test_name_display, "Positive Delta Plus One");
        phase_a_lead := 2 * CLK_PERIOD;
        phase_b_lead := 3 * CLK_PERIOD;
        phase_period := 6 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should equal +1 when A leads B by one clock"
        );

        set_test_name(test_name_display, "Positive Delta Plus Two");
        phase_a_lead := 2 * CLK_PERIOD;
        phase_b_lead := 4 * CLK_PERIOD;
        phase_period := 7 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should match the A-leading phase difference"
        );

        set_test_name(test_name_display, "Negative Delta Minus One");
        phase_a_lead := 3 * CLK_PERIOD;
        phase_b_lead := 2 * CLK_PERIOD;
        phase_period := 6 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should equal -1 when B leads A by one clock"
        );

        set_test_name(test_name_display, "Negative Delta Minus Two");
        phase_a_lead := 4 * CLK_PERIOD;
        phase_b_lead := 2 * CLK_PERIOD;
        phase_period := 7 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should match the B-leading phase difference"
        );

        set_test_name(test_name_display, "Large Unsaturated Positive Delta");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := 6 * CLK_PERIOD;
        phase_period := 7 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should match the unsaturated positive phase difference"
        );

        set_test_name(test_name_display, "Delta Latching");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := 2 * CLK_PERIOD;
        phase_period := 4 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should latch to the measured value"
        );

        -- because we never go back to 00 after hitting 11 previously delta should remain latched
        InA <= '0';
        InB <= '1';
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should remain latched after A is held low"
        );

        set_test_name(test_name_display, "Low-Low Reset Between Cycles");
        InA <= '0';
        InB <= '0';
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(to_unsigned(1, DELTA_BITS)),
            "Delta should hold the prior latched value while both inputs are low"
        ); 

        InA <= '1';
        InB <= '1';
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(to_unsigned(0, DELTA_BITS)),
            "Delta should remain zero after both inputs are held high"
        );

        set_test_name(test_name_display, "Positive Limit");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := (2 ** (DELTA_BITS - 1)) * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 1) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(POS_MAX),
            "Delta should saturate to the maximum positive value"
        );

        set_test_name(test_name_display, "Positive Overflow Saturates");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := (2 ** (DELTA_BITS - 1) + 1) * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 2) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(POS_MAX),
            "Delta should saturate when the positive limit is exceeded"
        );

        set_test_name(test_name_display, "Positive Limit Minus One");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := (2 ** (DELTA_BITS - 1) - 1) * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1)) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(POS_MAX - (to_signed(1, DELTA_BITS))),
            "Delta should equal one count below the positive saturation limit"
        );

        set_test_name(test_name_display, "Negative Limit");
        phase_a_lead := (2 ** (DELTA_BITS - 1) + 1) * CLK_PERIOD;
        phase_b_lead := 1 * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 2) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(NEG_MIN),
            "Delta should saturate to the maximum negative value"
        );

        set_test_name(test_name_display, "Negative Overflow Saturates");
        phase_a_lead := (2 ** (DELTA_BITS - 1) + 2) * CLK_PERIOD;
        phase_b_lead := 1 * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 3) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(NEG_MIN),
            "Delta should saturate when the negative limit is exceeded"
        );

        set_test_name(test_name_display, "Negative Limit Plus One");
        phase_a_lead := (2 ** (DELTA_BITS - 1)) * CLK_PERIOD;
        phase_b_lead := 1 * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 1) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 1);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(NEG_MIN + (to_signed(1, DELTA_BITS))),
            "Delta should equal one count above the negative saturation limit"
        );

        set_test_name(test_name_display, "Reset After Saturation");
        reset_dut(clk, rst);
        assert_equal(Delta, std_logic_vector(to_unsigned(0, DELTA_BITS)), "Delta should be zero after reset");
        
        set_test_name(test_name_display, "Repeated Positive Delta Measurements");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := 4 * CLK_PERIOD;
        phase_period := 10 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 10);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should remain correct across repeated positive measurements"
        );

        set_test_name(test_name_display, "Repeated Negative Delta Measurements");
        phase_a_lead := 4 * CLK_PERIOD;
        phase_b_lead := 1 * CLK_PERIOD;
        phase_period := 10 * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 10);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            expected_delta_value(phase_a_lead, phase_b_lead),
            "Delta should remain correct across repeated negative measurements"
        );

        set_test_name(test_name_display, "Repeated Positive Saturation");
        phase_a_lead := 1 * CLK_PERIOD;
        phase_b_lead := (2 ** (DELTA_BITS - 1)) * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 1) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 10);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(POS_MAX),
            "Delta should saturate to the maximum positive value over multiple cycles"
        );

        set_test_name(test_name_display, "Repeated Negative Saturation");
        phase_a_lead := (2 ** (DELTA_BITS - 1) + 1) * CLK_PERIOD;
        phase_b_lead := 1 * CLK_PERIOD;
        phase_period := (2 ** (DELTA_BITS - 1) + 2) * CLK_PERIOD;
        drive_phase_cycles(InA, InB, clk, phase_period, phase_a_lead, phase_b_lead, 10);
        cycle_clock(clk, 4);
        assert_equal(
            Delta,
            std_logic_vector(NEG_MIN),
            "Delta should saturate to the maximum negative value over multiple cycles"
        );

        finish;
    end process;

    dut : entity work.PhaseComparatorPorts
        generic map (
            MAX_CLOCK_BITS_DELTA => DELTA_BITS
        )
        port map (
            clk => clk,
            rst => rst,
            InA => InA,
            InB => InB,
            Delta => Delta
        );

end architecture sim;
