set_device -family {SmartFusion2} -die {M2S010} -speed {STD}
read_adl {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.adl}
read_afl {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.afl}
map_netlist
read_sdc {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/constraint/Filterwheel_derived_constraints.sdc}
read_sdc {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/constraint/user.sdc}
check_constraints -ignore_errors {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/constraint/placer_sdc_errors.log}
write_sdc -mode layout {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/place_route.sdc}
