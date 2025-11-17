`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// Create Date      : 2025/11/13
// Design Name      : I2C
// Module Name      : tb_I2C
// Description      : Testbench of I2C (WRITE then RESTART+READ+NACK+STOP)
//////////////////////////////////////////////////////////////////////////////////

module i2c_tb;

    // --------------------------------------------------------
    // Clock & Reset
    // --------------------------------------------------------
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;  // 100MHz

    // --------------------------------------------------------
    // I2C Bus (Wired-AND)
    // --------------------------------------------------------
    wire scl_master;
    wire sda_master_oe;
    wire sda_master_out;

    wire sda_slave_oe;
    wire sda_slave_out;

    // 실제 SDA 라인 (Wired-AND)
    wire SDA_line;

    assign SDA_line = (sda_master_oe ? sda_master_out : 1'b1) & (sda_slave_oe ? sda_slave_out : 1'b1);

    // Master에게 SDA 입력 공급
    wire       SDA_to_master = SDA_line;

    // Slave에게 SDA 입력 공급
    wire       SDA_to_slave = SDA_line;


    // --------------------------------------------------------
    // DUT : I2C Master
    // --------------------------------------------------------
    reg        iI2C_Start = 0;
    reg        iI2C_Stop = 0;
    reg        iI2C_Write = 0;
    reg        iI2C_Read = 0;
    reg  [7:0] iTx_Data = 0;

    wire [7:0] oRx_Data;
    wire       oRx_Done;
    wire       oTx_Done;
    wire       oTx_Ready;

    I2C_Master #(
        .CLK_FREQ(100_000_000),
        .I2C_FREQ(100_000)
    ) master (
        .iClk(clk),
        .iRst(rst),

        .iI2C_Start(iI2C_Start),
        .iI2C_Stop (iI2C_Stop),
        .iI2C_Write(iI2C_Write),
        .iI2C_Read (iI2C_Read),

        .iTx_Data(iTx_Data),

        .oTx_Done (oTx_Done),
        .oTx_Ready(oTx_Ready),

        .oRx_Data(oRx_Data),
        .oRx_Done(oRx_Done),

        .oSCL(scl_master),

        .ioSDA(SDA_to_master)  // master SDA in
    );

    assign sda_master_out = master.sda_out_reg;
    assign sda_master_oe  = master.sda_oe_reg;



    // --------------------------------------------------------
    // DUT : I2C Slave
    // --------------------------------------------------------
    wire [7:0] reg0, reg1, reg2, reg3;

    I2C_Slave #(
        .SLAVE_ADDR(7'h54)
    ) slave (
        .iClk(clk),
        .iRst(rst),

        .iSCL (scl_master),
        .ioSDA(SDA_to_slave), // slave SDA input/output

        .oReg0(reg0),
        .oReg1(reg1),
        .oReg2(reg2),
        .oReg3(reg3)
    );

    assign sda_slave_out = slave.sda_out_reg;
    assign sda_slave_oe  = slave.sda_oe_reg;



    // --------------------------------------------------------
    // Task : Send 1 byte (write flow)
    // --------------------------------------------------------
    task I2C_WRITE_BYTE(input [7:0] data);
        begin
            @(posedge clk);
            iTx_Data   = data;
            iI2C_Write = 1'b1;
            @(posedge clk);
            iI2C_Write = 1'b0;

            wait (oTx_Done);
            @(posedge clk);
        end
    endtask


    // --------------------------------------------------------
    // Task : Read 1 byte
    // --------------------------------------------------------
    task I2C_READ_BYTE();
        begin
            @(posedge clk);
            iI2C_Read = 1'b1;
            @(posedge clk);
            iI2C_Read = 1'b0;

            wait (oRx_Done);
            @(posedge clk);
            $display("READ DATA = %02x", oRx_Data);
        end
    endtask


    // --------------------------------------------------------
    // Test Scenario
    // --------------------------------------------------------
    initial begin
        $dumpfile("i2c_wave.vcd");
        $dumpvars(0, i2c_tb);

        // Reset
        #50 rst = 0;

        // ----------------------------------------------------
        // ① Write: Slave Address (Write)
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b0};  // addr + write(0)
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        // ----------------------------------------------------
        // ② Write: register pointer = 0x01
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'h01);

        // ----------------------------------------------------
        // ③ Write: data = 0xAA
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'hAA);

        I2C_WRITE_BYTE(8'hBB);

        I2C_WRITE_BYTE(8'hCC);

        // Issue STOP
        @(posedge clk);
        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;
        #1000;

        // ----------------------------------------------------
        // ④ Restart + Read
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b1};  // read
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        I2C_WRITE_BYTE(8'h1);

        // read 1 byte, send NACK (stop)
        I2C_READ_BYTE();

        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;

        #2000;



        // ----------------------------------------------------
        // ① Write: Slave Address (Write)
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b0};  // addr + write(0)
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        // ----------------------------------------------------
        // ② Write: register pointer = 0x01
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'h01);

        // ----------------------------------------------------
        // ③ Write: data = 0xAA
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'hAA);

        // Issue STOP
        @(posedge clk);
        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;
        #1000;

        // ----------------------------------------------------
        // ④ Restart + Read
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b1};  // read
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        I2C_WRITE_BYTE(8'h1);

        // read 1 byte, send NACK (stop)
        I2C_READ_BYTE();

        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;

        #2000;



        // ----------------------------------------------------
        // ① Write: Slave Address (Write)
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b0};  // addr + write(0)
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        // ----------------------------------------------------
        // ② Write: register pointer = 0x02
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'h02);

        // ----------------------------------------------------
        // ③ Write: data = 0xBB
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'hBB);

        // Issue STOP
        @(posedge clk);
        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;
        #1000;

        // ----------------------------------------------------
        // ④ Restart + Read
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b1};  // read
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        I2C_WRITE_BYTE(8'h2);

        // read 1 byte, send NACK (stop)
        I2C_READ_BYTE();

        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;

        #2000;



        // ----------------------------------------------------
        // ① Write: Slave Address (Write)
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b0};  // addr + write(0)
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        // ----------------------------------------------------
        // ② Write: register pointer = 0x03
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'h03);

        // ----------------------------------------------------
        // ③ Write: data = 0xCC
        // ----------------------------------------------------
        I2C_WRITE_BYTE(8'hCC);

        // Issue STOP
        @(posedge clk);
        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;
        #1000;

        // ----------------------------------------------------
        // ④ Restart + Read
        // ----------------------------------------------------
        @(posedge clk);
        iI2C_Start = 1'b1;
        iTx_Data   = {7'h54, 1'b1};  // read
        @(posedge clk);
        iI2C_Start = 1'b0;

        wait (oTx_Ready);
        I2C_WRITE_BYTE(8'h3);

        // read 1 byte, send NACK (stop)
        I2C_READ_BYTE();

        iI2C_Stop = 1'b1;
        @(posedge clk);
        iI2C_Stop = 1'b0;

        #2000;
        $finish;
    end


endmodule
