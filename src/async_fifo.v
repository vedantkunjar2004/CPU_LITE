
`default_nettype none
module async_fifo#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
    )(
    input wire wr_clk,
    input wire wr_rst_n,
    input wire wr_en,
    input wire [DATA_WIDTH-1:0] wr_data,
    output reg  full,
    
    input wire rd_clk,
    input wire rd_rst_n,
    input wire rd_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    output reg empty 
    );
    
    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    reg [ADDR_WIDTH:0] wptr_bin, wptr_gray;
    reg [ADDR_WIDTH:0] rptr_gray_sync1, rptr_gray_sync2;
    
    wire [ADDR_WIDTH:0] wptr_bin_next = wptr_bin + (wr_en && ~full);
    wire [ADDR_WIDTH:0] wptr_gray_next = (wptr_bin_next >> 1) ^ wptr_bin_next;
    wire full_next = (wptr_gray_next == {~(rptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1]),(rptr_gray_sync2[ADDR_WIDTH-2:0])});
    
    reg [ADDR_WIDTH:0] rptr_bin, rptr_gray;
    reg [ADDR_WIDTH:0] wptr_gray_sync1, wptr_gray_sync2;
    
    wire [ADDR_WIDTH:0] rptr_bin_next = rptr_bin + (rd_en && ~empty);
    wire [ADDR_WIDTH:0] rptr_gray_next = (rptr_bin_next >> 1) ^ rptr_bin_next;
    wire empty_next = (rptr_gray_next == wptr_gray_sync2);
    
    always@(posedge rd_clk or negedge rd_rst_n) begin
        if(!rd_rst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end
        else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end
    
    always@(posedge rd_clk or negedge rd_rst_n) begin
        if(!rd_rst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
            rd_data <= {DATA_WIDTH{1'b0}};
            empty <= 1'b1;
        end
        else begin
            if(rd_en && !empty) rd_data <= mem[rptr_bin[ADDR_WIDTH-1:0]];
            rptr_gray <= rptr_gray_next;
            rptr_bin <= rptr_bin_next;
            empty <= empty_next;
        end
    end
    
    
    always@(posedge wr_clk or negedge wr_rst_n) begin
        if(!wr_rst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end
        else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end
    
    always@(posedge wr_clk or negedge wr_rst_n) begin
        if(!wr_rst_n) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
            full <= 1'b0;
        end
        else begin
            wptr_bin <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
            full <= full_next;
        end
    end
    
    always@(posedge wr_clk) begin
        if(wr_en && !full) begin
            mem[wptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
        end
    end
    
endmodule
