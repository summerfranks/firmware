open_project -project {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel_fp/Filterwheel.pro}
enable_device -name {M2S010} -enable 1
set_programming_file -name {M2S010} -file {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.ppd}
set_programming_action -action {PROGRAM} -name {M2S010} 
run_selected_actions
save_project
close_project
