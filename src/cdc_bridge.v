`default_nettype none

module cdc_bridge(
    // Fast domain, Cache controller side 
    input wire cpu_clk,
    input wire cpu_rst_n,
    input wire mem_req,
    input wire mem_we,
    input wire [13:0] mem_addr,
    input wire [31:0] mem_wdata,
    output wire [31:0] mem_rdata,
    output reg mem_done,
    
    // Slow domain, data memory (dm) side
    input wire dm_clk,
    input wire dm_rst_n,
    output wire dm_en,
    output wire dm_we,
    output wire [13:0] dm_addr,
    output wire [31:0] dm_wdata,
    input wire [31:0] dm_rdata
    );
    
    // Command FIFO - Fast to slow 
    wire cmd_wr_en, cmd_full;
    reg cmd_rd_en;
    wire cmd_empty;
    wire [46:0] cmd_rd_data;
    wire [46:0] cmd_wr_data = {mem_we, mem_addr, mem_wdata};
    
    async_fifo #(
        .DATA_WIDTH (47),
        .ADDR_WIDTH (3) 
    ) u_cmd_fifo (
        cpu_clk,
        cpu_rst_n,
        cmd_wr_en,
        cmd_wr_data,
        cmd_full,
        
        dm_clk,
        dm_rst_n,
        cmd_rd_en,
        cmd_rd_data,
        cmd_empty
    );
    
    // Response FIFO - slow to fast
    reg res_wr_en;
    wire res_full;
    wire res_rd_en, res_empty;
    reg [31:0] res_wr_data;
    wire [31:0] res_rd_data;
     
     async_fifo #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (3) 
    ) u_res_fifo (
        dm_clk,
        dm_rst_n,
        res_wr_en,
        res_wr_data,
        res_full,
        
        cpu_clk,
        cpu_rst_n,
        res_rd_en,
        res_rd_data,
        res_empty
    );
    
    // Fast side logic
    reg sent;
    
    assign cmd_wr_en = mem_req && !sent && !cmd_full;
    assign res_rd_en = !res_empty;
    assign mem_rdata = res_rd_data;
    
    always@(posedge cpu_clk or negedge cpu_rst_n) begin
        if(!cpu_rst_n) begin
            sent <= 1'b0;
            mem_done <= 1'd0;
        end
        else begin
            mem_done <= res_rd_en;
            if(mem_done) sent <= 1'b0;
            else if (cmd_wr_en) sent <= 1'b1;
        end 
    end
    // Slow side fsm
    localparam S_IDLE = 2'd0;
    localparam S_ISSUE = 2'd1;
    localparam S_RESP = 2'd2;
    
    reg [1:0] ps, ns;
    
    always@(posedge dm_clk or negedge dm_rst_n) begin
        if(!dm_rst_n) ps <= S_IDLE;
        else ps <= ns;
    end
    
    assign dm_en = (ps == S_ISSUE);
    assign dm_we = cmd_rd_data[46];
    assign dm_addr = cmd_rd_data[45:32];
    assign dm_wdata = cmd_rd_data[31:0];
    
    always@(*) begin
        ns = ps;
        cmd_rd_en = 1'b0;
        res_wr_en = 1'b0;
        res_wr_data = 32'd0;
        
        case(ps) 
            S_IDLE: begin
                if(!cmd_empty) begin
                    cmd_rd_en = 1'b1;
                    ns = S_ISSUE;
                end
            end
            
            S_ISSUE: begin
                ns = S_RESP;
            end

            S_RESP: begin
                if(!res_full) begin
                    res_wr_en   = 1'b1;
                    res_wr_data = dm_we ? 32'd0 : dm_rdata;
                    ns          = S_IDLE;
                end
            end

            default: ns = S_IDLE;
        endcase
    end
    
endmodule
