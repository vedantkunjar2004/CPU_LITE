// Includes memory modules
`default_nettype none

module cpu_lite_top(
    input wire cpu_clk,   // 150MHz
    input wire cpu_rst_n,
    input wire dm_clk,    // 70MHz
    input wire dm_rst_n
    );
    
    // Program memory link
    wire [11:0] instr_addr;
    wire [31:0] instr_data;
    
    // CPU <-> Cache
    wire cache_req, cache_we;
    wire [13:0] cache_addr;
    wire [31:0] cache_wdata, cache_rdata;
    wire cache_ready;
    
    // Cache <-> Bridge (fast)
    wire mem_req, mem_we;
    wire [13:0] mem_addr;
    wire [31:0] mem_wdata, mem_rdata;
    wire mem_done;
    
    // Bridge <-> Data memory (slow)
    wire dm_en, dm_we;
    wire [13:0] dm_addr;
    wire [31:0] dm_wdata, dm_rdata;
    
    
    cpu_core_top u_cpu(
        cpu_clk,
        cpu_rst_n,
        instr_data,
        instr_addr,
        cache_req,
        cache_we,
        cache_addr,
        cache_wdata,
        cache_rdata,
        cache_ready    
    );
    
    program_memory u_pmem(
        instr_addr,
        instr_data
    );
    
    cache_controller u_cache(
        cpu_clk,
        cpu_rst_n,
        cache_req,
        cache_we,
        cache_addr,
        cache_wdata,
        cache_rdata,
        cache_ready,
        mem_req,
        mem_we,
        mem_addr,
        mem_wdata,
        mem_rdata,
        mem_done
    );
    
    cdc_bridge u_cdc(
        cpu_clk,
        cpu_rst_n,
        mem_req,
        mem_we,
        mem_addr,
        mem_wdata,
        mem_rdata,
        mem_done,
        dm_clk,
        dm_rst_n,
        dm_en,
        dm_we,
        dm_addr,
        dm_wdata,
        dm_rdata
    );
    
    data_memory u_dmem(
        dm_clk,
        dm_en,
        dm_we,
        dm_addr,
        dm_wdata,
        dm_rdata
    );
endmodule




//--------- The memory-free version-----
//`default_nettype none

//module cpu_lite_top(
//    input wire cpu_clk,   // 150MHz
//    input wire cpu_rst_n,
//    input wire dm_clk,    // 70MHz
//    input wire dm_rst_n,
    
//    // Program memory interface (black-box IP, fast domain)
//    output wire [11:0] instr_addr,  // To program memory
//    input  wire [31:0] instr_data,  // From program memory
    
//    // Data memory interface (black-box IP, slow domain)
//    output wire        dm_en,       // To data memory
//    output wire        dm_we,       // To data memory
//    output wire [13:0] dm_addr,     // To data memory
//    output wire [31:0] dm_wdata,    // To data memory
//    input  wire [31:0] dm_rdata     // From data memory
//    );
    
//    // CPU <-> Cache
//    wire cache_req, cache_we;
//    wire [13:0] cache_addr;
//    wire [31:0] cache_wdata, cache_rdata;
//    wire cache_ready;
    
//    // Cache <-> Bridge (fast)
//    wire mem_req, mem_we;
//    wire [13:0] mem_addr;
//    wire [31:0] mem_wdata, mem_rdata;
//    wire mem_done;
    
    
//    cpu_core_top u_cpu(
//        cpu_clk,
//        cpu_rst_n,
//        instr_data,
//        instr_addr,
//        cache_req,
//        cache_we,
//        cache_addr,
//        cache_wdata,
//        cache_rdata,
//        cache_ready    
//    );
    
//    cache_controller u_cache(
//        cpu_clk,
//        cpu_rst_n,
//        cache_req,
//        cache_we,
//        cache_addr,
//        cache_wdata,
//        cache_rdata,
//        cache_ready,
//        mem_req,
//        mem_we,
//        mem_addr,
//        mem_wdata,
//        mem_rdata,
//        mem_done
//    );
    
//    cdc_bridge u_cdc(
//        cpu_clk,
//        cpu_rst_n,
//        mem_req,
//        mem_we,
//        mem_addr,
//        mem_wdata,
//        mem_rdata,
//        mem_done,
//        dm_clk,
//        dm_rst_n,
//        dm_en,
//        dm_we,
//        dm_addr,
//        dm_wdata,
//        dm_rdata
//    );
    
//endmodule


