`include "cpu_core_header.vh"
`default_nettype none

module cpu_core_top(
    input wire clk, 
    input wire rst_n,
    
    input wire [31:0] instr_data, // from program memory
    output wire [11:0] instr_addr,  // to program memory (current pc value)
    
    output wire cache_req, // to L1 cache
    output wire cache_we,
    output wire [13:0] cache_addr,
    output wire [31:0] cache_wdata,
    input wire [31:0] cache_rdata,
    input wire cache_ready
    );
    
    // FETCH stage 
    wire [7:0] opcode;
    wire [3:0] rd, rs1, rs2;
    wire [11:0] imm;
    
    // Control Signals throughout the CPU core
    wire ir_write, pc_write;
    wire [3:0] alu_op;
    wire [1:0] alu_b_sel;
    wire [1:0] ext_sel;
    wire [3:0] flag;
    wire [2:0] branch_sel;
    wire mem_read, mem_write, addr_sel;
    wire register_we, raddr1_sel, raddr2_sel, wb_sel;
    wire branch_en;
    
    // Register file read address routing
    wire [3:0] raddr1 = raddr1_sel ? rs2 : rs1; // Normally Rs1 field; But while STORE_IND reroutes to Rs2
    wire [3:0] raddr2 = raddr2_sel ? rd : rs2; // Normally Rs2 field; But while STORE/STORE_IND reroutes to Rd
    wire [31:0] rdata1, rdata2;
    
    // Datapath signals
    wire [31:0] imm32;
    wire [31:0] alu_b = (alu_b_sel == 2'd0) ? rdata2 : ((alu_b_sel == 2'd1) ? imm32 : rdata1);
    wire [31:0] alu_result;
    wire alu_z, alu_n, alu_c, alu_v;
    
    wire psr_z, psr_n, psr_c, psr_v;
    wire branch_taken;
    
    wire [31:0] load_data;
    wire mem_done;
    
    wire [31:0] wdata = wb_sel ? load_data : alu_result;
    
    wire [11:0] pc;
    assign instr_addr = pc;
    
    // CPU controller instantiation
    cpu_controller u_controller(
        .clk (clk),
        .rst_n (rst_n),
        .opcode (opcode),
        .mem_done (mem_done),
        .ir_write (ir_write),
        .pc_write (pc_write),
        .alu_op (alu_op),
        .alu_b_sel (alu_b_sel),
        .ext_sel (ext_sel),
        .flag (flag),
        .branch_sel (branch_sel),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .addr_sel (addr_sel),
        .register_we (register_we),
        .raddr1_sel (raddr1_sel),
        .raddr2_sel (raddr2_sel),
        .wb_sel (wb_sel),
        .branch_en (branch_en)
    ); 
    
    // Instruction register/decoder instantiation
    instr_decoder u_instr_decoder(
        clk,
        rst_n,
        ir_write,
        instr_data,
        opcode,
        rd,
        rs1,
        rs2,
        imm
    );
    
    // Register file instantiation
    register_file u_reg_file(
        clk,
        rst_n,
        raddr1,
        raddr2,
        rdata1,
        rdata2,
        rd,
        wdata,
        register_we
    );
    
    // Immediate extension instantiation
    imm_extension u_imm_ext(
        imm,
        ext_sel,
        imm32
    );
    
    // ALU instantiation
    alu u_alu(
        rdata1,
        alu_b,
        alu_op,
        alu_result,
        alu_z,
        alu_n,
        alu_c,
        alu_v
    );
    
    // PSR registers instantiation
    psr_registers u_psr_reg(
        clk,
        rst_n,
        alu_z,
        alu_n,
        alu_c,
        alu_v,
        flag,
        psr_z,
        psr_n,
        psr_c,
        psr_v   
    );
    
    // Branching conditions instantiation
    branch_condition u_branch_cond(
        psr_z,
        psr_n,
        psr_c,
        psr_v,
        rdata1,
        branch_sel,
        branch_taken
    );
    
    
    // Program counter instantiation
    pc_unit u_pc_unit(
        clk,
        rst_n,
        pc_write,
        branch_en,
        branch_taken,
        imm,
        pc
    );
    
    // LOAD/STORE unit instantiation
    load_store_unit u_lsu(
        clk,
        rst_n,
        mem_read,
        mem_write,
        addr_sel,
        imm,
        rdata1,
        rdata2,
        cache_req,
        cache_we,
        cache_addr,
        cache_wdata,
        cache_rdata,
        cache_ready,
        load_data,
        mem_done
    );
    
endmodule
