// ****************************************************************************/    
// Actel Corporation Proprietary and Confidential    
// Copyright 2010 Actel Corporation.  All rights reserved.    
//    
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN    
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED    
// IN ADVANCE IN WRITING.    
//    
// Description: CoreSysServices - Top level RTL    
//    
// Revision Information:    
// Date            Description    
// ----            -----------------------------------------    
// 16May13         Inital. Ports and Parameters declaration    
//    
// SVN Revision Information:    
// SVN $Revision: 11146 $    
// SVN $Date: 2009-11-21 11:44:53 -0800 (Sat, 21 Nov 2009) $    
//    
// Resolved SARs    
// SAR      Date     Who   Description    
//     
// Notes:    
// 1.     
//    
// ****************************************************************************/    
`timescale 1 ns/10 ps    
 
 
module CORESYSSERVICES_C0_CORESYSSERVICES_C0_0_CORESYSSERVICES (    
                                       CLK,    
                                       RESETN,    
                                       // AHBL Master IF    
                                       HCLK,    
                                       HRESETN,    
                                       HSEL,    
                                       HADDR,    
                                       HWRITE,    
                                       HWDATA,    
                                       HTRANS,    
                                       HBURST,    
                                       HSIZE,    
                                       HRESP,    
                                       HREADY,    
                                       HRDATA,    
                                       // User IF    
                                       SERV_BUSY,    
                                       SERV_ENABLE_REQ,    
                                       SERV_CMDBYTE_REQ,    
                                       SERV_STATUS_VALID,
                                       SERV_STATUS_RESP,    
                                       SERV_TAMPER_MSGVALID,
                                       SERV_TAMPER_MSG,

                                       SERV_CMD_ERROR,         // v3.0
                                       SERV_OPTIONS_MODE,    

                                       SERV_DATA_WVALID,    
                                       SERV_DATA_W,
                                       SERV_DATA_WRDY,
                                       SERV_DATA_RVALID,    
                                       SERV_DATA_R,    
                                       
                                       // Interrupts    
                                       COMM_BLK_INT,
                                       // CRYPTO IF
                                       SERV_CRYPTO_KEY,
                                       SERV_CRYPTO_IV,
                                       SERV_CRYPTO_MODE,
                                       SERV_CRYPTO_NBLOCKS,
                                       SERV_CRYPTO_LENGTH,
                                       // NRBG IF
                                       SERV_NRBG_LENGTH,
                                       SERV_NRBG_HANDLE,
                                       SERV_NRBG_ADDLENGTH,
                                       SERV_NRBG_PRREQ,
                                       // DPA IF
                                       SERV_DPA_KEY,
                                       SERV_DPA_OPTYPE,
                                       SERV_DPA_PATH,
                                       // PUF IF
                                       SERV_PUF_SUBCMD,
                                       SERV_PUF_INKEYNUM, 
                                       SERV_PUFUSERKEYADDR, 
                                       SERV_USEREXTRINSICKEYADDR, 
                                       SERV_PUF_KEYSIZE,
				       SERV_SPIADDR        
                                       );    
   
   //------------------------------------------------------------------------------    
   // Parameter declarations    
   //------------------------------------------------------------------------------    
//   parameter FAMILY                 = 19;

   parameter SNSERVICE              = 0;    
   parameter DSNPTR                 = 0;
   parameter UCSERVICE              = 0;    
   parameter USERCODEPTR            = 0;
   parameter DCSERVICE              = 0;    
   parameter DEVICECERTPTR          = 0;
   parameter SECDCSERVICE           = 0;     
   parameter SECONDECCCERTPTR       = 0;    
   parameter UDVSERVICE             = 0;    
   parameter DESIGNVERPTR           = 0;

   parameter CRYPTOAES128SERVICE    = 0;    
   parameter CRYPTOAES128DATAPTR    = 0;
   parameter CRYPTOAES256SERVICE    = 0;
   parameter CRYPTOAES256DATAPTR    = 0;
   parameter CRYPTOSRCADPTR         = 0;
   parameter CRYPTODSTADPTR         = 0;
   parameter CRYPTOSHA256SERVICE    = 0;
   parameter CRYPTOSHA256DATAPTR    = 0;
   parameter CRYPTORSLTPTR          = 0;
   parameter CRYPTODATAINPPTR       = 0;
   parameter CRYPTOHMACSERVICE      = 0;
   parameter CRYPTOHMACDATAPTR      = 0;

   parameter FFSERVICE              = 0;    
 
   parameter KEYTREESERVICE         = 0;
   parameter KEYTREEDATAPTR         = 0;
   parameter CHRESPSERVICE          = 0;
   parameter CHRESPPTR              = 0;
   parameter CHRESPKEYADDR          = 0;
 
   parameter NRBGSERVICE            = 0;    
   parameter NRBGINSTPTR            = 0;
   parameter NRBGPERSTRINGPTR       = 0;
   parameter NRBGGENPTR             = 0;
   parameter NRBGREQDATAPTR         = 0;
   parameter NRBGRESEEDPTR          = 0;
   parameter NRBGADDINPPTR          = 0;
 
   parameter ZERSERVICE             = 0;    
   parameter PROGIAPSERVICE         = 0;
   parameter PROGNVMDISERVICE       = 0;    
   parameter PORDSERVICE            = 0;
    
   parameter ECCPOINTMULTSERVICE    = 0;     
   parameter ECCPMULTDESC           = 0;
   parameter ECCPMULTPPTR           = 0;
   parameter ECCPMULTDPTR           = 0;
   parameter ECCPMULTQPTR           = 0;

   parameter ECCPOINTADDSERVICE     = 0;    
   parameter ECCPADDDESC            = 0;    
   parameter ECCPADDPPTR            = 0;            
   parameter ECCPADDQPTR            = 0;
   parameter ECCPADDRPTR            = 0;

   parameter TAMPERDETECTSERVICE    = 0;    
   parameter TAMPERCONTROLSERVICE   = 0;    

   parameter PUFSERVICE             = 0;    
   parameter PUFUSERACPTR           = 0;   
   parameter PUFUSERKCPTR           = 0;   
   parameter PUFUSERKEYPTR          = 0;   
   parameter PUFPUBLICKEYPTR        = 0;   
   parameter PUFPUBLICKEYADDR       = 0;   
   parameter PUFSEEDPTR             = 0;   
   parameter PUFSEEDADDR            = 0;   
    
   localparam AHB_AWIDTH            = 32;    
   localparam AHB_DWIDTH            = 32;
   
    
   //------------------------------------------------------------------------------    
   // Port declarations    
   //------------------------------------------------------------------------------    
    
   // -----------    
   // Inputs    
   // -----------    
   input      CLK;    
   input      RESETN;
   // User IF    
   input                    SERV_ENABLE_REQ;    
   input [7:0]              SERV_CMDBYTE_REQ;    
   input [5:0]              SERV_OPTIONS_MODE;    
   input                    SERV_DATA_WVALID;
   input [AHB_DWIDTH - 1:0] SERV_DATA_W;    
   // AHBL Master IF    
   input                    HCLK;    
   input                    HRESETN;    
   input                    HREADY;    
   input [AHB_DWIDTH - 1:0] HRDATA;    
   input                    HRESP; 
   // Interrupts    
   input                    COMM_BLK_INT;
   
   // CRYPTO IF
   input [255:0]            SERV_CRYPTO_KEY;
   input [127:0]            SERV_CRYPTO_IV;
   input [7:0]              SERV_CRYPTO_MODE;
   input [15:0]             SERV_CRYPTO_NBLOCKS;
   input [31:0]             SERV_CRYPTO_LENGTH;
   // NRBG IF               
   input [7:0]              SERV_NRBG_LENGTH;
   input [7:0]              SERV_NRBG_HANDLE;
   input [7:0]              SERV_NRBG_ADDLENGTH;
   input [7:0]              SERV_NRBG_PRREQ;
   // DPA IF
   input [255:0]            SERV_DPA_KEY;
   input [7:0]              SERV_DPA_OPTYPE;
   input [127:0]            SERV_DPA_PATH;
   // PUF IF
   input [7:0]              SERV_PUF_SUBCMD;   
   input [7:0]              SERV_PUF_INKEYNUM;   
   input [7:0]              SERV_PUF_KEYSIZE;   
   input [31:0]             SERV_PUFUSERKEYADDR;
   input [31:0]             SERV_USEREXTRINSICKEYADDR;
   input [31:0]             SERV_SPIADDR;  
       
   // -----------   
   // Outputs   
   // -----------   
   
   // AHBL Master IF    
   output                    HSEL;    
   output [AHB_AWIDTH - 1:0] HADDR;    
   output                    HWRITE;    
   output [AHB_DWIDTH - 1:0] HWDATA;    
   output [1:0]              HTRANS;    
   output [2:0]              HBURST;    
   output [2:0]              HSIZE;    
   // User IF    
   output                    SERV_BUSY;    
   output                    SERV_DATA_WRDY;    
   output                    SERV_DATA_RVALID;    
   output [AHB_DWIDTH - 1:0] SERV_DATA_R;   

   output                    SERV_STATUS_VALID;
   output [7:0]              SERV_STATUS_RESP;    
   output                    SERV_TAMPER_MSGVALID;
   output [7:0]              SERV_TAMPER_MSG;
   
   output                    SERV_CMD_ERROR;   
   
   // -----------------   
   // Internal signals   
   // -----------------   
   wire [AHB_DWIDTH - 1:0]   mfhrdata_o;    
   wire                      mfhresp_o;
   wire                      mfhready_o;
   wire                      fcbusreq_o;  
   wire                      fmhwrite_o;  
   wire [2:0]                fmhsize_o;  
   wire [1:0]                fmhtrans_o;  
   wire [2:0]                fmhburst_o;  
   wire [31:0]               fmhaddr_o;  
   wire [31:0]               fmhwdata_o;  
   
   wire                      fctrans_done_o;  
   wire [31:0]               fcdataout_o;
   
   wire                      cfwr_req_o;
   wire                      cfrd_resp_o;
   wire [15:0]               cfburst_len_o;
   wire [31:0]               cfdatain_o;   
   wire [31:0]               cfsrc_addr_o;   
   wire [31:0]               cfdst_addr_o;
   
   // User IF   
   wire [7:0]                ustatus_resp_o;   
   wire                      ubusy_o;
   wire                      udata_en_o;
   wire                      udata_valid_o;
   wire [AHB_DWIDTH - 1:0]   udata_r_o;

   // To Command Decoder IF block
   wire                      uctrig_o;
   wire [7:0]                uclatchcmd_o;
   wire [5:0]                uclatchoptions_o;   
   wire                      uclatchpord_o;   

   // Crypto IF
   wire [255:0]              uccrypto_key_o;
   wire [127:0]              uccrypto_iv_o;
   wire [7:0]                uccrypto_mode_o;
   wire [1:0]                uccrypto_opmode_o;
   wire [15:0]               uccrypto_nblocks_o;
   wire [31:0]               uccrypto_length_o;
   
   // NRBG IF
   wire [7:0]                ucnrbg_length_o;
   wire [7:0]                ucnrbg_handle_o;
   wire [7:0]                ucnrbg_addlength_o;
   wire [7:0]                ucnrbg_prreq_o;    
   
   // DPA Keytree IF
   wire [255:0]              ucdpa_key_o;
   wire [7:0]                ucdpa_optype_o;
   wire [127:0]              ucdpa_path_o;  

   // PUF IF
   wire [7:0]                ucpuf_subcmd_o;
   wire [7:0]                ucpuf_inkeynum;
   wire [7:0]                ucpuf_keysize_o;

   wire                      ucdata_wvalid_o;
   wire [31:0]               ucdata_w_o;
   wire                      cudata_wrdy_o;
   wire                      cudata_wen_o;   
   wire                      cudata_rvalid_o;   
   wire [AHB_DWIDTH - 1:0]   cudata_r_o;  
   wire                      uccommblk_int_o;
   wire                      cubusy_o;
   wire                      fcpop_o;
   wire                      fcpush_o;
   
   wire [31:0]               cfburst_len_wr_o;
   wire [31:0]               cfburst_len_rd_o;
   wire [31:0]               ucpuf_userkeyaddr;
   wire [31:0]               ucpuf_userextrkeyaddr;
   wire [7:0]                cutamper_msg;  
   wire [31:0]               ucspiaddr;
  
   
   //////////////////////////////////////////////////////////////////////////////   
   //                           Start-of-Code                                  //   
   //////////////////////////////////////////////////////////////////////////////   

   //-----------------
   // User IF Instance
   //-----------------
   CoreSysServices_UserIF  #(
             .SNSERVICE           (SNSERVICE),
             .DSNPTR              (DSNPTR),
             .UCSERVICE           (UCSERVICE),
             .USERCODEPTR         (USERCODEPTR),
             .DCSERVICE           (DCSERVICE),  
             .DEVICECERTPTR       (DEVICECERTPTR),
             .SECDCSERVICE        (SECDCSERVICE),  
             .SECONDECCCERTPTR    (SECONDECCCERTPTR),
             .UDVSERVICE          (UDVSERVICE),   
             .DESIGNVERPTR        (DESIGNVERPTR),             
             .CRYPTOAES128SERVICE (CRYPTOAES128SERVICE),
             .CRYPTOAES128DATAPTR (CRYPTOAES128DATAPTR),
             .CRYPTOAES256SERVICE (CRYPTOAES256SERVICE),
             .CRYPTOAES256DATAPTR (CRYPTOAES256DATAPTR),
             .CRYPTOSHA256SERVICE (CRYPTOSHA256SERVICE),
             .CRYPTOSHA256DATAPTR (CRYPTOSHA256DATAPTR),
             .CRYPTORSLTPTR       (CRYPTORSLTPTR),
             .CRYPTODATAINPPTR    (CRYPTODATAINPPTR),
             .CRYPTOHMACSERVICE   (CRYPTOHMACSERVICE),
             .CRYPTOHMACDATAPTR   (CRYPTOHMACDATAPTR),
             .CRYPTOSRCADPTR      (CRYPTOSRCADPTR),
             .CRYPTODSTADPTR      (CRYPTODSTADPTR),     
             .FFSERVICE           (FFSERVICE),             
             .KEYTREESERVICE      (KEYTREESERVICE),
             .KEYTREEDATAPTR      (KEYTREEDATAPTR),
             .CHRESPSERVICE       (CHRESPSERVICE),
             .CHRESPPTR           (CHRESPPTR),
             .CHRESPKEYADDR       (CHRESPKEYADDR),                                                                     
             .NRBGSERVICE         (NRBGSERVICE),
             .NRBGINSTPTR         (NRBGINSTPTR),
             .NRBGPERSTRINGPTR    (NRBGPERSTRINGPTR),
             .NRBGGENPTR          (NRBGGENPTR),
             .NRBGREQDATAPTR      (NRBGREQDATAPTR),
             .NRBGRESEEDPTR       (NRBGRESEEDPTR),
             .NRBGADDINPPTR       (NRBGADDINPPTR),                                                                     
             .ZERSERVICE          (ZERSERVICE),
             .PROGIAPSERVICE      (PROGIAPSERVICE),
             .PROGNVMDISERVICE    (PROGNVMDISERVICE),
             .PORDSERVICE         (PORDSERVICE),
             .ECCPOINTMULTSERVICE (ECCPOINTMULTSERVICE),  
             .ECCPMULTDESC        (ECCPMULTDESC),
             .ECCPMULTDPTR        (ECCPMULTDPTR),
             .ECCPMULTPPTR        (ECCPMULTPPTR),
             .ECCPMULTQPTR        (ECCPMULTQPTR),
             .ECCPOINTADDSERVICE  (ECCPOINTADDSERVICE),
             .ECCPADDDESC         (ECCPADDDESC),
             .ECCPADDPPTR         (ECCPADDPPTR),
             .ECCPADDQPTR         (ECCPADDQPTR),
             .ECCPADDRPTR         (ECCPADDRPTR),
             .TAMPERDETECTSERVICE (TAMPERDETECTSERVICE),                              
             .TAMPERCONTROLSERVICE(TAMPERCONTROLSERVICE),                              
             .PUFSERVICE          (PUFSERVICE),     
             .PUFUSERACPTR        (PUFUSERACPTR),   
             .PUFUSERKCPTR        (PUFUSERKCPTR),   
             .PUFUSERKEYPTR       (PUFUSERKEYPTR),     
             .PUFPUBLICKEYPTR     (PUFPUBLICKEYPTR),  
             .PUFPUBLICKEYADDR    (PUFPUBLICKEYADDR), 
             .PUFSEEDPTR          (PUFSEEDPTR),
             .PUFSEEDADDR         (PUFSEEDADDR)
             )
     U_UserIF(   
                 // Inputs
                 .clk                  (CLK),   
                 .resetn               (RESETN),   
                 
                 // From User logic
                 .ureq_enable_i        (SERV_ENABLE_REQ),   
                 .ucmdbyte_req_i       (SERV_CMDBYTE_REQ),   
                 .uoptions_mode_i      (SERV_OPTIONS_MODE),
                 .ucommblk_int_i       (COMM_BLK_INT),
                 .udata_wvalid_i       (SERV_DATA_WVALID),   
                 .udata_w_i            (SERV_DATA_W),
                 
                 .ucrypto_key          (SERV_CRYPTO_KEY),
                 .ucrypto_iv           (SERV_CRYPTO_IV),    
                 .ucrypto_mode         (SERV_CRYPTO_MODE),  
                 .ucrypto_nblocks      (SERV_CRYPTO_NBLOCKS),
                 .ucrypto_length       (SERV_CRYPTO_LENGTH),
                 
                 .unrbg_length         (SERV_NRBG_LENGTH),
                 .unrbg_handle         (SERV_NRBG_HANDLE),
                 .unrbg_addlength      (SERV_NRBG_ADDLENGTH),
                 .unrbg_prreq          (SERV_NRBG_PRREQ),
                 
                 .udpa_key_i           (SERV_DPA_KEY),
                 .udpa_optype_i        (SERV_DPA_OPTYPE),
                 .udpa_path_i          (SERV_DPA_PATH),
                 
                 .upuf_subcmd_i        (SERV_PUF_SUBCMD), 
                 .upuf_inkeynum_i      (SERV_PUF_INKEYNUM),       
                 .upuf_userkeyaddr_i   (SERV_PUFUSERKEYADDR),          
                 .upuf_userextrkeyaddr_i (SERV_USEREXTRINSICKEYADDR),  
                 .upuf_keysize_i       (SERV_PUF_KEYSIZE),
                 
                 .uspiaddr_i           (SERV_SPIADDR),  

                 // From Command decoder IF
                 .cubusy_i             (cubusy_o),           
                 .cudata_wrdy_i        (cudata_wrdy_o),
                 .cudata_rvalid_i      (cudata_rvalid_o),
                 .cudata_r_i           (cudata_r_o),
                 .cuhprior_flushdone_i (cuhprior_flushdone_o),
                 .cutrans_done_i       (cutrans_done_o),
                 .custatus_valid_i     (custatus_valid_o),
                 .custatus_out_en      (custatus_out_en),
                 .cutamper_msg_valid   (cutamper_msg_valid),
                 .cutamper_msg         (cutamper_msg),  
                 .cucmd_error          (cucmd_error),
                 .cutamper_detect_valid(cutamper_detect_valid),
                 .cutamper_fail_valid  (cutamper_fail_valid),
                 .cunvm_bfr_iapverify_done(cunvm_bfr_iapverify_done),   
                 // Outputs       
                 // To CmdDec IF
                 .uccommblk_int_o      (uccommblk_int_o),
                 .uctrig_o             (uctrig_o),
                 .uclatchcmd_o         (uclatchcmd_o),   
                 .uclatchoptions_o     (uclatchoptions_o),
                 .uchprior_flushreq_o  (uchprior_flushreq_o),

                 .ucnvm_bfr_iapverify  (ucnvm_bfr_iapverify),  
                 
                 .uccrypto_key_o       (uccrypto_key_o),
                 .uccrypto_iv_o        (uccrypto_iv_o),
                 .uccrypto_mode_o      (uccrypto_mode_o),
                 .uccrypto_nblocks_o   (uccrypto_nblocks_o),
                 .uccrypto_length_o    (uccrypto_length_o), 
  
                 .ucnrbg_length_o      (ucnrbg_length_o),   
                 .ucnrbg_handle_o      (ucnrbg_handle_o),   
                 .ucnrbg_addlength_o   (ucnrbg_addlength_o),
                 .ucnrbg_prreq_o       (ucnrbg_prreq_o),
                 
                 .ucdpa_key_o          (ucdpa_key_o),
                 .ucdpa_optype_o       (ucdpa_optype_o),  
                 .ucdpa_path_o         (ucdpa_path_o), 
                      
                 .ucpuf_subcmd_o       (ucpuf_subcmd_o),
                 .ucpuf_inkeynum_o     (ucpuf_inkeynum),        
                 .ucpuf_userkeyaddr_o   (ucpuf_userkeyaddr),  
                 .ucpuf_userextrkeyaddr_o (ucpuf_userextrkeyaddr),  
                 .ucpuf_keysize_o      (ucpuf_keysize_o),

                 .ucspiaddr_o          (ucspiaddr),  

                 .ucdata_wvalid_o      (ucdata_wvalid_o),
                 .ucdata_w_o           (ucdata_w_o),
                 .ucvalid_cmd_o        (ucvalid_cmd_o),

                 // To User logic   
                 .ubusy_o              (SERV_BUSY),
                 
                 .udata_wrdy_o         (SERV_DATA_WRDY),   
                 .udata_rvalid_o       (SERV_DATA_RVALID),
                 .udata_r_o            (SERV_DATA_R),
                      
                 .ustatus_valid_o      (SERV_STATUS_VALID),
                 .ustatus_resp_o       (SERV_STATUS_RESP),
                 .utamper_msg_valid    (SERV_TAMPER_MSGVALID),
                 .utamper_msg          (SERV_TAMPER_MSG),
                 .ucmd_error           (SERV_CMD_ERROR)   
                 
                 );   


   //-------------------------
   // Command Decoder Instance
   //-------------------------
   CoreSysServices_CmdDec #(
            .SNSERVICE           (SNSERVICE),
            .DSNPTR              (DSNPTR),
            .UCSERVICE           (UCSERVICE),
            .USERCODEPTR         (USERCODEPTR),
            .DCSERVICE           (DCSERVICE),  
            .DEVICECERTPTR       (DEVICECERTPTR),
            .SECDCSERVICE        (SECDCSERVICE),  
            .SECONDECCCERTPTR    (SECONDECCCERTPTR),
            .UDVSERVICE          (UDVSERVICE),   
            .DESIGNVERPTR        (DESIGNVERPTR), 
            
            .CRYPTOAES128SERVICE (CRYPTOAES128SERVICE),
            .CRYPTOAES128DATAPTR (CRYPTOAES128DATAPTR),
            .CRYPTOAES256SERVICE (CRYPTOAES256SERVICE),
            .CRYPTOAES256DATAPTR (CRYPTOAES256DATAPTR),
            .CRYPTOSHA256SERVICE (CRYPTOSHA256SERVICE),
            .CRYPTOSHA256DATAPTR (CRYPTOSHA256DATAPTR),
            .CRYPTORSLTPTR       (CRYPTORSLTPTR),
            .CRYPTODATAINPPTR    (CRYPTODATAINPPTR),
            .CRYPTOHMACSERVICE   (CRYPTOHMACSERVICE),
            .CRYPTOHMACDATAPTR   (CRYPTOHMACDATAPTR),
            .CRYPTOSRCADPTR      (CRYPTOSRCADPTR),
            .CRYPTODSTADPTR      (CRYPTODSTADPTR),                                                                    
            .FFSERVICE           (FFSERVICE),             
            .KEYTREESERVICE      (KEYTREESERVICE),
            .KEYTREEDATAPTR      (KEYTREEDATAPTR),
            .CHRESPSERVICE       (CHRESPSERVICE),
            .CHRESPPTR           (CHRESPPTR),
            .CHRESPKEYADDR       (CHRESPKEYADDR),                                                                    
            .NRBGSERVICE         (NRBGSERVICE),
            .NRBGINSTPTR         (NRBGINSTPTR),
            .NRBGPERSTRINGPTR    (NRBGPERSTRINGPTR),
            .NRBGGENPTR          (NRBGGENPTR),
            .NRBGREQDATAPTR      (NRBGREQDATAPTR),
            .NRBGRESEEDPTR       (NRBGRESEEDPTR),
            .NRBGADDINPPTR       (NRBGADDINPPTR),                                                                    
            .ZERSERVICE          (ZERSERVICE),
            .PROGIAPSERVICE      (PROGIAPSERVICE),
            .PROGNVMDISERVICE    (PROGNVMDISERVICE),
            .PORDSERVICE         (PORDSERVICE),
            .ECCPOINTMULTSERVICE (ECCPOINTMULTSERVICE),  
            .ECCPMULTDESC        (ECCPMULTDESC),
            .ECCPMULTDPTR        (ECCPMULTDPTR),
            .ECCPMULTPPTR        (ECCPMULTPPTR),
            .ECCPMULTQPTR        (ECCPMULTQPTR),
            .ECCPOINTADDSERVICE  (ECCPOINTADDSERVICE),
            .ECCPADDDESC         (ECCPADDDESC),
            .ECCPADDPPTR         (ECCPADDPPTR),
            .ECCPADDQPTR         (ECCPADDQPTR),
            .ECCPADDRPTR         (ECCPADDRPTR),
            .TAMPERDETECTSERVICE (TAMPERDETECTSERVICE),                              
            .TAMPERCONTROLSERVICE(TAMPERCONTROLSERVICE),                              
            .PUFSERVICE          (PUFSERVICE),     
            .PUFUSERACPTR        (PUFUSERACPTR),   
            .PUFUSERKCPTR        (PUFUSERKCPTR),   
            .PUFUSERKEYPTR       (PUFUSERKEYPTR),     
            .PUFPUBLICKEYPTR     (PUFPUBLICKEYPTR),  
            .PUFPUBLICKEYADDR    (PUFPUBLICKEYADDR), 
            .PUFSEEDPTR          (PUFSEEDPTR),
            .PUFSEEDADDR         (PUFSEEDADDR)
            )
     U_CmdDec(   
                 .clk                  (CLK),   
                 .resetn               (RESETN),   
                 // From UserIF
                 .uctrig_i             (uctrig_o),
                 .uclatchcmd_i         (uclatchcmd_o),   
                 .uclatchoptions_i     (uclatchoptions_o),
                 .uchprior_flushreq_i  (uchprior_flushreq_o),

                 .uccrypto_key_i       (uccrypto_key_o),
                 .uccrypto_iv_i        (uccrypto_iv_o),
                 .uccrypto_mode_i      (uccrypto_mode_o),
                 .uccrypto_nblocks_i   (uccrypto_nblocks_o),
                 .uccrypto_length_i    (uccrypto_length_o), 
                 
                 .ucnrbg_length_i      (ucnrbg_length_o),   
                 .ucnrbg_handle_i      (ucnrbg_handle_o),   
                 .ucnrbg_addlength_i   (ucnrbg_addlength_o),
                 .ucnrbg_prreq_i       (ucnrbg_prreq_o),
                 
                 .ucdpa_key_i          (ucdpa_key_o),
                 .ucdpa_optype_i       (ucdpa_optype_o),  
                 .ucdpa_path_i         (ucdpa_path_o), 

                 .ucpuf_subcmd_i       (ucpuf_subcmd_o),
                 .ucpuf_inkeynum_i     (ucpuf_inkeynum),  
                 .ucpuf_keysize_i      (ucpuf_keysize_o),
                 .ucpuf_userkeyaddr_i   (ucpuf_userkeyaddr),  
                 .ucpuf_userextrkeyaddr_i (ucpuf_userextrkeyaddr),  
                 
                 .ucspiaddr_i          (ucspiaddr),  

                 .ucdata_wvalid_i      (ucdata_wvalid_o),
                 .ucdata_w_i           (ucdata_w_o),
                 
                 .ucvalid_cmd_i        (ucvalid_cmd_o),

                 .ucnvm_bfr_iapverify  (ucnvm_bfr_iapverify),  

                 .uccommblk_int_i      (uccommblk_int_o),

                 .mchready_i           (mfhready_o),

                 // From FSM logic IF
                 .fcdataout_i          (fcdataout_o),
                 .fcbusreq_i           (fcbusreq_o),
                 .fctrans_done_i       (fctrans_done_o),
                 .fcpop_i              (fcpop_o),
                 .fcpush_i             (fcpush_o),

                 .idle_trigger         (idle_trigger),
                 .rvalid_out_en        (rvalid_out_en),
                 .clr_req              (clr_req),
                 
                 // To UserIF
                 .cudata_wrdy_o        (cudata_wrdy_o),
                 .cudata_rvalid_o      (cudata_rvalid_o),
                 .cudata_r_o           (cudata_r_o),
                 .custatus_valid_o     (custatus_valid_o),
                 .cutrans_done_o       (cutrans_done_o),
                 .cuhprior_flushdone_o (cuhprior_flushdone_o),
                 .custatus_out_en      (custatus_out_en),
                 .cutamper_msg_valid   (cutamper_msg_valid),
                 .cutamper_msg         (cutamper_msg), 
                 .cucmd_error          (cucmd_error),
                 .cutamper_detect_valid(cutamper_detect_valid),
                 .cutamper_fail_valid  (cutamper_fail_valid),
                 .cunvm_bfr_iapverify_done(cunvm_bfr_iapverify_done),   
                 // To FSM logic IF
                 .cfgrant_o            (cfgrant_o),

                 .cfwr_req_d           (cfwr_req_d),
                 .cfrd_req_d           (cfrd_req_d),
                 .cfwr_req_o           (cfwr_req_o),
                 .cfrd_req_o           (cfrd_req_o),
                 .cfrd_resp_o          (cfrd_resp_o),
                 .cfburst_len_rd_o     (cfburst_len_rd_o),
                 .cfburst_len_wr_o     (cfburst_len_wr_o),
                 .cubusy_o             (cubusy_o),
                 .cfdatain_o           (cfdatain_o),
                 .cfsrc_addr_o         (cfsrc_addr_o),
                 .cfdst_addr_o         (cfdst_addr_o),
                 .cfcommaccess_active  (cfcommaccess_active),
                 .cfrd_asyncevent_o    (cfrd_asyncevent_o), 
                 .cfcommaccess_resp_active (cfcommaccess_resp_active)

                 );


   //--------------------------
   // AHBL FSM Control Instance
   //--------------------------
   CoreSysServices_FSMCtrl U_fsm_ctrl  
     (  
        // AHB Master Interface  
        .hclk                     (HCLK),  
        .hresetn                  (HRESETN),  
        
        .fmhtrans_o               (fmhtrans_o),  
        .fmhsel_o                 (fmhsel_o),  
        .fmhwrite_o               (fmhwrite_o),  
        .fmhsize_o                (fmhsize_o),  
        .fmhburst_o               (fmhburst_o),  
        .fmhaddr_o                (fmhaddr_o),  
        .fmhwdata_o               (fmhwdata_o),  
        .mfhrdata_i               (mfhrdata_o),  
        .mfhready_i               (mfhready_o),  
        .mfhresp_i                (mfhresp_o),  
        
        // From Cmd dec
        .cfgrant_i                (cfgrant_o),    
        .cfrd_resp_i              (cfrd_resp_o),  

        .cfwr_req_d               (cfwr_req_d),
        .cfrd_req_d               (cfrd_req_d),

        .cfwr_req_i               (cfwr_req_o),  
        .cfrd_req_i               (cfrd_req_o),
        .cfdatain_i               (cfdatain_o),  
        .cfsrc_addr_i             (cfsrc_addr_o),  
        .cfdst_addr_i             (cfdst_addr_o),            
        .cfburst_len_rd_i         (cfburst_len_rd_o),
        .cfburst_len_wr_i         (cfburst_len_wr_o),
        .cfcommaccess_active      (cfcommaccess_active),
        .cfcommaccess_resp_active (cfcommaccess_resp_active),
        .cfrd_asyncevent_i        (cfrd_asyncevent_o), 
        // To  Cmd dec
        .fctrans_done_o           (fctrans_done_o),  
        .fcdataout_o              (fcdataout_o),  
        .fcbusreq_o               (fcbusreq_o),
        .idle_trigger             (idle_trigger),
        .rvalid_out_en            (rvalid_out_en),
        .clr_req                  (clr_req),

        .push                     (fcpush_o),
        .pop                      (fcpop_o)
        
        );  
   

   //-------------------------
   // AHBL Master IF Instance
   //-------------------------
   CoreSysServices_AHBLMasterIF U_AHBLMasterIF (   
                                   // AHBL Master IF   
                                   .HCLK       (HCLK),   
                                   .HRESETN    (HRESETN),   
                                   .HSEL       (HSEL),   
                                   .HADDR      (HADDR),   
                                   .HWRITE     (HWRITE),   
                                   .HWDATA     (HWDATA),   
                                   .HTRANS     (HTRANS),   
                                   .HBURST     (HBURST),   
                                   .HSIZE      (HSIZE),   
                                   .HRESP      (HRESP),   
                                   .HREADY     (HREADY),   
                                   .HRDATA     (HRDATA),   
                                   // Backend IF
                                   .fmhsel_i   (fmhsel_o),
                                   .fmhtrans_i (fmhtrans_o),  
                                   .fmhwrite_i (fmhwrite_o),  
                                   .fmhsize_i  (fmhsize_o),  
                                   .fmhburst_i (fmhburst_o),  
                                   .fmhaddr_i  (fmhaddr_o),  
                                   .fmhwdata_i (fmhwdata_o),
                                   .mfhready_o (mfhready_o),  
                                   .mfhresp_o  (mfhresp_o),  
                                   .mfhrdata_o (mfhrdata_o)
                                   );


endmodule // CORESYSSERVICES_C0_CORESYSSERVICES_C0_0_CORESYSSERVICES



