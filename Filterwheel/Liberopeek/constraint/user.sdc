create_clock -name VCXO -period 19.6078 [ get_ports { CLK0_PAD } ]
create_clock -ignore_errors -name {Filterwheel_sb_0/FABOSC_0/I_RCOSC_25_50MHZ/CLKOUT} -period 20 [ get_pins { Filterwheel_sb_0/FABOSC_0/I_RCOSC_25_50MHZ/CLKOUT } ]
create_generated_clock -name MasterClk -multiply_by 4 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ]
create_generated_clock -name {Filterwheel_sb_0/CCC_0/GL0} -multiply_by 3 -divide_by 3 -source [ get_pins { Filterwheel_sb_0/CCC_0/CCC_INST/CLK0 } ] -phase 0 [ get_pins { Filterwheel_sb_0/CCC_0/CCC_INST/GL0 } ]
set_false_path -ignore_errors -through [ get_nets { Filterwheel_sb_0/CORERESETP_0/ddr_settled Filterwheel_sb_0/CORERESETP_0/count_ddr_enable Filterwheel_sb_0/CORERESETP_0/release_sdif*_core Filterwheel_sb_0/CORERESETP_0/count_sdif*_enable } ]
set_false_path -ignore_errors -from [ get_cells { Filterwheel_sb_0/CORERESETP_0/MSS_HPMS_READY_int } ] -to [ get_cells { Filterwheel_sb_0/CORERESETP_0/sm0_areset_n_rcosc Filterwheel_sb_0/CORERESETP_0/sm0_areset_n_rcosc_q1 } ]
set_false_path -ignore_errors -from [ get_cells { Filterwheel_sb_0/CORERESETP_0/MSS_HPMS_READY_int Filterwheel_sb_0/CORERESETP_0/SDIF*_PERST_N_re } ] -to [ get_cells { Filterwheel_sb_0/CORERESETP_0/sdif*_areset_n_rcosc* } ]
set_false_path -ignore_errors -through [ get_nets { Filterwheel_sb_0/CORERESETP_0/CONFIG1_DONE Filterwheel_sb_0/CORERESETP_0/CONFIG2_DONE Filterwheel_sb_0/CORERESETP_0/SDIF*_PERST_N Filterwheel_sb_0/CORERESETP_0/SDIF*_PSEL Filterwheel_sb_0/CORERESETP_0/SDIF*_PWRITE Filterwheel_sb_0/CORERESETP_0/SDIF*_PRDATA[*] Filterwheel_sb_0/CORERESETP_0/SOFT_EXT_RESET_OUT Filterwheel_sb_0/CORERESETP_0/SOFT_RESET_F2M Filterwheel_sb_0/CORERESETP_0/SOFT_M3_RESET Filterwheel_sb_0/CORERESETP_0/SOFT_MDDR_DDR_AXI_S_CORE_RESET Filterwheel_sb_0/CORERESETP_0/SOFT_FDDR_CORE_RESET Filterwheel_sb_0/CORERESETP_0/SOFT_SDIF*_PHY_RESET Filterwheel_sb_0/CORERESETP_0/SOFT_SDIF*_CORE_RESET Filterwheel_sb_0/CORERESETP_0/SOFT_SDIF0_0_CORE_RESET Filterwheel_sb_0/CORERESETP_0/SOFT_SDIF0_1_CORE_RESET } ]
set_false_path -ignore_errors -through [ get_pins { Filterwheel_sb_0/Filterwheel_sb_MSS_0/MSS_ADLIB_INST/CONFIG_PRESET_N } ]
set_false_path -ignore_errors -through [ get_pins { Filterwheel_sb_0/SYSRESET_POR/POWER_ON_RESET_N } ]

create_generated_clock -name uart0clk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart0BitClockDiv/clko_i/Q } ]
create_generated_clock -name uart0txclk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart0TxBitClockDiv/div_i/Q } ]

create_generated_clock -name uart1clk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart1BitClockDiv/clko_i/Q } ]
create_generated_clock -name uart1txclk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart1TxBitClockDiv/div_i/Q } ]

create_generated_clock -name uart2clk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart2BitClockDiv/clko_i/Q } ]
create_generated_clock -name uart2txclk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart2TxBitClockDiv/div_i/Q } ]

create_generated_clock -name uart3clk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart3BitClockDiv/clko_i/Q } ]
create_generated_clock -name uart3txclk -multiply_by 1 -divide_by 2 -source [ get_pins { FCCC_C0_0/FCCC_C0_0/CCC_INST/GL0 } ] [ get_pins { Main_0/Uart3TxBitClockDiv/div_i/Q } ]

#If this is a UART output then it has no timing requirements relative to the clock or any other signal inside the FPGA so add this constraint to the .sdc to clear this warning:

set_false_path -to [ get_ports { Txd0 } ]
set_false_path -to [ get_ports { Txd1 } ]
set_false_path -to [ get_ports { Txd2 } ]
set_false_path -to [ get_ports { Txd3 } ]
set_false_path -to [ get_ports { RxdUsb } ]
set_false_path -to [ get_ports { TxdGps } ]

#If each of these is a UART input then each has no timing requirements relative to the clock or any other signal inside the FPGA so add this constraint to the .sdc to clear this warning:

set_false_path -from [ get_ports { Rxd0 Rxd1 Rxd2 Rxd3 TxdUsb RxdGps } ]

#"I'd try constraining each output to be 1 ns less than MasterClk's period for now. If some fail this then we can look closer at those. I'm guessing none of the outputs need to have a non-zero minimum clock to out delay (like PCI bus does for example).

set_clock_to_output -min  0 -clock { MasterClk } [ get_ports { MosiMonAdc0 } ]
set_clock_to_output -max  19 -clock { MasterClk } [ get_ports { MosiMonAdc0 } ]

set_clock_to_output -min  0 -clock { MasterClk } [ get_ports { SckMonAdc0 } ]
set_clock_to_output -max  19 -clock { MasterClk } [ get_ports { SckMonAdc0 } ]

set_clock_to_output -min  0 -clock { MasterClk } [ get_ports { nCsMonAdc0 } ]
set_clock_to_output -max  19 -clock { MasterClk } [ get_ports { nCsMonAdc0 } ]