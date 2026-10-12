`include "cpu_core_header.vh"
`default_nettype none
module alu(
    input wire [31:0] a, //operand a
    input wire [31:0] b, //operand b
    input wire [3:0] alu_op, // operation - not the direct 8 bit opcode value. 
    // The opcode is decoded by the controller
    // Then it generates a 4 bit alu_opcode

    output reg [31:0] result,
    output wire alu_z,
    output wire alu_n,
    output reg alu_c,
    output reg alu_v
    );
    
    wire [32:0] add_res; // addition result which includes carry out
    wire [32:0] sub_res; // subtraction result which includes borrow out
    
    assign add_res = {1'b0, a} + {1'b0, b};
    assign sub_res = {1'b0, a} - {1'b0, b}; 
    
    assign alu_z = (result == 32'd0); // The zero flag checks if result=0
    assign alu_n = result[31]; // Checks the MSB bit for polarity of result
    
    always@(*) begin
    result = 32'd0;
    alu_c = 1'b0;
    alu_v = 1'b0;
        case(alu_op) 
            // Addition
            `ALU_ADD: begin
                result = add_res[31:0];
                alu_c = add_res[32];
                alu_v = (a[31] == b[31]) && (a[31] != result[31]);
            end
            
            // Subtraction (also used by CMP)
            `ALU_SUB: begin
                result = sub_res[31:0];
                alu_c = ~sub_res[32]; // C=1 means No borrow
                alu_v = (a[31] != b[31]) && (a[31] != result[31]);
            end
            
            // Multiplication with only 32 bit result. Remaining bits ignored
            `ALU_MUL: result = a * b;
                  
            // Bitwise AND
            `ALU_AND: result = a & b;
            
            // Bitwise OR
            `ALU_OR: result = a | b;
            
            // Bitwise NOT
            `ALU_NOT: result = ~a;
            
            // Equality compare
            `ALU_EQ: result = (a == b) ? 32'd1 : 32'd0;
            
            // Logical Shift left
            `ALU_SHL: result = a << b[4:0]; 
            
            // Logical Shift right
            `ALU_SHR: result = a >> b[4:0];
            
            // Arithmetic Shift right
            `ALU_SAR: result = $signed(a) >>> b[4:0];
            
            // Pass through (Pass operand b into result)
            `ALU_PASS: result = b;
            
            // Bitwise XOR
            `ALU_XOR: result = a ^ b;
            
            // Rotate left
            `ALU_ROL: result = (a << b[4:0]) | (a >> (32 - b[4:0]));
            
            // Rotate right
            `ALU_ROR: result = (a >> b[4:0]) | (a << (32 - b[4:0]));
            
            // Set less than for signed numbers
            `ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            
            // Set less than for unsigned numbers
            `ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            
            default: result = 32'd0;
        endcase
    end
endmodule
