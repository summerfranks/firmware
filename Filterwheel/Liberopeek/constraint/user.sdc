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