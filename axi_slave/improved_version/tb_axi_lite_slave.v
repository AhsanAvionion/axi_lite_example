`timescale 1ns / 1ps



module tb_axi_lite_slave;

  // Clock and Reset
  reg clk = 0;
  reg resetn = 0;

  // AXI Lite signals
  reg [31:0] s_axi_awaddr;
  reg s_axi_awvalid;
  wire S_AXI_AWREADY;

  reg [31:0] s_axi_wdata;
  reg [3:0] s_axi_wstrb;
  reg s_axi_wvalid;
  wire S_AXI_WREADY;

  wire [1:0] s_axi_bresp;
  wire S_AXI_BVALID;
  reg s_axi_bready;

  reg [31:0] s_axi_araddr;
  reg s_axi_arvalid;
  wire S_AXI_ARREADY;

  wire [31:0] s_axi_rdata;
  wire [1:0] s_axi_rresp;
  wire S_AXI_RVALID;
  reg s_axi_rready;

    reg [31:0] read_data;
    
    //debug
    wire [3:0] SM1_debug;
    
  // Instantiate your AXI-Lite Slave DUT
//  axi_lite_slave_vhdl dut (
  axi_lite_slave_verilog dut (
    .S00_AXI_ACLK(clk),
    .S00_AXI_ARESETN(resetn),
    .S00_AXI_AWADDR(s_axi_awaddr),
    .S00_AXI_AWVALID(s_axi_awvalid),
    .S00_AXI_AWREADY(S_AXI_AWREADY),
    .S00_AXI_WDATA(s_axi_wdata),
    .S00_AXI_WSTRB(s_axi_wstrb),
    .S00_AXI_WVALID(s_axi_wvalid),
    .S00_AXI_WREADY(S_AXI_WREADY),
    .S00_AXI_BRESP(s_axi_bresp),
    .S00_AXI_BVALID(S_AXI_BVALID),
    .S00_AXI_BREADY(s_axi_bready),
    .S00_AXI_ARADDR(s_axi_araddr),
    .S00_AXI_ARVALID(s_axi_arvalid),
    .S00_AXI_ARREADY(S_AXI_ARREADY),
    .S00_AXI_RDATA(s_axi_rdata),
    .S00_AXI_RRESP(s_axi_rresp),
    .S00_AXI_RVALID(S_AXI_RVALID),
    .S00_AXI_RREADY(s_axi_rready)
//    .SM1_debug(SM1_debug)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Write Task
  task axi_write1(input [31:0] addr, input [31:0] data);
  begin
    @(posedge clk);
    s_axi_awaddr <= addr;
    s_axi_awvalid <= 1;
    wait (S_AXI_AWREADY);
    @(posedge clk);
    s_axi_awvalid <= 0;
    @(posedge clk);
    s_axi_wdata <= data;
    s_axi_wstrb <= 4'hF;
    s_axi_wvalid <= 1;
    wait (S_AXI_WREADY);
    @(posedge clk);
    s_axi_wvalid <= 0;
    @(posedge clk);
    s_axi_awvalid <= 0;
    s_axi_wvalid <= 0;
    s_axi_bready <= 1;
    wait (S_AXI_BVALID);
    @(posedge clk);
    s_axi_bready <= 0;
    @(posedge clk);
    s_axi_bready <= 0;
  end
  endtask


  task axi_write(input [31:0] addr, input [31:0] data);
  begin
    @(posedge clk);
    s_axi_awaddr <= addr;
    s_axi_awvalid <= 1;
    s_axi_wdata <= data;
    s_axi_wstrb <= 4'hF;
    s_axi_wvalid <= 1;
    s_axi_bready <= 1;
    wait (S_AXI_BVALID);
    @(posedge clk);
    s_axi_bready <= 0;
    s_axi_awvalid <= 0;
    s_axi_wvalid <= 0;
  end
  
  
  endtask
  // Read Task
  task axi_read1(input [31:0] addr, output [31:0] data);
  begin
    @(posedge clk);
    s_axi_araddr <= addr;
    s_axi_arvalid <= 1;
    wait (S_AXI_ARREADY);
    @(posedge clk);
    s_axi_arvalid <= 0;
    @(posedge clk);
    s_axi_arvalid <= 0;
    s_axi_rready <= 1;
    wait (S_AXI_RVALID);
    @(posedge clk);
    s_axi_rready <= 0;
    data = s_axi_rdata;
    @(posedge clk);
    s_axi_rready <= 0;
  end
  endtask
  task axi_read(input [31:0] addr, output [31:0] data);
  begin
    @(posedge clk);
    s_axi_araddr <= addr;
    s_axi_arvalid <= 1;
    s_axi_rready <= 1;
    wait (S_AXI_RVALID);
    @(posedge clk);
    data = s_axi_rdata;
    s_axi_rready <= 0;
    s_axi_arvalid <= 0;
  end
  endtask

  // Main test
  initial begin
    // Init
    s_axi_awaddr = 0;
    s_axi_awvalid = 0;
    s_axi_wdata = 0;
    s_axi_wstrb = 0;
    s_axi_wvalid = 0;
    s_axi_bready = 0;
    s_axi_araddr = 0;
    s_axi_arvalid = 0;
    s_axi_rready = 0;

    resetn = 0;
    repeat (5) @(posedge clk);
    resetn = 1;

    // Perform write to address 0x10 with data 0xDEADBEEF
    axi_write(32'h00, 32'hDEADBEEF);
    axi_write(32'h00, 32'hDEADBEEF);
    
    axi_write1(32'h00, 32'hDEADBEEF);
    axi_write1(32'h00, 32'hDEADBEEF);

     //Perform read from address 0x10
    axi_write(32'h04, 32'hABCDABCD);
    axi_read(32'h04, read_data);
    axi_write(32'h04, 32'hBCDABCDA);
    axi_read(32'h04, read_data);
    
    axi_write1(32'h04, 32'hABCDABCD);
    axi_read1(32'h04, read_data);
    axi_write1(32'h04, 32'hBCDABCDA);
    axi_read1(32'h04, read_data);
    
     //Perform read from address 0x10
    axi_read(32'h04, read_data);
    axi_read(32'h284, read_data);
    
    axi_read1(32'h04, read_data);
    axi_read1(32'h284, read_data);

//    $display("Read data: 0x%08X", read_data);

    // Check result
//    if (read_data === 32'hDEADBEEF)
//      $display("Test PASSED");
//    else
//      $display("Test FAILED");

    $finish;
  end

endmodule
