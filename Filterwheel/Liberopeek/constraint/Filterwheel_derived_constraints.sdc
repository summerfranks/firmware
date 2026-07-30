# Microsemi Corp.
# Date: 2025-Mar-26 16:05:13
# This file was generated based on the following SDC source files:
#   /home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/FCCC_C0/FCCC_C0_0/FCCC_C0_FCCC_C0_0_FCCC.sdc
#   /home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb/CCC_0/Filterwheel_sb_CCC_0_FCCC.sdc
#   /home/summer/microchip/Libero_SoC_v2023.2/Libero/data/aPA4M/cores/constraints/coreresetp.sdc
#   /home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb/FABOSC_0/Filterwheel_sb_FABOSC_0_OSC.sdc
#   /home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/component/work/Filterwheel_sb_MSS/Filterwheel_sb_MSS.sdc
#   /home/summer/microchip/Libero_SoC_v2023.2/Libero/data/aPA4M/cores/constraints/sysreset.sdc
# *** Any modifications to this file will be lost if derived constraints is re-run. ***
#

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
