//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Tue Jul 30 11:36:27 2024
// Version: 2023.2 2023.2.0.10
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

//////////////////////////////////////////////////////////////////////
// Component Description (Tcl) 
//////////////////////////////////////////////////////////////////////
/*
# Exporting Component Description of CORESYSSERVICES_C0 to TCL
# Family: SmartFusion2
# Part Number: M2S010-TQ144I
# Create and Configure the core component CORESYSSERVICES_C0
create_and_configure_core -core_vlnv {Actel:DirectCore:CORESYSSERVICES:3.2.102} -component_name {CORESYSSERVICES_C0} -params {\
"CHRESPKEYADDR:0x20000000"  \
"CHRESPKEYADDR_HEX_RANGE:32"  \
"CHRESPPTR:0x20000000"  \
"CHRESPPTR_HEX_RANGE:32"  \
"CHRESPSERVICE:false"  \
"CRYPTOAES128DATAPTR:0x20000000"  \
"CRYPTOAES128DATAPTR_HEX_RANGE:32"  \
"CRYPTOAES128SERVICE:false"  \
"CRYPTOAES256DATAPTR:0x20000000"  \
"CRYPTOAES256DATAPTR_HEX_RANGE:32"  \
"CRYPTOAES256SERVICE:false"  \
"CRYPTODATAINPPTR:0x20000000"  \
"CRYPTODATAINPPTR_HEX_RANGE:32"  \
"CRYPTODSTADPTR:0x20000000"  \
"CRYPTODSTADPTR_HEX_RANGE:32"  \
"CRYPTOHMACDATAPTR:0x20000000"  \
"CRYPTOHMACDATAPTR_HEX_RANGE:32"  \
"CRYPTOHMACSERVICE:false"  \
"CRYPTORSLTPTR:0x20000000"  \
"CRYPTORSLTPTR_HEX_RANGE:32"  \
"CRYPTOSHA256DATAPTR:0x20000000"  \
"CRYPTOSHA256DATAPTR_HEX_RANGE:32"  \
"CRYPTOSHA256SERVICE:false"  \
"CRYPTOSRCADPTR:0x20000000"  \
"CRYPTOSRCADPTR_HEX_RANGE:32"  \
"DCSERVICE:false"  \
"DESIGNVERPTR:0x20000000"  \
"DESIGNVERPTR_HEX_RANGE:32"  \
"DEVICECERTPTR:0x20000000"  \
"DEVICECERTPTR_HEX_RANGE:32"  \
"DSNPTR:0x20000000"  \
"DSNPTR_HEX_RANGE:32"  \
"ECCPADDDESC:0x20000000"  \
"ECCPADDDESC_HEX_RANGE:32"  \
"ECCPADDPPTR:0x20000000"  \
"ECCPADDPPTR_HEX_RANGE:32"  \
"ECCPADDQPTR:0x20000000"  \
"ECCPADDQPTR_HEX_RANGE:32"  \
"ECCPADDRPTR:0x20000000"  \
"ECCPADDRPTR_HEX_RANGE:32"  \
"ECCPMULTDESC:0x20000000"  \
"ECCPMULTDESC_HEX_RANGE:32"  \
"ECCPMULTDPTR:0x20000000"  \
"ECCPMULTDPTR_HEX_RANGE:32"  \
"ECCPMULTPPTR:0x20000000"  \
"ECCPMULTPPTR_HEX_RANGE:32"  \
"ECCPMULTQPTR:0x20000000"  \
"ECCPMULTQPTR_HEX_RANGE:32"  \
"ECCPOINTADDSERVICE:false"  \
"ECCPOINTMULTSERVICE:false"  \
"FFSERVICE:false"  \
"KEYTREEDATAPTR:0x20000000"  \
"KEYTREEDATAPTR_HEX_RANGE:32"  \
"KEYTREESERVICE:false"  \
"NRBGADDINPPTR:0x20000000"  \
"NRBGADDINPPTR_HEX_RANGE:32"  \
"NRBGGENPTR:0x20000000"  \
"NRBGGENPTR_HEX_RANGE:32"  \
"NRBGINSTPTR:0x20000000"  \
"NRBGINSTPTR_HEX_RANGE:32"  \
"NRBGPERSTRINGPTR:0x20000000"  \
"NRBGPERSTRINGPTR_HEX_RANGE:32"  \
"NRBGREQDATAPTR:0x20000000"  \
"NRBGREQDATAPTR_HEX_RANGE:32"  \
"NRBGRESEEDPTR:0x20000000"  \
"NRBGRESEEDPTR_HEX_RANGE:32"  \
"NRBGSERVICE:false"  \
"PORDSERVICE:false"  \
"PROGIAPSERVICE:false"  \
"PROGNVMDISERVICE:false"  \
"PUFPUBLICKEYADDR:0x20000000"  \
"PUFPUBLICKEYADDR_HEX_RANGE:32"  \
"PUFPUBLICKEYPTR:0x20000000"  \
"PUFPUBLICKEYPTR_HEX_RANGE:32"  \
"PUFSEEDADDR:0x20000000"  \
"PUFSEEDADDR_HEX_RANGE:32"  \
"PUFSEEDPTR:0x20000000"  \
"PUFSEEDPTR_HEX_RANGE:32"  \
"PUFSERVICE:false"  \
"PUFUSERACPTR:0x20000000"  \
"PUFUSERACPTR_HEX_RANGE:32"  \
"PUFUSERKCPTR:0x20000000"  \
"PUFUSERKCPTR_HEX_RANGE:32"  \
"PUFUSERKEYPTR:0x20000000"  \
"PUFUSERKEYPTR_HEX_RANGE:32"  \
"SECDCSERVICE:false"  \
"SECONDECCCERTPTR:0x20000000"  \
"SECONDECCCERTPTR_HEX_RANGE:32"  \
"SNSERVICE:true"  \
"TAMPERCONTROLSERVICE:false"  \
"TAMPERDETECTSERVICE:false"  \
"UCSERVICE:true"  \
"UDVSERVICE:true"  \
"USERCODEPTR:0x20000000"  \
"USERCODEPTR_HEX_RANGE:32"  \
"ZERSERVICE:false"   }
# Exporting Component Description of CORESYSSERVICES_C0 to TCL done
*/

// CORESYSSERVICES_C0
module CORESYSSERVICES_C0(
    // Inputs
    CLK,
    COMM_BLK_INT,
    HCLK,
    HRDATA,
    HREADY,
    HRESETN,
    HRESP,
    RESETN,
    SERV_CMDBYTE_REQ,
    SERV_DATA_W,
    SERV_DATA_WVALID,
    SERV_ENABLE_REQ,
    // Outputs
    HADDR,
    HBURST,
    HSEL,
    HSIZE,
    HTRANS,
    HWDATA,
    HWRITE,
    SERV_BUSY,
    SERV_CMD_ERROR,
    SERV_DATA_R,
    SERV_DATA_RVALID,
    SERV_DATA_WRDY,
    SERV_STATUS_RESP,
    SERV_STATUS_VALID
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input         CLK;
input         COMM_BLK_INT;
input         HCLK;
input  [31:0] HRDATA;
input         HREADY;
input         HRESETN;
input         HRESP;
input         RESETN;
input  [7:0]  SERV_CMDBYTE_REQ;
input  [31:0] SERV_DATA_W;
input         SERV_DATA_WVALID;
input         SERV_ENABLE_REQ;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output [31:0] HADDR;
output [2:0]  HBURST;
output        HSEL;
output [2:0]  HSIZE;
output [1:0]  HTRANS;
output [31:0] HWDATA;
output        HWRITE;
output        SERV_BUSY;
output        SERV_CMD_ERROR;
output [31:0] SERV_DATA_R;
output        SERV_DATA_RVALID;
output        SERV_DATA_WRDY;
output [7:0]  SERV_STATUS_RESP;
output        SERV_STATUS_VALID;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire   [31:0] AHBL_MASTER_HADDR;
wire   [2:0]  AHBL_MASTER_HBURST;
wire   [31:0] HRDATA;
wire          HREADY;
wire          HRESP;
wire   [2:0]  AHBL_MASTER_HSIZE;
wire   [1:0]  AHBL_MASTER_HTRANS;
wire   [31:0] AHBL_MASTER_HWDATA;
wire          AHBL_MASTER_HWRITE;
wire          CLK;
wire          COMM_BLK_INT;
wire          HCLK;
wire          HRESETN;
wire          HSEL_net_0;
wire          RESETN;
wire          SERV_BUSY_net_0;
wire          SERV_CMD_ERROR_net_0;
wire   [7:0]  SERV_CMDBYTE_REQ;
wire   [31:0] SERV_DATA_R_net_0;
wire          SERV_DATA_RVALID_net_0;
wire   [31:0] SERV_DATA_W;
wire          SERV_DATA_WRDY_net_0;
wire          SERV_DATA_WVALID;
wire          SERV_ENABLE_REQ;
wire   [7:0]  SERV_STATUS_RESP_net_0;
wire          SERV_STATUS_VALID_net_0;
wire          HSEL_net_1;
wire          SERV_BUSY_net_1;
wire          SERV_STATUS_VALID_net_1;
wire   [7:0]  SERV_STATUS_RESP_net_1;
wire          SERV_DATA_WRDY_net_1;
wire          SERV_DATA_RVALID_net_1;
wire   [31:0] SERV_DATA_R_net_1;
wire          SERV_CMD_ERROR_net_1;
wire   [31:0] AHBL_MASTER_HADDR_net_0;
wire   [1:0]  AHBL_MASTER_HTRANS_net_0;
wire          AHBL_MASTER_HWRITE_net_0;
wire   [2:0]  AHBL_MASTER_HSIZE_net_0;
wire   [2:0]  AHBL_MASTER_HBURST_net_0;
wire   [31:0] AHBL_MASTER_HWDATA_net_0;
//--------------------------------------------------------------------
// TiedOff Nets
//--------------------------------------------------------------------
wire   [5:0]  SERV_OPTIONS_MODE_const_net_0;
wire   [255:0]SERV_CRYPTO_KEY_const_net_0;
wire   [127:0]SERV_CRYPTO_IV_const_net_0;
wire   [7:0]  SERV_CRYPTO_MODE_const_net_0;
wire   [15:0] SERV_CRYPTO_NBLOCKS_const_net_0;
wire   [31:0] SERV_CRYPTO_LENGTH_const_net_0;
wire   [7:0]  SERV_NRBG_LENGTH_const_net_0;
wire   [7:0]  SERV_NRBG_HANDLE_const_net_0;
wire   [7:0]  SERV_NRBG_ADDLENGTH_const_net_0;
wire   [7:0]  SERV_NRBG_PRREQ_const_net_0;
wire   [255:0]SERV_DPA_KEY_const_net_0;
wire   [7:0]  SERV_DPA_OPTYPE_const_net_0;
wire   [127:0]SERV_DPA_PATH_const_net_0;
wire   [7:0]  SERV_PUF_SUBCMD_const_net_0;
wire   [7:0]  SERV_PUF_INKEYNUM_const_net_0;
wire   [7:0]  SERV_PUF_KEYSIZE_const_net_0;
wire   [31:0] SERV_PUFUSERKEYADDR_const_net_0;
wire   [31:0] SERV_USEREXTRINSICKEYADDR_const_net_0;
wire   [31:0] SERV_SPIADDR_const_net_0;
//--------------------------------------------------------------------
// Constant assignments
//--------------------------------------------------------------------
assign SERV_OPTIONS_MODE_const_net_0         = 6'h00;
assign SERV_CRYPTO_KEY_const_net_0           = 256'h0000000000000000000000000000000000000000000000000000000000000000;
assign SERV_CRYPTO_IV_const_net_0            = 128'h00000000000000000000000000000000;
assign SERV_CRYPTO_MODE_const_net_0          = 8'h00;
assign SERV_CRYPTO_NBLOCKS_const_net_0       = 16'h0000;
assign SERV_CRYPTO_LENGTH_const_net_0        = 32'h00000000;
assign SERV_NRBG_LENGTH_const_net_0          = 8'h00;
assign SERV_NRBG_HANDLE_const_net_0          = 8'h00;
assign SERV_NRBG_ADDLENGTH_const_net_0       = 8'h00;
assign SERV_NRBG_PRREQ_const_net_0           = 8'h00;
assign SERV_DPA_KEY_const_net_0              = 256'h0000000000000000000000000000000000000000000000000000000000000000;
assign SERV_DPA_OPTYPE_const_net_0           = 8'h00;
assign SERV_DPA_PATH_const_net_0             = 128'h00000000000000000000000000000000;
assign SERV_PUF_SUBCMD_const_net_0           = 8'h00;
assign SERV_PUF_INKEYNUM_const_net_0         = 8'h00;
assign SERV_PUF_KEYSIZE_const_net_0          = 8'h00;
assign SERV_PUFUSERKEYADDR_const_net_0       = 32'h00000000;
assign SERV_USEREXTRINSICKEYADDR_const_net_0 = 32'h00000000;
assign SERV_SPIADDR_const_net_0              = 32'h00000000;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign HSEL_net_1               = HSEL_net_0;
assign HSEL                     = HSEL_net_1;
assign SERV_BUSY_net_1          = SERV_BUSY_net_0;
assign SERV_BUSY                = SERV_BUSY_net_1;
assign SERV_STATUS_VALID_net_1  = SERV_STATUS_VALID_net_0;
assign SERV_STATUS_VALID        = SERV_STATUS_VALID_net_1;
assign SERV_STATUS_RESP_net_1   = SERV_STATUS_RESP_net_0;
assign SERV_STATUS_RESP[7:0]    = SERV_STATUS_RESP_net_1;
assign SERV_DATA_WRDY_net_1     = SERV_DATA_WRDY_net_0;
assign SERV_DATA_WRDY           = SERV_DATA_WRDY_net_1;
assign SERV_DATA_RVALID_net_1   = SERV_DATA_RVALID_net_0;
assign SERV_DATA_RVALID         = SERV_DATA_RVALID_net_1;
assign SERV_DATA_R_net_1        = SERV_DATA_R_net_0;
assign SERV_DATA_R[31:0]        = SERV_DATA_R_net_1;
assign SERV_CMD_ERROR_net_1     = SERV_CMD_ERROR_net_0;
assign SERV_CMD_ERROR           = SERV_CMD_ERROR_net_1;
assign AHBL_MASTER_HADDR_net_0  = AHBL_MASTER_HADDR;
assign HADDR[31:0]              = AHBL_MASTER_HADDR_net_0;
assign AHBL_MASTER_HTRANS_net_0 = AHBL_MASTER_HTRANS;
assign HTRANS[1:0]              = AHBL_MASTER_HTRANS_net_0;
assign AHBL_MASTER_HWRITE_net_0 = AHBL_MASTER_HWRITE;
assign HWRITE                   = AHBL_MASTER_HWRITE_net_0;
assign AHBL_MASTER_HSIZE_net_0  = AHBL_MASTER_HSIZE;
assign HSIZE[2:0]               = AHBL_MASTER_HSIZE_net_0;
assign AHBL_MASTER_HBURST_net_0 = AHBL_MASTER_HBURST;
assign HBURST[2:0]              = AHBL_MASTER_HBURST_net_0;
assign AHBL_MASTER_HWDATA_net_0 = AHBL_MASTER_HWDATA;
assign HWDATA[31:0]             = AHBL_MASTER_HWDATA_net_0;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------CORESYSSERVICES_C0_CORESYSSERVICES_C0_0_CORESYSSERVICES   -   Actel:DirectCore:CORESYSSERVICES:3.2.102
CORESYSSERVICES_C0_CORESYSSERVICES_C0_0_CORESYSSERVICES #( 
        .CHRESPKEYADDR        ( 'h20000000 ),
        .CHRESPPTR            ( 'h20000000 ),
        .CHRESPSERVICE        ( 0 ),
        .CRYPTOAES128DATAPTR  ( 'h20000000 ),
        .CRYPTOAES128SERVICE  ( 0 ),
        .CRYPTOAES256DATAPTR  ( 'h20000000 ),
        .CRYPTOAES256SERVICE  ( 0 ),
        .CRYPTODATAINPPTR     ( 'h20000000 ),
        .CRYPTODSTADPTR       ( 'h20000000 ),
        .CRYPTOHMACDATAPTR    ( 'h20000000 ),
        .CRYPTOHMACSERVICE    ( 0 ),
        .CRYPTORSLTPTR        ( 'h20000000 ),
        .CRYPTOSHA256DATAPTR  ( 'h20000000 ),
        .CRYPTOSHA256SERVICE  ( 0 ),
        .CRYPTOSRCADPTR       ( 'h20000000 ),
        .DCSERVICE            ( 0 ),
        .DESIGNVERPTR         ( 'h20000000 ),
        .DEVICECERTPTR        ( 'h20000000 ),
        .DSNPTR               ( 'h20000000 ),
        .ECCPADDDESC          ( 'h20000000 ),
        .ECCPADDPPTR          ( 'h20000000 ),
        .ECCPADDQPTR          ( 'h20000000 ),
        .ECCPADDRPTR          ( 'h20000000 ),
        .ECCPMULTDESC         ( 'h20000000 ),
        .ECCPMULTDPTR         ( 'h20000000 ),
        .ECCPMULTPPTR         ( 'h20000000 ),
        .ECCPMULTQPTR         ( 'h20000000 ),
        .ECCPOINTADDSERVICE   ( 0 ),
        .ECCPOINTMULTSERVICE  ( 0 ),
        .FFSERVICE            ( 0 ),
        .KEYTREEDATAPTR       ( 'h20000000 ),
        .KEYTREESERVICE       ( 0 ),
        .NRBGADDINPPTR        ( 'h20000000 ),
        .NRBGGENPTR           ( 'h20000000 ),
        .NRBGINSTPTR          ( 'h20000000 ),
        .NRBGPERSTRINGPTR     ( 'h20000000 ),
        .NRBGREQDATAPTR       ( 'h20000000 ),
        .NRBGRESEEDPTR        ( 'h20000000 ),
        .NRBGSERVICE          ( 0 ),
        .PORDSERVICE          ( 0 ),
        .PROGIAPSERVICE       ( 0 ),
        .PROGNVMDISERVICE     ( 0 ),
        .PUFPUBLICKEYADDR     ( 'h20000000 ),
        .PUFPUBLICKEYPTR      ( 'h20000000 ),
        .PUFSEEDADDR          ( 'h20000000 ),
        .PUFSEEDPTR           ( 'h20000000 ),
        .PUFSERVICE           ( 0 ),
        .PUFUSERACPTR         ( 'h20000000 ),
        .PUFUSERKCPTR         ( 'h20000000 ),
        .PUFUSERKEYPTR        ( 'h20000000 ),
        .SECDCSERVICE         ( 0 ),
        .SECONDECCCERTPTR     ( 'h20000000 ),
        .SNSERVICE            ( 1 ),
        .TAMPERCONTROLSERVICE ( 0 ),
        .TAMPERDETECTSERVICE  ( 0 ),
        .UCSERVICE            ( 1 ),
        .UDVSERVICE           ( 1 ),
        .USERCODEPTR          ( 'h20000000 ),
        .ZERSERVICE           ( 0 ) )
CORESYSSERVICES_C0_0(
        // Inputs
        .CLK                       ( CLK ),
        .RESETN                    ( RESETN ),
        .HCLK                      ( HCLK ),
        .HRESETN                   ( HRESETN ),
        .HRESP                     ( HRESP ),
        .HREADY                    ( HREADY ),
        .HRDATA                    ( HRDATA ),
        .SERV_ENABLE_REQ           ( SERV_ENABLE_REQ ),
        .SERV_CMDBYTE_REQ          ( SERV_CMDBYTE_REQ ),
        .SERV_OPTIONS_MODE         ( SERV_OPTIONS_MODE_const_net_0 ), // tied to 6'h00 from definition
        .SERV_DATA_WVALID          ( SERV_DATA_WVALID ),
        .SERV_DATA_W               ( SERV_DATA_W ),
        .COMM_BLK_INT              ( COMM_BLK_INT ),
        .SERV_CRYPTO_KEY           ( SERV_CRYPTO_KEY_const_net_0 ), // tied to 256'h0000000000000000000000000000000000000000000000000000000000000000 from definition
        .SERV_CRYPTO_IV            ( SERV_CRYPTO_IV_const_net_0 ), // tied to 128'h00000000000000000000000000000000 from definition
        .SERV_CRYPTO_MODE          ( SERV_CRYPTO_MODE_const_net_0 ), // tied to 8'h00 from definition
        .SERV_CRYPTO_NBLOCKS       ( SERV_CRYPTO_NBLOCKS_const_net_0 ), // tied to 16'h0000 from definition
        .SERV_CRYPTO_LENGTH        ( SERV_CRYPTO_LENGTH_const_net_0 ), // tied to 32'h00000000 from definition
        .SERV_NRBG_LENGTH          ( SERV_NRBG_LENGTH_const_net_0 ), // tied to 8'h00 from definition
        .SERV_NRBG_HANDLE          ( SERV_NRBG_HANDLE_const_net_0 ), // tied to 8'h00 from definition
        .SERV_NRBG_ADDLENGTH       ( SERV_NRBG_ADDLENGTH_const_net_0 ), // tied to 8'h00 from definition
        .SERV_NRBG_PRREQ           ( SERV_NRBG_PRREQ_const_net_0 ), // tied to 8'h00 from definition
        .SERV_DPA_KEY              ( SERV_DPA_KEY_const_net_0 ), // tied to 256'h0000000000000000000000000000000000000000000000000000000000000000 from definition
        .SERV_DPA_OPTYPE           ( SERV_DPA_OPTYPE_const_net_0 ), // tied to 8'h00 from definition
        .SERV_DPA_PATH             ( SERV_DPA_PATH_const_net_0 ), // tied to 128'h00000000000000000000000000000000 from definition
        .SERV_PUF_SUBCMD           ( SERV_PUF_SUBCMD_const_net_0 ), // tied to 8'h00 from definition
        .SERV_PUF_INKEYNUM         ( SERV_PUF_INKEYNUM_const_net_0 ), // tied to 8'h00 from definition
        .SERV_PUF_KEYSIZE          ( SERV_PUF_KEYSIZE_const_net_0 ), // tied to 8'h00 from definition
        .SERV_PUFUSERKEYADDR       ( SERV_PUFUSERKEYADDR_const_net_0 ), // tied to 32'h00000000 from definition
        .SERV_USEREXTRINSICKEYADDR ( SERV_USEREXTRINSICKEYADDR_const_net_0 ), // tied to 32'h00000000 from definition
        .SERV_SPIADDR              ( SERV_SPIADDR_const_net_0 ), // tied to 32'h00000000 from definition
        // Outputs
        .HSEL                      ( HSEL_net_0 ),
        .HADDR                     ( AHBL_MASTER_HADDR ),
        .HWRITE                    ( AHBL_MASTER_HWRITE ),
        .HWDATA                    ( AHBL_MASTER_HWDATA ),
        .HTRANS                    ( AHBL_MASTER_HTRANS ),
        .HBURST                    ( AHBL_MASTER_HBURST ),
        .HSIZE                     ( AHBL_MASTER_HSIZE ),
        .SERV_BUSY                 ( SERV_BUSY_net_0 ),
        .SERV_STATUS_VALID         ( SERV_STATUS_VALID_net_0 ),
        .SERV_STATUS_RESP          ( SERV_STATUS_RESP_net_0 ),
        .SERV_DATA_WRDY            ( SERV_DATA_WRDY_net_0 ),
        .SERV_DATA_RVALID          ( SERV_DATA_RVALID_net_0 ),
        .SERV_DATA_R               ( SERV_DATA_R_net_0 ),
        .SERV_CMD_ERROR            ( SERV_CMD_ERROR_net_0 ),
        .SERV_TAMPER_MSGVALID      (  ),
        .SERV_TAMPER_MSG           (  ) 
        );


endmodule
