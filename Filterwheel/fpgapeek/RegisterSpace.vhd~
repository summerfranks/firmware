--------------------------------------------------------------------------------
-- UA Extra-Solar Camera PZT Controller Project FPGA Firmware
--
-- Register Space Definitions & Interface
--
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

entity RegisterSpacePorts is
	generic (
		ADDRESS_BITS : natural := 10--;
		--~ FIFO_BITS : natural := 9--;
	);
	port (
	
		clk : in std_logic;
		rst : in std_logic;
		
		-- Bus:
		Address : in std_logic_vector(ADDRESS_BITS - 1 downto 0); -- this is fucked, but vhdl can't figure out that ADDRESS_BITS is a constant because it's in a generic map...
		DataIn : in std_logic_vector(15 downto 0);
		DataOut : out std_logic_vector(15 downto 0);
		ReadReq : in  std_logic;
		WriteReq : in std_logic;
		ReadAck : out std_logic;
		WriteAck : out std_logic;
		
		--Data to access:			

		--Infrastructure
		SerialNumber : in std_logic_vector(31 downto 0);
		BuildNumber : in std_logic_vector(31 downto 0);
		
		--Motor
		MotorEnable : out std_logic;
		MotorSeekStep : out std_logic_vector(15 downto 0);
		MotorCurrentStep : in std_logic_vector(15 downto 0);
		ResetSteps : out std_logic;
		MotorA+ : in std_logic;
		MotorA- : in std_logic;
		MotorB+ : in std_logic;
		MotorB- : in std_logic;
		
		--Sensors
		PosLedsEnA : out std_logic;
		PosLedsEnB : out std_logic;
				
		PosSenseHomeA : in std_logic;
		PosSenseBit0A : in std_logic;
		PosSenseBit1A : in std_logic;
		PosSenseBit2A : in std_logic;
		PosSenseHomeB : in std_logic;
		PosSenseBit0B : in std_logic;
		PosSenseBit1B : in std_logic;
		PosSenseBit2B : in std_logic;
		
		PosSenseA : in std_logic_vector(3 downto 0);
		PosSenseB : in std_logic_vector(3 downto 0);
		
		PosDetHomeAOnStep : in std_logic_vector(15 downto 0);
		PosDetHomeAOffStep : in std_logic_vector(15 downto 0);
		PosDetA0OnStep : in std_logic_vector(15 downto 0);
		PosDetA0OffStep : in std_logic_vector(15 downto 0);
		PosDetA1OnStep : in std_logic_vector(15 downto 0);
		PosDetA1OffStep : in std_logic_vector(15 downto 0);
		PosDetA2OnStep : in std_logic_vector(15 downto 0);
		PosDetA2OffStep : in std_logic_vector(15 downto 0);
		
		PosDetHomeBOnStep : in std_logic_vector(15 downto 0);
		PosDetHomeBOffStep : in std_logic_vector(15 downto 0);
		PosDetB0OnStep : in std_logic_vector(15 downto 0);
		PosDetB0OffStep : in std_logic_vector(15 downto 0);
		PosDetB1OnStep : in std_logic_vector(15 downto 0);
		PosDetB1OffStep : in std_logic_vector(15 downto 0);
		PosDetB2OnStep : in std_logic_vector(15 downto 0);
		PosDetB2OffStep : in std_logic_vector(15 downto 0);
		
		PosDet0AOnStep : in std_logic_vector(15 downto 0);
		PosDet0AOffStep : in std_logic_vector(15 downto 0);
		PosDet1AOnStep : in std_logic_vector(15 downto 0);
		PosDet1AOffStep : in std_logic_vector(15 downto 0);
		PosDet2AOnStep : in std_logic_vector(15 downto 0);
		PosDet2AOffStep : in std_logic_vector(15 downto 0);
		PosDet3AOnStep : in std_logic_vector(15 downto 0);
		PosDet3AOffStep : in std_logic_vector(15 downto 0);
		PosDet4AOnStep : in std_logic_vector(15 downto 0);
		PosDet4AOffStep : in std_logic_vector(15 downto 0);
		PosDet5AOnStep : in std_logic_vector(15 downto 0);
		PosDet5AOffStep : in std_logic_vector(15 downto 0);
		PosDet6AOnStep : in std_logic_vector(15 downto 0);
		PosDet6AOffStep : in std_logic_vector(15 downto 0);
		PosDet7AOnStep : in std_logic_vector(15 downto 0);
		PosDet7AOffStep : in std_logic_vector(15 downto 0);
		
		PosDet0BOnStep : in std_logic_vector(15 downto 0);
		PosDet0BOffStep : in std_logic_vector(15 downto 0);
		PosDet1BOnStep : in std_logic_vector(15 downto 0);
		PosDet1BOffStep : in std_logic_vector(15 downto 0);
		PosDet2BOnStep : in std_logic_vector(15 downto 0);
		PosDet2BOffStep : in std_logic_vector(15 downto 0);
		PosDet3BOnStep : in std_logic_vector(15 downto 0);
		PosDet3BOffStep : in std_logic_vector(15 downto 0);
		PosDet4BOnStep : in std_logic_vector(15 downto 0);
		PosDet4BOffStep : in std_logic_vector(15 downto 0);
		PosDet5BOnStep : in std_logic_vector(15 downto 0);
		PosDet5BOffStep : in std_logic_vector(15 downto 0);
		PosDet6BOnStep : in std_logic_vector(15 downto 0);
		PosDet6BOffStep : in std_logic_vector(15 downto 0);
		PosDet7BOnStep : in std_logic_vector(15 downto 0);
		PosDet7BOffStep : in std_logic_vector(15 downto 0)
		
		
		--Monitor A/D:
		MonitorAdcChannelReadIndex : out std_logic_vector(4 downto 0);
		ReadMonitorAdcSample : out std_logic;
		MonitorAdcSampleToRead : in std_logic_vector(63 downto 0);
		
		--RS-422
		Uart0FifoReset : out std_logic;
		ReadUart0 : out std_logic;
		Uart0RxFifoFull : in std_logic;
		Uart0RxFifoEmpty : in std_logic;
		Uart0RxFifoData : in std_logic_vector(7 downto 0);
		Uart0RxFifoCount : in std_logic_vector(9 downto 0);
		WriteUart0 : out std_logic;
		Uart0TxFifoFull : in std_logic;
		Uart0TxFifoEmpty : in std_logic;
		Uart0TxFifoData : out std_logic_vector(7 downto 0);
		Uart0TxFifoCount : in std_logic_vector(9 downto 0);
		Uart0ClkDivider : out std_logic_vector(7 downto 0);
		
		Uart1FifoReset : out std_logic;
		ReadUart1 : out std_logic;
		Uart1RxFifoFull : in std_logic;
		Uart1RxFifoEmpty : in std_logic;
		Uart1RxFifoData : in std_logic_vector(7 downto 0);
		Uart1RxFifoCount : in std_logic_vector(9 downto 0);
		WriteUart1 : out std_logic;
		Uart1TxFifoFull : in std_logic;
		Uart1TxFifoEmpty : in std_logic;
		Uart1TxFifoData : out std_logic_vector(7 downto 0);
		Uart1TxFifoCount : in std_logic_vector(9 downto 0);
		Uart1ClkDivider : out std_logic_vector(7 downto 0);
		
		Uart2FifoReset : out std_logic;
		ReadUart2 : out std_logic;
		Uart2RxFifoFull : in std_logic;
		Uart2RxFifoEmpty : in std_logic;
		Uart2RxFifoData : in std_logic_vector(7 downto 0);
		Uart2RxFifoCount : in std_logic_vector(9 downto 0);
		WriteUart2 : out std_logic;
		Uart2TxFifoFull : in std_logic;
		Uart2TxFifoEmpty : in std_logic;
		Uart2TxFifoData : out std_logic_vector(7 downto 0);
		Uart2TxFifoCount : in std_logic_vector(9 downto 0);
		Uart2ClkDivider : out std_logic_vector(7 downto 0);

		--Timing
		IdealTicksPerSecond : in std_logic_vector(31 downto 0);
		ActualTicksLastSecond : in std_logic_vector(31 downto 0);
		PPSCountReset : out std_logic;
		ClockTicksThisSecond : in std_logic_vector(31 downto 0);				
		ClkDacWrite : out std_logic_vector(15 downto 0);
		WriteClkDac : out std_logic;
		ClkDacReadback : in std_logic_vector(15 downto 0)--;
	);
end RegisterSpacePorts;

architecture RegisterSpace of RegisterSpacePorts is

	-- this is fucked, but vhdl can't figure out that ADDRESS_BITS is a constant because it's in a generic map...so we do this whole circle-jerk
	--~ constant MAX_ADDRESS_BITS : natural := 8;
	constant MAX_ADDRESS_BITS : natural := ADDRESS_BITS;
	signal Address_i : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0);
	
	constant DeviceSerialNumberAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(0, MAX_ADDRESS_BITS));
	constant FpgaFirmwareBuildNumberAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(4, MAX_ADDRESS_BITS));

	constant UnixSecondsAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(8, MAX_ADDRESS_BITS)); --we have guard addresses on all fifos because accidental reading still removes a char from the fifo.
	constant IdealTicksPerSecondAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(12, MAX_ADDRESS_BITS));
	constant ActualTicksLastSecondAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(16, MAX_ADDRESS_BITS));
	constant ClockTicksThisSecondAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(20, MAX_ADDRESS_BITS));
	constant ClockSteeringDacSetpointAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(24, MAX_ADDRESS_BITS));

	constant Reserved0Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(28, MAX_ADDRESS_BITS));

	constant MotorControlStatusAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(32, MAX_ADDRESS_BITS));
	constant PosSensAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(36, MAX_ADDRESS_BITS));
	constant Reserved1Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(40, MAX_ADDRESS_BITS));

	constant Reserved2Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(48, MAX_ADDRESS_BITS));
	constant Reserved3Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(56, MAX_ADDRESS_BITS)); --should be contiguous with AdcSample so we can get the whole thing with an 8-byte xfer...
	constant Reserved4Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(64, MAX_ADDRESS_BITS));
	constant Reserved5Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(72, MAX_ADDRESS_BITS));
	constant Reserved6Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(80, MAX_ADDRESS_BITS));

	constant ControlRegisterAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(88, MAX_ADDRESS_BITS)); --we have guard addresses on all fifos because accidental reading still removes a char from the fifo.

	constant Reserved7Addr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(92, MAX_ADDRESS_BITS));

	constant PPSRtcPhaseCmpAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(96, MAX_ADDRESS_BITS));
	constant PPSAdcPhaseCmpAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(100, MAX_ADDRESS_BITS));

	constant MonitorAdcSample : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(104, MAX_ADDRESS_BITS));
	constant MonitorAdcReadChannel : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(112, MAX_ADDRESS_BITS));

	constant Uart2FifoAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(116, MAX_ADDRESS_BITS));
	constant Uart2FifoStatusAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(120, MAX_ADDRESS_BITS));
	constant Uart1FifoAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(124, MAX_ADDRESS_BITS));
	constant Uart1FifoStatusAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(128, MAX_ADDRESS_BITS));
	constant Uart0FifoAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(132, MAX_ADDRESS_BITS));
	constant Uart0FifoStatusAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(136, MAX_ADDRESS_BITS));
	constant UartClockDividersAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(140, MAX_ADDRESS_BITS));
	
	constant PosDetHomeAOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(148, MAX_ADDRESS_BITS));
	constant PosDetHomeAOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(150, MAX_ADDRESS_BITS));
	constant PosDetA0OnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(152, MAX_ADDRESS_BITS));
	constant PosDetA0OffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(154, MAX_ADDRESS_BITS));
	constant PosDetA1OnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(156, MAX_ADDRESS_BITS));
	constant PosDetA1OffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(158, MAX_ADDRESS_BITS));
	constant PosDetA2OnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(160, MAX_ADDRESS_BITS));
	constant PosDetA2OffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(162, MAX_ADDRESS_BITS));
	
	constant PosDetHomeBOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(164, MAX_ADDRESS_BITS));
	constant PosDetHomeBOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(166, MAX_ADDRESS_BITS));
	constant PosDetB0OnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(168, MAX_ADDRESS_BITS));
	constant PosDetB0OffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(170, MAX_ADDRESS_BITS));
	constant PosDetB1OnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(172, MAX_ADDRESS_BITS));
	constant PosDetB1OffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(174, MAX_ADDRESS_BITS));
	constant PosDetB2OnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(176, MAX_ADDRESS_BITS));
	constant PosDetB2OffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(178, MAX_ADDRESS_BITS));
	
	constant PosDet0AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(180, MAX_ADDRESS_BITS));
	constant PosDet0AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(182, MAX_ADDRESS_BITS));
	constant PosDet1AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(184, MAX_ADDRESS_BITS));
	constant PosDet1AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(186, MAX_ADDRESS_BITS));
	constant PosDet2AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(188, MAX_ADDRESS_BITS));
	constant PosDet2AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(190, MAX_ADDRESS_BITS));
	constant PosDet3AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(192, MAX_ADDRESS_BITS));
	constant PosDet3AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(194, MAX_ADDRESS_BITS));
	constant PosDet4AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(196, MAX_ADDRESS_BITS));
	constant PosDet4AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(198, MAX_ADDRESS_BITS));
	constant PosDet5AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(200, MAX_ADDRESS_BITS));
	constant PosDet5AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(202, MAX_ADDRESS_BITS));
	constant PosDet6AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(204, MAX_ADDRESS_BITS));
	constant PosDet6AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(206, MAX_ADDRESS_BITS));
	constant PosDet7AOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(208, MAX_ADDRESS_BITS));
	constant PosDet7AOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(210, MAX_ADDRESS_BITS));
	
	constant PosDet0BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(212, MAX_ADDRESS_BITS));
	constant PosDet0BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(214, MAX_ADDRESS_BITS));
	constant PosDet1BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(216, MAX_ADDRESS_BITS));
	constant PosDet1BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(218, MAX_ADDRESS_BITS));
	constant PosDet2BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(220, MAX_ADDRESS_BITS));
	constant PosDet2BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(222, MAX_ADDRESS_BITS));
	constant PosDet3BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(224, MAX_ADDRESS_BITS));
	constant PosDet3BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(226, MAX_ADDRESS_BITS));
	constant PosDet4BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(228, MAX_ADDRESS_BITS));
	constant PosDet4BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(230, MAX_ADDRESS_BITS));
	constant PosDet5BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(232, MAX_ADDRESS_BITS));
	constant PosDet5BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(234, MAX_ADDRESS_BITS));
	constant PosDet6BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(236, MAX_ADDRESS_BITS));
	constant PosDet6BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(238, MAX_ADDRESS_BITS));
	constant PosDet7BOnStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(240, MAX_ADDRESS_BITS));
	constant PosDet7BOffStepAddr : std_logic_vector(MAX_ADDRESS_BITS - 1 downto 0) := std_logic_vector(to_unsigned(240, MAX_ADDRESS_BITS));
	
	--Control Signals
	
	signal LastReadReq :  std_logic := '0';		
	signal LastWriteReq :  std_logic := '0';		

	--~ signal Uart0ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(102000000) / ( real(38400) * 32.0)) - 1.0), 8));	--38.4k
	--~ signal Uart1ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(102000000) / ( real(230400) * 32.0)) - 1.0), 8));	--230k
	--~ signal Uart0ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(153000000) / ( real(38400) * 32.0)) - 1.0), 8));	--38.4k
	--~ signal Uart1ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(153000000) / ( real(230400) * 32.0)) - 1.0), 8));	--230k
	signal Uart0ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(102000000) / ( real(38400) * 16.0)) - 1.0), 8));	--38.4k
	signal Uart1ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(102000000) / ( real(230400) * 16.0)) - 1.0), 8));	--230k
	--~ signal Uart0ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(153000000) / ( real(38400) * 16.0)) - 1.0), 8));	--38.4k
	--~ signal Uart1ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(natural((real(153000000) / ( real(230400) * 16.0)) - 1.0), 8));	--230k
	signal Uart2ClkDivider_i : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(0, 8));	--"real fast"
	
	signal MonitorAdcChannelReadIndex_i : std_logic_vector(4 downto 0);	
	
	signal MotorSeekStep_i : std_logic_vector(15 downto 0);	
	signal PosLedsEnA_i :  std_logic := '0';	
	signal PosLedsEnB_i :  std_logic := '0';	
	signal ResetSteps_i :  std_logic := '0';	
	
begin

	--~ Address_i(MAX_ADDRESS_BITS - 1 downto ADDRESS_BITS) <= std_logic_vector(to_unsigned(0, MAX_ADDRESS_BITS - ADDRESS_BITS));
	--~ Address_i(ADDRESS_BITS - 1 downto 0) <= Address;
	--~ Address_i <= std_logic_vector(to_unsigned(0, MAX_ADDRESS_BITS - ADDRESS_BITS)) & Address;
	Address_i <= Address;
	
	Uart0ClkDivider <= Uart0ClkDivider_i;
	Uart1ClkDivider <= Uart1ClkDivider_i;
	Uart2ClkDivider <= Uart2ClkDivider_i;
	
	MotorSeekStep <= MotorSeekStep_i;
	PosLedsEnA <= PosLedsEnA_i;
	PosLedsEnB <= PosLedsEnB_i;
	ResetSteps <= ResetSteps_i;
	
	MonitorAdcChannelReadIndex <= MonitorAdcChannelReadIndex_i;
	
	process (clk, rst)
	begin
	
		if (rst = '1') then
		
			LastReadReq <= '0';			
			LastWriteReq <= '0';		
			
		else
			
			if ( (clk'event) and (clk = '1') ) then
			
				--~ LastReadReq <= ReadReq;			
				--~ LastWriteReq <= WriteReq;			
										
				if (ReadReq = '1') then
				
					--ReadReq Rising Edge
					if (LastReadReq = '0') then
					
						LastReadReq <= '1';
					
						--~ DataOut <= x"77";
						
						ReadAck <= '1';
						
						--~ DataOut <= Address_i(7 downto 0);
							
						case Address_i is
						
						
							--Serial Number
							
							when DeviceSerialNumberAddr =>

								DataOut <= SerialNumber(15 downto 0);
								
							when DeviceSerialNumberAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								DataOut <= SerialNumber(31 downto 16);

							

							--Build Number
							
							when FpgaFirmwareBuildNumberAddr =>

								DataOut <= BuildNumber(15 downto 0);

							when FpgaFirmwareBuildNumberAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								DataOut <= BuildNumber(31 downto 16);

							
								
							--Monitor A/D
							
							when MonitorAdcSample =>

								DataOut <= MonitorAdcSampleToRead(15 downto 0);
						
							when MonitorAdcSample + x"02" =>

								DataOut <= MonitorAdcSampleToRead(31 downto 16);
							
							when MonitorAdcSample + x"04" =>

								DataOut <= MonitorAdcSampleToRead(47 downto 32);
														
							when MonitorAdcSample + x"06" =>

								DataOut <= MonitorAdcSampleToRead(63 downto 48);
														
							when MonitorAdcReadChannel =>

								DataOut(4 downto 0) <= MonitorAdcChannelReadIndex_i;
								DataOut(7 downto 5) <= "000";
					


							--RS-422
								
							when Uart0FifoAddr =>

								ReadUart0 <= '1';
								DataOut(7 downto 0) <= Uart0RxFifoData; --note that as the fifo hasn't actually had time to do the read yet, this will actually be the previous byte
								
							when Uart0FifoAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								--~ DataOut(7 downto 0) <= x"00";
								DataOut(7 downto 0) <= Uart0RxFifoData;
								DataOut(15 downto 8) <= x"00";
								
							when Uart0FifoStatusAddr =>

								DataOut(7) <= '0';
								DataOut(6) <= '0';
								DataOut(5) <= '0';
								DataOut(4) <= '0';
								DataOut(3) <= Uart0TxFifoFull;
								DataOut(2) <= Uart0TxFifoEmpty;
								DataOut(1) <= Uart0RxFifoFull;
								DataOut(0) <= Uart0RxFifoEmpty;
								--~ DataOut(15 downto 8) <= x"00";
								DataOut(15 downto 8) <= Uart0RxFifoCount(7 downto 0);
								
							when Uart0FifoStatusAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>
						
								DataOut(7 downto 0) <= Uart0TxFifoCount(7 downto 0);
								DataOut(15) <= '0';
								DataOut(14) <= '0';
								DataOut(13) <= '0';
								DataOut(12) <= '0';
								DataOut(11) <= Uart0TxFifoCount(9);
								DataOut(10) <= Uart0TxFifoCount(8);
								DataOut(9) <= Uart0RxFifoCount(9);
								DataOut(8) <= Uart0RxFifoCount(8);
						
						
						
							when Uart1FifoAddr =>

								ReadUart1 <= '1';
								DataOut(7 downto 0) <= Uart1RxFifoData; --note that as the fifo hasn't actually had time to do the read yet, this will actually be the previous byte
								
							when Uart1FifoAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								--~ DataOut(7 downto 0) <= x"00";
								DataOut(7 downto 0) <= Uart1RxFifoData;
								DataOut(15 downto 8) <= x"00";
								
							when Uart1FifoStatusAddr =>

								DataOut(7) <= '0';
								DataOut(6) <= '0';
								DataOut(5) <= '0';
								DataOut(4) <= '0';
								DataOut(3) <= Uart1TxFifoFull;
								DataOut(2) <= Uart1TxFifoEmpty;
								DataOut(1) <= Uart1RxFifoFull;
								DataOut(0) <= Uart1RxFifoEmpty;
								--~ DataOut(15 downto 8) <= x"00";
								DataOut(15 downto 8) <= Uart1RxFifoCount(7 downto 0);
								
							when Uart1FifoStatusAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>
						
								DataOut(7 downto 0) <= Uart1TxFifoCount(7 downto 0);
								DataOut(15) <= '0';
								DataOut(14) <= '0';
								DataOut(13) <= '0';
								DataOut(12) <= '0';
								DataOut(11) <= Uart1TxFifoCount(9);
								DataOut(10) <= Uart1TxFifoCount(8);
								DataOut(9) <= Uart1RxFifoCount(9);
								DataOut(8) <= Uart1RxFifoCount(8);
						
							
							
							when Uart2FifoAddr =>

								ReadUart2 <= '1';
								DataOut(7 downto 0) <= Uart2RxFifoData; --note that as the fifo hasn't actually had time to do the read yet, this will actually be the previous byte
								
							when Uart2FifoAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								--~ DataOut(7 downto 0) <= x"00";
								DataOut(7 downto 0) <= Uart2RxFifoData;
								DataOut(15 downto 8) <= x"00";
								
							when Uart2FifoStatusAddr =>

								DataOut(7) <= '0';
								DataOut(6) <= '0';
								DataOut(5) <= '0';
								DataOut(4) <= '0';
								DataOut(3) <= Uart2TxFifoFull;
								DataOut(2) <= Uart2TxFifoEmpty;
								DataOut(1) <= Uart2RxFifoFull;
								DataOut(0) <= Uart2RxFifoEmpty;
								--~ DataOut(15 downto 8) <= x"00";
								DataOut(15 downto 8) <= Uart2RxFifoCount(7 downto 0);
								
							when Uart2FifoStatusAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>
						
								DataOut(7 downto 0) <= Uart2TxFifoCount(7 downto 0);
								DataOut(15) <= '0';
								DataOut(14) <= '0';
								DataOut(13) <= '0';
								DataOut(12) <= '0';
								DataOut(11) <= Uart2TxFifoCount(9);
								DataOut(10) <= Uart2TxFifoCount(8);
								DataOut(9) <= Uart2RxFifoCount(9);
								DataOut(8) <= Uart2RxFifoCount(8);
								

							--Uart Clock dividers
							when UartClockDividersAddr =>

								DataOut(7 downto 0) <= Uart0ClkDivider_i;
								DataOut(15 downto 8) <= Uart1ClkDivider_i;

							when UartClockDividersAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								DataOut(7 downto 0) <= Uart2ClkDivider_i;
								--~ DataOut(15 downto 8) <= Uart3ClkDivider_i;

												
							--Timing
				
							--IdealTicksPerSecond
							when IdealTicksPerSecondAddr =>

								DataOut <= IdealTicksPerSecond(15 downto 0);
								
							when IdealTicksPerSecondAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								DataOut <= IdealTicksPerSecond(31 downto 16);
								
								
							--ActualTicksLastSecond
							when ActualTicksLastSecondAddr =>

								DataOut <= ActualTicksLastSecond(15 downto 0);
								
							when ActualTicksLastSecondAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								DataOut <= ActualTicksLastSecond(31 downto 16);
								
								
							--ClockTicksThisSecond
							when ClockTicksThisSecondAddr =>

								DataOut <= ClockTicksThisSecond(15 downto 0);
								
							when ClockTicksThisSecondAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								DataOut <= ClockTicksThisSecond(31 downto 16);
								
							
								
							--ClockSteeringDacSetpointAddr
							when ClockSteeringDacSetpointAddr =>

								DataOut <= ClkDacReadback
								
								
								
							--MotorControlStatusAddr
							when MotorControlStatusAddr =>

								DataOut <= MotorSeekStep_i;
								
							when MotorControlStatusAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>
							
								DataOut <= MotorCurrentStep;
								
								
								
							--ControlRegisterAddr
							when ControlRegisterAddr =>

								DataOut(0) <= PosLedsEnA_i;
								DataOut(1) <= PosLedsEnB_i;
								DataOut(2) <= MotorEnable_i;
								DataOut(3) <= ResetSteps_i;								
								DataOut(4) <= MotorA+;
								DataOut(5) <= MotorA-;
								DataOut(6) <= MotorB+;
								DataOut(7) <= MotorB-;
								DataOut(15 downto 8) <= "00000000";
								

							--PosSensAddr
							when PosSensAddr =>
							
								DataOut(0) <= PosSenseHomeA;
								DataOut(1) <= PosSenseBit0A;
								DataOut(2) <= PosSenseBit1A;
								DataOut(3) <= PosSenseBit2A;
								DataOut(4) <= PosSenseHomeB;
								DataOut(5) <= PosSenseBit0B;
								DataOut(6) <= PosSenseBit1B;
								DataOut(7) <= PosSenseBit2B;
								DataOut(11 downto 8) <= PosSenseA;
								DataOut(15 downto 12) <= PosSenseB;
								
							
							--The infinity of step latches
							when PosDetHomeAOnStepAddr => DataOut <= PosDetHomeAOnStep;
							when PosDetHomeAOffStepAddr => DataOut <= PosDetHomeAOffStep;
							when PosDetA0OnStepAddr => DataOut <= PosDetA0OnStep;
							when PosDetA0OffStepAddr => DataOut <= PosDetA0OffStep;
							when PosDetA1OnStepAddr => DataOut <= PosDetA1OnStep;
							when PosDetA1OffStepAddr => DataOut <= PosDetA1OffStep;
							when PosDetA2OnStepAddr => DataOut <= PosDetA2OnStep;
							when PosDetA2OffStepAddr => DataOut <= PosDetA2OffStep;
							
							when PosDetHomeBOnStepAddr => DataOut <= PosDetHomeBOnStep;
							when PosDetHomeBOffStepAddr => DataOut <= PosDetHomeBOffStep;
							when PosDetA0OnStepAddr => DataOut <= PosDetA0OnStep;
							when PosDetA0OffStepAddr => DataOut <= PosDetA0OffStep;
							when PosDetA1OnStepAddr => DataOut <= PosDetA1OnStep;
							when PosDetA1OffStepAddr => DataOut <= PosDetA1OffStep;
							when PosDetA2OnStepAddr => DataOut <= PosDetA2OnStep;
							when PosDetA2OffStepAddr => DataOut <= PosDetA2OffStep;
							
							when PosDet0AOnStepAddr => DataOut <= PosDet0AOnStep;
							when PosDet0AOffStepAddr => DataOut <= PosDet0AOffStep;
							when PosDet1AOnStepAddr => DataOut <= PosDet1AOnStep;
							when PosDet1AOffStepAddr => DataOut <= PosDet1AOffStep;
							when PosDet2AOnStepAddr => DataOut <= PosDet2AOnStep;
							when PosDet2AOffStepAddr => DataOut <= PosDet2AOffStep;
							when PosDet3AOnStepAddr => DataOut <= PosDet3AOnStep;
							when PosDet3AOffStepAddr => DataOut <= PosDet3AOffStep;
							when PosDet4AOnStepAddr => DataOut <= PosDet4AOnStep;
							when PosDet4AOffStepAddr => DataOut <= PosDet4AOffStep;
							when PosDet5AOnStepAddr => DataOut <= PosDet5AOnStep;
							when PosDet5AOffStepAddr => DataOut <= PosDet5AOffStep;
							when PosDet6AOnStepAddr => DataOut <= PosDet6AOnStep;
							when PosDet6AOffStepAddr => DataOut <= PosDet6AOffStep;
							when PosDet7AOnStepAddr => DataOut <= PosDet7AOnStep;
							when PosDet7AOffStepAddr => DataOut <= PosDet7AOffStep;
							
							when PosDet0BOnStepAddr => DataOut <= PosDet0BOnStep;
							when PosDet0BOffStepAddr => DataOut <= PosDet0BOffStep;
							when PosDet1BOnStepAddr => DataOut <= PosDet1BOnStep;
							when PosDet1BOffStepAddr => DataOut <= PosDet1BOffStep;
							when PosDet2BOnStepAddr => DataOut <= PosDet2BOnStep;
							when PosDet2BOffStepAddr => DataOut <= PosDet2BOffStep;
							when PosDet3BOnStepAddr => DataOut <= PosDet3BOnStep;
							when PosDet3BOffStepAddr => DataOut <= PosDet3BOffStep;
							when PosDet4BOnStepAddr => DataOut <= PosDet4BOnStep;
							when PosDet4BOffStepAddr => DataOut <= PosDet4BOffStep;
							when PosDet5BOnStepAddr => DataOut <= PosDet5BOnStep;
							when PosDet5BOffStepAddr => DataOut <= PosDet5BOffStep;
							when PosDet6BOnStepAddr => DataOut <= PosDet6BOnStep;
							when PosDet6BOffStepAddr => DataOut <= PosDet6BOffStep;
							when PosDet7BOnStepAddr => DataOut <= PosDet7BOnStep;
							when PosDet7BOffStepAddr => DataOut <= PosDet7BOffStep;
																	
							
							
							
							when others =>

								DataOut <= x"41";
								
						end case;
						
					end if;
					
				end if;
				
				if (ReadReq = '0') then
			
					--ReadReq falling edge				
					if (LastReadReq = '1') then
					
						LastReadReq <= '0';
					
						--If timing is good, this doesn't do anything. If the fpga is lagging the processor reads will all be 82's. Yeah, we tested that in practice.
						DataOut <= x"82"; 
						
						ReadAck <= '0';
						
						ReadAdcSample <= '0';		

						ReadUart0 <= '0';						
						ReadUart1 <= '0';						
						ReadUart2 <= '0';						
					
					end if;
					
				end if;

				if (WriteReq = '1') then
				
					--WriteReq Rising Edge
					if (LastWriteReq = '0') then
					
						LastWriteReq <= '1';
					
						WriteAck <= '1';
									
						case Address_i is
														
								
							--Monitor A/D
							when MonitorAdcReadChannel =>

								ReadMonitorAdcSample <= '1';
								MonitorAdcChannelReadIndex_i <= DataIn(4 downto 0);

								
							
							--RS-422
							
							when Uart0FifoAddr =>

								WriteUart0 <= '1';
								Uart0TxFifoData <= DataIn;
								
							when Uart0FifoStatusAddr =>

								Uart0FifoReset <= '1';
								
							when Uart1FifoAddr =>

								WriteUart1 <= '1';
								Uart1TxFifoData <= DataIn;
								
							when Uart1FifoStatusAddr =>

								Uart1FifoReset <= '1';
								
							when Uart2FifoAddr =>

								WriteUart2 <= '1';
								Uart2TxFifoData <= DataIn;
								
							when Uart2FifoStatusAddr =>

								Uart2FifoReset <= '1';
								
							--Uart Clock dividers
							when UartClockDividersAddr =>

								Uart0ClkDivider_i <= DataIn(7 downto 0);
								Uart1ClkDivider_i <= DataIn(15 downto 8);
								

							when UartClockDividersAddr + std_logic_vector(to_unsigned(2, MAX_ADDRESS_BITS)) =>

								Uart2ClkDivider_i <= DataIn(7 downto 0);
								--~ Uart3ClkDivider_i <= DataIn(15 downto 8);
								
								
														
							--Timing
						
							when ClockSteeringDacSetpointAddr =>

								PPSCountReset <= '1';
								WriteClkDac <= '1';
								
								ClkDacWrite <= DataIn;
								
								
								
								
							--MotorControlStatusAddr
							when MotorControlStatusAddr =>

								MotorSeekStep_i <= DataIn;
								
								
							--ControlRegisterAddr
							when ControlRegisterAddr =>

								PosLedsEnA_i <= DataIn(0);
								PosLedsEnB_i <= DataIn(1);
								MotorEnable_i <= DataIn(2);
								ResetSteps_i <= DataIn(3);
								
								

								
							when others => 


						end case;
						
					end if;

				end if;
				
				if (WriteReq = '0') then
			
					--WriteReq falling edge				
					if (LastWriteReq = '1') then
					
						LastWriteReq <= '0';
					
						WriteAck <= '0';
						
						ReadMonitorAdcSample <= '0';

						PPSCountReset <= '0';						
						
						WriteClkDac <= '0';		

						WriteUart0 <= '0';		
						Uart0FifoReset <= '0';						
						WriteUart1 <= '0';		
						Uart1FifoReset <= '0';						
						WriteUart2 <= '0';		
						Uart2FifoReset <= '0';						
					
					end if;
					
				end if;
				
			end if;

		end if;
		
	end process;

end RegisterSpace;
