
module axi_lite_slave_verilog #(
parameter integer S00_AXI_ADDR_WIDTH = 12,
parameter integer S00_AXI_DATA_WIDTH = 32
)(
    // AXI-Lite Slave Interface   
    
  input wire  S00_AXI_ACLK,
  input wire  S00_AXI_ARESETN,
  input wire [S00_AXI_ADDR_WIDTH-1 : 0] S00_AXI_AWADDR,
  input wire [2:0] S00_AXI_AWPROT,
  input wire  S00_AXI_AWVALID,
  output wire  S00_AXI_AWREADY, 
  input wire [S00_AXI_DATA_WIDTH-1:0] S00_AXI_WDATA,  
  input wire [3:0] S00_AXI_WSTRB,
  input wire  S00_AXI_WVALID,
  output wire  S00_AXI_WREADY,
  output wire [1:0] S00_AXI_BRESP,
  output wire  S00_AXI_BVALID,
  input wire  S00_AXI_BREADY,
  input wire [S00_AXI_ADDR_WIDTH-1 : 0] S00_AXI_ARADDR,
  input wire [2:0] S00_AXI_ARPROT,
  input wire  S00_AXI_ARVALID,
  output wire  S00_AXI_ARREADY,
  output wire [S00_AXI_DATA_WIDTH-1:0] S00_AXI_RDATA,
  output wire [1:0] S00_AXI_RRESP,
  output wire  S00_AXI_RVALID,
  input wire  S00_AXI_RREADY
      
);


    // AXI4LITE signals
    reg [S00_AXI_ADDR_WIDTH-1 : 0] 	s00_axi_awaddr_reg;
    reg  	s00_axi_awready_reg;
    reg  	s00_axi_wready_reg;
    reg [1:0] 	s00_axi_bresp_reg;
    reg  	s00_axi_bvalid_reg;
    reg [S00_AXI_ADDR_WIDTH-1 : 0] 	s00_axi_araddr_reg;
    reg  	s00_axi_arready_reg;
    reg [S00_AXI_DATA_WIDTH-1:0] 	s00_axi_rdata_reg;
    reg [1 : 0] 	s00_axi_rresp_reg;
    reg  	s00_axi_rvalid_reg;
    
    localparam CONN_TEST1_MMAP              = 12'h000;
    localparam CONN_TEST2_MMAP              = 12'h004;
    
    reg [S00_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [S00_AXI_DATA_WIDTH-1:0] slv_reg1;

    reg s00_axi_awaddr_pending;
    always @( posedge S00_AXI_ACLK ) begin
        if ( S00_AXI_ARESETN == 1'b0 ) begin
            s00_axi_awready_reg <= 1'b0;
            s00_axi_awaddr_pending <= 1'b0;
        end else begin
            if (~s00_axi_awready_reg && S00_AXI_AWVALID && ~s00_axi_awaddr_pending) begin
                // slave is ready to accept write address when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                s00_axi_awready_reg <= 1'b1;
                s00_axi_awaddr_pending <= 1;
            end else if (S00_AXI_BREADY && s00_axi_bvalid_reg) begin
                s00_axi_awaddr_pending <= 0;
                s00_axi_awready_reg <= 1'b0;
            end
            else begin
                s00_axi_awready_reg <= 1'b0;
            end
        end
    end       
    
    // Implement axi_awaddr latching
    // This process is used to latch the address when both 
    // S_AXI_AWVALID and S_AXI_WVALID are valid. 
    
    reg s00_axi_wdata_pending;
    reg s00_axi_wdata_done;
    always @( posedge S00_AXI_ACLK ) begin
        if ( S00_AXI_ARESETN == 1'b0 ) begin
            s00_axi_awaddr_reg <= 0;
            s00_axi_wdata_pending <= 0;
        end else begin
            if (s00_axi_awready_reg && S00_AXI_AWVALID && s00_axi_awaddr_pending) begin
                // Write Address latching 
                s00_axi_awaddr_reg <= S00_AXI_AWADDR;
                s00_axi_wdata_pending <= 1;
            end else begin
                if(s00_axi_wdata_done) begin
                    s00_axi_wdata_pending <= 0;
                end
            end
        end 
    end       
    

    reg s00_axi_bresp_pending;
    reg s00_axi_bresp_done;
    reg [3:0] gen_timer_saxi_wr;
    always @( posedge S00_AXI_ACLK ) begin
        if ( S00_AXI_ARESETN == 1'b0 ) begin
            s00_axi_wdata_done <= 0;
            s00_axi_wready_reg <= 0;
            gen_timer_saxi_wr <= 0;
            slv_reg0 <= 32'hdeadbeef;
            slv_reg1 <= 32'hbeeffeed;
            s00_axi_bresp_pending <= 0;
        end else begin
            if (s00_axi_wdata_pending && ~s00_axi_wready_reg && S00_AXI_WVALID) begin
                
                case (s00_axi_awaddr_reg)
                    CONN_TEST1_MMAP: begin
                        slv_reg0 <= S00_AXI_WDATA;
                        s00_axi_wready_reg <= 1;
                        s00_axi_wdata_done <= 1;
                        s00_axi_bresp_pending <= 1;
                    end
                    CONN_TEST2_MMAP: begin
                        if(gen_timer_saxi_wr==0) begin
                            gen_timer_saxi_wr <= 1;
                        end else if(gen_timer_saxi_wr==1) begin
                            gen_timer_saxi_wr <= 2;
                        end else if(gen_timer_saxi_wr==2) begin
                            gen_timer_saxi_wr <= 3;
                        end else if(gen_timer_saxi_wr==3) begin
                            gen_timer_saxi_wr <= 0;
                            slv_reg1 <= S00_AXI_WDATA;
                            s00_axi_wready_reg <= 1;
                            s00_axi_wdata_done <= 1;
                            s00_axi_bresp_pending <= 1;
                        end
                    end
                    default: begin // avoid any hang on axi_master side
                        s00_axi_wready_reg <= 1;
                        s00_axi_wdata_done <= 1;
                        s00_axi_bresp_pending <= 1;
                    end
                endcase
            end else begin
                if(s00_axi_wready_reg && s00_axi_wdata_done) begin
                    s00_axi_wready_reg <= 0;
                    s00_axi_wdata_done <= 0;
                end
                if(s00_axi_bresp_done) begin
                    s00_axi_bresp_pending <= 0;
                end
            end
        end
    end    
        
    always @( posedge S00_AXI_ACLK ) begin
        if ( S00_AXI_ARESETN == 1'b0 ) begin
            s00_axi_bvalid_reg  <= 0;
            s00_axi_bresp_reg   <= 2'b00;
            s00_axi_bresp_done <= 0;
        end else begin
            if (S00_AXI_BREADY && ~s00_axi_bvalid_reg) begin
                if(s00_axi_bresp_pending) begin
                    // indicates a valid write response is available
                    s00_axi_bvalid_reg <= 1'b1;
                    s00_axi_bresp_reg  <= 2'b00; // 'OKAY' response
                    s00_axi_bresp_done <= 1;
                end
            end else begin                  // work error responses in future
                if (S00_AXI_BREADY && s00_axi_bvalid_reg) begin
                  //check if bready is asserted while bvalid is high) 
                  //(there is a possibility that bready is always asserted high)
                    s00_axi_bvalid_reg <= 1'b0;
                end
                s00_axi_bresp_done <= 0;
            end
        end
    end
    
    reg s00_axi_rdata_pending;
    reg s00_axi_rdata_done;
    always @( posedge S00_AXI_ACLK ) begin
        if ( S00_AXI_ARESETN == 1'b0) begin
            s00_axi_arready_reg <= 1'b0;
            s00_axi_araddr_reg  <= 32'b0;
            s00_axi_rdata_pending <= 0;
        end else begin
            if (~s00_axi_arready_reg && S00_AXI_ARVALID) begin
                // indicates that the slave has acceped the valid read address
                s00_axi_arready_reg <= 1'b1;
                // Read address latching
                s00_axi_araddr_reg  <= S00_AXI_ARADDR;
                s00_axi_rdata_pending <= 1;
            end else begin
                s00_axi_arready_reg <= 1'b0;
                if(s00_axi_rdata_done) begin
                    s00_axi_rdata_pending <= 0;
                end
            end
        end 
    end
    
    
    localparam SM_AXIRD_IDLE = 1;
    localparam SM_AXIRD_PROC = 2;    
    reg [2:0] SM_AXIRD_state=SM_AXIRD_IDLE;
    reg [3:0] gen_timer_saxi_rd;


    always @( posedge S00_AXI_ACLK ) begin
        if ( S00_AXI_ARESETN == 1'b0) begin
            s00_axi_rvalid_reg <= 0;
            s00_axi_rresp_reg  <= 0;
            s00_axi_rdata_reg <= 0;
            SM_AXIRD_state <= SM_AXIRD_IDLE;
            s00_axi_rdata_done <= 0;
            
            gen_timer_saxi_rd <= 0;
            
        end else if(SM_AXIRD_state==SM_AXIRD_IDLE) begin
            if (s00_axi_rdata_pending) begin
                SM_AXIRD_state <= SM_AXIRD_PROC;
            end
            s00_axi_rvalid_reg <= 0;
        end else if(SM_AXIRD_state==SM_AXIRD_PROC) begin
            if (S00_AXI_RREADY && ~s00_axi_rvalid_reg) begin
                // Valid read data is available at the read data bus
                case (s00_axi_araddr_reg)
                    CONN_TEST1_MMAP: begin
                        s00_axi_rdata_reg <= slv_reg0;
                        s00_axi_rvalid_reg <= 1'b1;     // This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until s00_axi_rvalid is high
                        s00_axi_rresp_reg <= 2'b00; // OKAY response
                        s00_axi_rdata_done <= 1;
                    end
                    CONN_TEST2_MMAP: begin
                        if(gen_timer_saxi_rd==0) begin
                            gen_timer_saxi_rd <= 1;
                        end else if(gen_timer_saxi_rd==1) begin
                            gen_timer_saxi_rd <= 2;
                        end else if(gen_timer_saxi_rd==2) begin
                            gen_timer_saxi_rd <= 3;
                        end else if(gen_timer_saxi_rd==3) begin
                            gen_timer_saxi_rd <= 4;
                            s00_axi_rdata_reg[15:0] <= slv_reg1[15:0];
                        end else if(gen_timer_saxi_rd==4) begin
                            gen_timer_saxi_rd <= 0;
                            s00_axi_rdata_reg[31:16] <= slv_reg1[31:16];
                            s00_axi_rvalid_reg <= 1'b1;     // This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until s00_axi_rvalid is high
                            s00_axi_rresp_reg <= 2'b00; // OKAY response
                            s00_axi_rdata_done <= 1;
                        end
                    end
                    default: begin // to avoid CPU to hang when trying to access unavailable MMAP Address
                        s00_axi_rdata_reg <= 0;
                        s00_axi_rvalid_reg <= 1'b1;     // This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until s00_axi_rvalid is high
                        s00_axi_rresp_reg <= 2'b00; // OKAY response
                        s00_axi_rdata_done <= 1;
                    end
                endcase
            end else begin
                // Read data is accepted by the master
                s00_axi_rdata_reg <= 0;
                s00_axi_rvalid_reg <= 1'b0;
                SM_AXIRD_state <= SM_AXIRD_IDLE;
                s00_axi_rdata_done <= 1'b0;
            end 
        end
    end    
    

    // Assign outputs
    assign S00_AXI_AWREADY = s00_axi_awready_reg;
    assign S00_AXI_WREADY = s00_axi_wready_reg;
    assign S00_AXI_BRESP = s00_axi_bresp_reg;
    assign S00_AXI_BVALID = s00_axi_bvalid_reg;
    assign S00_AXI_ARREADY = s00_axi_arready_reg;
    assign S00_AXI_RDATA = s00_axi_rdata_reg;
    assign S00_AXI_RRESP = s00_axi_rresp_reg;
    assign S00_AXI_RVALID = s00_axi_rvalid_reg;
    
//    assign S00_AXI_ARADDR_DEBUG = S00_AXI_ARADDR;
endmodule
