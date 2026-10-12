`default_nettype none

module cache_datapath(
    input wire clk, 
    input wire rst_n,
    input wire [13:0] addr,
    input wire wr_en,
    input wire [31:0] wdata,
    output wire [31:0] rdata,
    output wire hit
    );
    
    wire [7:0] set_index = addr[7:0];
    wire [5:0] tag = addr[13:8];
    
    reg [5:0] tag_ram [0:255];
    reg valid_bits [0:255];
    reg [31:0] data_ram [0:255];
    
    assign hit = valid_bits [set_index] && (tag_ram [set_index] == tag);
    assign rdata = data_ram [set_index];
    
    integer i;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i = 0; i < 256; i = i + 1) 
                valid_bits[i] <= 1'b0;
        end
        else if(wr_en) begin
            valid_bits [set_index] <= 1'b1; 
        end
    end
    
    always@(posedge clk) begin
        if(wr_en) begin
            tag_ram [set_index] <= tag;
            data_ram [set_index] <= wdata;
        end
    end
    
endmodule
