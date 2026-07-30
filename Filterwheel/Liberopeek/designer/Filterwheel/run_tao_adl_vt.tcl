set_device -family {SmartFusion2} -die {M2S010} -speed {STD}
read_adl {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/designer/Filterwheel/Filterwheel.adl}
read_afl {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/designer/Filterwheel/Filterwheel.afl}
map_netlist
read_sdc {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/Filterwheel_derived_constraints.sdc}
read_sdc {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/user.sdc}
check_constraints -ignore_errors {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/constraint/timing_sdc_errors.log}
write_sdc -mode smarttime {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/designer/Filterwheel/timing_analysis.sdc}
