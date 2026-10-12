`include "cpu_core_header.vh"
`default_nettype none

module instr_decoder(
    input  wire clk,
    input  wire rst_n, 
    
    input  wire instr_write, // asserted by controller during FETCH
    input  wire [31:0] instr, // 32 bit instruction
    
    output wire [7:0] opcode, 
    output wire [3:0] rd,
    output wire [3:0] rs1,
    output wire [3:0] rs2,
    output wire [11:0] imm // feeds imm extension and direct address paths
    );
    
    reg [31:0] instr_reg;
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) instr_reg <= 32'd0;
        else if (instr_write) instr_reg  <= instr;
    end
    
    assign opcode = instr_reg[31:24];
    assign rd     = instr_reg[23:20];
    assign rs1    = instr_reg[19:16];
    assign rs2    = instr_reg[15:12];
    assign imm    = instr_reg[11:0];
    
endmodule
