open_project -project {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/designer/Filterwheel/Filterwheel_fp/Filterwheel.pro}\
         -connect_programmers {FALSE}
set_programming_file -name {M2S010} -file {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/designer/Filterwheel/Filterwheel.ppd}
enable_procedure -name {M2S010} -action {PROGRAM} -procedure {DO_VERIFY} -enable {TRUE}
save_project
close_project
