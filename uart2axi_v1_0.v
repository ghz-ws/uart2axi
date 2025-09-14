module uart2axi_v1_0 #(
    parameter integer C_M00_AXI_ADDR_WIDTH=32,
    parameter integer C_M00_AXI_DATA_WIDTH=32,
    parameter integer div_ratio=868
    )(
    input uart_rx,
    output uart_tx,
    input wire  m00_axi_aclk,
    input wire  m00_axi_aresetn,
    output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
    output wire [2 : 0] m00_axi_awprot,
    output wire  m00_axi_awvalid,
    input wire  m00_axi_awready,
    output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
    output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
    output wire  m00_axi_wvalid,
    input wire  m00_axi_wready,
    input wire [1 : 0] m00_axi_bresp,
    input wire  m00_axi_bvalid,
    output wire  m00_axi_bready,
    output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
    output wire [2 : 0] m00_axi_arprot,
    output wire  m00_axi_arvalid,
    input wire  m00_axi_arready,
    input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
    input wire [1 : 0] m00_axi_rresp,
    input wire  m00_axi_rvalid,
    output wire  m00_axi_rready
    );
    wire [31:0]addr,rdata,wdata;
	wire rw,rvalid,busy,txn;
	uart2axi_v1_0_M00_AXI # ( 
        .C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
    ) uart2axi_v1_0_M00_AXI_inst (
        .INIT_AXI_TXN(txn),
        .ERROR(),
        .TXN_DONE(),
        .M_AXI_ACLK(m00_axi_aclk),
        .M_AXI_ARESETN(m00_axi_aresetn),
        .M_AXI_AWADDR(m00_axi_awaddr),
        .M_AXI_AWPROT(m00_axi_awprot),
        .M_AXI_AWVALID(m00_axi_awvalid),
        .M_AXI_AWREADY(m00_axi_awready),
        .M_AXI_WDATA(m00_axi_wdata),
        .M_AXI_WSTRB(m00_axi_wstrb),
        .M_AXI_WVALID(m00_axi_wvalid),
        .M_AXI_WREADY(m00_axi_wready),
        .M_AXI_BRESP(m00_axi_bresp),
        .M_AXI_BVALID(m00_axi_bvalid),
        .M_AXI_BREADY(m00_axi_bready),
        .M_AXI_ARADDR(m00_axi_araddr),
        .M_AXI_ARPROT(m00_axi_arprot),
        .M_AXI_ARVALID(m00_axi_arvalid),
        .M_AXI_ARREADY(m00_axi_arready),
        .M_AXI_RDATA(m00_axi_rdata),
        .M_AXI_RRESP(m00_axi_rresp),
        .M_AXI_RVALID(m00_axi_rvalid),
        .M_AXI_RREADY(m00_axi_rready),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .rw(rw),
        .rvalid(rvalid),
        .busy(busy)
    );
    uart2axi_sm #(.div_ratio(div_ratio))uart2axi_sm(
	   .clk(m00_axi_aclk),
	   .rst(!m00_axi_aresetn),
	   .rx_line(uart_rx),
	   .axi_busy(busy),
	   .rvalid(rvalid),
	   .tx_line(uart_tx),
	   .txn(txn),
	   .rw(rw),
	   .addr(addr),
	   .wdata(wdata),
	   .rdata(rdata)
    );
endmodule
