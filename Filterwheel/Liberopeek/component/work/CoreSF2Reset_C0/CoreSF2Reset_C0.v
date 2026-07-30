//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Tue Jul 30 10:55:31 2024
// Version: 2023.2 2023.2.0.10
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

//////////////////////////////////////////////////////////////////////
// Component Description (Tcl) 
//////////////////////////////////////////////////////////////////////
/*
# Exporting Component Description of CoreSF2Reset_C0 to TCL
# Family: SmartFusion2
# Part Number: M2S010-TQ144I
# Create and Configure the core component CoreSF2Reset_C0
create_and_configure_core -core_vlnv {Actel:DirectCore:CoreSF2Reset:3.0.100} -component_name {CoreSF2Reset_C0} -params {\
"DDR_WAIT:200"  \
"DEVICE_VOLTAGE:2"  \
"EXT_RESET_CFG:3"  \
"FDDR_IN_USE:false"  \
"MDDR_IN_USE:false"  \
"SDIF0_IN_USE:false"  \
"SDIF1_IN_USE:false"  \
"SDIF2_IN_USE:false"  \
"SDIF3_IN_USE:false"   }
# Exporting Component Description of CoreSF2Reset_C0 to TCL done
*/

// CoreSF2Reset_C0
module CoreSF2Reset_C0(
    // Inputs
    CLR_INIT_DONE,
    CONFIG_DONE,
    EXT_RESET_IN_N,
    MSS_RESET_N_M2F,
    POWER_ON_RESET_N,
    RCOSC_25_50MHZ,
    USER_FAB_RESET_IN_N,
    // Outputs
    EXT_RESET_OUT,
    INIT_DONE,
    M3_RESET_N,
    MSS_RESET_N_F2M,
    USER_FAB_RESET_N
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  CLR_INIT_DONE;
input  CONFIG_DONE;
input  EXT_RESET_IN_N;
input  MSS_RESET_N_M2F;
input  POWER_ON_RESET_N;
input  RCOSC_25_50MHZ;
input  USER_FAB_RESET_IN_N;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output EXT_RESET_OUT;
output INIT_DONE;
output M3_RESET_N;
output MSS_RESET_N_F2M;
output USER_FAB_RESET_N;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   CLR_INIT_DONE;
wire   CONFIG_DONE;
wire   EXT_RESET_IN_N;
wire   EXT_RESET_OUT_net_0;
wire   INIT_DONE_net_0;
wire   M3_RESET_N_net_0;
wire   MSS_RESET_N_F2M_net_0;
wire   MSS_RESET_N_M2F;
wire   POWER_ON_RESET_N;
wire   RCOSC_25_50MHZ;
wire   USER_FAB_RESET_IN_N;
wire   USER_FAB_RESET_N_net_0;
wire   MSS_RESET_N_F2M_net_1;
wire   M3_RESET_N_net_1;
wire   EXT_RESET_OUT_net_1;
wire   USER_FAB_RESET_N_net_1;
wire   INIT_DONE_net_1;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire   GND_net;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net = 1'b0;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign MSS_RESET_N_F2M_net_1  = MSS_RESET_N_F2M_net_0;
assign MSS_RESET_N_F2M        = MSS_RESET_N_F2M_net_1;
assign M3_RESET_N_net_1       = M3_RESET_N_net_0;
assign M3_RESET_N             = M3_RESET_N_net_1;
assign EXT_RESET_OUT_net_1    = EXT_RESET_OUT_net_0;
assign EXT_RESET_OUT          = EXT_RESET_OUT_net_1;
assign USER_FAB_RESET_N_net_1 = USER_FAB_RESET_N_net_0;
assign USER_FAB_RESET_N       = USER_FAB_RESET_N_net_1;
assign INIT_DONE_net_1        = INIT_DONE_net_0;
assign INIT_DONE              = INIT_DONE_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------CoreSF2Reset   -   Actel:DirectCore:CoreSF2Reset:3.0.100
CoreSF2Reset #( 
        .DDR_WAIT       ( 200 ),
        .DEVICE_VOLTAGE ( 2 ),
        .EXT_RESET_CFG  ( 3 ),
        .FDDR_IN_USE    ( 0 ),
        .MDDR_IN_USE    ( 0 ),
        .SDIF0_IN_USE   ( 0 ),
        .SDIF1_IN_USE   ( 0 ),
        .SDIF2_IN_USE   ( 0 ),
        .SDIF3_IN_USE   ( 0 ) )
CoreSF2Reset_C0_0(
        // Inputs
        .MSS_RESET_N_M2F             ( MSS_RESET_N_M2F ),
        .POWER_ON_RESET_N            ( POWER_ON_RESET_N ),
        .EXT_RESET_IN_N              ( EXT_RESET_IN_N ),
        .USER_FAB_RESET_IN_N         ( USER_FAB_RESET_IN_N ),
        .RCOSC_25_50MHZ              ( RCOSC_25_50MHZ ),
        .FPLL_LOCK                   ( GND_net ), // tied to 1'b0 from definition
        .SDIF0_SPLL_LOCK             ( GND_net ), // tied to 1'b0 from definition
        .SDIF1_SPLL_LOCK             ( GND_net ), // tied to 1'b0 from definition
        .SDIF2_SPLL_LOCK             ( GND_net ), // tied to 1'b0 from definition
        .SDIF3_SPLL_LOCK             ( GND_net ), // tied to 1'b0 from definition
        .CONFIG_DONE                 ( CONFIG_DONE ),
        .CLR_INIT_DONE               ( CLR_INIT_DONE ),
        // Outputs
        .MSS_RESET_N_F2M             ( MSS_RESET_N_F2M_net_0 ),
        .M3_RESET_N                  ( M3_RESET_N_net_0 ),
        .EXT_RESET_OUT               ( EXT_RESET_OUT_net_0 ),
        .USER_FAB_RESET_N            ( USER_FAB_RESET_N_net_0 ),
        .MDDR_DDR_AXI_S_CORE_RESET_N (  ),
        .FDDR_CORE_RESET_N           (  ),
        .SDIF0_CORE_RESET_N          (  ),
        .SDIF0_PHY_RESET_N           (  ),
        .SDIF1_CORE_RESET_N          (  ),
        .SDIF1_PHY_RESET_N           (  ),
        .SDIF2_CORE_RESET_N          (  ),
        .SDIF2_PHY_RESET_N           (  ),
        .SDIF3_CORE_RESET_N          (  ),
        .SDIF3_PHY_RESET_N           (  ),
        .INIT_DONE                   ( INIT_DONE_net_0 ) 
        );


endmodule
