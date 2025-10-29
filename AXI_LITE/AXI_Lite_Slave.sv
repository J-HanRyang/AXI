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
    logic [31:0] slv_reg1;  // ADDR = 0x00
    logic [31:0] slv_reg2;  // ADDR = 0x04
    logic [31:0] slv_reg3;  // ADDR = 0x08
    logic [31:0] slv_reg4;  // ADDR = 0x0c


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
            aw_state <= AW_IDLE_S;
        end else begin
            aw_state <= aw_state_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        AWREADY = 1'b0;

        case (aw_state)
            AW_IDLE_S: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY_S;
                end
            end

            AW_READY_S: begin
                AWREADY = 1'b1;
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
            w_state <= W_IDLE_S;
            slv_reg1 = 32'b0;
            slv_reg2 = 32'b0;
            slv_reg3 = 32'b0;
            slv_reg4 = 32'b0;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY       = 1'b0;


        case (w_state)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if (WVALID) begin
                    w_state_next = W_READY_S;
                end
            end

            W_READY_S: begin
                case (AWADDR)
                    4'h0: slv_reg1 = WDATA;
                    4'h4: slv_reg2 = WDATA;
                    4'h8: slv_reg3 = WDATA;
                    4'hc: slv_reg4 = WDATA;
                endcase
                WREADY       = 1'b1;
                w_state_next = W_IDLE_S;
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
        b_state_next = b_state;
        BRESP        = 2'b0;
        BVALID       = 1'b0;

        case (b_state)
            B_IDLE_S: begin
                BVALID = 1'b0;
                if (WVALID & WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end

            B_VALID_S: begin
                BRESP  = 2'b0;
                BVALID = 1'b1;
                if (BVALID & BREADY) begin
                    b_state_next = B_IDLE_S;
                end
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
            ar_state <= AR_IDLE_S;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARREADY = 1'b0;

        case (ar_state)
            AR_IDLE_S: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY_S;
                end
            end

            AR_READY_S: begin
                ARREADY = 1'b1;
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
        r_state_next = r_state;
        RDATA        = 32'bx;
        RVALID       = 1'b0;
        RRESP        = 2'b0;

        case (r_state)
            R_IDLE_S: begin
                RVALID = 1'b0;
                if (ARVALID & ARREADY) begin
                    r_state_next = R_VALID_S;
                end
            end

            R_VALID_S: begin
                case (ARADDR)
                    4'h0: RDATA = slv_reg1;
                    4'h4: RDATA = slv_reg2;
                    4'h8: RDATA = slv_reg3;
                    4'hc: RDATA = slv_reg4;
                endcase
                RVALID = 1'b1;
                RRESP  = 2'b0;
                if (RVALID & RREADY) begin
                    r_state_next = R_IDLE_S;
                end
            end
        endcase
    end
endmodule
