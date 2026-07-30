// ****************************************************************************/   
// Actel Corporation Proprietary and Confidential   
// Copyright 2010 Actel Corporation.  All rights reserved.   
//   
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN   
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED   
// IN ADVANCE IN WRITING.   
//   
// Description: AHBLMaster.v - AHBL Master IF 
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
 
 
module CoreSysServices_AHBLMasterIF (   
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
                        // Backend IF from FSM Control logic
                        fmhsel_i,
                        fmhtrans_i,  
                        fmhwrite_i,  
                        fmhsize_i,  
                        fmhburst_i,  
                        fmhaddr_i,  
                        fmhwdata_i,
                        mfhready_o,  
                        mfhresp_o,  
                        mfhrdata_o  
                        
                        );   
   
   //------------------------------------------------------------------------------   
   // Parameter declarations   
   //------------------------------------------------------------------------------   
   localparam AHB_AWIDTH      = 32;   
   localparam AHB_DWIDTH      = 32;   
   
   //------------------------------------------------------------------------------   
   // Port declarations   
   //------------------------------------------------------------------------------   
   
   // -----------   
   // Inputs   
   // -----------   
   // AHBL Master IF   
   input                    HCLK;   
   input                    HRESETN;   
   input                    HREADY;   
   input [AHB_DWIDTH - 1:0] HRDATA;   
   input                    HRESP;   
   // Backend IF
   input                    fmhsel_i;             // hsel input   
   input [1:0]              fmhtrans_i;           // type of current transfer  
   input                    fmhwrite_i;           // type of current transfer  
   // (NONSEQ,SEQ,IDLE,BUSY)  
   input [2:0]              fmhsize_i;            // size of current transfer  
   input [2:0]              fmhburst_i;           // Burst type  
   input [31:0]             fmhaddr_i;            // Address in onto AHB for Rd/Wr     
   input [31:0]             fmhwdata_i;           // Write data in to AHB for Rx   
   

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
   

   // Backend IF      
   output                    mfhresp_o;          // transfer response from AHB Slave  
                                                 // (OKAY,ERROR)  
   output [31:0]             mfhrdata_o;         // Read data from AHB  
   output                    mfhready_o;         // Ready from AHB
   
   // -----------------  
   // Internal signals  
   // -----------------  
   wire                      HSEL;   
   wire [AHB_AWIDTH - 1:0]   HADDR;   
   wire                      HWRITE;   
   wire [AHB_DWIDTH - 1:0]   HWDATA;   
   wire [1:0]                HTRANS;   
   wire [2:0]                HBURST;   
   wire [2:0]                HSIZE;   
   
   wire [AHB_DWIDTH - 1:0]   mfhrdata_o;    
   wire                      mfhresp_o;
   wire                      mfhready_o;
   
   //////////////////////////////////////////////////////////////////////////////  
   //                           Start-of-Code                                  //  
   //////////////////////////////////////////////////////////////////////////////  
   
   assign                    HSEL       = fmhsel_i;
   assign                    HADDR      = fmhaddr_i;
   assign                    HWRITE     = fmhwrite_i;
   assign                    HWDATA     = fmhwdata_i;
   assign                    HTRANS     = fmhtrans_i;
   assign                    HBURST     = fmhburst_i;       
   assign                    HSIZE      = fmhsize_i;
   assign                    mfhresp_o  = HRESP;
   assign                    mfhrdata_o = HRDATA;
   assign                    mfhready_o = HREADY;   

endmodule // AHBLMasterIF

