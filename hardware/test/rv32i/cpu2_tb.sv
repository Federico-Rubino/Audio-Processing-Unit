`timescale 1ns / 1ps

module cpu_riscv_virtual_mem_test;

    // --- Clock / reset ---
    logic clk;
    logic rst;
    logic instr_en;

    // --- CPU buses ---
    logic [31:0] instr_to_cpu;
    logic [31:0] instr_addr;
    logic [31:0] data_from_mem;
    logic [31:0] data_to_mem;
    logic [3:0]  mem_we_mask;
    logic [31:0] addr_from_alu;

    // --- Debug registers ---
    logic [1023:0] debug_regs;
    wire [31:0] x1  = debug_regs[63:32];
    wire [31:0] x2  = debug_regs[95:64];
    wire [31:0] x3  = debug_regs[127:96];
    wire [31:0] x31 = debug_regs[1023:992];

    // --- Memories ---
    localparam MEM_SIZE = 64;
    logic [31:0] data_mem [0:MEM_SIZE-1];
    logic [31:0] instr_mem [0:MEM_SIZE-1];

    // --- Derived signals ---
    wire [31:0] mem_ptr = addr_from_alu >> 2;

    // --- Clock generation ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- CPU instance ---
    CPU cpu_inst (
        .clk(clk),
        .rst(rst),
        .instr_mem_data(instr_to_cpu),
        .data_mem_data_in(data_from_mem),
        .instr_mem_addr(instr_addr),
        .instr_mem_ena(instr_en),
        .data_mem_addr(addr_from_alu),
        .data_mem_data_out(data_to_mem),
        .data_mem_wea(mem_we_mask),
        .debug_regs(debug_regs)
    );

    // --- Instruction fetch (BRAM-like) ---
    logic [31:0] instr_to_cpu_r;
    always_ff @(posedge clk) begin
        if (instr_en)
            instr_to_cpu_r <= instr_mem[instr_addr[11:2]];
        // else: keep previous value (BRAM behavior)
    end
    assign instr_to_cpu = instr_to_cpu_r;

    // --- Data memory (write/read) ---
    always_ff @(posedge clk) begin
        if (mem_we_mask[0]) data_mem[mem_ptr][7:0]   <= data_to_mem[7:0];
        if (mem_we_mask[1]) data_mem[mem_ptr][15:8]  <= data_to_mem[15:8];
        if (mem_we_mask[2]) data_mem[mem_ptr][23:16] <= data_to_mem[23:16];
        if (mem_we_mask[3]) data_mem[mem_ptr][31:24] <= data_to_mem[31:24];
    end
    assign data_from_mem = data_mem[mem_ptr];

    // --- Initialization / reset ---
    initial begin
        rst = 1;
        instr_en = 0;

        // Clear memories
        for (int i=0; i<MEM_SIZE; i++) begin
            data_mem[i] = 32'h0;
            instr_mem[i] = 32'h00000013; // NOP
        end

        // Program: ALU + store/load test
        instr_mem[0] = 32'h00a00093; // addi x1, x0, 10
        instr_mem[1] = 32'h01400113; // addi x2, x0, 20
        instr_mem[2] = 32'h002081b3; // add x3, x1, x2 -> x3=30
        instr_mem[3] = 32'h00302023; // sw x3, 0(x0)
        instr_mem[4] = 32'h0000f1b7; // lui x31,0
        instr_mem[5] = 32'h00010083; // lw x31, 0(x0)

        #20;           // wait before release reset
        rst = 0;
        instr_en = 1;

        // Wait sufficient cycles for CPU to finish program
        repeat (30) @(posedge clk);

        // --- Verification ---
        if (x1 !== 10)   $error("FAIL: x1 != 10, got %0d", x1);
        if (x2 !== 20)   $error("FAIL: x2 != 20, got %0d", x2);
        if (x3 !== 30)   $error("FAIL: x3 != 30, got %0d", x3);
        if (data_mem[0] !== 30) $error("FAIL: MEM[0] != 30, got %0d", data_mem[0]);
        if (x31 !== 30)  $error("FAIL: x31 != 30, got %0d", x31);

        $display("PASS: CPU + memory basic test succeeded");
        $finish;
    end

endmodule