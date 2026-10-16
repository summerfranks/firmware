open_project -project {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel_fp/Filterwheel.pro}\
         -connect_programmers {FALSE}
load_programming_data \
    -name {M2S010} \
    -fpga {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.map} \
    -header {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.hdr} \
    -envm {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.efc} \
    -spm {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.spm} \
    -dca {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.dca}
export_single_ppd \
    -name {M2S010} \
    -file {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel.ppd}

save_project
close_project
