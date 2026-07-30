// ********************************************************************/
// Actel Corporation Proprietary and Confidential
//  Copyright 2011 Actel Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description:  
// //  testbench: Top-level testbench for User TB verification
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

`timescale 1ns/100ps

module testbench;
`include "coreparameters.v"

   parameter SYSCLK_PERIOD = 10; 

   reg SYSCLK;
   reg NSYSRESET;

   wire                      SERV_ENABLE_REQ;    
   wire   [7:0]              SERV_CMDBYTE_REQ;    
   wire   [5:0]              SERV_OPTIONS_MODE;    
   wire                      SERV_DATA_WVALID;
   wire   [31:0]             SERV_DATA_W;    

   // CRYPTO IF
   wire   [255:0]            SERV_CRYPTO_KEY;
   wire   [127:0]            SERV_CRYPTO_IV;
   wire   [7:0]              SERV_CRYPTO_MODE;
   wire   [15:0]             SERV_CRYPTO_NBLOCKS;
   wire   [31:0]             SERV_CRYPTO_LENGTH;
   // NRBG IF               
   wire   [7:0]              SERV_NRBG_LENGTH;
   wire   [7:0]              SERV_NRBG_HANDLE;
   wire   [7:0]              SERV_NRBG_ADDLENGTH;
   wire   [7:0]              SERV_NRBG_PRREQ;
   // DPA IF
   wire   [255:0]            SERV_DPA_KEY;
   wire   [7:0]              SERV_DPA_OPTYPE;
   wire   [127:0]            SERV_DPA_PATH;
   // PUF IF
   wire   [7:0]              SERV_PUF_SUBCMD;   
   wire   [7:0]              SERV_PUF_INKEYNUM;   
   wire   [7:0]              SERV_PUF_KEYSIZE;   
   wire   [31:0]             SERV_PUFUSERKEYADDR;   
   wire   [31:0]             SERV_USEREXTRINSICKEYADDR;   
   wire   [31:0]             SERV_SPIADDR;   
      
   wire                      SERV_TAMPER_MSGVALID ; 
   wire   [7:0]              SERV_TAMPER_MSG ; 

   wire                      SERV_CMD_ERROR ; 
   // User IF    
   wire                      SERV_BUSY;    
   wire                      SERV_DATA_WRDY;    
   wire                      SERV_DATA_RVALID;    
   wire   [31:0]             SERV_DATA_R;   

   wire                      SERV_STATUS_VALID;
   wire   [7:0]              SERV_STATUS_RESP;    

   wire                      COMM_BLK_INT ;

   wire   [31:0] HADDR;
   wire   [2:0]  HBURST;
   wire   [31:0] HRDATA;
   wire   [2:0]  HSIZE;
   wire   [1:0]  HTRANS;
   wire   [31:0] HWDATA;
   wire          HWRITE;
   wire          HSEL;

   wire          HREADY;
   wire          HRESP;

   reg           trigger_ext;
   reg [7:0]     command_req;

initial
begin
    SYSCLK = 1'b0;
    NSYSRESET = 1'b0;
    command_req = 0 ;
    trigger_ext = 0 ;
end


//////////////////////////////////////////////////////////////////////
// Reset Pulse
//////////////////////////////////////////////////////////////////////
initial
begin
    #(50) @ (posedge SYSCLK);
    NSYSRESET = 1'b1;
    #(50) @ (posedge SYSCLK);

    trigger_ext = 1'b0;
	
    $display("\n#################################################################");
    $display("## TESTBENCH_INFO: Microsemi CoreSysServices User Test Bench     ##"); 
    $display("## CoreSysServices 3.1 (April 2015)                              ##");
    $display("###################################################################\n");

    $display("##################################################################");
    $display("## Basic Test Configurations available for following services:  ##");
    $display("##################################################################");
    $display("##          Test 1:  Serial Number Service                      ##");
    $display("##          Test 2:  User Code Service                          ##");
    $display("##          Test 3:  Device CertificateService                  ##");
    $display("##          Test 4:  User Design Version Service                ##");
    $display("##          Test 5:  Crypto AES-128 Service                     ##");
    $display("##          Test 6:  Crypto AES-256 Service                     ##");
    $display("##          Test 7:  Crypto SHA-256 Service                     ##");
    $display("##          Test 8:  Crypto HMAC Service                        ##");
    $display("##          Test 9:  KEY TREE SERVICE  Service                  ##");
    $display("##          Test 10: Challenge Response SERVICE  Service        ##");
    $display("##          Test 11: NRBG Self Test SERVICE  Service            ##");
    $display("##          Test 12: Zeroization Service                        ##");
    $display("##          Test 13: IAP Service                                ##");
    $display("##          Test 14: ECC POINT MULT Service                     ##");
    $display("##          Test 15: ECC POINT ADD Service                      ##");
    $display("##          Test 16: PROG NVM DI Service                        ##");
    $display("##          Test 17: PUF user activation code Service           ##");
    $display("##          Test 18: SECONDARY DEVICE CERT  Service             ##");
    $display("##          Test 19: TAMPER CONTROL Service                     ##");
    $display("##################################################################\n\n\n");

    // Drive the services one after the other

    if(SNSERVICE == 1) begin
      $display("################################################################");
      $display("##          Running Test 1: Serial Number Service             ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h01  ;
      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(UCSERVICE == 1) begin
      $display("################################################################");
      $display("##          Running Test 2: User Code Service                 ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h04  ;
      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(DCSERVICE == 1) begin
      $display("################################################################");
      $display("##          Running Test 3: Device Certificate Service        ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h00  ;
      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end
 
    else if( UDVSERVICE == 1) begin
      $display("################################################################");
      $display("##          Running Test 4: User Design Version Service       ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h05  ;
      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(CRYPTOAES128SERVICE == 1) begin
      $display("################################################################");
      $display("##            Running Test 5: Crypto AES-128 Service          ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h03  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(CRYPTOAES256SERVICE == 1) begin
      $display("################################################################");
      $display("##             Running Test 6: Crypto AES-256 Service         ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h06  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(CRYPTOSHA256SERVICE == 1) begin
      $display("################################################################");
      $display("##             Running Test 7: Crypto SHA-256 Service         ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h0A  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(CRYPTOHMACSERVICE == 1) begin
      $display("################################################################");
      $display("##             Running Test 8: Crypto HMAC Service            ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h0C  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(KEYTREESERVICE == 1) begin
      $display("################################################################");
      $display("##             Running Test 9: KEY TREE SERVICE  Service      ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'h09  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(CHRESPSERVICE == 1) begin
      $display("#######################################################################");
      $display("##             Running Test 10: Challenge Response SERVICE  Service  ##");
      $display("#######################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd14  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(NRBGSERVICE == 1) begin
      $display("##########################################################################");
      $display("##             Running Test 11:NRBG Self Running Test SERVICE  Service  ##");
      $display("##########################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd40  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end
    
    else if(ZERSERVICE == 1) begin
      $display("################################################################");
      $display("##             Running Test 12: Zeroization Service           ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'hF0  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(PROGIAPSERVICE  == 1) begin
      $display("################################################################");
      $display("##             Running Test 13: IAP Service                   ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd20  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(ECCPOINTMULTSERVICE   == 1) begin
      $display("################################################################");
      $display("##             Running Test 14: ECC POINT MULT Service        ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd16  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(ECCPOINTADDSERVICE   == 1) begin
      $display("################################################################");
      $display("##             Running Test 15: ECC POINT ADD Service         ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd17  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if(PROGNVMDISERVICE   == 1) begin
      $display("################################################################");
      $display("##             Running Test 16: PROG NVM DI Service           ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd23  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    
    else if( PUFSERVICE  == 1) begin
      $display("#######################################################################");
      $display("##             Running Test 17: PUF user activation code Service     ##");
      $display("#######################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd25  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

     else if( SECDCSERVICE  == 1) begin
      $display("#######################################################################");
      $display("##             Running Test 18: SECONDARY DEVICE CERT  Service       ##");
      $display("#######################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd30  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    else if( TAMPERCONTROLSERVICE  == 1) begin
      $display("################################################################");
      $display("##             Running Test 19:TAMPER CONTROL Service         ##");
      $display("################################################################");
      #(10 ) @ (posedge SYSCLK);
      trigger_ext = 1'b1;
      command_req <= 8'd31  ;

      @ (posedge SYSCLK);
      trigger_ext = 1'b0;

      #50000 @ (posedge SYSCLK);
    end

    #10000 @ (posedge SYSCLK);

    $display(" ");
    $display("----------------------------------------------------------------\n ");
    $display("               -- Simulation complete --                        \n ");
    $display("----------------------------------------------------------------\n ");
    $display(" ");

    $finish;


end


//////////////////////////////////////////////////////////////////////
// 10MHz Clock Driver
//////////////////////////////////////////////////////////////////////
always @(SYSCLK)
    #(SYSCLK_PERIOD / 2.0) SYSCLK <= !SYSCLK;

//////////////////////////////////////////////////////////////////////
// Instantiate User Logic
//////////////////////////////////////////////////////////////////////
UserDriver Inst_UserDriver_0 (    
     .CLK(SYSCLK),
     .RESETN(NSYSRESET ),

// System Services Signals
     .SERV_BUSY(SERV_BUSY),                   

     .SERV_DATA_WRDY(SERV_DATA_WRDY),
     .SERV_DATA_W(SERV_DATA_W),
     .SERV_DATA_WVALID(SERV_DATA_WVALID),

     .SERV_DATA_RVALID(SERV_DATA_RVALID),
     .SERV_DATA_R(SERV_DATA_R),

     .SERV_ENABLE_REQ(SERV_ENABLE_REQ),
     .SERV_CMDBYTE_REQ(SERV_CMDBYTE_REQ),

     .SERV_DPA_KEY(SERV_DPA_KEY),
     .SERV_DPA_OPTYPE(SERV_DPA_OPTYPE),
     .SERV_DPA_PATH(SERV_DPA_PATH),
     
     .SERV_CRYPTO_KEY(SERV_CRYPTO_KEY),
     .SERV_CRYPTO_IV(SERV_CRYPTO_IV),
     .SERV_CRYPTO_MODE(SERV_CRYPTO_MODE),
     .SERV_CRYPTO_NBLOCKS(SERV_CRYPTO_NBLOCKS),
     .SERV_CRYPTO_LENGTH(SERV_CRYPTO_LENGTH),

     .SERV_NRBG_LENGTH(SERV_NRBG_LENGTH),
     .SERV_NRBG_HANDLE(SERV_NRBG_HANDLE),
     .SERV_NRBG_ADDLENGTH(SERV_NRBG_ADDLENGTH),
     .SERV_NRBG_PRREQ(SERV_NRBG_PRREQ),
     
     .SERV_STATUS_RESP(SERV_STATUS_RESP),
     .SERV_STATUS_VALID(SERV_STATUS_VALID),
     .SERV_TAMPER_MSGVALID(SERV_TAMPER_MSGVALID),
     .SERV_TAMPER_MSG(SERV_TAMPER_MSG),
     .SERV_CMD_ERROR(SERV_CMD_ERROR),

     .SERV_OPTIONS_MODE(SERV_OPTIONS_MODE),
     
     
     .SERV_PUF_SUBCMD      (SERV_PUF_SUBCMD),     
     .SERV_PUF_INKEYNUM      (SERV_PUF_INKEYNUM),     
     .SERV_PUF_KEYSIZE      (SERV_PUF_KEYSIZE),     
     
     .SERV_PUFUSERKEYADDR      (SERV_PUFUSERKEYADDR),     
     .SERV_USEREXTRINSICKEYADDR(SERV_USEREXTRINSICKEYADDR),     
     
     .command_req(command_req),
     .trigger_ext(trigger_ext),
     .SERV_SPIADDR    (SERV_SPIADDR)
);


//////////////////////////////////////////////////////////////////////
// Instantiate Unit Under  Test:  CoreSysServices
//////////////////////////////////////////////////////////////////////
CORESYSSERVICES_C0_CORESYSSERVICES_C0_0_CORESYSSERVICES #(
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
             .FFSERVICE           (FFSERVICE),   

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
                             ) U_CORESYSSERVICES0 (	
                                       .CLK(SYSCLK),    
                                       .RESETN(NSYSRESET),    

                                       // AHBL Master IF    
                                       .HCLK(SYSCLK),    
                                       .HRESETN(NSYSRESET),    
                                       .HSEL(HSEL),    
                                       .HADDR(HADDR),    
                                       .HWRITE(HWRITE),    
                                       .HWDATA(HWDATA),    
                                       .HTRANS(HTRANS),    
                                       .HBURST(HBURST),    
                                       .HSIZE(HSIZE),    
                                       .HRESP(HRESP),    
                                       .HREADY(HREADY),    
                                       .HRDATA(HRDATA),    

                                       // User IF    
                                       .SERV_BUSY(SERV_BUSY),    
                                       .SERV_ENABLE_REQ(SERV_ENABLE_REQ),    
                                       .SERV_CMDBYTE_REQ(SERV_CMDBYTE_REQ),    
                                       .SERV_STATUS_VALID(SERV_STATUS_VALID),
                                       .SERV_STATUS_RESP(SERV_STATUS_RESP),    
                                       .SERV_TAMPER_MSGVALID(SERV_TAMPER_MSGVALID),
                                       .SERV_TAMPER_MSG(SERV_TAMPER_MSG),

                                       .SERV_CMD_ERROR(SERV_CMD_ERROR),        
                                       .SERV_OPTIONS_MODE(SERV_OPTIONS_MODE),    

                                       .SERV_DATA_WVALID(SERV_DATA_WVALID),    
                                       .SERV_DATA_W(SERV_DATA_W),
                                       .SERV_DATA_WRDY(SERV_DATA_WRDY),
                                       .SERV_DATA_RVALID(SERV_DATA_RVALID),    
                                       .SERV_DATA_R(SERV_DATA_R),    
                                       
                                       // Interrupts    
                                       .COMM_BLK_INT(COMM_BLK_INT),

                                       // CRYPTO IF
                                       .SERV_CRYPTO_KEY(SERV_CRYPTO_KEY),
                                       .SERV_CRYPTO_IV(SERV_CRYPTO_IV),
                                       .SERV_CRYPTO_MODE(SERV_CRYPTO_MODE),
                                       .SERV_CRYPTO_NBLOCKS(SERV_CRYPTO_NBLOCKS),
                                       .SERV_CRYPTO_LENGTH(SERV_CRYPTO_LENGTH),

                                       // NRBG IF
                                       .SERV_NRBG_LENGTH(SERV_NRBG_LENGTH),
                                       .SERV_NRBG_HANDLE(SERV_NRBG_HANDLE),
                                       .SERV_NRBG_ADDLENGTH(SERV_NRBG_ADDLENGTH),
                                       .SERV_NRBG_PRREQ(SERV_NRBG_PRREQ),

                                       // DPA IF
                                       .SERV_DPA_KEY(SERV_DPA_KEY),
                                       .SERV_DPA_OPTYPE(SERV_DPA_OPTYPE),
                                       .SERV_DPA_PATH(SERV_DPA_PATH),

                                       // PUF IF
                                       .SERV_PUF_SUBCMD(SERV_PUF_SUBCMD),
                                       .SERV_PUF_INKEYNUM(SERV_PUF_INKEYNUM),
                                       .SERV_PUF_KEYSIZE(SERV_PUF_KEYSIZE),
                                       .SERV_PUFUSERKEYADDR      (SERV_PUFUSERKEYADDR),     
                                       .SERV_USEREXTRINSICKEYADDR(SERV_USEREXTRINSICKEYADDR),     

                                       .SERV_SPIADDR    (SERV_SPIADDR)
                                       );


                comm_block  comm_block_0 (
                                         // AHBL Master IF    
                                       .HCLK(SYSCLK),    
                                       .HRESETN(NSYSRESET),    
                                       .HSEL(HSEL),    
                                       .HADDR(HADDR),    
                                       .HWRITE(HWRITE),    
                                       .HWDATA(HWDATA),    
                                       .HTRANS(HTRANS),    
                                       .HBURST(HBURST),    
                                       .HSIZE(HSIZE),    
                                       .HRESP(HRESP),    
                                       .HREADY(HREADY),    
                                       .HRDATA(HRDATA),
                                       .COMM_BLK_INT(COMM_BLK_INT)
                               );

endmodule

