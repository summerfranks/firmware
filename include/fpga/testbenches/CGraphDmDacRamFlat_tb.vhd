--! \brief Testbench for CGraphDmTypes
--! Minimal sanity test so the package analyzes and elaborates cleanly.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.CGraphDMTypes.all;
use work.tb_utils_pkg.all;

entity CGraphDmDacRamFlat_tb is
end entity CGraphDmDacRamFlat_tb;


architecture sim of CGraphDmDacRamFlat_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant LAST_ADDRESS : integer := DMMaxActuators - 1;
    constant MID_ADDRESS : integer := DMMaxActuators / 2;

    signal test_name_display : string(1 to 80);
    signal clk : std_logic;
    signal rst : std_logic;

    signal ReadAddress : integer range (DMMaxActuators - 1) downto 0;
    signal WriteAddress : integer range (DMMaxActuators - 1) downto 0;
    signal DacSetpointIn : std_logic_vector(DMSetpointMSB downto 0);
    signal DacSetpointOut : std_logic_vector(DMSetpointMSB downto 0);
    signal WriteReq : std_logic;

    procedure write_word(
        signal write_address_out : out integer range (DMMaxActuators - 1) downto 0;
        signal read_address_out : out integer range (DMMaxActuators - 1) downto 0;
        signal dac_setpoint_in_out : out std_logic_vector(DMSetpointMSB downto 0);
        signal write_req_out : out std_logic;
        constant address : integer;
        constant data : std_logic_vector(DMSetpointMSB downto 0)
    ) is
    begin
        wait until falling_edge(clk);
        write_address_out <= address;
        read_address_out <= address;
        dac_setpoint_in_out <= data;
        write_req_out <= '1';
        wait until falling_edge(clk);
        write_req_out <= '0';
    end procedure;

    procedure read_expect(
        signal read_address_out : out integer range (DMMaxActuators - 1) downto 0;
        constant address : integer;
        constant expected : std_logic_vector(DMSetpointMSB downto 0);
        constant msg : string
    ) is
    begin
        wait until falling_edge(clk);
        read_address_out <= address;
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, expected, msg);
    end procedure;
begin

    clk_process : process
	begin
		clk <= '0';
		wait for CLK_PERIOD / 2;
		clk <= '1';
		wait for CLK_PERIOD / 2;
	end process;

	process
	begin
        ReadAddress <= 0;
        WriteAddress <= 0;
        DacSetpointIn <= (others => '0');
        WriteReq <= '0';

		set_test_name(test_name_display, "CGraphDmDacRamFlat reset");
        reset_dut(clk, rst);

        assert_equal(DacSetpointOut, (DacSetpointOut'range => '0'), "DMDacSetpointRamFlat reset state");

        set_test_name(test_name_display, "CGraphDmDacRamFlat write and read");
        WriteAddress <= 0;
        ReadAddress <= 0;
        DacSetpointIn <= x"000001";
        WriteReq <= '1';
        assert_equal(DacSetpointOut, x"000000", "DMDacSetpointRamFlat write and read before clock edge");
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"000001", "DMDacSetpointRamFlat write and read after clock edge");
        WriteReq <= '0';
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"000001", "DMDacSetpointRamFlat write and read");

        set_test_name(test_name_display, "CGraphDmDacRamFlat write and read multiple addresses");
        write_word(WriteAddress, ReadAddress, DacSetpointIn, WriteReq, 1, x"111111");
        write_word(WriteAddress, ReadAddress, DacSetpointIn, WriteReq, MID_ADDRESS, x"345678");
        write_word(WriteAddress, ReadAddress, DacSetpointIn, WriteReq, LAST_ADDRESS, x"ABCDEF");
        read_expect(ReadAddress, 0, x"000001", "Address 0 retains its value");
        read_expect(ReadAddress, 1, x"111111", "Address 1 returns its own value");
        read_expect(ReadAddress, MID_ADDRESS, x"345678", "Middle address returns its value");
        read_expect(ReadAddress, LAST_ADDRESS, x"ABCDEF", "Last address returns its value");

        set_test_name(test_name_display, "CGraphDmDacRamFlat write disabled does not update memory");
        wait until falling_edge(clk);
        ReadAddress <= 1;
        WriteAddress <= 1;
        DacSetpointIn <= x"222222";
        WriteReq <= '0';
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"111111", "WriteReq low leaves stored value unchanged");

        set_test_name(test_name_display, "CGraphDmDacRamFlat overwrite existing address");
        write_word(WriteAddress, ReadAddress, DacSetpointIn, WriteReq, 1, x"222222");
        read_expect(ReadAddress, 1, x"222222", "Overwrite updates the addressed word");
        read_expect(ReadAddress, 0, x"000001", "Overwrite does not disturb another address");

        set_test_name(test_name_display, "CGraphDmDacRamFlat registered read address change");
        wait until falling_edge(clk);
        ReadAddress <= LAST_ADDRESS;
        assert_equal(DacSetpointOut, x"000001", "Output holds previous word until next clock");
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"ABCDEF", "Output updates on next clock for new read address");

        set_test_name(test_name_display, "CGraphDmDacRamFlat reset drives output low");
        reset_dut(clk, rst);
        assert_equal(DacSetpointOut, (DacSetpointOut'range => '0'), "Reset forces output low after data has been written");

        set_test_name(test_name_display, "CGraphDmDacRamFlat reset doesn't clear memory");
        write_word(WriteAddress, ReadAddress, DacSetpointIn, WriteReq, 0, x"123456");
        reset_dut(clk, rst);
        read_expect(ReadAddress, 0, x"123456", "Reset doesn't clear memory after data has been written");

		finish;
	end process;

    dut : entity work.DmDacRamFlatPorts
        port map (
            clk => clk,
            rst => rst,
            ReadAddress => ReadAddress,
            WriteAddress => WriteAddress,
            DacSetpointIn => DacSetpointIn,
            DacSetpointOut => DacSetpointOut,
            WriteReq => WriteReq
        );

end architecture sim;
