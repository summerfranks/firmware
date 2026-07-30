//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Thu Jul 30 14:16:24 2026
// Version: 2023.2 2023.2.0.10
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// Filterwheel
module Filterwheel(
    // Inputs
    CLK0_PAD,
    DEVRST_N,
    Fault1V,
    Fault3V,
    Fault5V,
    MisoMonAdc0,
    PPS,
    PosSenseBit0A,
    PosSenseBit0B,
    PosSenseBit1A,
    PosSenseBit1B,
    PosSenseBit2A,
    PosSenseBit2B,
    PosSenseHomeA,
    PosSenseHomeB,
    PowerCycd,
    Rxd0,
    Rxd1,
    Rxd2,
    Rxd3,
    RxdGps,
    TxdUsb,
    nDrdyMonAdc0,
    // Outputs
    CtsUsb,
    INIT_DONE,
    LedB,
    LedG,
    LedR,
    MosiMonAdc0,
    MosiXO,
    MotorDriveAMinus,
    MotorDriveAMinusPrime,
    MotorDriveAPlus,
    MotorDriveAPlusPrime,
    MotorDriveBMinus,
    MotorDriveBMinusPrime,
    MotorDriveBPlus,
    MotorDriveBPlusPrime,
    Oe0,
    Oe1,
    Oe2,
    Oe3,
    PosLEDEnA,
    PosLEDEnB,
    PowerSync,
    PowernEn5V,
    RxdUsb,
    SckMonAdc0,
    SckXO,
    TP1,
    TP2,
    TP3,
    TP4,
    TP5,
    TP6,
    TP7,
    TP8,
    Txd0,
    Txd1,
    Txd2,
    Txd3,
    TxdGps,
    nCsMonAdc0,
    nCsXO,
    nFaultClr1V,
    nFaultClr3V,
    nFaultClr5V,
    nPowerCycClr,
    // Inouts
    Ux1SelJmp
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  CLK0_PAD;
input  DEVRST_N;
input  Fault1V;
input  Fault3V;
input  Fault5V;
input  MisoMonAdc0;
input  PPS;
input  PosSenseBit0A;
input  PosSenseBit0B;
input  PosSenseBit1A;
input  PosSenseBit1B;
input  PosSenseBit2A;
input  PosSenseBit2B;
input  PosSenseHomeA;
input  PosSenseHomeB;
input  PowerCycd;
input  Rxd0;
input  Rxd1;
input  Rxd2;
input  Rxd3;
input  RxdGps;
input  TxdUsb;
input  nDrdyMonAdc0;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output CtsUsb;
output INIT_DONE;
output LedB;
output LedG;
output LedR;
output MosiMonAdc0;
output MosiXO;
output MotorDriveAMinus;
output MotorDriveAMinusPrime;
output MotorDriveAPlus;
output MotorDriveAPlusPrime;
output MotorDriveBMinus;
output MotorDriveBMinusPrime;
output MotorDriveBPlus;
output MotorDriveBPlusPrime;
output Oe0;
output Oe1;
output Oe2;
output Oe3;
output PosLEDEnA;
output PosLEDEnB;
output PowerSync;
output PowernEn5V;
output RxdUsb;
output SckMonAdc0;
output SckXO;
output TP1;
output TP2;
output TP3;
output TP4;
output TP5;
output TP6;
output TP7;
output TP8;
output Txd0;
output Txd1;
output Txd2;
output Txd3;
output TxdGps;
output nCsMonAdc0;
output nCsXO;
output nFaultClr1V;
output nFaultClr3V;
output nFaultClr5V;
output nPowerCycClr;
//--------------------------------------------------------------------
// Inout
//--------------------------------------------------------------------
inout  Ux1SelJmp;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire           CLK0_PAD;
wire           CtsUsb_net_0;
wire           DEVRST_N;
wire           Fault1V;
wire           Fault3V;
wire           Fault5V;
wire           FCCC_C0_0_GL0;
wire   [9:0]   Filterwheel_sb_0_AMBA_SLAVE_0_PADDRS9to0;
wire           Filterwheel_sb_0_AMBA_SLAVE_0_PENABLES;
wire           Filterwheel_sb_0_AMBA_SLAVE_0_PSELS0;
wire   [31:0]  Filterwheel_sb_0_AMBA_SLAVE_0_PWDATAS;
wire           Filterwheel_sb_0_AMBA_SLAVE_0_PWRITES;
wire           INIT_DONE_net_0;
wire           LedB_net_0;
wire           LedG_net_0;
wire           LedR_net_0;
wire           Main_0_RamBusAck;
wire   [31:0]  Main_0_RamBusDataOut;
wire           MisoMonAdc0;
wire           MosiMonAdc0_net_0;
wire           MosiXO_net_0;
wire           MotorDriveAMinus_net_0;
wire           MotorDriveAMinusPrime_net_0;
wire           MotorDriveAPlus_net_0;
wire           MotorDriveAPlusPrime_net_0;
wire           MotorDriveBMinus_net_0;
wire           MotorDriveBMinusPrime_net_0;
wire           MotorDriveBPlus_net_0;
wire           MotorDriveBPlusPrime_net_0;
wire           nCsMonAdc0_net_0;
wire           nCsXO_net_0;
wire           nDrdyMonAdc0;
wire           nFaultClr1V_net_0;
wire           nFaultClr3V_net_0;
wire           nFaultClr5V_net_0;
wire           nPowerCycClr_net_0;
wire           Oe0_net_0;
wire           Oe1_net_0;
wire           Oe2_net_0;
wire           Oe3_net_0;
wire           PosLEDEnA_net_0;
wire           PosLEDEnB_net_0;
wire           PosSenseBit0A;
wire           PosSenseBit0B;
wire           PosSenseBit1A;
wire           PosSenseBit1B;
wire           PosSenseBit2A;
wire           PosSenseBit2B;
wire           PosSenseHomeA;
wire           PosSenseHomeB;
wire           PowerCycd;
wire           PowernEn5V_net_0;
wire           PowerSync_net_0;
wire           PPS;
wire           Rxd0;
wire           Rxd1;
wire           Rxd2;
wire           Rxd3;
wire           RxdGps;
wire           RxdUsb_net_0;
wire           SckMonAdc0_net_0;
wire           SckXO_net_0;
wire           TP1_net_0;
wire           TP2_net_0;
wire           TP3_net_0;
wire           TP4_net_0;
wire           TP5_net_0;
wire           TP6_net_0;
wire           TP7_net_0;
wire           TP8_net_0;
wire           Txd0_net_0;
wire           Txd1_net_0;
wire           Txd2_net_0;
wire           Txd3_net_0;
wire           TxdGps_net_0;
wire           TxdUsb;
wire           Ux1SelJmp;
wire           PosLEDEnA_net_1;
wire           PosLEDEnB_net_1;
wire           MotorDriveAPlus_net_1;
wire           MotorDriveAMinus_net_1;
wire           MotorDriveBPlus_net_1;
wire           MotorDriveBMinus_net_1;
wire           MotorDriveAPlusPrime_net_1;
wire           MotorDriveAMinusPrime_net_1;
wire           MotorDriveBPlusPrime_net_1;
wire           MotorDriveBMinusPrime_net_1;
wire           Txd0_net_1;
wire           Txd1_net_1;
wire           Txd2_net_1;
wire           Oe0_net_1;
wire           Oe1_net_1;
wire           Oe2_net_1;
wire           INIT_DONE_net_1;
wire           nCsXO_net_1;
wire           SckXO_net_1;
wire           MosiXO_net_1;
wire           Txd3_net_1;
wire           Oe3_net_1;
wire           CtsUsb_net_1;
wire           TxdGps_net_1;
wire           nCsMonAdc0_net_1;
wire           SckMonAdc0_net_1;
wire           MosiMonAdc0_net_1;
wire           nFaultClr1V_net_1;
wire           nFaultClr3V_net_1;
wire           nFaultClr5V_net_1;
wire           nPowerCycClr_net_1;
wire           PowerSync_net_1;
wire           LedR_net_1;
wire           LedG_net_1;
wire           LedB_net_1;
wire           TP1_net_1;
wire           TP2_net_1;
wire           TP3_net_1;
wire           TP4_net_1;
wire           TP5_net_1;
wire           TP6_net_1;
wire           TP7_net_1;
wire           TP8_net_1;
wire           PowernEn5V_net_1;
wire           RxdUsb_net_1;
wire   [31:10] AMBA_SLAVE_0_PADDRS_slice_0;
wire   [31:0]  AMBA_SLAVE_0_PADDRS_net_0;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire           GND_net;
wire           VCC_net;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign GND_net = 1'b0;
assign VCC_net = 1'b1;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign PosLEDEnA_net_1             = PosLEDEnA_net_0;
assign PosLEDEnA                   = PosLEDEnA_net_1;
assign PosLEDEnB_net_1             = PosLEDEnB_net_0;
assign PosLEDEnB                   = PosLEDEnB_net_1;
assign MotorDriveAPlus_net_1       = MotorDriveAPlus_net_0;
assign MotorDriveAPlus             = MotorDriveAPlus_net_1;
assign MotorDriveAMinus_net_1      = MotorDriveAMinus_net_0;
assign MotorDriveAMinus            = MotorDriveAMinus_net_1;
assign MotorDriveBPlus_net_1       = MotorDriveBPlus_net_0;
assign MotorDriveBPlus             = MotorDriveBPlus_net_1;
assign MotorDriveBMinus_net_1      = MotorDriveBMinus_net_0;
assign MotorDriveBMinus            = MotorDriveBMinus_net_1;
assign MotorDriveAPlusPrime_net_1  = MotorDriveAPlusPrime_net_0;
assign MotorDriveAPlusPrime        = MotorDriveAPlusPrime_net_1;
assign MotorDriveAMinusPrime_net_1 = MotorDriveAMinusPrime_net_0;
assign MotorDriveAMinusPrime       = MotorDriveAMinusPrime_net_1;
assign MotorDriveBPlusPrime_net_1  = MotorDriveBPlusPrime_net_0;
assign MotorDriveBPlusPrime        = MotorDriveBPlusPrime_net_1;
assign MotorDriveBMinusPrime_net_1 = MotorDriveBMinusPrime_net_0;
assign MotorDriveBMinusPrime       = MotorDriveBMinusPrime_net_1;
assign Txd0_net_1                  = Txd0_net_0;
assign Txd0                        = Txd0_net_1;
assign Txd1_net_1                  = Txd1_net_0;
assign Txd1                        = Txd1_net_1;
assign Txd2_net_1                  = Txd2_net_0;
assign Txd2                        = Txd2_net_1;
assign Oe0_net_1                   = Oe0_net_0;
assign Oe0                         = Oe0_net_1;
assign Oe1_net_1                   = Oe1_net_0;
assign Oe1                         = Oe1_net_1;
assign Oe2_net_1                   = Oe2_net_0;
assign Oe2                         = Oe2_net_1;
assign INIT_DONE_net_1             = INIT_DONE_net_0;
assign INIT_DONE                   = INIT_DONE_net_1;
assign nCsXO_net_1                 = nCsXO_net_0;
assign nCsXO                       = nCsXO_net_1;
assign SckXO_net_1                 = SckXO_net_0;
assign SckXO                       = SckXO_net_1;
assign MosiXO_net_1                = MosiXO_net_0;
assign MosiXO                      = MosiXO_net_1;
assign Txd3_net_1                  = Txd3_net_0;
assign Txd3                        = Txd3_net_1;
assign Oe3_net_1                   = Oe3_net_0;
assign Oe3                         = Oe3_net_1;
assign CtsUsb_net_1                = CtsUsb_net_0;
assign CtsUsb                      = CtsUsb_net_1;
assign TxdGps_net_1                = TxdGps_net_0;
assign TxdGps                      = TxdGps_net_1;
assign nCsMonAdc0_net_1            = nCsMonAdc0_net_0;
assign nCsMonAdc0                  = nCsMonAdc0_net_1;
assign SckMonAdc0_net_1            = SckMonAdc0_net_0;
assign SckMonAdc0                  = SckMonAdc0_net_1;
assign MosiMonAdc0_net_1           = MosiMonAdc0_net_0;
assign MosiMonAdc0                 = MosiMonAdc0_net_1;
assign nFaultClr1V_net_1           = nFaultClr1V_net_0;
assign nFaultClr1V                 = nFaultClr1V_net_1;
assign nFaultClr3V_net_1           = nFaultClr3V_net_0;
assign nFaultClr3V                 = nFaultClr3V_net_1;
assign nFaultClr5V_net_1           = nFaultClr5V_net_0;
assign nFaultClr5V                 = nFaultClr5V_net_1;
assign nPowerCycClr_net_1          = nPowerCycClr_net_0;
assign nPowerCycClr                = nPowerCycClr_net_1;
assign PowerSync_net_1             = PowerSync_net_0;
assign PowerSync                   = PowerSync_net_1;
assign LedR_net_1                  = LedR_net_0;
assign LedR                        = LedR_net_1;
assign LedG_net_1                  = LedG_net_0;
assign LedG                        = LedG_net_1;
assign LedB_net_1                  = LedB_net_0;
assign LedB                        = LedB_net_1;
assign TP1_net_1                   = TP1_net_0;
assign TP1                         = TP1_net_1;
assign TP2_net_1                   = TP2_net_0;
assign TP2                         = TP2_net_1;
assign TP3_net_1                   = TP3_net_0;
assign TP3                         = TP3_net_1;
assign TP4_net_1                   = TP4_net_0;
assign TP4                         = TP4_net_1;
assign TP5_net_1                   = TP5_net_0;
assign TP5                         = TP5_net_1;
assign TP6_net_1                   = TP6_net_0;
assign TP6                         = TP6_net_1;
assign TP7_net_1                   = TP7_net_0;
assign TP7                         = TP7_net_1;
assign TP8_net_1                   = TP8_net_0;
assign TP8                         = TP8_net_1;
assign PowernEn5V_net_1            = PowernEn5V_net_0;
assign PowernEn5V                  = PowernEn5V_net_1;
assign RxdUsb_net_1                = RxdUsb_net_0;
assign RxdUsb                      = RxdUsb_net_1;
//--------------------------------------------------------------------
// Slices assignments
//--------------------------------------------------------------------
assign Filterwheel_sb_0_AMBA_SLAVE_0_PADDRS9to0 = AMBA_SLAVE_0_PADDRS_net_0[9:0];
assign AMBA_SLAVE_0_PADDRS_slice_0              = AMBA_SLAVE_0_PADDRS_net_0[31:10];
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------FCCC_C0
FCCC_C0 FCCC_C0_0(
        // Inputs
        .CLK0_PAD ( CLK0_PAD ),
        // Outputs
        .GL0      ( FCCC_C0_0_GL0 ),
        .GL1      (  ),
        .LOCK     (  ) 
        );

//--------Filterwheel_sb
Filterwheel_sb Filterwheel_sb_0(
        // Inputs
        .FAB_RESET_N            ( VCC_net ), // tied to 1'b1 from definition
        .AMBA_SLAVE_0_PREADYS0  ( Main_0_RamBusAck ),
        .AMBA_SLAVE_0_PSLVERRS0 ( GND_net ),
        .DEVRST_N               ( DEVRST_N ),
        .CLK0                   ( FCCC_C0_0_GL0 ),
        .MMUART_0_RXD_F2M       ( VCC_net ),
        .AMBA_SLAVE_0_PRDATAS0  ( Main_0_RamBusDataOut ),
        // Outputs
        .POWER_ON_RESET_N       (  ),
        .INIT_DONE              ( INIT_DONE_net_0 ),
        .AMBA_SLAVE_0_PSELS0    ( Filterwheel_sb_0_AMBA_SLAVE_0_PSELS0 ),
        .AMBA_SLAVE_0_PENABLES  ( Filterwheel_sb_0_AMBA_SLAVE_0_PENABLES ),
        .AMBA_SLAVE_0_PWRITES   ( Filterwheel_sb_0_AMBA_SLAVE_0_PWRITES ),
        .FIC_0_CLK              (  ),
        .FIC_0_LOCK             (  ),
        .MSS_READY              (  ),
        .MMUART_0_TXD_M2F       (  ),
        .AMBA_SLAVE_0_PADDRS    ( AMBA_SLAVE_0_PADDRS_net_0 ),
        .AMBA_SLAVE_0_PWDATAS   ( Filterwheel_sb_0_AMBA_SLAVE_0_PWDATAS ) 
        );

//--------Main
Main Main_0(
        // Inputs
        .clk                   ( FCCC_C0_0_GL0 ),
        .rst_in                ( GND_net ),
        .PosSenseHomeA         ( PosSenseHomeA ),
        .PosSenseBit0A         ( PosSenseBit0A ),
        .PosSenseBit1A         ( PosSenseBit1A ),
        .PosSenseBit2A         ( PosSenseBit2A ),
        .PosSenseHomeB         ( PosSenseHomeB ),
        .PosSenseBit0B         ( PosSenseBit0B ),
        .PosSenseBit1B         ( PosSenseBit1B ),
        .PosSenseBit2B         ( PosSenseBit2B ),
        .RamBusnCs             ( Filterwheel_sb_0_AMBA_SLAVE_0_PSELS0 ),
        .RamBusWrnRd           ( Filterwheel_sb_0_AMBA_SLAVE_0_PWRITES ),
        .RamBusLatch           ( Filterwheel_sb_0_AMBA_SLAVE_0_PENABLES ),
        .Rxd0                  ( Rxd0 ),
        .Rxd1                  ( Rxd1 ),
        .Rxd2                  ( Rxd2 ),
        .Rxd3                  ( Rxd3 ),
        .TxdUsb                ( TxdUsb ),
        .RxdGps                ( RxdGps ),
        .PPS                   ( PPS ),
        .MisoMonAdc0           ( MisoMonAdc0 ),
        .nDrdyMonAdc0          ( nDrdyMonAdc0 ),
        .Fault1V               ( Fault1V ),
        .Fault3V               ( Fault3V ),
        .Fault5V               ( Fault5V ),
        .PowerCycd             ( PowerCycd ),
        .RamBusAddress         ( Filterwheel_sb_0_AMBA_SLAVE_0_PADDRS9to0 ),
        .RamBusDataIn          ( Filterwheel_sb_0_AMBA_SLAVE_0_PWDATAS ),
        // Outputs
        .rst_out               (  ),
        .nCsXO                 ( nCsXO_net_0 ),
        .SckXO                 ( SckXO_net_0 ),
        .MosiXO                ( MosiXO_net_0 ),
        .PosLEDEnA             ( PosLEDEnA_net_0 ),
        .PosLEDEnB             ( PosLEDEnB_net_0 ),
        .MotorDriveAPlus       ( MotorDriveAPlus_net_0 ),
        .MotorDriveAMinus      ( MotorDriveAMinus_net_0 ),
        .MotorDriveBPlus       ( MotorDriveBPlus_net_0 ),
        .MotorDriveBMinus      ( MotorDriveBMinus_net_0 ),
        .MotorDriveAPlusPrime  ( MotorDriveAPlusPrime_net_0 ),
        .MotorDriveAMinusPrime ( MotorDriveAMinusPrime_net_0 ),
        .MotorDriveBPlusPrime  ( MotorDriveBPlusPrime_net_0 ),
        .MotorDriveBMinusPrime ( MotorDriveBMinusPrime_net_0 ),
        .RamBusAck             ( Main_0_RamBusAck ),
        .Txd0                  ( Txd0_net_0 ),
        .Oe0                   ( Oe0_net_0 ),
        .Txd1                  ( Txd1_net_0 ),
        .Oe1                   ( Oe1_net_0 ),
        .Txd2                  ( Txd2_net_0 ),
        .Oe2                   ( Oe2_net_0 ),
        .Txd3                  ( Txd3_net_0 ),
        .Oe3                   ( Oe3_net_0 ),
        .RxdUsb                ( RxdUsb_net_0 ),
        .CtsUsb                ( CtsUsb_net_0 ),
        .TxdGps                ( TxdGps_net_0 ),
        .nCsMonAdc0            ( nCsMonAdc0_net_0 ),
        .SckMonAdc0            ( SckMonAdc0_net_0 ),
        .MosiMonAdc0           ( MosiMonAdc0_net_0 ),
        .nFaultClr1V           ( nFaultClr1V_net_0 ),
        .nFaultClr3V           ( nFaultClr3V_net_0 ),
        .nFaultClr5V           ( nFaultClr5V_net_0 ),
        .nPowerCycClr          ( nPowerCycClr_net_0 ),
        .PowernEn5V            ( PowernEn5V_net_0 ),
        .PowerSync             ( PowerSync_net_0 ),
        .LedR                  ( LedR_net_0 ),
        .LedG                  ( LedG_net_0 ),
        .LedB                  ( LedB_net_0 ),
        .TP1                   ( TP1_net_0 ),
        .TP2                   ( TP2_net_0 ),
        .TP3                   ( TP3_net_0 ),
        .TP4                   ( TP4_net_0 ),
        .TP5                   ( TP5_net_0 ),
        .TP6                   ( TP6_net_0 ),
        .TP7                   ( TP7_net_0 ),
        .TP8                   ( TP8_net_0 ),
        .RamBusDataOut         ( Main_0_RamBusDataOut ),
        // Inouts
        .Ux1SelJmp             ( Ux1SelJmp ) 
        );


endmodule
