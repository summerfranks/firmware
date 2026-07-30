// Actel Corporation Proprietary and Confidential
//  Copyright 2011 Actel Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description:  
// //  UserDriver: Drives System Services 
//
//
// Revision Information:
// Date     Description
//
// SVN Revision Information:
// SVN $Revision: 4805 $
// SVN $Date: 2008-11-27 17:48:48 +0530 (Thu, 27 Nov 2008) $
//
// Resolved SARs
// SAR      Date     Who   Description
//
// Notes:
//
// ********************************************************************/

module UserDriver (    
                                       CLK,    
                                       RESETN,    

                                       // User IF    
                                       SERV_BUSY,    
                                       SERV_ENABLE_REQ,    
                                       SERV_CMDBYTE_REQ,    
                                       SERV_STATUS_VALID,
                                       SERV_STATUS_RESP,    
                                       SERV_TAMPER_MSGVALID,
                                       SERV_TAMPER_MSG,

                                       SERV_CMD_ERROR,         
                                       SERV_OPTIONS_MODE,    

                                       SERV_DATA_WVALID,    
                                       SERV_DATA_W,
                                       SERV_DATA_WRDY,
                                       SERV_DATA_RVALID,    
                                       SERV_DATA_R,    
                                       
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
				       SERV_SPIADDR,        
				       trigger_ext,        
				       command_req       
                                       );


   `include "coreparameters.v"

   //------------------------------------------------------------------------------    
   // Port declarations    
   //------------------------------------------------------------------------------    
    
   // -----------    
   // Inputs    
   // -----------    
   input      CLK;    
   input      RESETN;
   // User IF    
   output                     SERV_ENABLE_REQ;    
   output  [7:0]              SERV_CMDBYTE_REQ;    
   output  [5:0]              SERV_OPTIONS_MODE;    
   output                     SERV_DATA_WVALID;
   output  [31:0]             SERV_DATA_W;    

   // Interrupts    
   
   // CRYPTO IF
   output  [255:0]            SERV_CRYPTO_KEY;
   output  [127:0]            SERV_CRYPTO_IV;
   output  [7:0]              SERV_CRYPTO_MODE;
   output  [15:0]             SERV_CRYPTO_NBLOCKS;
   output  [31:0]             SERV_CRYPTO_LENGTH;
   // NRBG IF               
   output  [7:0]              SERV_NRBG_LENGTH;
   output  [7:0]              SERV_NRBG_HANDLE;
   output  [7:0]              SERV_NRBG_ADDLENGTH;
   output  [7:0]              SERV_NRBG_PRREQ;
   // DPA IF
   output  [255:0]            SERV_DPA_KEY;
   output  [7:0]              SERV_DPA_OPTYPE;
   output  [127:0]            SERV_DPA_PATH;
   // PUF IF
   output  [7:0]              SERV_PUF_SUBCMD;   
   output  [7:0]              SERV_PUF_INKEYNUM;   
   output  [7:0]              SERV_PUF_KEYSIZE;   
   output  [31:0]             SERV_PUFUSERKEYADDR;
   output  [31:0]             SERV_USEREXTRINSICKEYADDR;
   output  [31:0]             SERV_SPIADDR;  
 
       
   // -----------   
   // Outputs   
   // -----------   
   
   // User IF    
   input                    SERV_BUSY;    
   input                    SERV_DATA_WRDY;    
   input                    SERV_DATA_RVALID;    
   input [31:0]             SERV_DATA_R;   

   input                    SERV_STATUS_VALID;
   input [7:0]              SERV_STATUS_RESP;    
   input                    SERV_TAMPER_MSGVALID;
   input [7:0]              SERV_TAMPER_MSG;
   
   input                    SERV_CMD_ERROR;   

   input [7:0]              command_req;
   input                    trigger_ext ;
   reg [31:0]               wdata = 1  ;
   reg [31:0]               i = 0  ;

   reg [5:0]                state ;
   reg [5:0]                next_state ;
   reg                      trigger_ext_reg ;
   // User IF    
    reg                    SERV_ENABLE_REQ;    
    reg [7:0]              SERV_CMDBYTE_REQ;    
    reg [5:0]              SERV_OPTIONS_MODE;    
    reg                    SERV_DATA_WVALID;
    reg [31:0]             SERV_DATA_W;    

   // Interrupts    
   
   // CRYPTO IF
    reg [255:0]            SERV_CRYPTO_KEY;
    reg [127:0]            SERV_CRYPTO_IV;
    reg [7:0]              SERV_CRYPTO_MODE;
    reg [15:0]             SERV_CRYPTO_NBLOCKS;
    reg [31:0]             SERV_CRYPTO_LENGTH;
   // NRBG IF               
    reg [7:0]              SERV_NRBG_LENGTH;
    reg [7:0]              SERV_NRBG_HANDLE;
    reg [7:0]              SERV_NRBG_ADDLENGTH;
    reg [7:0]              SERV_NRBG_PRREQ;
   // DPA IF
    reg [255:0]            SERV_DPA_KEY;
    reg [7:0]              SERV_DPA_OPTYPE;
    reg [127:0]            SERV_DPA_PATH;
   // PUF IF
    reg [7:0]              SERV_PUF_SUBCMD;   
    reg [7:0]              SERV_PUF_INKEYNUM;   
    reg [7:0]              SERV_PUF_KEYSIZE;   
    reg [31:0]             SERV_PUFUSERKEYADDR;
    reg [31:0]             SERV_USEREXTRINSICKEYADDR;
    reg [31:0]             SERV_SPIADDR;  


   localparam INIT 	= 5'h00;
   localparam SERV1 	= 5'h01;
   localparam RSP_PHASE = 5'h02;

   always@(posedge CLK or negedge RESETN) begin
    if(RESETN == 1'b0) begin
        trigger_ext_reg  <= 'd0;
        end else begin
        trigger_ext_reg  <= trigger_ext ;
       
    end
   end

//#######################################################################
//          COREUSERLOGIC STATE MACHINE LOGIC                           #
//#######################################################################
always@(*) begin
   case(state)
     INIT : begin
	if(trigger_ext_reg == 1'b1 ) begin
           case (command_req )
              1 : begin 
                     drive_serial_number_service() ;
                  end
              4: begin 
                     drive_usercode_service() ;
                  end
              0 : begin 
                     drive_device_certificate_service() ;
                  end
              5 : begin 
                     drive_user_design_version_service() ;
                  end
              3 : begin 
                     drive_128bit_AES_service() ;
                  end
              6 : begin 
                     drive_256bit_AES_service() ;
                  end
              10: begin 
                     drive_SHA_256_service() ;
                  end
              12 : begin 
                     drive_HMAC_service() ;
                  end
              9 : begin 
                    drive_key_tree_service() ;
                  end
              14: begin 
                     drive_pseudo_PUF_challege_response_service() ;
                  end
              40 : begin 
                     drive_self_test_service() ;
                  end
              41 : begin 
                     drive_instantiate_service() ;
                  end
              42 : begin 
                     drive_generate_service() ;
                  end
              43 : begin 
                     drive_reseed_service() ;
                  end
              44 : begin 
                     drive_uninstantiate_service() ;
                  end
              45 : begin 
                     drive_reset_service() ;
                  end
              240: begin 
                     drive_zeroization_service() ;
                  end
              20 : begin 
                     drive_IAP_service() ;
                  end
              21 : begin 
                     drive_ISP_service() ;
                  end
              23 : begin 
                   drive_NVM_data_integrity_service()   ;
                  end
              241 : begin 
                   drive_power_on_reset_digest_error()  ;
                  end
              16 : begin 
                   drive_ECC_mul_service()  ;
                  end
              17 : begin 
                   drive_ECC_add_service()  ;
                  end
              25 : begin 
                   drive_PUF_user_activation_code_service()  ;
                  end
              26 : begin 
                   drive_PUF_user_key_code_service()  ;
                  end
              27 : begin 
                   drive_PUF_fetch_user_key_service()  ;
                  end
              28 : begin 
                   drive_PUF_fetch_public_key_service()  ;
                  end
              29 : begin 
                   drive_PUF_get_seed_service()  ;
                  end
              30 : begin 
                   drive_secondary_device_certificate_service()  ;
                  end
              31 : begin 
                   drive_tamper_control_service()  ;
                  end
              default : begin 
                      drive_serial_number_service() ;
              end
           endcase
           next_state = SERV1;
        end
	else begin
           next_state = INIT;
        end
     end
     SERV1 : begin
          if(SERV_BUSY == 0)
            next_state = INIT ;
     end

  endcase

end

//#######################################################################
//          COREUSERLOGIC STATE CHANGE LOGIC                            #
//#######################################################################

always@(posedge CLK or negedge RESETN) begin
    if(RESETN == 1'b0) begin
        state <= 5'b00000;
        end else begin
        state <= next_state;
       
    end
end

initial begin
      SERV_DATA_W           = 32'd0 ;
      SERV_ENABLE_REQ       = 0     ;
      SERV_CMDBYTE_REQ      = 8'd0 ;
      SERV_CRYPTO_KEY       = 'd0 ;
      SERV_CRYPTO_IV        = 'd0 ;
      SERV_CRYPTO_MODE      = 'd0 ;
      SERV_CRYPTO_NBLOCKS   = 'd0 ;
      SERV_CRYPTO_LENGTH    = 'd0 ;
      SERV_DPA_KEY          = 'd0 ;
      SERV_DPA_OPTYPE       = 'd0 ;
      SERV_DPA_PATH         = 'd0 ;
      SERV_NRBG_LENGTH      = 'd0 ;
      SERV_NRBG_HANDLE      = 'd0 ;
      SERV_NRBG_ADDLENGTH   = 'd0 ;
      SERV_NRBG_PRREQ       = 'd0 ;
      SERV_OPTIONS_MODE     = 'd0 ;
      SERV_DATA_WVALID      = 'd0 ;
     
      SERV_PUF_SUBCMD       = 'd0  ;
      SERV_PUFUSERKEYADDR        = 'h0  ;
      SERV_USEREXTRINSICKEYADDR  = 'h0  ;
      SERV_PUF_INKEYNUM     = 'd0  ;
      SERV_PUF_KEYSIZE      = 'd0  ;

      SERV_SPIADDR          = 'd0  ;
 
 end


//============================================================
//  Drive drive_serial_number_service
//============================================================
task  drive_serial_number_service(  );
   begin
      //$display(TIME=$time,"Driving drive_serial_number_service ");
      @ (posedge CLK);
      SERV_CMDBYTE_REQ           <= 8'd1  ;
      SERV_ENABLE_REQ            <= 1'b1 ;

      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b0 ;
      SERV_CMDBYTE_REQ           <= 'd0 ;

      repeat(10) @ (posedge CLK);
  end
endtask



//============================================================
//  Drive drive_usercode_service
//============================================================
task  drive_usercode_service(  );
   begin

      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 8'd4  ;

      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b0 ;
      SERV_CMDBYTE_REQ           <= 'd0 ;

      repeat(10) @ (posedge CLK);
 end
endtask



//============================================================
//  Drive drive_device_certificate_service
//============================================================
task  drive_device_certificate_service(  );
   begin

      //$display("Driving drive_device_certificate_service");
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 8'd0  ;

      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b0 ;
      SERV_CMDBYTE_REQ           <= 'd0 ;

 end
endtask




//============================================================
//  Drive drive_user_design_version_service
//============================================================
task  drive_user_design_version_service(  );
   begin

      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 8'd5  ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b0 ;
      SERV_CMDBYTE_REQ           <= 'd0 ;

 end
endtask





//============================================================
//  Drive drive_128bit_AES_servic/e
//============================================================
task  drive_128bit_AES_service(  );
   begin
      // wait for busy low
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 8'd3  ;
      
      // Drive Discriptor 
      SERV_CRYPTO_KEY       <= 256'h0000_0000_0000_0000_0000_0000_0000_0000_100F_0E0D_0C0B_0A09_0807_0605_0403_0201 ;
      SERV_CRYPTO_IV <= 128'h201F_1E1D_1C1B_1A19_1817_1615_1413_1211 ;
      SERV_CRYPTO_MODE      <= 8'd1 ;       // 0(enc), 1(decr) 
      SERV_CRYPTO_NBLOCKS   <= 16'h1 ;      // no.of 128bit blocks

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_CRYPTO_KEY       <= 256'h0 ;
      SERV_CRYPTO_IV <= 128'h0 ;
      SERV_CRYPTO_MODE      <= 8'd0 ;       // 0(enc), 1(decr) 
      SERV_CRYPTO_NBLOCKS   <= 16'h0 ;      // no.of 128bit blocks
 
          wdata = 32'h2 ;
          // Drive Data 1*4 = NBLOCKS*4 
          repeat ( 1*4 ) begin  
             // wait for SERV_DATA_WRDY & Drive plain data
             wait(SERV_DATA_WRDY);
             @ (posedge CLK);
             SERV_DATA_WVALID <= 'd1 ;
             SERV_DATA_W      <= wdata ;

             @ (posedge CLK);
             wdata = wdata + 1 ;
             SERV_DATA_WVALID <= 'd0 ;
          end

      
 end
endtask




//============================================================
//  Drive drive_256bit_AES_service
//============================================================
task  drive_256bit_AES_service(  );
   begin
      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 8'd6  ;
      
      // Drive Discriptor
      SERV_CRYPTO_KEY       <= 256'h201F_1E1D_1C1B_1A19_1817_1615_1413_1211_100F_0E0D_0C0B_0A09_0807_0605_0403_0201 ;
      SERV_CRYPTO_IV <= 128'h302F_2E2D_2C2B_2A29_2827_2625_2423_2221 ; 
      SERV_CRYPTO_MODE      <= 8'd0 ;
      SERV_CRYPTO_NBLOCKS   <= 16'd2 ;
      SERV_CRYPTO_LENGTH    <= 32'd1 ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_CRYPTO_KEY       <= 256'h0 ;
      SERV_CRYPTO_IV <= 128'h0 ;
      SERV_CRYPTO_MODE      <= 8'd0 ;       // 0(enc), 1(decr) 
      SERV_CRYPTO_NBLOCKS   <= 16'h0 ;      // no.of 128bit blocks
      SERV_CRYPTO_LENGTH    <= 32'h0 ;      // Length of data

         // Drive Data 1*4 = NBLOCKS*4 
         wdata = 2;
         repeat ( 2*4 ) begin  
            // wait for SERV_DATA_WRDY & Drive plain data
            wait(SERV_DATA_WRDY);
            @ (posedge CLK);
            SERV_DATA_WVALID <= 'd1 ;
            SERV_DATA_W      <= wdata ;
         
            @ (posedge CLK);
            wdata = wdata + 1 ;
            SERV_DATA_WVALID <= 'd0 ;
         end
         
         
 end
endtask
         
         


//============================================================
//  Drive drive_SHA_256_service
//============================================================
task  drive_SHA_256_service(  );
   begin

      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 10 ;
      
      // Drive Discriptor 
      SERV_CRYPTO_LENGTH    <= 'd33 ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_CRYPTO_LENGTH    <= 'd0 ;

         // Drive Data 1*4 = NBLOCKS*4 
         wdata = 2;
         repeat ( 1*2 ) begin  
            // wait for SERV_DATA_WRDY & Drive plain data
            wait(SERV_DATA_WRDY);
            @ (posedge CLK);
            SERV_DATA_WVALID <= 'd1 ;
            SERV_DATA_W      <= wdata ;

            @ (posedge CLK);
            wdata = wdata + 1 ;
            SERV_DATA_WVALID <= 'd0 ;


         end

         wdata = 2;

 end
endtask




//============================================================
//  Drive drive_HMAC_service
//============================================================
task  drive_HMAC_service(  );
   begin

      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 12  ;
      
      // Drive Discriptor 
      SERV_CRYPTO_KEY       <= 256'h201F_1E1D_1C1B_1A19_1817_1615_1413_1211_100F_0E0D_0C0B_0A09_0807_0605_0403_0201 ;
      SERV_CRYPTO_LENGTH    <= 'd9 ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_CRYPTO_KEY       <= 256'h0 ;
      SERV_CRYPTO_LENGTH    <= 'd0 ;

          // Drive Data 1*4 = NBLOCKS*4 
          wdata = 2;
          repeat ( 1*3 ) begin  
             // wait for SERV_DATA_WRDY & Drive plain data
             wait(SERV_DATA_WRDY);
             @ (posedge CLK);
             SERV_DATA_WVALID <= 'd1 ;
             SERV_DATA_W      <= wdata ;

             @ (posedge CLK);
             wdata = wdata + 1 ;
             SERV_DATA_WVALID <= 'd0 ;

          end

          wdata = 2;
      
 end
endtask




//============================================================
//  Drive drive_key_tree_service
//============================================================
task  drive_key_tree_service(  );
   begin
      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 9  ;

      SERV_DPA_KEY          <= 256'h201F_1E1D_1C1B_1A19_1817_1615_1413_1211_100F_0E0D_0C0B_0A09_0807_0605_0403_0201 ;
      SERV_DPA_OPTYPE       <= 8'h01 ; 
      SERV_DPA_PATH         <= 128'h302F_2E2D_2C2B_2A29_2827_2625_2423_2221 ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_DPA_KEY          <= 256'h0 ;
      SERV_DPA_OPTYPE       <= 8'h0 ; 
      SERV_DPA_PATH         <= 128'h0 ;


 end
endtask




//============================================================
//  Drive drive_pseudo_PUF_challege_response_service
//============================================================
task  drive_pseudo_PUF_challege_response_service(  );
   begin

      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 14  ;
      
      SERV_DPA_OPTYPE       <= 8'h01 ; 
      SERV_DPA_PATH         <= 128'h302F_2E2D_2C2B_2A29_2827_2625_2423_2221 ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_DPA_OPTYPE       <= 8'h00 ; 
      SERV_DPA_PATH         <= 128'h0 ;

 end
endtask




//============================================================
//  Drive drive_self_test_service
//============================================================
task  drive_self_test_service(  );
   begin

      
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 40  ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;


 end
endtask




//============================================================
//  Drive drive_instantiate_service
//============================================================
task  drive_instantiate_service(  );
   begin


      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 41  ;
      SERV_NRBG_LENGTH      <= 16'd4 ;
      SERV_NRBG_HANDLE      <= 8'hFF ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_NRBG_LENGTH      <= 16'd0 ;
      SERV_NRBG_HANDLE      <= 8'h0 ;

      repeat ( 1*1 ) begin  
         // wait for SERV_DATA_WRDY & Drive plain data
         wait(SERV_DATA_WRDY);
         @ (posedge CLK);
         SERV_DATA_WVALID <= 'd1 ;
         SERV_DATA_W      <= wdata ;

         @ (posedge CLK);
         wdata = wdata + 1 ;
         SERV_DATA_WVALID <= 'd0 ;
      end

 end
endtask




//============================================================
//  Drive drive_generate_service
//============================================================
task  drive_generate_service(  );
   begin
  
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 42  ;
      SERV_NRBG_LENGTH      <= 16'd0 ;
      SERV_NRBG_HANDLE      <= 8'h00 ;
      SERV_NRBG_ADDLENGTH   <= 8'h0 ;
      SERV_NRBG_PRREQ       <= 8'h0 ;
      
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_NRBG_LENGTH      <= 16'd0 ;
      SERV_NRBG_HANDLE      <= 8'h0 ;
      SERV_NRBG_ADDLENGTH   <= 8'h0 ;

      wdata = 2;
      repeat ( 1*1 ) begin  
         // wait for SERV_DATA_WRDY & Drive plain data
         wait(SERV_DATA_WRDY);
         @ (posedge CLK);
         SERV_DATA_WVALID <= 'd1 ;
         SERV_DATA_W      <= wdata ;

         @ (posedge CLK);
         wdata = wdata + 1 ;
         SERV_DATA_WVALID <= 'd0 ;
      end

      wdata = 1;

 end
endtask




//============================================================
//  Drive drive_reseed_service
//============================================================
task  drive_reseed_service(  );
   begin

      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 43  ;
      SERV_NRBG_LENGTH      <= 16'd32 ;
      SERV_NRBG_HANDLE      <= 8'hFF ;
      SERV_NRBG_ADDLENGTH   <= 8'h7 ;
      SERV_NRBG_PRREQ       <= 8'h0 ;
      

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_NRBG_LENGTH      <= 16'd0 ;
      SERV_NRBG_HANDLE      <= 8'h0 ;
      SERV_NRBG_ADDLENGTH   <= 8'h0 ;

      repeat ( 1*2 ) begin  
         // wait for SERV_DATA_WRDY & Drive plain data
         wait(SERV_DATA_WRDY);
         @ (posedge CLK);
         SERV_DATA_WVALID <= 'd1 ;
         SERV_DATA_W      <= wdata ;

         @ (posedge CLK);
         wdata = wdata + 1 ;
         SERV_DATA_WVALID <= 'd0 ;
      end

 end
endtask




//============================================================
//  Drive drive_uninstantiate_service
//============================================================
task  drive_uninstantiate_service(  );
   begin

      
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 44  ;
      SERV_NRBG_HANDLE      <= 8'hFF ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_NRBG_HANDLE      <= 8'h00 ;


 end
endtask




//============================================================
//  Drive drive_reset_service
//============================================================
task  drive_reset_service(  );
   begin

      
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 45  ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;


 end
endtask




//============================================================
//  Drive drive_zeroization_service
//============================================================
task  drive_zeroization_service(  );
   begin

      
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 240  ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;


 end
endtask





//============================================================
//  Drive drive_IAP_service
//============================================================
task  drive_IAP_service(  );
   begin

      
      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 20  ;
      SERV_OPTIONS_MODE          <= 0  ;
      SERV_SPIADDR               <= 32'h2000_3000 ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_OPTIONS_MODE     <= 'd0 ;
      SERV_SPIADDR          <= 32'h0 ;


 end
endtask





//============================================================
//  Drive drive_ISP_service
//============================================================
task  drive_ISP_service(  );
   begin

      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 21  ;
      
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;


 end
endtask




//============================================================
//  Drive drive_NVM_data_integrity_service
//============================================================
task  drive_NVM_data_integrity_service(  );
   begin

      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 23  ;
      SERV_OPTIONS_MODE     <= 1 ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_OPTIONS_MODE     <= 'd0 ;


 end
endtask




//============================================================
//  Drive drive_power_on_reset_digest_error
//============================================================
task  drive_power_on_reset_digest_error(  );
   begin

      
      // SERV_ENABLE_REQ            <= 1'b1 ;
      // SERV_CMDBYTE_REQ           <= SERV_CMDBYTE_REQ  ;
      
      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;


 end
endtask

//============================================================
// drive_ECC_mul_service Drive 
//============================================================
task  drive_ECC_mul_service(  );
   begin

      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 16  ;
      

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;

      repeat ( 36 ) begin  
         // wait for SERV_DATA_WRDY & Drive plain data
         wait(SERV_DATA_WRDY);
         @ (posedge CLK);
         SERV_DATA_WVALID <= 'd1 ;
         SERV_DATA_W      <= wdata ;

         @ (posedge CLK);
         wdata = wdata + 1 ;
         SERV_DATA_WVALID <= 'd0 ;
      end

     // fill ram with result
     wdata =1 ;
     i     = 0 ;

 end
endtask

//============================================================
// drive_ECC_add_service Drive 
//============================================================
task  drive_ECC_add_service(  );
   begin

      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 17  ;
      

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;

      repeat ( 48 ) begin  
         // wait for SERV_DATA_WRDY & Drive plain data
         wait(SERV_DATA_WRDY);
         @ (posedge CLK);
         SERV_DATA_WVALID <= 'd1 ;
         SERV_DATA_W      <= wdata ;

         @ (posedge CLK);
         wdata = wdata + 1 ;
         SERV_DATA_WVALID <= 'd0 ;
      end

     // fill ram with result
     wdata =1 ;

 end
endtask


//============================================================
// drive_PUF_user_activation_code_service  
//============================================================
task  drive_PUF_user_activation_code_service (  );
   begin

      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 25  ;
      SERV_PUF_SUBCMD       <= 1   ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0 ;
      SERV_PUF_SUBCMD       <= 0   ;

 end
endtask


//============================================================
// drive_PUF_user_key_code_service  
//============================================================
task  drive_PUF_user_key_code_service (  );
   begin

      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 26     ;
      SERV_PUF_SUBCMD       <= 0      ;
      SERV_PUFUSERKEYADDR   <= 32'h2000_3100      ;
      SERV_USEREXTRINSICKEYADDR  <= 32'h2000_3200  ;
      SERV_PUF_INKEYNUM     <=  4   ;
      SERV_PUF_KEYSIZE      <=   8   ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0  ;
      SERV_PUF_SUBCMD       <= 'd0  ;
      SERV_PUFUSERKEYADDR        <= 'h0  ;
      SERV_USEREXTRINSICKEYADDR  <= 'h0  ;
      SERV_PUF_INKEYNUM     <= 'd0  ;
      SERV_PUF_KEYSIZE      <= 'd0  ;


      if(SERV_PUF_SUBCMD ==1 |SERV_PUF_SUBCMD == 2 ) begin
         repeat ( SERV_PUF_KEYSIZE*64/32 ) begin  
            // wait for SERV_DATA_WRDY & Drive plain data
            wait(SERV_DATA_WRDY);
            @ (posedge CLK);
            SERV_DATA_WVALID <= 'd1 ;
            SERV_DATA_W      <= wdata ;

            @ (posedge CLK);
            wdata = wdata + 1 ;
            SERV_DATA_WVALID <= 'd0 ;
         end
      end


 end
endtask

//============================================================
// drive_PUF_fetch_user_key_service   
//============================================================
task  drive_PUF_fetch_user_key_service  (  );
   begin

      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 27  ;
      SERV_PUFUSERKEYADDR   <= 32'h2000_3300      ;
      SERV_PUF_INKEYNUM     <= 4   ;
      SERV_PUF_KEYSIZE      <= 8    ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0  ;
      SERV_PUFUSERKEYADDR        <= 'h0  ;
      SERV_PUF_INKEYNUM     <= 'd0  ;
      SERV_PUF_KEYSIZE      <= 'd0  ;
      

 end
endtask

//============================================================
// drive_PUF_fetch_public_key_service    
//============================================================
task  drive_PUF_fetch_public_key_service (  );
   begin
      
      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 28  ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0  ;


 end
endtask

//============================================================
// drive_PUF_get_seed_service     
//============================================================
task  drive_PUF_get_seed_service (  );
   begin

      SERV_ENABLE_REQ       <= 1'b1 ;
      SERV_CMDBYTE_REQ      <= 29  ;

      @ (posedge CLK);
      SERV_ENABLE_REQ       <= 1'b0 ;
      SERV_CMDBYTE_REQ      <= 'd0  ;

 end
endtask

//============================================================
//  Drive drive_secondary_device_certificate_service
//============================================================
task  drive_secondary_device_certificate_service (  );
   begin

      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 30  ;

      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b0 ;
      SERV_CMDBYTE_REQ           <= 'd0 ;


 end
endtask

//============================================================
//  Drive drive_tamper_control_service 
//============================================================
task drive_tamper_control_service (  );
   begin

      SERV_ENABLE_REQ            <= 1'b1 ;
      SERV_CMDBYTE_REQ           <= 31  ;
      SERV_OPTIONS_MODE          <= 6'b11_1001  ;

      @ (posedge CLK);
      SERV_ENABLE_REQ            <= 1'b0 ;
      SERV_CMDBYTE_REQ           <= 'd0 ;
      SERV_OPTIONS_MODE          <= 'd0 ;

 end
endtask


endmodule

