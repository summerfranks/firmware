read_sdc -scenario "timing_analysis" -netlist "optimized" -pin_separator "/" -ignore_errors {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/timing_analysis.sdc}
set_options -analysis_scenario "timing_analysis" 
save
source {Filterwheel_run_timrpt_st_shell_txt.tcl}
