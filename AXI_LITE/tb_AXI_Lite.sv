`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/10/29
// Design Name      : AXI_LITE
// Module Name      : tb_AXI_Lite
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : AXI Lite Testbench
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module tb_AXI4_Lite ();
    // Global Signals
    logic        ACLK;
    logic        ARESETn;

    // internal signals
    logic        transfer;
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    AXI_Lite U_Dut (.*);

    /***********************************************
    // Clock define
    **********************************************/
    initial ACLK = 1'b0;
    always #5 ACLK = ~ACLK;  // 100MHz clock


    /****************************************************
    // Intialization & function start !!!!!!!!!!!!!!!!!!!
    ****************************************************/
    initial begin
        // 1. Reset DUT
        reset_dut();
        
        // 2. Wait a bit
        repeat(5) @(posedge ACLK);
        
        
        // 3. --- Test Sequence Start ---
        $display("\n[%0t] === Test 1: Write/Read slv_reg1 (0x0) ===", $time);
        host_write(32'h0000_0000, 32'hDEADBEEF); // Write to slv_reg1
        repeat(5) @(posedge ACLK);
        host_read(32'h0000_0000, 32'hDEADBEEF);  // Read from slv_reg1
        
        
        $display("\n[%0t] === Test 2: Write/Read slv_reg3 (0x8) ===", $time);
        host_write(32'h0000_0008, 32'hCAFEF00D); // Write to slv_reg3
        repeat(5) @(posedge ACLK);
        host_read(32'h0000_0008, 32'hCAFEF00D);  // Read from slv_reg3
        
        
        $display("\n[%0t] === Test 3: Write/Read slv_reg2 (0x4) & slv_reg4 (0xC) ===", $time);
        host_write(32'h0000_0004, 32'h12345678); // Write to slv_reg2
        repeat(5) @(posedge ACLK);
        host_write(32'h0000_000C, 32'h87654321); // Write to slv_reg4
        repeat(5) @(posedge ACLK);
        host_read(32'h0000_0004, 32'h12345678);  // Read from slv_reg2
        repeat(5) @(posedge ACLK);
        host_read(32'h0000_000C, 32'h87654321);  // Read from slv_reg4
        
        
        $display("\n[%0t] === Test 4: Overwrite slv_reg1 (0x0) ===", $time);
        host_write(32'h0000_0000, 32'hFFFFFFFF); // Overwrite slv_reg1
        repeat(5) @(posedge ACLK);
        host_read(32'h0000_0000, 32'hFFFFFFFF);  // Read from slv_reg1
        
        
        // 4. --- Finish Simulation ---
        $display("\n[%0t] All test sequences finished.", $time);
        repeat(10) @(posedge ACLK);
        $finish;
    end


    /***********************************************
    // Tasks for Host Transaction
    ***********************************************/
    // DUT Reset Task
    task reset_dut();
        $display("[Applying Reset...");
        ARESETn <= 1'b0;
        transfer <= 1'b0;
        write    <= 1'b0;
        addr     <= 32'b0;
        wdata    <= 32'b0;
        ARESETn <= 1'b1;
        $display("Reset Released.");
        @(posedge ACLK);
    endtask

    // 호스트 쓰기 Task
    task host_write(input [31:0] i_addr, input [31:0] i_wdata);
        $display("Host WRITE: Addr=0x%h, Data=0x%h", i_addr, i_wdata);
        @(posedge ACLK);
        
        // 1. Request
        transfer <= 1'b1;
        write    <= 1'b1;
        addr     <= i_addr;
        wdata    <= i_wdata;
        
        // 2. Wait for completion (Master가 'ready' 신호를 줄 때까지 대기)
        @(posedge ready);
        
        // 3. De-assert signals
        @(posedge ACLK);
        transfer <= 1'b0;
        write    <= 1'b0;
        $display("Host WRITE: Complete.");
    endtask

    // 호스트 읽기 Task (데이터 검증 포함)
    task host_read(input [31:0] i_addr, input [31:0] exp_rdata);
        logic [31:0] local_rdata;
        
        $display("Host READ: Addr=0x%h", i_addr);
        @(posedge ACLK);
        
        // 1. Request
        transfer <= 1'b1;
        write    <= 1'b0; // Read operation
        addr     <= i_addr;
        
        // 2. Wait for completion
        @(posedge ready);
        
        // 3. Sample data (ready와 rdata가 같은 사이클에 유효해짐)
        local_rdata = rdata;
        
        // 4. De-assert signals
        @(posedge ACLK);
        transfer <= 1'b0;
        
        $display("Host READ: Complete. Got Data=0x%h", local_rdata);
        
        // 5. Check data
        if (local_rdata == exp_rdata) begin
            $display("  ==> \033[0;32mPASS: Read data 0x%h matches expected 0x%h\033[0m", local_rdata, exp_rdata);
        end else begin
            $display("  ==> \033[0;31mFAIL: Read data 0x%h, Expected 0x%h\033[0m", local_rdata, exp_rdata);
        end
    endtask
endmodule
