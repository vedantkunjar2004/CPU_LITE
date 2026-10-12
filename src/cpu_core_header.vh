 `ifndef CPU_CORE_HEADER_VH
 `define CPU_CORE_HEADER_VH

// ALU parameters
`define ALU_ADD 4'd0
`define ALU_SUB 4'd1
`define ALU_MUL 4'd2
`define ALU_AND 4'd3
`define ALU_OR 4'd4
`define ALU_NOT 4'd5
`define ALU_EQ 4'd6
`define ALU_SHL 4'd7
`define ALU_SHR 4'd8
`define ALU_SAR 4'd9
`define ALU_PASS 4'd10
`define ALU_XOR 4'd11
`define ALU_ROL 4'd12
`define ALU_ROR 4'd13
`define ALU_SLT 4'd14
`define ALU_SLTU 4'd15

// IMM EXT parameters
`define EXT_ZERO 2'd0
`define EXT_SIGN 2'd1
`define EXT_LUI 2'd2

// Branch selector parameters
`define BR_BEQ 3'd0
`define BR_BNE 3'd1
`define BR_BLT 3'd2
`define BR_BGE 3'd3
`define BR_BLTU 3'd4
`define BR_BGEU 3'd5
`define BR_JMPIF 3'd6
`define BR_JMP 3'd7
 

// CPU controller states 
`define FETCH 3'd0
`define EXECUTE 3'd1
`define MEM_WAIT 3'd2
`define WRITE_BACK 3'd3
`define HALT 3'd4

// CPU controller opcode values 
`define OP_NOP 8'h00
 
`define OP_LOAD 8'h01
`define OP_LOAD_IND 8'h02
`define OP_LOAD_IMM 8'h03

`define OP_STORE 8'h04
`define OP_STORE_IND 8'h05

`define OP_ADD 8'h06
`define OP_SUB 8'h07
`define OP_MUL 8'h08
`define OP_AND 8'h09
`define OP_OR 8'h0A
`define OP_NOT 8'h0B

`define OP_CMP 8'h0C
`define OP_EQ 8'h0D

`define OP_JMP 8'h0E
`define OP_JMP_IF 8'h0F

`define OP_XOR 8'h10
`define OP_SHL 8'h11
`define OP_SHR 8'h12
`define OP_SAR 8'h13
`define OP_ROL 8'h14
`define OP_ROR 8'h15

`define OP_ADDI 8'h16
`define OP_SUBI 8'h17
`define OP_ANDI 8'h18
`define OP_ORI 8'h19
`define OP_XORI 8'h1A
`define OP_MOV 8'h1B
`define OP_SLT 8'h1C
`define OP_SLTU 8'h1D
`define OP_LUI 8'h1E

`define OP_BEQ 8'h20
`define OP_BNE 8'h21
`define OP_BLT 8'h22
`define OP_BGE 8'h23
`define OP_BLTU 8'h24
`define OP_BGEU 8'h25

`define OP_HALT 8'hFF

// Cache controller states
`define S_ACCESS 1'b0
`define S_MEM_WAIT 1'b1

`endif

