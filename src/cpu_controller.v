`include "cpu_core_header.vh"
`default_nettype none

module cpu_controller(
    input wire clk,
    input wire rst_n,
    
    input wire [7:0] opcode,
    input wire mem_done, // from the LSU
    
    output reg ir_write, // write enable signal for instr
    output reg pc_write, // write enable for PC unit
    output reg [3:0] alu_op,
    output reg [1:0] alu_b_sel, // 00=rs2_data, 01=imm32, 10=rs1_data(MOV only)
    output reg [1:0] ext_sel, // immediate extension selector
    output reg [3:0] flag, // PSR enable signals
    output reg [2:0] branch_sel, 
    output reg mem_read, // LOAD/LOAD_IND
    output reg mem_write, // STORE/STORE_IND
    output reg addr_sel, // to the LSU, 0=Direct, 1=register
    output reg register_we, // register file write enable
    output reg raddr1_sel, // 0=Rs1 field, 1=Rs2_field(STORE_IND only)
    output reg raddr2_sel, // 0=Rs2 field, 1=Rd field(STORE/STORE_IND)
    output reg wb_sel, // write back mux, 0=ALU result, 1=load_data 
    output reg branch_en // 1 = branch/jump opcode, gates branch_taken into PC
    );
    
    function automatic is_mem_op(input [7:0] op);
        is_mem_op = (op == `OP_LOAD) || (op == `OP_LOAD_IND) || (op == `OP_STORE) || (op == `OP_STORE_IND);
    endfunction 
    
    function automatic is_load (input [7:0] op);
        is_load = (op == `OP_LOAD) || (op == `OP_LOAD_IND);
    endfunction
    
    function automatic has_result (input [7:0] op);
        has_result = !((op == `OP_CMP) || (op == `OP_STORE) || (op == `OP_STORE_IND) || (op == `OP_NOP) ||
                        (op == `OP_HALT) || (op == `OP_JMP) || (op == `OP_JMP_IF) || (op == `OP_BEQ) || 
                        (op == `OP_BNE) || (op == `OP_BLT) || (op == `OP_BGE) || (op == `OP_BLTU) || 
                        (op == `OP_BGEU) || is_mem_op(op));
    endfunction
    
    reg [2:0] ps;
    reg [2:0] ns;
    
    reg [3:0] flag_mask;
    
    // Decode logic 
    always@(*) begin
        alu_op = `ALU_ADD;
        alu_b_sel = 2'd0;
        ext_sel = `EXT_ZERO;
        branch_sel = `BR_BEQ;
        branch_en = 1'b0;
        addr_sel = 1'b0;
        raddr1_sel = 1'b0;
        raddr2_sel = 1'b0;
        wb_sel = is_load(opcode);
        flag_mask = 4'b0000;
        
        case(opcode) 
            `OP_ADD: begin alu_op = `ALU_ADD; flag_mask = 4'b1111; end
            `OP_ADDI: begin alu_op = `ALU_ADD; alu_b_sel = 2'b01; ext_sel = `EXT_SIGN; flag_mask = 4'b1111; end
            `OP_SUB: begin alu_op = `ALU_SUB; flag_mask = 4'b1111; end
            `OP_SUBI: begin alu_op = `ALU_SUB; alu_b_sel = 2'b01; ext_sel = `EXT_SIGN; flag_mask = 4'b1111; end
            `OP_CMP: begin alu_op = `ALU_SUB; flag_mask = 4'b1111; end
            `OP_MUL: begin alu_op = `ALU_MUL; flag_mask = 4'b0011; end
            `OP_AND: begin alu_op = `ALU_AND; flag_mask = 4'b0011; end
            `OP_ANDI: begin alu_op = `ALU_AND; alu_b_sel = 2'b01; flag_mask = 4'b0011; end
            `OP_OR: begin alu_op = `ALU_OR; flag_mask = 4'b0011; end
            `OP_ORI: begin alu_op = `ALU_OR; alu_b_sel = 2'b01; flag_mask = 4'b0011; end
            `OP_XOR: begin alu_op = `ALU_XOR; flag_mask = 4'b0011; end
            `OP_XORI: begin alu_op = `ALU_XOR; alu_b_sel = 2'd1; flag_mask = 4'b0011; end
            `OP_SHL: begin alu_op = `ALU_SHL; flag_mask = 4'b0011; end
            `OP_SHR: begin alu_op = `ALU_SHR; flag_mask = 4'b0011; end
            `OP_SAR: begin alu_op = `ALU_SAR; flag_mask = 4'b0011; end
            `OP_ROL: begin alu_op = `ALU_ROL; flag_mask = 4'b0011; end
            `OP_ROR: begin alu_op = `ALU_ROR; flag_mask = 4'b0011; end
            `OP_NOT: begin alu_op = `ALU_NOT; flag_mask = 4'b0011; end
            `OP_MOV: begin alu_op = `ALU_PASS; alu_b_sel = 2'b10;  end
            `OP_STORE:  begin raddr2_sel = 1'b1; end
            `OP_STORE_IND: begin addr_sel = 1'b1; raddr1_sel = 1'b1; raddr2_sel = 1'b1; end
            `OP_LOAD_IND: begin addr_sel = 1'b1; end
            `OP_BEQ: begin branch_sel = `BR_BEQ; branch_en = 1'b1; end 
            `OP_BNE: begin branch_sel = `BR_BNE; branch_en = 1'b1; end
            `OP_BLT: begin branch_sel = `BR_BLT; branch_en = 1'b1; end
            `OP_BGE: begin branch_sel = `BR_BGE; branch_en = 1'b1; end
            `OP_BLTU: begin branch_sel = `BR_BLTU; branch_en = 1'b1; end
            `OP_BGEU: begin branch_sel = `BR_BGEU; branch_en = 1'b1; end
            `OP_JMP: begin branch_sel = `BR_JMP; branch_en = 1'b1; end
            `OP_JMP_IF: begin branch_sel = `BR_JMPIF; branch_en = 1'b1; end
            `OP_LOAD_IMM: begin alu_op = `ALU_PASS; alu_b_sel = 2'd1; end
            `OP_LUI: begin alu_op = `ALU_PASS; alu_b_sel = 2'd1; ext_sel = `EXT_LUI; end
            `OP_EQ: begin alu_op = `ALU_EQ; flag_mask = 4'b0001; end
            `OP_SLT: begin alu_op = `ALU_SLT; flag_mask = 4'b0001; end
            `OP_SLTU: begin alu_op = `ALU_SLTU; flag_mask = 4'b0001; end
            default: flag_mask = 4'b0000;
        endcase
    end
    
    // Present state logic 
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) ps <= `FETCH;
        else ps <= ns;
    end
    
//    // Output logic (depends only on ps/opcode, NOT on mem_done)
//    always@(*) begin
//        ir_write = 1'b0; pc_write = 1'b0; register_we = 1'b0;
//        mem_read = 1'b0; mem_write = 1'b0; flag = 4'b0000;
//        case(ps)
//            `FETCH:      ir_write = 1'b1;
//            `EXECUTE:    begin pc_write = 1'b1; flag = flag_mask; end
//            `MEM_WAIT:   begin mem_read = is_load(opcode); mem_write = !is_load(opcode); end
//            `WRITE_BACK: register_we = 1'b1;
//            default:     flag = 4'b0000;
//        endcase
//    end
    
//    // Next-state logic (the only block that reads mem_done)
//    always@(*) begin
//        ns = ps;
//        case(ps)
//            `FETCH: ns = `EXECUTE;
//            `EXECUTE: begin
//                if(opcode == `OP_HALT)         ns = `HALT;
//                else if(is_mem_op(opcode))     ns = `MEM_WAIT;
//                else if(has_result(opcode))    ns = `WRITE_BACK;
//                else                           ns = `FETCH;
//            end
//            `MEM_WAIT:   if(mem_done) ns = is_load(opcode) ? `WRITE_BACK : `FETCH;
//            `WRITE_BACK: ns = `FETCH;
//            `HALT:       ns = `HALT;
//            default:     ns = `FETCH;
//        endcase
//    end 
    
    // Next state logic 
    always@(*) begin
        ns = ps;
        ir_write = 1'b0;
        pc_write = 1'b0;
        register_we = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        flag = 4'b0000;
        
        case(ps) 
            `FETCH: begin 
                ir_write = 1'b1;
                ns =`EXECUTE; 
            end 
            
            `EXECUTE: begin
                pc_write = 1'b1;
                flag = flag_mask;
                
                if(opcode == `OP_HALT) ns = `HALT;
                else if(is_mem_op(opcode)) ns = `MEM_WAIT;
                else if(has_result(opcode)) ns = `WRITE_BACK;
                else ns = `FETCH; 
            end
            
            `MEM_WAIT: begin
                mem_read = is_load(opcode); 
                mem_write = !is_load(opcode);
                
                if(mem_done) ns = is_load(opcode) ? `WRITE_BACK : `FETCH;
            end
            
            `WRITE_BACK: begin
                register_we = 1'b1;
                ns = `FETCH;
            end
            
            `HALT: ns = `HALT;
            
            default: ns = `FETCH;
        endcase
    end
endmodule


















