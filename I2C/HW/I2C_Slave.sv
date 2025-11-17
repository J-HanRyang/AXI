`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
//
// Create Date      : 2025/11/13
// Design Name      : I2C
// Module Name      : I2C_Slave
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : I2C Slave
//
// Revision         : 2025/11/14    V1.1 Update - Add Reg_Addr FSM
//////////////////////////////////////////////////////////////////////////////////

module I2C_Slave #(
    parameter SLAVE_ADDR = 7'h54
) (
    // Global Signals.
    input  logic       iClk,
    input  logic       iRst,
    // Master Signals
    input  logic       iSCL,
    inout  logic       ioSDA,
    // Registers
    output logic [7:0] oReg0,
    output logic [7:0] oReg1,
    output logic [7:0] oReg2,
    output logic [7:0] oReg3
);

    /***********************************************
    // Reg & Wire
    ***********************************************/
    logic sda_out_reg, sda_out_next;
    logic sda_oe_reg, sda_oe_next;
    logic sda_in;

    // SCL/SDA Edge Detect
    logic scl_prev, sda_prev;
    logic scl_rise, scl_fall;
    logic start_cond, stop_cond;

    // Data Registers
    logic [7:0] rx_data_reg, rx_data_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [2:0] bit_count_reg, bit_count_next;
    logic [1:0] ptr_reg, ptr_next;
    logic ptr_set_reg, ptr_set_next;
    logic rw_bit_reg, rw_bit_next;
    logic addr_match_reg, addr_match_next;

    // Output Registers
    logic [7:0] reg0, reg1, reg2, reg3;

    assign oReg0 = reg0;
    assign oReg1 = reg1;
    assign oReg2 = reg2;
    assign oReg3 = reg3;


    /***********************************************
    // Edge Detect
    ***********************************************/
    always_ff @(posedge iClk, posedge iRst) begin
        if (iRst) begin
            scl_prev <= 1'b1;
            sda_prev <= 1'b1;
        end else begin
            scl_prev <= iSCL;
            sda_prev <= sda_in;
        end
    end

    assign scl_rise   = iSCL & ~scl_prev;
    assign scl_fall   = ~iSCL & scl_prev;

    assign start_cond = iSCL & ~sda_in & sda_prev;  // SDA: 1 → 0
    assign stop_cond  = iSCL & sda_in & ~sda_prev;  // SDA: 0 → 1


    /***********************************************
    // FSM 
    ***********************************************/
    typedef enum logic [3:0] {
        SL_IDLE,
        SL_ADDR,
        SL_RW_BIT,
        SL_ADDR_ACK,
        SL_REG_ADDR,
        SL_REG_ADDR_ACK,
        SL_WRITE_DATA,
        SL_WRITE_ACK,
        SL_READ_DATA,
        SL_READ_ACK
    } state_t;

    state_t state, state_next;


    /***********************************************
    // State & Register Update
    ***********************************************/
    always_ff @(posedge iClk, posedge iRst) begin
        if (iRst) begin
            state          <= SL_IDLE;
            rx_data_reg    <= 0;
            tx_data_reg    <= 0;
            bit_count_reg  <= 0;
            rw_bit_reg     <= 0;
            addr_match_reg <= 0;
            ptr_reg        <= 0;
            ptr_set_reg    <= 0;
            sda_out_reg    <= 1'b0;
            sda_oe_reg     <= 1'b0;
            reg0           <= 0;
            reg1           <= 0;
            reg2           <= 0;
            reg3           <= 0;
        end else begin
            state          <= state_next;
            rx_data_reg    <= rx_data_next;
            tx_data_reg    <= tx_data_next;
            bit_count_reg  <= bit_count_next;
            rw_bit_reg     <= rw_bit_next;
            addr_match_reg <= addr_match_next;
            ptr_reg        <= ptr_next;
            ptr_set_reg    <= ptr_set_next;
            sda_out_reg    <= sda_out_next;
            sda_oe_reg     <= sda_oe_next;

            // Write to output registers
            if (state_next == SL_WRITE_ACK && state == SL_WRITE_DATA && ptr_set_reg) begin

                case (ptr_reg)
                    2'd0: reg0 <= rx_data_reg;
                    2'd1: reg1 <= rx_data_reg;
                    2'd2: reg2 <= rx_data_reg;
                    2'd3: reg3 <= rx_data_reg;
                endcase
            end  // Update TX data before READ
            else if (state_next == SL_READ_DATA && ptr_set_reg) begin
                case (ptr_reg)
                    2'd0: tx_data_reg <= reg0;
                    2'd1: tx_data_reg <= reg1;
                    2'd2: tx_data_reg <= reg2;
                    2'd3: tx_data_reg <= reg3;
                endcase
            end
        end
    end


    /***********************************************
    // Next-State Logic
    ***********************************************/
    always_comb begin
        state_next      = state;
        rx_data_next    = rx_data_reg;
        tx_data_next    = tx_data_reg;
        bit_count_next  = bit_count_reg;
        rw_bit_next     = rw_bit_reg;
        addr_match_next = addr_match_reg;
        ptr_next        = ptr_reg;
        ptr_set_next    = ptr_set_reg;
        sda_out_next    = 1'b0;
        sda_oe_next     = 1'b0;


        if (stop_cond) begin
            state_next   = SL_IDLE;
            ptr_set_next = 1'b0;
        end else if (start_cond) begin
            state_next     = SL_ADDR;
            bit_count_next = 0;
            rx_data_next   = 0;
            ptr_set_next   = 1'b0;
        end else begin
            case (state)
                SL_IDLE: begin
                    // Nothing special here
                end

                SL_ADDR: begin
                    sda_oe_next = 1'b0;

                    if (scl_rise) rx_data_next = {rx_data_reg[6:0], sda_in};

                    if (scl_fall) begin
                        if (bit_count_reg == 7) begin
                            bit_count_next = 0;
                            state_next     = SL_RW_BIT;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                end

                SL_RW_BIT: begin
                    sda_oe_next = 1'b0;

                    if (scl_rise) begin
                        rw_bit_next     = sda_in;
                        addr_match_next = (rx_data_reg == SLAVE_ADDR);
                    end

                    if (scl_fall) state_next = SL_ADDR_ACK;
                end

                SL_ADDR_ACK: begin
                    sda_oe_next  = 1'b1;
                    sda_out_next = ~addr_match_reg;  // ACK=0 / NACK=1

                    if (scl_fall) begin
                        if (!addr_match_reg) begin
                            state_next = SL_IDLE;
                        end else begin
                            state_next = SL_REG_ADDR;
                        end
                    end
                end

                SL_REG_ADDR: begin
                    sda_oe_next = 1'b0;

                    if (scl_rise) rx_data_next = {rx_data_reg[6:0], sda_in};

                    if (scl_fall) begin
                        if (bit_count_reg == 7) begin
                            ptr_next       = rx_data_reg[1:0];
                            bit_count_next = 0;
                            state_next     = SL_REG_ADDR_ACK;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                end

                SL_REG_ADDR_ACK: begin
                    sda_oe_next  = 1'b1;
                    sda_out_next = 1'b0;

                    if (scl_fall) begin
                        ptr_set_next = 1'b1;

                        if (!rw_bit_reg) state_next = SL_WRITE_DATA;
                        else state_next = SL_READ_DATA;
                    end
                end

                SL_WRITE_DATA: begin
                    sda_oe_next = 1'b0;

                    if (scl_rise) rx_data_next = {rx_data_reg[6:0], sda_in};

                    if (scl_fall) begin
                        if (bit_count_reg == 7) begin
                            bit_count_next = 0;
                            state_next     = SL_WRITE_ACK;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                end

                SL_WRITE_ACK: begin
                    sda_oe_next  = 1'b1;
                    sda_out_next = 1'b0;

                    if (scl_fall) state_next = SL_WRITE_DATA;
                end

                SL_READ_DATA: begin
                    sda_oe_next  = 1'b1;
                    sda_out_next = tx_data_reg[7];
                    ptr_set_next = 1'b0;

                    if (scl_fall) begin
                        tx_data_next = {tx_data_reg[6:0], 1'b0};

                        if (bit_count_reg == 7) begin
                            bit_count_next = 0;
                            state_next     = SL_READ_ACK;
                            ptr_set_next   = 1'b1;
                        end else begin
                            bit_count_next = bit_count_reg + 1;
                        end
                    end
                end

                SL_READ_ACK: begin
                    sda_oe_next = 1'b0;

                    if (scl_fall) begin
                        if (sda_in) begin
                            state_next = SL_IDLE;  // NACK
                        end else begin
                            ptr_set_next = 1'b1;
                            state_next   = SL_READ_DATA;
                        end
                    end
                end

                default: begin
                    state_next = SL_IDLE;
                end
            endcase
        end
    end

    /***********************************************
    // Output
    ***********************************************/
    assign ioSDA  = sda_oe_reg ? sda_out_reg : 1'bz;
    assign sda_in = ioSDA;

endmodule
