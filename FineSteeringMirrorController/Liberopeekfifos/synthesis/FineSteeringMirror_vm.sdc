# Written by Synplify Pro version map202209actsp2, Build 145R. Synopsys Run ID: sid1780618032 
# Top Level Design Parameters 

# Clocks 
create_clock -period 10.000 -waveform {0.000 5.000} -name {FCCC_C0_FCCC_C0_0_FCCC|GL1_net_inferred_clock} [get_pins {FCCC_C0_0/FCCC_C0_0/CCC_INST/GL1}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDividerPorts_work_main_architecture_main_0layer1_0|div_i_inferred_clock} [get_pins {Main_0/Uart3TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDividerPorts_work_main_architecture_main_0layer1_0|clko_i_inferred_clock} [get_pins {Main_0/Uart3BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDividerPorts_work_main_architecture_main_0layer1_1|div_i_inferred_clock} [get_pins {Main_0/Uart2TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDividerPorts_work_main_architecture_main_0layer1_1|clko_i_inferred_clock} [get_pins {Main_0/Uart2BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDividerPorts_work_main_architecture_main_0layer1_2|div_i_inferred_clock} [get_pins {Main_0/Uart1TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDividerPorts_work_main_architecture_main_0layer1_2|clko_i_inferred_clock} [get_pins {Main_0/Uart1BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDividerPorts_work_main_architecture_main_0layer1_3|div_i_inferred_clock} [get_pins {Main_0/Uart0TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDividerPorts_work_main_architecture_main_0layer1_3|clko_i_inferred_clock} [get_pins {Main_0/Uart0BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {FineSteeringMirror_sb_CCC_0_FCCC|GL0_net_inferred_clock} [get_pins {FineSteeringMirror_sb_0/CCC_0/CCC_INST/GL0}] 

# Virtual Clocks 
create_clock -period 19.608 -waveform {0.000 9.804} -name {CLK0_PAD}

# Generated Clocks 

# Paths Between Clocks 

# Multicycle Constraints 

# Point-to-point Delay Constraints 

# False Path Constraints 

# Output Load Constraints 

# Driving Cell Constraints 

# Input Delay Constraints 

# Output Delay Constraints 

# Wire Loads 

# Other Constraints 

# syn_hier Attributes 

# set_case Attributes 

# Clock Delay Constraints 
set_clock_groups -asynchronous -group [get_clocks {FCCC_C0_FCCC_C0_0_FCCC|GL1_net_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDividerPorts_work_main_architecture_main_0layer1_0|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDividerPorts_work_main_architecture_main_0layer1_0|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDividerPorts_work_main_architecture_main_0layer1_1|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDividerPorts_work_main_architecture_main_0layer1_1|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDividerPorts_work_main_architecture_main_0layer1_2|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDividerPorts_work_main_architecture_main_0layer1_2|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDividerPorts_work_main_architecture_main_0layer1_3|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDividerPorts_work_main_architecture_main_0layer1_3|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {FineSteeringMirror_sb_CCC_0_FCCC|GL0_net_inferred_clock}]

# syn_mode Attributes 

# Cells 

# Port DRC Rules 

# Input Transition Constraints 

# Unused constraints (intentionally commented out) 


# Non-forward-annotatable constraints (intentionally commented out) 

# Block Path constraints 

