// ****************************************************************************/     
// Actel Corporation Proprietary and Confidential     
// Copyright 2010 Actel Corporation.  All rights reserved.     
//     
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN     
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED     
// IN ADVANCE IN WRITING.     
//     
// Description: FSMCtrl.v - FSM control logic block 
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
 
`timescale 1ns/10ps  
 
module CoreSysServices_FSMCtrl (  
                   // AHB Master Interface  
                   hclk,  
                   hresetn,  
                   
                   mfhready_i,  
                   mfhresp_i,  
                   mfhrdata_i,  
                   // From Cmd Dec
                   cfgrant_i,  
                   cfsrc_addr_i,  
                   cfdst_addr_i,            
                   cfburst_len_wr_i,  
                   cfburst_len_rd_i,  
                   cfrd_resp_i,  
                   cfwr_req_i,  
                   cfrd_req_i,
                   cfrd_asyncevent_i,
     
                   cfwr_req_d,
                   cfrd_req_d,
    
                   cfdatain_i,     
                   cfcommaccess_active,
                   cfcommaccess_resp_active,
   
                   // To AHB Master
                   fmhtrans_o,  
                   fmhwrite_o,  
                   fmhsize_o,  
                   fmhburst_o,     
                   fmhsel_o,
                   fmhaddr_o,  
                   fmhwdata_o,
                   // To Cmd Dec
                   fcbusreq_o,  
                   fctrans_done_o,  
                   fcdataout_o,  
     
                   idle_trigger,
                   rvalid_out_en,
                   clr_req,
     
                   push,  
                   pop
                   
                   );
   
   //------------------------------------------------------------------------------     
   // Parameter declarations     
   //------------------------------------------------------------------------------     

   //------------------------------------------------------------------------------     
   // AHB Master Interface State Machine Encoding  
   //------------------------------------------------------------------------------     
   localparam         AHM_IDLE       =  4'b0000;  
   localparam         AHM_BREQ       =  4'b0001;  
   localparam         AHM_NSEQWR     =  4'b0010;  
   localparam         AHM_SEQWR      =  4'b0011;  
   localparam         AHM_WRWAIT     =  4'b0101;  
   localparam         AHM_RETRY      =  4'b0110;  
   localparam         AHM_LASTWR     =  4'b0111;  
   localparam         AHM_GOIDLE     =  4'b1000;  
   localparam         AHM_NSEQRD     =  4'b1001;  
   localparam         AHM_SEQRD      =  4'b1010;  
   localparam         AHM_RDWAIT     =  4'b1011;  
   localparam         AHM_LASTRD     =  4'b1100;  
      
   //------------------------------------------------------------------------------     
   // Parameter Definition for AHB Transfer Type(HTRANS)  
   //------------------------------------------------------------------------------     
   localparam         IDLE                = 2'b00;  
   localparam         BUSY                = 2'b01;  
   localparam         NONSEQ              = 2'b10;  
   localparam         SEQ                 = 2'b11;  
   
   //------------------------------------------------------------------------------     
   // Parameter Definition for AHB Transfer Type(HBURST)  
   //------------------------------------------------------------------------------     
   localparam         SINGLE              = 3'b000;  
   localparam         INCR                = 3'b001;
   localparam         INCR4               = 3'b011;
   localparam         INCR8               = 3'b101;
   localparam         INCR16              = 3'b111;  
   
   //------------------------------------------------------------------------------     
   // Parameter Definition for AHB Transfer SIZE(HSIZE)  
   //------------------------------------------------------------------------------     
   localparam         BYTE                = 3'b000;  
   localparam         HALFWORD            = 3'b001;  
   localparam         WORD                = 3'b010;  
   
   //------------------------------------------------------------------------------     
   // Parameter Definition for AHB Response Type(mfhresp_i)  
   //------------------------------------------------------------------------------     
   localparam         OKAY                = 1'b0;  
   localparam         ERROR               = 1'b1;  
   
   //------------------------------------------------------------------------------     
   // Parameter Definition for AHB Write/Read Command (HWRITE)  
   //------------------------------------------------------------------------------     
   localparam         READ                = 1'b0;  
   localparam         WRITE               = 1'b1;  
   
   //------------------------------------------------------------------------------     
   // Port declarations     
   //------------------------------------------------------------------------------     
   
   // -----------     
   // Inputs     
   // ----------- 
   // AHB Interface     
   input             hclk;                // This clock times all bus transfers  
   input             hresetn;             // AHB reset signal  
   input             mfhready_i;          // when active indicates that  
                                          // a transfer has finished on the bus  
   input             mfhresp_i;           // transfer response from AHB Slave  
                                          // (OKAY,ERROR)  
   input             cfgrant_i;           // bus grant from AHB Arbiter  
   
   input [31:0]      mfhrdata_i;          // Read data from AHB for Tx  
   
   // From FSM Control logic
   input [31:0]      cfsrc_addr_i;  
   input [31:0]      cfdst_addr_i;            
   input [31:0]      cfburst_len_wr_i;  
   input [31:0]      cfburst_len_rd_i;     
   input             cfrd_resp_i;  
   input             cfwr_req_i;  
   input             cfrd_req_i;    
   input             cfrd_asyncevent_i;
   
   input             cfwr_req_d;  
   input             cfrd_req_d;     
   input [31:0]      cfdatain_i;		// Data In from Write FIFO 
   input             cfcommaccess_active;
   input             cfcommaccess_resp_active;
   
   // -----------    
   // Outputs    
   // -----------     
   output            fcbusreq_o;           // bus request to AHB Arbiter  
   output [1:0]      fmhtrans_o;           // type of current transfer  
   output            fmhwrite_o;           // type of current transfer  
                                           // (NONSEQ,SEQ,IDLE,BUSY)  
   output [2:0]      fmhsize_o;            // size of current transfer  
   output [2:0]      fmhburst_o;           // Burst type  
   output [31:0]     fmhaddr_o;            // Address out onto AHB for Rd/Wr  
   output            fmhsel_o;   
   output [31:0]     fmhwdata_o;           // Write data out to AHB for Rx   

   // FSM Control logic I/F
   output            fctrans_done_o;  
   output [31:0]     fcdataout_o;	 	// Data Out to Read FIFO  
   output            push;  
   output            pop;  
   output            idle_trigger;
   output            rvalid_out_en;
   output            clr_req;
   
   // -----------------    
   // Internal signals    
   // -----------------    
   reg               fmhwrite_o;
   reg               fmhwrite_d1;
   reg [1:0]         fmhtrans_int;  
   reg [1:0]         fmhtrans_int2;  
   reg [2:0]         fmhburst_o;  
   reg [2:0]         fmhburst_d1;
   reg [31:0]        fmhaddr_o;  
   reg               fmhsel_o;   
   wire [31:0]       fmhwdata_o;  
   reg               pop_d1;
   
   reg               fctrans_done_tmp;  
   reg [31:0]        word_count;  
   reg               push;  
   
   reg [3:0]         curr_state;     // AHB Master I/F S/M current State bits  
   reg [3:0]         next_state;     // AHB Master I/F S/M next State bits  
   reg [3:0]         state_prev_clk; // AHB Master I/F S/M State bits delayed by 1-clock  
   
   reg               latch_addr;
   reg               burstwrflag_last_n;  
   reg [29:0]        haddr_reg;
   reg [29:0]        haddr_prev;                                  
   reg               ahm_busreq_reg;
   reg               rddf_wren;

   reg               busreq_prev;
   reg               busreq_comb;  
   
   reg               latch_addr_d1;
   reg               cfwr_req_d1;
   reg               cfrd_resp_d1;
   reg               latch_addr_d2;
   reg               latch_addr_d3;

   reg               cfwr_req_d2;
   reg               cfrd_resp_d2;   
   reg               cfrd_req_d1;   
   reg               cfrd_req_d2;
   reg               cfrd_asyncevent_d1;   
   reg               cfrd_asyncevent_d2;   
   
   reg               idle_trigger;
   reg               rvalid_out_en_d1;
   reg               rvalid_out_en_d2;
   reg               rvalid_out_en;
   
   reg               clr_req;

   wire              fcbusreq_o;  
   wire [2:0]        fmhsize_o;  
   wire [1:0]        fmhtrans_o;  
   wire [31:0]       fmhaddr_lat;     
   wire              fctrans_done_o;  
   wire              pop;  
   wire [31:0]       fcdataout_o;
   wire              lastbrstrd;
   wire              lastbrstwr;
   wire [29:0]       nextaddr;
   wire              cfrd_req_c;
   wire              cfwr_req_c;

   //////////////////////////////////////////////////////////////////////////////    
   //                           Start-of-Code                                  //    
   //////////////////////////////////////////////////////////////////////////////    
   
   
   //------------------------------------------------------------------------------     
   // HRDATA received from AHBL Master I/F is forwarded to FSM Control logic block
   //------------------------------------------------------------------------------     
   assign            fcdataout_o[31:0] = mfhrdata_i;  
      
   //------------------------------------------------------------------------------     
   // Transfer size
   //------------------------------------------------------------------------------     
   assign            fmhsize_o = WORD;		   // Always WORD Transfer  

   //------------------------------------------------------------------------------     
   // Transfer done signal sent to Command decoder block
   //------------------------------------------------------------------------------     
   assign            fctrans_done_o = fctrans_done_tmp & idle_trigger;

   always @(posedge hclk or negedge hresetn)
     begin  
        if(!hresetn) begin  
           fctrans_done_tmp  <= 1'b0;  
        end
        else begin
           if(fcbusreq_o) begin
              fctrans_done_tmp  <= 1'b0;  
           end
           else if((word_count == 32'h00000001) && (push || pop)) begin
              fctrans_done_tmp  <= 1'b1;  
           end
        end
     end

   //------------------------------------------------------------------------------     
   // Registered signals
   //------------------------------------------------------------------------------     
   always @(posedge hclk or negedge hresetn)  
     begin  
        if(!hresetn) begin  
           fmhwrite_d1  <= 1'b0;  
           fmhburst_d1  <= 3'b000;
        end
        else begin
           fmhwrite_d1  <= fmhwrite_o;  
           fmhburst_d1  <= fmhburst_o;
        end
     end

   always @(posedge hclk or negedge hresetn)  
     begin     
        if(!hresetn) begin  
           clr_req  <= 1'b0;  
        end 
        else begin
           // v3.0 - Async Event
           if(curr_state == AHM_IDLE && (cfrd_resp_i == 1'b1 || 
                                         cfrd_req_i == 1'b1  || cfrd_asyncevent_i == 1'b1 ||
                                         cfwr_req_i == 1'b1)) begin
              clr_req  <= 1'b1;
           end
           else begin
              clr_req  <= 1'b0;
           end                      
        end 
     end
   
   //------------------------------------------------------------------------------     
   // AHB Master State machine
   //------------------------------------------------------------------------------     
   always @(posedge hclk or negedge hresetn)  
     begin          
        if(!hresetn) begin  
           curr_state  <= AHM_IDLE;  
        end
        else begin
           curr_state  <= next_state;  
        end
     end
   
   //------------------------------------------------------------------------------     
   // AHB Master State machine: Next state and output decoder
   //------------------------------------------------------------------------------     
   always @(*) begin
      ahm_busreq_reg    = 1'b0;
      fmhwrite_o        = fmhwrite_d1;  
      latch_addr        = 1'b0;  
      fmhburst_o        = fmhburst_d1;  
      rddf_wren         = 1'b0;  
      next_state        = curr_state;  
      idle_trigger      = 1'b0;
      
      case(curr_state)
       
        AHM_IDLE:  begin  
           idle_trigger = 1'b1;
            
           if((cfrd_resp_i == 1'b1 || cfrd_req_i == 1'b1 || cfrd_asyncevent_i == 1'b1)) begin			
              // Assert bus access request to for read transfers
           
              ahm_busreq_reg    = 1'b1; 
              // assign the read/write command to indicate read cycle  
              fmhwrite_o        = READ;  
              // latch current address from address fifo into  
              // incrementer, output of which gets onto AHB  
              // as transfer address  
              latch_addr   = 1'b1;  
              next_state   = AHM_BREQ;  
           end  
           else if(cfwr_req_i) begin	// AHB Write Cycle  
              // Assert bus access request to AHB Arbiter  
              ahm_busreq_reg    = 1'b1; 
              // assign the read/write command to indicate write cycle  
              fmhwrite_o        = WRITE;  
              // latch current address from address fifo into  
              // incrementer, output of which gets onto AHB  
              // as transfer address  
              latch_addr  = 1'b1;  
              next_state  = AHM_BREQ;  
           end  
        end  
       
        // wait until bus is granted  
        AHM_BREQ:  begin  
           latch_addr          = 1'b0;  

           if(cfgrant_i & mfhready_i) begin  
              // write transfer  
              if(fmhwrite_o) begin  
                 next_state  = AHM_NSEQWR;  
                 if((word_count == 32'h00000001)) begin  
                    fmhburst_o     = SINGLE;
                 end  
                 // if it is intended burst then keep bus request  
                 // asserted and assert HBURST to INCR  
                 // (burst of undefined length)  
                 else begin  
                    fmhburst_o     = SINGLE;
                 end  
              end  
              // read transfer  
              else begin  
                 if ((word_count == 32'h00000001)) begin  
                    fmhburst_o     = SINGLE;  
                 end  
                 else begin  
                    fmhburst_o     = SINGLE;  
                 end  
                 // read request is single  
                 next_state    = AHM_NSEQRD;  
              end  
           end  
        end  
        // first address phase of read transfer  
        AHM_NSEQRD:  begin  
           // Target is ready accept data  
           if(mfhready_i) begin  
              if(fmhburst_o == SINGLE) begin  
                 next_state    = AHM_RDWAIT;  
              end  
              // more data to be read but grant is lost  
              else if(~cfgrant_i) begin  
                 next_state    = AHM_IDLE;
              end  
              // continue to read  
              else begin  
                 if(lastbrstrd) begin  
                 end  
                 next_state    = AHM_SEQRD;  
              end  
              // enable data fifo write logic  
              rddf_wren       = 1'b1;  
           end  
        end  
        // consecutive transfers of burst read  
        AHM_SEQRD:  begin  
           // target is ready to provide data  
           if(mfhready_i & mfhresp_i == OKAY) begin  
              if(fmhtrans_o == IDLE) begin  
                 next_state    = AHM_GOIDLE;  
                 rddf_wren      = 1'b0;  
              end  
              // only one more data left from current read burst  
              else if(lastbrstrd) begin   
                 next_state    = AHM_RDWAIT;  
              end  
              else if(~cfgrant_i) begin  
                 next_state    = AHM_IDLE; 
                 if(~busreq_comb) begin  
                 end  
              end  
           end  
           // system needs to be reset  
           else if(~mfhready_i && mfhresp_i == ERROR) begin  
              rddf_wren     = 1'b0;  
              next_state    = AHM_IDLE;  
           end  
           else begin  
              // enable as long as in SEQRD state  
              rddf_wren      = 1'b1;  
              if(~busreq_comb) begin  
              end  
           end  
        end  
        // last read data phase from current read transfer  
        // (due to lost ownership of address bus)  
        // once the current data phase is over(successful or not(retry/split))  
        // master rearbitrates and starts with non-sequential again  
        AHM_LASTRD:  begin  
           // target is ready to accept data  
           if(mfhready_i & mfhresp_i == OKAY) begin  
              next_state       = AHM_BREQ;  
              rddf_wren        = 1'b0;  
           end  
           // error indicated on AHB  
           // in current design it is unrecoverable  
           // system needs to be reset  
           else if(~mfhready_i && mfhresp_i == ERROR) begin  
              rddf_wren     = 1'b0;  
              next_state    = AHM_IDLE;  
           end  
           else begin  
              rddf_wren      = 1'b1;  
           end  
        end  
        // first address phase of write transfer  
        AHM_NSEQWR:  begin  
           if(mfhready_i) begin  
              // If it is single write cycle go to WAIT as  
              // current data is last data phase  
              if (fmhburst_o == SINGLE) begin  
                 next_state    = AHM_WRWAIT;  
              end  
              else if(~cfgrant_i) begin  
                 next_state    = AHM_IDLE; 
              end  
              else begin  
                 next_state    = AHM_SEQWR;  
              end  
           end  
        end  
        // data phase of either single read cycle  
        // or last data phase of burst read cycle  
        AHM_RDWAIT:  begin  
           // target is ready  
           if(mfhready_i == 1'b1 && mfhresp_i == OKAY) begin  
              next_state    = AHM_GOIDLE;  
              // disable data fifo write logic  
              rddf_wren           = 1'b0;  
              // read the address fifo as it is last data phase  
              // so that application can strobe new cycle if any  
           end  
           // error indicated on AHB  
           // in current design it is unrecoverable  
           // system needs to be reset  
           else if(~mfhready_i & mfhresp_i == ERROR) begin  
              next_state    = AHM_IDLE;  
           end  
        end  
        // last data phase of write transfer(single/burst)  
        // if successful S/M goes to idle  
        // if unsuccessful(RETRY/SPLIT) transfer is retried  
        AHM_WRWAIT:  begin  
           // target is ready  
           if(mfhready_i == 1'b1 & mfhresp_i == OKAY) begin  
              next_state    = AHM_GOIDLE;  
           end  
           // system needs to be reset  
           else if(~mfhready_i & mfhresp_i == ERROR) begin  
              next_state    = AHM_IDLE;  
           end  
        end  
        // sub-sequent address/data phases of burst write cycle  
        AHM_SEQWR:                 // target is ready to accept data  
          if(mfhready_i & mfhresp_i == OKAY) begin  
             if(fmhtrans_o == BUSY) begin  
                fmhburst_o      = INCR;  
                if(cfgrant_i) begin  
                   next_state    = AHM_NSEQWR;  
                end  
                else begin  
                   next_state    = AHM_IDLE;  
                end  
             end  
             else if(fmhtrans_o == IDLE) begin  
                next_state    = AHM_GOIDLE;  
             end  
             // Finish cycle when last word is written  
             else if(lastbrstwr) begin  
                next_state    = AHM_LASTWR;  
             end    
             // grant lost while waiting for transfer to finish  
             else if(~cfgrant_i) begin  
                next_state    = AHM_IDLE; 
             end  
          end  
        // error indicated on AHB  
        // in current design it is unrecoverable  
        // system needs to be reset  
          else if(~mfhready_i & mfhresp_i == ERROR) begin  
             next_state    = AHM_IDLE;  
          end  
        // last data phase of write transfer because of lost ownership  
        // of address bus(Grant lost)  
        // once current data phase completes(successful or not(retry/split))  
        // master re-arbitrates and resumes pending cycle starting with  
        // non-sequential  
        AHM_LASTWR:  begin  
           // target is ready to accept data  
           if(mfhready_i & mfhresp_i == OKAY) begin  
              // if the current data is last data from current burst  
              // goto idle, emptying the address fifo  
              if(burstwrflag_last_n) begin  
                 next_state    = AHM_GOIDLE;  
              end  
              else begin  
                 next_state    = AHM_BREQ;  
              end  
           end  
           // error indicated on AHB  
           // in current design it is unrecoverable  
           // system needs to be reset  
           else if(~mfhready_i & mfhresp_i == ERROR) begin  
              next_state    = AHM_IDLE;  
           end  
        end  
        AHM_GOIDLE:  begin

           if(word_count != 32'h0 && mfhready_i == 1'b1) begin
              next_state    = AHM_BREQ;
           end
           else if(mfhready_i == 1'b1) begin
              next_state    = AHM_IDLE;
           end
        end  
        
      endcase  
   end  

  //------------------------------------------------------------------------------   
  // Generate RVALID to command decoder  
  //------------------------------------------------------------------------------   
  always @(*)  
  begin  
      if((curr_state == AHM_GOIDLE && next_state == AHM_BREQ) || 
	 (curr_state == AHM_GOIDLE && next_state == AHM_IDLE)) begin  
        rvalid_out_en <= 1'b1;  
      end  
      else begin  
        rvalid_out_en  <= 1'b0;  
      end  
  end

  //------------------------------------------------------------------------------   
  // AHB write burst flag latching  
  //------------------------------------------------------------------------------   
  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
      burstwrflag_last_n  <= 1'b1;  
    end  
    else begin  
      if(pop | (curr_state == AHM_IDLE)) begin  
        burstwrflag_last_n  <= (word_count == 32'h00000001);  
      end  
    end  
  end  
   
  //------------------------------------------------------------------------------   
  // latching state   
  //------------------------------------------------------------------------------   
  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
      state_prev_clk      <= AHM_IDLE;  
    end  
    else begin  
      if(mfhready_i) begin  
        state_prev_clk      <= curr_state;  
      end  
    end  
  end  

  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
       latch_addr_d1		  <= 1'b0;
    end  
    else begin
       latch_addr_d1          <= latch_addr;
    end
  end
  
  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
       cfwr_req_d1            <= 1'b0;
    end  
    else begin
       if(curr_state == AHM_GOIDLE) begin
         cfwr_req_d1            <= 1'b0;
       end
       else if(cfwr_req_i) begin
         cfwr_req_d1            <= 1'b1;
       end
    end
  end

  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
       cfrd_req_d1            <= 1'b0;
    end  
    else begin
       if(curr_state == AHM_GOIDLE) begin
         cfrd_req_d1            <= 1'b0;
       end
       else if(cfrd_req_i) begin
         cfrd_req_d1            <= 1'b1;
       end
    end
  end

  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
       cfrd_asyncevent_d1            <= 1'b0;
    end  
    else begin
       if(curr_state == AHM_GOIDLE) begin
         cfrd_asyncevent_d1            <= 1'b0;
       end
       else if(cfrd_asyncevent_i == 1'b1) begin
         cfrd_asyncevent_d1            <= 1'b1;
       end
    end
  end

  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
       cfrd_resp_d1            <= 1'b0;
    end  
    else begin
       if(curr_state == AHM_GOIDLE) begin
         cfrd_resp_d1            <= 1'b0;
       end
       else if(cfrd_resp_i) begin
         cfrd_resp_d1            <= 1'b1;
       end
    end
  end

  always @(posedge hclk or negedge hresetn)  
  begin  
    if(!hresetn) begin  
       latch_addr_d2		  <= 1'b0;
       latch_addr_d3		  <= 1'b0;
       cfwr_req_d2            <= 1'b0;
       cfrd_req_d2            <= 1'b0;
       cfrd_resp_d2           <= 1'b0;
       cfrd_asyncevent_d2     <= 1'b0;
   end  
   else begin
	   latch_addr_d2          <= latch_addr_d1;
	   latch_addr_d3          <= latch_addr_d2;
	   cfwr_req_d2            <= cfwr_req_d1;
	   cfrd_req_d2            <= cfrd_req_d1;
	   cfrd_resp_d2           <= cfrd_resp_d1;
       cfrd_asyncevent_d2     <= cfrd_asyncevent_d1;
   end
end

   //------------------------------------------------------------------------------      
   // HADDR: address generation
   //------------------------------------------------------------------------------   
   always @(posedge hclk or negedge hresetn)  
     begin  
        if(!hresetn) begin  
           haddr_reg[29:0]      <= 30'h0000_0000;  
           haddr_prev[29:0]     <= 30'h0000_0000;  
        end  
        else if(cfrd_resp_d1 || cfrd_asyncevent_d1) begin   
           haddr_reg[29:0]      <= cfsrc_addr_i[31:2];   
           haddr_prev[29:0]     <= cfsrc_addr_i[31:2];  
        end  
        else if((cfwr_req_d1 || cfrd_req_d1)) begin 
           haddr_reg[29:0]      <= cfdst_addr_i[31:2];   
           haddr_prev[29:0]     <= cfdst_addr_i[31:2];   
        end  
        else begin  
           if((curr_state == AHM_NSEQWR ||  curr_state == AHM_SEQWR ||  curr_state == AHM_NSEQRD || curr_state == AHM_SEQRD) && 
              (!cfcommaccess_active || !cfcommaccess_resp_active)) begin  
              if(mfhready_i & mfhresp_i == OKAY & fmhtrans_o != BUSY ) begin   
                 haddr_reg[29:0]      <= nextaddr[29:0];  
                 haddr_prev[29:0]     <= fmhaddr_o[31:2];  
              end  
           end  
        end  
     end  

   //------------------------------------------------------------------------------      
   // Word count generation
   //------------------------------------------------------------------------------      
   always @(posedge hclk or negedge hresetn)  
     begin  
        if(!hresetn) begin  
           word_count			  <= 32'h00000;   
        end  
        else if(latch_addr && (cfrd_resp_i || cfrd_req_i || cfrd_asyncevent_i)) begin   
           word_count			  <= cfburst_len_rd_i;
        end
        else if(latch_addr && cfwr_req_i) begin 
           word_count			  <= cfburst_len_wr_i;
        end  
        else if ((push | pop) && word_count != 32'h0) begin  
           word_count			  <= word_count - 1;   
        end
     end  


   //------------------------------------------------------------------------------   
   // Final address that gets onto AHB for Read/Write transfers  
   //------------------------------------------------------------------------------   
   always @(posedge hclk or negedge hresetn)
     begin  
        if(!hresetn) begin  
           fmhaddr_o <= 32'h00000000;  
        end  
        else begin  
             if((curr_state == AHM_NSEQWR) || (curr_state == AHM_NSEQRD)) begin
                if ((cfwr_req_d2 || cfrd_req_d2 )) begin  
                   fmhaddr_o <= cfdst_addr_i;
                end
                //else if(cfrd_resp_d2) begin
                else if(cfrd_resp_d2 || cfrd_asyncevent_d2) begin  
                   fmhaddr_o <= cfsrc_addr_i;                   
                end 
                else begin
                   if( curr_state == AHM_NSEQWR |  
                       curr_state == AHM_SEQWR |  
                       curr_state == AHM_NSEQRD |
                       curr_state == AHM_SEQRD) begin  
                      if(mfhready_i & mfhresp_i == OKAY & fmhtrans_o != BUSY ) begin   
                         fmhaddr_o <= {nextaddr[29:0],2'b00};  
                      end  
                   end  
                end
             end
        end
     end

   
   //------------------------------------------------------------------------------   
   // Address of next transfer used by address incrementer  
   //------------------------------------------------------------------------------   
   assign nextaddr[29:0]  = haddr_reg[29:0] + 1;  
   
   assign pop = (curr_state == AHM_SEQWR | curr_state == AHM_NSEQWR)  && 
                mfhready_i && (mfhresp_i == OKAY);  

   //------------------------------------------------------------------------------   
   // Write strobe logic  
   //------------------------------------------------------------------------------   
   always @(rddf_wren or mfhready_i or mfhresp_i)  
     begin  
        if(mfhready_i == 1'b1 & mfhresp_i == OKAY) begin  
           if(rddf_wren) begin  
              push = 1'b1;  
           end  
           else begin  
              push = 1'b0;  
           end  
        end  
        else begin  
           push = 1'b0;  
        end  
     end

   //------------------------------------------------------------------------------   
   // HSEL generation logic  
   //------------------------------------------------------------------------------   
   always @(posedge hclk or negedge hresetn)  
     begin  
        if(!hresetn) begin  
           fmhsel_o <= 1'b0;
        end  
        else begin
           if(curr_state == AHM_IDLE) begin
              fmhsel_o <= 1'b0;
           end
           else begin
              fmhsel_o <= 1'b1;
           end
        end // else: !if(!hresetn)
     end // always @ (posedge hclk or negedge hresetn)
   
     always @ (posedge hclk or negedge hresetn)
     begin  
        if(!hresetn) begin  
           fmhtrans_int <= IDLE;  
        end  
        else begin
           if((curr_state == AHM_NSEQWR && next_state == AHM_WRWAIT) || 
              (curr_state == AHM_NSEQRD && next_state == AHM_RDWAIT)) begin
                fmhtrans_int <= NONSEQ;  
           end
           else if(mfhready_i == 1'b1)begin
                fmhtrans_int <= IDLE;  
           end
        end 
     end
     always @ (posedge hclk or negedge hresetn)
     begin  
        if(!hresetn) begin  
           fmhtrans_int2 <= IDLE;  
        end  
        else begin                
           if(curr_state == AHM_GOIDLE || curr_state == AHM_IDLE)begin
                fmhtrans_int2 <= IDLE;  
           end
           if(mfhready_i == 1'b0)begin
                fmhtrans_int2 <= fmhtrans_int;  
           end

        end 
     end
 
   //------------------------------------------------------------------------------   
   // HTRANS generation
   //------------------------------------------------------------------------------   
     assign fmhtrans_o = (fmhtrans_int);
     
    //------------------------------------------------------------------------------   
    // removing bus request signal at the beginning of last data phase  
    // of SEQWR  
    // input signal dependencies removed to avoid combinitorial path  
    // thru the core input signals  
    //------------------------------------------------------------------------------   
    always @(curr_state or fmhtrans_o)  
    begin  
      if(curr_state == AHM_SEQWR) begin  
        if( fmhtrans_o == IDLE ) begin  
          busreq_comb = 1'b0;  
        end  
        else begin  
          busreq_comb = 1'b1;  
        end  
      end  
      else if(curr_state == AHM_SEQRD) begin  
          if(fmhtrans_o == IDLE) begin  
            busreq_comb = 1'b0;  
          end  
          else begin  
            busreq_comb = 1'b1;  
          end  
        end  
        else begin  
          busreq_comb = 1'b1;  
        end  
      end  
       
   //------------------------------------------------------------------------------          
   // Final AHB access request signal to arbiter  
   //------------------------------------------------------------------------------   
   assign fcbusreq_o = ahm_busreq_reg;    

   assign cfrd_req_c = cfrd_req_d & !cfrd_req_d1;
   assign cfwr_req_c = cfwr_req_d & !cfwr_req_d1;   

   //------------------------------------------------------------------------------   
   // AHB write data generation  
   //------------------------------------------------------------------------------   
   assign fmhwdata_o = cfdatain_i;

   //------------------------------------------------------------------------------
   // pop_d1: Delayed pop
   //------------------------------------------------------------------------------
      always @(posedge hclk or negedge hresetn)  
      begin  
        if(!hresetn) begin  
          pop_d1     <= 1'b0;  
        end  
        else begin
          pop_d1     <= pop;  
        end  
      end  


      assign lastbrstrd   = push && (word_count == 32'h00000002);  
      assign lastbrstwr   = pop && (word_count == 32'h00000001);
       
   //------------------------------------------------------------------------------
   // delayed version of fcbusreq_o  
   // used in fmhtrans_o generation logic  
   //------------------------------------------------------------------------------   
   always @(posedge hclk or negedge hresetn)  
   begin  
        if(!hresetn)  
        busreq_prev <= 1'b0;  
        else  
        busreq_prev <= fcbusreq_o;  
   end  
       
endmodule // fsm_ctrl 
     
     
     
