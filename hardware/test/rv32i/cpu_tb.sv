`timescale 1ns / 1ps

module cpu_tb;

  logic clk;
  logic rst;

  logic [31:0] instr_mem_data;
  logic [31:0] data_mem_data_in;
  logic [31:0] data_mem_data_out;
  logic [31:0] data_mem_addra;
  logic [3:0]  data_mem_wea;

  logic [31:0] pc;
  logic instr_mem_ena;
  logic data_mem_ena;

  logic [1023:0] debug_regs;

  int cycle_count = 0;
  int max_cycles = 5000;

  // register mapping
  wire [31:0] x0  = debug_regs[31:0];
  wire [31:0] x1  = debug_regs[63:32];
  wire [31:0] x2  = debug_regs[95:64];
  wire [31:0] x3  = debug_regs[127:96];
  wire [31:0] x4  = debug_regs[159:128];
  wire [31:0] x31 = debug_regs[1023:992];

  // DUT
  CPU cpu_inst (
    .clk(clk),
    .rst(rst),

    .instr_mem_data(instr_mem_data),
    .data_mem_data_in(data_mem_data_in),
    .data_mem_data_out(data_mem_data_out),

    .instr_mem_addr(pc),
    .instr_mem_ena(instr_mem_ena),

    .data_mem_ena(data_mem_ena),
    .data_mem_addr(data_mem_addra),
    .data_mem_wea(data_mem_wea),

    .debug_regs(debug_regs)
  );

  instruction_memory instr_mem_inst(
    .clka(clk),
    .ena(instr_mem_ena),
    .addra(pc[11:2]),
    .douta(instr_mem_data)
  );

  data_memory data_mem_inst(
    .clka(clk),
    .ena(data_mem_ena),
    .addra(data_mem_addra[16:2]),
    .douta(data_mem_data_in),
    .dina(data_mem_data_out),
    .wea(data_mem_wea)
  );

  // clock
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst = 1;

    #20 rst = 0;

    // timeout watchdog
    fork
      begin
        while (x31 != 32'hDEAD && cycle_count < max_cycles) begin
          @(posedge clk);
          cycle_count++;
        end
      end

      begin
        #200000;
        $fatal("TIMEOUT HARD");
      end
    join_any

    disable fork;

    // =========================
    // CHECK RESULTS
    // =========================

    $display("x1 (RA) = %0d", x1);
    $display("x2       = %0d", x2);
    $display("x3       = %0d", x3);
    $display("x31      = %h", x31);

    // ===== ASSERTIONS =====

    if (x31 != 32'hDEAD)
      $fatal(1, "FAIL: JAL/JALR flow broken (x31 never reached)");

    if (x1 == 0)
      $fatal(1, "FAIL: JAL did not write return address");

    $display("JAL/JALR TEST PASSED");
    $finish;
  end

endmodule