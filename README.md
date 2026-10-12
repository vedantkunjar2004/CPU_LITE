
# CPU Lite — 32-bit RISC Multi-Cycle Processor

A fully synthesisable **32-bit RISC multi-cycle processor** featuring a **Direct-Mapped L1 Data Cache**, **dual-clock architecture** (150 MHz CPU / 70 MHz Data Memory), and a **Gray-coded Asynchronous FIFO CDC Bridge**. Designed, verified, and synthesised targeting the **Synopsys SAED 32 nm EDK** standard-cell library.

---

## Micro-Architecture

<p align="center">
  <img src="https://drive.google.com/file/d/135d3I4OGk92K4m5FwHLEFgf2RNaXZqJa/view?usp=sharing" alt="CPU Lite V2 Micro-Architecture" width="95%"/>
</p>

The processor is organised into **four major subsystems** operating across two asynchronous clock domains:

| Subsystem | Clock Domain | Frequency | Description |
|:---|:---|:---|:---|
| **CPU Core** (`cpu_core_top`) | `cpu_clk` | 150 MHz | Datapath + FSM controller, register file, ALU, PC unit, instruction decoder |
| **L1 Data Cache** (`cache_controller` + `cache_datapath`) | `cpu_clk` | 150 MHz | 256-line direct-mapped, write-through, no write-allocate |
| **CDC Bridge** (`cdc_bridge` + `async_fifo`) | Both | 150 / 70 MHz | Gray-coded async FIFO pair for command/response crossing |
| **Data Memory** (`data_memory`) | `dm_clk` | 70 MHz | 16K × 32-bit synchronous SRAM |

### Execution Model

The CPU uses a **multi-cycle FSM controller** with 5 states:

```
FETCH → EXECUTE → { WRITE_BACK → FETCH
                   { MEM_WAIT → (WRITE_BACK or FETCH)
                   { HALT (self-loop)
```

- **Register-to-register ALU operations:** 3 cycles (Fetch → Execute → Write-Back)
- **Memory operations (cache hit):** 3 cycles
- **Memory operations (cache miss):** Variable cycles (depends on CDC round-trip latency)

---

## Instruction Set Architecture (ISA)

36 instructions across 7 categories, encoded in a fixed 32-bit format:

| Category | Instructions |
|:---|:---|
| **Load / Store** | `LOAD`, `LOAD_IND`, `LOAD_IMM`, `STORE`, `STORE_IND` |
| **Arithmetic** | `ADD`, `SUB`, `MUL`, `ADDI`, `SUBI` |
| **Bitwise** | `AND`, `OR`, `NOT`, `XOR`, `ANDI`, `ORI`, `XORI` |
| **Shift / Rotate** | `SHL`, `SHR`, `SAR`, `ROL`, `ROR` |
| **Compare / Set** | `CMP`, `EQ`, `SLT`, `SLTU`, `MOV`, `LUI` |
| **Branch / Jump** | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `JMP`, `JMP_IF` |
| **Control** | `NOP`, `HALT` |

### Instruction Encoding

```
[31:24]  Opcode (8 bits)
[23:20]  Rd — Destination register (4 bits)
[19:16]  Rs1 — Source register 1 (4 bits)
[15:12]  Rs2 — Source register 2 (4 bits)  OR  [15:0] Immediate (16 bits)
```

- **16 General-Purpose Registers** (R0–R15), each 32 bits wide
- **Processor Status Register (PSR):** Zero (Z), Negative (N), Carry (C), Overflow (V) flags

---

## Directory Structure

```
CPU LITE PROJECT/
├── RTL/                        # Synthesisable Verilog source files
│   ├── cpu_lite_top.v          # Top-level: integrates CPU, cache, CDC, memories
│   ├── cpu_core_top.v          # CPU core datapath wrapper
│   ├── cpu_controller.v        # Multi-cycle FSM controller
│   ├── alu.v                   # 32-bit ALU (16 operations)
│   ├── register_file.v         # 16 × 32-bit register file (2R1W)
│   ├── pc_unit.v               # Program counter with branch/jump support
│   ├── instr_decoder.v         # Instruction register + field extraction
│   ├── imm_extension.v         # Zero / Sign / LUI immediate extension
│   ├── branch_condition.v      # Branch condition evaluator (PSR-based)
│   ├── psr_registers.v         # Processor Status Register (Z, N, C, V)
│   ├── load_store_unit.v       # Cache interface multiplexing
│   ├── cache_controller.v      # L1 cache FSM (S_ACCESS / S_MEM_WAIT)
│   ├── cache_datapath.v        # 256-line tag + data SRAM arrays
│   ├── cdc_bridge.v            # Dual-FIFO CDC bridge + slow-domain FSM
│   ├── async_fifo.v            # Parameterised Gray-coded async FIFO
│   ├── program_memory.v        # Instruction ROM (loaded from program.mem)
│   ├── data_memory.v           # 16K × 32-bit synchronous data SRAM
│   ├── cpu_core_header.vh      # ISA opcode and parameter definitions
│   └── program.mem             # Test program (hex): Σ(1..10) = 55
│
├── Testbench/
│   ├── cpu_lite_tb.v           # Self-checking SystemVerilog testbench
│   ├── Log report output.txt   # Simulation log with cycle-accurate trace
│   └── Waveforms/              # Annotated simulation waveform screenshots
│
├── Synthesis/
│   ├── constraint.sdc.txt      # SDC constraints (dual-clock, I/O delays)
│   └── synthesis_report.txt    # DC Ultra report_timing, report_area, report_qor
│
├── STA/
│   └── STA_report.txt          # PrimeTime signoff timing report
│
├── Lint/
│   ├── lint_waivers.awl.txt    # SpyGlass architectural waivers
│   └── *.png                   # Lint status screenshots
│
├── CDC/
│   ├── constraint.sgdc.txt     # SpyGlass CDC clock domain constraints
│   ├── cdc_waivers.awl.txt     # CDC structural waivers
│   └── *.png                   # CDC verification screenshots
│
├── Reference/
│   ├── CPU_Lite_v2_Spec.docx   # Design specification document
│   └── CPU_lite_microarchitecture.png
│
├── Reports/
│   ├── CPU_Lite_Project_Report.pdf    # Final compiled project report
│   └── CPU_Lite_Report_latex_code.tex # LaTeX source for the report
│
└── RTL_explanation/
    └── CPU_Lite_RTL_Explanation.md    # Detailed module-by-module RTL walkthrough
```

---

## Key Design Decisions

| Decision | Rationale |
|:---|:---|
| **Multi-cycle over pipeline** | Eliminates hazard detection, forwarding logic, and pipeline registers — ~40% fewer cells |
| **Direct-mapped write-through cache** | Avoids multi-way comparators; write-through guarantees memory coherence without dirty-bit tracking |
| **Gray-coded async FIFOs** | Single-bit transitions per pointer increment eliminate multi-bit synchronisation glitches across clock domains |
| **Black-box SRAM ports** | Memory arrays exposed as top-level I/O for clean SRAM macro integration during physical design |
| **Harvard memory architecture** | Separate instruction and data address spaces enable simultaneous fetch and memory access |

---

## Verification & Results Summary

### Functional Simulation
- **Test Program:** Iterative summation loop computing Σ(1..10) = 55
- **Result:** `R3 = 0x37 (55)` correctly stored to memory address `0x200` ✅
- **Tool:** VCS (Synopsys)

### Lint Analysis (SpyGlass)
- **Goal:** `lint_rtl_enhanced`
- **Result:** **0 errors, 0 warnings** after architecturally justified waivers ✅

### CDC Verification (SpyGlass)
- **Goals:** `cdc_setup_check` + `cdc_verify`
- **Result:** **All structural CDC checks passed** with justified waivers for Gray-code FIFO synchronisers ✅

### Logic Synthesis (Design Compiler)

| Metric | Value |
|:---|:---|
| Technology | SAED 32 nm LVT (`ss0p75v25c`) |
| Total Cell Area | 140,204.64 µm² |
| Total Cells | 36,888 |
| Sequential Cells | 11,359 |
| Setup Slack (`clk1`) | **+0.00 ns (MET)** |
| Setup Slack (`clk2`) | **+8.50 ns (MET)** |
| Hold Violations | **0** |

### Static Timing Analysis (PrimeTime)

| Check | Total | Met | Violated |
|:---|:---|:---|:---|
| Setup | 11,359 | 11,343 (100%) | **0** |
| Hold | 11,359 | 11,343 (100%) | **0** |
| Output Setup | 60 | 60 (100%) | **0** |
| Output Hold | 60 | 60 (100%) | **0** |

> **Complete timing closure achieved** at 150 MHz (clk1) and 70 MHz (clk2) with zero violations.

---

## SDC Constraints Overview

```tcl
# Dual-clock definition
create_clock -name clk1 -period 6.00  [get_ports cpu_clk]   ;# 150 MHz
create_clock -name clk2 -period 14.00 [get_ports dm_clk]    ;# 70 MHz

# Asynchronous clock domain isolation
set_clock_groups -asynchronous -group [get_clocks clk1] -group [get_clocks clk2]

# Domain-aware I/O delay constraints
set_input_delay  -clock clk1 -max 2.40 [get_ports {cpu_rst_n instr_data[*]}]
set_input_delay  -clock clk2 -max 5.00 [get_ports {dm_rst_n dm_rdata[*]}]
set_output_delay -clock clk1 -max 2.00 [get_ports {instr_addr[*]}]
set_output_delay -clock clk2 -max 4.50 [get_ports {dm_en dm_we dm_addr[*] dm_wdata[*]}]
```

---

## Tools Used

| Stage | Tool | Version |
|:---|:---|:---|
| RTL Simulation | Synopsys VCS | S-2021.09 |
| Lint Analysis | Synopsys SpyGlass | L-2016.06 |
| CDC Verification | Synopsys SpyGlass CDC | L-2016.06 |
| Logic Synthesis | Synopsys Design Compiler | S-2021.06-SP4 |
| Static Timing Analysis | Synopsys PrimeTime | S-2021.06-SP2 |
| Technology Library | SAED 32 nm EDK (LVT) | `saed32lvt_ss0p75v25c` |

---

## How to Run

### Simulation (VCS)
```bash
vcs -full64 -sverilog RTL/*.v RTL/*.vh Testbench/cpu_lite_tb.v -o simv
./simv
```

### Synthesis (Design Compiler)
```bash
dc_shell
read_file -format verilog {RTL/cpu_core_header.vh RTL/*.v}
source Synthesis/constraint.sdc.txt
compile_ultra
report_timing
report_area -hier
report_qor
```

### STA (PrimeTime)
```bash
pt_shell
read_verilog cpu_lite_netlist.v
link
source constraint.sdc
report_timing
report_timing -delay_type min
```

---

## Author

**Vedant Vasant Kunjar**

---

## License

This project was developed as a training project at Mirafra Technologies. All rights reserved.

