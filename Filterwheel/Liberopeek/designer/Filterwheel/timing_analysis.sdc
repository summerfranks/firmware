# Microsemi Corp.
# Date: 2025-Apr-01 11:30:18
# This file was generated based on the following SDC source files:
#   /home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/Filterwheel_derived_constraints.sdc
#   /home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/user.sdc
#

create_clock -name {VCXO} -period 19.6078 [ get_ports { CLK0_PAD } ]
create_clock -name {Filterwheel_sb_0/FABOSC_0/I_RCOSC_25_50MHZ/CLKOUT} -period 20 [ get_pins { Filterwheel_sb_0/FABOSC_0/I_RCOSC_25_50MHZ/CLKOUT } ]
create_generated_clock -name {MasterClk} -multiply_by 4 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ]
create_generated_clock -name {Filterwheel_sb_0/CCC_0/GL0} -multiply_by 3 -divide_by 3 -source [ get_pins { Filterwheel_sb_0/CCC_0/CCC_INST/INST_CCC_IP/CLK0 } ] -phase 0 [ get_pins { Filterwheel_sb_0/CCC_0/CCC_INST/INST_CCC_IP/GL0 } ]
create_generated_clock -name {uart0clk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart0BitClockDiv/clko_i/Q } ]
create_generated_clock -name {uart0txclk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart0TxBitClockDiv/div_i/Q } ]
create_generated_clock -name {uart1clk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart1BitClockDiv/clko_i/Q } ]
create_generated_clock -name {uart1txclk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart1TxBitClockDiv/div_i/Q } ]
create_generated_clock -name {uart2clk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart2BitClockDiv/clko_i/Q } ]
create_generated_clock -name {uart2txclk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart2TxBitClockDiv/div_i/Q } ]
create_generated_clock -name {uart3clk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart3BitClockDiv/clko_i/Q } ]
create_generated_clock -name {uart3txclk} -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/INST_CCC_IP/GL0 } ] [ get_pins { Main_0/Uart3TxBitClockDiv/div_i/Q } ]
set_clock_to_output -min 0 -clock { MasterClk } [ get_ports { MosiMonAdc0 } ]
set_clock_to_output -max 19 -clock { MasterClk } [ get_ports { MosiMonAdc0 } ]
set_clock_to_output -min 0 -clock { MasterClk } [ get_ports { SckMonAdc0 } ]
set_clock_to_output -max 19 -clock { MasterClk } [ get_ports { SckMonAdc0 } ]
set_clock_to_output -min 0 -clock { MasterClk } [ get_ports { nCsMonAdc0 } ]
set_clock_to_output -max 19 -clock { MasterClk } [ get_ports { nCsMonAdc0 } ]
set_false_path -through [ get_nets { Filterwheel_sb_0/CORERESETP_0/ddr_settled Filterwheel_sb_0/CORERESETP_0/release_sdif*_core } ]
set_false_path -from [ get_cells { Filterwheel_sb_0/CORERESETP_0/MSS_HPMS_READY_int } ] -to [ get_cells { Filterwheel_sb_0/CORERESETP_0/sm0_areset_n_rcosc Filterwheel_sb_0/CORERESETP_0/sm0_areset_n_rcosc_q1 } ]
set_false_path -from [ get_cells { Filterwheel_sb_0/CORERESETP_0/MSS_HPMS_READY_int } ] -to [ get_cells { Filterwheel_sb_0/CORERESETP_0/sdif*_areset_n_rcosc* } ]
set_false_path -through [ get_pins { Filterwheel_sb_0/Filterwheel_sb_MSS_0/MSS_ADLIB_INST/INST_MSS_010_IP/CONFIG_PRESET_N } ]
set_false_path -through [ get_pins { Filterwheel_sb_0/SYSRESET_POR/INST_SYSRESET_FF_IP/POWER_ON_RESET_N } ]
set_false_path -to [ get_ports { Txd0 } ]
set_false_path -to [ get_ports { Txd1 } ]
set_false_path -to [ get_ports { Txd2 } ]
set_false_path -to [ get_ports { Txd3 } ]
set_false_path -to [ get_ports { RxdUsb } ]
set_false_path -to [ get_ports { TxdGps } ]
set_false_path -from [ get_ports { Rxd0 Rxd1 Rxd2 Rxd3 TxdUsb RxdGps } ]
