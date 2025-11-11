`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/11/11
// Design Name      : I2C
// Module Name      : I2C_Master
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      :
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////


module I2C_Master #(
    parameter CLK_FREQ = 100_000_000,
    parameter I2C_FREQ = 100_000
) (
    // Global Signals
    input  logic       iClk,
    input  logic       iRst,
    // External Signals
    // input  logic       iI2C_En,
    input  logic       iI2C_Start,
    input  logic       iI2C_Stop,
    input  logic       iI2C_Write,
    input  logic       iI2C_Read,
    //      Tx
    input  logic [7:0] iTx_Data,
    output logic       oTx_Done,
    output logic       oTx_Ready,
    //      Rx
    output logic [7:0] oRx_Data,
    output logic       oRx_Done,
    // Internal Signals
    output logic       oSCL,
    inout  logic       ioSDA
);

    localparam CNT_MAX = (CLK_FREQ / (I2C_FREQ * 2));  // 500
    localparam CNT_COUNT_WIDTH = $clog2(CNT_MAX);


    typedef enum logic [7:0] {
        // IDLE / START
        p_IDLE         = 8'h00,
        p_START_1      = 8'h01,
        p_START_2      = 8'h02,
        // WRITE_DATA
        p_WRITE_DATA_1 = 8'h10,
        p_WRITE_DATA_2 = 8'h11,
        p_WRITE_DATA_3 = 8'h12,
        p_WRITE_DATA_4 = 8'h13,
        // READ_DATA
        p_READ_DATA_1  = 8'h20,
        p_READ_DATA_2  = 8'h21,
        p_READ_DATA_3  = 8'h22,
        p_READ_DATA_4  = 8'h23,
        // ACK
        p_ACK_1        = 8'h30,
        p_ACK_2        = 8'h31,
        p_ACK_3        = 8'h32,
        p_ACK_4        = 8'h33,
        // SEND_ACK
        p_SEND_ACK_1   = 8'h40,
        p_SEND_ACK_2   = 8'h41,
        p_SEND_ACK_3   = 8'h42,
        p_SEND_ACK_4   = 8'h43,
        // HOLD
        p_HOLD         = 8'hE0,
        // STOP
        p_STOP_1       = 8'hF1,
        p_STOP_2       = 8'hF2
    } state_t;

    state_t state, state_next;


    /***********************************************
    // Reg & Wire
    ***********************************************/
    // SDA
    logic sda_out_reg, sda_out_next;
    logic sda_oe_reg, sda_oe_next;
    logic sda_in;

    // Data / Count
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [CNT_COUNT_WIDTH-1 : 0] cnt_count_reg, cnt_count_next;
    logic [2:0] bit_count_reg, bit_count_next;

    // ACK
    logic ack_reg, ack_next;
    logic send_nack_reg, send_nack_next;


    /***********************************************
    // FSM 
    ***********************************************/
    // Current State Update
    always_ff @(posedge iClk, posedge iRst) begin
        if (iRst) begin
            state         <= p_IDLE;
            tx_data_reg   <= 0;
            rx_data_reg   <= 0;
            cnt_count_reg <= 0;
            bit_count_reg <= 0;
            sda_out_reg   <= 0;
            sda_oe_reg    <= 0;
            ack_reg       <= 0;
            send_nack_reg <= 0;

        end else begin
            state         <= state_next;
            tx_data_reg   <= tx_data_next;
            rx_data_reg   <= rx_data_next;
            cnt_count_reg <= cnt_count_next;
            bit_count_reg <= bit_count_next;
            sda_out_reg   <= sda_out_next;
            sda_oe_reg    <= sda_oe_next;
            ack_reg       <= ack_next;
            send_nack_reg <= send_nack_next;
        end
    end

    // Next State Decision
    always_comb begin
        state_next     = state;
        tx_data_next   = tx_data_reg;
        rx_data_next   = rx_data_reg;
        bit_count_next = bit_count_reg;
        ack_next       = ack_reg;
        send_nack_next = send_nack_reg;
        // Count
        cnt_count_next = cnt_count_reg + 1;
        // SCL/SDA
        oSCL           = 1'b1;
        sda_out_next   = 1'b1;
        sda_oe_next    = 1'b0;
        // Output Ports
        oTx_Done       = 1'b0;
        oTx_Ready      = 1'b0;
        oRx_Done       = 1'b0;

        case (state)
            p_IDLE: begin
                if (iI2C_Start) begin
                    state_next = p_START_1;
                end
            end

            // START
            p_START_1: begin
                sda_oe_next  = 1'b1;
                sda_out_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX - 1)) begin
                    state_next     = p_START_2;
                    cnt_count_next = 0;
                end
            end

            p_START_2: begin
                oSCL         = 1'b0;
                sda_oe_next  = 1'b1;
                sda_out_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX - 1)) begin
                    state_next     = p_WRITE_DATA_1;
                    tx_data_next   = iTx_Data;
                    bit_count_next = 0;
                    cnt_count_next = 0;
                end
            end

            // WRITE
            p_WRITE_DATA_1: begin
                oSCL         = 1'b0;
                sda_oe_next  = 1'b1;
                sda_out_next = tx_data_reg[7];

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_WRITE_DATA_2;
                    cnt_count_next = 0;
                end
            end

            p_WRITE_DATA_2: begin
                oSCL         = 1'b1;
                sda_oe_next  = 1'b1;
                sda_out_next = tx_data_reg[7];

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_WRITE_DATA_3;
                    cnt_count_next = 0;
                end
            end

            p_WRITE_DATA_3: begin
                oSCL         = 1'b1;
                sda_oe_next  = 1'b1;
                sda_out_next = tx_data_reg[7];

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_WRITE_DATA_4;
                    cnt_count_next = 0;
                end
            end

            p_WRITE_DATA_4: begin
                oSCL         = 1'b0;
                sda_oe_next  = 1'b1;
                sda_out_next = tx_data_reg[7];

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    tx_data_next   = {tx_data_reg[6:0], 1'b0};
                    cnt_count_next = 0;

                    if (bit_count_reg == 7) begin
                        bit_count_next = 0;
                        state_next     = p_ACK_1;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                        state_next     = p_WRITE_DATA_1;
                    end
                end
            end

            // READ
            p_READ_DATA_1: begin
                oSCL        = 1'b0;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_READ_DATA_2;
                    cnt_count_next = 0;
                end
            end

            p_READ_DATA_2: begin
                oSCL        = 1'b1;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_READ_DATA_3;
                    cnt_count_next = 0;
                end
            end

            p_READ_DATA_3: begin
                oSCL         = 1'b1;
                sda_oe_next  = 1'b0;
                rx_data_next = {rx_data_reg[6:0], sda_in};

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_READ_DATA_4;
                    cnt_count_next = 0;
                end
            end

            p_READ_DATA_4: begin
                oSCL        = 1'b0;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    cnt_count_next = 0;

                    if (bit_count_reg == 7) begin
                        bit_count_next = 0;
                        state_next     = p_SEND_ACK_1;
                    end else begin
                        bit_count_next = bit_count_reg + 1;
                        state_next     = p_READ_DATA_1;
                    end
                end
            end

            // WRITE_ACK
            p_ACK_1: begin
                oSCL        = 1'b0;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_ACK_2;
                    cnt_count_next = 0;
                end
            end

            p_ACK_2: begin
                oSCL        = 1'b1;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_ACK_3;
                    cnt_count_next = 0;
                end
            end

            p_ACK_3: begin
                oSCL        = 1'b1;
                sda_oe_next = 1'b0;
                ack_next    = sda_in;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next = p_ACK_4;
                    cnt_count_next = 0;
                end
            end

            p_ACK_4: begin
                oSCL        = 1'b0;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    cnt_count_next = 0;
                    oTx_Done       = 1'b1;

                    if (ack_reg == 1'b0) begin  // ACK
                        state_next = p_HOLD;
                    end else begin  // NACK
                        state_next = p_STOP_1;
                    end
                end
            end

            // READ_ACK
            p_SEND_ACK_1: begin
                oSCL         = 1'b0;
                sda_oe_next  = 1'b1;
                sda_out_next = send_nack_reg;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_SEND_ACK_2;
                    cnt_count_next = 0;
                end
            end

            p_SEND_ACK_2: begin
                oSCL         = 1'b1;
                sda_oe_next  = 1'b1;
                sda_out_next = send_nack_reg;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_SEND_ACK_3;
                    cnt_count_next = 0;
                end
            end

            p_SEND_ACK_3: begin
                oSCL         = 1'b1;
                sda_oe_next  = 1'b1;
                sda_out_next = send_nack_reg;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    state_next     = p_SEND_ACK_4;
                    cnt_count_next = 0;
                end
            end

            p_SEND_ACK_4: begin
                oSCL        = 1'b0;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX / 2 - 1)) begin
                    cnt_count_next = 0;
                    oRx_Done       = 1'b1;
                    oRx_Data       = rx_data_reg;

                    if (send_nack_reg) begin
                        state_next = p_STOP_1;
                    end else begin
                        state_next = p_HOLD;
                    end
                end
            end

            // HOLD
            p_HOLD: begin
                oSCL         = 1'b0;
                sda_out_next = 1'b0;
                oTx_Ready    = 1'b1;

                if (iI2C_Write) begin
                    state_next     = p_WRITE_DATA_1;
                    tx_data_next   = iTx_Data;
                    bit_count_next = 0;
                    cnt_count_next = 0;
                end else if (iI2C_Read) begin
                    state_next     = p_READ_DATA_1;
                    rx_data_next   = 0;
                    send_nack_next = iI2C_Stop;
                    bit_count_next = 0;
                    cnt_count_next = 0;
                end else if (iI2C_Stop) begin
                    state_next     = p_STOP_1;
                    cnt_count_next = 0;
                end
            end

            // STOP
            p_STOP_1: begin
                oSCL         = 1'b1;
                sda_oe_next  = 1'b1;
                sda_out_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX - 1)) begin
                    state_next     = p_STOP_2;
                    cnt_count_next = 0;
                end
            end

            p_STOP_2: begin
                oSCL        = 1'b1;
                sda_oe_next = 1'b0;

                if (cnt_count_reg == (CNT_MAX - 1)) begin
                    state_next     = p_IDLE;
                    cnt_count_next = 0;
                end
            end
        endcase
    end

    // Output Decision
    assign ioSDA  = sda_oe_reg ? sda_out_reg : 1'bz;
    assign sda_in = ioSDA;

endmodule
