`default_nettype none

module program_memory(
    input wire [11:0] instr_addr, // From CPU core
    output wire [31:0] instr_data // To CPU core
    );
    
    reg [31:0] mem [0:4095];
    
    initial begin
        $readmemh ("program.mem", mem);
    end
    
    assign instr_data = mem[instr_addr];
    
endmodule
