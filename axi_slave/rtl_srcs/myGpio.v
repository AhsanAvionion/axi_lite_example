`timescale 1ns / 1ps



module myGpio #(
parameter integer S00_AXI_ADDR_WIDTH = 8,
parameter integer S00_AXI_DATA_WIDTH = 32
)(
    // AXI-Lite Slave Interface
    input wire S00_AXI_ACLK,
    input wire S00_AXI_ARESETN,
    input wire [S00_AXI_ADDR_WIDTH-1:0] S00_AXI_AWADDR,
    input wire S00_AXI_AWVALID,
    output wire S00_AXI_AWREADY,
    input wire [31:0] S00_AXI_WDATA,
    input wire [3:0] S00_AXI_WSTRB,
    input wire S00_AXI_WVALID,
    output wire S00_AXI_WREADY,
    output wire [1:0] S00_AXI_BRESP,
    output wire S00_AXI_BVALID,
    input wire S00_AXI_BREADY,
    input wire [S00_AXI_ADDR_WIDTH-1:0] S00_AXI_ARADDR,
    input wire S00_AXI_ARVALID,
    output wire S00_AXI_ARREADY,
    output wire [31:0] S00_AXI_RDATA,
    output wire [1:0] S00_AXI_RRESP,
    output wire S00_AXI_RVALID,
    input wire S00_AXI_RREADY,
    
    // User IOs
    output wire GPIO_OUTPUT,
    input wire GPIO_INPUT
    
);
    
    reg [31:0] GPIO_OUTPUT_pins;
    wire [31:0] GPIO_INPUT_pins;
    assign GPIO_OUTPUT = GPIO_OUTPUT_pins[0];
    assign GPIO_INPUT_pins[0] = GPIO_INPUT;
    
    
    reg [31:0] s00_axi_rdata;
    reg s00_axi_awready, s00_axi_wready, s00_axi_bvalid, s00_axi_arready, s00_axi_rvalid;
    reg [1:0] s00_axi_bresp, s00_axi_rresp;
    
    
    
    // Write address channel
    always @(posedge S00_AXI_ACLK or negedge S00_AXI_ARESETN) begin
        if (!S00_AXI_ARESETN) begin
            s00_axi_awready <= 1'b0;
        end else if (S00_AXI_AWVALID && !s00_axi_awready) begin
            s00_axi_awready <= 1'b1;
        end else begin
//            S00_AXI_AWADDR_reg <= S00_AXI_AWADDR;    //Store it if slave takes some processing time, maybe S00_AXI_AWADDR will be changed during slave processing. OR //no need to store address, it is always available until the data has been written
            s00_axi_awready <= 1'b0;
        end
    end
    

    reg [1:0] s00_axi_bresp_reg;

    // Write data channel
    always @(posedge S00_AXI_ACLK or negedge S00_AXI_ARESETN) begin
        if (!S00_AXI_ARESETN) begin
            s00_axi_wready <= 1'b0;
            GPIO_OUTPUT_pins <= 0;
            s00_axi_bresp_reg <= 2'b00; // 2'b00=OKAY, 2'b11=(DECERR): Decode error
        end else if (S00_AXI_WVALID && !s00_axi_wready) begin
            s00_axi_wready <= 1'b1;
            s00_axi_bresp_reg <= 2'b00; // 2'b00=OKAY, 2'b11=(DECERR): Decode error
        end else begin
            if(S00_AXI_WVALID && s00_axi_wready) begin
//                if (S00_AXI_WSTRB[0]) HI_6138_REGS[S00_AXI_AWADDR>>2][7:0] <= S00_AXI_WDATA[7:0];
//                if (S00_AXI_WSTRB[1]) HI_6138_REGS[S00_AXI_AWADDR>>2][15:8] <= S00_AXI_WDATA[15:8];
//                if (S00_AXI_WSTRB[2]) HI_6138_REGS[S00_AXI_AWADDR>>2][23:16] <= S00_AXI_WDATA[23:16];
//                if (S00_AXI_WSTRB[3]) HI_6138_REGS[S00_AXI_AWADDR>>2][31:24] <= S00_AXI_WDATA[31:24];

                if(S00_AXI_AWADDR == 8'h00) begin // 0x0000 is the address to write on external GPIO
                    GPIO_OUTPUT_pins <= S00_AXI_WDATA;
                end else begin
                    s00_axi_bresp_reg <= 2'b11; // 2'b00=OKAY, 2'b11=(DECERR): Decode error
                end
                s00_axi_wready <= 1'b0;
            end
        end
    end

    // Write response channel
    always @(posedge S00_AXI_ACLK or negedge S00_AXI_ARESETN) begin
        if (!S00_AXI_ARESETN) begin
            s00_axi_bvalid <= 1'b0;
            s00_axi_bresp <= 2'b00; // 2'b00=OKAY, 2'b11=(DECERR): Decode error
        end else if (s00_axi_awready && S00_AXI_AWVALID && s00_axi_wready && S00_AXI_WVALID && !s00_axi_bvalid) begin
            s00_axi_bvalid <= 1'b1;
            s00_axi_bresp <= s00_axi_bresp_reg; // 2'b00=OKAY, 2'b11=(DECERR): Decode error
            // s00_axi_bresp <= 2'b00; // OKAY response
        end else if (S00_AXI_BREADY && s00_axi_bvalid) begin
            s00_axi_bvalid <= 1'b0;
        end
    end


    
    // Read address channel
    always @(posedge S00_AXI_ACLK or negedge S00_AXI_ARESETN) begin
        if (!S00_AXI_ARESETN) begin
            s00_axi_arready <= 1'b0;
        end else if (S00_AXI_ARVALID && !s00_axi_arready) begin
            s00_axi_arready <= 1'b1;
            
        end else begin
//            S00_AXI_ARADDR_reg <= S00_AXI_ARADDR;    //Store it if slave takes some processing time, maybe S00_AXI_ARADDR will be changed during slave processing.
            s00_axi_arready <= 1'b0;
        end
    end
    
    localparam SM1_IDLE = 1;
    localparam SM1_PROC = 2;
    
    
    reg [3:0] SM1=0;
    // Read data channel
    always @(posedge S00_AXI_ACLK or negedge S00_AXI_ARESETN) begin
        if (!S00_AXI_ARESETN) begin
            SM1 <= SM1_IDLE;
            s00_axi_rvalid <= 1'b0;
            s00_axi_rresp <= 2'b00;
        end else begin
            case(SM1)
                SM1_IDLE: begin
                    if (s00_axi_arready && S00_AXI_ARVALID && !s00_axi_rvalid) begin
                        SM1 <= SM1_PROC;
                    end else if (S00_AXI_RREADY && s00_axi_rvalid) begin
                        s00_axi_rvalid <= 1'b0;
                    end
                end
                SM1_PROC: begin // user space
                    if(S00_AXI_ARADDR == 8'h04) begin // 0x0001 is the address to read external GPIO
                        s00_axi_rdata <= GPIO_INPUT_pins;
                        SM1 <= SM1_IDLE;
                        s00_axi_rvalid <= 1'b1;     // This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until s00_axi_rvalid is high
                        s00_axi_rresp <= 2'b00; // OKAY response
                    end else begin
                        s00_axi_rdata <= 0;
                        SM1 <= SM1_IDLE;
                        s00_axi_rvalid <= 1'b1;     // This function Xil_In32(XPAR_PCIE_1553_0_BASEADDR+XX) stucks until s00_axi_rvalid is high
                        s00_axi_rresp <= 2'b11; // 11=(DECERR): Decode error. This indicates that the address did not match any slave on the bus.
                    end
                end
                default: begin
                    SM1 <= SM1_IDLE;
                end
            endcase
        end            
    end
    

    // Assign outputs
    assign S00_AXI_AWREADY = s00_axi_awready;
    assign S00_AXI_WREADY = s00_axi_wready;
    assign S00_AXI_BRESP = s00_axi_bresp;
    assign S00_AXI_BVALID = s00_axi_bvalid;
    assign S00_AXI_ARREADY = s00_axi_arready;
    assign S00_AXI_RDATA = s00_axi_rdata;
    assign S00_AXI_RRESP = s00_axi_rresp;
    assign S00_AXI_RVALID = s00_axi_rvalid;
    
    
endmodule
