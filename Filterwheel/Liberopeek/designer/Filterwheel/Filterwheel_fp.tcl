new_project \
         -name {Filterwheel} \
         -location {/home/summer/projects/CGraph/firmware/FilterwheelTq144/Libero/designer/Filterwheel/Filterwheel_fp} \
         -mode {chain} \
         -connect_programmers {FALSE}
add_actel_device \
         -device {M2S010} \
         -name {M2S010}
enable_device \
         -name {M2S010} \
         -enable {TRUE}
save_project
close_project
