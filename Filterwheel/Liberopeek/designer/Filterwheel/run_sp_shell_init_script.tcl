set_device \
    -family  SmartFusion2 \
    -die     PA4M2500_N \
    -package vf256 \
    -speed   -1 \
    -tempr   {IND} \
    -voltr   {IND}
set_def {VOLTAGE} {1.2}
set_def {VCCI_1.2_VOLTR} {COM}
set_def {VCCI_1.5_VOLTR} {COM}
set_def {VCCI_1.8_VOLTR} {COM}
set_def {VCCI_2.5_VOLTR} {COM}
set_def {VCCI_3.3_VOLTR} {COM}
set_def {PLL_SUPPLY} {PLL_SUPPLY_25}
set_def {VPP_SUPPLY_25_33} {VPP_SUPPLY_25}
set_def {VDDAUX_SUPPLY_25_33} {VDDAUX_SUPPLY_25}
set_def {PA4_URAM_FF_CONFIG} {SUSPEND}
set_def {PA4_SRAM_FF_CONFIG} {SUSPEND}
set_def {PA4_MSS_FF_CLOCK} {RCOSC_1MHZ}
set_def USE_CONSTRAINTS_FLOW 1
set_netlist -afl {/home/summer/projects/CGraph/firmware/Filterwheel/Libero/designer/Filterwheel/Filterwheel.afl} -adl {/home/summer/projects/CGraph/firmware/Filterwheel/Libero/designer/Filterwheel/Filterwheel.adl}
set_placement   {/home/summer/projects/CGraph/firmware/Filterwheel/Libero/designer/Filterwheel/Filterwheel.loc}
set_routing     {/home/summer/projects/CGraph/firmware/Filterwheel/Libero/designer/Filterwheel/Filterwheel.seg}
