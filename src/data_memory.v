`default_nettype none

module data_memory(
    input wire clk,
    input wire en,
    input wire we,
    input wire [13:0] addr,
    input wire [31:0] wdata,
    output reg [31:0] rdata
    );
    
    reg [31:0] mem [0:16383];
    
    integer i;
    initial begin
        for(i = 0; i < 16384; i = i + 1)
            mem[i] = 32'd0;
        rdata = 32'd0;
    end
    
    always@(posedge clk) begin
        if(en) begin
            if(we) mem[addr] <= wdata;
            else rdata <= mem[addr];
        end  
    end
endmodule
