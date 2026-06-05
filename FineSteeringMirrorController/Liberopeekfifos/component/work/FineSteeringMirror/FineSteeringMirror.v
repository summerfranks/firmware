//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Thu Jun  4 12:07:13 2026
// Version: 2023.2 2023.2.0.10
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// FineSteeringMirror
module FineSteeringMirror(
    // Inputs
    DEVRST_N,
    Fault1V,
    Fault2VA,
    Fault2VD,
    Fault3VA,
    Fault3VD,
    Fault43V,
    Fault5V,
    FaultHV,
    FaultNegV,
    MisoAdcA,
    MisoAdcB,
    MisoAdcC,
    MisoAdcD,
    MisoMonAdc0,
    MisoMonAdc1,
    PPS,
    PowerCycd,
    Rx0,
    Rx1,
    Rx2,
    Rx3,
    XO1,
    nDrdyAdcA,
    nDrdyAdcB,
    nDrdyAdcC,
    nDrdyAdcD,
    nDrdyMonAdc0,
    nDrdyMonAdc1,
    nHVFaultA,
    nHVFaultB,
    nHVFaultC,
    nHVFaultD,
    // Outputs
    ChopAdcs,
    ChopRef,
    GlobalFaultInhibit,
    HVEn1,
    HVEn2,
    MosiMonAdcs,
    Oe0,
    Oe1,
    Oe2,
    Oe3,
    PowerEnMax,
    PowerEnTi,
    PowerSync,
    PowernEn,
    PowernEnHV,
    SckAdcs,
    SckMonAdcs,
    SckXO,
    TP1,
    TP2,
    TP3,
    TP4,
    TP5,
    TP6,
    TP7,
    TP8,
    TrigAdcs,
    TrigMonAdcs,
    Tx0,
    Tx1,
    Tx2,
    Tx3,
    nCsAdcs,
    nCsMonAdcs,
    nCsXO,
    nFaultsClr,
    nPowerCycClr,
    // Inouts
    MosiMaxDacA,
    MosiMaxDacB,
    MosiMaxDacC,
    MosiMaxDacD,
    MosiTiDacA,
    MosiTiDacB,
    MosiTiDacC,
    MosiTiDacD,
    MosiXO,
    SckMaxDacs,
    SckTiDacs,
    Ux1SelJmp,
    nCsMaxDacs,
    nCsTiDacs,
    nLoadMaxDacs
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  DEVRST_N;
input  Fault1V;
input  Fault2VA;
input  Fault2VD;
input  Fault3VA;
input  Fault3VD;
input  Fault43V;
input  Fault5V;
input  FaultHV;
input  FaultNegV;
input  MisoAdcA;
input  MisoAdcB;
input  MisoAdcC;
input  MisoAdcD;
input  MisoMonAdc0;
input  MisoMonAdc1;
input  PPS;
input  PowerCycd;
input  Rx0;
input  Rx1;
input  Rx2;
input  Rx3;
input  XO1;
input  nDrdyAdcA;
input  nDrdyAdcB;
input  nDrdyAdcC;
input  nDrdyAdcD;
input  nDrdyMonAdc0;
input  nDrdyMonAdc1;
input  nHVFaultA;
input  nHVFaultB;
input  nHVFaultC;
input  nHVFaultD;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output ChopAdcs;
output ChopRef;
output GlobalFaultInhibit;
output HVEn1;
output HVEn2;
output MosiMonAdcs;
output Oe0;
output Oe1;
output Oe2;
output Oe3;
output PowerEnMax;
output PowerEnTi;
output PowerSync;
output PowernEn;
output PowernEnHV;
output SckAdcs;
output SckMonAdcs;
output SckXO;
output TP1;
output TP2;
output TP3;
output TP4;
output TP5;
output TP6;
output TP7;
output TP8;
output TrigAdcs;
output TrigMonAdcs;
output Tx0;
output Tx1;
output Tx2;
output Tx3;
output nCsAdcs;
output nCsMonAdcs;
output nCsXO;
output nFaultsClr;
output nPowerCycClr;
//--------------------------------------------------------------------
// Inout
//--------------------------------------------------------------------
inout  MosiMaxDacA;
inout  MosiMaxDacB;
inout  MosiMaxDacC;
inout  MosiMaxDacD;
inout  MosiTiDacA;
inout  MosiTiDacB;
inout  MosiTiDacC;
inout  MosiTiDacD;
inout  MosiXO;
inout  SckMaxDacs;
inout  SckTiDacs;
inout  Ux1SelJmp;
inout  nCsMaxDacs;
inout  nCsTiDacs;
inout  nLoadMaxDacs;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire          ChopAdcs_net_0;
wire          ChopRef_net_0;
wire          DEVRST_N;
wire          Fault1V;
wire          Fault2VA;
wire          Fault2VD;
wire          Fault3VA;
wire          Fault3VD;
wire          Fault5V;
wire          Fault43V;
wire          FaultHV;
wire          FaultNegV;
wire          FCCC_C0_0_GL0;
wire          FCCC_C0_0_GL1;
wire   [9:0]  FineSteeringMirror_sb_0_AMBA_SLAVE_0_PADDRS9to0;
wire          FineSteeringMirror_sb_0_AMBA_SLAVE_0_PENABLES;
wire          FineSteeringMirror_sb_0_AMBA_SLAVE_0_PSELS0;
wire   [31:0] FineSteeringMirror_sb_0_AMBA_SLAVE_0_PWDATAS;
wire          FineSteeringMirror_sb_0_AMBA_SLAVE_0_PWRITES;
wire          GlobalFaultInhibit_net_0;
wire          HVEn1_net_0;
wire          HVEn2_net_0;
wire          Main_0_RamBusAck;
wire   [31:0] Main_0_RamBusDataOut;
wire          MisoAdcA;
wire          MisoAdcB;
wire          MisoAdcC;
wire          MisoAdcD;
wire          MisoMonAdc0;
wire          MisoMonAdc1;
wire          MosiMaxDacA;
wire          MosiMaxDacB;
wire          MosiMaxDacC;
wire          MosiMaxDacD;
wire          MosiMonAdcs_net_0;
wire          MosiTiDacA;
wire          MosiTiDacB;
wire          MosiTiDacC;
wire          MosiTiDacD;
wire          MosiXO;
wire          nCsAdcs_net_0;
wire          nCsMaxDacs;
wire          nCsMonAdcs_net_0;
wire          nCsTiDacs;
wire          nCsXO_net_0;
wire          nDrdyAdcA;
wire          nDrdyAdcB;
wire          nDrdyAdcC;
wire          nDrdyAdcD;
wire          nDrdyMonAdc0;
wire          nDrdyMonAdc1;
wire          nFaultsClr_net_0;
wire          nHVFaultA;
wire          nHVFaultB;
wire          nHVFaultC;
wire          nHVFaultD;
wire          nLoadMaxDacs;
wire          nPowerCycClr_net_0;
wire          Oe0_net_0;
wire          Oe1_net_0;
wire          Oe2_net_0;
wire          Oe3_net_0;
wire          PowerCycd;
wire          PowerEnMax_net_0;
wire          PowerEnTi_net_0;
wire          PowernEn_net_0;
wire          PowernEnHV_net_0;
wire          PowerSync_net_0;
wire          PPS;
wire          Rx0;
wire          Rx1;
wire          Rx2;
wire          Rx3;
wire          SckAdcs_net_0;
wire          SckMaxDacs;
wire          SckMonAdcs_net_0;
wire          SckTiDacs;
wire          SckXO_net_0;
wire          TP1_net_0;
wire          TP2_net_0;
wire          TP3_net_0;
wire          TP4_net_0;
wire          TP5_net_0;
wire          TP6_net_0;
wire          TP7_net_0;
wire          TP8_net_0;
wire          TrigAdcs_net_0;
wire          TrigMonAdcs_net_0;
wire          Tx0_net_0;
wire          Tx1_net_0;
wire          Tx2_net_0;
wire          Tx3_net_0;
wire          Ux1SelJmp;
wire          XO1;
wire          Oe0_net_1;
wire          Oe1_net_1;
wire          Oe2_net_1;
wire          nCsXO_net_1;
wire          SckXO_net_1;
wire          Oe3_net_1;
wire          nPowerCycClr_net_1;
wire          PowerSync_net_1;
wire          PowernEn_net_1;
wire          PowernEnHV_net_1;
wire          TrigAdcs_net_1;
wire          SckAdcs_net_1;
wire          nCsAdcs_net_1;
wire          nCsMonAdcs_net_1;
wire          SckMonAdcs_net_1;
wire          MosiMonAdcs_net_1;
wire          TrigMonAdcs_net_1;
wire          GlobalFaultInhibit_net_1;
wire          nFaultsClr_net_1;
wire          Tx0_net_1;
wire          Tx1_net_1;
wire          Tx2_net_1;
wire          Tx3_net_1;
wire          HVEn1_net_1;
wire          HVEn2_net_1;
wire          TP1_net_1;
wire          TP2_net_1;
wire          TP3_net_1;
wire          TP4_net_1;
wire          TP5_net_1;
wire          TP6_net_1;
wire          TP7_net_1;
wire          TP8_net_1;
wire          PowerEnTi_net_1;
wire          PowerEnMax_net_1;
wire          ChopRef_net_1;
wire          ChopAdcs_net_1;
wire   [31:0] AMBA_SLAVE_0_PADDRS_net_0;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire          VCC_net;
wire          GND_net;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign VCC_net = 1'b1;
assign GND_net = 1'b0;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign Oe0_net_1                = Oe0_net_0;
assign Oe0                      = Oe0_net_1;
assign Oe1_net_1                = Oe1_net_0;
assign Oe1                      = Oe1_net_1;
assign Oe2_net_1                = Oe2_net_0;
assign Oe2                      = Oe2_net_1;
assign nCsXO_net_1              = nCsXO_net_0;
assign nCsXO                    = nCsXO_net_1;
assign SckXO_net_1              = SckXO_net_0;
assign SckXO                    = SckXO_net_1;
assign Oe3_net_1                = Oe3_net_0;
assign Oe3                      = Oe3_net_1;
assign nPowerCycClr_net_1       = nPowerCycClr_net_0;
assign nPowerCycClr             = nPowerCycClr_net_1;
assign PowerSync_net_1          = PowerSync_net_0;
assign PowerSync                = PowerSync_net_1;
assign PowernEn_net_1           = PowernEn_net_0;
assign PowernEn                 = PowernEn_net_1;
assign PowernEnHV_net_1         = PowernEnHV_net_0;
assign PowernEnHV               = PowernEnHV_net_1;
assign TrigAdcs_net_1           = TrigAdcs_net_0;
assign TrigAdcs                 = TrigAdcs_net_1;
assign SckAdcs_net_1            = SckAdcs_net_0;
assign SckAdcs                  = SckAdcs_net_1;
assign nCsAdcs_net_1            = nCsAdcs_net_0;
assign nCsAdcs                  = nCsAdcs_net_1;
assign nCsMonAdcs_net_1         = nCsMonAdcs_net_0;
assign nCsMonAdcs               = nCsMonAdcs_net_1;
assign SckMonAdcs_net_1         = SckMonAdcs_net_0;
assign SckMonAdcs               = SckMonAdcs_net_1;
assign MosiMonAdcs_net_1        = MosiMonAdcs_net_0;
assign MosiMonAdcs              = MosiMonAdcs_net_1;
assign TrigMonAdcs_net_1        = TrigMonAdcs_net_0;
assign TrigMonAdcs              = TrigMonAdcs_net_1;
assign GlobalFaultInhibit_net_1 = GlobalFaultInhibit_net_0;
assign GlobalFaultInhibit       = GlobalFaultInhibit_net_1;
assign nFaultsClr_net_1         = nFaultsClr_net_0;
assign nFaultsClr               = nFaultsClr_net_1;
assign Tx0_net_1                = Tx0_net_0;
assign Tx0                      = Tx0_net_1;
assign Tx1_net_1                = Tx1_net_0;
assign Tx1                      = Tx1_net_1;
assign Tx2_net_1                = Tx2_net_0;
assign Tx2                      = Tx2_net_1;
assign Tx3_net_1                = Tx3_net_0;
assign Tx3                      = Tx3_net_1;
assign HVEn1_net_1              = HVEn1_net_0;
assign HVEn1                    = HVEn1_net_1;
assign HVEn2_net_1              = HVEn2_net_0;
assign HVEn2                    = HVEn2_net_1;
assign TP1_net_1                = TP1_net_0;
assign TP1                      = TP1_net_1;
assign TP2_net_1                = TP2_net_0;
assign TP2                      = TP2_net_1;
assign TP3_net_1                = TP3_net_0;
assign TP3                      = TP3_net_1;
assign TP4_net_1                = TP4_net_0;
assign TP4                      = TP4_net_1;
assign TP5_net_1                = TP5_net_0;
assign TP5                      = TP5_net_1;
assign TP6_net_1                = TP6_net_0;
assign TP6                      = TP6_net_1;
assign TP7_net_1                = TP7_net_0;
assign TP7                      = TP7_net_1;
assign TP8_net_1                = TP8_net_0;
assign TP8                      = TP8_net_1;
assign PowerEnTi_net_1          = PowerEnTi_net_0;
assign PowerEnTi                = PowerEnTi_net_1;
assign PowerEnMax_net_1         = PowerEnMax_net_0;
assign PowerEnMax               = PowerEnMax_net_1;
assign ChopRef_net_1            = ChopRef_net_0;
assign ChopRef                  = ChopRef_net_1;
assign ChopAdcs_net_1           = ChopAdcs_net_0;
assign ChopAdcs                 = ChopAdcs_net_1;
//--------------------------------------------------------------------
// Slices assignments
//--------------------------------------------------------------------
assign FineSteeringMirror_sb_0_AMBA_SLAVE_0_PADDRS9to0 = AMBA_SLAVE_0_PADDRS_net_0[9:0];
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------FCCC_C0
FCCC_C0 FCCC_C0_0(
        // Inputs
        .CLK0_PAD ( XO1 ),
        // Outputs
        .GL0      ( FCCC_C0_0_GL0 ),
        .GL1      ( FCCC_C0_0_GL1 ),
        .LOCK     (  ) 
        );

//--------FineSteeringMirror_sb
FineSteeringMirror_sb FineSteeringMirror_sb_0(
        // Inputs
        .FAB_RESET_N            ( VCC_net ),
        .AMBA_SLAVE_0_PREADYS0  ( Main_0_RamBusAck ),
        .AMBA_SLAVE_0_PSLVERRS0 ( GND_net ),
        .DEVRST_N               ( DEVRST_N ),
        .CLK0                   ( FCCC_C0_0_GL0 ),
        .MMUART_0_RXD_F2M       ( VCC_net ),
        .AMBA_SLAVE_0_PRDATAS0  ( Main_0_RamBusDataOut ),
        // Outputs
        .POWER_ON_RESET_N       (  ),
        .INIT_DONE              (  ),
        .AMBA_SLAVE_0_PSELS0    ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PSELS0 ),
        .AMBA_SLAVE_0_PENABLES  ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PENABLES ),
        .AMBA_SLAVE_0_PWRITES   ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PWRITES ),
        .FIC_0_CLK              (  ),
        .FIC_0_LOCK             (  ),
        .MSS_READY              (  ),
        .MMUART_0_TXD_M2F       (  ),
        .AMBA_SLAVE_0_PADDRS    ( AMBA_SLAVE_0_PADDRS_net_0 ),
        .AMBA_SLAVE_0_PWDATAS   ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PWDATAS ) 
        );

//--------Main
Main Main_0(
        // Inputs
        .clk                ( FCCC_C0_0_GL1 ),
        .nHVFaultA          ( nHVFaultA ),
        .nHVFaultB          ( nHVFaultB ),
        .nHVFaultC          ( nHVFaultC ),
        .nHVFaultD          ( nHVFaultD ),
        .MisoAdcA           ( MisoAdcA ),
        .MisoAdcB           ( MisoAdcB ),
        .MisoAdcC           ( MisoAdcC ),
        .MisoAdcD           ( MisoAdcD ),
        .nDrdyAdcA          ( nDrdyAdcA ),
        .nDrdyAdcB          ( nDrdyAdcB ),
        .nDrdyAdcC          ( nDrdyAdcC ),
        .nDrdyAdcD          ( nDrdyAdcD ),
        .RamBusAddress      ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PADDRS9to0 ),
        .RamBusDataIn       ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PWDATAS ),
        .RamBusnCs          ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PSELS0 ),
        .RamBusWrnRd        ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PWRITES ),
        .RamBusLatch        ( FineSteeringMirror_sb_0_AMBA_SLAVE_0_PENABLES ),
        .Rx0                ( Rx0 ),
        .Rx1                ( Rx1 ),
        .Rx2                ( Rx2 ),
        .Rx3                ( Rx3 ),
        .PPS                ( PPS ),
        .MisoMonAdc0        ( MisoMonAdc0 ),
        .nDrdyMonAdc0       ( nDrdyMonAdc0 ),
        .MisoMonAdc1        ( MisoMonAdc1 ),
        .nDrdyMonAdc1       ( nDrdyMonAdc1 ),
        .PowerCycd          ( PowerCycd ),
        .FaultNegV          ( FaultNegV ),
        .Fault1V            ( Fault1V ),
        .Fault2VA           ( Fault2VA ),
        .Fault2VD           ( Fault2VD ),
        .Fault3VA           ( Fault3VA ),
        .Fault3VD           ( Fault3VD ),
        .Fault43V           ( Fault43V ),
        .Fault5V            ( Fault5V ),
        .FaultHV            ( FaultHV ),
        // Outputs
        .nCsXO              ( nCsXO_net_0 ),
        .SckXO              ( SckXO_net_0 ),
        .PowerEnTi          ( PowerEnTi_net_0 ),
        .PowerEnMax         ( PowerEnMax_net_0 ),
        .HVEn1              ( HVEn1_net_0 ),
        .HVEn2              ( HVEn2_net_0 ),
        .PowernEnHV         ( PowernEnHV_net_0 ),
        .ChopRef            ( ChopRef_net_0 ),
        .ChopAdcs           ( ChopAdcs_net_0 ),
        .TrigAdcs           ( TrigAdcs_net_0 ),
        .SckAdcs            ( SckAdcs_net_0 ),
        .nCsAdcs            ( nCsAdcs_net_0 ),
        .RamBusDataOut      ( Main_0_RamBusDataOut ),
        .RamBusAck          ( Main_0_RamBusAck ),
        .Tx0                ( Tx0_net_0 ),
        .Oe0                ( Oe0_net_0 ),
        .Tx1                ( Tx1_net_0 ),
        .Oe1                ( Oe1_net_0 ),
        .Tx2                ( Tx2_net_0 ),
        .Oe2                ( Oe2_net_0 ),
        .Tx3                ( Tx3_net_0 ),
        .Oe3                ( Oe3_net_0 ),
        .nCsMonAdcs         ( nCsMonAdcs_net_0 ),
        .SckMonAdcs         ( SckMonAdcs_net_0 ),
        .MosiMonAdcs        ( MosiMonAdcs_net_0 ),
        .TrigMonAdcs        ( TrigMonAdcs_net_0 ),
        .PowerSync          ( PowerSync_net_0 ),
        .PowernEn           ( PowernEn_net_0 ),
        .GlobalFaultInhibit ( GlobalFaultInhibit_net_0 ),
        .nFaultsClr         ( nFaultsClr_net_0 ),
        .nPowerCycClr       ( nPowerCycClr_net_0 ),
        .TP1                ( TP1_net_0 ),
        .TP2                ( TP2_net_0 ),
        .TP3                ( TP3_net_0 ),
        .TP4                ( TP4_net_0 ),
        .TP5                ( TP5_net_0 ),
        .TP6                ( TP6_net_0 ),
        .TP7                ( TP7_net_0 ),
        .TP8                ( TP8_net_0 ),
        // Inouts
        .MosiXO             ( MosiXO ),
        .MosiTiDacA         ( MosiTiDacA ),
        .MosiTiDacB         ( MosiTiDacB ),
        .MosiTiDacC         ( MosiTiDacC ),
        .MosiTiDacD         ( MosiTiDacD ),
        .SckTiDacs          ( SckTiDacs ),
        .nCsTiDacs          ( nCsTiDacs ),
        .MosiMaxDacA        ( MosiMaxDacA ),
        .MosiMaxDacB        ( MosiMaxDacB ),
        .MosiMaxDacC        ( MosiMaxDacC ),
        .MosiMaxDacD        ( MosiMaxDacD ),
        .SckMaxDacs         ( SckMaxDacs ),
        .nCsMaxDacs         ( nCsMaxDacs ),
        .nLoadMaxDacs       ( nLoadMaxDacs ),
        .Ux1SelJmp          ( Ux1SelJmp ) 
        );


endmodule
