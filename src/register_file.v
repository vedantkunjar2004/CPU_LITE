`include "cpu_core_header.vh"
`default_nettype none
module register_file(
    input  wire        clk,
    input  wire        rst_n, // asynchronous active low reset 
    
    input  wire [3:0]  raddr1, // read address port 1
    input  wire [3:0]  raddr2, // read address port 2
    output wire [31:0] rdata1,
    output wire [31:0] rdata2,
    
    input  wire [3:0]  waddr, // write address 
    input  wire [31:0] wdata, // write data
    input  wire        we // write enable
    );
    
    // Register storage
    reg [31:0]mem[0:15];
    
    // Asynchronous read ports - Combinational 
    // So that the DECODE stage sees the value in the same cycle its requested
    assign rdata1 = mem[raddr1]; 
    assign rdata2 = mem[raddr2];
    
    // Synchronous write port 
    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            for(i = 0; i < 16; i = i + 1) begin
                mem[i] <= 32'd0; // resets all 16 registers
            end
        end
        else if(we) begin
            mem[waddr] <= wdata;
        end
    end
endmodule
