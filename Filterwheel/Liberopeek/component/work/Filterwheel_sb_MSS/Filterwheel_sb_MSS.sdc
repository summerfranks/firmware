set_component Filterwheel_sb_MSS
# Microsemi Corp.
# Date: 2024-May-23 17:02:44
#

create_clock -period 39.2157 [ get_pins { MSS_ADLIB_INST/CLK_CONFIG_APB } ]
set_false_path -ignore_errors -through [ get_pins { MSS_ADLIB_INST/CONFIG_PRESET_N } ]
