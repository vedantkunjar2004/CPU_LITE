`include "cpu_core_header.vh"
`default_nettype none
module imm_extension(
    input  wire [11:0]  imm, // 12 bit immediate value
    input  wire [1:0]   ext_sel, // 2 bit extension mode select, given by controller
    output reg  [31:0]  imm32 // 32 bit extended immediate value
    );
    
    always@(*) begin
        case(ext_sel) 
            `EXT_ZERO: imm32 = {20'd0, imm}; // Zero extend
            `EXT_SIGN: imm32 = {{20{imm[11]}},imm}; // Sign extend
            `EXT_LUI: imm32 = {imm, 20'd0}; // Zero extend in LSB for LUI
            default: imm32 = 32'd0;
        endcase
    end 
endmodule
