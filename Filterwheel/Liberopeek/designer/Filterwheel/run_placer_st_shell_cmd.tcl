read_sdc -scenario "place_and_route" -netlist "optimized" -pin_separator "/" -ignore_errors {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/place_route.sdc}
set_options -tdpr_scenario "place_and_route" 
save
set_options -analysis_scenario "place_and_route"
report -type combinational_loops -format xml {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel_layout_combinational_loops.xml}
report -type slack {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/pinslacks.txt}
set coverage [report \
    -type     constraints_coverage \
    -format   xml \
    -slacks   no \
    {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/Filterwheel_place_and_route_constraint_coverage.xml}]
set reportfile {/home/summer/projects/CGraph/firmware/Filterwheel/Liberopeek/designer/Filterwheel/coverage_placeandroute}
set fp [open $reportfile w]
puts $fp $coverage
close $fp