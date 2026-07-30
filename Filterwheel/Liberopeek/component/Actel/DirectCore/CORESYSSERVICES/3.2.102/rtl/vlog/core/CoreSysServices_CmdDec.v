// ****************************************************************************/   
// Actel Corporation Proprietary and Confidential   
// Copyright 2010 Actel Corporation.  All rights reserved.   
//   
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN   
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED   
// IN ADVANCE IN WRITING.   
//   
// Description: CmdDec.v - Command Decoder logic block
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
 
 
module CoreSysServices_CmdDec (   
                  clk,   
                  resetn,   
                  // From UserIF
                  uctrig_i,
                  uclatchcmd_i,   
                  uclatchoptions_i,
                  uchprior_flushreq_i,         
                  
                  uccrypto_key_i,
                  uccrypto_iv_i,    
                  uccrypto_mode_i,   
                  uccrypto_nblocks_i,
                  uccrypto_length_i,
                  
                  ucnrbg_length_i,   
                  ucnrbg_handle_i,   
                  ucnrbg_addlength_i,
                  ucnrbg_prreq_i,

                  ucdpa_key_i,
                  ucdpa_optype_i,
                  ucdpa_path_i,

                  ucpuf_subcmd_i,  
                  ucpuf_inkeynum_i,
                  ucpuf_keysize_i,
                  ucpuf_userkeyaddr_i,                  
                  ucpuf_userextrkeyaddr_i,                  
                  ucspiaddr_i,    
                  uccommblk_int_i,
                  
                  ucdata_wvalid_i,
                  ucdata_w_i,

                  ucvalid_cmd_i,     
                  ucnvm_bfr_iapverify,  

                  mchready_i,
                  
                  // From FSM logic IF
                  fcdataout_i,
                  fcbusreq_i,
                  fctrans_done_i,
                  fcpop_i,
                  fcpush_i,
                  
                  idle_trigger,
                  rvalid_out_en,
                  clr_req,

                  // To UserIF                  
                  cudata_wrdy_o,
                  cudata_rvalid_o,
                  cudata_r_o,
                  custatus_valid_o,
                  cutamper_msg_valid,
                  cutamper_msg,
                  cutrans_done_o,
                  cubusy_o,
                  cuhprior_flushdone_o,
                  custatus_out_en,
                  cucmd_error,              
                  cutamper_detect_valid,    
                  cutamper_fail_valid,      
                  cunvm_bfr_iapverify_done, 

                  // To FSM logic IF
                  cfgrant_o,

                  cfwr_req_d,
                  cfrd_req_d,
                  cfwr_req_o,
                  cfrd_req_o,
                  cfrd_resp_o,
                  cfrd_asyncevent_o,
                  cfburst_len_wr_o,
                  cfburst_len_rd_o,

                  cfdatain_o,
                  cfsrc_addr_o,
                  cfdst_addr_o,
                  cfcommaccess_active,
                  cfcommaccess_resp_active

                  );   
   
   //------------------------------------------------------------------------------   
   // Parameter declarations   
   //------------------------------------------------------------------------------   
   parameter SNSERVICE        = 0;    
   parameter DSNPTR           = 0;
   parameter UCSERVICE        = 0;    
   parameter USERCODEPTR      = 0;
   parameter DCSERVICE        = 0;    
   parameter DEVICECERTPTR    = 0;
   parameter SECDCSERVICE     = 0;     
   parameter SECONDECCCERTPTR = 0;     
   parameter UDVSERVICE       = 0;    
   parameter DESIGNVERPTR     = 0;
 
   parameter CRYPTOAES128SERVICE    = 0;    
   parameter CRYPTOAES128DATAPTR    = 0;
   parameter CRYPTOAES256SERVICE    = 0;
   parameter CRYPTOAES256DATAPTR    = 0;
   parameter CRYPTOSHA256SERVICE    = 0;
   parameter CRYPTOSHA256DATAPTR    = 0;
   parameter CRYPTORSLTPTR          = 0;
   parameter CRYPTODATAINPPTR       = 0;
   parameter CRYPTOHMACSERVICE      = 0;
   parameter CRYPTOHMACDATAPTR      = 0;
   parameter CRYPTOSRCADPTR         = 0;
   parameter CRYPTODSTADPTR         = 0;
 
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

   localparam AHB_AWIDTH      = 32;   
   localparam AHB_DWIDTH      = 32;   
 
   // State Machine parameter definition
   localparam C_IDLE       = 2'b00;
   localparam C_REQ_PHASE  = 2'b01;
   localparam C_RESP_PHASE = 2'b10;

  // State Machine parameter definition
   localparam REQ_IDLE           = 6'b000000;
   localparam REQ_WAIT_MEMWR1    = 6'b000001;
   localparam REQ_MEMWR_DESC     = 6'b000010;
   localparam REQ_WAIT_MEMWR2    = 6'b000011;
   localparam REQ_MEMWR_DATA     = 6'b000100;
   localparam REQ_PHASE          = 6'b000101;
   localparam REQ_FIIC_INT       = 6'b000111;
   localparam REQ_POLL_CINT1     = 6'b001000;
   localparam REQ_RDCOMM_STATUS1 = 6'b001001;
   localparam REQ_WRCOMM_CTRL    = 6'b001010;
   localparam REQ_WRCOMM_INT     = 6'b001011;
   localparam REQ_WRCOMM_FRM     = 6'b001100;
   localparam REQ_WRCOMM_DATA    = 6'b001101;
   localparam REQ_POLL_CINT2     = 6'b001110;
   localparam REQ_RDCOMM_STATUS2 = 6'b001111;
   localparam REQ_WAIT_REG1      = 6'b010000;
   localparam REQ_WAIT_REG2      = 6'b010001;
   localparam REQ_WAIT_REG3      = 6'b010010;
   localparam REQ_WAIT_REG4      = 6'b010011;
   localparam REQ_WAIT_REG5      = 6'b010100;
   localparam REQ_WAIT_REG6      = 6'b010101;
   localparam REQ_WAIT_REG7      = 6'b010110;
   localparam REQ_WAIT_REG8      = 6'b010111;
   localparam REQ_WAIT_REG9      = 6'b011000;
   localparam REQ_RD_INT         = 6'b011011;   
   localparam REQ_RDCOMM_INT     = 6'b011100;
   localparam REQ_WAIT_REG10     = 6'b100001;
   localparam REQ_WAIT_REG11     = 6'b100010;
   localparam REQ_WAIT_REG12     = 6'b100011;
   localparam REQ_WAIT_REG13     = 6'b100100;
   localparam REQ_WRCOMM_CTRL2   = 6'b100101;
   localparam REQ_WRCOMM_CTRL3   = 6'b100110;
   localparam REQ_WRCOMM_CTRL4   = 6'b100111;
   localparam REQ_WRCOMM_INT2    = 6'b101000;
   localparam REQ_WAIT_MEMWR22   = 6'b101001;
   localparam REQ_MEMWR_DATA1    = 6'b101010;
   localparam REQ_WAIT_ASYNCRD1    = 6'b101011;
   localparam REQ_RDCOMM_ASYNCFRM1 = 6'b101100;
   localparam REQ_WAIT_ASYNCRD2    = 6'b101101;
   localparam REQ_RDCOMM_ASYNCFRM2 = 6'b101110;
   localparam REQ_ASYNC_OUT1       = 6'b110000;
   localparam REQ_ASYNC_OUT2       = 6'b110001;
   localparam REQ_WAIT_REG14       = 6'b110010;
   localparam REQ_WRCOMM_DESC2     = 6'b110011;
   localparam REQ_WAIT_REG15       = 6'b110100;

   localparam RESP_IDLE           = 6'b000000;
   localparam RESP_PHASE          = 6'b000001;
   localparam RESP_RDCOMM_STATUS  = 6'b000011;
   localparam RESP_RDCOMM_FRM     = 6'b000100;
   localparam RESP_RDCOMM_DESC    = 6'b000101;
   localparam RESP_RDCOMM_DATA    = 6'b000110;
   localparam RESP_WAIT_MEMRD     = 6'b000111;
   localparam RESP_MEMRD          = 6'b001000;
   localparam RESP_POLL_CINT1     = 6'b001001;
   localparam RESP_POLL_CINT4     = 6'b001100;
   localparam RESP_REG1           = 6'b001101;   
   localparam RESP_REG4           = 6'b010000;   
   localparam RESP_REG5           = 6'b010001;
   localparam RESP_REG6           = 6'b010010;
   localparam RESP_REG7           = 6'b010011;
   localparam RESP_REG8           = 6'b010100;
   localparam RESP_REG9           = 6'b010101;
   localparam RESP_WRCOMM_CTRL1   = 6'b010110;   
   localparam RESP_WAIT_REG11     = 6'b010111;
   localparam RESP_WRCOMM_CTRL2   = 6'b011000;   
   localparam RESP_WAIT_REG12     = 6'b011001;
   localparam RESP_RDCOMM_STATUS3 = 6'b011011;
   localparam RESP_WRCOMM_INT3    = 6'b100100;
   localparam RESP_WAIT_REG13     = 6'b100101;
   localparam RESP_FIIC_INT       = 6'b100110;
   localparam RESP_WAIT_REG14     = 6'b100111;
   localparam RESP_WAIT_ASYNCRD1    = 6'b101000;
   localparam RESP_RDCOMM_ASYNCFRM1 = 6'b101001;
   localparam RESP_ASYNC_OUT1       = 6'b101100;
   localparam RESP_WAIT_ASYNCRD3    = 6'b101110;
   localparam RESP_RDCOMM_ASYNCFRM3 = 6'b101111;
   localparam RESP_ASYNC_OUT3       = 6'b110000;

   localparam ASYNCEVENT_POLL_IDLE     = 4'b0000;
   localparam ASYNCEVENT_POLL_WAIT     = 4'b0001;
   localparam ASYNCEVENT_POLL_CINT     = 4'b0010;
   localparam ASYNCEVENT_REG1          = 4'b0011;
   localparam ASYNCEVENT_RDCOMM_STATUS = 4'b0100;
   localparam ASYNCEVENT_WAIT_RD1      = 4'b0101;
   localparam ASYNCEVENT_RDCOMM_FRM1   = 4'b0110;
   localparam ASYNCEVENT_RDCOMM_OUT1   = 4'b0111;
   localparam ASYNCEVENT_WAIT          = 4'b1000;
   localparam ASYNCEVENT_PHASE         = 4'b1001;
   localparam ASYNCEVENT_WAIT_REG11    = 4'b1010;
   localparam ASYNCEVENT_WRCOMM_CTRL1  = 4'b1011;
   localparam ASYNCEVENT_WAIT_REG13    = 4'b1100;
   localparam ASYNCEVENT_FIIC_INT      = 4'b1101;
   localparam ASYNCEVENT_WAIT_REG14    = 4'b1110;
   localparam ASYNCEVENT_WRCOMM_INT3   = 4'b1111;

   localparam COMM_CTRL_REG         = 32'h40016000;
   localparam COMM_STATUS_REG       = 32'h40016004;
   localparam COMM_INTEN_REG        = 32'h40016008;
   localparam COMM_DATA8_REG        = 32'h40016010;
   localparam COMM_DATA32_REG       = 32'h40016014;
   localparam COMM_FRM8_REG         = 32'h40016018;
   localparam COMM_FRM32_REG        = 32'h4001601C;

   //------------------------------------------------------------------------------   
   // Port declarations   
   //------------------------------------------------------------------------------   
   
   // -----------   
   // Inputs   
   // -----------   
   input      clk;   
   input      resetn;   
   // User IF   
   input      uctrig_i;
   input [7:0] uclatchcmd_i;
   input [5:0] uclatchoptions_i;
   input       uchprior_flushreq_i;

   // Crypto inputs
   input [255:0] uccrypto_key_i;
   input [127:0] uccrypto_iv_i;
   input [7:0]   uccrypto_mode_i;
   input [15:0]  uccrypto_nblocks_i;
   input [31:0]  uccrypto_length_i;
   
   // NRBG inputs
   input [7:0]   ucnrbg_length_i;
   input [7:0]   ucnrbg_handle_i;
   input [7:0]   ucnrbg_addlength_i;
   input [7:0]   ucnrbg_prreq_i;
   
   // DPA inputs
   input [255:0] ucdpa_key_i;
   input [7:0]   ucdpa_optype_i;
   input [127:0] ucdpa_path_i;
   
   // PUF inputs
   input [7:0]   ucpuf_subcmd_i;   
   input [7:0]   ucpuf_inkeynum_i;   
   input [7:0]   ucpuf_keysize_i;   
   input [31:0]  ucpuf_userkeyaddr_i;
   input [31:0]  ucpuf_userextrkeyaddr_i;
   input [31:0]  ucspiaddr_i;  
   
   input         uccommblk_int_i;
   
   input         ucdata_wvalid_i;
   input [31:0]  ucdata_w_i;
   input         ucvalid_cmd_i;
   input         ucnvm_bfr_iapverify;  

   input         mchready_i;
   
   input [31:0]  fcdataout_i;   
   input         fcbusreq_i;
   input         fctrans_done_i;
   input         fcpop_i;
   input         fcpush_i;

   input         idle_trigger;
   input         rvalid_out_en;   
   input         clr_req;   

   // -----------  
   // Outputs  
   // -----------  
   // User IF   
   output        cudata_wrdy_o;
   output        cudata_rvalid_o;
   output [AHB_DWIDTH - 1:0] cudata_r_o;
   output                    custatus_valid_o;   
   output                    cutamper_msg_valid;   
   output [7:0]              cutamper_msg;   
   output                    cutrans_done_o;
   output                    cubusy_o;
   output                    cuhprior_flushdone_o;
   
   
   // To FSM Control block
   output                    cfgrant_o;

   output                    cfwr_req_d;
   output                    cfrd_req_d;
   output                    cfwr_req_o;
   output                    cfrd_req_o;
   output                    cfrd_resp_o;
   output                    cfrd_asyncevent_o;  
   
   output [31:0]             cfburst_len_wr_o;
   output [31:0]             cfburst_len_rd_o;
   output [31:0]             cfdatain_o;   
   output [31:0]             cfsrc_addr_o;   
   output [31:0]             cfdst_addr_o;
   output                    cfcommaccess_active;   
   output                    cfcommaccess_resp_active;   
   output                    custatus_out_en;
   output                    cucmd_error;
   output                    cutamper_detect_valid;
   output                    cutamper_fail_valid;
   output                    cunvm_bfr_iapverify_done;  
   
   // -----------------  
   // Internal signals  
   // -----------------  
   reg [5:0]                 req_curr_state;          // Command Decoder REQ S/M current State
   reg [5:0]                 req_next_state;          // Command Decoder REQ S/M next State 
   reg [5:0]                 resp_curr_state;         // Command Decoder RESP S/M current State
   reg [5:0]                 resp_next_state;         // Command Decoder RESP S/M next State 
   reg [3:0]                 asynchevent_curr_state;  // Command Decoder I/F S/M current State
   reg [3:0]                 asynchevent_next_state;  // Command Decoder I/F S/M next State 
   reg [1:0]                 main_curr_state;         // Command Decoder MAI S/M current State 
   reg [1:0]                 main_next_state;         // Command Decoder MAIN S/M next State 


   reg                        cfgrant_req;
   reg                        cfgrant_resp;
   reg                        cfgrant_asyncevent;
   reg                        cfwr_req_o;   
   reg                        cfwr_req_d;
   reg                        cfwr_req_d1;
   reg                        cfrd_req_o;
   reg                        cfrd_req_d;
   reg                        cfrd_resp_o;
   reg                        cfrd_asyncevent_d;
   reg                        cfrd_asyncevent_o;
   reg [31:0]                 cfburst_len_wr_o;
   reg [31:0]                 cfburst_len_rd_o;
   reg [31:0]                 cfdatain_o;
   reg [31:0]                 cfdatain_d1;
   reg                        fctrans_done_d1;
   reg                        fctrans_done_d2;
   reg                        fcbusreq_d1;
   reg [31:0]                 cfburst_len_wr_d1;
   reg [31:0]                 cfburst_len_rd_d1;
   reg [31:0]                 cfsrc_addr_o;   
   reg [31:0]                 memrd_data_addr;
   reg [31:0]                 cfdst_addr_o;
   reg [31:0]                 cfsrc_addr_int;   
   reg [31:0]                 cfdst_addr_int;
   reg                        cubusy_o;
   reg                        req_phase_active;
   reg                        resp_phase_active;
   reg [15:0]                 burstlen_memwr_desc;
   reg [31:0]                 burstlen_memwr_data;
   reg [31:0]                 burstlen_memwr_data_r;
   reg [15:0]                 burstlen_memrd_data;
   reg [15:0]                 burstlen_memrd_data_d1;
   reg [479:0]                memwr_desc;
   reg [31:0]                 memwr_data;
   reg [31:0]                 memwr_desc_int;
   reg [31:0]                 memwr_desc_addr;
   reg [31:0]                 memwr_data_addr;   
   reg                        req_desc_done;
   reg                        resp_desc_done;   
   reg                        resp_data_done;   
   reg                        req_phase_active_pulse;
   reg                        req_phase_active_d1;   
   reg                        resp_data_done_d1;   
   reg                        resp_phase_done_d1;   
   reg                        resp_phase_done_pulse;   
   reg                        resp_phase_active_d1;
   reg                        resp_phase_active_pulse;
   reg                        custatus_out_en1;   
   reg                        hprior_abort;   
   reg                        cucmd_error;
   reg                        cmd_error;
   reg                        asyncevent_cmd_error;
   reg                        resp_frm_done;
   reg                        req_phase_done;
   reg                        req_phase_done_d1;
   reg [31:0]                 req_dstreg_addr;
   reg [31:0]                 req_srcreg_addr;
   reg [31:0]                 req_dstreg_data;
   reg [31:0]                 req_srcreg_data;
   reg [31:0]                 resp_srcreg_addr;
   reg [31:0]                 resp_srcreg_data;
   reg [31:0]                 asyncevent_srcreg_addr;
   reg [31:0]                 asyncevent_dstreg_addr;
   reg [31:0]                 asyncevent_dstreg_data;
   reg                        cfcommaccess_active;
   reg                        cfcommaccess_resp_active;
   reg                        fiicreg_done;
   reg                        commctrlreg_done;
   reg                        resp_phase_done;   
   reg                        datawr_reqd;
   reg                        cudata_wrdy_o;
   reg                        cudata_wrdy_d1;
   reg                        cudata_rvalid_o;   
   reg [AHB_DWIDTH - 1:0]     cudata_r_o;  
   reg [AHB_DWIDTH - 1:0]     cudata_r_int;  
   reg                        do_mem_wr;
   reg                        do_mem_rd;   
   reg                        txtokay;

   wire                       FF_entry_c;  
   reg                        FF_entry;
   wire                       FF_entry_bit;

   wire                       FF_exit_c;
   reg                        FF_exit;
   wire                       FF_exit_bit;

   reg                        FF_entry_led;
   reg                        FF_exit_led;  
   
   reg [31:0]                 resp_srcreg_addr_d1;
   reg [31:0]                 resp_srcreg_data_d1;
   reg                        cmd_error_d1;
   reg                        cunvm_bfr_iapverify_done;     
   reg                        cunvm_bfr_iapverify_done_d1;  
   reg                        rcvokay;
   reg                        cmdrcv;
   reg                        cuhprior_flushdone_o;
   reg                        cuhprior_flushdone_d1;
   reg                        fcpop_d1;
   reg                        fiicreg_done_d1;
   reg                        commctrlreg_done_d1;
   reg                        commpoll_done;
   reg                        commpoll_done_d1;
   reg                        tamper_detect_valid;
   reg                        tamper_fail_valid;
   reg                        tamper_detect_valid_r;
   reg                        tamper_fail_valid_r;
   reg                        cutamper_detect_valid;
   reg                        cutamper_fail_valid;
   reg [2:0]                  wait_count;
   reg [31:0]                 cfdst_addr_d1;
   reg [31:0]                 cfsrc_addr_d1;   
   reg                        custatus_valid_o;
   reg                        cutamper_msg_valid;
   reg                        pord_d1;
   reg                        pord_d2;
   reg                        pord;
   reg                        rd_active;
  
   wire                       FF_TO_START;  
   wire                       FF_DONE;      

   reg                        asyncevent_active;
   reg                        set_sent_options;
   reg                        set_sent_options_r;
   reg                        set_puf_getkcnum;  
   reg                        reset_puf_getkcnum;  
   reg                        set_puf_getkcnum_r;  
   wire [7:0]                 uclatchcmd_i_mux;
   reg [31:0]                 memwr_data_addr_r;
   reg [31:0]                 fcdataout_d1;   
   reg                        latchen_hrdata_r;
   reg [7:0]                  cutamper_msg;   
   reg                        unreg_cmd;

   wire                       rcvokay_bit;
   wire                       cmdrcv_bit;
   wire                       txtokay_bit;
   wire                       custatus_out_en;
   wire                       custatus_out_en2;  
   wire                       cfwr_req_int;
   wire                       cfgrant_o;
   wire                       cfwr_req_c;
   wire                       rdcommstatus_valid;   
   wire                       txtokay_c;
   wire                       rcvokay_c;
   wire                       cmdrcv_c;
   wire                       cudata_wrdy_int;
   wire                       cfdata_w_o;
   wire                       cudata_rvalid_int;   
   wire                       cudata_rvalid_int2;   
   wire [7:0]                 ucpuf_keysize_dec;
   wire                       latchen_hrdata_int;
   wire                       latchen_hrdata;
   integer                    desc_datasel_cntr;

   //////////////////////////////////////////////////////////////////////////////  
   //                           Start-of-Code                                  //  
   //////////////////////////////////////////////////////////////////////////////  
         
   assign uclatchcmd_i_mux = (set_puf_getkcnum == 1'b1) ? 8'h1A : uclatchcmd_i; 

   // --------------------------------------------------------------------------
   // 
   // --------------------------------------------------------------------------
   always  @(posedge clk or negedge resetn) begin  
      if(~resetn) begin
         set_puf_getkcnum <= 1'b0;
      end
      else begin
	 if(main_curr_state == C_IDLE) begin
           set_puf_getkcnum <= 1'b0;
         end
	 else if(reset_puf_getkcnum == 1'b0 && (resp_curr_state == RESP_REG8) &&  
                 	           ((uclatchcmd_i == 8'h19 && ucpuf_subcmd_i == 8'h00) || 
	                            (uclatchcmd_i == 8'h19 && ucpuf_subcmd_i == 8'h01)  
	                           )) begin
            set_puf_getkcnum <= 1'b1;
         end
	 else if(reset_puf_getkcnum == 1'b0 && (resp_curr_state == RESP_RDCOMM_DATA) &&
                 	           ((uclatchcmd_i == 8'h1A && ucpuf_subcmd_i == 8'h01) || 
	                            (uclatchcmd_i == 8'h1A && ucpuf_subcmd_i == 8'h02) || 
	                            (uclatchcmd_i == 8'h1A && ucpuf_subcmd_i == 8'h05))) begin
            set_puf_getkcnum <= 1'b1;
         end
      end
   end
 
   always  @(posedge clk or negedge resetn) begin  
      if(~resetn) begin
         reset_puf_getkcnum <= 1'b0;
      end
      else begin
	 if(main_curr_state == C_IDLE) begin
           reset_puf_getkcnum <= 1'b0;
         end
	 else if(set_puf_getkcnum == 1'b1 && req_curr_state == REQ_WAIT_REG14) begin
           reset_puf_getkcnum <= 1'b1;
         end
      end
   end

   // --------------------------------------------------------------------------
   // Determine whether exclusive write or read to eSRAM is required for a
   // particular service.
   // For some services, data needs to be written into eSRAM memory space at the
   // location pointed by the data pointer descriptor handle during request.
   // For some services, data needs to be read from eSRAM memory space from the
   // location pointed by the data pointer descriptor handle during request.
   // do_mem_wr = 1, write to eSRAM is required.
   // do_mem_rd = 1, read to eSRAM is required.
   // --------------------------------------------------------------------------
   always @(*) begin
      do_mem_wr = 1'b0;
      do_mem_rd = 1'b0;
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux) 
           8'h00, 8'h01, 8'h05, 8'h04, 8'h1E : begin  // Device and Design Information services  
              do_mem_wr = 1'b0;
              do_mem_rd = 1'b1;
           end
           8'h02 : begin                       // F*F services
              do_mem_wr = 1'b0;
              do_mem_rd = 1'b0;
           end
           8'h03, 8'h06, 8'h0A, 8'h0C: begin   // AES128/AES256/SHA256/HMAC services
              do_mem_wr = 1'b1;
              do_mem_rd = 1'b1;
           end
           8'h09, 8'h0E: begin                 // Key Tree/PUF services
              do_mem_wr = 1'b1;
              do_mem_rd = 1'b1;
           end
           8'h28,8'h2C, 8'h2D: begin           // NRBG services
              do_mem_wr = 1'b0;
              do_mem_rd = 1'b0;
           end
           8'h29: begin                        // NRBG Instantiate services
              do_mem_wr = 1'b1;
              do_mem_rd = 1'b1;
           end
           8'h2A: begin                        // NRBG Generate services
              do_mem_wr = 1'b1;
              do_mem_rd = 1'b1;
           end
           8'h2B: begin                        // NRBG Reseed services
              do_mem_wr = 1'b1;
              do_mem_rd = 1'b0;
           end
           8'hF0: begin                        // Zeroization service
              do_mem_wr = 1'b0;
              do_mem_rd = 1'b0;
           end
           8'h14, 8'h17, 8'h1F: begin          // IAP/NVMData Integrity service  // Tamper control
              do_mem_wr = 1'b0;
              do_mem_rd = 1'b0;
           end
           8'h10, 8'h11: begin                 // Elliptic Curve services 
              do_mem_wr = 1'b1;
              do_mem_rd = 1'b1;
           end
           8'h19: begin                        // PUFUSERAC services
              do_mem_wr = 1'b1; 
              do_mem_rd = 1'b0;
           end
           8'h1A: begin                        // PUFUSERKC services 
              do_mem_wr = 1'b1;           
              do_mem_rd = (ucpuf_subcmd_i == 8'h00 && set_puf_getkcnum == 1'b0) ? 1'b1 : 1'b0; 
           end
           8'h1B: begin                        // PUFUSERKEY services  
              do_mem_wr = 1'b1;  
              do_mem_rd = 1'b1;
           end
           8'h1C: begin                        // PUFPUBLICKEY services 
              do_mem_wr = 1'b1;  
              do_mem_rd = 1'b1;
           end
           8'h1D: begin                        // PUFSEED services 
              do_mem_wr = 1'b1;  
              do_mem_rd = 1'b1;
           end
           default: begin
              do_mem_wr = 1'b0;
              do_mem_rd = 1'b0;
           end

         endcase // case (uclatchcmd_i)        
      end          
   end

   // --------------------------------------------------------------------------
   // burstlen_memwr_desc: Calculate the descriptor burstlength required for 
   // write to eSRAM memory space
   // --------------------------------------------------------------------------
   always @(*) begin
      burstlen_memwr_desc = 16'h0000;
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux) 
           8'h03: begin   // AES128 services
              burstlen_memwr_desc = 16'h000B; //# of Word transfers
           end
           8'h06: begin   // AES256 services
              burstlen_memwr_desc = 16'h000F; //# of Word transfers
           end
           8'h0A: begin   // SHA256 services
              burstlen_memwr_desc = 16'h0003; //# of Word transfers
           end
           8'h0C: begin   // HMAC services
              burstlen_memwr_desc = 16'h000B; //# of Word transfers
           end
           8'h09: begin  // Key Tree services
              burstlen_memwr_desc = 32'h000D; //# of Word transfers
           end
           8'h0E: begin  // PUF services
              burstlen_memwr_desc = 32'h0006; //# of Word transfers
           end
           8'h29: begin  // Instantiate services
              burstlen_memwr_desc = 32'h0002; //# of Word transfers
           end
           8'h2A: begin  // Generate services
              burstlen_memwr_desc = 32'h0003; //# of Word transfers
           end
           8'h2B: begin  // Reseed services
              burstlen_memwr_desc = 32'h0002; //# of Word transfers
           end
           8'h10, 8'h11: begin                // Elliptic Curve services
              burstlen_memwr_desc = 32'h0003; //# of Word transfers
           end
           8'h19: begin  // PUFUSERAC Services  
              burstlen_memwr_desc = 32'h0001; //# of Word transfers
           end
           8'h1A: begin  // PUFUSERKC Services 
              burstlen_memwr_desc = set_puf_getkcnum ? 16'h0003 : 32'h0003; //# of Word transfers 
           end
           8'h1B: begin  // PUFUSERKEY Services 
              burstlen_memwr_desc = 32'h0002; //# of Word transfers
           end
           8'h1C: begin  // PUFPUBLICKEY Services 
              burstlen_memwr_desc = 32'h0001; //# of Word transfers
           end
           8'h1D: begin  // PUFSEED Services 
              burstlen_memwr_desc = 32'h0001; //# of Word transfers
           end
           default: begin
              burstlen_memwr_desc = 16'h0000;
           end

         endcase // case (uclatchcmd_i)
      end // if (uctrig_i == 1'b1)     
   end


   // --------------------------------------------------------------------------
   // burstlen_memwr_data: Calculate the data burstlength required for write to 
   // eSRAM memory space
   // --------------------------------------------------------------------------
   always @(*) begin
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux) 
           8'h03: begin   // AES128 services
              burstlen_memwr_data = uccrypto_nblocks_i*4;
           end
           8'h06: begin   // AES256 services
              burstlen_memwr_data = uccrypto_nblocks_i*4;
           end
           8'h0A: begin   // SHA256 services
    	      if(uccrypto_length_i == 32'h00000000) begin
                 burstlen_memwr_data = 32'h00000001;
	      end
	      else begin
   	         if(uccrypto_length_i[4:0] == 5'b00000) begin
                   burstlen_memwr_data = uccrypto_length_i/32;
                 end
   	         else begin
                   burstlen_memwr_data = (uccrypto_length_i/32) + 32'h00000001;
                 end
              end
           end
           8'h0C: begin   // HMAC services
    	      if(uccrypto_length_i == 32'h00000000) begin
                 burstlen_memwr_data = 32'h00000001;
	      end
	      else begin
   	         if(uccrypto_length_i[1:0] == 2'b00) begin  
                   burstlen_memwr_data = uccrypto_length_i/4;
                 end
   	         else begin
                   burstlen_memwr_data = (uccrypto_length_i/4) + 32'h00000001;
                 end
              end
           end
           8'h29: begin   // Instantiate 
              if(ucnrbg_length_i == 32'h00000000 )begin
                 burstlen_memwr_data = 32'h00000001 ;
              end 
              else begin
   	         if(ucnrbg_length_i[1:0] == 2'b00) begin
                   burstlen_memwr_data = ucnrbg_length_i/4;
                 end
   	         else begin
                   burstlen_memwr_data = (ucnrbg_length_i/4) + 32'h00000001;
                 end
              end
           end
           8'h2A: begin   // Generate
              if(ucnrbg_addlength_i == 32'h00000000 )begin
                 burstlen_memwr_data = 32'h00000001 ;
              end 
              else begin
   	         if(ucnrbg_addlength_i[1:0] == 2'b00) begin
                   burstlen_memwr_data = ucnrbg_addlength_i/4;
                 end
   	         else begin
                   burstlen_memwr_data = (ucnrbg_addlength_i/4) + 32'h00000001;
                 end
              end
           end
           8'h2B: begin   // Reseed
              if(ucnrbg_addlength_i == 32'h00000000 )begin
                 burstlen_memwr_data = 32'h00000001 ;
              end 
              else begin
   	         if(ucnrbg_addlength_i[1:0] == 2'b00) begin
                   burstlen_memwr_data = ucnrbg_addlength_i/4;
                 end
   	         else begin
                   burstlen_memwr_data = (ucnrbg_addlength_i/4) + 32'h00000001;
                 end
              end
             
           end
           8'h20: begin   // SPI
              burstlen_memwr_data = 32'h1;
           end
           8'h10: begin   // Elliptic Curve
           if(req_curr_state == REQ_WAIT_MEMWR2) begin
              burstlen_memwr_data = 32'h0000000C;
           end
           else if(req_curr_state == REQ_WAIT_MEMWR22) begin
              burstlen_memwr_data = 32'h00000018;
           end
           else begin
              burstlen_memwr_data = burstlen_memwr_data_r;
           end
           end
           8'h11: begin   // Elliptic Curve
              burstlen_memwr_data = 32'h00000018;
           end
           8'h1A: begin   //PUFUSERKC 
 	   if (set_puf_getkcnum == 1'b1) begin  
              burstlen_memwr_data = 32'h00000000;  
           end
	   else begin
              if(ucpuf_subcmd_i == 8'h00 || ucpuf_subcmd_i == 8'h05) begin        
                 burstlen_memwr_data = 32'h00000000;  
              end
              else if(ucpuf_subcmd_i == 8'h01 || ucpuf_subcmd_i == 8'h02) begin
                 burstlen_memwr_data = ucpuf_keysize_dec;  
              end
              else if(ucpuf_subcmd_i == 8'h04) begin  
                 burstlen_memwr_data = 32'h00000000;  
              end
              else begin
                 burstlen_memwr_data = burstlen_memwr_data_r;
              end
           end
           end
           default: begin
              burstlen_memwr_data = 32'h00000000;
           end

         endcase // case (uclatchcmd_i)
      end // if (ucvalid_cmd_i == 1'b1)    
      else begin
         burstlen_memwr_data = 32'h00000000;
      end  
   end

   assign ucpuf_keysize_dec = (ucpuf_keysize_i == 8'h00) ? 8'h80 : (ucpuf_keysize_i*64/32);      

   // --------------------------------------------------------------------------
   // burstlen_memrd_data: Calculate the burstlength required for read from eSRAM 
   // memory space
   // --------------------------------------------------------------------------
   always @(*) begin
      burstlen_memrd_data = burstlen_memrd_data_d1;  
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux)  
           8'h01 : begin  // SNS services
              burstlen_memrd_data = 16'h0004; // # of word length
           end
           8'h04 : begin  // UCS services
              burstlen_memrd_data = 16'h0001; // # of word length
           end
           8'h00 : begin  // DCS services
              burstlen_memrd_data = 16'h00C0; // # of word length
           end
           8'h1E : begin  // v3.0 - SDCS services
              burstlen_memrd_data = 16'h00A0; 
           end
           8'h05 : begin  // DVS services
              burstlen_memrd_data = 16'h0001; // # of word length
           end
           8'h03: begin   // AES128 services
              burstlen_memrd_data = uccrypto_nblocks_i*4;
           end
           8'h06: begin   // AES256 services
              burstlen_memrd_data = uccrypto_nblocks_i*4;
           end
           8'h0A: begin   // SHA256 services
              burstlen_memrd_data = 8;        // # of word length
           end
           8'h0C: begin   // HMAC services 
              burstlen_memrd_data = 8;        // # of word length
           end
           8'h09: begin   // Key Tree services 
              burstlen_memrd_data = 8;        // # of word length
           end
           8'h0E: begin   // Challenge Resp services 
              burstlen_memrd_data = 8;        // # of word length
           end
           8'h2A: begin   // Generate services 
   	      if(ucnrbg_length_i == 8'h00) begin
                   burstlen_memrd_data = 16'h0001;
	      end
	      else begin
      	        if(ucnrbg_length_i[1:0] == 2'b00) begin
                   burstlen_memrd_data = ucnrbg_length_i/4;
                end
   	        else begin
                   burstlen_memrd_data = (ucnrbg_length_i/4) + 16'h0001;
                end
              end
           end
           8'h29: begin   // Instantiate services 
              burstlen_memrd_data = 16'h0001;        // # of bytes length
           end
           8'h2B: begin   // Reseed services 
              burstlen_memrd_data = 16'h0001;        // # of bytes length
           end
           8'h10: begin   // Elliptic Curve
              burstlen_memrd_data = 16'h0018;
           end
           8'h11: begin   // Elliptic Curve
              burstlen_memrd_data = 16'h0018;
           end
           8'h19: begin   // PUFUSERAC 
              burstlen_memrd_data = 16'h0001;
           end
           8'h1A: begin   // PUFUSERKC 
 	   if (set_puf_getkcnum == 1'b1) begin  
              burstlen_memrd_data = 16'h0000;
	   end
	   else begin
              if(ucpuf_subcmd_i == 8'h00) begin   // Get # of KC
                 burstlen_memrd_data = 16'h0001;
              end
	   end
           end
           8'h1B: begin   // PUFUSERKEY 
              burstlen_memrd_data = {8'h00, ucpuf_keysize_dec+1};  
           end
           8'h1C: begin   // PUFPUBLICKEY 
              burstlen_memrd_data = 16'h0018;
           end
           8'h1D: begin   // PUFSEED 
              burstlen_memrd_data = 16'h0008;
           end
           default: begin
              burstlen_memrd_data = 16'h0000;
           end

         endcase // case (uclatchcmd_i)
      end // if (uctrig_i == 1'b1)
      else begin
         burstlen_memrd_data = burstlen_memrd_data_d1;
      end
   end // always @ (*)

   // --------------------------------------------------------------------------
   // burstlen_memrd_data_d1: Regisetered burstlen_memrd_data
   // --------------------------------------------------------------------------
   always  @(posedge clk or negedge resetn) begin
      if(~resetn) begin
         burstlen_memrd_data_d1 <= 16'h0000;
         burstlen_memwr_data_r  <= 32'h00000000;
      end
      else begin
         burstlen_memrd_data_d1 <= burstlen_memrd_data;
         burstlen_memwr_data_r  <= burstlen_memwr_data;
      end
   end
   
   // --------------------------------------------------------------------------
   // req_desc_done: Set the signal to perform the write data to memory after  
   // the write descriptor to memory is performed.
   // It allows the transition from REQ_WAIT_MEMWR1/2 state to appropriate next st.
   // Set when current state is REQ_MEMWR_DESC
   // Reset when current state is REQ_MEMWR_DATA
   // --------------------------------------------------------------------------
   always  @(posedge clk or negedge resetn) begin
      if(~resetn) begin
         req_desc_done <= 1'b0;
      end
      else if(req_curr_state == REQ_MEMWR_DATA || req_curr_state == REQ_PHASE) begin
         req_desc_done <= 1'b0;
      end
      else if(req_curr_state == REQ_MEMWR_DESC) begin
         req_desc_done <= 1'b1;
      end
   end

   // --------------------------------------------------------------------------
   // resp_desc_done: Set the signal to perform the read data from comm_blk
   // to read the cmd, descriptor and status
   // Set when current state is RESP_RDCOMM_DESC
   // Reset when current state is RESP_RDCOMM_DATA
   // --------------------------------------------------------------------------
   always  @(posedge clk or negedge resetn) begin
      if(~resetn) begin
         resp_desc_done <= 1'b0;
         resp_data_done <= 1'b0;
         resp_frm_done <= 1'b0;
      end
      else if(resp_curr_state == RESP_IDLE) begin
         resp_desc_done <= 1'b0;
         resp_data_done <= 1'b0;
         resp_frm_done <= 1'b0;
      end
      else if(resp_curr_state == RESP_RDCOMM_DATA) begin
         resp_data_done <= 1'b1;
      end
      else if(resp_curr_state == RESP_RDCOMM_DESC) begin
         resp_desc_done <= 1'b1;
      end
      else if(resp_curr_state == RESP_RDCOMM_FRM) begin
         resp_frm_done <= 1'b1;
      end
   end

   // --------------------------------------------------------------------------
   // cfburst_len_wr_o: Calculate the burstlen for # of writes to be done in the   
   // memory and also for # of writes to be done on the comm_blk.
   // --------------------------------------------------------------------------
   always  @(*) begin
      if(req_curr_state == REQ_WAIT_MEMWR1 && idle_trigger) begin
         cfburst_len_wr_o <= {16'h0000, burstlen_memwr_desc};
      end
      else if(req_curr_state == REQ_WAIT_MEMWR2 && idle_trigger) begin
         cfburst_len_wr_o <= burstlen_memwr_data;
      end
      else if(req_curr_state == REQ_WAIT_MEMWR22 && idle_trigger) begin  
         cfburst_len_wr_o <= burstlen_memwr_data;
      end
      else if(req_curr_state == REQ_PHASE && idle_trigger) begin
         cfburst_len_wr_o <= 32'h00000001;
      end
      else if(resp_curr_state == RESP_PHASE && idle_trigger) begin 
         cfburst_len_wr_o <= 32'h00000001;
      end
      else if(resp_curr_state == RESP_RDCOMM_DESC && idle_trigger) begin
         cfburst_len_wr_o <= 32'h00000001;
      end
      else if(resp_curr_state == RESP_RDCOMM_FRM && idle_trigger) begin // For interrupt reg mask addition
         cfburst_len_wr_o <= 32'h00000001;
      end
      else if(resp_curr_state == RESP_RDCOMM_ASYNCFRM1 && idle_trigger) begin 
         cfburst_len_wr_o <= 32'h00000001;
      end
      else if(asynchevent_curr_state == ASYNCEVENT_PHASE && idle_trigger) begin 
         cfburst_len_wr_o <= 32'h00000001;
      end
      else begin
         cfburst_len_wr_o <= cfburst_len_wr_d1;
      end
   end // always  @ (posedge clk or negedge resetn)
   
   // --------------------------------------------------------------------------
   // cfburst_len_wr_d1: Delayed cfburst_len_wr_o
   // cfburst_len_rd_d1: Delayed cfburst_len_rd_o
   // --------------------------------------------------------------------------
   always  @(posedge clk or negedge resetn) begin
      if(~resetn) begin
         cfburst_len_wr_d1 <= 32'h00000000;
         cfburst_len_rd_d1 <= 16'h0000;
      end
      else begin
         cfburst_len_wr_d1 <= cfburst_len_wr_o;
         cfburst_len_rd_d1 <= cfburst_len_rd_o;
      end
   end
   
   // --------------------------------------------------------------------------
   // cfburst_len_rd_o: Calculate the burstlen for read to be done from the   
   // memory and also when read to be done from the comm_blk.
   // --------------------------------------------------------------------------
   always  @(*) begin
      if(resp_curr_state == RESP_RDCOMM_DATA && resp_next_state == RESP_WAIT_MEMRD) begin
         cfburst_len_rd_o <= burstlen_memrd_data;
      end
      else if((req_curr_state == REQ_PHASE) || (req_next_state == REQ_MEMWR_DESC) || (asynchevent_curr_state == ASYNCEVENT_POLL_WAIT) ||            
              (resp_curr_state == RESP_PHASE) && !resp_data_done) begin  
         cfburst_len_rd_o <= 16'h0001;
      end
      else begin
         cfburst_len_rd_o <= cfburst_len_rd_d1;
      end
   end

   // --------------------------------------------------------------------------
   // datawr_reqd:Determine whether any data write to memory is required or
   // not.
   // --------------------------------------------------------------------------
   always @(*) begin
      datawr_reqd = 1'b0;
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux) 
           8'h03, 8'h06, 8'h0A, 8'h0C: begin // AES128/256/SHA/HMAC services
              datawr_reqd = 1'b1;
           end
           8'h29, 8'h2A, 8'h2B: begin        // Instantiate/Generate/Reseed services
              datawr_reqd = 1'b1;
           end
           8'h20: begin                      // SPI services
              datawr_reqd = 1'b1;
           end
           8'h10, 8'h11: begin               // Elliptic Curve
              datawr_reqd = 1'b1;
           end
           8'h1A: begin                      // PUFUSERKC 
              if(set_puf_getkcnum == 1'b1) begin   
                 datawr_reqd = 1'b0;  
              end
              else if(set_puf_getkcnum == 1'b0) begin
                 datawr_reqd = (ucpuf_subcmd_i == 8'h00 || ucpuf_subcmd_i == 8'h02 || ucpuf_subcmd_i == 8'h03 || ucpuf_subcmd_i == 8'h04 || ucpuf_subcmd_i == 8'h05) ? 1'b0 : 1'b1;  
              end
           end
           default: begin
              datawr_reqd = 1'b0;
           end
  
         endcase // case (uclatchcmd_i)
      end // if (uctrig_i == 1'b1)           
   end

   // --------------------------------------------------------------------------
   // cfdst_addr_int: Generate and pass the appropriate address corresponding to
   // the state in which the state machine is.
   // --------------------------------------------------------------------------
   always @(*) begin
      // Write desc address
      if(req_curr_state == REQ_MEMWR_DESC) begin
         cfdst_addr_o = memwr_desc_addr;
      end
      // Write data address
      else if(req_curr_state == REQ_MEMWR_DATA) begin
         cfdst_addr_o = memwr_data_addr;        
      end
      // Write data address
      else if(req_curr_state == REQ_MEMWR_DATA1) begin
         cfdst_addr_o = memwr_data_addr;        
      end
      // write address for COMM_BLK -->
      else if(req_curr_state == REQ_FIIC_INT) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(resp_curr_state == RESP_FIIC_INT) begin           
         cfdst_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_WRCOMM_INT3) begin        
         cfdst_addr_o = resp_srcreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_CTRL) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_INT) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_INT2) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_DESC2) begin   
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_CTRL2) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_CTRL3) begin   
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(resp_curr_state == RESP_WRCOMM_CTRL1) begin  
         cfdst_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_WRCOMM_CTRL2) begin 
         cfdst_addr_o = resp_srcreg_addr;
      end
      else if(req_curr_state == REQ_RDCOMM_STATUS1) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_RDCOMM_ASYNCFRM1) begin  
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_FRM) begin
         cfdst_addr_o = req_dstreg_addr;
      end 
      else if(req_curr_state == REQ_RDCOMM_STATUS2) begin
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_RDCOMM_ASYNCFRM2) begin  
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_DATA) begin   
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(req_curr_state == REQ_WRCOMM_DESC2) begin    
         cfdst_addr_o = req_dstreg_addr;
      end
      else if(asynchevent_curr_state == ASYNCEVENT_RDCOMM_FRM1) begin  
         cfdst_addr_o = asyncevent_srcreg_addr;
      end
      else if(asynchevent_curr_state == ASYNCEVENT_RDCOMM_STATUS) begin  
         cfdst_addr_o = asyncevent_srcreg_addr;
      end
      else if(asynchevent_curr_state == ASYNCEVENT_WRCOMM_CTRL1) begin  
         cfdst_addr_o = asyncevent_dstreg_addr;
      end
      else if(asynchevent_curr_state == ASYNCEVENT_FIIC_INT) begin      
         cfdst_addr_o = asyncevent_dstreg_addr;
      end
      else if(asynchevent_curr_state == ASYNCEVENT_WRCOMM_INT3) begin   
         cfdst_addr_o = asyncevent_dstreg_addr;
      end
      else begin
         cfdst_addr_o = cfdst_addr_d1;
      end
   end

   // --------------------------------------------------------------------------
   // cfdst_addr_d1: Registered cfdst_addr_o
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cfdst_addr_d1 <= 32'h00000000;
      end
      else begin
         cfdst_addr_d1 <= cfdst_addr_o;
      end
   end

   // --------------------------------------------------------------------------
   // cfsrc_addr_o: Generate and pass the appropriate address corresponding to
   // the state in which the state machine is.
   // --------------------------------------------------------------------------
   always @(*) begin
      // Read data address
      if(resp_curr_state == RESP_MEMRD) begin
         cfsrc_addr_o = memrd_data_addr;        
      end
      // Read address for COMM_BLK 
      else if(resp_curr_state == RESP_RDCOMM_STATUS) begin
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_RDCOMM_STATUS3) begin
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_RDCOMM_ASYNCFRM1) begin  
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_RDCOMM_ASYNCFRM3) begin  
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_RDCOMM_FRM) begin
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_RDCOMM_DESC) begin
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else if(resp_curr_state == RESP_RDCOMM_DATA) begin
         cfsrc_addr_o = resp_srcreg_addr;
      end
      else begin
         cfsrc_addr_o = cfsrc_addr_d1; 
      end
   end

   // --------------------------------------------------------------------------
   // cfsrc_addr_d1: Registered cfsrc_addr_o
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cfsrc_addr_d1 <= 32'h00000000;
      end
      else begin
         cfsrc_addr_d1 <= cfsrc_addr_o;
      end
   end


   // --------------------------------------------------------------------------
   // memwr_desc_addr: Calculate the address required for write to eSRAM 
   // memory space based on the type of service selected
   // --------------------------------------------------------------------------
   always @(*) begin
      memwr_desc_addr = 32'h00000000;
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux) 
           8'h01: begin   // SN services
              memwr_desc_addr = DSNPTR;
           end
           8'h04: begin   // UC services
              memwr_desc_addr = USERCODEPTR;
           end
           8'h00: begin   // DC services
              memwr_desc_addr = DEVICECERTPTR;
           end
           8'h1E: begin   // v3.0 Sec DC services
              memwr_desc_addr = SECONDECCCERTPTR;
           end
           8'h05: begin   // DV services
              memwr_desc_addr = DESIGNVERPTR;
           end
           8'h03: begin   // AES128 services
              memwr_desc_addr = CRYPTOAES128DATAPTR;
           end
           8'h06: begin   // AES256 services
              memwr_desc_addr = CRYPTOAES256DATAPTR;
           end
           8'h0A: begin   // SHA256 services
               memwr_desc_addr = CRYPTOSHA256DATAPTR;
           end
           8'h0C: begin   // HMAC services
              memwr_desc_addr = CRYPTOHMACDATAPTR;
           end
           8'h09: begin  // Key Tree services
              memwr_desc_addr = KEYTREEDATAPTR;
           end
           8'h0E: begin  // PUF services
              memwr_desc_addr = CHRESPPTR;
           end
           8'h29: begin  // Instantiate services
              memwr_desc_addr = NRBGINSTPTR;
           end
           8'h2A: begin  // Generate services
              memwr_desc_addr = NRBGGENPTR;
           end
           8'h2B: begin  // Reseed services
              memwr_desc_addr = NRBGRESEEDPTR;
           end
           8'h10: begin     // Elliptic Curve
              memwr_desc_addr = ECCPMULTDESC;
           end
           8'h11: begin     // Elliptic Curve
              memwr_desc_addr = ECCPADDDESC;
           end
           8'h14: begin     // IAP
              memwr_desc_addr = ucspiaddr_i;  
           end
           8'h19: begin     // PUFUSERAC 
              memwr_desc_addr = PUFUSERACPTR;
           end
           8'h1A: begin     // PUFUSERKC 
              memwr_desc_addr = PUFUSERKCPTR;
           end
           8'h1B: begin     // PUFUSERKEY 
              memwr_desc_addr = PUFUSERKEYPTR;
           end
           8'h1C: begin     // PUFPUBLICKEY 
              memwr_desc_addr = PUFPUBLICKEYPTR;
           end
           8'h1D: begin     // PUFSEED 
              memwr_desc_addr = PUFSEEDPTR;
           end
           default: begin
              memwr_desc_addr = 32'h00000000;
           end
   
         endcase // case (uclatchcmd_i)
      end // if (uctrig_i == 1'b1)     
   end
   
   // --------------------------------------------------------------------------
   // memwr_data_addr: Calculate the address required for write to eSRAM 
   // memory space based on the type of service selected
   // --------------------------------------------------------------------------
   always @(*) begin
      memwr_data_addr = 32'h00000000;
     if(ucvalid_cmd_i == 1'b1) begin
        case(uclatchcmd_i_mux) 
          8'h03, 8'h06: begin  // AES128/AES256 services   
             memwr_data_addr = CRYPTOSRCADPTR;
          end
          8'h0A , 8'h0C: begin  // SHA256/HMAC services  
             memwr_data_addr = CRYPTODATAINPPTR;
          end
          8'h29: begin  // Instantiate services
             memwr_data_addr = NRBGPERSTRINGPTR;
          end
          8'h2A: begin  // Generate services
             memwr_data_addr = NRBGADDINPPTR;
          end
          8'h2B: begin  // Reseed services
             memwr_data_addr = NRBGADDINPPTR;
          end          
          8'h10: begin  // Elliptic Curve
           if(req_curr_state == REQ_WAIT_MEMWR2) begin
              memwr_data_addr = ECCPMULTDPTR;
           end
           else if(req_curr_state == REQ_WAIT_MEMWR22) begin
              memwr_data_addr = ECCPMULTPPTR;
           end
           else begin
              memwr_data_addr = memwr_data_addr_r;
           end
          end
          8'h11: begin  // Elliptic Curve
           if(req_curr_state == REQ_WAIT_MEMWR2) begin
              memwr_data_addr = ECCPADDPPTR;
           end
           else if(req_curr_state == REQ_WAIT_MEMWR22) begin
              memwr_data_addr = ECCPADDQPTR;
           end
           else begin
              memwr_data_addr = memwr_data_addr_r;
           end
          end
          8'h1A: begin     //PUFUSERKC 
             if(ucpuf_subcmd_i == 8'h01) begin
               memwr_data_addr = ucpuf_userextrkeyaddr_i;
             end
             else if(ucpuf_subcmd_i == 8'h02) begin
                memwr_data_addr = ucpuf_userkeyaddr_i;
             end
             else begin
                memwr_data_addr = 32'h00000000;
             end
          end
          default: begin
             memwr_data_addr = 32'h00000000;
          end

        endcase // case (uclatchcmd_i)
     end // if (uctrig_i == 1'b1)     
   end

   // --------------------------------------------------------------------------
   // memrd_data_addr: Calculate the address required for read from eSRAM 
   // memory space based on the type of service selected
   // --------------------------------------------------------------------------
   always @(*) begin
      memrd_data_addr = 32'h00000000;
     if(ucvalid_cmd_i == 1'b1) begin
        case(uclatchcmd_i_mux)  
          8'h03, 8'h06: begin   // AES128/AES256 services  
             memrd_data_addr = CRYPTODSTADPTR;
          end
          8'h0A , 8'h0C: begin   // SHA256/HMAC services  
             memrd_data_addr = CRYPTORSLTPTR;
          end
          8'h01: begin   // Design and Information Services
             memrd_data_addr = DSNPTR;
          end
          8'h04: begin   // Design and Information Services
             memrd_data_addr = USERCODEPTR;
          end
          8'h00: begin   // Design and Information Services
             memrd_data_addr = DEVICECERTPTR;
          end
          8'h1E: begin   // Sec. Design and Information Services
             memrd_data_addr = SECONDECCCERTPTR;
          end
          8'h05: begin   // Design and Information Services
             memrd_data_addr = DESIGNVERPTR;
          end
          8'h09: begin   // Key Tree
             memrd_data_addr = KEYTREEDATAPTR;
          end
          8'h0E: begin   // PUF
             memrd_data_addr = CHRESPKEYADDR;
          end
          8'h2A: begin   // Generate NRBG
             memrd_data_addr = NRBGREQDATAPTR;
          end
          8'h29: begin  // Instantiate services
             memrd_data_addr = NRBGINSTPTR + 32'h00000004;  // To read Handle
          end
          8'h2B: begin  // Reseed services
             memrd_data_addr = NRBGRESEEDPTR + 32'h00000004;  // To read Handle
          end
          8'h10: begin  // Elliptic Curve
             memrd_data_addr = ECCPMULTQPTR;  
          end
          8'h11: begin  // Elliptic Curve
             memrd_data_addr = ECCPADDRPTR;  
          end
          8'h1A: begin     // PUFUSERKC  
             memrd_data_addr = PUFUSERKCPTR +  32'h00000008;
          end
          8'h1B: begin     // PUFUSERKEY   
             memrd_data_addr = ucpuf_userkeyaddr_i;  
          end
          8'h1C: begin     // PUFPUBLICKEY 
             memrd_data_addr = PUFPUBLICKEYADDR;  
          end
          8'h1D: begin     // PUFSEED 
             memrd_data_addr = PUFSEEDADDR;  
          end
          default: begin
             memrd_data_addr = 32'h00000000;
          end
        endcase // case (uclatchcmd_i)
     end // if (uctrig_i == 1'b1)     
   end // always @ (*)

   
   // --------------------------------------------------------------------------
   // Registered signals
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         req_phase_done_d1    <= 1'b0;
         resp_phase_done_d1   <= 1'b0;
         resp_phase_active_d1 <= 1'b0;
         resp_data_done_d1    <= 1'b0;         
         req_phase_active_d1  <= 1'b0;         
         cuhprior_flushdone_o <= 1'b0;         
      end
      else begin
         req_phase_done_d1    <= req_phase_done;
         resp_phase_done_d1   <= resp_phase_done;
         resp_phase_active_d1 <= resp_phase_active;
         resp_data_done_d1    <= resp_data_done;
         req_phase_active_d1  <= req_phase_active;         
         cuhprior_flushdone_o <= hprior_abort;         
      end
   end

   // --------------------------------------------------------------------------
   // resp_phase_active_pulse: Generate response phase active pulse
   // This is used to invoke the response state machine
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         resp_phase_active_pulse <= 1'b0;
      end
      else begin
         resp_phase_active_pulse <= resp_phase_active & !resp_phase_active_d1;
      end
   end

   // --------------------------------------------------------------------------
   // resp_phase_done_pulse: Generate response phase done pulse
   // This is used to exit the main state machine from response phase back to 
   // idle indicating that the service has been serviced.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         resp_phase_done_pulse <= 1'b0;
      end
      else begin
         resp_phase_done_pulse <= !resp_phase_done & resp_phase_done_d1;
      end
   end

   // --------------------------------------------------------------------------
   // req_phase_active_pulse: Generate request phase active pulse
   // This is used to invoke the request state machine
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         req_phase_active_pulse <= 1'b0;
      end
      else begin
         req_phase_active_pulse <= req_phase_active & !req_phase_active_d1;
      end
   end

   // --------------------------------------------------------------------------
   // pord: PoR Digest check pulse when reset is de-asserted
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         pord <= 1'b0;
      end
      else begin
         if(PORDSERVICE == 1'b1) begin
            pord <= pord_d1 & !pord_d2;
         end
         else begin
            pord <= 1'b0;
         end
      end
   end

   // --------------------------------------------------------------------------
   // Registered signals
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         pord_d1 <= 1'b0;
         pord_d2 <= 1'b0;
      end
      else begin
         pord_d1 <= 1'b1;
         pord_d2 <= pord_d1;
      end
   end

   
   // --------------------------------------------------------------------------
   /////////////////////////////////////////////////////////////////////////////
   //                                                                         //
   //        ||\  /|| ||||| || ||   ||         |||||| |||||| ||\  /||         //
   //        ||\\//|| || || || ||\  ||         ||     ||     ||\\//||         //
   //        || \/ || ||_|| || || \ ||   ==    ||||   |||||| || \/ ||         //
   //        ||    || || || || ||  \||         ||         || ||    ||         //
   //        ||    || || || || ||   \|         ||     |||||| ||    ||         //
   //                                                                         //
   /////////////////////////////////////////////////////////////////////////////
   // --------------------------------------------------------------------------

   // --------------------------------------------------------------------------
   // Main State Machine: Command Decoder 
   // This State Machine combines the two sub-state machines: Reqest FSM and
   // Response FSM
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         main_curr_state <= C_IDLE;
      end
      else begin
         main_curr_state <= main_next_state;
      end
   end
   
   // --------------------------------------------------------------------------
   // Main State Machine: Next state and output decoder
   // --------------------------------------------------------------------------
   always @(*) begin
      main_next_state   = main_curr_state;
      cubusy_o          = 1'b0;
      req_phase_active  = 1'b0;
      resp_phase_active = 1'b0;
      custatus_out_en1   = 1'b0;  
      hprior_abort      = 1'b0;
      
      case(main_curr_state)
        C_IDLE: begin
           if(pord == 1'b1) begin
              main_next_state = C_RESP_PHASE;              
           end
           else if(uctrig_i == 1'b1) begin
              main_next_state = C_REQ_PHASE;              
           end
        end

        C_REQ_PHASE: begin
           cubusy_o     = 1'b1;
           req_phase_active = 1'b1;

           if(uchprior_flushreq_i == 1'b1) begin  
              main_next_state = C_IDLE;
              hprior_abort    = 1'b1;
           end
           else if(!req_phase_done && req_phase_done_d1 && (uclatchcmd_i != 8'hF0)) begin
              main_next_state = C_RESP_PHASE; 
              req_phase_active = 1'b0;  
           end
           else if(!req_phase_done && req_phase_done_d1) begin 
              main_next_state = C_IDLE; 
              req_phase_active = 1'b0;  
           end
        end

        C_RESP_PHASE: begin
           cubusy_o      = 1'b1;
           resp_phase_active = 1'b1;

           if(uchprior_flushreq_i == 1'b1) begin  
              main_next_state = C_IDLE;
              hprior_abort    = 1'b1;
           end
           else if(resp_phase_done_pulse == 1'b1 && set_puf_getkcnum == 1'b0 && reset_puf_getkcnum == 1'b0) begin  
              main_next_state = C_IDLE;
              custatus_out_en1 = 1'b1;               
           end
           else if(resp_phase_done_pulse == 1'b1 && set_puf_getkcnum == 1'b1 && reset_puf_getkcnum == 1'b1) begin  
              main_next_state = C_IDLE;
           end
           else if(cunvm_bfr_iapverify_done == 1'b1) begin   //for NVMDI before IAP Verify
              main_next_state = C_REQ_PHASE;
              resp_phase_active = 1'b0;  
           end
           else if(set_puf_getkcnum == 1'b1 && reset_puf_getkcnum == 1'b0 && resp_curr_state == RESP_IDLE && fctrans_done_i) begin   
              main_next_state = C_REQ_PHASE;
              resp_phase_active = 1'b0;  
           end
        end
        default : main_next_state = C_IDLE;
        
      endcase // case (main_curr_state)      
   end // always @ (*)

   assign custatus_out_en2 = (resp_curr_state == RESP_REG9 || (resp_curr_state == RESP_RDCOMM_DATA && resp_next_state == RESP_IDLE)) & 
                             set_puf_getkcnum & !reset_puf_getkcnum; 
   
   assign custatus_out_en = custatus_out_en1                     || (asynchevent_curr_state == ASYNCEVENT_WAIT) || custatus_out_en2 || 
                            (req_curr_state == REQ_ASYNC_OUT1)   || (req_curr_state == REQ_ASYNC_OUT2); 

   // --------------------------------------------------------------------------
   // cfgrant_o: Generate grant output to the AHB FSM
   // --------------------------------------------------------------------------
   assign cfgrant_o = cfgrant_req | cfgrant_resp | cfgrant_asyncevent; 

   // --------------------------------------------------------------------------
   // Registered signals
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         fctrans_done_d1 <= 1'b0;
         fctrans_done_d2 <= 1'b0;
         fcbusreq_d1     <= 1'b0;         
      end
      else begin
         fctrans_done_d1 <= fctrans_done_i;
         fctrans_done_d2 <= fctrans_done_d1;
         fcbusreq_d1     <= fcbusreq_i;
      end
   end

   // --------------------------------------------------------------------------
   // cfwr_req_d: Write request enable to FSM control logic so that AHB write 
   // cycle is driven
   // --------------------------------------------------------------------------
   always @(*) begin
         if(req_curr_state == REQ_PHASE) begin
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_RDCOMM_STATUS2 && txtokay == 1'b1 && idle_trigger && mchready_i) begin   
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_RDCOMM_STATUS1 && txtokay ) begin 
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG4) begin   
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG2) begin
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG11) begin
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG14) begin   
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG15) begin   
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG1) begin
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG10) begin 
            cfwr_req_d <= 1'b1;
         end
         else if(resp_curr_state == RESP_PHASE) begin
            cfwr_req_d <= 1'b1;
         end
         else if(resp_curr_state == RESP_WRCOMM_CTRL1) begin   
            cfwr_req_d <= 1'b1;
         end
         else if(resp_curr_state == RESP_FIIC_INT) begin   
            cfwr_req_d <= 1'b1;
         end
         else if(resp_curr_state == RESP_RDCOMM_FRM && idle_trigger) begin
            cfwr_req_d <= 1'b1;
         end
         else if(resp_curr_state == RESP_RDCOMM_DESC && idle_trigger && uclatchcmd_i != 8'h28 && unreg_cmd == 1'b0  && 
                 uclatchcmd_i != 8'h2D && uclatchcmd_i != 8'h17  && uclatchcmd_i != 8'h1F && uclatchcmd_i != 8'hF1 && uclatchcmd_i != 8'h14) begin  
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_PHASE) begin
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_MEMWR2) begin
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_MEMWR22) begin  
            cfwr_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_MEMWR1) begin
            cfwr_req_d <= 1'b1;
         end
         else if(asynchevent_curr_state == ASYNCEVENT_WAIT_REG11) begin  
            cfwr_req_d <= 1'b1;
         end
         else if(asynchevent_curr_state == ASYNCEVENT_WAIT_REG13) begin  
            cfwr_req_d <= 1'b1;
         end
         else if(asynchevent_curr_state == ASYNCEVENT_WAIT_REG14) begin  
            cfwr_req_d <= 1'b1;
         end
         else begin
            cfwr_req_d <= 1'b0;
         end
   end // always @ (*)

   // --------------------------------------------------------------------------
   // cfwr_req_o: Write request enable to FSM control logic so that AHB write 
   // cycle is driven
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cfwr_req_o <= 1'b0;
      end
      else begin
         cfwr_req_o <= cfwr_req_d;
      end
   end
   
   // --------------------------------------------------------------------------
   // cfrd_req_d: Read request enable to FSM control logic so that AHB write 
   // cycle is driven
   // --------------------------------------------------------------------------
   always @(*) begin
         if(req_curr_state == REQ_WAIT_REG3) begin
            cfrd_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_REG5) begin
            cfrd_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_ASYNCRD1) begin                 
            cfrd_req_d <= 1'b1;
         end
         else if(req_curr_state == REQ_WAIT_ASYNCRD2) begin  
            cfrd_req_d <= 1'b1;
         end
         else if(asynchevent_curr_state == ASYNCEVENT_REG1) begin  
            cfrd_req_d <= 1'b1;
         end
         else if(asynchevent_curr_state == ASYNCEVENT_WAIT_RD1) begin  
            cfrd_req_d <= 1'b1;
         end
         else begin
            cfrd_req_d <= 1'b0;
         end
   end // always @ (*)

   // --------------------------------------------------------------------------
   // cfrd_req_o: Read request enable to FSM control logic so that AHB write 
   // cycle is driven
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cfrd_req_o <= 1'b0;
      end
      else begin
         cfrd_req_o <= cfrd_req_d;
      end
   end

   // --------------------------------------------------------------------------
   // cfrd_asyncevent_d: Read request enable to FSM control logic so that AHB write 
   // cycle is driven
   // --------------------------------------------------------------------------
   always @(*) begin 
         if(asynchevent_curr_state == ASYNCEVENT_REG1) begin
            cfrd_asyncevent_d <= 1'b1;
         end
         else if(asynchevent_curr_state == ASYNCEVENT_WAIT_RD1) begin
            cfrd_asyncevent_d <= 1'b1;
         end
         else begin
            cfrd_asyncevent_d <= 1'b0;
         end
   end 

   // --------------------------------------------------------------------------
   // cfrd_asyncevent_o: Read request enable to FSM control logic so that AHB write 
   // cycle is driven
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cfrd_asyncevent_o <= 1'b0;
      end
      else begin
         cfrd_asyncevent_o <= cfrd_asyncevent_d;
      end
   end



   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         wait_count <= 3'b000;
      end
      else begin
         if(!mchready_i) begin
            wait_count <= wait_count;
         end           
         else if((req_curr_state == REQ_WAIT_REG6 || req_curr_state == REQ_RDCOMM_STATUS2) && 
                 mchready_i) begin
            wait_count <= wait_count + 1'b1;
         end
         else begin
            wait_count <= 3'b000;
         end
      end
   end

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         tamper_detect_valid_r <= 1'b0;
         tamper_fail_valid_r   <= 1'b0;
         set_sent_options_r    <= 1'b0;        
         memwr_data_addr_r     <= 32'h0; 
         fcdataout_d1          <= 32'h0; 
         set_puf_getkcnum_r    <= 1'b0;        
      end
      else begin
         tamper_detect_valid_r <= tamper_detect_valid;
         tamper_fail_valid_r   <= tamper_fail_valid;
         set_sent_options_r    <= set_sent_options;         
         memwr_data_addr_r     <= memwr_data_addr; 
         fcdataout_d1          <= fcdataout_i; 
         set_puf_getkcnum_r    <= set_puf_getkcnum;  
      end
   end
   
   // Tamper async event outputs to User IF
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cutamper_detect_valid <= 1'b0;
         cutamper_fail_valid   <= 1'b0;
      end
      else begin
         cutamper_detect_valid <= tamper_detect_valid;
         cutamper_fail_valid   <= tamper_fail_valid;
      end
   end

   // --------------------------------------------------------------------------
   /////////////////////////////////////////////////////////////////////////////
   //                                                                         //
   //        |||||  ||||| ||||||         |||||| |||||| ||\  /||               //
   //        || ||  ||    ||  ||         ||     ||     ||\\//||               //
   //        ||_||  ||||  ||  ||   ==    ||||   |||||| || \/ ||               //
   //        || \\  ||    ||  ||         ||         || ||    ||               //
   //        ||  \\ ||||| ||||\\         ||     |||||| ||    ||               //
   //                                                                         //
   /////////////////////////////////////////////////////////////////////////////
   // --------------------------------------------------------------------------    

   // --------------------------------------------------------------------------
   // Request Phase State Machine
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         req_curr_state <= REQ_IDLE;
      end
      else if(uchprior_flushreq_i == 1'b1) begin  
         req_curr_state <= REQ_IDLE;
      end
      else begin
         req_curr_state <= req_next_state;
      end
   end
   
   // --------------------------------------------------------------------------
   // Request Phase: Next state and output decoder
   // --------------------------------------------------------------------------
   always @(*) begin
      req_next_state = req_curr_state;
      cfgrant_req    = 1'b0;
      req_phase_done = 1'b0;
      req_dstreg_addr = 32'h0;
      req_dstreg_data = 32'h0;
      cfcommaccess_active = 1'b0;      
      fiicreg_done     = 1'b0;
      commctrlreg_done = 1'b0;
      commpoll_done    = 1'b0;      
      tamper_detect_valid = tamper_detect_valid_r;
      tamper_fail_valid   = tamper_fail_valid_r;      
      set_sent_options    = set_sent_options_r;              
      
      case(req_curr_state)
        REQ_IDLE: begin  
           if(req_phase_active && do_mem_wr && !asyncevent_active) begin  
              req_next_state = REQ_WAIT_MEMWR1;
           end
           else if(req_phase_active && !do_mem_wr && !asyncevent_active) begin  
              req_next_state = REQ_PHASE;         
           end
           tamper_detect_valid = 1'b0;
           tamper_fail_valid   = 1'b0;      
        end
        REQ_WAIT_MEMWR1: begin
           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_MEMWR_DESC;
           end
        end
        REQ_MEMWR_DESC: begin
           cfgrant_req = 1'b1;

           if(fctrans_done_i == 1'b1) begin
              if(datawr_reqd == 1'b1) begin
                 req_next_state = REQ_WAIT_MEMWR2;
              end
              else begin
                 req_next_state = REQ_PHASE;
              end
           end
        end
        REQ_WAIT_MEMWR2: begin
           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_MEMWR_DATA;
           end
        end
        REQ_MEMWR_DATA: begin
           cfgrant_req = 1'b1;

           if(fctrans_done_i == 1'b1 && uclatchcmd_i == 8'h10) begin
              req_next_state = REQ_WAIT_MEMWR22;  // For Elliptic Curve
           end
           else if(fctrans_done_i == 1'b1 && uclatchcmd_i == 8'h11) begin
              req_next_state = REQ_WAIT_MEMWR22;  // For Elliptic Curve
           end
           else if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_PHASE;
           end
        end
        REQ_WAIT_MEMWR22: begin    // For Elliptic Curve
           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_MEMWR_DATA1;
           end
        end
        REQ_MEMWR_DATA1: begin    // For Elliptic Curve
           cfgrant_req = 1'b1;

           if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_PHASE;
           end
        end
        REQ_PHASE: begin
           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_FIIC_INT;     
           end
        end
        REQ_FIIC_INT: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40006000;
           req_dstreg_data = 32'h20000000;
           fiicreg_done    = 1'b1;
           
           if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_WAIT_REG1;
           end
        end

        REQ_WAIT_REG1: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           fiicreg_done     = fiicreg_done_d1;
           commctrlreg_done = commctrlreg_done_d1;
           commpoll_done    = commpoll_done_d1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_WRCOMM_CTRL;
           end

        end

        REQ_WRCOMM_CTRL: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016000;
           req_dstreg_data = 32'h00000010;
           commctrlreg_done = 1'b1;

           if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_WAIT_REG2;
           end
        end
        
        REQ_WAIT_REG2: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_WRCOMM_INT;
           end

        end

        // Set interrupt mask for TXTOKAY+CMD+RCVOKAY bit only
        REQ_WRCOMM_INT: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016008;
           req_dstreg_data = 32'h00000083; // TXTOKAY+CMD+RCVOKAY bit only

           if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_POLL_CINT1; 
           end
        end

        // Poll for COMM_BLK interrupt
        REQ_POLL_CINT1: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           commpoll_done = 1'b1;
           if(uccommblk_int_i == 1'b1 && idle_trigger) begin  // to sync with AHB FS
              req_next_state = REQ_WAIT_REG3;
           end
        end
        
        REQ_WAIT_REG3: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_RDCOMM_STATUS1;
           end

        end

        REQ_RDCOMM_STATUS1: begin
           cfgrant_req = 1'b1;           
           req_dstreg_addr = 32'h40016004;
           cfcommaccess_active = 1'b1;


           if(txtokay == 1'b1 && idle_trigger) begin   // reversed the if and else conditions
              req_next_state = REQ_WAIT_REG4;
           end
           else if((cmdrcv == 1'b1 && rcvokay == 1'b1) && idle_trigger) begin  
              req_next_state = REQ_WAIT_ASYNCRD1;
           end
        end
        
        // ------------------------------------------------
        // v3.0 - To read the async message event. First read the command and then see if it async event 
        // and report
        REQ_WAIT_ASYNCRD1: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_RDCOMM_ASYNCFRM1;
           end

        end

        REQ_RDCOMM_ASYNCFRM1: begin
           cfgrant_req = 1'b1;           
           req_dstreg_addr = 32'h40016018;
           cfcommaccess_active = 1'b1;
           if(fctrans_done_i == 1'b1 &&                   
              ( ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'h80) && (fcdataout_d1[7:0] <= 8'hA0)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'hB0) && (fcdataout_d1[7:0] <= 8'hB7)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE0 ))                                ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE1 )) 
                )) begin 
              req_next_state = REQ_ASYNC_OUT1;
           end  
           else if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_WAIT_REG4;  
           end
         end

        REQ_ASYNC_OUT1: begin
           cfgrant_req = 1'b1;           
           cfcommaccess_active = 1'b1;
           req_next_state = REQ_POLL_CINT1;
         end
        
        REQ_WAIT_REG4: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_WRCOMM_FRM;
           end
        end

        // Write Command byte - Request Command
        REQ_WRCOMM_FRM: begin       
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016018;
	   if(set_puf_getkcnum == 1'b1) begin  
              req_dstreg_data = {24'h000000,8'h1A};
           end
	   else begin
              req_dstreg_data = {24'h000000,uclatchcmd_i};
	   end

           if(idle_trigger == 1'b1) begin  
              if(uclatchcmd_i == 8'h28 || uclatchcmd_i == 8'h2D) begin   
                 req_next_state = REQ_WAIT_REG11;
              end
              else begin
                 req_next_state = REQ_POLL_CINT2;
              end
           end
        end
        
        // Poll for COMM_BLK interrupt
        REQ_POLL_CINT2: begin
           cfgrant_req = 1'b1;           
           cfcommaccess_active = 1'b1;

           if(uccommblk_int_i == 1'b1 && idle_trigger) begin  
              req_next_state = REQ_WAIT_REG5;
           end
        end
        
        REQ_WAIT_REG5: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_RDCOMM_STATUS2;
           end

        end

        // Check whether TXTOKAY bit is set in the COMM_BLK status 
        // register
        REQ_RDCOMM_STATUS2: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016004;
           if(txtokay == 1'b1 && idle_trigger && mchready_i) begin
              req_next_state = REQ_WAIT_REG6;
           end
           else if((cmdrcv == 1'b1 && rcvokay == 1'b1) && idle_trigger && mchready_i) begin 
              req_next_state = REQ_WAIT_ASYNCRD2;
           end
        end

        // To read the async message event. First read the command and then see if it async event 
        // and report
        REQ_WAIT_ASYNCRD2: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_RDCOMM_ASYNCFRM2;
           end

        end

        REQ_RDCOMM_ASYNCFRM2: begin
           cfgrant_req = 1'b1;           
           req_dstreg_addr = 32'h40016018;
           cfcommaccess_active = 1'b1;
           if(fctrans_done_i == 1'b1 &&                   
              ( ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'h80) && (fcdataout_d1[7:0] <= 8'hA0)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'hB0) && (fcdataout_d1[7:0] <= 8'hB7)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE0 ))                                ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE1 )) 
                )) begin 
              req_next_state = REQ_ASYNC_OUT2;
           end           
           else if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_POLL_CINT2;
           end
         end

        REQ_ASYNC_OUT2: begin
           cfgrant_req = 1'b1;           
           cfcommaccess_active = 1'b1;
           req_next_state = REQ_POLL_CINT2;
         end

        REQ_WAIT_REG6: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1 && set_sent_options == 1'b1) begin               
              req_next_state = REQ_WRCOMM_DATA;
           end
           else if(fcbusreq_d1 == 1'b1) begin          
              req_next_state = REQ_WRCOMM_CTRL2;
           end

        end
        
        REQ_WRCOMM_CTRL2: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016000;
           if(uclatchcmd_i == 8'h2C) begin
              req_dstreg_data = 32'h00000010;
           end
           else if(uclatchcmd_i == 8'h14 || uclatchcmd_i == 8'h17) begin   
              req_dstreg_data = 32'h00000010;
           end
           else begin
              req_dstreg_data = 32'h00000014;
           end
           commctrlreg_done = 1'b1;

           if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_WAIT_REG10; 
           end
        end
        REQ_WAIT_REG10: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
                req_next_state = REQ_WRCOMM_DATA;
           end

        end

        // Send descriptor pointer
        REQ_WRCOMM_DATA: begin
           cfgrant_req    = 1'b1;
           cfcommaccess_active = 1'b1;
           if(uclatchcmd_i == 8'h2C) begin
             req_dstreg_addr = 32'h40016010;
           end
           else if(uclatchcmd_i == 8'h14 || uclatchcmd_i == 8'h17) begin    
             req_dstreg_addr = 32'h40016010;
           end
           else begin
             req_dstreg_addr = 32'h40016014;
           end

           if(uclatchcmd_i == 8'h02 || uclatchcmd_i == 8'h17 || uclatchcmd_i == 8'h1F) begin  
              req_dstreg_data = {{26{1'b0}},uclatchoptions_i};  // Send options
           end
           else if(uclatchcmd_i == 8'h14) begin     
              req_dstreg_data = {{26{1'b0}},uclatchoptions_i};  // Send options
              set_sent_options = 1'b1;              
           end
           else if(uclatchcmd_i == 8'h2C) begin   // Send Handle for Uninstatiate service
              req_dstreg_data = {{24{1'b0}},ucnrbg_handle_i};
           end
           else begin
              req_dstreg_data = memwr_desc_addr;  // Send descriptor
              set_sent_options = 1'b0;              
           end

           if(fctrans_done_d1 == 1'b1 && uclatchcmd_i == 8'h14) begin        
              req_next_state = REQ_WAIT_REG15 ;   
           end
           else if(fctrans_done_d1 == 1'b1) begin        
              req_next_state = REQ_WAIT_REG14 ;   
           end
        end

        REQ_WAIT_REG15: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           commctrlreg_done = commctrlreg_done_d1;           

           if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_WRCOMM_CTRL3;
           end

        end

        REQ_WRCOMM_CTRL3: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016000;
           req_dstreg_data = 32'h00000014;
           commctrlreg_done = 1'b1;

           if(fctrans_done_i == 1'b1) begin
              req_next_state = REQ_WAIT_REG11;
           end
        end
        
        REQ_WAIT_REG11: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;

           if(fcbusreq_d1 == 1'b1 && uclatchcmd_i == 8'h14) begin    
              req_next_state = REQ_WRCOMM_DESC2;
           end
           else if(fcbusreq_d1 == 1'b1) begin        
              req_next_state = REQ_WRCOMM_INT2;
           end

        end

        // Send the SPIADDR
        // only CMDRCV and RCVOKAY  
        REQ_WRCOMM_DESC2: begin   
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016014;
           req_dstreg_data = ucspiaddr_i;   

           if(fctrans_done_d1 == 1'b1) begin
              req_next_state = REQ_WAIT_REG14;
           end
        end

        REQ_WAIT_REG14: begin   
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           
	   if(fcbusreq_d1 == 1'b1) begin
              req_next_state = REQ_WRCOMM_INT2;
           end

        end

        // Set interrupt register to mask 
        // only CMDRCV and RCVOKAY
        REQ_WRCOMM_INT2: begin
           cfgrant_req = 1'b1;
           cfcommaccess_active = 1'b1;
           req_dstreg_addr = 32'h40016008;
           req_dstreg_data = 32'h00000082;  
           req_phase_done = 1'b1; 

           if(fctrans_done_d1 == 1'b1) begin
              req_next_state = REQ_IDLE;
           end
        end

        default: req_next_state = REQ_IDLE;
      endcase // case (req_curr_state)
   end // always @ (*)


   /////////////////////////////////////////////////////////////////////////////
   // Memory write data logic signals                                         //
   /////////////////////////////////////////////////////////////////////////////

   // --------------------------------------------------------------------------
   // cudata_wrdy_o: It is used to request for the write data from the
   // user logic.
   // --------------------------------------------------------------------------
   assign cudata_wrdy_int = fcpop_i & (req_curr_state == REQ_MEMWR_DATA | req_curr_state == REQ_MEMWR_DATA1);    

   // --------------------------------------------------------------------------
   // Delayed signals
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         fcpop_d1            <= 1'b0;
         fiicreg_done_d1     <= 1'b0;  
         commctrlreg_done_d1 <= 1'b0;  
         commpoll_done_d1    <= 1'b0;        
         cudata_wrdy_o       <= 1'b0;        
      end
      else begin
         fcpop_d1            <= fcpop_i;
         fiicreg_done_d1     <= fiicreg_done;
         commctrlreg_done_d1 <= commctrlreg_done;
         commpoll_done_d1    <= commpoll_done;
         cudata_wrdy_o       <= cudata_wrdy_int;
      end
   end

   // --------------------------------------------------------------------------
   // desc_datasel_cntr: Used to select descriptor data word-wise for service
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         desc_datasel_cntr  <= 'h0;
      end
      else begin
         if(req_curr_state != REQ_MEMWR_DESC) begin
            desc_datasel_cntr <= 'h0;
         end
         else if(fcpop_d1 == 1'b1 && req_curr_state == REQ_MEMWR_DESC) begin
            desc_datasel_cntr <= desc_datasel_cntr + 1;
         end
      end
   end

   // --------------------------------------------------------------------------
   // memwr_desc: Construct the write descriptor for each service which is to be
   // written to eSRAM memory space
   // --------------------------------------------------------------------------
   always @(*) begin
      if(ucvalid_cmd_i == 1'b1) begin
         case(uclatchcmd_i_mux)   
           8'h03: begin   // AES128 services
              memwr_desc = {{128{1'b0}},CRYPTOSRCADPTR,CRYPTODSTADPTR,8'h00,uccrypto_mode_i,uccrypto_nblocks_i,uccrypto_iv_i,uccrypto_key_i[127:0]}; 
           end
           8'h06: begin   // AES256 services
              memwr_desc = {CRYPTOSRCADPTR,CRYPTODSTADPTR,8'h00,uccrypto_mode_i,uccrypto_nblocks_i,uccrypto_iv_i,uccrypto_key_i};
           end
           8'h0A: begin   // SHA256 services
              memwr_desc = {{384{1'b0}},CRYPTODATAINPPTR,CRYPTORSLTPTR,uccrypto_length_i};
           end
           8'h0C: begin   // HMAC services
              memwr_desc = {{128{1'b0}},CRYPTORSLTPTR,CRYPTODATAINPPTR,uccrypto_length_i,uccrypto_key_i};
           end
           8'h09: begin  // Key Tree services
              memwr_desc = {{88{1'b0}},ucdpa_path_i,ucdpa_optype_i,ucdpa_key_i};
           end
           8'h0E: begin  // Challenge services
              memwr_desc = {{312{1'b0}},ucdpa_path_i,ucdpa_optype_i,CHRESPKEYADDR};
           end
           8'h29: begin  // Instantiate services
              memwr_desc = {{424{1'b0}},ucnrbg_handle_i,8'h00,ucnrbg_length_i,NRBGPERSTRINGPTR};
           end
           8'h2A: begin  // Generate services
              memwr_desc = {{384{1'b0}},ucnrbg_handle_i,ucnrbg_prreq_i,ucnrbg_addlength_i,ucnrbg_length_i,NRBGADDINPPTR,NRBGREQDATAPTR};
           end
           8'h2B: begin  // Reseed services
              memwr_desc = {{432{1'b0}},ucnrbg_handle_i,ucnrbg_addlength_i,NRBGADDINPPTR};
           end
           8'h10: begin  // v3.0 - Elliptic Curve
              memwr_desc = {{384{1'b0}},ECCPMULTQPTR,ECCPMULTPPTR,ECCPMULTDPTR};  
           end
           8'h11: begin  // v3.0 - Elliptic Curve
              memwr_desc = {{384{1'b0}},ECCPADDRPTR,ECCPADDQPTR,ECCPADDPPTR};              
           end
           8'h19: begin  // v3.0 - PUFUSERAC 
              memwr_desc = {{472{1'b0}},ucpuf_subcmd_i};               
           end
           8'h1A: begin  // v3.0 - PUFUSERKC 
	      if(set_puf_getkcnum == 1'b1) begin  
                 memwr_desc = {{392{1'b0}},ucpuf_keysize_i,ucpuf_inkeynum_i,ucpuf_userextrkeyaddr_i,ucpuf_userkeyaddr_i,8'h00};              
              end
	      else begin
                 memwr_desc = {{392{1'b0}},ucpuf_keysize_i,ucpuf_inkeynum_i,ucpuf_userextrkeyaddr_i,ucpuf_userkeyaddr_i,ucpuf_subcmd_i};              
              end
           end
           8'h1B: begin  // v3.0 - PUFUSERKEY 
              memwr_desc = {{440{1'b0}},ucpuf_inkeynum_i,ucpuf_userkeyaddr_i};              
           end
           8'h1C: begin  // v3.0 - PUFPUBLICKEY 
              memwr_desc = {{448{1'b0}},PUFPUBLICKEYADDR};              
           end
           8'h1D: begin  // v3.0 - PUFSEED 
              memwr_desc = {{448{1'b0}},PUFSEEDADDR};              
           end
           default: begin
              memwr_desc = {480{1'b0}};
           end

         endcase // case (uclatchcmd_i)
      end // if (uctrig_i == 1'b1)
      else begin
         memwr_desc = {480{1'b0}};
      end
   end


   // --------------------------------------------------------------------------
   // memwr_desc_int: This the descriptor data to be written in to external
   // memory every AHB write cycle.
   // --------------------------------------------------------------------------
   always @(*) begin
      case(desc_datasel_cntr)

        'h0: memwr_desc_int = memwr_desc[31:0];
        'h1: memwr_desc_int = memwr_desc[63:32];
        'h2: memwr_desc_int = memwr_desc[95:64];
        'h3: memwr_desc_int = memwr_desc[127:96];
        'h4: memwr_desc_int = memwr_desc[159:128];
        'h5: memwr_desc_int = memwr_desc[191:160];
        'h6: memwr_desc_int = memwr_desc[223:192];
        'h7: memwr_desc_int = memwr_desc[255:224];
        'h8: memwr_desc_int = memwr_desc[287:256];
        'h9: memwr_desc_int = memwr_desc[319:288];
        'hA: memwr_desc_int = memwr_desc[351:320];
        'hB: memwr_desc_int = memwr_desc[383:352];
        'hC: memwr_desc_int = memwr_desc[415:384];
        'hD: memwr_desc_int = memwr_desc[447:416];
        'hE: memwr_desc_int = memwr_desc[479:448];
        default: memwr_desc_int = 32'h00000000;
      endcase
   end

   
   // --------------------------------------------------------------------------
   // cfdatain_o: Write data to FSM Control.block
   // It is the AHB Master write data. It is selected only when write valid.
   // --------------------------------------------------------------------------
   always @(*) begin
      // external memory write data
      if(req_curr_state == REQ_MEMWR_DATA || req_curr_state == REQ_MEMWR_DATA1) begin   
         cfdatain_o = ucdata_w_i;
      end
      // external memory write descriptor
      else if(cudata_wrdy_d1 && (req_curr_state == REQ_MEMWR_DESC  || 
                                 req_curr_state == REQ_PHASE       || 
                                 req_curr_state == REQ_WAIT_MEMWR2 || 
                                 req_curr_state == REQ_WAIT_MEMWR22)) begin
         cfdatain_o = memwr_desc_int;
      end
      // write to COMM_BLK -->
      else if(fcpop_i && req_curr_state == REQ_FIIC_INT) begin
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_CTRL) begin
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_CTRL2) begin  
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_CTRL3) begin    
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && resp_curr_state == RESP_FIIC_INT) begin  
         cfdatain_o = resp_srcreg_data;
      end
      else if(fcpop_i && resp_curr_state == RESP_WRCOMM_INT3) begin  
         cfdatain_o = resp_srcreg_data;
      end
      else if(fcpop_i && resp_curr_state == RESP_WRCOMM_CTRL1) begin 
         cfdatain_o = resp_srcreg_data;
      end
      else if(fcpop_i && resp_curr_state == RESP_WRCOMM_CTRL2) begin 
         cfdatain_o = resp_srcreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_INT) begin
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_INT2) begin
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_DESC2) begin   
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_FRM) begin
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && req_curr_state == REQ_WRCOMM_DATA) begin
         cfdatain_o = req_dstreg_data;
      end
      else if(fcpop_i && asynchevent_curr_state == ASYNCEVENT_WRCOMM_CTRL1) begin    
         cfdatain_o = asyncevent_dstreg_data;
      end
      else if(fcpop_i && asynchevent_curr_state == ASYNCEVENT_FIIC_INT) begin 
         cfdatain_o = asyncevent_dstreg_data;
      end
      else if(fcpop_i && asynchevent_curr_state == ASYNCEVENT_WRCOMM_INT3) begin 
         cfdatain_o = asyncevent_dstreg_data;
      end
      else begin
         cfdatain_o = cfdatain_d1;
      end
      
   end   

   // --------------------------------------------------------------------------
   // cudata_wrdy_d1: Registered cudata_wrdy_o
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cudata_wrdy_d1 <= 1'b0;
         cfdatain_d1    <= 32'h00000000;
      end
      else begin
         cudata_wrdy_d1 <= fcpop_i;
         cfdatain_d1    <= cfdatain_o;
      end
   end
   
   // --------------------------------------------------------------------------
   // Nov 13
   // unreg_cmd: This signal is generated to indicate that an unrecognised
   // command response has been received from the System Controller
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         unreg_cmd <= 1'b0;
      end
      else begin
         if(resp_curr_state == RESP_IDLE) begin
            unreg_cmd <= 1'b0;
         end
         else if(resp_curr_state == RESP_RDCOMM_DESC && resp_next_state == RESP_RDCOMM_DESC && fcdataout_i == 8'hFC) begin
            unreg_cmd <= 1'b1;
         end
      end
   end



   /////////////////////////////////////////////////////////////////////////////
   // Memory read data logic signals                                          //
   /////////////////////////////////////////////////////////////////////////////

   // --------------------------------------------------------------------------
   // cudata_r_o: Send the read data back to the user logic through Cmd Dec
   // --------------------------------------------------------------------------
   always @(*) begin
     cudata_r_int <= fcdataout_i;
   end

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cudata_r_o <= 32'h00000000;
      end
      else begin
         cudata_r_o <= cudata_r_int;
      end
   end

   // --------------------------------------------------------------------------
   // cudata_rvalid_int: intermediate rvalid for read data from memory
   // --------------------------------------------------------------------------
   assign cudata_rvalid_int = (rd_active & rvalid_out_en) | 
                              (resp_data_done_d1 & !resp_data_done & do_mem_rd); 
   
   // --------------------------------------------------------------------------
   // cudata_rvalid_o: Send the read data valid back to the user logic thru' 
   // the Cmd Dec. 
   // This indicates the ravalid for the data read from the eSRAM memory.
   // --------------------------------------------------------------------------
   assign cudata_rvalid_int2 = rvalid_out_en & rd_active; 

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cudata_rvalid_o <= 1'b0;
      end
      else begin
         cudata_rvalid_o <= cudata_rvalid_int2 && !cucmd_error;   
      end
   end

   // --------------------------------------------------------------------------
   // custatus_valid_o: Send the status valid back to the user logic thru' 
   // the Cmd Dec. 
   // This indicates that the received response data from COMM_BLK is valid.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         custatus_valid_o <= 1'b0;
      end
      else begin

         if((resp_curr_state == RESP_RDCOMM_DESC && resp_next_state == RESP_RDCOMM_DESC && mchready_i == 1'b1 ) || 
     		 (resp_curr_state == RESP_RDCOMM_DESC && resp_next_state == RESP_RDCOMM_DESC && mchready_i == 1'b1 && 
             (uclatchcmd_i == 8'h17 || uclatchcmd_i == 8'h28 || 
	      uclatchcmd_i == 8'h1F || uclatchcmd_i == 8'h14 ||   
              uclatchcmd_i == 8'h2D || uclatchcmd_i == 8'hF1))) begin
            custatus_valid_o <= 1'b1;
         end
         else begin
            custatus_valid_o <= 1'b0;
         end
      end
   end // always @ (posedge clk or negedge resetn)

   assign latchen_hrdata_int = (resp_curr_state == RESP_RDCOMM_DESC & mchready_i & 
                          (uclatchcmd_i == 8'h17 || uclatchcmd_i == 8'h28 || uclatchcmd_i == 8'h1F || uclatchcmd_i == 8'h14 ||   
                           uclatchcmd_i == 8'h2D || uclatchcmd_i == 8'hF1));
  
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         latchen_hrdata_r <= 1'b0;
      end
      else begin
         latchen_hrdata_r <= latchen_hrdata_int;         
      end
   end

   assign latchen_hrdata = !latchen_hrdata_r & latchen_hrdata_int;
   
   // --------------------------------------------------------------------------
   // cutamper_msg_valid: Send the tamper message valid back to the user logic thru' 
   // the Cmd Dec. 
   // This indicates that the received response data from COMM_BLK is valid.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cutamper_msg_valid <= 1'b0;
      end
      else begin
         if(((asynchevent_curr_state == ASYNCEVENT_RDCOMM_FRM1 && asynchevent_next_state == ASYNCEVENT_RDCOMM_OUT1)  || 
             (req_curr_state  == REQ_ASYNC_OUT1 ) || (req_curr_state  == REQ_ASYNC_OUT2)                 ||   
             (resp_curr_state == RESP_RDCOMM_ASYNCFRM1 && resp_next_state == RESP_ASYNC_OUT1)  || 
             (resp_curr_state == RESP_RDCOMM_ASYNCFRM3 && resp_next_state == RESP_ASYNC_OUT3)  || 
             (resp_curr_state  == RESP_REG7 && 
             (uclatchcmd_i == 8'h17 || uclatchcmd_i == 8'h28 || uclatchcmd_i == 8'h1F || uclatchcmd_i == 8'h14 ||  
              uclatchcmd_i == 8'h2D || uclatchcmd_i == 8'hF1))) && TAMPERDETECTSERVICE) begin  
            cutamper_msg_valid <= 1'b1;
         end
         else begin
            cutamper_msg_valid <= 1'b0;
         end
      end
   end

   // --------------------------------------------------------------------------
   // cutamper_msg: Send the tamper message back to the user logic thru' 
   // the Cmd Dec. 
   // This indicates that the received response data from COMM_BLK.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cutamper_msg <= 8'h0;
      end
      else begin
         if(((asynchevent_curr_state == ASYNCEVENT_RDCOMM_FRM1 && asynchevent_next_state == ASYNCEVENT_RDCOMM_OUT1)  ||
             (req_curr_state  == REQ_ASYNC_OUT1 ) || (req_curr_state  == REQ_ASYNC_OUT2)                 || 
             (resp_curr_state == RESP_RDCOMM_ASYNCFRM1 && resp_next_state == RESP_ASYNC_OUT1 ) || 
	     (resp_curr_state == RESP_RDCOMM_ASYNCFRM3 && resp_next_state == RESP_ASYNC_OUT3) ||  
             (resp_curr_state  == RESP_REG7 && 
             (uclatchcmd_i == 8'h17 || uclatchcmd_i == 8'h28 || uclatchcmd_i == 8'h1F || uclatchcmd_i == 8'h14 ||  
              uclatchcmd_i == 8'h2D || uclatchcmd_i == 8'hF1))) && TAMPERDETECTSERVICE) begin  
            cutamper_msg <= cudata_r_o[7:0];
         end
      end
   end


   always @(posedge clk or negedge resetn) begin  
      if(resetn == 1'b0) begin
         cunvm_bfr_iapverify_done <= 1'b0;
      end
      else begin
         if(resp_next_state == RESP_REG9 && ucnvm_bfr_iapverify == 1'b1) begin
            cunvm_bfr_iapverify_done <= 1'b1;
         end
         else if(ucnvm_bfr_iapverify == 1'b0) begin   
            cunvm_bfr_iapverify_done <= 1'b0;
         end
      end // else: !if(resetn == 1'b0)
   end // always @ (posedge clk or negedge resetn)
   
   // --------------------------------------------------------------------------
   // rdcommstatus_valid: Valid indicator for checking the status register for
   // rcvokay/txtokay/cmdrcv bits.
   // --------------------------------------------------------------------------
   assign rdcommstatus_valid = fcpush_i &  (resp_curr_state == RESP_RDCOMM_STATUS);

   // --------------------------------------------------------------------------
   // cmdrcv: Determine whether 'cmdrcv' bit is set after read from status
   // register. 
   // --------------------------------------------------------------------------
   assign cmdrcv_bit  = fcdataout_i[7];
   assign cmdrcv_c  = mchready_i ? (cmdrcv_bit  == 1'b1) : cmdrcv; 

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cmdrcv <= 1'b0;
      end
      else begin
         cmdrcv <= cmdrcv_c;
      end
   end

   // --------------------------------------------------------------------------
   // rcvokay: Determine whether 'rcvokay' bit is set after read from status
   // register. 
   // --------------------------------------------------------------------------
   assign rcvokay_bit = fcdataout_i[1];
   assign rcvokay_c = mchready_i ? (rcvokay_bit == 1'b1) : rcvokay; 


   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         rcvokay <= 1'b0;
      end
      else begin
         rcvokay <= rcvokay_c;
      end
   end

   // --------------------------------------------------------------------------
   // txtokay: Determine whether 'txtokay' bit is set after read from status
   // register. 
   // --------------------------------------------------------------------------
   assign txtokay_bit = fcdataout_i[0];
   assign txtokay_c = mchready_i ? (txtokay_bit == 1'b1) : txtokay;

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         txtokay <= 1'b0;
         resp_srcreg_addr_d1 <= 32'h00000000;         
         resp_srcreg_data_d1 <= 32'h00000000;         
         cmd_error_d1        <= 1'b0;  
         cunvm_bfr_iapverify_done_d1 <= 1'b0;  
      end
      else begin
         txtokay <= txtokay_c;
         resp_srcreg_addr_d1 <= resp_srcreg_addr;
         resp_srcreg_data_d1 <= resp_srcreg_data;
         cmd_error_d1        <= cmd_error;
         cunvm_bfr_iapverify_done_d1 <= cunvm_bfr_iapverify_done;         
      end
   end

   //--------------------------------------------------------------------
   // cucmd_error: Command Error
   //--------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cucmd_error        <= 1'b0;         
      end
      else begin
         if(cubusy_o == 1'b0) begin // v3.1 - Apr23
            cucmd_error        <= 1'b0;         
         end
         else if(cmd_error == 1'b1) begin
           cucmd_error        <= 1'b1;
         end
      end
   end

   // v3.1 --->
   //--------------------------------------------------------------------
   // FLASH_FREEZE: Component instance
   //--------------------------------------------------------------------
   FLASH_FREEZE FLASH_FREEZE_0(
        // Outputs
        .FF_TO_START ( FF_TO_START ),
        .FF_DONE     ( FF_DONE ) 
        );

   // --------------------------------------------------------------------------
   // FF_entry: Determine whether "E0" is set after read from FRM8 register
   // --------------------------------------------------------------------------
   assign FF_entry_bit = (fcdataout_i[7:0] == 8'hE0);
   assign FF_entry_c   = mchready_i ? (FF_entry_bit == 1'b1) : FF_entry;  

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         FF_entry <= 1'b0;
      end
      else begin
         FF_entry <= FF_entry_c;
      end
   end

   // Only for validation purpose
   always @(posedge clk or negedge resetn) begin  
      if(resetn == 1'b0) begin
         FF_entry_led <= 1'b0;
      end
      else begin
         //if(FF_entry == 1'b1) begin
         if(FF_TO_START == 1'b1) begin
           FF_entry_led <= 1'b1;
         end	
      end
   end
   
   // Only for validation purpose
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         FF_exit_led <= 1'b1;
      end
      else begin  
         //if(FF_exit == 1'b1) begin
         if(FF_DONE == 1'b1) begin
           FF_exit_led <= 1'b0;
         end	
      end
   end  

   // --------------------------------------------------------------------------
   // FF_exit: Determine whether "E1" is set after read from FRM8 register
   // --------------------------------------------------------------------------
   assign FF_exit_bit = (fcdataout_i[7:0] == 8'hE1);
   assign FF_exit_c   = mchready_i ? (FF_exit_bit == 1'b1) : FF_exit;

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         FF_exit <= 1'b0;
      end
      else begin
         FF_exit <= FF_exit_c;
      end
   end

   // --------------------------------------------------------------------------
   /////////////////////////////////////////////////////////////////////////////
   //                                                                         //
   //        |||||  ||||| |||||| ||||||         |||||| |||||| ||\  /||        //
   //        || ||  ||    ||     ||  ||         ||     ||     ||\\//||        //
   //        ||_||  ||||  |||||| ||||||   ==    ||||   |||||| || \/ ||        //
   //        || \\  ||        || ||             ||         || ||    ||        //
   //        ||  \\ ||||| |||||| ||             ||     |||||| ||    ||        //
   //                                                                         //
   /////////////////////////////////////////////////////////////////////////////
   // --------------------------------------------------------------------------

   // --------------------------------------------------------------------------
   // Response Phase State Machine
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         resp_curr_state <= RESP_IDLE;
      end
      else if(uchprior_flushreq_i == 1'b1) begin  // v3.0 - For Zeroization 
         resp_curr_state <= RESP_IDLE;
      end
      else begin
         resp_curr_state <= resp_next_state;
      end
   end

   // --------------------------------------------------------------------------
   // Response Phase: Next state and output decoder
   // --------------------------------------------------------------------------
   always @(*) begin
      resp_next_state          = resp_curr_state;
      cfgrant_resp             = 1'b0;
      cfrd_resp_o              = 1'b0;
      resp_srcreg_addr         = resp_srcreg_addr_d1;
      resp_srcreg_data         = resp_srcreg_data_d1;
      resp_phase_done          = 1'b0;
      cfcommaccess_resp_active = 1'b0;
      rd_active                = 1'b0;
      cmd_error                = cmd_error_d1;              
      
      case(resp_curr_state)
   
        RESP_IDLE: begin
           cmd_error       = 1'b0;             
           if(resp_phase_active_pulse == 1'b1 && asyncevent_active == 1'b0) begin  
              resp_next_state = RESP_PHASE;     
           end
        end

        RESP_PHASE: begin
           cfcommaccess_resp_active = 1'b1;
           resp_next_state = RESP_WAIT_REG11;  
        end

        RESP_WAIT_REG11: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_WRCOMM_CTRL1;
           end

        end
        RESP_WRCOMM_CTRL1: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016000;
           resp_srcreg_data = 32'h00000010;

           if(fctrans_done_i == 1'b1) begin
              resp_next_state = RESP_WAIT_REG13;  
           end
        end
 
        // Mar12: Added for PoR --------------
        RESP_WAIT_REG13: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_FIIC_INT;
           end

        end
        
        RESP_FIIC_INT: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40006000;
           resp_srcreg_data = 32'h20000000;

           if(fctrans_done_i == 1'b1) begin
              resp_next_state = RESP_WAIT_REG14; 
           end
        end

        RESP_WAIT_REG14: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_WRCOMM_INT3;
           end
        end

        RESP_WRCOMM_INT3: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016008;
           resp_srcreg_data = 32'h00000082;  

           if(fctrans_done_i == 1'b1) begin
              resp_next_state = RESP_POLL_CINT1; 
           end
        end

        RESP_POLL_CINT1: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(uccommblk_int_i == 1'b1 && idle_trigger) begin  
              resp_next_state = RESP_REG1;

              cfrd_resp_o    = 1'b1;
           end
        end

        RESP_REG1: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_RDCOMM_STATUS;
           end
        end
        
        RESP_RDCOMM_STATUS: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016004;

           if(idle_trigger) begin 
	      if(cmdrcv && rcvokay && idle_trigger) begin  // Goto Asynch event read state and check whether any async messages occured.
                 resp_next_state = RESP_WAIT_ASYNCRD1;  
                 cfrd_resp_o     = 1'b1;
              end
	      else if(rcvokay && idle_trigger) begin  // Else goto read status/descriptor
                 resp_next_state = RESP_REG4;   
                 cfrd_resp_o     = 1'b1;
              end
              else begin
                 resp_next_state = RESP_POLL_CINT1;
                 cfrd_resp_o    = 1'b0;
              end
           end
        end

        // To read the async message event. First read the command and then see if it async event 
        // and report
        RESP_WAIT_ASYNCRD1: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_RDCOMM_ASYNCFRM1;
           end
        end

        // Read command in response phase
        RESP_RDCOMM_ASYNCFRM1: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016018;

           if(fctrans_done_i == 1'b1 &&                   
              ( ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'h80) && (fcdataout_d1[7:0] <= 8'hA0)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'hB0) && (fcdataout_d1[7:0] <= 8'hB7)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE0 ))                                ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE1 )) 
                )) begin 
              resp_next_state = RESP_ASYNC_OUT1;
           end   
           else if(fctrans_done_i == 1'b1 && (fcdataout_d1[7:0] == uclatchcmd_i_mux)) begin 
              resp_next_state = RESP_POLL_CINT1;  
           end
           else if(fctrans_done_i == 1'b1) begin
              resp_next_state = RESP_POLL_CINT1;  
              cmd_error       = 1'b1;              
           end
         end

        RESP_ASYNC_OUT1: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_next_state = RESP_POLL_CINT1;
        end
        RESP_REG4: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_RDCOMM_DESC;
           end
           
        end

        // Read the status response
        RESP_RDCOMM_DESC: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016010;

           if(unreg_cmd == 1'b1 && fctrans_done_i == 1'b1) begin 
              resp_next_state = RESP_IDLE;  
              resp_phase_done = 1'b1; 
           end  
           else if(uclatchcmd_i != 8'h02 && uclatchcmd_i != 8'h17 && uclatchcmd_i != 8'h28 && uclatchcmd_i != 8'h1F && uclatchcmd_i != 8'h14 &&  
              uclatchcmd_i != 8'h2D && uclatchcmd_i != 8'hF1 && uclatchcmd_i_mux != 8'h19) begin 
              if(fctrans_done_i == 1'b1) begin
                 resp_next_state = RESP_WAIT_REG12;   // Move to read descriptor
              end
           end
           else begin
              if(idle_trigger) begin 
                 resp_next_state = RESP_REG7;
              end  
           end
        end

        RESP_WAIT_REG12: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

              if(fcbusreq_d1 == 1'b1) begin
                 resp_next_state = RESP_WRCOMM_CTRL2;
              end
        end

        RESP_WRCOMM_CTRL2: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016000;
           if(uclatchcmd_i == 8'h2C) begin
             resp_srcreg_data = 32'h00000010;
           end
           else begin
             resp_srcreg_data = 32'h00000018;
           end

           if(fctrans_done_i == 1'b1) begin
              resp_next_state = RESP_POLL_CINT4; 
           end
        end

        RESP_REG7: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           if(mchready_i == 1'b1) begin
              resp_next_state = RESP_REG8;
           end
        end

        RESP_REG8: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1; 

           resp_next_state = RESP_REG9;
        end

        RESP_REG9: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1; 

           if(ucnvm_bfr_iapverify == 1'b0) begin   
              resp_phase_done = 1'b1;
           end

           resp_next_state = RESP_IDLE;
        end

        RESP_POLL_CINT4: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(uccommblk_int_i == 1'b1 && idle_trigger) begin
              resp_next_state = RESP_REG5;

              cfrd_resp_o    = 1'b1;
           end
        end

        RESP_REG5: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_RDCOMM_STATUS3;  
           end
        end

        RESP_RDCOMM_STATUS3: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016004;

           if(uclatchcmd_i == 8'h02) begin
              if(idle_trigger) begin           
                 if(cmdrcv && rcvokay && idle_trigger) begin 
                    resp_next_state = RESP_REG6;
                    cfrd_resp_o    = 1'b1;
                 end
                 else begin
                    resp_next_state = RESP_POLL_CINT4;
                 end	      
              end
           end
           else begin
              if(idle_trigger) begin           
                 if(cmdrcv && rcvokay && idle_trigger) begin   
                    resp_next_state = RESP_WAIT_ASYNCRD3;    
                    cfrd_resp_o    = 1'b1;
                 end
                 else if(rcvokay && idle_trigger) begin 
                    resp_next_state = RESP_REG6;
                    cfrd_resp_o    = 1'b1;
                 end
                 else begin
                    resp_next_state = RESP_POLL_CINT4;
                 end	      
              end
           end
        end

        // To read the async message event. First read the command and then see if it async event 
        // and report
        RESP_WAIT_ASYNCRD3: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_RDCOMM_ASYNCFRM3;
           end
        end

        // Read command in response phase
        RESP_RDCOMM_ASYNCFRM3: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           resp_srcreg_addr = 32'h40016018;

           if(fctrans_done_i == 1'b1 &&                   
              ( ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'h80) && (fcdataout_d1[7:0] <= 8'hA0)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'hB0) && (fcdataout_d1[7:0] <= 8'hB7)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE0 ))                                 ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE1 )) 
                )) begin 
              resp_next_state = RESP_ASYNC_OUT3;
           end           
           else if(fctrans_done_i == 1'b1 && (fcdataout_d1[7:0] == uclatchcmd_i_mux)) begin   
              resp_next_state = RESP_POLL_CINT4;  
           end
           else if(fctrans_done_i == 1'b1) begin
              cmd_error       = 1'b1;              
              resp_next_state = RESP_POLL_CINT4;  
           end
         end

        RESP_ASYNC_OUT3: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

           resp_next_state = RESP_POLL_CINT4;
        end

        RESP_REG6: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;

              if(fcbusreq_d1 == 1'b1) begin
                 resp_next_state = RESP_RDCOMM_DATA;
              end
        end

        // Read descriptor pointer
        RESP_RDCOMM_DATA: begin
           cfcommaccess_resp_active = 1'b1;
           cfgrant_resp = 1'b1;
           if(uclatchcmd_i == 8'h2C) begin
             resp_srcreg_addr = 32'h40016010;
           end
           else begin
             resp_srcreg_addr = 32'h40016014;
           end

           if(idle_trigger) begin
              if(do_mem_rd && !cucmd_error) begin  
                 resp_next_state = RESP_WAIT_MEMRD;
                 
                 cfrd_resp_o   = 1'b1;
              end
              else begin
                 resp_phase_done = 1'b1;
                 resp_next_state = RESP_IDLE;
              end
           end
        end

      // Read E0h in case of F*F
        RESP_WAIT_MEMRD: begin
           rd_active = 1'b1;
           cfgrant_resp = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              resp_next_state = RESP_MEMRD; 

           end
        end

        RESP_MEMRD: begin
           rd_active = 1'b1;
           cfgrant_resp    = 1'b1;
           resp_phase_done = 1'b1;
           
           if(fctrans_done_i) begin
              resp_next_state = RESP_IDLE; 
           end
        end

        default: resp_next_state = RESP_IDLE;
        
      endcase // case (resp_curr_state)      
   end // always @ (*)
   
   // --------------------------------------------------------------------------
   // Asynchronous Event messaging: FSM
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         asynchevent_curr_state <= ASYNCEVENT_POLL_IDLE;
      end
      else begin
         asynchevent_curr_state <= asynchevent_next_state;
      end
   end

   // --------------------------------------------------------------------------
   // Asynchronous Event messaging: Next state and output decoder
   // --------------------------------------------------------------------------
   always @(*) begin
      asynchevent_next_state = asynchevent_curr_state;
      asyncevent_active      = 1'b0;
      cfgrant_asyncevent     = 1'b0;      
      asyncevent_srcreg_addr = 32'h0;
      asyncevent_dstreg_addr = 32'h0;
      asyncevent_dstreg_data = 32'h0;
      asyncevent_cmd_error   = 1'b0;
      case(asynchevent_curr_state)
   
        ASYNCEVENT_POLL_IDLE: begin
           cfgrant_asyncevent = 1'b0;
           asyncevent_active  = 1'b1;
           asynchevent_next_state = ASYNCEVENT_PHASE;
        end

        ASYNCEVENT_PHASE: begin
           cfgrant_asyncevent     = 1'b1;

           if(TAMPERDETECTSERVICE == 1 && req_phase_active == 1'b0 && resp_phase_active == 1'b0 && main_curr_state == 'h0) begin  
              asyncevent_active      = 1'b1;
              asynchevent_next_state = ASYNCEVENT_WAIT_REG11;
           end
        end

        ASYNCEVENT_WAIT_REG11: begin
           cfgrant_asyncevent     = 1'b1;

           if(TAMPERDETECTSERVICE == 1 && req_phase_active == 1'b0 && resp_phase_active == 1'b0 && main_curr_state == 'h0) begin  
              asyncevent_active      = 1'b1;
              if(fcbusreq_d1 == 1'b1) begin
                 asynchevent_next_state = ASYNCEVENT_WRCOMM_CTRL1;
              end
           end

        end
        ASYNCEVENT_WRCOMM_CTRL1: begin
           asyncevent_active      = 1'b1;
           cfgrant_asyncevent     = 1'b1;
           asyncevent_dstreg_addr = 32'h40016000;
           asyncevent_dstreg_data = 32'h00000010;

           if(fctrans_done_i == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_WAIT_REG13;
           end
        end
 
        ASYNCEVENT_WAIT_REG13: begin
           asyncevent_active      = 1'b1;
           cfgrant_asyncevent     = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_FIIC_INT;
           end

        end
        
        ASYNCEVENT_FIIC_INT: begin
           asyncevent_active      = 1'b1;
           cfgrant_asyncevent     = 1'b1;
           asyncevent_dstreg_addr = 32'h40006000;
           asyncevent_dstreg_data = 32'h20000000;

           if(fctrans_done_i == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_WAIT_REG14; 
           end
        end

        ASYNCEVENT_WAIT_REG14: begin
           asyncevent_active      = 1'b1;
           cfgrant_asyncevent     = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_WRCOMM_INT3;
           end
        end

        ASYNCEVENT_WRCOMM_INT3: begin
           asyncevent_active      = 1'b1;
           cfgrant_asyncevent     = 1'b1;
           asyncevent_dstreg_addr = 32'h40016008;
           asyncevent_dstreg_data = 32'h00000080;

           if(fctrans_done_i == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_POLL_WAIT; 
           end
        end

        ASYNCEVENT_POLL_WAIT: begin
           if(uccommblk_int_i == 1'b1 && req_phase_active == 1'b0 && resp_phase_active == 1'b0 && main_curr_state == 'h0) begin  
              asyncevent_active      = 1'b1;
              cfgrant_asyncevent     = 1'b1;
              asynchevent_next_state = ASYNCEVENT_POLL_CINT;
           end
        end
        ASYNCEVENT_POLL_CINT: begin
           asyncevent_active      = 1'b1;
           if(req_phase_active == 1'b0 && resp_phase_active == 1'b0 && main_curr_state == 'h0) begin  
              asynchevent_next_state = ASYNCEVENT_REG1;
              cfgrant_asyncevent = 1'b1;
           end
        end
        ASYNCEVENT_REG1: begin
           cfgrant_asyncevent = 1'b1;
           asyncevent_active      = 1'b1;
           if(fcbusreq_d1 == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_RDCOMM_STATUS;
           end
        end
        
        ASYNCEVENT_RDCOMM_STATUS: begin
           cfgrant_asyncevent = 1'b1;
           asyncevent_active      = 1'b1;
           asyncevent_srcreg_addr = 32'h40016004;

           if(idle_trigger) begin
              if(cmdrcv && idle_trigger) begin
                 asynchevent_next_state = ASYNCEVENT_WAIT_RD1;  
              end
              else begin
                 asynchevent_next_state = ASYNCEVENT_POLL_IDLE;
              end
           end
        end

        // To read the async message event. First read the command and then see if it async event 
        // and report
        ASYNCEVENT_WAIT_RD1: begin
           cfgrant_asyncevent = 1'b1;
           asyncevent_active      = 1'b1;

           if(fcbusreq_d1 == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_RDCOMM_FRM1;
           end
        end

        // Read command in response phase
        ASYNCEVENT_RDCOMM_FRM1: begin
           cfgrant_asyncevent = 1'b1;
           asyncevent_active      = 1'b1;
           asyncevent_srcreg_addr = 32'h40016018;

           if(fctrans_done_i == 1'b1 &&                   
              ( ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'h80) && (fcdataout_d1[7:0] <= 8'hA0)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] >= 8'hB0) && (fcdataout_d1[7:0] <= 8'hB7)) ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE0 ))                                ||
                ((fcdataout_d1[7:0] != uclatchcmd_i_mux) && (fcdataout_d1[7:0] == 8'hE1 )) 
                )) begin 
              asynchevent_next_state = ASYNCEVENT_RDCOMM_OUT1;
           end           
           else if(fctrans_done_i == 1'b1) begin
              asynchevent_next_state = ASYNCEVENT_WAIT;
              asyncevent_cmd_error   = 1'b1;              
           end
         end

        ASYNCEVENT_RDCOMM_OUT1: begin
           asyncevent_active      = 1'b1;
           cfgrant_asyncevent = 1'b1;
           asynchevent_next_state = ASYNCEVENT_WAIT;
        end

        ASYNCEVENT_WAIT: begin
           asyncevent_active      = 1'b1;

           asynchevent_next_state = ASYNCEVENT_POLL_IDLE;
        end
      endcase // case (asynchevent_curr_state)
   end // always @ (*)
   
   

endmodule // CmdDec

