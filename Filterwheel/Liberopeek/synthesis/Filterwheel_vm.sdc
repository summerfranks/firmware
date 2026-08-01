# Written by Synplify Pro version map202209actsp2, Build 145R. Synopsys Run ID: sid1785543352 
# Top Level Design Parameters 

# Clocks 
create_clock -period 19.608 -waveform {0.000 9.804} -name {VCXO} [get_ports {CLK0_PAD}] 
create_clock -period 20.000 -waveform {0.000 10.000} -name {Filterwheel_sb_0/FABOSC_0/I_RCOSC_25_50MHZ/CLKOUT} [get_pins {Filterwheel_sb_0/FABOSC_0/I_RCOSC_25_50MHZ/CLKOUT}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_0layer1_0|div_i_inferred_clock} [get_pins {Main_0/UartGpsTxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_2layer1|div_i_inferred_clock} [get_pins {Main_0/UartGpsRxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_0layer1_1|div_i_inferred_clock} [get_pins {Main_0/UartUsbTxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_1layer1|div_i_inferred_clock} [get_pins {Main_0/UartUsbRxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_0layer1_2|div_i_inferred_clock} [get_pins {Main_0/Uart3TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_0|clko_i_inferred_clock} [get_pins {Main_0/Uart3BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_0layer1_3|div_i_inferred_clock} [get_pins {Main_0/Uart2TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_1|clko_i_inferred_clock} [get_pins {Main_0/Uart2BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_0layer1_4|div_i_inferred_clock} [get_pins {Main_0/Uart1TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_2|clko_i_inferred_clock} [get_pins {Main_0/Uart1BitClockDiv/clko_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {ClockDivider2XPorts_work_main_architecture_main_0layer1_5|div_i_inferred_clock} [get_pins {Main_0/Uart0TxBitClockDiv/div_i/Q}] 
create_clock -period 10.000 -waveform {0.000 5.000} -name {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_3|clko_i_inferred_clock} [get_pins {Main_0/Uart0BitClockDiv/clko_i/Q}] 

# Virtual Clocks 

# Generated Clocks 
create_generated_clock -name {MasterClk} -multiply_by {4} -divide_by {2} -source [get_pins {FCCC_C0_0/FCCC_C0_0/CCC_INST/CLK0_PAD}]  [get_pins {FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0}] 
create_generated_clock -name {Filterwheel_sb_0/CCC_0/GL0} -multiply_by {3} -divide_by {3} -source [get_pins {Filterwheel_sb_0/CCC_0/CCC_INST/CLK0}]  [get_pins {Filterwheel_sb_0/CCC_0/CCC_INST/GL0}] 

# Paths Between Clocks 

# Multicycle Constraints 

# Point-to-point Delay Constraints 

# False Path Constraints 
set_false_path -through [get_pins {Filterwheel_sb_0/SYSRESET_POR/POWER_ON_RESET_N}] 
set_false_path -through [get_pins {Filterwheel_sb_0/CORERESETP_0/release_sdif3_core/Q Filterwheel_sb_0/CORERESETP_0/release_sdif2_core/Q Filterwheel_sb_0/CORERESETP_0/release_sdif1_core/Q Filterwheel_sb_0/CORERESETP_0/release_sdif0_core/Q Filterwheel_sb_0/CORERESETP_0/ddr_settled/Q}] 
set_false_path -from [get_cells {Filterwheel_sb_0/CORERESETP_0/MSS_HPMS_READY_int}] -to [get_cells {Filterwheel_sb_0/CORERESETP_0/sm0_areset_n_rcosc_q1 Filterwheel_sb_0/CORERESETP_0/sm0_areset_n_rcosc}] 
set_false_path -from [get_cells {Filterwheel_sb_0/CORERESETP_0/MSS_HPMS_READY_int}] -to [get_cells {Filterwheel_sb_0/CORERESETP_0/sdif3_areset_n_rcosc_q1 Filterwheel_sb_0/CORERESETP_0/sdif3_areset_n_rcosc Filterwheel_sb_0/CORERESETP_0/sdif2_areset_n_rcosc_q1 Filterwheel_sb_0/CORERESETP_0/sdif2_areset_n_rcosc Filterwheel_sb_0/CORERESETP_0/sdif1_areset_n_rcosc_q1 Filterwheel_sb_0/CORERESETP_0/sdif1_areset_n_rcosc Filterwheel_sb_0/CORERESETP_0/sdif0_areset_n_rcosc_q1 Filterwheel_sb_0/CORERESETP_0/sdif0_areset_n_rcosc}] 

# Output Load Constraints 

# Driving Cell Constraints 

# Input Delay Constraints 

# Output Delay Constraints 

# Wire Loads 

# Other Constraints 

# syn_hier Attributes 

# set_case Attributes 

# Clock Delay Constraints 
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_0layer1_0|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_2layer1|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_0layer1_1|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_1layer1|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_0layer1_2|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_0|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_0layer1_3|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_1|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_0layer1_4|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_2|clko_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {ClockDivider2XPorts_work_main_architecture_main_0layer1_5|div_i_inferred_clock}]
set_clock_groups -asynchronous -group [get_clocks {VariableClockDivider2XPorts_work_main_architecture_main_0layer1_3|clko_i_inferred_clock}]

# syn_mode Attributes 

# Cells 

# Port DRC Rules 

# Input Transition Constraints 

# Unused constraints (intentionally commented out) 
# set_false_path -through [get_nets { Filterwheel_sb_0.CORERESETP_0.CONFIG1_DONE Filterwheel_sb_0.CORERESETP_0.CONFIG2_DONE Filterwheel_sb_0.CORERESETP_0.SDIF*_PERST_N Filterwheel_sb_0.CORERESETP_0.SDIF*_PSEL Filterwheel_sb_0.CORERESETP_0.SDIF*_PWRITE Filterwheel_sb_0.CORERESETP_0.SDIF*_PRDATA[*] Filterwheel_sb_0.CORERESETP_0.SOFT_EXT_RESET_OUT Filterwheel_sb_0.CORERESETP_0.SOFT_RESET_F2M Filterwheel_sb_0.CORERESETP_0.SOFT_M3_RESET Filterwheel_sb_0.CORERESETP_0.SOFT_MDDR_DDR_AXI_S_CORE_RESET Filterwheel_sb_0.CORERESETP_0.SOFT_FDDR_CORE_RESET Filterwheel_sb_0.CORERESETP_0.SOFT_SDIF*_PHY_RESET Filterwheel_sb_0.CORERESETP_0.SOFT_SDIF*_CORE_RESET Filterwheel_sb_0.CORERESETP_0.SOFT_SDIF0_0_CORE_RESET Filterwheel_sb_0.CORERESETP_0.SOFT_SDIF0_1_CORE_RESET }]
# set_false_path -through [get_pins { Filterwheel_sb_0.Filterwheel_sb_MSS_0.MSS_ADLIB_INST.CONFIG_PRESET_N }]


# Non-forward-annotatable constraints (intentionally commented out) 

# Block Path constraints 

