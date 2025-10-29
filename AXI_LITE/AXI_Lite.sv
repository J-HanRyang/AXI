`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company          : Semicon_Academi
// Engineer         : Jiyun_Han
// 
// Create Date	    : 2025/10/29
// Design Name      : AXI_LITE
// Module Name      : AXI_Lite
// Target Devices   : Basys3
// Tool Versions    : 2020.2
// Description      : AXI Lite Module
//
// Revision 	    : 
//////////////////////////////////////////////////////////////////////////////////

module AXI_Lite (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // Host Signals
    input  logic        transfer,
    output logic        ready,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        write,
    output logic [31:0] rdata
);

    /***********************************************
    // Reg & Wire
    ***********************************************/
    // Write Address
    logic [ 3:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    // Write Ddata
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    // Write Response
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    // Read Address
    logic [ 3:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    // Read Data
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;

    AXI_Lite_Master U_AXI_Lite_Master (.*);
    AXI_Lite_Slave U_AXI_Lite_Slave (.*);
endmodule
