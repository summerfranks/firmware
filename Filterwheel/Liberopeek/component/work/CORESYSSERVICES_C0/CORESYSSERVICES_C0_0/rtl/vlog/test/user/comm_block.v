// Actel Corporation Proprietary and Confidential
//  Copyright 2011 Actel Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description:  
// //  comm_block: Communication block model
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

module comm_block(
   HCLK   ,
   HRESETN ,
   HADDR  ,
   HSEL   ,
   HTRANS ,
   HWRITE ,
   HWDATA ,
   HBURST ,
   HSIZE  ,

   HREADY ,
   HRDATA ,
   HRESP  ,
   COMM_BLK_INT ) ;


`include "coreparameters.v"
parameter AHB_DELAY  = 5 ;
parameter AHB_DELAY2 = 20 ;
parameter CMD_ERROR  = 0 ;

  input         HCLK    ;
  input         HRESETN ;
  input  [31:0] HADDR   ;
  input         HSEL   ;
  input  [1:0]  HTRANS  ;
  input  [2:0]  HBURST  ;
  input  [2:0]  HSIZE  ;
  input         HWRITE  ;
  input  [31:0] HWDATA  ;

  output         HREADY      ;
  output  [31:0] HRDATA      ;
  output         HRESP       ;
  output         COMM_BLK_INT;
  reg        HREADY      ;
  reg [31:0] HRDATA      ;
  reg        HRESP       ;
  reg        COMM_BLK_INT;
  // ---------------------------------------------------------------------------
  // |  R  |  R  | loopback | enable | size Rx | size Tx | flush In | flush Out|
  // ---------------------------------------------------------------------------
  reg [7:0]     control_reg ; 
 
  // -----------------------------------------------------------------------------
  // | cmd  | SIIerr | flush Rx | SII done | Underflow | Overflow | Rx ok | Tx ok|
  // -----------------------------------------------------------------------------
  reg [7:0]     status_reg ;
  reg [7:0]     status_reg_d ;

  reg [7:0]     int_enable_reg ;

  reg [7:0]     data8_reg ;
  reg [31:0]    data32_reg ;

  reg [7:0]     frame8_reg ; 
  reg [31:0]    frame32_reg ;

  reg [31:0]    HADDR_r ; 
  reg           PREADY_r ;
  reg           HWRITE_r ;

  reg [3:0]     rand_status ;
  reg [2:0]     rand_timer ;

  // FIIC registers
  reg [31:0]    INTERRUPT_ENABLE0 ;
  reg [31:0]    INTERRUPT_ENABLE1 ;
  reg [31:0]    INTERRUPT_REASON0 ;
  reg [31:0]    INTERRUPT_REASON1 ;
  reg [11:0]    Interrupt_Mode    ;
  reg [31:0]    present_cmd       ;

  reg           response_phase    ;
  reg           response_phase_d1    ;
  reg [2:0]     phase_value       ;

  reg [7:0]     cmd_options       ;

  reg           WR_DATA_phase ;

//  reg [31:0]    slave_memory[0:536936447] ;
  reg [31:0]    slave_memory[0:100] ;  
  reg [31:0]    mem_data = 1 ;

 
  always @(posedge HCLK or negedge HRESETN) begin
     if(!HRESETN) begin 
        COMM_BLK_INT         <= 1'b0 ;
     end else  begin
        if(INTERRUPT_ENABLE0[29]) 
          COMM_BLK_INT    <= (|(int_enable_reg & status_reg) ) ;
        else 
          COMM_BLK_INT    <= 1'b0 ; // enhance FIIC int enable
     end
  end
  
 
 //============================================
 // HREADY generation 
 //============================================
  always @(posedge HCLK or negedge HRESETN) begin
     if(!HRESETN) begin 
       HREADY        <= 1'b0 ;
       HRESP         <= 1'b0 ;
     end else  begin
       repeat(2) @ (posedge HCLK);
       HREADY        <= ~HREADY  ;
       HRESP         <= 1'b0 ;
     end
  end 

 //============================================
 // Write transaction eSRAM
 //============================================
 always @ (negedge HCLK or negedge HRESETN ) begin      
    if(! HRESETN)  begin        
    end                         
    else begin                  
       if( HREADY & WR_DATA_phase & HADDR[31:16] == 16'h2000  )  begin
           slave_memory[HADDR_r] = HWDATA ;
       end
    end
 end 


 always @ (posedge HCLK or negedge HRESETN) begin

    if(!HRESETN)  begin
       WR_DATA_phase <= 1'd0 ;
    end 
    else begin
       if(HSEL & HREADY & (HTRANS == 2'd2) ) begin
          HADDR_r  <= HADDR ;
       end 

       if(HSEL & HREADY & HWRITE & (HTRANS == 2'd2 ) ) 
           WR_DATA_phase <= 1'd1 ;
       else if( HSEL & HREADY )
           WR_DATA_phase <= 1'd0 ;
            
    end
 end 

 always @ (negedge HCLK or negedge HRESETN ) begin      
    if(! HRESETN)  begin        
       response_phase_d1 <= 'h0;
    end                         
    else begin                  
       response_phase_d1 <= response_phase;
    end
 end 

  //===============================================
  // Write into the comm_blk registers
  //===============================================
  always @ (negedge HCLK , negedge HRESETN) begin
     if(!HRESETN) begin // check reset values
        control_reg      = 8'b0001_1100 ;
        status_reg       = 8'b0000_0001 ;
        int_enable_reg   = 8'b1010_1111 ;
        data8_reg        = 8'd0 ;   
        data32_reg       = 32'd0 ;   
        cmd_options      = 32'd0 ;

        if(PORDSERVICE == 1) begin
           response_phase  = 1'b0 ;
           repeat(11) @ ( posedge HCLK) ; 
           response_phase  = 1'b1 ;
           present_cmd     = 32'd241 ;
           frame32_reg     = 32'd241 ; 
           frame8_reg      = 8'd241 ; 
        end
        else begin
           response_phase   = 1'b0 ;
           present_cmd      = 32'h0 ;
           frame8_reg       = 8'd0 ;
           frame32_reg      = 32'd0 ;
        end

        INTERRUPT_ENABLE0 = 32'h0 ;
        INTERRUPT_ENABLE1 = 32'h0 ;
        Interrupt_Mode    = 32'h0 ;
     end
     else begin
        if(HREADY & HWRITE & HSEL & WR_DATA_phase ) begin
            if(HADDR_r[31:12] == 20'h40016) begin // write to comm_blk registers
                if(HADDR_r == 32'h40016000) begin
                    control_reg     = {{2'b0}, {HWDATA[5:2]},{control_reg[1]}, {HWDATA[0]} } ;
                    control_reg[1]  = control_reg[0] ;
                    status_reg[1]   = HWDATA[0] ? 1'b0 : status_reg[1] ;
                end

                else if(HADDR_r == 32'h40016004) begin
                    status_reg      = { {status_reg[7]}, {HWDATA[6:2]}, {status_reg[1]}, {status_reg[0]} };
                end

                else if(HADDR_r == 32'h40016008) begin
                    int_enable_reg      = HWDATA[7:0] ;
                end

                else if(HADDR_r == 32'h40016010) begin
                    data8_reg       = HWDATA[7:0] ;
                    response_phase  = 1'b1 ;
                    cmd_options     = HWDATA ;

                end

                else if(HADDR_r == 32'h40016014) begin
                    data32_reg      = HWDATA ;
                    response_phase  = 1'b1   ;
                    
                end

                else if(HADDR_r == 32'h40016018) begin
                    frame8_reg      = HWDATA[7:0] ;
                    present_cmd     = HWDATA[7:0] ;
                    if(HWDATA[7:0] == 8'd45 | HWDATA[7:0] == 8'd40 ) // self test service
                      response_phase  = 1'b1 ;
                end

                else if(HADDR_r == 32'h4001601C) begin
                    frame32_reg     = HWDATA ;
                    present_cmd     = HWDATA[7:0] ;
                    if(HWDATA[7:0] == 8'd45 | HWDATA[7:0] == 8'd40 ) // self test service
                      response_phase  = 1'b1 ;
                        
                end
            end
            else if (HADDR_r[31:12] == 20'h40006) begin // write to FIIC registers

                if(HADDR_r == 32'h40006000) begin
                    INTERRUPT_ENABLE0 = HWDATA ;
                    response_phase    = 1'b0 ;
                end
                else if(HADDR_r == 32'h40006004) begin
                    INTERRUPT_ENABLE1 = HWDATA ;
                end
                else if(HADDR_r == 32'h40016010) begin
                    Interrupt_Mode = HWDATA ;
                end

            end

        end
        else begin
           // comm_blk logic
           control_reg[1]  = 1'd0 ;
        end

     end
    
  end


  // =========================================================
  // Read operation
  // =========================================================
  always @ (posedge HCLK , negedge HRESETN) begin
     if(!HRESETN) begin
        HRDATA <= 32'd0 ;
     end
     else begin

        if(HREADY & !HWRITE & HSEL & HTRANS==2 ) begin
            //============================================
            // Read transaction from eSRAM
            //============================================
            if( HADDR[31:16] == 16'h2000 ) begin
                // HRDATA   <= slave_memory[HADDR];
                HRDATA   <= mem_data ;
                mem_data <= mem_data + 1 ;
            end else if(HADDR == 32'h40016000)
                HRDATA   <= {24'h0, control_reg };

            else if(HADDR == 32'h40016004)
                HRDATA   <= {24'h0, status_reg }  ;

            else if(HADDR == 32'h40016008)
                HRDATA   <= {24'h0, int_enable_reg } ;

            // read from data8 reg
            else if(HADDR == 32'h40016010) begin
                if( phase_value    == 3'd2 ) begin 
                    if(present_cmd == 8)
                       HRDATA  <= 32'h0000_00FC ;          // response
                    else begin
                       HRDATA  <= 32'h0000_0000 ;          // response
                    end
                end
                else if ( phase_value    == 3'd3 ) begin
                    if(present_cmd == 3)
                        HRDATA  <= CRYPTOAES128DATAPTR  ; // AES 128bit dscr ptr
                    else if(present_cmd == 6)
                        HRDATA  <= CRYPTOAES256DATAPTR  ; // AES 256bit dscr ptr
                    else if(present_cmd == 10)
                        HRDATA  <= CRYPTOSHA256DATAPTR  ; // SHA256 dcsr ptr
                    else if(present_cmd == 12)
                        HRDATA  <= CRYPTOHMACDATAPTR    ; // HMAC dcsr ptr
                    else if(present_cmd == 1)
                        HRDATA  <=  DSNPTR              ; // Device no dcsr ptr
                    else if(present_cmd == 4)
                        HRDATA  <=  USERCODEPTR         ; // USERCODE ptr dcsr ptr
                    else if(present_cmd == 0)
                        HRDATA  <=  DEVICECERTPTR       ; // DEVICECERTPTR ptr dcsr ptr
                    else if(present_cmd == 5)
                        HRDATA  <=  DESIGNVERPTR        ; // DESIGNVERPTR ptr dcsr ptr
                    else if(present_cmd == 9)
                        HRDATA  <=  KEYTREEDATAPTR      ; // DPA KEY TREE ptr dcsr ptr
                    else if(present_cmd == 14)
                        HRDATA  <=  CHRESPPTR           ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 16)
                        HRDATA  <=  ECCPMULTPPTR        ; // Elliptic Point Mult dcsr ptr
                    else if(present_cmd == 17)
                        HRDATA  <=  ECCPADDPPTR         ; // Elliptic Point Add dcsr ptr
                    else if(present_cmd == 20)
                        HRDATA  <=  32'h0000_00FF       ; // Elliptic Point Add dcsr ptr
                end
                else
                    HRDATA   <= {24'h0, data8_reg } ;
            end

            // read from data32 reg
            else if(HADDR == 32'h40016014) begin
                if( phase_value    == 3'd2 ) 
                    HRDATA  <= 32'd1 ;          // response
                else if ( phase_value    == 3'd3 ) begin
                    if(present_cmd == 3)
                        HRDATA  <= CRYPTOAES128DATAPTR  ; // AES 128bit dscr ptr
                    else if(present_cmd == 6)
                        HRDATA  <= CRYPTOAES256DATAPTR  ; // AES 256bit dscr ptr
                    else if(present_cmd == 10)
                        HRDATA  <= CRYPTOSHA256DATAPTR  ; // SHA256 dcsr ptr
                    else if(present_cmd == 12)
                        HRDATA  <= CRYPTOHMACDATAPTR    ; // HMAC dcsr ptr
                    else if(present_cmd == 1)
                        HRDATA  <=  DSNPTR              ; // Device no dcsr ptr
                    else if(present_cmd == 4)
                        HRDATA  <=  USERCODEPTR         ; // USERCODE ptr dcsr ptr
                    else if(present_cmd == 0)
                        HRDATA  <=  DEVICECERTPTR       ; // DEVICECERTPTR ptr dcsr ptr
                    else if(present_cmd == 5)
                        HRDATA  <=  DESIGNVERPTR        ; // DESIGNVERPTR ptr dcsr ptr
                    else if(present_cmd == 9)
                        HRDATA  <=  KEYTREEDATAPTR      ; // DPA KEY TREE ptr dcsr ptr
                    else if(present_cmd == 14)
                        HRDATA  <=  CHRESPPTR           ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 41)
                        HRDATA  <=  NRBGINSTPTR         ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 42)
                        HRDATA  <=  NRBGINSTPTR         ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 43)
                        HRDATA  <=  NRBGRESEEDPTR       ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 44)
                        HRDATA  <=  32'd0               ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 45)
                        HRDATA  <=  32'd0               ; // DPA PUF ptr dcsr ptr
                    else if(present_cmd == 16)
                        HRDATA  <=  ECCPMULTDESC        ; // Elliptic Point Mult dcsr ptr
                    else if(present_cmd == 17)
                        HRDATA  <=  ECCPADDDESC         ; // Elliptic Point Add dcsr ptr
                    else if(present_cmd == 26)
                        HRDATA  <=  PUFUSERKCPTR        ; // PUFUSERKC dcsr ptr
                    else if(present_cmd == 27)
                        HRDATA  <=  PUFUSERKEYPTR       ; // PUFUSERKEY dcsr ptr
                    else if(present_cmd == 28)
                        HRDATA  <=  PUFPUBLICKEYPTR     ; // PUFPUBLICKEYPTR dcsr ptr
                    else if(present_cmd == 29)
                        HRDATA  <=  PUFSEEDPTR          ; // PUFSEEDPTR ptr
                    else if(present_cmd == 30)
                        HRDATA  <=  SECONDECCCERTPTR    ; // SECONDECCCERTPTR ptr
                end
                else
                    HRDATA <= data32_reg  ;
            end

            // read from frame8 reg
            else if(HADDR == 32'h40016018) begin
                if(present_cmd == 20 ) begin // IAP RESPONSE
                   if(cmd_options == 0) begin  
                         HRDATA <= {24'h0, frame8_reg } ;           
                   end else if (cmd_options == 2) begin             
                      if(phase_value == 1) 
                         HRDATA <= 32'hE0  ;
                      if(phase_value == 2) 
                         HRDATA <= 32'hE1  ;
                      if(phase_value == 3) 
                         HRDATA <= {24'h0, frame8_reg } ; 
                   end else if (cmd_options == 1) begin             
                         HRDATA <= 32'hE0  ;
                   end          
                end else begin

                   if( (present_cmd == 2) && (phase_value    == 3) )
                      HRDATA <= 32'hE0  ;
                   else if( (present_cmd == 2) && (phase_value == 4) )
                      HRDATA <= 32'hE1  ;
                   else begin
	              if(CMD_ERROR ==1 )	                     // july 14
                         HRDATA <= ({24'h0, frame8_reg } + 1'b1)  ;
                      else
                         HRDATA <= {24'h0, frame8_reg }  ;
		   end

		end
            end

            // read from frame32 reg
            else if(HADDR[7:0] == 8'h1C)
                HRDATA <= frame32_reg ;

        end else begin
          // HRDATA <= 8'h00 ;
        end
     end
    
  end

  // =========================================================
  // Change status_reg in response phase
  // =========================================================
  //always @ (posedge response_phase , negedge HRESETN) begin
  always @ (*) begin
      if(response_phase && !response_phase_d1) begin      
     //if(!HRESETN) begin
     //end
     //else begin
        // commands which has 3 transactions in response phase
        //if(present_cmd inside {1,4,0,5,3,6,10,12,9,14,41,42,43,44,  16,17,26,27,28,29,30} ) begin      
        if(present_cmd== 1 | present_cmd== 4 | present_cmd== 0 | present_cmd== 5 | present_cmd== 3 |
           present_cmd== 6 | present_cmd== 10 | present_cmd== 12 | present_cmd== 9 | present_cmd== 14 | 
           present_cmd== 41 | present_cmd== 42 | present_cmd== 43 | present_cmd== 44 | present_cmd==   16 |
           present_cmd== 17 | present_cmd== 26 | present_cmd== 27 | present_cmd== 28 | present_cmd== 29 | present_cmd== 30 ) begin      
       
           // Rx_okay and CMD   
           repeat(AHB_DELAY) @ ( posedge HCLK) ; 
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;
 
           // wait for read from status reg
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd1 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read frame8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016018) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;

           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           // Rx_okay    
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b1 ;

           // wait for read from status reg 
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd2 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read data8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016010) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;

           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           // Rx_okay    
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b1 ;

           // wait for read from status reg 
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd3 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read data32 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016014) );
           status_reg[7]  =  1'b0 ;
           status_reg[1]  =  1'b0 ;
        end

        // commands which has 2 transactions in response phase
        else if(present_cmd == 40 | present_cmd== 23 | present_cmd== 241 | present_cmd== 45 | present_cmd==   25 |
                present_cmd== 31 | present_cmd== 8 ) begin      
           repeat(AHB_DELAY) @ ( posedge HCLK) ; 
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;
 
           // wait for read from status reg 
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd1 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read frame8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016018) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;

           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b1 ;

           // wait for read from status reg 
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd2 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read data8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016010) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
        end
        
        // commands which has 4 transactions in response phase
        else if(present_cmd == 2 ) begin      // For Flash*Freeze
           repeat(AHB_DELAY) @ ( posedge HCLK) ;                // for CMD
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;
 
           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd1 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read frame8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016018) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;

           repeat(AHB_DELAY2) @ (posedge HCLK) ;        // For status
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b1 ;

           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd2 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read frame8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016018) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;

           repeat(AHB_DELAY2) @ (posedge HCLK) ;        // For 0xE0
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;

           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd3 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read frame8 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016018) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;

           repeat(AHB_DELAY2) @ (posedge HCLK) ;        // For 0xE1
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;

           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           phase_value    = 3'd4 ;
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           //wait for read data32 reg
            wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016014) );
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
        end

        //======================================================
        // IAP RESPONSE PHASE
        //======================================================
        // commands which has 2 transactions in response phase
        else if( (present_cmd== 20) && (cmd_options == 0) ) begin // authenticate     
           repeat(AHB_DELAY) @ ( posedge HCLK) ; // for CMD
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;
 
           // wait for read from status reg 
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd1 ;

           repeat(AHB_DELAY) @ (posedge HCLK) ; // for STATUS
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b1 ;

           // wait for read from status reg 
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd2 ;
        end
        
        // commands which has 4 transactions in response phase
        else if( (present_cmd== 20) && (cmd_options == 2) ) begin // verify     
           repeat(AHB_DELAY) @ ( posedge HCLK) ;                // for E0
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;
 
           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd1 ;

           repeat(AHB_DELAY2) @ (posedge HCLK) ;        // For E1
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;

           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd2 ;

           repeat(AHB_DELAY2) @ (posedge HCLK) ;        // For CMD
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;

           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd3 ;

           repeat(AHB_DELAY2) @ (posedge HCLK) ;        // For STATUS
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b1 ;

           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd4 ;
        end

        // commands which has 1 transactions in response phase
        else if( (present_cmd== 20) && (cmd_options == 1) ) begin      // program
           repeat(AHB_DELAY) @ ( posedge HCLK) ;                // for E0
           status_reg[7]  = 1'b1 ;
           status_reg[1]  = 1'b1 ;
 
           // wait for read transaction
           wait((HREADY & !HWRITE & HSEL & HTRANS == 2'h2 & HADDR == 32'h40016004));
           repeat(AHB_DELAY) @ (posedge HCLK) ; 
           status_reg[7]  = 1'b0 ;
           status_reg[1]  = 1'b0 ;
           phase_value    = 3'd1 ;

        end

    end
 end

endmodule 

