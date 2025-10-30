`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/10/29
// Design Name      : AXI_LITE
// Module Name      : AXI_Lite_Slave
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : AXI Lite Slave Module
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module AXI_Lite_Slave (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // Write Address
    input  logic [ 3:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // Write Ddata
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // Write Response
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // Read Address
    input  logic [ 3:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // Read Data
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

    /***********************************************
    // Reg & Wire
    ***********************************************/
    logic [31:0] slv_reg1_reg, slv_reg1_next;  // ADDR = 0x00
    logic [31:0] slv_reg2_reg, slv_reg2_next;  // ADDR = 0x04
    logic [31:0] slv_reg3_reg, slv_reg3_next;  // ADDR = 0x08
    logic [31:0] slv_reg4_reg, slv_reg4_next;  // ADDR = 0x0c
    logic [3:0] aw_addr_reg, aw_addr_next;  // AWADDR Latching
    logic [3:0] ar_addr_reg, ar_addr_next;  // ARADDR Latching


    /***********************************************
    // WRITE Transaction, AW Channel tramsfer
    ***********************************************/
    typedef enum {
        AW_IDLE_S,
        AW_READY_S
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state    <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end else begin
            aw_state    <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always_comb begin
        AWREADY       = 1'b0;
        aw_state_next = aw_state;
        aw_addr_next  = aw_addr_reg;

        case (aw_state)
            AW_IDLE_S: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY_S;
                    aw_addr_next  = AWADDR;
                end
            end

            AW_READY_S: begin
                AWREADY       = 1'b1;
                aw_state_next = AW_IDLE_S;
            end
        endcase
    end


    /***********************************************
    // WRITE Transaction, W Channel tramsfer
    ***********************************************/
    typedef enum {
        W_IDLE_S,
        W_READY_S
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state      <= W_IDLE_S;
            slv_reg1_reg <= 32'b0;
            slv_reg2_reg <= 32'b0;
            slv_reg3_reg <= 32'b0;
            slv_reg4_reg <= 32'b0;
        end else begin
            w_state      <= w_state_next;
            slv_reg1_reg <= slv_reg1_next;
            slv_reg2_reg <= slv_reg2_next;
            slv_reg3_reg <= slv_reg3_next;
            slv_reg4_reg <= slv_reg4_next;
        end
    end

    always_comb begin
        WREADY        = 1'b0;
        w_state_next  = w_state;
        slv_reg1_next = slv_reg1_reg;
        slv_reg2_next = slv_reg2_reg;
        slv_reg3_next = slv_reg3_reg;
        slv_reg4_next = slv_reg4_reg;

        case (w_state)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if (AWVALID) begin
                    w_state_next = W_READY_S;
                end
            end

            W_READY_S: begin
                if (WVALID) begin
                    WREADY       = 1'b1;
                    w_state_next = W_IDLE_S;
                    case (aw_addr_reg[3:2])
                        2'd0: slv_reg1_next = WDATA;
                        2'd1: slv_reg2_next = WDATA;
                        2'd2: slv_reg3_next = WDATA;
                        2'd3: slv_reg4_next = WDATA;
                    endcase
                end
            end
        endcase
    end

    /***********************************************
    // WRITE Transaction, B Channel tramsfer
    ***********************************************/
    typedef enum {
        B_IDLE_S,
        B_VALID_S
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        BRESP        = 2'b0;
        BVALID       = 1'b0;
        b_state_next = b_state;

        case (b_state)
            B_IDLE_S: begin
                BVALID = 1'b0;
                if (WVALID & WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end

            B_VALID_S: begin
                BRESP        = 2'b0;
                BVALID       = 1'b1;
                b_state_next = B_IDLE_S;
            end
        endcase
    end

    /***********************************************
    // READ Transaction, AR Channel tramsfer
    ***********************************************/
    typedef enum {
        AR_IDLE_S,
        AR_READY_S
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state    <= AR_IDLE_S;
            ar_addr_reg <= 0;
        end else begin
            ar_state    <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always_comb begin
        ARREADY       = 1'b0;
        ar_state_next = ar_state;
        ar_addr_next  = ar_addr_reg;

        case (ar_state)
            AR_IDLE_S: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY_S;
                    ar_addr_next  = ARADDR;
                end
            end

            AR_READY_S: begin
                ARREADY       = 1'b1;
                ar_state_next = AR_IDLE_S;
            end
        endcase
    end

    /***********************************************
    // READ Transaction, R Channel tramsfer
    ***********************************************/
    typedef enum {
        R_IDLE_S,
        R_VALID_S
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        RDATA        = 32'bx;
        RVALID       = 1'b0;
        RRESP        = 2'b0;
        r_state_next = r_state;

        case (r_state)
            R_IDLE_S: begin
                RVALID = 1'b0;
                if (ARVALID & ARREADY) begin
                    r_state_next = R_VALID_S;
                end
            end

            R_VALID_S: begin
                RRESP  = 2'b0;
                RVALID = 1'b1;
                case (ar_addr_reg[3:2])
                    2'd0: RDATA = slv_reg1_reg;
                    2'd1: RDATA = slv_reg2_reg;
                    2'd2: RDATA = slv_reg3_reg;
                    2'd3: RDATA = slv_reg4_reg;
                endcase
                if (RVALID & RREADY) begin
                    r_state_next = R_IDLE_S;
                end
            end
        endcase
    end
endmodule
