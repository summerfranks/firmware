set_component FCCC_C0_FCCC_C0_0_FCCC
# Microsemi Corp.
# Date: 2024-Jul-18 09:27:49
#

create_clock -period 19.6078 [ get_pins { CCC_INST/CLK0_PAD } ]
create_generated_clock -multiply_by 4 -divide_by 2 -source [ get_pins { CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { CCC_INST/GL0 } ]
create_generated_clock -multiply_by 4 -divide_by 2 -source [ get_pins { CCC_INST/CLK0_PAD } ] -phase 0 [ get_pins { CCC_INST/GL1 } ]
