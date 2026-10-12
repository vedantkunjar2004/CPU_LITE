`timescale 1ns/1ps
// ============================================================================
// tb_cpu_lite_top : instruction-flow trace testbench for CPU Lite (V2)
//
//  * The program is read from program.mem by program_memory.v (nothing is
//    re-encoded here).  Data memory is pre-loaded with DATA[0x100+i] = i+1.
//  * After EVERY instruction completes (write-back done, or the last state of
//    instructions that have no write-back) one result block is printed:
//        ALU ops     -> operands, ALU result, register written, flags
//        CMP         -> ALU result (not written), flags
//        branch/JMP  -> flags used, taken / not taken, next PC
//        LOAD        -> address, cache hit/miss, data memory content, register
//        STORE       -> address, cache write hit/miss, data memory content
//  * The same text goes to the simulator log AND to  cpu_lite_flow.log
//    (written in the simulator's run directory).
//  * Only the DUT-connected signals are visible at the top of the waveform;
//    every helper variable lives in a named block (tb_cpu_lite_top.trace ...).
//
//  Needs program.mem in the simulator run directory (Vivado: add it as a
//  simulation source or copy it to <proj>.sim/sim_1/behav/xsim/).
// ============================================================================

// ---------------- user settings ----------------
`define TB_LOG_FILE      "cpu_lite_flow.log"
`define TB_MAX_NS        200000        // watchdog (simulated ns)
`define TB_CHECK_RESULT                // comment out if you change the program
`define TB_RESULT_ADDR   14'h200       // spec example stores the sum here
`define TB_RESULT_VALUE  32'd55
// ------------------------------------------------

`define TB_CPU_HALF 3.333              // 150 MHz
`define TB_DM_HALF  7.143              //  70 MHz

`define TB_ST_FETCH   3'd0
`define TB_ST_EXECUTE 3'd1
`define TB_ST_MEMWAIT 3'd2
`define TB_ST_WB      3'd3
`define TB_ST_HALT    3'd4

`define TB_C_OTHER 4'd0
`define TB_C_ALU2  4'd1                // Rd = A op B
`define TB_C_NOT   4'd2                // Rd = ~A
`define TB_C_PASS  4'd3                // Rd = B (LOAD_IMM, LUI, MOV)
`define TB_C_CMP   4'd4                // flags only
`define TB_C_BR    4'd5                // branches and jumps
`define TB_C_LOAD  4'd6
`define TB_C_STORE 4'd7
`define TB_C_NOP   4'd8
`define TB_C_HALT  4'd9

module tb_cpu_lite_top;

    // ------------------------------------------------------------------
    // Only these four signals + the DUT appear at the top of the waveform
    // ------------------------------------------------------------------
    reg cpu_clk;
    reg dm_clk;
    reg cpu_rst_n;
    reg dm_rst_n;

    initial begin
        cpu_clk   = 1'b0;
        dm_clk    = 1'b0;
        cpu_rst_n = 1'b0;
        dm_rst_n  = 1'b0;
    end

    always #(`TB_CPU_HALF) cpu_clk = ~cpu_clk;

    initial begin                       // offset: the two clocks are unrelated
        #2.7;
        forever #(`TB_DM_HALF) dm_clk = ~dm_clk;
    end

    initial begin
        repeat (4) @(negedge cpu_clk);
        cpu_rst_n = 1'b1;
    end
    initial begin
        repeat (3) @(negedge dm_clk);
        dm_rst_n = 1'b1;
    end

    cpu_lite_top dut (
        .cpu_clk   (cpu_clk),
        .cpu_rst_n (cpu_rst_n),
        .dm_clk    (dm_clk),
        .dm_rst_n  (dm_rst_n)
    );

    // ------------------------------------------------------------------
    // Helpers (functions / tasks keep their variables out of the waveform)
    // ------------------------------------------------------------------

    // print to simulator log and to the log file
    task emit;
        input [8*256-1:0] s;
        integer fd;
        reg     opened;
        begin
            if (opened !== 1'b1) begin
                fd     = $fopen(`TB_LOG_FILE, "w");
                opened = 1'b1;
            end
            $display("%0s", s);
            $fdisplay(fd, "%0s", s);
            $fflush(fd);
        end
    endtask

    function [3:0] cls;
        input [7:0] op;
        begin
            case (op)
                8'h06, 8'h07, 8'h08, 8'h09, 8'h0A, 8'h0D, 8'h10, 8'h11, 8'h12,
                8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18, 8'h19, 8'h1A, 8'h1C,
                8'h1D:                                   cls = `TB_C_ALU2;
                8'h0B:                                   cls = `TB_C_NOT;
                8'h03, 8'h1B, 8'h1E:                     cls = `TB_C_PASS;
                8'h0C:                                   cls = `TB_C_CMP;
                8'h0E, 8'h0F, 8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25:
                                                         cls = `TB_C_BR;
                8'h01, 8'h02:                            cls = `TB_C_LOAD;
                8'h04, 8'h05:                            cls = `TB_C_STORE;
                8'h00:                                   cls = `TB_C_NOP;
                8'hFF:                                   cls = `TB_C_HALT;
                default:                                 cls = `TB_C_OTHER;
            endcase
        end
    endfunction

    function [8*10-1:0] mnem;
        input [7:0] op;
        begin
            case (op)
                8'h00: mnem = "NOP";       8'h01: mnem = "LOAD";
                8'h02: mnem = "LOAD_IND";  8'h03: mnem = "LOAD_IMM";
                8'h04: mnem = "STORE";     8'h05: mnem = "STORE_IND";
                8'h06: mnem = "ADD";       8'h07: mnem = "SUB";
                8'h08: mnem = "MUL";       8'h09: mnem = "AND";
                8'h0A: mnem = "OR";        8'h0B: mnem = "NOT";
                8'h0C: mnem = "CMP";       8'h0D: mnem = "EQ";
                8'h0E: mnem = "JMP";       8'h0F: mnem = "JMP_IF";
                8'h10: mnem = "XOR";       8'h11: mnem = "SHL";
                8'h12: mnem = "SHR";       8'h13: mnem = "SAR";
                8'h14: mnem = "ROL";       8'h15: mnem = "ROR";
                8'h16: mnem = "ADDI";      8'h17: mnem = "SUBI";
                8'h18: mnem = "ANDI";      8'h19: mnem = "ORI";
                8'h1A: mnem = "XORI";      8'h1B: mnem = "MOV";
                8'h1C: mnem = "SLT";       8'h1D: mnem = "SLTU";
                8'h1E: mnem = "LUI";       8'h20: mnem = "BEQ";
                8'h21: mnem = "BNE";       8'h22: mnem = "BLT";
                8'h23: mnem = "BGE";       8'h24: mnem = "BLTU";
                8'h25: mnem = "BGEU";      8'hFF: mnem = "HALT";
                default: mnem = "???";
            endcase
        end
    endfunction

    function [8*4-1:0] op_sym;
        input [7:0] op;
        begin
            case (op)
                8'h06, 8'h16: op_sym = "+";
                8'h07, 8'h17: op_sym = "-";
                8'h08:        op_sym = "*";
                8'h09, 8'h18: op_sym = "&";
                8'h0A, 8'h19: op_sym = "|";
                8'h10, 8'h1A: op_sym = "^";
                8'h0D:        op_sym = "==";
                8'h11:        op_sym = "<<";
                8'h12:        op_sym = ">>";
                8'h13:        op_sym = ">>>";
                8'h14:        op_sym = "rol";
                8'h15:        op_sym = "ror";
                8'h1C:        op_sym = "<s";
                8'h1D:        op_sym = "<u";
                default:      op_sym = "?";
            endcase
        end
    endfunction

    // 32-bit instruction word -> assembly text
    function [8*40-1:0] disasm;
        input [31:0] w;
        reg [7:0]       op;
        reg [3:0]       d, s1, s2;
        reg [11:0]      im;
        reg [8*40-1:0]  t;
        begin
            op = w[31:24];  d = w[23:20];  s1 = w[19:16];  s2 = w[15:12];  im = w[11:0];
            case (cls(op))
                `TB_C_ALU2: begin
                    if (op >= 8'h16 && op <= 8'h1A)
                        $sformat(t, "%0s R%0d, R%0d, #0x%03h", mnem(op), d, s1, im);
                    else
                        $sformat(t, "%0s R%0d, R%0d, R%0d", mnem(op), d, s1, s2);
                end
                `TB_C_NOT:  $sformat(t, "NOT R%0d, R%0d", d, s1);
                `TB_C_PASS: begin
                    if (op == 8'h1B) $sformat(t, "MOV R%0d, R%0d", d, s1);
                    else             $sformat(t, "%0s R%0d, #0x%03h", mnem(op), d, im);
                end
                `TB_C_CMP:  $sformat(t, "CMP R%0d, R%0d", s1, s2);
                `TB_C_BR: begin
                    if (op == 8'h0F) $sformat(t, "JMP_IF R%0d, -> PC %0d", s1, im);
                    else             $sformat(t, "%0s -> PC %0d", mnem(op), im);
                end
                `TB_C_LOAD: begin
                    if (op == 8'h01) $sformat(t, "LOAD R%0d, [0x%03h]", d, im);
                    else             $sformat(t, "LOAD_IND R%0d, [R%0d]", d, s1);
                end
                `TB_C_STORE: begin
                    if (op == 8'h04) $sformat(t, "STORE R%0d, [0x%03h]", d, im);
                    else             $sformat(t, "STORE_IND R%0d, [R%0d]", d, s2);
                end
                `TB_C_NOP:  $sformat(t, "NOP");
                `TB_C_HALT: $sformat(t, "HALT");
                default:    $sformat(t, "UNKNOWN (0x%08h)", w);
            endcase
            disasm = t;
        end
    endfunction

    // ------------------------------------------------------------------
    // Start-up: check program.mem, preload data memory, print banner/listing
    // ------------------------------------------------------------------
    initial begin : setup
        integer         k;
        reg             stop;
        reg [31:0]      w;
        reg [8*256-1:0] l;

        #1;     // after the DUT's own time-0 initial blocks

        if (^dut.u_pmem.mem[0] === 1'bx) begin
            emit("ERROR: program.mem was not loaded (file not found in the simulator run directory?)");
            emit("       Add program.mem as a simulation source or copy it to <proj>.sim/sim_1/behav/xsim/");
            $finish;
        end

        for (k = 0; k < 10; k = k + 1)
            dut.u_dmem.mem[14'h100 + k] = k + 1;

        emit("==============================================================================");
        emit(" CPU Lite V2 - instruction flow trace   (program source: program.mem)");
        emit("==============================================================================");
        emit(" Data memory preload : DATA[0x100..0x109] = 1..10  (sum loop result = 55)");
        emit(" Clocks              : cpu_clk 150 MHz, dm_clk 70 MHz (async, CDC bridge between)");
        emit(" PC / cycle numbers are decimal; flags: Z=zero N=negative C=carry(no-borrow) V=overflow");
        emit("");
        emit(" ---- program listing (PC, word, assembly) ----");

        stop = 1'b0;
        for (k = 0; k < 64 && !stop; k = k + 1) begin
            w = dut.u_pmem.mem[k];
            if (^w === 1'bx) stop = 1'b1;
            else begin
                $sformat(l, "   PC %03d : 0x%08h : %0s", k, w, disasm(w));
                emit(l);
                if (w[31:24] == 8'hFF) stop = 1'b1;
            end
        end
        emit("");
        emit(" ---- execution trace (one block per instruction, printed after write-back) ----");
    end

    // ------------------------------------------------------------------
    // Instruction trace + end-of-test summary
    // ------------------------------------------------------------------
    always @(posedge cpu_clk) begin : trace
        reg              inited;
        integer          cyc, cyc_start, n_instr, n_rd_hit, n_rd_miss, n_wr_hit, n_wr_miss;
        integer          n_cdc, n_bad, n_taken, k;
        reg [2:0]        st, nst;
        reg              retire, c_hit, br_en, br_tk;
        reg [11:0]       i_pc, npc;
        reg [31:0]       i_word, a, b, r, sdat, rv, mv, res_mem;
        reg [7:0]        op;
        reg [3:0]        d, s1, s2;
        reg [11:0]       im;
        reg [13:0]       ea;
        reg              z, n, c, v;
        reg [8*256-1:0]  l1, l2, l3;
        reg [8*12-1:0]   verdict;

        if (inited !== 1'b1) begin
            inited = 1'b1;  cyc = 0;  cyc_start = 0;  n_instr = 0;
            n_rd_hit = 0;  n_rd_miss = 0;  n_wr_hit = 0;  n_wr_miss = 0;
            n_cdc = 0;  n_bad = 0;  n_taken = 0;  c_hit = 1'b0;
            a = 0; b = 0; r = 0; sdat = 0; ea = 0; br_en = 0; br_tk = 0;
        end

        if (cpu_rst_n === 1'b1) begin
            cyc = cyc + 1;
            st  = dut.u_cpu.u_controller.ps;
            nst = dut.u_cpu.u_controller.ns;

            if (dut.u_cdc.cmd_wr_en === 1'b1) n_cdc = n_cdc + 1;

            // ---- sample values BEFORE the clock edge updates them ----
            if (st == `TB_ST_FETCH) begin
                cyc_start = cyc;
                i_pc      = dut.u_cpu.pc;
                i_word    = dut.instr_data;
            end
            if (st == `TB_ST_EXECUTE) begin
                a     = dut.u_cpu.rdata1;       // ALU input A
                b     = dut.u_cpu.alu_b;        // ALU input B (register, imm32 or Rs1)
                r     = dut.u_cpu.alu_result;
                sdat  = dut.u_cpu.cache_wdata;  // store data
                ea    = dut.u_cpu.cache_addr;   // effective memory address
                br_en = dut.u_cpu.branch_en;
                br_tk = dut.u_cpu.branch_taken;
            end
            if (st == `TB_ST_MEMWAIT && dut.u_cache.ps === 1'b0)
                c_hit = dut.u_cache.hit;        // first MEM_WAIT cycle = cache lookup

            retire = ((st != `TB_ST_FETCH) && (nst == `TB_ST_FETCH)) ||
                     ((st == `TB_ST_EXECUTE) && (nst == `TB_ST_HALT));

            // ---- instruction finished: print after the edge has settled ----
            if (retire) begin
                #1;
                n_instr = n_instr + 1;
                op = i_word[31:24];  d = i_word[23:20];  s1 = i_word[19:16];
                s2 = i_word[15:12];  im = i_word[11:0];
                rv  = dut.u_cpu.u_reg_file.mem[d];       // Rd after write-back
                mv  = dut.u_dmem.mem[ea];                // data memory content at ea
                npc = dut.u_cpu.pc;
                z = dut.u_cpu.psr_z;  n = dut.u_cpu.psr_n;
                c = dut.u_cpu.psr_c;  v = dut.u_cpu.psr_v;

                $sformat(l1, "#%03d  t=%8.1f ns  PC=%03d  0x%08h  %0s   [%0d cycles]",
                         n_instr, $realtime, i_pc, i_word, disasm(i_word), cyc - cyc_start + 1);
                emit(l1);

                case (cls(op))
                    `TB_C_ALU2: begin
                        verdict = (rv === r) ? "OK" : "MISMATCH";
                        if (rv !== r) n_bad = n_bad + 1;
                        $sformat(l2, "      ALU : 0x%08h %0s 0x%08h = 0x%08h (%0d)",
                                 a, op_sym(op), b, r, $signed(r));
                        $sformat(l3, "      WB  : R%0d <= 0x%08h [%0s]   flags Z=%b N=%b C=%b V=%b",
                                 d, rv, verdict, z, n, c, v);
                        emit(l2);  emit(l3);
                    end
                    `TB_C_NOT: begin
                        verdict = (rv === r) ? "OK" : "MISMATCH";
                        if (rv !== r) n_bad = n_bad + 1;
                        $sformat(l2, "      ALU : ~0x%08h = 0x%08h (%0d)", a, r, $signed(r));
                        $sformat(l3, "      WB  : R%0d <= 0x%08h [%0s]   flags Z=%b N=%b C=%b V=%b",
                                 d, rv, verdict, z, n, c, v);
                        emit(l2);  emit(l3);
                    end
                    `TB_C_PASS: begin
                        verdict = (rv === r) ? "OK" : "MISMATCH";
                        if (rv !== r) n_bad = n_bad + 1;
                        $sformat(l2, "      ALU : pass 0x%08h = 0x%08h (%0d)", b, r, $signed(r));
                        $sformat(l3, "      WB  : R%0d <= 0x%08h [%0s]", d, rv, verdict);
                        emit(l2);  emit(l3);
                    end
                    `TB_C_CMP: begin
                        $sformat(l2, "      ALU : 0x%08h - 0x%08h = 0x%08h (%0d)   (result not written)",
                                 a, b, r, $signed(r));
                        $sformat(l3, "      PSR : Z=%b N=%b C=%b V=%b", z, n, c, v);
                        emit(l2);  emit(l3);
                    end
                    `TB_C_BR: begin
                        $sformat(l2, "      COND: flags used Z=%b N=%b C=%b V=%b   -> %0s",
                                 z, n, c, v, (br_en && br_tk) ? "TAKEN" : "NOT taken");
                        $sformat(l3, "      PC  : next PC = %0d %0s", npc,
                                 (br_en && br_tk) ? "(branch target)" : "(PC + 1)");
                        if (br_en && br_tk) n_taken = n_taken + 1;
                        emit(l2);  emit(l3);
                    end
                    `TB_C_LOAD: begin
                        verdict = (rv === mv) ? "OK" : "MISMATCH";
                        if (rv !== mv) n_bad = n_bad + 1;
                        if (c_hit) n_rd_hit = n_rd_hit + 1; else n_rd_miss = n_rd_miss + 1;
                        $sformat(l2, "      MEM : addr 0x%04h   cache %0s",
                                 ea, c_hit ? "HIT  (served by L1)" : "MISS (fetched from data memory via CDC, line filled)");
                        $sformat(l3, "      DATA: mem[0x%04h] = 0x%08h (%0d)   R%0d <= 0x%08h [%0s]",
                                 ea, mv, mv, d, rv, verdict);
                        emit(l2);  emit(l3);
                    end
                    `TB_C_STORE: begin
                        verdict = (mv === sdat) ? "OK" : "MISMATCH";
                        if (mv !== sdat) n_bad = n_bad + 1;
                        if (c_hit) n_wr_hit = n_wr_hit + 1; else n_wr_miss = n_wr_miss + 1;
                        $sformat(l2, "      MEM : addr 0x%04h   cache write-%0s", ea,
                                 c_hit ? "HIT  (L1 line + data memory updated)" :
                                         "MISS (data memory updated, L1 untouched: no write-allocate)");
                        $sformat(l3, "      DATA: R%0d = 0x%08h  ->  mem[0x%04h] = 0x%08h (%0d) [%0s]",
                                 d, sdat, ea, mv, mv, verdict);
                        emit(l2);  emit(l3);
                    end
                    `TB_C_NOP:  emit("      NOP : nothing to do");
                    `TB_C_HALT: emit("      CPU stops here (controller in HALT state)");
                    default:    emit("      ??? : unknown opcode");
                endcase
                emit("");

                // ---------------- end of program: summary ----------------
                if (cls(op) == `TB_C_HALT) begin
                    repeat (3) @(posedge cpu_clk);   // let the last writes settle
                    emit("==============================================================================");
                    emit(" SUMMARY");
                    emit("==============================================================================");
                    $sformat(l1, " Instructions executed : %0d  (%0d branches/jumps taken)   CPU cycles : %0d",
                             n_instr, n_taken, cyc);
                    emit(l1);
                    $sformat(l1, " L1 cache  reads  : %0d hit / %0d miss      writes : %0d hit / %0d miss (write-through)",
                             n_rd_hit, n_rd_miss, n_wr_hit, n_wr_miss);
                    emit(l1);
                    $sformat(l1, " CDC commands sent to data memory : %0d", n_cdc);
                    emit(l1);
                    emit(" Final registers:");
                    for (k = 0; k < 16; k = k + 4) begin
                        $sformat(l1, "   R%0d..R%0d : 0x%08h  0x%08h  0x%08h  0x%08h", k, k+3,
                                 dut.u_cpu.u_reg_file.mem[k],   dut.u_cpu.u_reg_file.mem[k+1],
                                 dut.u_cpu.u_reg_file.mem[k+2], dut.u_cpu.u_reg_file.mem[k+3]);
                        emit(l1);
                    end
                    $sformat(l1, " Final flags : Z=%b N=%b C=%b V=%b",
                             dut.u_cpu.psr_z, dut.u_cpu.psr_n, dut.u_cpu.psr_c, dut.u_cpu.psr_v);
                    emit(l1);
                    emit(" Data memory (non-zero words):");
                    for (k = 0; k < 16384; k = k + 1)
                        if (dut.u_dmem.mem[k] !== 32'd0) begin
                            $sformat(l1, "   mem[0x%04h] = 0x%08h (%0d)", k[13:0], dut.u_dmem.mem[k], dut.u_dmem.mem[k]);
                            emit(l1);
                        end
                    emit("------------------------------------------------------------------------------");
                    $sformat(l1, " Per-instruction consistency checks failed : %0d", n_bad);
                    emit(l1);
`ifdef TB_CHECK_RESULT
                    res_mem = dut.u_dmem.mem[`TB_RESULT_ADDR];
                    if (res_mem !== `TB_RESULT_VALUE) n_bad = n_bad + 1;
                    $sformat(l1, " Expected result : mem[0x%04h] == %0d  ->  got %0d  [%0s]",
                             `TB_RESULT_ADDR, `TB_RESULT_VALUE, res_mem,
                             (res_mem === `TB_RESULT_VALUE) ? "PASS" : "FAIL");
                    emit(l1);
`endif
                    if (n_bad == 0) emit(" RESULT : PASS");
                    else            emit(" RESULT : FAIL");
                    emit("==============================================================================");
                    $finish;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Watchdog
    // ------------------------------------------------------------------
    initial begin : watchdog
        #(`TB_MAX_NS);
        emit("RESULT : FAIL - TIMEOUT, CPU never reached HALT");
        $display("   controller state = %0d, PC = %0d",
                 dut.u_cpu.u_controller.ps, dut.u_cpu.pc);
        $finish;
    end

endmodule
