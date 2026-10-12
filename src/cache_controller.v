`include "cpu_core_header.vh"
`default_nettype none

module cache_controller(
    input wire clk,
    input wire rst_n,
    
    // CPU facing
    input wire cache_req, // From the CPU core
    input wire cache_we, // 1 = write
    input wire [13:0] cache_addr,
    input wire [31:0] cache_wdata,
    output reg [31:0] cache_rdata,
    output reg cache_ready, // Pulses when response valid
    
    // Memory facing
    output reg mem_req,
    output wire mem_we,
    output wire [13:0] mem_addr,
    output wire [31:0] mem_wdata,
    input wire [31:0] mem_rdata,
    input wire mem_done // Pulses when memory response is valid
    );
    
    wire hit;
    reg dp_wr_en;
    wire [31:0] dp_wdata, dp_rdata;
    
    cache_datapath u_cache_datapath(
        clk,
        rst_n,
        cache_addr,
        dp_wr_en,
        dp_wdata,
        dp_rdata,
        hit
    );
    
    assign dp_wdata = cache_we ? cache_wdata : mem_rdata;
    assign mem_we = cache_we;
    assign mem_addr = cache_addr;
    assign mem_wdata = cache_wdata;

    reg ps,ns;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) ps <= `S_ACCESS;
        else ps <= ns; 
    end
    
    always@(*) begin
        ns = ps;
        dp_wr_en = 1'b0;
        cache_rdata = 32'd0;
        cache_ready = 1'b0;
        mem_req = 1'b0;
        
        case(ps) 
            `S_ACCESS: begin
                if(cache_req) begin
                    if(!cache_we && hit) begin   // If read-hit, then 
                        cache_rdata = dp_rdata;  // output cache_rdata is read from the datapath and 
                        cache_ready = 1'b1;      // cache is ready with its output in the same cycle
                    end
                    else begin                      // If read-miss or any write, then
                        mem_req = 1'b1;             // This means that the further process needs data memory access    
                        dp_wr_en = cache_we & hit;  // Asserts only on a write-hit. On clock edge stores cache_wdata 
                        ns = `S_MEM_WAIT;            
                    end
                end
            end
            
            `S_MEM_WAIT: begin
                mem_req = 1'b1;  // Stays high until the memory access is completed
                if(mem_done) begin
                    cache_ready = 1'b1;
                    if(!cache_we) begin // For read-miss, updates the cache_rdata with value of mem_rdata 
                        cache_rdata = mem_rdata; 
                        dp_wr_en = 1'b1; // The same mem_rdata should be updated inside the cache memory as well
                    end
                    ns = `S_ACCESS;
                end
            end
            
            default: ns = `S_ACCESS;
        endcase
    end
    
endmodule
