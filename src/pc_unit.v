`include "cpu_core_header.vh"
`default_nettype none
module pc_unit(
    input wire clk,
    input wire rst_n,
    
    input wire pc_write, // Asserted once per instruction
    input wire branch_en, // 1 = current instruction is a branch/jump
    input wire branch_taken, // Tells whether to increment pc or go to sleceted target
    
    input wire [11:0] imm_addr,
    
    output reg [11:0] pc
    );
    
    // Branch only takes effect when the instruction is actually a branch/jump
    wire [11:0] pc_next = (branch_en && branch_taken) ? imm_addr : (pc + 1'b1);
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) pc <= 12'd0;
        else if(pc_write) pc <= pc_next;
    end
endmodule
