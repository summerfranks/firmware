--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.CGraphTypes.all;
--~ use work.ads1258.all;
--~ use work.ads1258accumulator_pkg.all;

entity Main is
port (
    clk : in  std_logic;
    rst_in : in std_logic;
    rst_out : out std_logic;
	
	--ClkDac
	nCsXO : out std_logic;
	SckXO : out std_logic;
	MosiXO : out std_logic;
	
	--Light outputs
	PosLEDEnA : out std_logic;
	PosLEDEnB : out std_logic;
	
	--Photodetector Inputs
	PosSenseHomeA : in std_logic;
	PosSenseBit0A : in std_logic;
	PosSenseBit1A : in std_logic;
	PosSenseBit2A : in std_logic;
	PosSenseHomeB : in std_logic;
	PosSenseBit0B : in std_logic;
	PosSenseBit1B : in std_logic;
	PosSenseBit2B : in std_logic;
	
	--H-Bridge
	MotorDriveAPlus : out std_logic;
	MotorDriveAMinus : out std_logic;
	MotorDriveBPlus : out std_logic;
	MotorDriveBMinus : out std_logic;
	MotorDriveAPlusPrime : out std_logic;
	MotorDriveAMinusPrime : out std_logic;
	MotorDriveBPlusPrime : out std_logic;
	MotorDriveBMinusPrime : out std_logic;
	
	--uC Ram Bus 
	RamBusAddress : in std_logic_vector(9 downto 0); 
	RamBusDataIn : in std_logic_vector(31 downto 0);
	RamBusDataOut : out std_logic_vector(31 downto 0);
	RamBusnCs : in std_logic;
	RamBusWrnRd : in std_logic;
	RamBusLatch : in std_logic;
	RamBusAck : out std_logic;
	
	--RS-422 (uses LVDS and/or Accel pins)
	Txd0 : out std_logic;
	Oe0 : out std_logic;
	Rxd0 : in std_logic;
	Txd1 : out std_logic;
	Oe1 : out std_logic;
	Rxd1 : in std_logic;
	Txd2 : out std_logic;
	Oe2 : out std_logic;
	Rxd2 : in std_logic;
	Txd3 : out std_logic;
	Oe3 : out std_logic;
	Rxd3 : in std_logic;
	
	RxdUsb : out std_logic;
	TxdUsb : in std_logic;
	CtsUsb : out std_logic;
	
	TxdGps : out std_logic;
	RxdGps : in std_logic;
	PPS : in std_logic;
	
	--MonitorA/D
	
	nCsMonAdc0 : out std_logic;
	SckMonAdc0 : out std_logic;
	MosiMonAdc0 : out std_logic;
	MisoMonAdc0 : in std_logic;
	nDrdyMonAdc0 : in std_logic;
	
	--  Discrete I/O Connections

		--Faults
		nFaultClr1V : out std_logic;
		nFaultClr3V : out std_logic;
		nFaultClr5V : out std_logic;
		nPowerCycClr : out std_logic;
		PowernEn5V : out std_logic;
		PowerSync : out std_logic;
		Fault1V : in std_logic;
		Fault3V : in std_logic;
		Fault5V : in std_logic;
		PowerCycd: in std_logic;
		
		LedR : out std_logic;
		LedG : out std_logic;
		LedB : out std_logic;
		
		TP1 : out std_logic;
		TP2 : out std_logic;
		TP3 : out std_logic;
		TP4 : out std_logic;
		TP5 : out std_logic;
		TP6 : out std_logic;
		TP7 : out std_logic;
		TP8 : out std_logic;
		
		Ux1SelJmp : inout std_logic--;
		--Ux2SelJmp : out std_logic--; --currently used for INIT_DONE
);
end Main;

architecture architecture_Main of Main is
   
						component IBufP1Ports is
						port (
							clk : in std_logic;
							I : in std_logic;
							O : out std_logic--;
						);
						end component;

						component IOBufP1Ports is
						port (
							clk : in std_logic;
							IO  : inout std_logic;
							T : in std_logic;
							I : in std_logic;
							O : out std_logic--;
						);
						end component;
	
						component IBufP2Ports is
						port (
							clk : in std_logic;
							I : in std_logic;
							O : out std_logic--;
						);
						end component;

						component IOBufP2Ports is
						port (
							clk : in std_logic;
							IO  : inout std_logic;
							T : in std_logic;
							I : in std_logic;
							O : out std_logic--;
						);
						end component;
						
						component IBufP3Ports is
						port (
							clk : in std_logic;
							I : in std_logic;
							O : out std_logic--;
						);
						end component;

						component IOBufP3Ports is
						port (
							clk : in std_logic;
							IO  : inout std_logic;
							T : in std_logic;
							I : in std_logic;
							O : out std_logic--;
						);
						end component;
	
						component ClockDivider2XPorts is
						generic (
							CLOCK_DIVIDER : natural := 10;
							DIVOUT_RST_STATE : std_logic := '0'--;
						);
						port (
						
							clk : in std_logic;
							rst : in std_logic;
							div : out std_logic
						);
						end component;
						
						component VariableClockDivider2XPorts is
						generic (
							WIDTH_BITS : natural := 8;
							DIVOUT_RST_STATE : std_logic := '0'--;
						);
						port 
						(						
							clki : in std_logic;
							rst : in std_logic;
							rst_count : in std_logic_vector(WIDTH_BITS - 1 downto 0);
							terminal_count : in std_logic_vector(WIDTH_BITS - 1 downto 0);
							clko : out std_logic
						);
						end component;
						
						component OneShotPorts is
						generic (
							CLOCK_FREQHZ : natural := 10000000;
							DELAY_SECONDS : real := 0.001;
							SHOT_RST_STATE : std_logic := '0';
							SHOT_PRETRIGGER_STATE : std_logic := '0'--;
						);
						port (	
							clk : in std_logic;
							rst : in std_logic;
							shot : out std_logic
						);
						end component;
						
						component BuildNumberPorts is
						port (
							BuildNumber : out std_logic_vector(31 downto 0)--;
						);
						end component;
						
						component ClockMultiplierPorts is
						generic (
							CLOCK_DIVIDER : natural := 1;
							CLOCK_MULTIPLIER : natural := 2;
							CLOCK_FREQ_KHZ : real := 10000.0--;
						);
						port (
								rst : in std_logic;
								clkin : in std_logic;
								clkout : out std_logic;
								locked : out std_logic--;
						);
						end component;

						component SpiDacPorts is
						generic (
							MASTER_CLOCK_FREQHZ : natural := 100000000;
							BIT_WIDTH : natural := 24--;
						);
						port (
						
							--Globals
							clk : in std_logic;
							rst : in std_logic;
							
							-- D/A:
							nCs : out std_logic;
							Sck : out std_logic;
							Mosi : out  std_logic;
							Miso : in  std_logic;
							
							--Control signals
							DacWriteOut : in std_logic_vector(BIT_WIDTH - 1 downto 0);
							WriteDac : in std_logic;
							DacReadback : out std_logic_vector(BIT_WIDTH - 1 downto 0)--;
								
						); end component;
						
						component PPSCountPorts is
						port
						(
							clk : in std_logic;
							PPS : in std_logic;
							PPSReset : in std_logic;
							PPSDetected : out std_logic;
							PPSCounter : out std_logic_vector(31 downto 0);
							PPSAccum : out std_logic_vector(31 downto 0)--;
						);
						end component;

						component RtcCounterPorts is
						generic (
							CLOCK_FREQ : natural := 100000000--;
						);
						port
						(
							clk : in std_logic;
							rst : in std_logic;
							PPS : in std_logic;
							PPSDetected : out std_logic;
							Sync : in std_logic;
							GeneratedPPS : out std_logic;
							SetTimeSeconds : in std_logic_vector(21 downto 0);
							SetTime : in std_logic;
							SetChangedTime : out std_logic;
							Seconds : out std_logic_vector(21 downto 0);
							Milliseconds : out std_logic_vector(9 downto 0)--;
						);
						end component;
						
						component fifo is
						generic (
							WIDTH : natural := 32;
							DEPTH_BITS : natural := 9
						);
						port (
							clk		: in std_logic;
							rst		: in std_logic;
							wone_i	: in std_logic;
							data_i	: in std_logic_vector(WIDTH - 1 downto 0);
							rone_i	: in std_logic;
							full_o	: out std_logic;
							empty_o	: out std_logic;
							data_o	: out std_logic_vector(WIDTH - 1 downto 0);
							count_o	: out std_logic_vector(DEPTH_BITS - 1 downto 0);
							r_ack : out std_logic--;
						);
						end component;
												
						component UartRxRaw is
						port (
							 Clk    : in  std_logic;  -- system clock signal
							 Reset  : in  std_logic;  -- Reset input
							 Enable : in  std_logic;  -- Enable input
							 --~ ReadA  : in  Std_logic;  -- Async Read Received Byte
							 RxD    : in  std_logic;  -- RS-232 data input
							 RxAv   : out std_logic;  -- Byte available
							 DataO  : out std_logic_vector(7 downto 0)--; -- Byte received
						);
						end component;
						
						component UartRx is
						generic (
							CLOCK_FREQHZ : natural := 14745600;
							BAUDRATE : natural := 38400--;
						);
						port (						
							clk : in std_logic;
							rst : in std_logic;
							UartClk : out std_logic; --debug
							Rxd : in std_logic; --external (async) uart data input pin
							RxComplete : out std_logic; --Just got a byte
							RxData : out std_logic_vector(7 downto 0) --The byte we just got		
						);
						end component;
						
						component UartRxFifo is
						generic 
						(
							UART_CLOCK_FREQHZ : natural := 14745600;
							FIFO_BITS : natural := 10;
							BAUDRATE : natural := 38400--;
						);
						port 
						(
							--Outside world:
							clk : in std_logic;
							uclk : in std_logic;
							rst : in std_logic;
							--External (async) uart data input pin
							Rxd : in std_logic; 
							Dbg1 : out std_logic; 
							--Read from fifo:
							ReadFifo	: in std_logic;
							FifoReadAck : out std_logic;
							FifoReadData : out std_logic_vector(7 downto 0);
							--Fifo status:
							FifoFull	: out std_logic;
							FifoEmpty	: out std_logic;
							FifoCount	: out std_logic_vector(FIFO_BITS - 1 downto 0)--;		
						);
						end component;
						
						component UartRxFifoExtClk is
						generic 
						(
							FIFO_BITS : natural := 10--;
						);
						port 
						(
							--Outside world:
							clk : in std_logic;
							uclk : in std_logic;
							rst : in std_logic;
							--External (async) uart data input pin
							Rxd : in std_logic; 
							Dbg1 : out std_logic; 
							RxComplete : out std_logic;
							--Read from fifo:
							ReadFifo	: in std_logic;
							FifoReadAck : out std_logic;
							FifoReadData : out std_logic_vector(7 downto 0);
							--Fifo status:
							FifoFull	: out std_logic;
							FifoEmpty	: out std_logic;
							FifoCount	: out std_logic_vector(FIFO_BITS - 1 downto 0)--;		
						);
						end component;
						
						component UartRxMultiFifo is
						generic 
						(
							FIFO_BITS : natural := 10;
							BAUD_DIVIDER_BITS : natural := 8--;
						);
						port 
						(
							--Outside world:
							clk : in std_logic;
							uclk : in std_logic;
							rst : in std_logic;
							BaudDivider : in std_logic_vector(BAUD_DIVIDER_BITS - 1 downto 0); --sets baud rate
							--External (async) uart data input pin
							Rxd : in std_logic; 
							--Read from fifo:
							ReadFifo	: in std_logic;
							FifoReadAck : out std_logic;
							FifoReadData : out std_logic_vector(7 downto 0);
							--Fifo status:
							FifoFull	: out std_logic;
							FifoEmpty	: out std_logic;
							FifoCount	: out std_logic_vector(FIFO_BITS - 1 downto 0)--;		
						);
						end component;
						
						component UartRxFifoExtClkPeek is
						port 
						(
							--Outside world:
							clk : in std_logic;
							uclk : in std_logic;
							rst : in std_logic;
							--External (async) uart data input pin
							Rxd : in std_logic; 
							Dbg1 : out std_logic; 
							Dbg2 : out std_logic;
							Dbg3 : out std_logic;
							RxComplete : out std_logic;
							--Read from fifo:
							ReadFifo	: in std_logic;
							FifoReadAck : out std_logic;
							FifoReadData : out std_logic_vector(7 downto 0);
							--Packet decodes:
							HeaderFound : out std_logic;
							FooterFound : out std_logic;
							HeaderEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
							FooterEndPos : out std_logic_vector(PeekRamDepth - 1 downto 0);
							PayloadType : out std_logic_vector(15 downto 0);
							PayloadLen : out std_logic_vector(15 downto 0);
							PacketCrc : out std_logic_vector(31 downto 0);
							CalcCrc : out std_logic_vector(31 downto 0);
							--Fifo status:
							FifoFull	: out std_logic;
							FifoEmpty	: out std_logic;
							FifoCount	: out std_logic_vector(PeekRamDepth - 1 downto 0);
							FifoReadAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
							FifoWriteAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
							FifoPeekAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
							FifoPeekData : out std_logic_vector(7 downto 0);
							FifoMultiPopAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
							FifoMultiPopStrobe : in std_logic--;		
						);
						end component;
						
						component UartRxMultiFifoPeek is
						generic 
						(
							DEPTH_BITS : natural := 10;
							BAUD_DIVIDER_BITS : natural := 8--;
						);
						port 
						(
							--Outside world:
							clk : in std_logic;
							uclk : in std_logic;
							rst : in std_logic;
							BaudDivider : in std_logic_vector(BAUD_DIVIDER_BITS - 1 downto 0); --sets baud rate
							--External (async) uart data input pin
							Rxd : in std_logic; 
							--Read from fifo:
							ReadFifo	: in std_logic;
							FifoReadAck : out std_logic;
							FifoReadData : out std_logic_vector(7 downto 0);
							--Fifo status:
							FifoFull	: out std_logic;
							FifoEmpty	: out std_logic;
							FifoCount	: out std_logic_vector(DEPTH_BITS - 1 downto 0)--;		
						);
						end component;

						component UartTx is
						port 
						(
							Clk    : in  Std_Logic;
							Reset  : in  Std_Logic;
							Go     : in  Std_Logic; --To initate a xfer, raise this bit and wait for busy to go high, then lower.
							TxD    : out Std_Logic;
							Busy   : out Std_Logic;
							Data  : in  Std_Logic_Vector(7 downto 0)--; --not latched; must be held constant while busy is high
						);
						end component;

						component UartTxFifo is
						generic 
						(
							UART_CLOCK_FREQHZ : natural := 14745600; --for making industry-standard baudrates
							FIFO_BITS : natural := 10;
							BAUDRATE : natural := 38400--;
						);
						port 
						(
							--global control signals
							clk : in std_logic; --generic clock base for fifo & control signals
							uclk : in std_logic; --clock base for correct uart speed (should be less than clk)
							rst : in std_logic; --global reset
							BitClockOut : out std_logic; --generally used for debug of divider values...		
							
							--'digital' side (backyard)
							WriteStrobe : in std_logic; --send byte to fifo
							WriteData : in std_logic_vector(7 downto 0); --the byte
							FifoFull : out std_logic; --fifo status:
							FifoEmpty : out std_logic; --fifo status:
							FifoCount : out std_logic_vector(FIFO_BITS - 1 downto 0); --fifo status:
							
							--'analog' side (frontyard)
							TxInProgress : out std_logic; --currently sending data...
							Cts : in std_logic;
							Txd : out std_logic--; --Uart data output pin (i.e. to RS-232 driver chip)
						);
						end component;
						
						component UartTxFifoExtClk is
						generic 
						(
							FIFO_BITS : natural := 10--;
						);
						port 
						(
							--global control signals
							clk : in std_logic; --generic clock base for fifo & control signals
							uclk : in std_logic; --clock base for correct uart speed (should be less than clk)
							rst : in std_logic; --global reset
							
							--'digital' side (backyard)
							WriteStrobe : in std_logic; --send byte to fifo
							WriteData : in std_logic_vector(7 downto 0); --the byte
							FifoFull : out std_logic; --fifo status:
							FifoEmpty : out std_logic; --fifo status:
							FifoCount : out std_logic_vector(FIFO_BITS - 1 downto 0); --fifo status:
							BitClockOut : out std_logic; --generally used for debug of divider values...		
							BitCountOut : out std_logic_vector(3 downto 0);
							
							--'analog' side (frontyard)
							TxInProgress : out std_logic; --currently sending data...
							Cts : in std_logic; --Are the folks on the other end actually ready for data if we have some? (Just tie it to zero if unused).
							Txd : out std_logic--; --Uart data output pin (i.e. to RS-232 driver chip)
						);
						end component;
						
						component SRamSlaveBusPorts is
						generic (
							INT_ADDRESS_BITS : natural := 8;
							INT_DATA_BITS : natural := 8;
							RAM_BASE_ADDR : std_logic_vector(15 downto 0) := x"6900"--; --bottom <INT_ADDRESS_BITS> lsb bits are ignored...
						);
						port (
							clk : in std_logic;
							--External bus signals:
							Addr : in std_logic_vector(15 downto 0);
							DataIn : in std_logic_vector(INT_DATA_BITS - 1 downto 0);
							DataOut : out std_logic_vector(INT_DATA_BITS - 1 downto 0);
							DataOutEn : out std_logic;
							OE : in std_logic;
							WE : in std_logic;
							--Internal bus signals:
							AddrMatch : out std_logic;
							IntAddress : out std_logic_vector(INT_ADDRESS_BITS - 1 downto 0);
							IntWriteData : out std_logic_vector(INT_DATA_BITS - 1 downto 0);
							IntWriteReq : out std_logic;
							IntWriteAck : in  std_logic;
							IntReadData : in std_logic_vector(INT_DATA_BITS - 1 downto 0);
							IntReadReq : out  std_logic;
							IntReadAck : in  std_logic
						);
						end component;
						
						component SpiRegistersPorts is
						port
						(
							ByteComplete : out std_logic;
							AddrLatched : out std_logic;
							
							clk : in std_logic;

							--Bus
							nCS : in std_logic;
							Mosi : in std_logic;
							Sck : in std_logic;
							Miso : out std_logic;
							nCsAck : out std_logic;

							--Registers
							Address : out std_logic_vector(6 downto 0);
							DataToWrite : out std_logic_vector(7 downto 0);
							DataWriteReq : out std_logic;
							DataWriteAck : in std_logic;
							DataFromRead : in std_logic_vector(7 downto 0);
							DataReadReq : out  std_logic;
							DataReadAck : in std_logic--;
						);
						end component;

						component RegisterSpacePorts is
						generic (
							ADDRESS_BITS : natural := 10;
							UART_FIFO_DEPTH_BITS : natural := 9--;
						);
						port (
											
							clk : in std_logic;
							rst : in std_logic;
							
							-- Bus:
							Address : in std_logic_vector(ADDRESS_BITS - 1 downto 0); -- vhdl can't figure out that ADDRESS_BITS is a constant because it's in a generic map...
							DataIn : in std_logic_vector(31 downto 0);
							DataOut : out std_logic_vector(31 downto 0);
							ReadReq : in  std_logic;
							WriteReq : in std_logic;
							ReadAck : out std_logic;
							WriteAck : out std_logic;
							
							--Data to access:			

							--Infrastructure
							SerialNumber : in std_logic_vector(31 downto 0);
							BuildNumber : in std_logic_vector(31 downto 0);
							
							--Faults and control
							Fault1V : in std_logic;
							Fault3V : in std_logic;
							Fault5V : in std_logic;
							nFaultClr1V : out std_logic;								
							nFaultClr3V : out std_logic;								
							nFaultClr5V : out std_logic;								
							PowernEn5V : out std_logic;								
							PowerCycd : in std_logic;
							nPowerCycClr : out std_logic;								
							LedR : out std_logic;
							LedG : out std_logic;
							LedB : out std_logic;
							Uart0OE : out std_logic;
							Uart1OE : out std_logic;
							Uart2OE : out std_logic;
							Uart3OE : out std_logic;				
							Ux1SelJmp : out std_logic;
							Ux2SelJmp : out std_logic;
							
							--Motor
							MotorEnable : out std_logic;
							--~ MotorSeekStep : out std_logic_vector(15 downto 0);
							--~ MotorCurrentStep : in std_logic_vector(15 downto 0);
							MotorSeekStep : out signed(15 downto 0);
							MotorCurrentStep : in signed(15 downto 0);
							ResetSteps : out std_logic;
							MotorAPlus : in std_logic;
							MotorAMinus : in std_logic;
							MotorBPlus : in std_logic;
							MotorBMinus : in std_logic;
							
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
							
							PosDetHomeAOnStep : in signed(15 downto 0);
							PosDetHomeAOffStep : in signed(15 downto 0);
							PosDetA0OnStep : in signed(15 downto 0);
							PosDetA0OffStep : in signed(15 downto 0);
							PosDetA1OnStep : in signed(15 downto 0);
							PosDetA1OffStep : in signed(15 downto 0);
							PosDetA2OnStep : in signed(15 downto 0);
							PosDetA2OffStep : in signed(15 downto 0);
							
							PosDetHomeBOnStep : in signed(15 downto 0);
							PosDetHomeBOffStep : in signed(15 downto 0);
							PosDetB0OnStep : in signed(15 downto 0);
							PosDetB0OffStep : in signed(15 downto 0);
							PosDetB1OnStep : in signed(15 downto 0);
							PosDetB1OffStep : in signed(15 downto 0);
							PosDetB2OnStep : in signed(15 downto 0);
							PosDetB2OffStep : in signed(15 downto 0);
							
							PosDet0AOnStep : in signed(15 downto 0);
							PosDet0AOffStep : in signed(15 downto 0);
							PosDet1AOnStep : in signed(15 downto 0);
							PosDet1AOffStep : in signed(15 downto 0);
							PosDet2AOnStep : in signed(15 downto 0);
							PosDet2AOffStep : in signed(15 downto 0);
							PosDet3AOnStep : in signed(15 downto 0);
							PosDet3AOffStep : in signed(15 downto 0);
							PosDet4AOnStep : in signed(15 downto 0);
							PosDet4AOffStep : in signed(15 downto 0);
							PosDet5AOnStep : in signed(15 downto 0);
							PosDet5AOffStep : in signed(15 downto 0);
							PosDet6AOnStep : in signed(15 downto 0);
							PosDet6AOffStep : in signed(15 downto 0);
							PosDet7AOnStep : in signed(15 downto 0);
							PosDet7AOffStep : in signed(15 downto 0);
							
							PosDet0BOnStep : in signed(15 downto 0);
							PosDet0BOffStep : in signed(15 downto 0);
							PosDet1BOnStep : in signed(15 downto 0);
							PosDet1BOffStep : in signed(15 downto 0);
							PosDet2BOnStep : in signed(15 downto 0);
							PosDet2BOffStep : in signed(15 downto 0);
							PosDet3BOnStep : in signed(15 downto 0);
							PosDet3BOffStep : in signed(15 downto 0);
							PosDet4BOnStep : in signed(15 downto 0);
							PosDet4BOffStep : in signed(15 downto 0);
							PosDet5BOnStep : in signed(15 downto 0);
							PosDet5BOffStep : in signed(15 downto 0);
							PosDet6BOnStep : in signed(15 downto 0);
							PosDet6BOffStep : in signed(15 downto 0);
							PosDet7BOnStep : in signed(15 downto 0);
							PosDet7BOffStep : in signed(15 downto 0);
							
							--Monitor A/D:
							MonitorAdcChannelReadIndex : out std_logic_vector(4 downto 0);
							ReadMonitorAdcSample : out std_logic;
							MonitorAdcSampleToRead : in std_logic_vector(63 downto 0);
							MonitorAdcReset : out std_logic;
							MonitorAdcSpiDataIn : out std_logic_vector(7 downto 0);
							MonitorAdcSpiDataOut : in std_logic_vector(7 downto 0);
							MonitorAdcSpiXferStart : out std_logic;
							MonitorAdcSpiXferDone : in std_logic;
							MonitorAdcnDrdy  : in std_logic;
							MonitorAdcSpiFrameEnable : out std_logic;
							
							--RS-422
							Uart0FifoReset : out std_logic;
							ReadUart0 : out std_logic;
							Uart0RxFifoFull : in std_logic;
							Uart0RxFifoEmpty : in std_logic;
							Uart0RxFifoData : in std_logic_vector(7 downto 0);
							Uart0RxFifoCount : in std_logic_vector(PeekRamDepth - 1 downto 0);
							WriteUart0 : out std_logic;
							Uart0TxFifoFull : in std_logic;
							Uart0TxFifoEmpty : in std_logic;
							Uart0TxFifoData : out std_logic_vector(7 downto 0);
							Uart0TxFifoCount : in std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0ClkDivider : out std_logic_vector(7 downto 0);
							Uart0RxFifoPeekReadAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0RxFifoPeekWriteAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0RxFifoPeekPeekAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0RxFifoPeekPeekData : in std_logic_vector(7 downto 0);
							Uart0RxFifoPeekMultiPopAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0RxFifoPeekMultiPopStrobe : out std_logic;		
							Uart0CrcStartAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0CrcEndAddr : out std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0CrcCurrentAddr : in std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0DoCrc : out std_logic;
							Uart0CrcDone : in std_logic;
							Uart0Crc : in std_logic_vector(31 downto 0);
							Uart0HeaderFound : in std_logic;
							Uart0FooterFound : in std_logic;
							Uart0HeaderEndPos : in std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0FooterEndPos : in std_logic_vector(PeekRamDepth - 1 downto 0);
							Uart0PayloadType : in std_logic_vector(15 downto 0);
							Uart0PayloadLen : in std_logic_vector(15 downto 0);
							Uart0PacketCrc : in std_logic_vector(31 downto 0);
							Uart0CalcCrc : in std_logic_vector(31 downto 0);
							
							Uart1FifoReset : out std_logic;
							ReadUart1 : out std_logic;
							Uart1RxFifoFull : in std_logic;
							Uart1RxFifoEmpty : in std_logic;
							Uart1RxFifoData : in std_logic_vector(7 downto 0);
							Uart1RxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							WriteUart1 : out std_logic;
							Uart1TxFifoFull : in std_logic;
							Uart1TxFifoEmpty : in std_logic;
							Uart1TxFifoData : out std_logic_vector(7 downto 0);
							Uart1TxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							Uart1ClkDivider : out std_logic_vector(7 downto 0);
							
							Uart2FifoReset : out std_logic;
							ReadUart2 : out std_logic;
							Uart2RxFifoFull : in std_logic;
							Uart2RxFifoEmpty : in std_logic;
							Uart2RxFifoData : in std_logic_vector(7 downto 0);
							Uart2RxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							WriteUart2 : out std_logic;
							Uart2TxFifoFull : in std_logic;
							Uart2TxFifoEmpty : in std_logic;
							Uart2TxFifoData : out std_logic_vector(7 downto 0);
							Uart2TxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							Uart2ClkDivider : out std_logic_vector(7 downto 0);
							
							Uart3FifoReset : out std_logic;
							ReadUart3 : out std_logic;
							Uart3RxFifoFull : in std_logic;
							Uart3RxFifoEmpty : in std_logic;
							Uart3RxFifoData : in std_logic_vector(7 downto 0);
							Uart3RxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							WriteUart3 : out std_logic;
							Uart3TxFifoFull : in std_logic;
							Uart3TxFifoEmpty : in std_logic;
							Uart3TxFifoData : out std_logic_vector(7 downto 0);
							Uart3TxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							Uart3ClkDivider : out std_logic_vector(7 downto 0);
							
							UartUsbFifoReset : out std_logic;
							ReadUartUsb : out std_logic;
							UartUsbRxFifoFull : in std_logic;
							UartUsbRxFifoEmpty : in std_logic;
							UartUsbRxFifoData : in std_logic_vector(7 downto 0);
							UartUsbRxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							WriteUartUsb : out std_logic;
							UartUsbTxFifoFull : in std_logic;
							UartUsbTxFifoEmpty : in std_logic;
							UartUsbTxFifoData : out std_logic_vector(7 downto 0);
							UartUsbTxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							UartUsbClkDivider : out std_logic_vector(7 downto 0);
							
							UartGpsFifoReset : out std_logic;
							ReadUartGps : out std_logic;
							UartGpsRxFifoFull : in std_logic;
							UartGpsRxFifoEmpty : in std_logic;
							UartGpsRxFifoData : in std_logic_vector(7 downto 0);
							UartGpsRxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							WriteUartGps : out std_logic;
							UartGpsTxFifoFull : in std_logic;
							UartGpsTxFifoEmpty : in std_logic;
							UartGpsTxFifoData : out std_logic_vector(7 downto 0);
							UartGpsTxFifoCount : in std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
							UartGpsClkDivider : out std_logic_vector(7 downto 0);
							
							--Timing
							IdealTicksPerSecond : in std_logic_vector(31 downto 0);
							ActualTicksLastSecond : in std_logic_vector(31 downto 0);
							ClockTicksThisSecond : in std_logic_vector(31 downto 0);
							PPSCountReset : out std_logic;		
							PPSDetected : in std_logic;
							ClkDacWrite : out std_logic_vector(15 downto 0);
							WriteClkDac : out std_logic;
							ClkDacReadback : in std_logic_vector(15 downto 0)--;
						);
						end component;
						
						--~ component ads1258Ports is
						--~ generic (
							--~ MASTER_CLOCK_FREQHZ : natural := 10000000--;
						--~ );
						--~ port (
						
							--~ clk : in std_logic;
							--~ rst : in std_logic;
							
							--~ -- A/D:
							--~ nDrdy : in std_logic;
							--~ nCsAdc : out std_logic;
							--~ Sck : out std_logic;
							--~ Mosi : out  std_logic;
							--~ Miso : in  std_logic;		
							
							--~ --Raw, Basic Spi Xfers
							--~ SpiDataIn : in std_logic_vector(7 downto 0);
							--~ SpiDataOut : out std_logic_vector(7 downto 0);
							--~ SpiXferStart : in std_logic;
							--~ SpiXferDone : out std_logic;
							
							--~ -- Bus / Fifos:
							--~ Sample : out ads1258sample;
							--~ SampleLatched : out std_logic;		
							--~ TimestampReq : out std_logic--;				
						--~ );
						--~ end component;
						
						--~ component ads1258accumulatorPorts is
						--~ port 
						--~ (
							--~ clk : in std_logic;
							--~ rst : in std_logic;
							
							--~ -- From A/D
							--~ AdcSampleIn : in ads1258sample;
							--~ AdcSampleLatched : in std_logic;		
							--~ AdcChannelLatched : out std_logic_vector(4 downto 0);
							
							--~ -- To Datamapper
							--~ AdcChannelReadIndex : in std_logic_vector(4 downto 0);
							--~ ReadAdcSample : in std_logic;		
							--~ AdcSampleToRead : out ads1258accumulator--;
						--~ );
						--~ end component;
						
						component SpiDevicePorts is
						generic (
							CLOCK_DIVIDER : natural := 4;
							BIT_WIDTH : natural := 8;
							CPOL : std_logic := '0'; --'standard' spi knob - inverts clock polarity (0 seems to be the standard, 1 less common)
							CPHA : std_logic := '0'--; --'standard' spi knob - inverts clock phase (0 seems to be the standard, 1 less common)
						);
						port (
						
							--Globals
							clk : in std_logic;
							rst : in std_logic;
							
							-- D/A:
							nCs : out std_logic;
							Sck : out std_logic;
							Mosi : out  std_logic;
							Miso : in  std_logic;
							
							--Control signals
							WriteOut : in std_logic_vector(BIT_WIDTH - 1 downto 0);
							Transfer : in std_logic;
							Readback : out std_logic_vector(BIT_WIDTH - 1 downto 0);
							TransferComplete : out std_logic--;
						); 
						end component;
						
						component gated_fifo is
						generic (
							WIDTH_BITS : natural := 32;
							DEPTH_BITS : natural := 9
						);
						port (
							clk		: in std_logic;
							rst		: in std_logic;
							wone_i	: in std_logic;
							data_i	: in std_logic_vector(WIDTH_BITS - 1 downto 0);
							rone_i	: in std_logic;
							full_o	: out std_logic;
							empty_o	: out std_logic;
							data_o	: out std_logic_vector(WIDTH_BITS - 1 downto 0);
							count_o	: out std_logic_vector(DEPTH_BITS - 1 downto 0);
							r_ack : out std_logic--;
						);
						end component;
												
						component SpiMasterPorts is
						generic (
							CLOCK_DIVIDER : integer := 4; --allowable values are from AClk/2 to AClk/16...
							BYTE_WIDTH : natural := 1;
							CPOL : std_logic := '0'--;	
						);
						port
						(
							clk : in std_logic;
							rst : in std_logic;
							Mosi : out std_logic;
							Sck : out std_logic;
							Miso : in std_logic;
							DataToMosi : in std_logic_vector((BYTE_WIDTH * 8) - 1 downto 0);
							DataFromMiso : out std_logic_vector((BYTE_WIDTH * 8) - 1 downto 0);
							XferComplete : out std_logic--;
						);
						end component;
						
						component FourWireStepperMotorDriverPorts is
						generic (
							CLOCK_FREQHZ : natural := 10000000;
							MOTOR_STEP_SECONDS : real := 0.001--;
						);
						port (
							clk : in std_logic;
							rst : in std_logic;

							--inputs
							--~ SeekStep : in std_logic_vector(15 downto 0);
							SeekStep : in signed(15 downto 0);
							
							--outputs
							--~ CurrentStep : out std_logic_vector(15 downto 0);
							CurrentStep : out signed(15 downto 0);
							MotorStepEdge : out std_logic;
							
							MotorAPlus : out std_logic;
							MotorAMinus : out std_logic;
							MotorBPlus : out std_logic;
							MotorBMinus : out std_logic--;
						);
						end component;

						component CrcFifo is
						generic (
								DEPTH_BITS : natural := 10--;
						);
						port (
						
							--Globals
							clk : in std_logic;
							rst : in std_logic;
							
							FifoStartAddr : in std_logic_vector(DEPTH_BITS - 1 downto 0);
							FifoEndAddr : in std_logic_vector(DEPTH_BITS - 1 downto 0);
							FifoPeekAddr : out std_logic_vector(DEPTH_BITS - 1 downto 0);
							FifoPeekData : in std_logic_vector(7 downto 0);
							
							StartCrc : in std_logic;
							Crc : out std_logic_vector(31 downto 0);
							CrcComplete : out std_logic--;
							
						); end component;


						
--Constants & Setup
	

	--Clocks
			
		--~ constant BaseClockFreq : natural := 16777216; --new xtal (256Hz Fs)
		--~ constant ClockFreqMultiplier : natural := 5; --Xilinx says it won't run at 100MHz (x6) as currently written (prob. the accumulator). x4=67MHz, x5=84MHz
		--~ constant BaseClockPeriod : real := 59.6; --really should be exactly 1 / conv_real(BaseClockFreq), but it's just used by DCM clock library, and conv_real doesn't exist.
		--~ constant BoardMasterClockFreq : natural := BaseClockFreq * ClockFreqMultiplier; 
		
		constant BoardMasterClockFreq : natural := 102000000; -- --102.0 clock
		--~ constant BoardUartClockFreq : natural := 136000000;
		constant BoardUartClockFreq : natural := 102000000;
		--~ constant BoardMasterClockFreq : natural := 153000000; -- --102.0 clock
		signal MasterClk : std_logic; --This is the main clock for *everything*
		signal UartClk : std_logic; --This is the uart clock, it runs at 136MHz, and a lot of the regular logic won't run that fast, which is why we have a seperate clock. In practice, it immediately gets divided by 16 ny the uarts so it actually is slower than the other logic, but at a weird ratio...
		--~ constant UartClockFreqMultiplier : natural := 7; --15/17 is also a good scaler, and uart dividers come out just over ideal instead of under, so integer math works on them...
		--~ constant UartClockFreqDivider : natural := 8;
		--~ constant UartClockPeriod : real := 68.1; --really should be exactly 1 / conv_real(UartBaseClockFreq), but it's just used by DCM clock library, and conv_real doesn't exist.
		--~ constant UartClockFreq : natural := BaseClockFreq * UartClockFreqMultiplier / UartClockFreqDivider; -- 14.6802MHz (14.7456 ideal; 0.44% dev)

		constant UART_FIFO_DEPTH_BITS : natural := 11;

		--FPGA internal
		
			signal rst_pulse : std_logic; --One shot reset generator
			signal MasterReset : std_logic; --Our power-on-reset signal for everything
			signal SerialNumber : std_logic_vector(31 downto 0); --This is a xilinx proprietary toy that we use as the serial number, it's supposed to be unique on each board
			signal BuildNumber : std_logic_vector(31 downto 0); --How many attempts got us to this particular version of the firmware?
		
		-- Ram bus
						
			signal RamBusLatch_i : std_logic;		
			signal RamBusCE_i : std_logic;		
			signal RamBusWrnRd_i : std_logic;		
			signal RamBusAddress_i : std_logic_vector(9 downto 0);		
			signal RamDataOut : std_logic_vector(31 downto 0);		
			signal RamDataIn : std_logic_vector(31 downto 0);		
			signal RamBusAck_i : std_logic;					
			
		-- Register space
		
			signal DataToWrite : std_logic_vector(31 downto 0);
			signal WriteReq : std_logic;
			signal WriteAck : std_logic;
			signal DataFromRead : std_logic_vector(31 downto 0);
			signal ReadReq : std_logic;
			signal ReadAck : std_logic;

			signal MotorEnable : std_logic;        
			--~ signal MotorSeekStep : std_logic_vector(15 downto 0);    
			signal MotorSeekStep : signed(15 downto 0);    
			--signal MotorCurrentStep : std_logic_vector(15 downto 0);
			signal ResetSteps : std_logic;          
			--signal MotorAPlus_i : std_logic;        
			--signal MotorAMinus_i : std_logic;      
			--signal MotorBPlus_i : std_logic;        
			--signal MotorBMinus_i : std_logic;      
			
		--Monitor A/D
		
			signal nDrdyMonitorAdc_i : std_logic;
			signal nCsMonitorAdc_i : std_logic;
			signal SckMonitorAdc_i : std_logic;
			signal MosiMonitorAdc_i : std_logic;
			signal MisoMonitorAdc_i : std_logic;
			signal MonitorAdcChannel : std_logic_vector(4 downto 0);
			signal MonitorAdcReadSample : std_logic;
			--~ signal MonitorAdcSample : ltc244xaccumulator;
			--~ signal MonitorAdcSample : ads1258accumulator;			
			signal MonitorAdcSample : std_logic_vector(63 downto 0);
			signal MonitorAdcReset : std_logic;
			signal MonitorAdcReset_i : std_logic;			
			signal MonitorAdcSpiDataIn : std_logic_vector(7 downto 0);
			signal MonitorAdcSpiDataOut : std_logic_vector(7 downto 0);
			signal MonitorAdcSpiXferStart : std_logic;
			signal MonitorAdcSpiXferDone : std_logic;
			signal MonitorAdcSpiFrameEnable : std_logic;
			
		--RS-422
		
			signal Uart0FifoReset : std_logic;
			signal Uart0FifoReset_i : std_logic;
			signal ReadUart0 : std_logic;
			signal Uart0RxFifoFull : std_logic;
			signal Uart0RxFifoEmpty : std_logic;
			signal Uart0RxFifoReadAck : std_logic;
			signal Uart0RxFifoData : std_logic_vector(7 downto 0);
			signal Uart0RxFifoCount : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal WriteUart0 : std_logic;
			signal Uart0TxFifoFull : std_logic;
			signal Uart0TxFifoEmpty : std_logic;
			signal Uart0TxFifoData : std_logic_vector(7 downto 0);
			signal Uart0TxFifoCount : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0ClkDivider : std_logic_vector(7 downto 0);
			signal UartClk0 : std_logic;			
			signal UartTxClk0 : std_logic;			
			signal Txd0_i : std_logic;
			signal Rxd0_i : std_logic;
			signal UartRx0Dbg : std_logic;			

			signal Uart0RxFifoPeekReadAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0RxFifoPeekWriteAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0RxFifoPeekPeekAddr_i : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0RxFifoPeekPeekAddrRegisterSpace : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0RxFifoPeekPeekAddrCrcer : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0RxFifoPeekPeekData : std_logic_vector(7 downto 0);
			signal Uart0RxFifoPeekMultiPopAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0RxFifoPeekMultiPopStrobe : std_logic;
			signal Uart0CrcStartAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0CrcEndAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0CrcCurrentAddr : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0DoCrc : std_logic;
			signal Uart0CrcDone : std_logic;
			signal Uart0Crc : std_logic_vector(31 downto 0);
			signal Uart0LastHeaderEnd : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0LastFooterEnd : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0PayloadType : std_logic_vector(15 downto 0);
			signal Uart0PayloadLen : std_logic_vector(15 downto 0);
			signal Uart0HeaderFooterPayloadLenMatches : std_logic;
			signal Uart0HeaderFound : std_logic;
			signal Uart0FooterFound : std_logic;
			signal Uart0HeaderEndPos : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0FooterEndPos : std_logic_vector(PeekRamDepth - 1 downto 0);
			signal Uart0PacketCrc : std_logic_vector(31 downto 0);
			signal Uart0CalcCrc : std_logic_vector(31 downto 0);
			
			signal Uart1FifoReset : std_logic;
			signal Uart1FifoReset_i : std_logic;
			signal ReadUart1 : std_logic;
			signal Uart1RxFifoFull : std_logic;
			signal Uart1RxFifoEmpty : std_logic;
			signal Uart1RxFifoReadAck : std_logic;
			signal Uart1RxFifoData : std_logic_vector(7 downto 0);
			signal Uart1RxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal WriteUart1 : std_logic;
			signal Uart1TxFifoFull : std_logic;
			signal Uart1TxFifoEmpty : std_logic;
			signal Uart1TxFifoData : std_logic_vector(7 downto 0);
			signal Uart1TxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal Uart1ClkDivider : std_logic_vector(7 downto 0);
			signal UartClk1 : std_logic;			
			signal UartTxClk1 : std_logic;			
			signal Txd1_i : std_logic;
			signal Rxd1_i : std_logic;
			signal UartRx1Dbg : std_logic;	
			
			signal Uart2FifoReset : std_logic;
			signal Uart2FifoReset_i : std_logic;
			signal ReadUart2 : std_logic;
			signal Uart2RxFifoFull : std_logic;
			signal Uart2RxFifoEmpty : std_logic;
			signal Uart2RxFifoReadAck : std_logic;
			signal Uart2RxFifoData : std_logic_vector(7 downto 0);
			signal Uart2RxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal WriteUart2 : std_logic;
			signal Uart2TxFifoFull : std_logic;
			signal Uart2TxFifoEmpty : std_logic;
			signal Uart2TxFifoData : std_logic_vector(7 downto 0);
			signal Uart2TxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal Uart2ClkDivider : std_logic_vector(7 downto 0);
			signal UartClk2 : std_logic;			
			signal UartTxClk2 : std_logic;			
			signal Txd2_i : std_logic;
			signal Rxd2_i : std_logic;
			signal UartRx2Dbg : std_logic;		
			
			signal Uart3FifoReset : std_logic;
			signal Uart3FifoReset_i : std_logic;
			signal ReadUart3 : std_logic;
			signal Uart3RxFifoFull : std_logic;
			signal Uart3RxFifoEmpty : std_logic;
			signal Uart3RxFifoReadAck : std_logic;
			signal Uart3RxFifoData : std_logic_vector(7 downto 0);
			signal Uart3RxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal WriteUart3 : std_logic;
			signal Uart3TxFifoFull : std_logic;
			signal Uart3TxFifoEmpty : std_logic;
			signal Uart3TxFifoData : std_logic_vector(7 downto 0);
			signal Uart3TxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal Uart3ClkDivider : std_logic_vector(7 downto 0);
			signal UartClk3 : std_logic;			
			signal UartTxClk3 : std_logic;			
			signal Txd3_i : std_logic;
			signal Rxd3_i : std_logic;
			signal UartRx3Dbg : std_logic;		

			signal UartUsbFifoReset : std_logic;
			signal UartUsbFifoReset_i : std_logic;
			signal ReadUartUsb : std_logic;
			signal UartUsbRxFifoFull : std_logic;
			signal UartUsbRxFifoEmpty : std_logic;
			signal UartUsbRxFifoReadAck : std_logic;
			signal UartUsbRxFifoData : std_logic_vector(7 downto 0);
			signal UartUsbRxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal WriteUartUsb : std_logic;
			signal UartUsbTxFifoFull : std_logic;
			signal UartUsbTxFifoEmpty : std_logic;
			signal UartUsbTxFifoData : std_logic_vector(7 downto 0);
			signal UartUsbTxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal UartUsbClkDivider : std_logic_vector(7 downto 0);
			signal UartClkUsb : std_logic;			
			signal UartTxClkUsb : std_logic;			
			signal TxdUsb_i : std_logic;
			signal RxdUsb_i : std_logic;
			signal UartRxUsbDbg : std_logic;					
			signal TxdUartBitCount : std_logic_vector(3 downto 0);
			
			signal UartGpsFifoReset : std_logic;
			signal UartGpsFifoReset_i : std_logic;
			signal ReadUartGps : std_logic;
			signal UartGpsRxFifoFull : std_logic;
			signal UartGpsRxFifoEmpty : std_logic;
			signal UartGpsRxFifoReadAck : std_logic;
			signal UartGpsRxFifoData : std_logic_vector(7 downto 0);
			signal UartGpsRxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal WriteUartGps : std_logic;
			signal UartGpsTxFifoFull : std_logic;
			signal UartGpsTxFifoEmpty : std_logic;
			signal UartGpsTxFifoData : std_logic_vector(7 downto 0);
			signal UartGpsTxFifoCount : std_logic_vector(UART_FIFO_DEPTH_BITS - 1 downto 0);
			signal UartGpsClkDivider : std_logic_vector(7 downto 0);
			signal UartClkGps : std_logic;			
			signal UartTxClkGps : std_logic;			
			signal TxdGps_i : std_logic;
			signal RxdGps_i : std_logic;
			signal UartRxGpsDbg : std_logic;					
			
		-- Timing
		
			signal PPS_i : std_logic;	
			signal PPSCountReset : std_logic; --generated by register read
			signal PPSDetected : std_logic; --are edges occuring on PPS?  Mainly used by rtc to decide wether to roll the clock over on it's own or let PPS sync it
			signal PPSCount : std_logic_vector(31 downto 0) := x"00000000"; --How many MasterClocks have gone by since the last PPS edge (so we can phase-lock oscillator to GPS time)
			signal PPSCounter : std_logic_vector(31 downto 0) := x"00000000"; --This one is the current count for this second, not the total for the last second...
			signal ClkDacWrite : std_logic_vector(15 downto 0) := x"0000";
			signal WriteClkDac : std_logic;
			signal ClkDacReadback : std_logic_vector(15 downto 0);
			signal nCsXO_i : std_logic;
			signal SckXO_i : std_logic;
			signal MosiXO_i : std_logic;
			signal MisoXO_i : std_logic;
			
		-- Positioning System - Led's and Optodetectors
		
		signal PosSenseHomeA_i : std_logic := '0';
		signal PosSenseBit0A_i : std_logic := '0';
		signal PosSenseBit1A_i : std_logic := '0';
		signal PosSenseBit2A_i : std_logic := '0';
		signal PosSenseHomeB_i : std_logic := '0';
		signal PosSenseBit0B_i : std_logic := '0';
		signal PosSenseBit1B_i : std_logic := '0';
		signal PosSenseBit2B_i : std_logic := '0';
	
		signal LastPosSenseHomeA : std_logic := '0';
		signal LastPosSenseBit0A : std_logic := '0';
		signal LastPosSenseBit1A : std_logic := '0';
		signal LastPosSenseBit2A : std_logic := '0';
		signal LastPosSenseHomeB : std_logic := '0';
		signal LastPosSenseBit0B : std_logic := '0';
		signal LastPosSenseBit1B : std_logic := '0';
		signal LastPosSenseBit2B : std_logic := '0';

		signal PosSenseA : std_logic_vector(3 downto 0) := "0000";
		signal PosSenseB : std_logic_vector(3 downto 0) := "0000";
		signal LastPosSenseA : std_logic_vector(3 downto 0) := "0000";
		signal LastPosSenseB : std_logic_vector(3 downto 0) := "0000";				
				
		--~ signal PosLedsEnA : std_logic := '0';
		
		signal PosDetHomeAOnStep : signed(15 downto 0) := x"0000";
		signal PosDetHomeAOffStep : signed(15 downto 0) := x"0000";
		signal PosDetA0OnStep : signed(15 downto 0) := x"0000";
		signal PosDetA0OffStep : signed(15 downto 0) := x"0000";
		signal PosDetA1OnStep : signed(15 downto 0) := x"0000";
		signal PosDetA1OffStep : signed(15 downto 0) := x"0000";
		signal PosDetA2OnStep : signed(15 downto 0) := x"0000";
		signal PosDetA2OffStep : signed(15 downto 0) := x"0000";
		
		--~ signal PosLedsEnB : std_logic := '0';
		
		signal PosDetHomeBOnStep : signed(15 downto 0) := x"0000";
		signal PosDetHomeBOffStep : signed(15 downto 0) := x"0000";
		signal PosDetB0OnStep : signed(15 downto 0) := x"0000";
		signal PosDetB0OffStep : signed(15 downto 0) := x"0000";
		signal PosDetB1OnStep : signed(15 downto 0) := x"0000";
		signal PosDetB1OffStep : signed(15 downto 0) := x"0000";
		signal PosDetB2OnStep : signed(15 downto 0) := x"0000";
		signal PosDetB2OffStep : signed(15 downto 0) := x"0000";
		
		signal PosDet0AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet0AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet1AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet1AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet2AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet2AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet3AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet3AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet4AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet4AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet5AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet5AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet6AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet6AOffStep : signed(15 downto 0) := x"0000";
		signal PosDet7AOnStep : signed(15 downto 0) := x"0000";
		signal PosDet7AOffStep : signed(15 downto 0) := x"0000";
		
		signal PosDet0BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet0BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet1BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet1BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet2BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet2BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet3BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet3BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet4BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet4BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet5BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet5BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet6BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet6BOffStep : signed(15 downto 0) := x"0000";
		signal PosDet7BOnStep : signed(15 downto 0) := x"0000";
		signal PosDet7BOffStep : signed(15 downto 0) := x"0000";
		
		-- Motors

		signal MotorAPlus_i : std_logic := '0';
		signal MotorAMinus_i : std_logic := '0';
		signal MotorBPlus_i : std_logic := '0';
		signal MotorBMinus_i : std_logic := '0';

		--~ signal ShootThruIxnae : std_logic := '0';
        signal ShootThruIxnaeAPlus : std_logic;
        signal ShootThruIxnaeAMinus : std_logic;
        signal ShootThruIxnaeBPlus : std_logic;
        signal ShootThruIxnaeBMinus : std_logic;
        --~ signal MotorCurrentStep : std_logic_vector(15 downto 0);
		signal MotorCurrentStep : signed(15 downto 0);
		signal MotorStepEdge : std_logic;
		signal LastMotorStepEdge : std_logic;


		constant PushPullHigh : std_logic := '1';
		constant PushPullGround : std_logic := '0';

		constant OpenDrainOn : std_logic := '0';
		constant OpenDrainFloat : std_logic := 'Z';

		constant nCsEnabled : std_logic := '0';
		constant nCsNotEnabled : std_logic := '1';
		
		constant JumperNotInserted : std_logic := '1';
		constant JumperInserted : std_logic := '0';

begin

	------------------------------------------ Globals ---------------------------------------------------

	MasterClk <= clk;
	UartClk <= clk;
	
	SerialNumber <= x"DEADA555";
	
	BuildNumber_i : BuildNumberPorts
	port map
	(
		BuildNumber => BuildNumber--;
	);
	
	--~ BuildNumber <= x"69696969";
	
	--Replace with external 74VHC123 or RC
	BootupReset : OneShotPorts
	generic map (
		CLOCK_FREQHZ => BoardMasterClockFreq,
		DELAY_SECONDS => 0.000010,
		SHOT_RST_STATE => '1',
		SHOT_PRETRIGGER_STATE => '1'--,
	)
	port map 
	(	
		clk => MasterClk,
		--~ rst => not(rst_in),
		rst => '0',
		shot => MasterReset
		--~ shot => rst_pulse
	);
	
	--~ MasterReset <= not(rst_in) or rst_pulse;
	
	rst_out <= MasterReset;
	
	------------------------------------------ RegisterSpaces ---------------------------------------------------

		IBufLatch : IBufP2Ports port map(clk => MasterClk, I => RamBusLatch, O => RamBusLatch_i);
		--~ IBufCE : IBufP2Ports port map(clk => MasterClk, I => RamBusnCs(0), O => RamBusCE_i);
		IBufCE : IBufP2Ports port map(clk => MasterClk, I => RamBusnCs, O => RamBusCE_i);
		IBufWrnRd : IBufP2Ports port map(clk => MasterClk, I => RamBusWrnRd, O => RamBusWrnRd_i);

		GenRamAddrBus: for i in 0 to 9 generate
		begin
			IBUF_RamAddr_i : IBufP1Ports
			port map (
				clk => MasterClk,
				I => RamBusAddress(i),
				O => RamBusAddress_i(i)--,
			); 
		end generate;
		
		GenRamDataBus: for i in 0 to 31 generate
		begin
			IBUF_RamData_i : IBufP1Ports
			port map (
				clk => MasterClk,
				I => RamBusDataIn(i),
				O => RamDataIn(i)--,
			);
			
			RamBusDataOut(i) <= RamDataOut(i);
		end generate;
		
	DataToWrite <= RamDataIn;
	WriteReq <= '1' when ( (RamBusCE_i = '1') and (RamBusWrnRd_i = '1') ) else '0';
	RamDataOut <= DataFromRead;
    ReadReq <= '1' when ( (RamBusCE_i = '1') and (RamBusWrnRd_i = '0') ) else '0';
	RamBusAck_i <= ReadAck or WriteAck;
	RamBusAck <= RamBusAck_i;
	
	--~ TP1 <= RamBusCE_i;
	--~ TP2 <= RamBusLatch_i;
	--~ TP3 <= RamBusDataIn(0);
	--~ TP4 <= RamBusWrnRd_i;
	--~ TP5 <= WriteReq;
	--~ TP6 <= ReadAck;
	--~ TP7 <= ReadReq;
	--~ TP8 <= RamBusAck_i;
	
	
	------------------------------------------ RegisterSpace ---------------------------------------------------




        

	--Mapping between bus transactions and specific registers - see RegisterSpace.vhd for adresses
	RegisterSpace : RegisterSpacePorts
	generic map 
	(
		ADDRESS_BITS => 10,
		UART_FIFO_DEPTH_BITS => UART_FIFO_DEPTH_BITS--,
	)
	port map
	(
		clk => MasterClk,
		rst => MasterReset,

		Address => RamBusAddress_i,
		DataIn => DataToWrite,
		DataOut => DataFromRead,
		ReadReq => ReadReq,
		WriteReq => WriteReq,
		ReadAck => ReadAck,
		WriteAck => WriteAck,
		
		--Data to access:		

		--Infrastructure
		SerialNumber => SerialNumber,
		BuildNumber => BuildNumber,
		
		--Faults and control
		Fault1V => Fault1V,
		Fault3V => Fault3V,
		Fault5V => Fault5V,
		nFaultClr1V => nFaultClr1V,
		nFaultClr3V => nFaultClr3V,
		nFaultClr5V => nFaultClr5V,
		--~ PowernEn5V => PowernEn5V,
		PowernEn5V => open,
		PowerCycd => PowerCycd,
		nPowerCycClr => nPowerCycClr,
		--~ LedR => LedR,
		--~ LedG => LedG,
		--~ LedB => LedB,
		LedR => open,
		LedG => open,
		LedB => open,
		Uart0OE => OE0,
		Uart1OE => OE1,
		Uart2OE => OE2,
		Uart3OE => OE3,
		--~ Ux1SelJmp => Ux1SelJmp,
		--~ Ux2SelJmp => Ux2SelJmp,
		Ux1SelJmp => open,
		Ux2SelJmp => open,
				
		--Motor
		MotorEnable => MotorEnable,        
		MotorSeekStep => MotorSeekStep,    
		MotorCurrentStep => MotorCurrentStep,
		ResetSteps => ResetSteps,          
		MotorAPlus => MotorAPlus_i,        
		MotorAMinus => MotorAMinus_i,      
		MotorBPlus => MotorBPlus_i,        
		MotorBMinus => MotorBMinus_i,      
		                                   
		--Sensors                          
		PosLedsEnA => PosLEDEnA,          
		PosLedsEnB => PosLEDEnB,          
			                  
		PosSenseHomeA => PosSenseHomeA_i,    
		PosSenseBit0A => PosSenseBit0A_i,    
		PosSenseBit1A => PosSenseBit1A_i,    
		PosSenseBit2A => PosSenseBit2A_i,    
		PosSenseHomeB => PosSenseHomeB_i,    
		PosSenseBit0B => PosSenseBit0B_i,    
		PosSenseBit1B => PosSenseBit1B_i,    
		PosSenseBit2B => PosSenseBit2B_i,    
		                                   
		PosSenseA => PosSenseA,            
		PosSenseB => PosSenseB,            
		                                   
		PosDetHomeAOnStep => PosDetHomeAOnStep,
		PosDetHomeAOffStep => PosDetHomeAOffStep,
		PosDetA0OnStep => PosDetA0OnStep,  
		PosDetA0OffStep => PosDetA0OffStep,
		PosDetA1OnStep => PosDetA1OnStep,  
		PosDetA1OffStep => PosDetA1OffStep,
		PosDetA2OnStep => PosDetA2OnStep,  
		PosDetA2OffStep => PosDetA2OffStep,
		                                   
		PosDetHomeBOnStep => PosDetHomeBOnStep,
		PosDetHomeBOffStep => PosDetHomeBOffStep,
		PosDetB0OnStep => PosDetB0OnStep,  
		PosDetB0OffStep => PosDetB0OffStep,
		PosDetB1OnStep => PosDetB1OnStep,  
		PosDetB1OffStep => PosDetB1OffStep,
		PosDetB2OnStep => PosDetB2OnStep,  
		PosDetB2OffStep => PosDetB2OffStep,
		                                   
		PosDet0AOnStep => PosDet0AOnStep,  
		PosDet0AOffStep => PosDet0AOffStep,
		PosDet1AOnStep => PosDet1AOnStep,  
		PosDet1AOffStep => PosDet1AOffStep,
		PosDet2AOnStep => PosDet2AOnStep,  
		PosDet2AOffStep => PosDet2AOffStep,
		PosDet3AOnStep => PosDet3AOnStep,  
		PosDet3AOffStep => PosDet3AOffStep,
		PosDet4AOnStep => PosDet4AOnStep,  
		PosDet4AOffStep => PosDet4AOffStep,
		PosDet5AOnStep => PosDet5AOnStep,  
		PosDet5AOffStep => PosDet5AOffStep,
		PosDet6AOnStep => PosDet6AOnStep,  
		PosDet6AOffStep => PosDet6AOffStep,
		PosDet7AOnStep => PosDet7AOnStep,  
		PosDet7AOffStep => PosDet7AOffStep,
		                                   
		PosDet0BOnStep => PosDet0BOnStep,  
		PosDet0BOffStep => PosDet0BOffStep,
		PosDet1BOnStep => PosDet1BOnStep,  
		PosDet1BOffStep => PosDet1BOffStep,
		PosDet2BOnStep => PosDet2BOnStep,  
		PosDet2BOffStep => PosDet2BOffStep,
		PosDet3BOnStep => PosDet3BOnStep,  
		PosDet3BOffStep => PosDet3BOffStep,
		PosDet4BOnStep => PosDet4BOnStep,  
		PosDet4BOffStep => PosDet4BOffStep,
		PosDet5BOnStep => PosDet5BOnStep,  
		PosDet5BOffStep => PosDet5BOffStep,
		PosDet6BOnStep => PosDet6BOnStep,  
		PosDet6BOffStep => PosDet6BOffStep,
		PosDet7BOnStep => PosDet7BOnStep,  
		PosDet7BOffStep => PosDet7BOffStep,
		
		--Monitor A/D
		MonitorAdcChannelReadIndex => MonitorAdcChannel,
		ReadMonitorAdcSample => MonitorAdcReadSample,
		--~ MonitorAdcSampleToRead => ltc244xaccum_to_std_logic(MonitorAdcSample),
		MonitorAdcSampleToRead => MonitorAdcSample,
		MonitorAdcReset => MonitorAdcReset,
		MonitorAdcSpiDataIn => MonitorAdcSpiDataIn,
		MonitorAdcSpiDataOut => MonitorAdcSpiDataOut,
		MonitorAdcSpiXferStart => MonitorAdcSpiXferStart,
		MonitorAdcSpiXferDone => MonitorAdcSpiXferDone,
		MonitorAdcnDrdy => nDrdyMonitorAdc_i,
		MonitorAdcSpiFrameEnable => MonitorAdcSpiFrameEnable,			
		
		--RS-422
		Uart0FifoReset => Uart0FifoReset,
		ReadUart0 => ReadUart0,
		Uart0RxFifoFull => Uart0RxFifoFull,
		Uart0RxFifoEmpty => Uart0RxFifoEmpty,
		Uart0RxFifoData => Uart0RxFifoData,
		Uart0RxFifoCount => Uart0RxFifoCount,
		WriteUart0 => WriteUart0,
		Uart0TxFifoFull => Uart0TxFifoFull,
		Uart0TxFifoEmpty => Uart0TxFifoEmpty,
		Uart0TxFifoData => Uart0TxFifoData,
		Uart0TxFifoCount => Uart0TxFifoCount,
		Uart0ClkDivider => Uart0ClkDivider,
		Uart0RxFifoPeekReadAddr => Uart0RxFifoPeekReadAddr,
		Uart0RxFifoPeekWriteAddr => Uart0RxFifoPeekWriteAddr,
		Uart0RxFifoPeekPeekAddr => Uart0RxFifoPeekPeekAddrRegisterSpace,
		Uart0RxFifoPeekPeekData => Uart0RxFifoPeekPeekData,
		Uart0RxFifoPeekMultiPopAddr => Uart0RxFifoPeekMultiPopAddr,
		Uart0RxFifoPeekMultiPopStrobe => Uart0RxFifoPeekMultiPopStrobe,
		Uart0CrcStartAddr => Uart0CrcStartAddr,
		Uart0CrcEndAddr => Uart0CrcEndAddr,
		Uart0CrcCurrentAddr => Uart0RxFifoPeekPeekAddrCrcer,
		Uart0DoCrc => Uart0DoCrc,
		Uart0CrcDone => Uart0CrcDone,
		Uart0Crc => Uart0Crc,
		Uart0HeaderFound => Uart0HeaderFound,
		Uart0FooterFound => Uart0FooterFound,
		Uart0HeaderEndPos => Uart0HeaderEndPos,
		Uart0FooterEndPos => Uart0FooterEndPos,
		Uart0PayloadType => Uart0PayloadType,
		Uart0PayloadLen => Uart0PayloadLen,
		Uart0PacketCrc => Uart0PacketCrc,
		Uart0CalcCrc => Uart0CalcCrc,
		
		Uart1FifoReset => Uart1FifoReset,
		ReadUart1 => ReadUart1,
		Uart1RxFifoFull => Uart1RxFifoFull,
		Uart1RxFifoEmpty => Uart1RxFifoEmpty,
		Uart1RxFifoData => Uart1RxFifoData,
		Uart1RxFifoCount => Uart1RxFifoCount,
		WriteUart1 => WriteUart1,
		Uart1TxFifoFull => Uart1TxFifoFull,
		Uart1TxFifoEmpty => Uart1TxFifoEmpty,
		Uart1TxFifoData => Uart1TxFifoData,
		Uart1TxFifoCount => Uart1TxFifoCount,
		Uart1ClkDivider => Uart1ClkDivider,
		
		Uart2FifoReset => Uart2FifoReset,
		ReadUart2 => ReadUart2,
		Uart2RxFifoFull => Uart2RxFifoFull,
		Uart2RxFifoEmpty => Uart2RxFifoEmpty,
		Uart2RxFifoData => Uart2RxFifoData,
		Uart2RxFifoCount => Uart2RxFifoCount,
		WriteUart2 => WriteUart2,
		Uart2TxFifoFull => Uart2TxFifoFull,
		Uart2TxFifoEmpty => Uart2TxFifoEmpty,
		Uart2TxFifoData => Uart2TxFifoData,
		Uart2TxFifoCount => Uart2TxFifoCount,
		Uart2ClkDivider => Uart2ClkDivider,
		
		Uart3FifoReset => Uart3FifoReset,
		ReadUart3 => ReadUart3,
		Uart3RxFifoFull => Uart3RxFifoFull,
		Uart3RxFifoEmpty => Uart3RxFifoEmpty,
		Uart3RxFifoData => Uart3RxFifoData,
		Uart3RxFifoCount => Uart3RxFifoCount,
		WriteUart3 => WriteUart3,
		Uart3TxFifoFull => Uart3TxFifoFull,
		Uart3TxFifoEmpty => Uart3TxFifoEmpty,
		Uart3TxFifoData => Uart3TxFifoData,
		Uart3TxFifoCount => Uart3TxFifoCount,
		Uart3ClkDivider => Uart3ClkDivider,
		
		UartUsbFifoReset => UartUsbFifoReset,
		ReadUartUsb => ReadUartUsb,
		UartUsbRxFifoFull => UartUsbRxFifoFull,
		UartUsbRxFifoEmpty => UartUsbRxFifoEmpty,
		UartUsbRxFifoData => UartUsbRxFifoData,
		UartUsbRxFifoCount => UartUsbRxFifoCount,
		WriteUartUsb => WriteUartUsb,
		UartUsbTxFifoFull => UartUsbTxFifoFull,
		UartUsbTxFifoEmpty => UartUsbTxFifoEmpty,
		UartUsbTxFifoData => UartUsbTxFifoData,
		UartUsbTxFifoCount => UartUsbTxFifoCount,
		UartUsbClkDivider => UartUsbClkDivider,
		
		UartGpsFifoReset => UartGpsFifoReset,
		ReadUartGps => ReadUartGps,
		UartGpsRxFifoFull => UartGpsRxFifoFull,
		UartGpsRxFifoEmpty => UartGpsRxFifoEmpty,
		UartGpsRxFifoData => UartGpsRxFifoData,
		UartGpsRxFifoCount => UartGpsRxFifoCount,
		WriteUartGps => WriteUartGps,
		UartGpsTxFifoFull => UartGpsTxFifoFull,
		UartGpsTxFifoEmpty => UartGpsTxFifoEmpty,
		UartGpsTxFifoData => UartGpsTxFifoData,
		UartGpsTxFifoCount => UartGpsTxFifoCount,
		UartGpsClkDivider => UartGpsClkDivider,
				
		--Timing
		IdealTicksPerSecond => std_logic_vector(to_unsigned(BoardMasterClockFreq, 32)),
		ActualTicksLastSecond => PPSCount,
		PPSCountReset => PPSCountReset,
		PPSDetected => PPSDetected,
		ClockTicksThisSecond => PPSCounter,
		ClkDacWrite => ClkDacWrite,
		WriteClkDac => WriteClkDac,
		ClkDacReadback => ClkDacReadback--,
	);
	
	----------------------------------------------------------------Monitor A/D--------------------------------------------------------------------
			
	IBufnDrdyAdc : IBufP3Ports port map(clk => MasterClk, I => nDrdyMonAdc0, O => nDrdyMonitorAdc_i); --if you want to change the pin for this chip select, it's here
	IBufMisoAdc : IBufP3Ports port map(clk => MasterClk, I => MisoMonAdc0, O => MisoMonitorAdc_i); --if you want to change the pin for this chip select, it's here
	
	--~ --Decodes the A/D data into a buffer and creates timing signals to manage fifos
	--~ ads1258 : ads1258Ports
	--~ generic map 
	--~ (
		--~ MASTER_CLOCK_FREQHZ => BoardMasterClockFreq--,
	--~ )
	--~ port map (
		--~ clk => MasterClk,
		--~ rst => MonitorAdcReset_i,
		--~ nDrdy => nDrdyMonitorAdc_i,
		--~ nCsAdc => nCsMonAdc0,
		--~ Sck => SckMonAdc0,
		--~ Mosi => MosiMonAdc0,
		--~ Miso => MisoMonitorAdc_i,
		--~ SpiDataIn => MonitorAdcSpiDataIn,
		--~ SpiDataOut => MonitorAdcSpiDataOut,
		--~ SpiXferStart => MonitorAdcSpiXferStart,
		--~ SpiXferDone => MonitorAdcSpiXferDone,
		--~ Sample => MonitorAdcSample,
		--~ SampleLatched => MonitorAdcSampleLatched,
		--~ TimestampReq => open--,
	--~ );
	
	--~ ads1258accum : ads1258accumulatorPorts
	--~ port map
	--~ (
		--~ clk => MasterClk,
		--~ rst => MonitorAdcReset_i,
		--~ AdcSampleIn => MonitorAdcSample,
		--~ AdcSampleLatched => MonitorAdcSampleLatched,
		--~ AdcChannelLatched => open,
		--~ AdcChannelReadIndex => MonitorAdcChannel,
		--~ ReadAdcSample => MonitorAdcReadSample,
		--~ AdcSampleToRead => MonitorAdcSampleToRead--,
	--~ );
	
	ads1258 : SpiDevicePorts
	generic map 
	(
		--~ CLOCK_DIVIDER => 16,
		CLOCK_DIVIDER => 256,
		--~ CLOCK_DIVIDER => 4096,
		BIT_WIDTH => 8,
		CPOL => '0',
		--~ CPOL => '1',
		CPHA => '0'--,
		--~ CPHA => '1'--,
	)
	port map 
	(
		clk => MasterClk,
		rst => MonitorAdcReset_i,
		--~ nCs => nCsMonitorAdc_i,
		nCs => open,
		Sck => SckMonitorAdc_i,
		Mosi => MosiMonitorAdc_i,
		Miso => MisoMonitorAdc_i,
		WriteOut => MonitorAdcSpiDataIn,
		Transfer => MonitorAdcSpiXferStart,
		Readback => MonitorAdcSpiDataOut,
		TransferComplete => MonitorAdcSpiXferDone--,
	);
	
	nCsMonitorAdc_i <= not(MonitorAdcSpiFrameEnable);
	nCsMonAdc0 <= nCsMonitorAdc_i;
	SckMonAdc0 <= SckMonitorAdc_i;
	MosiMonAdc0 <= MosiMonitorAdc_i;	
	
	MonitorAdcReset_i <= MasterReset or MonitorAdcReset;
	
	--~ TP1 <= nCsMonitorAdc_i;
	--~ TP2 <= SckMonitorAdc_i;
	--~ TP3 <= MosiMonitorAdc_i;
	--~ TP4 <= MisoMonitorAdc_i;
	--~ TP5 <= MonitorAdcSpiXferStart;
	--~ TP6 <= MonitorAdcSpiXferDone;
	--~ TP7 <= MonitorAdcSpiDataIn(0);
	--~ TP8 <= MonitorAdcSpiDataOut(0);
	
	
	----------------------------- RS-422 ----------------------------------
	
	--~ Oe0 <= '1';
	--~ Oe1 <= '1';
	--~ Oe2 <= '1';
	--~ Oe3 <= '1';
	
	--This is just to excercise the thing so it stays in the design...
	--~ Ux1SelJmp <= '1' when ( (Rxd1 = '1') and (Rxd2 = '0') ) else '0' when ( (Rxd1 = '0') and (Rxd2 = '1') ) else 'Z';

	--First, the _really_ boring loopback (hardware)
	--~ Txd0 <= Rxd0;
	
	--~ --Second, the somewhat less boring loopback (firmware)	

	--~ RS422_Rx1 : UartRx
	--~ generic map (
		--~ CLOCK_FREQHZ => BoardMasterClockFreq,
		--~ --BAUDRATE => 12500000--;
		--~ --BAUDRATE => 8000000--,
		--~ --BAUDRATE => BoardMasterClockFreq / 16--, --9.216MHz
		--~ BAUDRATE => 115200--,
		
	--~ )
	--~ port map (						
		--~ clk => MasterClk,
		--~ rst => MasterReset,
		--~ Rxd => Rxd1,
		--~ UartClk => Uart1Clkx16,
		--~ RxComplete => Uart1RxComplete,
		--~ RxData => Uart1Data
	--~ );
	
	--~ Uart1TxClockDivider : ClockDivider2XPorts generic map(CLOCK_DIVIDER => 16, DIVOUT_RST_STATE => '0') port map(clk => Uart1Clkx16, rst => MasterReset, div => Uart1Clk);
	
	--~ RS422_Tx1 : UartTx
	--~ port map
	--~ (
		--~ clk => Uart1Clk,
		--~ reset => MasterReset,
		--~ Go => Uart1RxComplete,
		--~ TxD => Txd1,
		--~ --TxD => open,
		--~ Busy => open,
		--~ --Busy => Ux1SelJmp,
		--~ Data => Uart1Data
	--~ );

	--Thirdly, the very NOT boring fifos (software)
	
	Uart0BitClockDiv : VariableClockDivider2XPorts
	generic map
	(
		WIDTH_BITS => 8,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		--~ clki => MasterClk,
		clki => UartClk,
		rst => MasterReset,
		rst_count => x"00",
		--~ terminal_count => Uart0ClkDivider,
		terminal_count => std_logic_vector(to_unsigned(natural((real(102000000) / ( real(115200) * 16.0)) - 1.0), 8)),
		clko => UartClk0
	);
	Uart0TxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => 16,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClk0,
		rst => MasterReset,
		div => UartTxClk0
	);
		
	IBufRxd0 : IBufP3Ports port map(clk => UartClk, I => Rxd0, O => Rxd0_i); --if you want to change the pin for this chip select, it's here
	
	RS422_Rx0 : UartRxFifoExtClkPeek
	port map
	(
		clk => MasterClk,
		uclk => UartClk0,
		rst => Uart0FifoReset_i,
		--~ BaudDivider => Uart0ClkDivider,
		Rxd => Rxd0_i,
		--~ Dbg1 => UartRx0Dbg,
		Dbg1 => open,
		Dbg2 => open,
		Dbg3 => open,
		RxComplete => open,
		ReadFifo => ReadUart0,
		--~ HeaderFooterPayloadLenMatches => Uart0HeaderFooterPayloadLenMatches,
		FifoFull => Uart0RxFifoFull,
		FifoEmpty => Uart0RxFifoEmpty,
		FifoReadData => Uart0RxFifoData,
		FifoCount => Uart0RxFifoCount,
		FifoReadAck => open,
		HeaderFound => Uart0HeaderFound,
		FooterFound => Uart0FooterFound,
		HeaderEndPos => Uart0HeaderEndPos,
		FooterEndPos => Uart0FooterEndPos,
		PayloadType => Uart0PayloadType,
		PayloadLen => Uart0PayloadLen,
		PacketCrc => Uart0PacketCrc,
		CalcCrc => Uart0CalcCrc,
		FifoReadAddr => Uart0RxFifoPeekReadAddr,
		FifoWriteAddr => Uart0RxFifoPeekWriteAddr,
		FifoPeekAddr => Uart0RxFifoPeekPeekAddr_i,
		FifoPeekData => Uart0RxFifoPeekPeekData,
		FifoMultiPopAddr => Uart0RxFifoPeekMultiPopAddr,
		FifoMultiPopStrobe => Uart0RxFifoPeekMultiPopStrobe--,
	);
	
	RS422_Rx0_Crcer : CrcFifo
	generic map
	(
		DEPTH_BITS => PeekRamDepth--,
	)
	port map
	(
		clk => MasterClk,
		rst => Uart0FifoReset_i,
		FifoStartAddr => Uart0CrcStartAddr,
		FifoEndAddr => Uart0CrcEndAddr,
		FifoPeekData => Uart0RxFifoPeekPeekData,
		FifoPeekAddr => Uart0CrcCurrentAddr,
		StartCrc => Uart0DoCrc,
		Crc => Uart0Crc,
		CrcComplete => Uart0CrcDone--,
	);
	-- !!May want to add Uart0CrcCurrentAddr functionality for debug...
	
	--This gonna get funky: if we're doing a crc, the crc core has acess to the fifo, otherwise the processor gets acess to the fifo...
	Uart0RxFifoPeekPeekAddr_i <= Uart0RxFifoPeekPeekAddrCrcer when (Uart0CrcDone = '0') else Uart0RxFifoPeekPeekAddrRegisterSpace;
			

	--~ LedG <= not(UartRx0Dbg);
	LedG <= Uart0DoCrc;
	--~ LedR <= not(Uart0RxFifoEmpty);
	LedR <= '0';
	TP1 <= Uart0CrcDone;
	TP4 <= Uart0CrcCurrentAddr(0);
	TP5 <= Uart0DoCrc;
	TP6 <= Uart0Crc(0);
	TP7 <= Uart0CrcStartAddr(0);
	TP8 <= Uart0CrcEndAddr(0);
	
	RS422_Tx0 : UartTxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		--~ FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		FIFO_BITS => PeekRamDepth--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 12500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => 4000000--,
		--~ BAUDRATE => 2000000--,
		--~ BAUDRATE => 1000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.216MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8192--,
		--~ BAUDRATE => 115200--,
	)
	port map
	(
		clk => MasterClk,
		uclk => UartTxClk0,
		rst => Uart0FifoReset_i,
		--~ BaudDivider => Uart0ClkDivider,
		BitClockOut => open,
		--~ BitClockOut => Ux1SelJmp,		
		WriteStrobe => WriteUart0,
		WriteData => Uart0TxFifoData,
		FifoFull => Uart0TxFifoFull,
		FifoEmpty => Uart0TxFifoEmpty,
		FifoCount => Uart0TxFifoCount,
		TxInProgress => open,
		--~ TxInProgress => SckMonitorAdcTP3,		
		Cts => '0',
		Txd => Txd0_i--,
		--~ Txd => open--,
	);
	Txd0 <= Txd0_i;
	
	--Mux master reset (boot) and user reset (datamapper)
	Uart0FifoReset_i <= MasterReset or Uart0FifoReset;
	
	Uart1BitClockDiv : VariableClockDivider2XPorts
	generic map
	(
		WIDTH_BITS => 8,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		--~ clki => MasterClk,
		clki => UartClk,
		rst => MasterReset,
		rst_count => x"00",
		terminal_count => Uart1ClkDivider,
		clko => UartClk1
	);
	Uart1TxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => 16,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClk1,
		rst => MasterReset,
		div => UartTxClk1
	);
	
	IBufRxd1 : IBufP3Ports port map(clk => UartClk, I => Rxd1, O => Rxd1_i); --if you want to change the pin for this chip select, it's here
	
	RS422_Rx1 : UartRxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 12500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.216MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8192--,
		--~ BAUDRATE => 921600--,
		--~ BAUDRATE => 460800--, --calcs show 460k is the fastest standard baudrate with a clean divisor...
	)
	port map
	(
		clk => MasterClk,
		uclk => UartClk1,
		rst => Uart1FifoReset_i,
		--~ BaudDivider => Uart1ClkDivider,
		Rxd => Rxd1_i,
		Dbg1 => open,
		RxComplete => open,
		ReadFifo => ReadUart1,
		FifoFull => Uart1RxFifoFull,
		FifoEmpty => Uart1RxFifoEmpty,
		FifoReadData => Uart1RxFifoData,
		FifoCount => Uart1RxFifoCount,
		FifoReadAck => open--,		
	);
	
	RS422_Tx1 : UartTxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 12500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.216MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8192--,
		--~ BAUDRATE => 921600--,
		--~ BAUDRATE => 460800--, --calcs show 460k is the fastest standard baudrate with a clean divisor...
	)
	port map
	(
		clk => MasterClk,
		uclk => UartTxClk1,
		rst => Uart1FifoReset_i,
		--~ BaudDivider => Uart1ClkDivider,
		BitClockOut => open,
		WriteStrobe => WriteUart1,
		WriteData => Uart1TxFifoData,
		FifoFull => Uart1TxFifoFull,
		FifoEmpty => Uart1TxFifoEmpty,
		FifoCount => Uart1TxFifoCount,
		TxInProgress => open,
		--~ TxInProgress => SckMonitorAdcTP3,		
		Cts => '0',
		Txd => Txd1_i--,
		--~ Txd => open--,
	);
	Txd1 <= Txd1_i;
	
	--Mux master reset (boot) and user reset (datamapper)
	Uart1FifoReset_i <= MasterReset or Uart1FifoReset;
	
	Uart2BitClockDiv : VariableClockDivider2XPorts
	generic map
	(
		WIDTH_BITS => 8,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		--~ clki => MasterClk,
		clki => UartClk,
		rst => MasterReset,
		rst_count => x"00",
		terminal_count => Uart2ClkDivider,
		clko => UartClk2
	);
	Uart2TxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => 16,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClk2,
		rst => MasterReset,
		div => UartTxClk2
	);
	
	--~ Ux1SelJmp <= UartClk2;
	
	IBufRxd2 : IBufP3Ports port map(clk => UartClk, I => Rxd2, O => Rxd2_i); --if you want to change the pin for this chip select, it's here
	
	--~ Ux1SelJmp <= Rxd2;
	
	RS422_Rx2 : UartRxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 12500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.216MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8192--,
		--~ BAUDRATE => 115200--,
	)
	port map
	(
		clk => MasterClk,
		uclk => UartClk2,
		rst => Uart2FifoReset_i,
		--~ BaudDivider => Uart2ClkDivider,
		Rxd => Rxd2_i,
		Dbg1 => open,
		RxComplete => open,
		ReadFifo => ReadUart2,
		FifoFull => Uart2RxFifoFull,
		FifoEmpty => Uart2RxFifoEmpty,
		FifoReadData => Uart2RxFifoData,
		FifoCount => Uart2RxFifoCount,
		FifoReadAck => open--,		
	);
	
	RS422_Tx2 : UartTxFifoExtClk
	--~ RS422_Tx2 : UartTxFifo
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		--~ FIFO_BITS => UART_FIFO_DEPTH_BITS,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 12500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.216MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8192--,
		--~ BAUDRATE => 115200--,
	)
	port map
	(
		clk => MasterClk,
		--~ uclk => MasterClk,
		uclk => UartTxClk2,
		rst => Uart2FifoReset_i,
		--~ BaudDivider => Uart2ClkDivider,
		BitClockOut => open,
		--~ BitClockOut => Ux1SelJmp,		
		WriteStrobe => WriteUart2,
		WriteData => Uart2TxFifoData,
		FifoFull => Uart2TxFifoFull,
		FifoEmpty => Uart2TxFifoEmpty,
		FifoCount => Uart2TxFifoCount,
		TxInProgress => open,
		--~ TxInProgress => SckMonitorAdcTP3,		
		Cts => '0',
		Txd => Txd2_i--,
		--~ Txd => open--,
	);
	Txd2 <= Txd2_i;
	
	--Debug monitors
	--~ Txd2 <= Txd0_i;
	--~ Txd1 <= Rxd0_i;
	
	--Mux master reset (boot) and user reset (datamapper)
	Uart2FifoReset_i <= MasterReset or Uart2FifoReset;
	
	
	
	
	
	
	Uart3BitClockDiv : VariableClockDivider2XPorts
	generic map
	(
		WIDTH_BITS => 8,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		--~ clki => MasterClk,
		clki => UartClk,
		rst => MasterReset,
		rst_count => x"00",
		terminal_count => Uart3ClkDivider,
		clko => UartClk3
	);
	Uart3TxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => 16,
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClk3,
		rst => MasterReset,
		div => UartTxClk3
	);
	
	--~ Ux1SelJmp <= UartClk3;
	
	IBufRxd3 : IBufP3Ports port map(clk => UartClk, I => Rxd3, O => Rxd3_i); --if you want to change the pin for this chip select, it's here
	
	--~ Ux1SelJmp <= Rxd3;
	
	RS433_Rx3 : UartRxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 13500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.316MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8193--,
		--~ BAUDRATE => 115300--,
	)
	port map
	(
		clk => MasterClk,
		uclk => UartClk3,
		rst => Uart3FifoReset_i,
		--~ BaudDivider => Uart3ClkDivider,
		Rxd => Rxd3_i,
		Dbg1 => open,
		RxComplete => open,
		ReadFifo => ReadUart3,
		FifoFull => Uart3RxFifoFull,
		FifoEmpty => Uart3RxFifoEmpty,
		FifoReadData => Uart3RxFifoData,
		FifoCount => Uart3RxFifoCount,
		FifoReadAck => open--,		
	);
	
	RS433_Tx3 : UartTxFifoExtClk
	--~ RS433_Tx3 : UartTxFifo
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		--~ FIFO_BITS => UART_FIFO_DEPTH_BITS,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 13500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.316MHz
		--~ BAUDRATE => BoardMasterClockFreq / 8193--,
		--~ BAUDRATE => 115300--,
	)
	port map
	(
		clk => MasterClk,
		--~ uclk => MasterClk,
		uclk => UartTxClk3,
		rst => Uart3FifoReset_i,
		--~ BaudDivider => Uart3ClkDivider,
		BitClockOut => open,
		--~ BitClockOut => Ux1SelJmp,		
		WriteStrobe => WriteUart3,
		WriteData => Uart3TxFifoData,
		FifoFull => Uart3TxFifoFull,
		FifoEmpty => Uart3TxFifoEmpty,
		FifoCount => Uart3TxFifoCount,
		TxInProgress => open,
		--~ TxInProgress => SckMonitorAdcTP3,		
		Cts => '0',
		Txd => Txd3_i--,
		--~ Txd => open--,
	);
	Txd3 <= Txd3_i;
	
	--Debug monitors
	--~ Txd3 <= Txd0_i;
	--~ Txd1 <= Rxd0_i;
	
	--Mux master reset (boot) and user reset (datamapper)
	Uart3FifoReset_i <= MasterReset or Uart3FifoReset;
	

	
	--~ UartUsbBitClockDiv : VariableClockDivider2XPorts
	--~ generic map
	--~ (
		--~ WIDTH_BITS => 8,
		--~ DIVOUT_RST_STATE => '0'--;
	--~ )
	--~ port map
	--~ (
		--~ --clki => MasterClk,
		--~ clki => UartClk,
		--~ rst => MasterReset,
		--~ rst_count => x"00",
		--~ --terminal_count => UartUsbClkDivider,
		--~ terminal_count => std_logic_vector(to_unsigned(natural((real(153000000) / ( real(115200) * 16.0)) - 1.0), 8)),
		--~ clko => UartClkUsb
	--~ );
	
	--We're hardcoding Usb to 115,200 bps so we have a reachable benchtest...
	UartUsbRxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => natural((real(102000000) / ( real(115200) * 16.0)) - 1.0),
		--~ CLOCK_DIVIDER => natural((real(102000000) / ( real(9600) * 16.0)) - 1.0),
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClk,
		rst => MasterReset,
		div => UartClkUsb
	);
	
	UartUsbTxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => 16,
		--~ CLOCK_DIVIDER => 8, --8 not 16 cause has to be rising edge of clk for each state so intrinsic /2
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClkUsb,
		rst => MasterReset,
		div => UartTxClkUsb
	);
	
	--~ Ux1SelJmp <= UartClkUsb;
	
	IBufRxdUsb : IBufP3Ports port map(clk => UartClk, I => TxdUsb, O => RxdUsb_i); --if you want to change the pin for this chip select, it's here
	
	--~ TP2 <= RxdUsb_i;
	--~ LedB <= not(TxdUsb);
	
	--~ Ux1SelJmp <= RxdUsb;
	
	RxdUsb_RxUsb : UartRxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 1Usb500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.Usb16MHz
		--~ BAUDRATE => BoardMasterClockFreq / 819Usb--,
		--~ BAUDRATE => 115Usb00--,
	)
	port map
	(
		clk => MasterClk,
		uclk => UartClkUsb,
		rst => UartUsbFifoReset_i,
		--~ BaudDivider => UartUsbClkDivider,
		Rxd => RxdUsb_i,
		--~ Dbg1 => TP4,
		--~ RxComplete => TP3,
		Dbg1 => open,
		RxComplete => open,
		ReadFifo => ReadUartUsb,
		FifoFull => UartUsbRxFifoFull,
		FifoEmpty => UartUsbRxFifoEmpty,
		FifoReadData => UartUsbRxFifoData,
		FifoCount => UartUsbRxFifoCount,
		FifoReadAck => open--,		
	);
	
	--~ CtsUsb <= UartUsbRxFifoFull; --polarity??
	CtsUsb <= '1';
	
	RS4UsbUsb_TxUsb : UartTxFifoExtClk
	--~ RS4UsbUsb_TxUsb : UartTxFifo
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		--~ FIFO_BITS => UART_FIFO_DEPTH_BITS,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 1Usb500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.Usb16MHz
		--~ BAUDRATE => BoardMasterClockFreq / 819Usb--,
		--~ BAUDRATE => 115Usb00--,
	)
	port map
	(
		clk => MasterClk,
		--~ uclk => MasterClk,
		uclk => UartTxClkUsb,
		rst => UartUsbFifoReset_i,
		--~ BaudDivider => UartUsbClkDivider,
		BitClockOut => open,
		--~ BitClockOut => Ux1SelJmp,		
		BitCountOut => TxdUartBitCount,
		WriteStrobe => WriteUartUsb,
		WriteData => UartUsbTxFifoData,
		FifoFull => UartUsbTxFifoFull,
		FifoEmpty => UartUsbTxFifoEmpty,
		FifoCount => UartUsbTxFifoCount,
		TxInProgress => open,
		--~ TxInProgress => TP3,		
		Cts => '0', --RtsUsb in this case, ignore cause the computer can pretty much alwyays keep up
		Txd => TxdUsb_i--,
		--~ Txd => open--,
	);
	RxdUsb <= TxdUsb_i;
	
	Ux1SelJmp <= not(TxdUsb_i);
	--~ TP8 <= TxdUsb_i;
	
	--~ LedR <= not(TxdUsb_i);
	--~ TP1 <= TxdUsb_i;
	
	--Debug monitors
	--~ TxdUsb <= Txd0_i;
	--~ Txd1 <= Rxd0_i;
	
	--Mux master reset (boot) and user reset (datamapper)
	UartUsbFifoReset_i <= MasterReset or UartUsbFifoReset;
	
	
	
	
	
	--Gps is hardcoded to 9600 bps
	UartGpsRxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => natural((real(102000000) / ( real(9600) * 16.0)) - 1.0),
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClk,
		rst => MasterReset,
		div => UartClkGps
	);
	
	UartGpsTxBitClockDiv : ClockDivider2XPorts
	generic map
	(
		CLOCK_DIVIDER => 16,
		--~ CLOCK_DIVIDER => 8, --8 not 16 cause has to be rising edge of clk for each state so intrinsic /2
		DIVOUT_RST_STATE => '0'--;
	)
	port map
	(
		clk => UartClkGps,
		rst => MasterReset,
		div => UartTxClkGps
	);
	
	--~ Ux1SelJmp <= UartClkGps;
	
	IBufRxdGps : IBufP3Ports port map(clk => UartClk, I => RxdGps, O => RxdGps_i); --if you want to change the pin for this chip select, it's here
	
	--~ TP2 <= RxdGps_i;
	--~ LedB <= not(TxdGps);
	
	--~ Ux1SelJmp <= RxdGps;
	
	RxdGps_RxGps : UartRxFifoExtClk
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 1Gps500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.Gps16MHz
		--~ BAUDRATE => BoardMasterClockFreq / 819Gps--,
		--~ BAUDRATE => 115Gps00--,
	)
	port map
	(
		clk => MasterClk,
		uclk => UartClkGps,
		rst => UartGpsFifoReset_i,
		--~ BaudDivider => UartGpsClkDivider,
		Rxd => RxdGps_i,
		--~ Dbg1 => TP4,
		--~ RxComplete => TP3,
		Dbg1 => open,
		RxComplete => open,
		ReadFifo => ReadUartGps,
		FifoFull => UartGpsRxFifoFull,
		FifoEmpty => UartGpsRxFifoEmpty,
		FifoReadData => UartGpsRxFifoData,
		FifoCount => UartGpsRxFifoCount,
		FifoReadAck => open--,		
	);
	
	RS4GpsGps_TxGps : UartTxFifoExtClk
	--~ RS4GpsGps_TxGps : UartTxFifo
	generic map
	(
		--~ UART_CLOCK_FREQHZ => BoardMasterClockFreq,
		--~ FIFO_BITS => UART_FIFO_DEPTH_BITS,
		FIFO_BITS => UART_FIFO_DEPTH_BITS--,
		--~ BAUD_DIVIDER_BITS => 8--,
		--~ BAUDRATE => 1Gps500000--,
		--~ BAUDRATE => 8000000--,
		--~ BAUDRATE => BoardMasterClockFreq / 16--, --9.Gps16MHz
		--~ BAUDRATE => BoardMasterClockFreq / 819Gps--,
		--~ BAUDRATE => 115Gps00--,
	)
	port map
	(
		clk => MasterClk,
		--~ uclk => MasterClk,
		uclk => UartTxClkGps,
		rst => UartGpsFifoReset_i,
		--~ BaudDivider => UartGpsClkDivider,
		BitClockOut => open,
		--~ BitClockOut => Ux1SelJmp,		
		BitCountOut => open,
		WriteStrobe => WriteUartGps,
		WriteData => UartGpsTxFifoData,
		FifoFull => UartGpsTxFifoFull,
		FifoEmpty => UartGpsTxFifoEmpty,
		FifoCount => UartGpsTxFifoCount,
		TxInProgress => open,
		--~ TxInProgress => TP3,		
		Cts => '0', --RtsGps in this case, ignore cause the computer can pretty much alwyays keep up
		Txd => TxdGps_i--,
		--~ Txd => open--,
	);
	TxdGps <= TxdGps_i;
	
	--Mux master reset (boot) and user reset (datamapper)
	UartGpsFifoReset_i <= MasterReset or UartGpsFifoReset;
	
	--~ TP1 <= RxdUsb_i;
	--~ TP2 <= UartClkUsb;
	--~ TP3 <= RamBusDataIn(0);
	--~ TP4 <= UartTxClkUsb;
	--~ TP5 <= TxdUartBitCount(0);
	--~ TP6 <= TxdUartBitCount(1);
	--~ TP7 <= TxdUartBitCount(2);
	--~ TP8 <= TxdUartBitCount(3);
	--~ TP5 <= UartUsbRxFifoEmpty;
	--~ TP6 <= ReadUartUsb;
	--~ TP7 <= UartUsbRxFifoCount(0);
	--~ TP8 <= UartUsbRxFifoCount(1);
	
	
	----------------------------- Timing ----------------------------------
	
		--~ --Just sync external PPS to master clock
		IBufPPS : IBufP2Ports port map(clk => MasterClk, I => PPS, O => PPS_i);
		
	--~ --Count up MasterClocks per PPS so we can sync the oscilator to the GPS clock
	PPSAccumulator : PPSCountPorts
    port map
	(
		clk => MasterClk,
		PPS => PPS_i,
		PPSReset => PPSCountReset,
		PPSDetected => PPSDetected,
		PPSCounter => PPSCounter,
		PPSAccum => PPSCount--,
	);
	
	--~ PPSRtcPhaseComparator : PhaseComparatorPorts
	--~ generic map (
		--~ MAX_CLOCK_BITS_DELTA => 32--,
	--~ )
	--~ port map (
		--~ clk => MasterClk,
		--~ rst => not(nMasterReset),
		--~ InA => PPSMux,
		--~ InB => PpsGenerated,
		--~ Delta => PPSRtcPhaseCmp--,
	--~ );
	
	--~ SarPPSAdcPhaseComparator : PhaseComparatorPorts
	--~ generic map (
		--~ MAX_CLOCK_BITS_DELTA => 32--,
	--~ )
	--~ port map (
		--~ clk => MasterClk,
		--~ rst => not(nMasterReset),
		--~ InA => PPSMux,
		--~ --InB => SarAdcnDrdy, --since the A/D undersamples, this really should be the one drdy where we read the a/d, not all of them!
		--~ InB => SarSampleTimestampLatched,
		--~ Delta => SarPPSAdcPhaseCmp--,
	--~ );
	
	--~ --Implements a real time clock that's locked to the PPS
	--~ RtcCounter : RtcCounterPorts
    --~ generic map
	--~ (
		--~ CLOCK_FREQ => BoardMasterClockFreq--,
	--~ )
    --~ port map
	--~ (
		--~ clk => MasterClk,
		--~ rst => not(nMasterReset),
		--~ PPS => PPS_i,
		--~ PPSDetected => PPSDetected,
		--~ Sync => SyncAdcRequest,
		--~ GeneratedPPS => PpsGenerated,
		--~ SetTimeSeconds => SetTimeSeconds,
		--~ SetTime => SetTime,
		--~ SetChangedTime => SetChangedTime,
		--~ Seconds => Seconds,
		--~ Milliseconds => Milliseconds--,
	--~ );
	
	IBufDacMiso : IBufP2Ports port map(clk => MasterClk, I => '1', O => MisoXO_i);

	ClkDac_i : SpiDacPorts
	generic map 
	(
		MASTER_CLOCK_FREQHZ => BoardMasterClockFreq,
		BIT_WIDTH => 16
	)
	port map 
	(
		clk => MasterClk,
		rst => MasterReset,
		nCs => nCsXO_i,
		Sck => SckXO_i,
		Mosi => MosiXO_i,
		Miso => MisoXO_i,
		DacWriteOut => ClkDacWrite,
		WriteDac => WriteClkDac,
		DacReadback => ClkDacReadback
	);

	nCsXO <= nCsXO_i;
	SckXO <= SckXO_i;
	MosiXO <= MosiXO_i;
	
	----------------------------- Power Supplies ----------------------------------
	
	PowernEn5V <= '0';
	
	PowerSync <= '1';
	--~ PowerSyncClockDivider2X : ClockDivider2XPorts generic map(CLOCK_DIVIDER => 96, DIVOUT_RST_STATE => '0') port map(clk => MasterClk, rst => MasterReset, div => PowerSync);

	----------------------------- H-Bridge ----------------------------------
	
	--ShootThruIxnae is a 100nsec pulse reset & initiated by either edge of period; thus we must also gate on (Period_i = LastPeriod) to avoid a one-clock glitch while ShootThruIxnae is being reset
	  
	--"Prime" signals are the high-side FETs in the H-bridge and due to complex drive circuits take much longer to turn on and turn off! Therefore we wanna take our sweet time turning on the low-side drivers!
	
	--~ --just use the 100MHz clock: that's 10nsec, which is a 'long' time
	--~ ShootThruIxnae <= MasterClk;
	
	--SiCFETs show maybe 25nsec for transistion time, others are probably alot worse - use a clock divider to get 100nsec-type delays...
	ShootThruIxnaeOneShotAPlus : OneShotPorts
	generic map (
		CLOCK_FREQHZ => BoardMasterClockFreq,
		DELAY_SECONDS => 0.0010,
		SHOT_RST_STATE => '0',
		SHOT_PRETRIGGER_STATE => '0'--,
	)
	port map (	
		clk => MasterClk,
		rst => not(MotorAPlus_i), 
		shot => ShootThruIxnaeAPlus
	);
	ShootThruIxnaeOneShotAMinus : OneShotPorts
	generic map (
		CLOCK_FREQHZ => BoardMasterClockFreq,
		DELAY_SECONDS => 0.0010,
		SHOT_RST_STATE => '0',
		SHOT_PRETRIGGER_STATE => '0'--,
	)
	port map (	
		clk => MasterClk,
		rst => not(MotorAMinus_i), 
		shot => ShootThruIxnaeAMinus
	);
	ShootThruIxnaeOneShotBPlus : OneShotPorts
	generic map (
		CLOCK_FREQHZ => BoardMasterClockFreq,
		DELAY_SECONDS => 0.0010,
		SHOT_RST_STATE => '0',
		SHOT_PRETRIGGER_STATE => '0'--,
	)
	port map (	
		clk => MasterClk,
		rst => not(MotorBPlus_i), 
		shot => ShootThruIxnaeBPlus
	);
	ShootThruIxnaeOneShotBMinus : OneShotPorts
	generic map (
		CLOCK_FREQHZ => BoardMasterClockFreq,
		DELAY_SECONDS => 0.0010,
		SHOT_RST_STATE => '0',
		SHOT_PRETRIGGER_STATE => '0'--,
	)
	port map (	
		clk => MasterClk,
		rst => not(MotorBMinus_i), 
		shot => ShootThruIxnaeBMinus
	);

	StepperMotor : FourWireStepperMotorDriverPorts
	generic map (
		CLOCK_FREQHZ => BoardMasterClockFreq,
		MOTOR_STEP_SECONDS => 0.0100	--;
	)
	port map (	
	
		clk => MasterClk,
		rst => ResetSteps,		
	
		--inputs
		SeekStep => MotorSeekStep,
		
		--outputs
		CurrentStep => MotorCurrentStep,
		MotorStepEdge => MotorStepEdge,
		
		--outputs
		MotorAPlus => MotorAPlus_i,
		MotorAMinus => MotorAMinus_i,
		MotorBPlus => MotorBPlus_i,
		MotorBMinus => MotorBMinus_i--,
	);

	--Low-side FETs
	MotorDriveAPlus <= PushPullHigh when ( (MotorEnable = '1') and (MotorAPlus_i = '1') and (ShootThruIxnaeAPlus = '1') ) else PushPullGround;
	MotorDriveAMinus <= PushPullHigh when ( (MotorEnable = '1') and (MotorAMinus_i = '1') and (ShootThruIxnaeAMinus = '1') ) else PushPullGround;
	MotorDriveBPlus <= PushPullHigh when ( (MotorEnable = '1') and (MotorBPlus_i = '1') and (ShootThruIxnaeBPlus = '1') ) else PushPullGround;
	MotorDriveBMinus <= PushPullHigh when ( (MotorEnable = '1') and (MotorBMinus_i = '1') and (ShootThruIxnaeBMinus = '1') ) else PushPullGround;
	
	--High-side FETs
	MotorDriveAPlusPrime <= PushPullHigh when ( (MotorEnable = '1') and (MotorAPlus_i = '1') and (ShootThruIxnaeAPlus = '1') ) else PushPullGround;
	MotorDriveAMinusPrime <= PushPullHigh when ( (MotorEnable = '1') and (MotorAMinus_i = '1') and (ShootThruIxnaeAMinus = '1') ) else PushPullGround;
	MotorDriveBPlusPrime <= PushPullHigh when ( (MotorEnable = '1') and (MotorBPlus_i = '1') and (ShootThruIxnaeBPlus = '1') ) else PushPullGround;
	MotorDriveBMinusPrime <= PushPullHigh when ( (MotorEnable = '1') and (MotorBMinus_i = '1') and (ShootThruIxnaeBMinus = '1') ) else PushPullGround;
	
	--~ LedG <= MotorSeekStep(7);
	
	----------------------------- DEBUG IDEAS ----------------------------------
	
	--~ Ux1SelJmp <= RamBusDataIn(0);
	--~ Ux1SelJmp <= MotorSeekStep(0);
	--~ Ux1SelJmp <= '1' when ( (Rxd1 = '1') and (Rxd2 = '0') ) else '0' when ( (Rxd1 = '0') and (Rxd2 = '1') ) else 'Z';
	--~ Ux1SelJmp <= MasterClk;
		
	--  Discrete I/O Connections

		--~ LedR <= '1';
		--~ LedG <= '1';
		--~ LedB <= '1';
		--~ LedR <= not(PosSenseBit0A);
		--~ LedG <= not(PosSenseBit1A);
		--~ LedB <= not(PosSenseBit2A);
		
		--~ LedR <= not(PosSenseBit0A);
		--~ LedG <= not(PosSenseBit1A);
		LedB <= not(PosSenseBit2A);
		--~ LedR <= not(RxdUsb_i);
		--~ LedG <= '0';
		--~ LedB <= not(TxdUsb_i);
		
		--~ TP1 <= not(PosSenseHomeA);
		--~ TP2 <= not(PosSenseBit0A); --msb
		--~ TP3 <= not(PosSenseBit1A);
		--~ TP4 <= not(PosSenseBit2A); --lsb
		--~ TP5 <= not(PosSenseHomeB);
		--~ TP6 <= not(PosSenseBit0B); --msb
		--~ TP7 <= not(PosSenseBit1B);
		--~ TP8 <= not(PosSenseBit2B); --lsb
		--~ TP7 <= TxdUsb;
		--~ TP8 <= RxdUsb_i;
		
		--~ TP1 <= RamBusnCs;
		--~ TP2 <= RamBusWrnRd;
		--~ TP3 <= RamBusDataIn(0);
		--~ TP4 <= WriteUartUsb;
		--~ TP5 <= TxdUsb_i;
		--~ TP6 <= UartClkUsb;
		--~ TP7 <= '1';
		--~ TP8 <= '1';
		--~ TP5 <= 'Fault5V;
		--~ TP6 <= PowerCycd;
		--~ TP7 <= UartUsbFifoReset_i;
		--~ TP8 <= Fault3V or Fault1V or PowerCycd or Fault5V;
			
	----------------------------- Clocked Logic / Main Loop ----------------------------------
	
	--Uhhhh, we gonna need to remap these to keep from losing our minds since we made some really bad assumptions about the mechanicals initially (we can fix the cable and this code later)...
	
	PosSenseHomeA_i <= PosSenseBit2A;
	PosSenseBit0A_i <= PosSenseHomeA;
	PosSenseBit1A_i <= PosSenseBit0A;
	PosSenseBit2A_i <= PosSenseBit1A;
	PosSenseHomeB_i <= PosSenseBit2B;
	PosSenseBit0B_i <= PosSenseHomeB;
	PosSenseBit1B_i <= PosSenseBit0B;
	PosSenseBit2B_i <= PosSenseBit1B;
	
	PosSenseA <= PosSenseBit2A_i & PosSenseBit1A_i & PosSenseBit0A_i & PosSenseHomeA_i;
	PosSenseB <= PosSenseBit2B_i & PosSenseBit1B_i & PosSenseBit0B_i & PosSenseHomeB_i;
	
	process(MasterReset, MasterClk)
	begin
	
		if (MasterReset = '1') then
		
		--This is where we have to actually set all of our registers, since the M2S devices don't support initialization as though they are from the 1980's...
		
		
		else
		
			if ( (MasterClk'event) and (MasterClk = '1') ) then
			
				--Run position detector logic:
			
				if (ResetSteps = '1') then
				
					PosDetHomeAOnStep <= x"0000";
					PosDetHomeAOffStep <= x"0000";
					PosDetA0OnStep <= x"0000";
					PosDetA0OffStep <= x"0000";
					PosDetA1OnStep <= x"0000";
					PosDetA1OffStep <= x"0000";
					PosDetA2OnStep <= x"0000";
					PosDetA2OffStep <= x"0000";

					PosDetHomeBOnStep <= x"0000";
					PosDetHomeBOffStep <= x"0000";
					PosDetB0OnStep <= x"0000";
					PosDetB0OffStep <= x"0000";
					PosDetB1OnStep <= x"0000";
					PosDetB1OffStep <= x"0000";
					PosDetB2OnStep <= x"0000";
					PosDetB2OffStep <= x"0000";
				
					PosDet0AOnStep <= x"0000"; 
					PosDet1AOnStep <= x"0000";
					PosDet2AOnStep <= x"0000";
					PosDet3AOnStep <= x"0000";
					PosDet4AOnStep <= x"0000";
					PosDet5AOnStep <= x"0000";
					PosDet6AOnStep <= x"0000";
					PosDet7AOnStep <= x"0000";

					PosDet0AOffStep <= x"0000";
					PosDet1AOffStep <= x"0000";
					PosDet2AOffStep <= x"0000";
					PosDet3AOffStep <= x"0000";
					PosDet4AOffStep <= x"0000";
					PosDet5AOffStep <= x"0000";
					PosDet6AOffStep <= x"0000";
					PosDet7AOffStep <= x"0000";

					PosDet0BOnStep <= x"0000";
					PosDet1BOnStep <= x"0000";
					PosDet2BOnStep <= x"0000";
					PosDet3BOnStep <= x"0000";
					PosDet4BOnStep <= x"0000";
					PosDet5BOnStep <= x"0000";
					PosDet6BOnStep <= x"0000";
					PosDet7BOnStep <= x"0000";

					PosDet0BOffStep <= x"0000";
					PosDet1BOffStep <= x"0000";
					PosDet2BOffStep <= x"0000";
					PosDet3BOffStep <= x"0000";
					PosDet4BOffStep <= x"0000";
					PosDet5BOffStep <= x"0000";
					PosDet6BOffStep <= x"0000";
					PosDet7BOffStep <= x"0000";
				
				else
				
					if (MotorStepEdge /= LastMotorStepEdge) then
					
						LastMotorStepEdge <= MotorStepEdge;
						
						if (MotorStepEdge = '1') then
							
							if (LastPosSenseHomeA /= PosSenseHomeA_i) then LastPosSenseHomeA <= PosSenseHomeA_i; if (PosSenseHomeA_i = '0') then PosDetHomeAOnStep <= MotorCurrentStep; else PosDetHomeAOffStep <= MotorCurrentStep; end if; end if;
							if (LastPosSenseBit0A /= PosSenseBit0A_i) then LastPosSenseBit0A <= PosSenseBit0A_i; if (PosSenseBit0A_i = '0') then PosDetA0OnStep <= MotorCurrentStep; else PosDetA0OffStep <= MotorCurrentStep; end if; end if;
							if (LastPosSenseBit1A /= PosSenseBit1A_i) then LastPosSenseBit1A <= PosSenseBit1A_i; if (PosSenseBit1A_i = '0') then PosDetA1OnStep <= MotorCurrentStep; else PosDetA1OffStep <= MotorCurrentStep; end if; end if;
							if (LastPosSenseBit2A /= PosSenseBit2A_i) then LastPosSenseBit2A <= PosSenseBit2A_i; if (PosSenseBit2A_i = '0') then PosDetA2OnStep <= MotorCurrentStep; else PosDetA2OffStep <= MotorCurrentStep; end if; end if;
							
							if (LastPosSenseHomeB /= PosSenseHomeB_i) then LastPosSenseHomeB <= PosSenseHomeB_i; if (PosSenseHomeB_i = '0') then PosDetHomeBOnStep <= MotorCurrentStep; else PosDetHomeBOffStep <= MotorCurrentStep; end if; end if;
							if (LastPosSenseBit0B /= PosSenseBit0B_i) then LastPosSenseBit0B <= PosSenseBit0B_i; if (PosSenseBit0B_i = '0') then PosDetB0OnStep <= MotorCurrentStep; else PosDetB0OffStep <= MotorCurrentStep; end if; end if;
							if (LastPosSenseBit1B /= PosSenseBit1B_i) then LastPosSenseBit1B <= PosSenseBit1B_i; if (PosSenseBit1B_i = '0') then PosDetB1OnStep <= MotorCurrentStep; else PosDetB1OffStep <= MotorCurrentStep; end if; end if;
							if (LastPosSenseBit2B /= PosSenseBit2B_i) then LastPosSenseBit2B <= PosSenseBit2B_i; if (PosSenseBit2B_i = '0') then PosDetB2OnStep <= MotorCurrentStep; else PosDetB2OffStep <= MotorCurrentStep; end if; end if;
						
							if (LastPosSenseA /= PosSenseA) then
							
								LastPosSenseA <= PosSenseA;
								
								--~ if (LastPosSenseA = "1111") then
								
									case PosSenseA is
										
										when "1110" => PosDet0AOnStep <= MotorCurrentStep; 
										when "1101" => PosDet1AOnStep <= MotorCurrentStep;
										when "1011" => PosDet2AOnStep <= MotorCurrentStep;
										when "1001" => PosDet3AOnStep <= MotorCurrentStep;
										when "0111" => PosDet4AOnStep <= MotorCurrentStep;
										when "0101" => PosDet5AOnStep <= MotorCurrentStep;
										when "0011" => PosDet6AOnStep <= MotorCurrentStep;
										when "0001" => PosDet7AOnStep <= MotorCurrentStep;
										when others =>
										
									end case;
									
								--~ end if;
								
								--~ if (PosSenseA = "1111") then
								
									case LastPosSenseA is
										
										when "1110" => PosDet0AOffStep <= MotorCurrentStep; 
										when "1101" => PosDet1AOffStep <= MotorCurrentStep;
										when "1011" => PosDet2AOffStep <= MotorCurrentStep;
										when "1001" => PosDet3AOffStep <= MotorCurrentStep;
										when "0111" => PosDet4AOffStep <= MotorCurrentStep;
										when "0101" => PosDet5AOffStep <= MotorCurrentStep;
										when "0011" => PosDet6AOffStep <= MotorCurrentStep;
										when "0001" => PosDet7AOffStep <= MotorCurrentStep;
										when others =>
										
									end case;
									
								--~ end if;
								
							end if;
							
							if (LastPosSenseB /= PosSenseB) then
							
								LastPosSenseB <= PosSenseB;
								
								case PosSenseB is
									
									when "1110" => PosDet0BOnStep <= MotorCurrentStep; 
									when "1101" => PosDet1BOnStep <= MotorCurrentStep;
									when "1011" => PosDet2BOnStep <= MotorCurrentStep;
									when "1001" => PosDet3BOnStep <= MotorCurrentStep;
									when "0111" => PosDet4BOnStep <= MotorCurrentStep;
									when "0101" => PosDet5BOnStep <= MotorCurrentStep;
									when "0011" => PosDet6BOnStep <= MotorCurrentStep;
									when "0001" => PosDet7BOnStep <= MotorCurrentStep;
									when others =>
									
								end case;
								
								case LastPosSenseB is
									
									when "1110" => PosDet0BOffStep <= MotorCurrentStep; 
									when "1101" => PosDet1BOffStep <= MotorCurrentStep;
									when "1011" => PosDet2BOffStep <= MotorCurrentStep;
									when "1001" => PosDet3BOffStep <= MotorCurrentStep;
									when "0111" => PosDet4BOffStep <= MotorCurrentStep;
									when "0101" => PosDet5BOffStep <= MotorCurrentStep;
									when "0011" => PosDet6BOffStep <= MotorCurrentStep;
									when "0001" => PosDet7BOffStep <= MotorCurrentStep;
									when others =>
									
								end case;
								
							end if;
							
						end if;
						
					end if;
						
				end if;
				
			end if;
			
		end if;		

	end process;

	
end architecture_Main;


