// ***********************************************************************/
// Microsemi Corporation Proprietary and Confidential
// Copyright 2012 Microsemi Corporation.  All rights reserved.
//
// ANY USE OR REDISTRIBUTION IN PART OR IN WHOLE MUST BE HANDLED IN
// ACCORDANCE WITH THE ACTEL LICENSE AGREEMENT AND MUST BE APPROVED
// IN ADVANCE IN WRITING.
//
// Description:	CoreSF2Reset
//				Soft IP reset controller for SmartFusion2 device.
//              Sequences various reset signals to blocks to
//              SmartFusion2 device.
//
// SVN Revision Information:
// SVN $Revision: 20293 $
// SVN $Date: 2013-04-26 11:36:28 -0700 (Fri, 26 Apr 2013) $
//
// Notes:
//
// ***********************************************************************/

module CoreSF2Reset (
    // Clock from RC oscillator
    input           RCOSC_25_50MHZ,
    // Clock from fabric CCC
    //input           CLK_BASE,
    // Power on reset signal from g4m_control
    input           POWER_ON_RESET_N,
    // Signals from/to reset pad (open drain, bidirectional pad,
    //  connects to external reset controller.)
    input           EXT_RESET_IN_N,
    output  reg     EXT_RESET_OUT,
    // Signals to/from MSSDDR
    output  reg     MSS_RESET_N_F2M,
    output  reg     M3_RESET_N,
    input           MSS_RESET_N_M2F,
    output  reg     MDDR_DDR_AXI_S_CORE_RESET_N,
    output  reg     INIT_DONE,
    // CLR_INIT_DONE comes from CoreSF2Config
    input           CLR_INIT_DONE,
    // Configuration done indication from CoreSF2Config
    input           CONFIG_DONE,
    // Reset input from fabric. This is ANDed with EXT_RESET_IN_N in this
    // core.
    input           USER_FAB_RESET_IN_N,
    // Reset to (AHB/AXI based) user logic in fabric
    output  reg     USER_FAB_RESET_N,
    // FDDR signals
    input           FPLL_LOCK,
    output  reg     FDDR_CORE_RESET_N,
    // SERDESIF_0 signals
    input           SDIF0_SPLL_LOCK,
    output  reg     SDIF0_PHY_RESET_N,
    output  reg     SDIF0_CORE_RESET_N,
    // SERDESIF_1 signals
    input           SDIF1_SPLL_LOCK,
    output  reg     SDIF1_PHY_RESET_N,
    output  reg     SDIF1_CORE_RESET_N,
    // SERDESIF_2 signals
    input           SDIF2_SPLL_LOCK,
    output  reg     SDIF2_PHY_RESET_N,
    output  reg     SDIF2_CORE_RESET_N,
    // SERDESIF_3 signals
    input           SDIF3_SPLL_LOCK,
    output  reg     SDIF3_PHY_RESET_N,
    output  reg     SDIF3_CORE_RESET_N
    );

    parameter FAMILY = 19;

    // EXT_RESET_CFG is used to determine what can cause the external reset
    // to be driven (by asserting EXT_RESET_OUT).
    //    0 = EXT_RESET_OUT is never asserted
    //    1 = EXT_RESET_OUT is asserted if power up reset
    //        (POWER_ON_RESET_N) is asserted
    //    2 = EXT_RESET_OUT is asserted if MSS_RESET_N_M2F (from MSS) is
    //        asserted
    //    3 = EXT_RESET_OUT is asserted if power up reset
    //        (POWER_ON_RESET_N) or MSS_RESET_N_M2F (from MSS) is asserted.
    parameter EXT_RESET_CFG = 3;

    // DEVICE_VOLTAGE is set to according to the supply voltage to the
    // device. The supply voltage determines the RC oscillator frequency.
    // This can be 25 or 50 MHz.
    //    1 = 1.0 V (RC osc freq = 25 MHz)
    //    2 = 1.2 V (RC osc freq = 50 MHz)
    parameter DEVICE_VOLTAGE = 2;

    // Use the following parameters to indicate whether or not a particular
    // peripheral block is being used (and connected to this core).
    parameter MDDR_IN_USE  = 1;
    parameter FDDR_IN_USE  = 1;
    parameter SDIF0_IN_USE = 1;
    parameter SDIF1_IN_USE = 1;
    parameter SDIF2_IN_USE = 1;
    parameter SDIF3_IN_USE = 1;

    // DDR_WAIT specifies the time in microseconds that must have elapsed
    // between release of the reset to the FDDR block (FDDR_CORE_RESET_N)
    // and release of the reset to user logic (USER_FAB_RESET_N) (and
    // assertion of INIT_DONE output).
    parameter DDR_WAIT = 200;

    localparam RCOSC_MEGAHERTZ = 25 * DEVICE_VOLTAGE;

    localparam COUNT_130us = 130 * RCOSC_MEGAHERTZ;
    localparam COUNT_DDR   = DDR_WAIT * RCOSC_MEGAHERTZ;

    localparam COUNT_MAX = (COUNT_DDR > COUNT_130us) ? COUNT_DDR :
                                                       COUNT_130us;

    function integer calc_count_width;
        input x;
        integer x;
        begin
            if      (x > 2147483647) calc_count_width =  32;
            else if (x > 1073741823) calc_count_width =  31;
            else if (x >  536870911) calc_count_width =  30;
            else if (x >  268435455) calc_count_width =  29;
            else if (x >  134217727) calc_count_width =  28;
            else if (x >   67108863) calc_count_width =  27;
            else if (x >   33554431) calc_count_width =  26;
            else if (x >   16777215) calc_count_width =  25;
            else if (x >    8388607) calc_count_width =  24;
            else if (x >    4194303) calc_count_width =  23;
            else if (x >    2097151) calc_count_width =  22;
            else if (x >    1048575) calc_count_width =  21;
            else if (x >     524287) calc_count_width =  20;
            else if (x >     262143) calc_count_width =  19;
            else if (x >     131071) calc_count_width =  18;
            else if (x >      65535) calc_count_width =  17;
            else if (x >      32767) calc_count_width =  16;
            else if (x >      16383) calc_count_width =  15;
            else if (x >       8191) calc_count_width =  14;
            else if (x >       4095) calc_count_width =  13;
            else if (x >       2047) calc_count_width =  12;
            else if (x >       1023) calc_count_width =  11;
            else if (x >        511) calc_count_width =  10;
            else if (x >        255) calc_count_width =   9;
            else if (x >        127) calc_count_width =   8;
            else if (x >         63) calc_count_width =   7;
            else if (x >         31) calc_count_width =   6;
            else if (x >         15) calc_count_width =   5;
            else if (x >          7) calc_count_width =   4;
            else if (x >          3) calc_count_width =   3;
            else                     calc_count_width =   2;
        end
    endfunction

    localparam COUNT_WIDTH = calc_count_width(COUNT_MAX);

    // Parameters for state machine states
    localparam S0 = 0;
    localparam S1 = 1;
    localparam S2 = 2;
    localparam S3 = 3;
    localparam S4 = 4;
    localparam S5 = 5;
    localparam S6 = 6;

    // Signals
    reg     [2:0]   sm0_state;
    //reg     [2:0]   sm1_state;
    reg     [2:0]   sm2_state;
    reg     [2:0]   next_sm0_state;
    //reg     [2:0]   next_sm1_state;
    reg     [2:0]   next_sm2_state;
    reg             next_ext_reset_out;
    reg             next_user_fab_reset_n;
    reg             next_fddr_core_reset_n;
    reg             next_sdif0_phy_reset_n;
    reg             next_sdif0_core_reset_n;
    reg             next_sdif1_phy_reset_n;
    reg             next_sdif1_core_reset_n;
    reg             next_sdif2_phy_reset_n;
    reg             next_sdif2_core_reset_n;
    reg             next_sdif3_phy_reset_n;
    reg             next_sdif3_core_reset_n;
    reg             next_mddr_core_reset_n;
    //reg             next_user_mss_reset_n;
    //reg             next_fab_m3_reset_n;
    reg             next_count_enable;
    reg             next_init_done_rcosc;
    reg             release_ext_reset;
    reg             next_release_ext_reset;

    reg             sm0_areset_n;
    reg             sm1_areset_n;
    reg             sm2_areset_n;

    reg             sm0_areset_n_q1;
    reg             sm0_areset_n_rcosc;
    reg             sm1_areset_n_q1;
    reg             sm1_areset_n_rcosc;
    reg             sm2_areset_n_q1;
    reg             sm2_areset_n_rcosc;

    reg             fpll_lock_q1;
    reg             fpll_lock_q2;
    reg             sdif0_spll_lock_q1;
    reg             sdif0_spll_lock_q2;
    reg             sdif1_spll_lock_q1;
    reg             sdif1_spll_lock_q2;
    reg             sdif2_spll_lock_q1;
    reg             sdif2_spll_lock_q2;
    reg             sdif3_spll_lock_q1;
    reg             sdif3_spll_lock_q2;

    reg             count_130us;
    reg             count_ddr;
    reg             count_enable;

    reg             init_done_rcosc;

    reg [COUNT_WIDTH-1:0] count;

    reg             FPLL_LOCK_int;
    reg             SDIF0_SPLL_LOCK_int;
    reg             SDIF1_SPLL_LOCK_int;
    reg             SDIF2_SPLL_LOCK_int;
    reg             SDIF3_SPLL_LOCK_int;

    reg             CLR_INIT_DONE_q1;
    reg             CLR_INIT_DONE_rcosc;
    reg             CONFIG_DONE_q1;
    reg             CONFIG_DONE_rcosc;

    // If a peripheral block is not in use, internally tie its PLL lock
    // signal high.
    always @(*)
    begin
        if (FDDR_IN_USE)
        begin
            FPLL_LOCK_int = FPLL_LOCK;
        end
        else
        begin
            FPLL_LOCK_int = 1'b1;
        end
    end
    always @(*)
    begin
        if (SDIF0_IN_USE)
        begin
            SDIF0_SPLL_LOCK_int = SDIF0_SPLL_LOCK;
        end
        else
        begin
            SDIF0_SPLL_LOCK_int = 1'b1;
        end
    end
    always @(*)
    begin
        if (SDIF1_IN_USE)
        begin
            SDIF1_SPLL_LOCK_int = SDIF1_SPLL_LOCK;
        end
        else
        begin
            SDIF1_SPLL_LOCK_int = 1'b1;
        end
    end
    always @(*)
    begin
        if (SDIF2_IN_USE)
        begin
            SDIF2_SPLL_LOCK_int = SDIF2_SPLL_LOCK;
        end
        else
        begin
            SDIF2_SPLL_LOCK_int = 1'b1;
        end
    end
    always @(*)
    begin
        if (SDIF3_IN_USE)
        begin
            SDIF3_SPLL_LOCK_int = SDIF3_SPLL_LOCK;
        end
        else
        begin
            SDIF3_SPLL_LOCK_int = 1'b1;
        end
    end

    //---------------------------------------------------------------------
    // Create a number of asynchronous resets.
    // Some source reset signals may be "combined" to create a single
    // asynchronous reset.
    //---------------------------------------------------------------------
    always @(*)
    begin
        sm0_areset_n = EXT_RESET_IN_N && USER_FAB_RESET_IN_N
                       && POWER_ON_RESET_N && MSS_RESET_N_M2F;
    end

    // Assertion of resets to MSS (MSS_RESET_N_F2M and M3_RESET_N) caused
    // by assertion of external reset input or assertion of reset signal
    // from fabric.
    always @(*)
    begin
        sm1_areset_n = EXT_RESET_IN_N && USER_FAB_RESET_IN_N;
    end

    // There are a number of options for what can cause the external reset
    // to be asserted.
generate
  if (EXT_RESET_CFG == 0)
  begin
    always @(*)
    begin
        sm2_areset_n = POWER_ON_RESET_N;
    end
  end
  else if (EXT_RESET_CFG == 1)
  begin
    always @(*)
    begin
        sm2_areset_n = POWER_ON_RESET_N;
    end
  end
  else if (EXT_RESET_CFG == 2)
  begin
    always @(*)
    begin
        sm2_areset_n = MSS_RESET_N_M2F;
    end
  end
  else
  begin
    always @(*)
    begin
        sm2_areset_n = POWER_ON_RESET_N && MSS_RESET_N_M2F;
    end
  end
endgenerate

    //---------------------------------------------------------------------
    // Create versions of asynchronous resets that are released
    // synchronous to RCOSC_25_50MHZ.
    //---------------------------------------------------------------------
    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n)
    begin
        if (!sm0_areset_n)
        begin
            sm0_areset_n_q1 <= 1'b0;
            sm0_areset_n_rcosc <= 1'b0;
        end
        else
        begin
            sm0_areset_n_q1 <= 1'b1;
            sm0_areset_n_rcosc <= sm0_areset_n_q1;
        end
    end

    always @(posedge RCOSC_25_50MHZ or negedge sm1_areset_n)
    begin
        if (!sm1_areset_n)
        begin
            sm1_areset_n_q1 <= 1'b0;
            sm1_areset_n_rcosc <= 1'b0;
        end
        else
        begin
            sm1_areset_n_q1 <= 1'b1;
            sm1_areset_n_rcosc <= sm1_areset_n_q1;
        end
    end

    always @(posedge RCOSC_25_50MHZ or negedge sm2_areset_n)
    begin
        if (!sm2_areset_n)
        begin
            sm2_areset_n_q1 <= 1'b0;
            sm2_areset_n_rcosc <= 1'b0;
        end
        else
        begin
            sm2_areset_n_q1 <= 1'b1;
            sm2_areset_n_rcosc <= sm2_areset_n_q1;
        end
    end

    //---------------------------------------------------------------------
    // Synchronize CLR_INIT_DONE input to RCOSC_25_50MHZ domain.
    //---------------------------------------------------------------------
    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n_rcosc)
    begin
        if (!sm0_areset_n_rcosc)
        begin
            CLR_INIT_DONE_q1    <= 1'b0;
            CLR_INIT_DONE_rcosc <= 1'b0;
        end
        else
        begin
            CLR_INIT_DONE_q1    <= CLR_INIT_DONE;
            CLR_INIT_DONE_rcosc <= CLR_INIT_DONE_q1;
        end
    end

    //---------------------------------------------------------------------
    // Synchronize CONFIG_DONE input to RCOSC_25_50MHZ domain.
    //---------------------------------------------------------------------
    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n_rcosc)
    begin
        if (!sm0_areset_n_rcosc)
        begin
            CONFIG_DONE_q1    <= 1'b0;
            CONFIG_DONE_rcosc <= 1'b0;
        end
        else
        begin
            CONFIG_DONE_q1    <= CONFIG_DONE;
            CONFIG_DONE_rcosc <= CONFIG_DONE_q1;
        end
    end

    //---------------------------------------------------------------------
    // Synchronize PLL lock signals to RCOSC_25_50MHZ domain.
    //---------------------------------------------------------------------
    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n_rcosc)
    begin
        if (!sm0_areset_n_rcosc)
        begin
            fpll_lock_q1       <= 1'b0;
            fpll_lock_q2       <= 1'b0;
            sdif0_spll_lock_q1 <= 1'b0;
            sdif0_spll_lock_q2 <= 1'b0;
            sdif1_spll_lock_q1 <= 1'b0;
            sdif1_spll_lock_q2 <= 1'b0;
            sdif2_spll_lock_q1 <= 1'b0;
            sdif2_spll_lock_q2 <= 1'b0;
            sdif3_spll_lock_q1 <= 1'b0;
            sdif3_spll_lock_q2 <= 1'b0;
        end
        else
        begin
            fpll_lock_q1       <= FPLL_LOCK_int;
            fpll_lock_q2       <= fpll_lock_q1;
            sdif0_spll_lock_q1 <= SDIF0_SPLL_LOCK_int;
            sdif0_spll_lock_q2 <= sdif0_spll_lock_q1;
            sdif1_spll_lock_q1 <= SDIF1_SPLL_LOCK_int;
            sdif1_spll_lock_q2 <= sdif1_spll_lock_q1;
            sdif2_spll_lock_q1 <= SDIF2_SPLL_LOCK_int;
            sdif2_spll_lock_q2 <= sdif2_spll_lock_q1;
            sdif3_spll_lock_q1 <= SDIF3_SPLL_LOCK_int;
            sdif3_spll_lock_q2 <= sdif3_spll_lock_q1;
        end
    end

    //---------------------------------------------------------------------
    // State machine 0
    // Controls all output signals except MSS_RESET_N_F2M, M3_RESET_N and
    // EXT_RESET_OUT.
    //---------------------------------------------------------------------
    // State machine 0 - combinational part
    always @(*)
    begin
        next_sm0_state = sm0_state;
        next_user_fab_reset_n = USER_FAB_RESET_N;
        next_fddr_core_reset_n = FDDR_CORE_RESET_N;
        next_sdif0_phy_reset_n = SDIF0_PHY_RESET_N;
        next_sdif0_core_reset_n = SDIF0_CORE_RESET_N;
        next_sdif1_phy_reset_n = SDIF1_PHY_RESET_N;
        next_sdif1_core_reset_n = SDIF1_CORE_RESET_N;
        next_sdif2_phy_reset_n = SDIF2_PHY_RESET_N;
        next_sdif2_core_reset_n = SDIF2_CORE_RESET_N;
        next_sdif3_phy_reset_n = SDIF3_PHY_RESET_N;
        next_sdif3_core_reset_n = SDIF3_CORE_RESET_N;
        next_mddr_core_reset_n = MDDR_DDR_AXI_S_CORE_RESET_N;
        next_count_enable = count_enable;
        next_init_done_rcosc = init_done_rcosc;
        next_release_ext_reset = release_ext_reset;
        case (sm0_state)
            S0:
            begin
                next_sm0_state = S1;
            end
            S1:
            begin
                next_sm0_state = S2;
                // Release resets to FDDR and MDDR blocks
                next_fddr_core_reset_n = 1'b1;
                next_mddr_core_reset_n = 1'b1;
            end
            S2:
            begin
                // Wait for CONFIG_DONE and PLL lock signals
                if (CONFIG_DONE_rcosc && fpll_lock_q2 && sdif0_spll_lock_q2 && sdif1_spll_lock_q2
                    && sdif2_spll_lock_q2 && sdif3_spll_lock_q2)
                begin
                    next_sm0_state = S3;
                    // Release serdes phy resets and start counter
                    next_sdif0_phy_reset_n = 1'b1;
                    next_sdif1_phy_reset_n = 1'b1;
                    next_sdif2_phy_reset_n = 1'b1;
                    next_sdif3_phy_reset_n = 1'b1;
                    next_count_enable = 1'b1;
                end
            end
            S3:
            begin
                // Release serdes core resets 130us after phy resets.
                if (count_130us)
                begin
                    next_sm0_state = S4;
                    next_sdif0_core_reset_n = 1'b1;
                    next_sdif1_core_reset_n = 1'b1;
                    next_sdif2_core_reset_n = 1'b1;
                    next_sdif3_core_reset_n = 1'b1;
                end
            end
            S4:
            begin
                next_sm0_state = S5;
            end
            S5:
            begin
                // Wait until enough time has been allowed for DDR memory
                // to be ready for use before releasing reset to user logic
                // in fabric and asserting INIT_DONE output.
                // (May not have to wait here at all, depending on how long
                // it takes for CONFIG_DONE input to be asserted.)
                if (count_ddr)
                begin
                    next_sm0_state = S6;
                    next_user_fab_reset_n = 1'b1;
                    next_init_done_rcosc = 1'b1;
                    next_count_enable = 1'b0;
                end
            end
            S6:
            begin
                next_sm0_state = S6;
                // Allow release of external reset at this point.
                // A separate state machine controls the external reset.
                // The external reset may or may not be asserted depending
                // on the reset source and the configuration chosen for
                // external reset via the EXT_RESET_CFG parameter.
                next_release_ext_reset = 1'b1;
            end
            default:
            begin
                next_sm0_state = S0;
            end
        endcase
    end

    // State machine 0 - sequential part
    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n_rcosc)
    begin
        if (!sm0_areset_n_rcosc)
        begin
            sm0_state                   <= S0;
            USER_FAB_RESET_N            <= 1'b0;
            FDDR_CORE_RESET_N           <= 1'b0;
            SDIF0_PHY_RESET_N           <= 1'b0;
            SDIF0_CORE_RESET_N          <= 1'b0;
            SDIF1_PHY_RESET_N           <= 1'b0;
            SDIF1_CORE_RESET_N          <= 1'b0;
            SDIF2_PHY_RESET_N           <= 1'b0;
            SDIF2_CORE_RESET_N          <= 1'b0;
            SDIF3_PHY_RESET_N           <= 1'b0;
            SDIF3_CORE_RESET_N          <= 1'b0;
            MDDR_DDR_AXI_S_CORE_RESET_N <= 1'b0;
            count_enable                <= 1'b0;
            release_ext_reset           <= 1'b0;
        end
        else
        begin
            sm0_state                   <= next_sm0_state;
            USER_FAB_RESET_N            <= next_user_fab_reset_n;
            FDDR_CORE_RESET_N           <= next_fddr_core_reset_n;
            SDIF0_PHY_RESET_N           <= next_sdif0_phy_reset_n;
            SDIF0_CORE_RESET_N          <= next_sdif0_core_reset_n;
            SDIF1_PHY_RESET_N           <= next_sdif1_phy_reset_n;
            SDIF1_CORE_RESET_N          <= next_sdif1_core_reset_n;
            SDIF2_PHY_RESET_N           <= next_sdif2_phy_reset_n;
            SDIF2_CORE_RESET_N          <= next_sdif2_core_reset_n;
            SDIF3_PHY_RESET_N           <= next_sdif3_phy_reset_n;
            SDIF3_CORE_RESET_N          <= next_sdif3_core_reset_n;
            MDDR_DDR_AXI_S_CORE_RESET_N <= next_mddr_core_reset_n;
            count_enable                <= next_count_enable;
            //init_done_rcosc             <= next_init_done_rcosc;
            release_ext_reset           <= next_release_ext_reset;
        end
    end

    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n_rcosc)
    begin
        if (!sm0_areset_n_rcosc)
        begin
            init_done_rcosc <= 1'b0;
        end
        else
        begin
            if (next_init_done_rcosc)
            begin
                init_done_rcosc <= 1'b1;
            end
            if (CLR_INIT_DONE_rcosc)
            begin
                init_done_rcosc <= 1'b0;
            end
        end
    end
    // End of state machine 0.
    //---------------------------------------------------------------------

    //---------------------------------------------------------------------
    // State machine 1
    // Controls MSS_RESET_N_F2M and M3_RESET_N signals.
    //---------------------------------------------------------------------
/*
    // State machine 1 - combinational part
    always @(*)
    begin
        next_sm1_state = sm1_state;
        next_user_mss_reset_n = MSS_RESET_N_F2M;
        next_fab_m3_reset_n = M3_RESET_N;
        case (sm1_state)
            S0:
            begin
                next_sm1_state = S1;
            end
            S1:
            begin
                // Not waiting for PLL lock signals to be asserted before
                // releasing MSS_RESET_N_F2M and M3_RESET_N.
                next_user_mss_reset_n = 1'b1;
                next_fab_m3_reset_n = 1'b1;
            end
            default:
            begin
                next_sm1_state = S0;
            end
        endcase
    end

    // State machine 1 - sequential part
    always @(posedge RCOSC_25_50MHZ or negedge sm1_areset_n_rcosc)
    begin
        if (!sm1_areset_n_rcosc)
        begin
            sm1_state       <= S0;
            MSS_RESET_N_F2M <= 1'b0;
            M3_RESET_N      <= 1'b0;
        end
        else
        begin
            sm1_state       <= next_sm1_state;
            MSS_RESET_N_F2M <= next_user_mss_reset_n;
            M3_RESET_N      <= next_fab_m3_reset_n;
        end
    end
    // End of state machine 1.
*/

    always @(posedge RCOSC_25_50MHZ or negedge sm1_areset_n_rcosc)
    begin
        if (!sm1_areset_n_rcosc)
        begin
            MSS_RESET_N_F2M <= 1'b0;
            M3_RESET_N      <= 1'b0;
        end
        else
        begin
            MSS_RESET_N_F2M <= 1'b1;
            M3_RESET_N      <= 1'b1;
        end
    end
    //---------------------------------------------------------------------

    //---------------------------------------------------------------------
    // State machine 2
    // Controls EXT_RESET_OUT signal.
    //---------------------------------------------------------------------
    // State machine 2 - combinational part
    always @(*)
    begin
        next_sm2_state = sm2_state;
        next_ext_reset_out = EXT_RESET_OUT;
        case (sm2_state)
            S0:
            begin
                next_sm2_state = S1;
            end
            S1:
            begin
                // release_ext_reset is controlled by state machine 0.
                if (release_ext_reset)
                begin
                    next_ext_reset_out = 1'b0;
                end
            end
            default:
            begin
                next_sm2_state = S0;
            end
        endcase
    end

    // State machine 2 - sequential part
    always @(posedge RCOSC_25_50MHZ or negedge sm2_areset_n_rcosc)
    begin
        if (!sm2_areset_n_rcosc)
        begin
            sm2_state       <= S0;
            EXT_RESET_OUT   <= (EXT_RESET_CFG > 0) ? 1'b1 : 1'b0;
        end
        else
        begin
            sm2_state       <= next_sm2_state;
            EXT_RESET_OUT   <= next_ext_reset_out;
        end
    end
    // End of state machine 2.
    //---------------------------------------------------------------------

    // Counter clocked by RCOSC_25_50MHZ.
    // Used to time intervals between reset releases.
    always @(posedge RCOSC_25_50MHZ or negedge sm0_areset_n_rcosc)
    begin
        if (!sm0_areset_n_rcosc)
        begin
            count <= 'd0;
            count_130us <= 1'b0;
            count_ddr <= 1'b0;
        end
        else
        begin
            if (count_enable)
            begin
                count <= count + 'd1;
            end
            // Detect elapse of 130us.
            if (count == COUNT_130us)
            begin
                count_130us <= 1'b1;
            end
            // Detect when enough time has been allowed for DDR memory to
            // be ready for use
            if (count == COUNT_DDR)
            begin
                count_ddr <= 1'b1;
            end
        end
    end

    always @(*)
    begin
        INIT_DONE = init_done_rcosc;
    end

endmodule
