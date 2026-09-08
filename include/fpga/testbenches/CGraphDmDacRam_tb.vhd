--! \brief Testbench for CGraphDmDacRam.vhd
--! Covers reset behavior, flat write-address decoding, registered reads,
--! write gating, overwrite behavior, and boundary-address access.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library work;
use work.CGraphDMTypes.all;
use work.tb_utils_pkg.all;

entity CGraphDmDacRam_tb is
end entity CGraphDmDacRam_tb;

architecture sim of CGraphDmDacRam_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal test_name_display : string(1 to 80);
    signal clk : std_logic;
    signal rst : std_logic;

    signal ReadAddressController : integer range (DMMaxControllerBoards - 1) downto 0;
    signal ReadAddressDac : integer range (DMMDacsPerControllerBoard - 1) downto 0;
    signal ReadAddressChannel : integer range (DMActuatorsPerDac - 1) downto 0;
    signal WriteAddress : integer range (DMMaxActuators - 1) downto 0;
    signal DacSetpointIn : std_logic_vector(DMSetpointMSB downto 0);
    signal DacSetpointOut : std_logic_vector(DMSetpointMSB downto 0);
    signal WriteReq : std_logic;

    function flat_address(
        constant controller : integer;
        constant dac : integer;
        constant channel : integer
    ) return integer is
    begin
        return (controller * DMMDacsPerControllerBoard * DMActuatorsPerDac) +
               (dac * DMActuatorsPerDac) +
               channel;
    end function;

    procedure write_word(
        signal write_address_out : out integer range (DMMaxActuators - 1) downto 0;
        signal dac_setpoint_in_out : out std_logic_vector(DMSetpointMSB downto 0);
        signal write_req_out : out std_logic;
        constant address : integer;
        constant data : std_logic_vector(DMSetpointMSB downto 0)
    ) is
    begin
        wait until falling_edge(clk);
        write_address_out <= address;
        dac_setpoint_in_out <= data;
        write_req_out <= '1';
        wait until falling_edge(clk);
        write_req_out <= '0';
    end procedure;

    procedure read_expect(
        signal read_address_controller_out : out integer range (DMMaxControllerBoards - 1) downto 0;
        signal read_address_dac_out : out integer range (DMMDacsPerControllerBoard - 1) downto 0;
        signal read_address_channel_out : out integer range (DMActuatorsPerDac - 1) downto 0;
        constant controller : integer;
        constant dac : integer;
        constant channel : integer;
        constant expected : std_logic_vector(DMSetpointMSB downto 0);
        constant msg : string
    ) is
    begin
        wait until falling_edge(clk);
        read_address_controller_out <= controller;
        read_address_dac_out <= dac;
        read_address_channel_out <= channel;
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

    test_process : process
        constant MID_CONTROLLER : integer := DMMaxControllerBoards / 2;
        constant MID_DAC : integer := DMMDacsPerControllerBoard / 2;
        constant MID_CHANNEL : integer := DMActuatorsPerDac / 2;
        constant LAST_CONTROLLER : integer := DMMaxControllerBoards - 1;
        constant LAST_DAC : integer := DMMDacsPerControllerBoard - 1;
        constant LAST_CHANNEL : integer := DMActuatorsPerDac - 1;
    begin
        ReadAddressController <= 0;
        ReadAddressDac <= 0;
        ReadAddressChannel <= 0;
        WriteAddress <= 0;
        DacSetpointIn <= (others => '0');
        WriteReq <= '0';

        set_test_name(test_name_display, "CGraphDmDacRam reset");
        reset_dut(clk, rst);
        assert_equal(DacSetpointOut, (DacSetpointOut'range => '0'), "Reset drives DacSetpointOut low");

        set_test_name(test_name_display, "CGraphDmDacRam write and read first address");
        WriteAddress <= flat_address(0, 0, 0);
        DacSetpointIn <= x"000001";
        WriteReq <= '1';
        assert_equal(DacSetpointOut, x"000000", "Output remains reset value before write clock edge");
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"000001", "Write becomes visible after the write clock edge");
        WriteReq <= '0';
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"000001", "Stored value remains readable");

        set_test_name(test_name_display, "CGraphDmDacRam decode multiple flat addresses");
        write_word(WriteAddress, DacSetpointIn, WriteReq, flat_address(0, 1, 2), x"010102");
        write_word(WriteAddress, DacSetpointIn, WriteReq, flat_address(MID_CONTROLLER, MID_DAC, MID_CHANNEL), x"123456");
        write_word(WriteAddress, DacSetpointIn, WriteReq, flat_address(LAST_CONTROLLER, LAST_DAC, LAST_CHANNEL), x"FEDCBA");
        read_expect(ReadAddressController, ReadAddressDac, ReadAddressChannel, 0, 0, 0, x"000001", "Controller 0 DAC 0 channel 0 retains its value");
        read_expect(ReadAddressController, ReadAddressDac, ReadAddressChannel, 0, 1, 2, x"010102", "Flat address decodes to controller 0 DAC 1 channel 2");
        read_expect(ReadAddressController, ReadAddressDac, ReadAddressChannel, MID_CONTROLLER, MID_DAC, MID_CHANNEL, x"123456", "Middle decoded address returns its stored value");
        read_expect(ReadAddressController, ReadAddressDac, ReadAddressChannel, LAST_CONTROLLER, LAST_DAC, LAST_CHANNEL, x"FEDCBA", "Last reachable decoded address returns its stored value");

        set_test_name(test_name_display, "CGraphDmDacRam write disabled leaves memory unchanged");
        wait until falling_edge(clk);
        ReadAddressController <= 0;
        ReadAddressDac <= 1;
        ReadAddressChannel <= 2;
        WriteAddress <= flat_address(0, 1, 2);
        DacSetpointIn <= x"AAAAAA";
        WriteReq <= '0';
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"010102", "WriteReq low does not modify stored data");

        set_test_name(test_name_display, "CGraphDmDacRam overwrite existing location");
        write_word(WriteAddress, DacSetpointIn, WriteReq, flat_address(0, 1, 2), x"0F0F0F");
        read_expect(ReadAddressController, ReadAddressDac, ReadAddressChannel, 0, 1, 2, x"0F0F0F", "Overwrite updates the selected decoded location");
        read_expect(ReadAddressController, ReadAddressDac, ReadAddressChannel, LAST_CONTROLLER, LAST_DAC, LAST_CHANNEL, x"FEDCBA", "Overwrite does not disturb another location");

        set_test_name(test_name_display, "CGraphDmDacRam registered read address change");
        wait until falling_edge(clk);
        ReadAddressController <= 0;
        ReadAddressDac <= 0;
        ReadAddressChannel <= 0;
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"000001", "Baseline read returns the previous selected location");
        ReadAddressController <= LAST_CONTROLLER;
        ReadAddressDac <= LAST_DAC;
        ReadAddressChannel <= LAST_CHANNEL;
        assert_equal(DacSetpointOut, x"000001", "Output holds prior value until the next read clock edge");
        wait until falling_edge(clk);
        assert_equal(DacSetpointOut, x"FEDCBA", "Output updates after the next read clock edge");

        set_test_name(test_name_display, "CGraphDmDacRam reset drives output low after writes");
        reset_dut(clk, rst);
        assert_equal(DacSetpointOut, (DacSetpointOut'range => '0'), "Reset clears the registered output after memory activity");

        finish;
    end process;

    dut : entity work.DmDacRamPorts
        port map (
            clk => clk,
            rst => rst,
            ReadAddressController => ReadAddressController,
            ReadAddressDac => ReadAddressDac,
            ReadAddressChannel => ReadAddressChannel,
            WriteAddress => WriteAddress,
            DacSetpointIn => DacSetpointIn,
            DacSetpointOut => DacSetpointOut,
            WriteReq => WriteReq
        );

end architecture sim;
