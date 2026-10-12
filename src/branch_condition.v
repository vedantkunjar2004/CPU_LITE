`include "cpu_core_header.vh"  
`default_nettype none          

module branch_condition(
    input wire psr_z, // latched psr flags 
    input wire psr_n,
    input wire psr_c,
    input wire psr_v,
    
    input wire [31:0] rs1_data, // rs1's register value
    input wire [2:0] branch_sel, // condition type - decoded by the controller 
    
    output reg branch_taken // Forwarded to the PC unit 
    );
    
    always@(*) begin
        case(branch_sel)
            `BR_BEQ: branch_taken = psr_z; 
            `BR_BNE: branch_taken = ~psr_z;
            `BR_BLT: branch_taken = psr_n ^ psr_v;
            `BR_BGE: branch_taken = ~(psr_n ^ psr_v);
            `BR_BLTU: branch_taken = ~psr_c;
            `BR_BGEU: branch_taken = psr_c;
            `BR_JMPIF: branch_taken = (rs1_data != 32'd0);
            `BR_JMP: branch_taken = 1'b1;
            default: branch_taken = 1'b0;
        endcase
    end
endmodule
