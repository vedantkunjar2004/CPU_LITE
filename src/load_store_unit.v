`include "cpu_core_header.vh"
`default_nettype none

module load_store_unit(
    input wire clk,
    input wire rst_n,
    
    input wire mem_read,  //this is LOAD/LOAD_IND
    input wire mem_write, // this is STORE/STORE_IND
    input wire addr_sel,  // 0 = direct addr field, 1 = register rs1 LSB 14 bit value  
    
    input wire [11:0] imm_addr, // instr[11:0]
    input wire [31:0] rs1_data, // base register value for indirect addressing
    input wire [31:0] store_data, // value to write, stored from Rd
    
    output wire cache_req, // request to L1 cache
    output wire cache_we,  // 1 = write, 0 = read
    output wire [13:0] cache_addr, // full 14 bit address
    output wire [31:0] cache_wdata, // for STORE/STORE_IND
    input wire [31:0] cache_rdata, //for LOAD/LOAD_IND
    input wire cache_ready,
    
    output reg [31:0] load_data, // captured read data, feeds the write back mux
    output wire mem_done // tells the controller that its safe to leave MEM_WAIT state
    );
    
    assign cache_req = mem_read | mem_write;
    assign cache_we = mem_write;
    assign cache_addr = addr_sel ? rs1_data[13:0] : {2'b00, imm_addr};
    assign cache_wdata = store_data;
    assign mem_done = cache_ready;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) load_data <= 32'd0;
        else if(cache_ready) load_data <= cache_rdata;
    end
endmodule
