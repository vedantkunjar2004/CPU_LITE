`include "cpu_core_header.vh"
`default_nettype none
module psr_registers(
    input wire clk,
    input wire rst_n,

    input wire alu_z,
    input wire alu_n,
    input wire alu_c,
    input wire alu_v,
    
    input wire [3:0] flag,
    
    output reg psr_z,
    output reg psr_n,
    output reg psr_c,
    output reg psr_v
    );
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) {psr_z, psr_n, psr_c, psr_v} <= 4'd0;
        else begin 
            if(flag[0]) psr_z <= alu_z;
            if(flag[1]) psr_n <= alu_n;
            if(flag[2]) psr_c <= alu_c;
            if(flag[3]) psr_v <= alu_v;
        end
    end
endmodule
