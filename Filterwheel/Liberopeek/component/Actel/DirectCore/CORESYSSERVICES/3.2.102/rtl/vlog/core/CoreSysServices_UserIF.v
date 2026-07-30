// ****************************************************************************/   
// Actel Corporation Proprietary and Confidential   
// Copyright 2010 Actel Corporation.  All rights reserved.   
//   
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN   
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED   
// IN ADVANCE IN WRITING.   
//   
// Description: UserIF.v - User IF logic 
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
 
 
module CoreSysServices_UserIF (   
                  // Inputs
                  clk,   
                  resetn,   
                  
                  // From User logic
                  ureq_enable_i,   
                  ucmdbyte_req_i,   
                  uoptions_mode_i,
                  ucommblk_int_i,
                  udata_wvalid_i,
                  udata_w_i,  

                  ucrypto_key,
                  ucrypto_iv,
                  ucrypto_mode,
                  ucrypto_nblocks,
                  ucrypto_length, 

                  unrbg_length,   
                  unrbg_handle,   
                  unrbg_addlength,
                  unrbg_prreq,

                  udpa_key_i,
                  udpa_optype_i,  
                  udpa_path_i,    

                  upuf_subcmd_i,
                  upuf_inkeynum_i,  
                  upuf_keysize_i,
                  upuf_userkeyaddr_i,    
                  upuf_userextrkeyaddr_i,

                  uspiaddr_i,
                  // From Command decoder IF
                  cudata_wrdy_i,
                  cudata_rvalid_i,
                  cudata_r_i,
                  custatus_valid_i,
                  cutamper_msg_valid,
                  cutamper_msg, 
                  cutrans_done_i,
                  cubusy_i,
                  cuhprior_flushdone_i,
                  custatus_out_en,
                  cucmd_error,  
                  cutamper_detect_valid,  
                  cutamper_fail_valid,    
                  cunvm_bfr_iapverify_done, 
                  // Outputs       
                  // To CmdDec IF
                  uccommblk_int_o,
                  uctrig_o,
                  uclatchcmd_o,   
                  uclatchoptions_o,
                  
                  uccrypto_key_o,
                  uccrypto_iv_o,
                  uccrypto_mode_o,
                  uccrypto_nblocks_o,
                  uccrypto_length_o, 

                  ucnrbg_length_o,   
                  ucnrbg_handle_o,   
                  ucnrbg_addlength_o,
                  ucnrbg_prreq_o,
                  
                  ucdpa_key_o,
                  ucdpa_optype_o,  
                  ucdpa_path_o, 
                  
                  ucpuf_subcmd_o,
                  ucpuf_inkeynum_o,         
                  ucpuf_userkeyaddr_o,      
                  ucpuf_userextrkeyaddr_o,  
                  ucpuf_keysize_o,
                  
                  ucspiaddr_o, 

                  ucdata_w_o,
                  ucdata_wvalid_o,
                  ucvalid_cmd_o,
                  uchprior_flushreq_o,
                  ucnvm_bfr_iapverify,
                  
                  // To User logic   
                  ubusy_o,
                  udata_wrdy_o,
                  udata_rvalid_o,
                  udata_r_o,

                  ustatus_valid_o,
                  ustatus_resp_o,
                  utamper_msg_valid,  
                  utamper_msg,  
                  ucmd_error             

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

   localparam AHB_AWIDTH            = 32;   
   localparam AHB_DWIDTH            = 32;   
    
   //------------------------------------------------------------------------------   
   // Port declarations   
   //------------------------------------------------------------------------------   
    
   // -----------   
   // Inputs   
   // -----------   
   input      clk;   
   input      resetn;   
   // User IF   
   input      ureq_enable_i;   
   input [7:0] ucmdbyte_req_i;   
   input [5:0] uoptions_mode_i;   
   input       ucommblk_int_i;   

   input       udata_wvalid_i;   
   input [AHB_DWIDTH - 1:0] udata_w_i;
   // Crypto inputs
   input [255:0]            ucrypto_key;
   input [127:0]            ucrypto_iv;
   input [7:0]              ucrypto_mode;
   input [15:0]             ucrypto_nblocks;
   input [31:0]             ucrypto_length;
   
   // NRBG inputs
   input [7:0]              unrbg_length;
   input [7:0]              unrbg_handle;
   input [7:0]              unrbg_addlength;
   input [7:0]              unrbg_prreq;    
   
   // DPA inputs
   input [255:0]            udpa_key_i;
   input [7:0]              udpa_optype_i;
   input [127:0]            udpa_path_i;
   
   input [7:0]              upuf_subcmd_i;   
   input [7:0]              upuf_inkeynum_i;        

   input [31:0]             upuf_userkeyaddr_i;     
   input [31:0]             upuf_userextrkeyaddr_i; 
   input [7:0]              upuf_keysize_i;
   
   input [31:0]             uspiaddr_i; 

   input                    cudata_wrdy_i;
   input                    cudata_rvalid_i;
   input [AHB_DWIDTH - 1:0] cudata_r_i;
   input                    custatus_valid_i;   
   input                    cutamper_msg_valid;
   input [7:0]              cutamper_msg;
   
   input                    cutrans_done_i;
   input                    cubusy_i;
   input                    cuhprior_flushdone_i;
   input                    custatus_out_en;
   input                    cucmd_error;
   input                    cutamper_detect_valid;
   input                    cutamper_fail_valid;
   input                    cunvm_bfr_iapverify_done;   
   
   // -----------  
   // Outputs  
   // -----------  
   // User IF   
   output                   ustatus_valid_o;   
   output [7:0]             ustatus_resp_o;   
   output [7:0]             utamper_msg;
   output                   utamper_msg_valid;
   output                   ubusy_o;
   
   output                   udata_wrdy_o;
   output                   udata_rvalid_o;
   output [AHB_DWIDTH - 1:0] udata_r_o;
   
   // To Command Decoder IF block
   output                   uccommblk_int_o;   

   output                   uctrig_o;
   output [7:0]             uclatchcmd_o;
   output [5:0]             uclatchoptions_o;   

   output [31:0]            ucdata_w_o;
   output                   ucdata_wvalid_o;
   output                   ucvalid_cmd_o;
   output                   uchprior_flushreq_o;

   output                   ucnvm_bfr_iapverify;     
   
   // Crypto inputs
   output [255:0]           uccrypto_key_o;
   output [127:0]           uccrypto_iv_o;
   output [7:0]             uccrypto_mode_o;
   output [15:0]            uccrypto_nblocks_o;
   output [31:0]            uccrypto_length_o;
   
   // NRBG outputs
   output [7:0]             ucnrbg_length_o;
   output [7:0]             ucnrbg_handle_o;
   output [7:0]             ucnrbg_addlength_o;
   output [7:0]             ucnrbg_prreq_o;    

   // DPA Keytree/Challenge Resp outputs
   output [255:0]           ucdpa_key_o;
   output [7:0]             ucdpa_optype_o;
   output [127:0]           ucdpa_path_o;  
   
   // PUF outputs  
   output [7:0]             ucpuf_subcmd_o;   
   output [7:0]             ucpuf_inkeynum_o;   
   output [31:0]            ucpuf_userkeyaddr_o;
   output [31:0]            ucpuf_userextrkeyaddr_o;
   output [7:0]             ucpuf_keysize_o;
   
   output [31:0]            ucspiaddr_o;  
   output                   ucmd_error;
 
   // -----------------  
   // Internal signals  
   // -----------------  
   reg [7:0]                uclatchcmd_o;
   reg [5:0]                uclatchoptions_o;   
   reg [7:0]                ucmdbyte_req_d1;
   reg [5:0]                uclatchoptions_d1;   
   reg                      ubusy_o;
   reg                      ubusy_int;
   reg                      hprior_kp_busy_high;
   reg [7:0]                ucmdbyte_req_hold;
   reg [5:0]                uclatchoptions_hold;   
   reg                      ucnvm_bfr_iapverify;
   reg                      cunvm_bfr_iapverify_done_d1;   
   wire                     cunvm_bfr_iapverify_done_trig; 
   
   reg [7:0]                ustatus_resp_o;
   reg                      ustatus_valid_o;   
   reg [7:0]                ustatus_resp_lat;
   reg [7:0]                utamper_msg;
   reg                      utamper_msg_valid;
   
   reg                      ustatus_valid_lat;   

   reg                      uctrig_o;
   wire                     uccommblk_int_o;
   wire                     new_serv;
   wire                     new_serv_pord;
   reg                      new_serv_d1;
   reg                      ucvalid_cmd_o;
   reg                      ucvalid_cmd_int;
   wire                     udata_wrdy_d1;
   reg                      udata_wrdy_d2;
   wire                     udata_wrdy_o;
   wire [31:0]              ucdata_w_o;
   wire                     ucdata_wvalid_o;
   wire                     udata_rvalid_o;
   wire [AHB_DWIDTH - 1:0]  udata_r_o;
   wire                     zer_new_serv;
   reg                      zer_new_serv_d1;   

   reg                      cuhprior_flushdone_d1;
   reg                      cuhprior_flushdone_d2;
   reg                      cuhprior_flushdone_d3;
   reg                      ureq_enable_d1;
   reg                      ureq_enable_d2;   

   // Crypto inputs
   reg [255:0]           uccrypto_key_o;
   reg [127:0]           uccrypto_iv_o;
   reg [7:0]             uccrypto_mode_o;
   reg [15:0]            uccrypto_nblocks_o;
   reg [31:0]            uccrypto_length_o;
   
   // NRBG outputs
   reg [7:0]             ucnrbg_length_o;
   reg [7:0]             ucnrbg_handle_o;
   reg [7:0]             ucnrbg_addlength_o;
   reg [7:0]             ucnrbg_prreq_o;    

   // DPA Keytree/Challenge Resp outputs
   reg [255:0]           ucdpa_key_o;
   reg [7:0]             ucdpa_optype_o;
   reg [127:0]           ucdpa_path_o;  

   // PUF outputs
   reg [7:0]             ucpuf_subcmd_o;   
   reg [7:0]             ucpuf_inkeynum_o;   
   reg [31:0]            ucpuf_userkeyaddr_o;
   reg [31:0]            ucpuf_userextrkeyaddr_o;
   reg [7:0]             ucpuf_keysize_o;

   reg                   pord_d1;
   reg                   pord_d2;
   reg                   pord;

   wire                  pord_comb;
   reg                   pord_comb_d1;  
   reg                   custatus_out_en_r;

   reg [31:0]            ucspiaddr_o;
   wire [AHB_DWIDTH - 1:0]  udata_r_sel1;
   wire [AHB_DWIDTH - 1:0]  udata_r_sel2;
   reg                   ucmd_error;

   //////////////////////////////////////////////////////////////////////////////  
   //                           Start-of-Code                                  //  
   //////////////////////////////////////////////////////////////////////////////  

   //---------------------------------------------------------------------------
   // This output is generated when the requested system service opcode does
   // NOT match with the received response command opcode. In that case the
   // system service is aborted. 
   //---------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucmd_error  <= 1'b0;
      end
      else begin
         if(cubusy_i == 1'b1) begin
            ucmd_error  <= cucmd_error;
         end
         else begin
            ucmd_error  <= 1'b0;
         end
      end
   end
   
   //---------------------------------------------------------------------------
   // udata_wrdy_d1:Registered cudata_wrdy_i
   // Register the data ready received from Cmd Decoder block
   //---------------------------------------------------------------------------
   assign                   udata_wrdy_d1  = cudata_wrdy_i;

   //---------------------------------------------------------------------------
   // udata_wrdy_d2: Registered udata_wrdy_d1
   //---------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         udata_wrdy_d2  <= 1'b0;
      end
      else begin
         udata_wrdy_d2  <= udata_wrdy_d1;
      end
   end

   //---------------------------------------------------------------------------
   // udata_wrdy_o: Generate the data ready pulse to the user logic.
   // This is generated to indicate to the user logic that the DUT is ready to 
   // accept write data along with write enable asserted.
   //---------------------------------------------------------------------------
   assign udata_wrdy_o = udata_wrdy_d1 & !udata_wrdy_d2;
   
   //---------------------------------------------------------------------------
   // ucdata_w_o: Pass the write data to the Cmd Decoder block from the user 
   // ucdata_wvalid_o: Pass the write data valid to the Cmd Decoder block from
   // the user
   //---------------------------------------------------------------------------
   assign ucdata_w_o      = udata_w_i;
   assign ucdata_wvalid_o = udata_wvalid_i;

   //---------------------------------------------------------------------------
   // udata_rvalid_o: Pass the read data valid from the Cmd Decoder block to the
   // user 
   // ucdata_r_o: Pass the read data from the Cmd Decoder block to the user
   // Pass the only the handle value in instantiate service(3rd byte)
   //---------------------------------------------------------------------------
   assign udata_rvalid_o  = cudata_rvalid_i;
   assign udata_r_sel1       = ((uclatchcmd_o == 8'h29) & cudata_rvalid_i) ? {24'h000000, cudata_r_i[23:16]} : udata_r_sel2;  
   assign udata_r_sel2       = ((uclatchcmd_o == 8'h1A) & cudata_rvalid_i) ? {24'h000000, cudata_r_i[15:8]}  : cudata_r_i;  
   assign udata_r_o          = udata_r_sel1;  

   //---------------------------------------------------------------------------
   // Pass the COMM BLK interrupt to the Command Decoder FSM for polling
   // purpose
   //---------------------------------------------------------------------------
   assign uccommblk_int_o = ucommblk_int_i;

   // --------------------------------------------------------------------------
   // ubusy_o: Send the busy output back to the user logic
   // It is asserted as long as the requested service has not been serviced.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin  
      if(resetn == 1'b0) begin
         ubusy_int     <= 1'b0;
      end
      else begin
         if(ureq_enable_i == 1'b1 || ureq_enable_d1 == 1'b1 || ureq_enable_d2 == 1'b1 || hprior_kp_busy_high == 1'b1 || cubusy_i == 1'b1 || pord == 1'b1 || pord_comb == 1'b1) begin
            ubusy_int     <= 1'b1;
         end
         else if(cubusy_i == 1'b0) begin
            ubusy_int     <= 1'b0;
         end
      end
   end
   
   always @(*) begin
      ubusy_o     <= PORDSERVICE ? (ubusy_int | pord_comb | pord_comb_d1) : ubusy_int; 
   end

   // --------------------------------------------------------------------------
   // hprior_kp_busy_high: For zer, keeps busy high
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin   
      if(resetn == 1'b0) begin
         hprior_kp_busy_high     <= 1'b0;
      end
      else begin
         if(uctrig_o == 1'b1) begin
            hprior_kp_busy_high     <= 1'b0;
         end
         else if(uchprior_flushreq_o == 1'b1 && ZERSERVICE == 1) begin
            hprior_kp_busy_high     <= 1'b1;
         end
      end
   end

   // --------------------------------------------------------------------------
   // ureq_enable_d1: Delayed ureq_enable_i
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ureq_enable_d1     <= 1'b0;
         ureq_enable_d2     <= 1'b0;
         pord_comb_d1       <= 1'b0;  
      end
      else begin
         ureq_enable_d1     <= ureq_enable_i;
         ureq_enable_d2     <= ureq_enable_d1;
         pord_comb_d1       <= pord_comb;   
      end
   end
   
   // --------------------------------------------------------------------------
   // ustatus_resp_o: Send the status for the command back to the user logic
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ustatus_resp_lat     <= 8'h00;
      end
      else begin
         if(custatus_valid_i == 1'b1) begin
            ustatus_resp_lat     <= cudata_r_i;
         end
      end
   end // always @ (posedge clk or negedge resetn)
   
   // --------------------------------------------------------------------------
   // utamper_msg: Send the status for the command back to the user logic
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         utamper_msg     <= 8'h00;
      end
      else begin
         if(cutamper_msg_valid == 1'b1) begin
            utamper_msg     <= cutamper_msg;  
         end
      end
   end // always @ (posedge clk or negedge resetn)
   
   // --------------------------------------------------------------------------
   // utamper_msg_valid: Send the status valid for the command back to the user logic
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         utamper_msg_valid     <= 1'b0;
      end
      else begin
         utamper_msg_valid     <= cutamper_msg_valid;
      end
   end // always @ (posedge clk or negedge resetn)
   
   // --------------------------------------------------------------------------
   // ustatus_valid_o: Indicates valid status response to the User logic
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ustatus_valid_lat     <= 1'b0;
      end
      else begin
         if(ubusy_o == 1'b0) begin
            ustatus_valid_lat     <= 1'b0;
         end
         else if(custatus_valid_i == 1'b1) begin
            ustatus_valid_lat     <= 1'b1;
         end
      end
   end // always @ (posedge clk or negedge resetn)

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         custatus_out_en_r     <= 1'b0;
      end
      else begin
         custatus_out_en_r  <= custatus_out_en;
      end
   end // always @ (posedge clk or negedge resetn)
   
   
   // --------------------------------------------------------------------------
   // ustatus_resp_o: Send the status for the command back to the user logic
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ustatus_resp_o     <= 8'h00;
      end
      else begin
         if(custatus_out_en == 1'b1) begin
            ustatus_resp_o  <= ustatus_resp_lat;
         end
      end
   end // always @ (posedge clk or negedge resetn)
   
   // --------------------------------------------------------------------------
   // ustatus_valid_o: Indicates valid status response to the User logic
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ustatus_valid_o     <= 1'b0;
      end
      else begin
         if(custatus_out_en == 1'b1) begin
            ustatus_valid_o     <= ustatus_valid_lat;
         end
         else begin
            ustatus_valid_o     <= 1'b0;
         end
      end
   end // always @ (posedge clk or negedge resetn)
   


   // --------------------------------------------------------------------------
   // Latch the incoming command byte and buffer pointer/descriptor and prog.
   // options mode for programming services.
   // Also, generate the busy when the incoming command is latched indicating
   // that the system service is active and no other system service is active.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin         
      if(resetn == 1'b0) begin
         cunvm_bfr_iapverify_done_d1 <= 1'b0;
      end
      else begin
         cunvm_bfr_iapverify_done_d1 <= cunvm_bfr_iapverify_done;
      end
   end

   assign cunvm_bfr_iapverify_done_trig = cunvm_bfr_iapverify_done & !cunvm_bfr_iapverify_done_d1;  
   
     
   always @(posedge clk or negedge resetn) begin         
      if(resetn == 1'b0) begin
         uclatchcmd_o        <= 8'h00;
         uclatchoptions_o    <= 6'b000000;
         ucmdbyte_req_hold   <= 8'h00;   
         uclatchoptions_hold <= 6'b000000;
         ucnvm_bfr_iapverify <= 1'b0;         
      end
      else begin
         if(cunvm_bfr_iapverify_done == 1'b1 && cunvm_bfr_iapverify_done_d1 == 1'b0 && ucmdbyte_req_hold == 8'h14 && uclatchoptions_hold == 6'h02) begin
            // Send the value of IAP command and option = Verify after NVM DI is done
            // workaround for IAP(option=2), -- drive NVM Digest check first 
            uclatchcmd_o        <= ucmdbyte_req_hold;
            uclatchoptions_o    <= uclatchoptions_hold;

            ucnvm_bfr_iapverify <= 1'b0;         
         end
         else if(new_serv_d1 == 1'b1 && ucmdbyte_req_d1 == 8'h14 && uclatchoptions_d1 == 6'h02) begin
            // Copy the value of IAP command and option when it is Verify
            ucmdbyte_req_hold   <= ucmdbyte_req_d1;
            uclatchoptions_hold <= uclatchoptions_d1;

            // Send NVM DI with Fabric Digest Check
            uclatchcmd_o        <= 8'h17;
            uclatchoptions_o    <= 6'h01;  

            // Assert the signal to indicate that the NVM DI is to be performed before IAP verify
            ucnvm_bfr_iapverify <= 1'b1;         

         end
         else if(new_serv_d1 == 1'b1) begin
            uclatchcmd_o     <= ucmdbyte_req_d1;
            uclatchoptions_o <= uclatchoptions_d1;
         end
         else if(new_serv_pord & PORDSERVICE == 1'b1) begin  
            uclatchcmd_o     <= 8'hF1;
         end
         else if(zer_new_serv_d1 == 1'b1) begin  
            uclatchcmd_o     <= ucmdbyte_req_d1;
         end
      end
   end

   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucmdbyte_req_d1   <= 8'h00;
         uclatchoptions_d1 <= 6'b000000;
      end
      else begin
         if(ureq_enable_i == 1'b1) begin
            ucmdbyte_req_d1   <= ucmdbyte_req_i;
            uclatchoptions_d1 <= uoptions_mode_i;
         end
      end
   end

   // -------------------------------------------------------------------------
   // new_serv: Accept new service only when the busy is de-asserted and new 
   // request is requested.
   // -------------------------------------------------------------------------
   assign new_serv      = !ubusy_o & ureq_enable_i & !pord_comb;  
   assign new_serv_pord = PORDSERVICE & pord_comb;  

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

   assign pord_comb = (PORDSERVICE == 1'b1) ? (pord_d1 & !pord_d2) : 1'b0;       

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

   // -------------------------------------------------------------------------
   // new_serv_d1: Delayed new_seerv
   // -------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         new_serv_d1     <= 1'b0;
      end
      else begin
         new_serv_d1     <= new_serv;
      end
   end
   
   // -------------------------------------------------------------------------
   // zer_new_serv: Assert on receiving high priority Zeroization service req
   // and service request enable pulse.  
   // -------------------------------------------------------------------------
   assign zer_new_serv = !ubusy_o & ureq_enable_i & (ZERSERVICE == 1); 

   assign uchprior_flushreq_o = ubusy_o & ureq_enable_i & (ZERSERVICE == 1);

   // -------------------------------------------------------------------------
   // zer_new_serv_d1: Delayed zer_new_serv
   // -------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         zer_new_serv_d1     <= 1'b0;
      end
      else begin
         if((cuhprior_flushdone_d2 == 1'b1) || (zer_new_serv == 1'b1)) begin
            zer_new_serv_d1     <= 1'b1;
         end
         else begin
            zer_new_serv_d1     <= 1'b0;
         end
      end
   end

   // -------------------------------------------------------------------------
   // cuhprior_flushdone_d1: delayed cuhprior_flushdone_i
   // -------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         cuhprior_flushdone_d1     <= 1'b0;
         cuhprior_flushdone_d2     <= 1'b0;
         cuhprior_flushdone_d3     <= 1'b0;
      end
      else begin
         cuhprior_flushdone_d1     <= cuhprior_flushdone_i;
         cuhprior_flushdone_d2     <= cuhprior_flushdone_d1;
         cuhprior_flushdone_d3     <= cuhprior_flushdone_d2;
      end
   end

   // -------------------------------------------------------------------------
   // ucvalid_cmd_o: Generate command valid output to Cmd Decoder
   // De-assert when high priority zeroization service request is received OR
   // when busy is de-asserted.
   // -------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucvalid_cmd_o     <= 1'b0;
      end
      else begin
         if((ubusy_o == 1'b0 && ucvalid_cmd_int == 1'b0)) begin
            ucvalid_cmd_o   <= 1'b0;
         end
         else if(ucvalid_cmd_int == 1'b1) begin
            ucvalid_cmd_o   <= 1'b1;
         end
      end
   end

   always @(*) begin
      if(new_serv == 1'b1) begin
         ucvalid_cmd_int = 1'b0;
         case(ucmdbyte_req_i)
           8'h01 : begin  // Device and Design Information services
              if(SNSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
             end
           8'h04 : begin  // Device and Design Information services
              if(UCSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h00 : begin  // Device and Design Information services
              if(DCSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h05 : begin  // Device and Design Information services
              if(UDVSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h02 : begin                       // Added v3.1 Jan31 - F*F services
              if(FFSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h1E : begin  // v3.0 - Secondary Device Certificate
              if(SECDCSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h03: begin   // AES128 services
              if(CRYPTOAES128SERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h06: begin   // AES256 services
              if(CRYPTOAES256SERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h0A: begin   // SHA256 services
              if(CRYPTOSHA256SERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h0C: begin   // HMAC services
              if(CRYPTOHMACSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h09: begin                 // Key Tree services
              if(KEYTREESERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
                end
           end
           8'h0E: begin                 // Challenge Resp. services
              if(CHRESPSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h28, 8'h29, 8'h2A, 8'h2B,8'h2C, 8'h2D: begin      // NRBG services
              if(NRBGSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'hF0: begin                 // Zeroization service
              if(ZERSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h14: begin                 // IAP service
              if(PROGIAPSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h17: begin                 // NVMData Integrity service
              if(PROGNVMDISERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h1F: begin                 // v3.0 - Tamper control service
              if(TAMPERCONTROLSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h10: begin                 // v3.0 - ECC Point Multiply
              if(ECCPOINTMULTSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h11: begin                 // v3.0 - ECC Point Add
              if(ECCPOINTADDSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h19: begin                 // v3.0 - PUF USERAC
              if(PUFSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h1A: begin                 // v3.0 - PUF USERKC
              if(PUFSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h1B: begin                 // v3.0 - PUF USERKEY
              if(PUFSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h1C: begin                 // v3.0 - PUF PUBLICKEY
              if(PUFSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           8'h1D: begin                 // v3.0 - PUF SEED
              if(PUFSERVICE == 1) begin
                 ucvalid_cmd_int = 1'b1;
              end
           end
           default: begin
              ucvalid_cmd_int = 1'b1;
           end
         endcase // case (ucmdbyte_req_i)
      end // if (new_serv == 1'b1)     
      //else if(PORDSERVICE == 1) begin   // PORD Service 
      else if(new_serv_pord) begin   // PORD Service : For PoR SAR
         ucvalid_cmd_int = 1'b1;
      end
      else begin
         ucvalid_cmd_int = 1'b0;
      end // else: !if(new_serv == 1'b1)     
   end // always @ (*)

   // --------------------------------------------------------------------------
   // uctrig_o: Generate the trigger to the command decoder IF on the busy
   // pulse. Zeroization HP service.
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         uctrig_o <= 1'b0;
      end
      else begin
         if(ucvalid_cmd_o == 1'b0) begin
            uctrig_o <= 1'b0;
         end
         else begin
            uctrig_o <= (new_serv_d1 | zer_new_serv_d1);
         end
      end
   end

   // --------------------------------------------------------------------------
   // Pass the descriptors for crypto service to Cmd Decoder block
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         uccrypto_key_o     <= {256{1'b0}};
         uccrypto_iv_o      <= {128{1'b0}};
         uccrypto_mode_o    <= {8{1'b0}};     
         uccrypto_nblocks_o <= {16{1'b0}};
         uccrypto_length_o  <= {32{1'b0}};
      end
      else begin
         if(ureq_enable_i == 1'b1) begin
            uccrypto_key_o     <= ucrypto_key;
            uccrypto_iv_o      <= ucrypto_iv;        
            uccrypto_mode_o    <= ucrypto_mode;
            uccrypto_nblocks_o <= ucrypto_nblocks;
            uccrypto_length_o  <= ucrypto_length;
         end
      end
   end

   // --------------------------------------------------------------------------
   // Pass the descriptors for nrbg service to Cmd Decoder block
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucnrbg_length_o    <= {8{1'b0}};
         ucnrbg_handle_o    <= {8{1'b0}};
         ucnrbg_addlength_o <= {8{1'b0}};
         ucnrbg_prreq_o     <= {8{1'b0}};
      end
      else begin
         if(ureq_enable_i == 1'b1) begin
            ucnrbg_length_o    <= unrbg_length;
            ucnrbg_handle_o    <= unrbg_handle;       
            ucnrbg_addlength_o <= unrbg_addlength;
            ucnrbg_prreq_o     <= unrbg_prreq;
         end
      end
   end

   // --------------------------------------------------------------------------
   // Pass the descriptors for dpa service to Cmd Decoder block
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucdpa_key_o    <= {16{1'b0}};
         ucdpa_optype_o <= {8{1'b0}};
    	 ucdpa_path_o   <= {8{1'b0}};   
      end
      else begin
         if(ureq_enable_i == 1'b1) begin
            ucdpa_key_o    <= udpa_key_i;
            ucdpa_optype_o <= udpa_optype_i;
            ucdpa_path_o   <= udpa_path_i;
         end
      end
   end

   // --------------------------------------------------------------------------
   // Pass the descriptors for puf service to Cmd Decoder block  
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucpuf_subcmd_o    <= {8{1'b0}};
         ucpuf_inkeynum_o  <= {8{1'b0}};
         ucpuf_keysize_o   <= {8{1'b0}};
         ucpuf_userkeyaddr_o <= {32{1'b0}};
         ucpuf_userextrkeyaddr_o <= {32{1'b0}};
      end
      else begin
         if(ureq_enable_i == 1'b1) begin 
            ucpuf_subcmd_o   <= upuf_subcmd_i; 
            ucpuf_inkeynum_o <= upuf_inkeynum_i;
            ucpuf_keysize_o  <= upuf_keysize_i; 
            ucpuf_userkeyaddr_o     <= upuf_userkeyaddr_i;
            ucpuf_userextrkeyaddr_o <= upuf_userextrkeyaddr_i;
         end
      end
   end

   // --------------------------------------------------------------------------
   // Pass the descriptors for IAP SPI ADDRESS to Cmd Decoder block  
   // --------------------------------------------------------------------------
   always @(posedge clk or negedge resetn) begin
      if(resetn == 1'b0) begin
         ucspiaddr_o <= {32{1'b0}};
      end
      else begin
         if(ureq_enable_i == 1'b1) begin 
            ucspiaddr_o <= uspiaddr_i;
         end
      end
   end
   
         
endmodule // UserIF


