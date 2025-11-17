`timescale 1 ns / 1 ps

module I2C_v2_0_S00_AXI #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    // --------------------------------------------------
    // -- I2C Master 포트 추가
    // --------------------------------------------------
    output wire       I2C_SCL,
    inout  wire       I2C_SDA,
    output wire [7:0] i2c_master_led_status,
    // --------------------------------------------------
    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input wire S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input wire S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- 4개의 슬레이브 레지스터 (AXI에 의해 R/W됨)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // 제어 (W)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  // TX 데이터 (W)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;  // RX 데이터 (R)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  // 상태 (R)
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    reg aw_en;

    // I/O Connections assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // --------------------------------------------------
    // -- User Logic Wire/Reg
    // --------------------------------------------------
    wire rst_sync;  // Active-high reset for I2C_Master

    // I2C Master <-> AXI Wires
    reg i2c_start;
    reg i2c_stop;
    reg i2c_write;
    reg i2c_read;

    wire i2c_tx_done;
    wire i2c_tx_ready;
    wire i2c_rx_done;
    wire [7:0] i2c_rx_data;

    // AXI Reset은 Active Low, I2C Master는 Active High
    assign rst_sync = ~S_AXI_ARESETN;


    // Implement axi_awready generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // Write Address latching 
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    // Implement axi_wready generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // AXI 레지스터 쓰기 및 유저 로직 업데이트
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;  // Read-Only RX Data Reg
            slv_reg3 <= 0;  // Read-Only Status Reg
        end else begin
            // AXI Write Logic
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    // slv_reg0 (Control): C 코드의 펄스 생성 로직을 따름 (Write)
                    2'h0:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    // slv_reg1 (TX Data): C 코드가 데이터를 미리 써 둠 (Write)
                    2'h1:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    // slv_reg2 (RX Data) - CPU Write 비활성화 (Read-Only)
                    // slv_reg3 (Status) - CPU Write 비활성화 (Read-Only)

                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                    end
                endcase
            end

            // --------------------------------------------------
            // -- User Logic: I2C Master 출력 -> AXI 레지스터 저장
            // --------------------------------------------------
            // 1. RX Data 저장 (slv_reg2)
            //    oRx_Done (i2c_rx_done) 펄스가 뜨면 oRx_Data (i2c_rx_data)를 저장
            if (i2c_rx_done) begin
                slv_reg2[7:0] <= i2c_rx_data;
            end

            // 2. 상태 레지스터 업데이트 (slv_reg3)
            //    C 코드가 실시간으로 폴링할 수 있도록 항상 상태를 반영
            slv_reg3 <= {29'b0, i2c_rx_done, i2c_tx_ready, i2c_tx_done};
            // --------------------------------------------------
        end
    end

    // --------------------------------------------------
    // -- User Logic: AXI 제어 -> I2C Master 입력 (펄스 생성)
    // --------------------------------------------------
    // slv_reg0에 쓰기 이벤트(slv_reg_wren)가 발생하면,
    // S_AXI_WDATA의 비트를 1클럭 펄스로 변환하여 I2C Master FSM에 전달
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            i2c_start <= 1'b0;
            i2c_stop  <= 1'b0;
            i2c_write <= 1'b0;
            i2c_read  <= 1'b0;
        end else begin
            // 기본값은 0
            i2c_start <= 1'b0;
            i2c_stop  <= 1'b0;
            i2c_write <= 1'b0;
            i2c_read  <= 1'b0;

            // slv_reg0 (주소 0x00)에 쓰기 이벤트가 발생했을 때
            if (slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0))
            begin
                i2c_start <= S_AXI_WDATA[0];  // [0]: START
                i2c_stop  <= S_AXI_WDATA[1];  // [1]: STOP
                i2c_write <= S_AXI_WDATA[2];  // [2]: WRITE
                i2c_read  <= S_AXI_WDATA[3];  // [3]: READ
            end
        end
    end
    // --------------------------------------------------

    // Implement write response logic generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;  // 'OKAY' response 
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Implement axi_arready generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Implement axi_arvalid generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  // 'OKAY' response
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // AXI 레지스터 읽기 로직
    // (이 로직은 slv_reg2와 slv_reg3가 위에서
    //  User Logic에 의해 업데이트되므로 수정할 필요 없음)
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*) begin
        // Address decoding for reading registers
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0:
            reg_data_out <= slv_reg0; // 제어 레지스터 읽기 (디버그용)
            2'h1:
            reg_data_out <= slv_reg1; // TX 데이터 레지스터 읽기 (디버그용)
            2'h2: reg_data_out <= slv_reg2;  // RX 데이터 읽기
            2'h3: reg_data_out <= slv_reg3;  // 상태 읽기
            default: reg_data_out <= 0;
        endcase
    end

    // Output register or memory read data
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;
            end
        end
    end

    // Add user logic here
    // --------------------------------------------------
    // -- I2C Master 인스턴스화
    // --------------------------------------------------
    I2C_Master #(
        // S_AXI_ACLK이 100MHz라고 가정합니다.
        // 다를 경우 이 파라미터를 수정해야 합니다.
        .CLK_FREQ(100_000_000),
        .I2C_FREQ(100_000)
    ) i2c_master_inst (
        .iClk(S_AXI_ACLK),
        .iRst(rst_sync),    // Active-high reset

        // Control (AXI 펄스 입력)
        .iI2C_Start(i2c_start),
        .iI2C_Stop (i2c_stop),
        .iI2C_Write(i2c_write),
        .iI2C_Read (i2c_read),

        // TX Data (slv_reg1에서 직접 연결)
        .iTx_Data(slv_reg1[7:0]),

        // Status (AXI 레지스터로 출력)
        .oTx_Done (i2c_tx_done),
        .oTx_Ready(i2c_tx_ready),

        // RX Data (AXI 레지스터로 출력)
        .oRx_Data(i2c_rx_data),
        .oRx_Done(i2c_rx_done),

        // I2C Bus (외부 핀으로 연결)
        .oSCL (I2C_SCL),
        .ioSDA(I2C_SDA),
        .oLed (i2c_master_led_status)
    );
    // --------------------------------------------------
    // User logic ends

endmodule
