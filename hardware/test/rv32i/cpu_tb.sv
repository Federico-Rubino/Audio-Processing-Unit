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
  wire [31:0] x5  = debug_regs[191:160];
  wire [31:0] x6  = debug_regs[223:192];
  wire [31:0] x7  = debug_regs[255:224];
  wire [31:0] x8  = debug_regs[287:256];
  wire [31:0] x9  = debug_regs[319:288];
  wire [31:0] x10 = debug_regs[351:320];
  wire [31:0] x11 = debug_regs[383:352];
  wire [31:0] x12 = debug_regs[415:384];
  wire [31:0] x13 = debug_regs[447:416];
  wire [31:0] x14 = debug_regs[479:448];
  wire [31:0] x15 = debug_regs[511:480];
  wire [31:0] x16 = debug_regs[543:512];
  wire [31:0] x17 = debug_regs[575:544];
  wire [31:0] x18 = debug_regs[607:576];
  wire [31:0] x19 = debug_regs[639:608];
  wire [31:0] x20 = debug_regs[671:640];
  wire [31:0] x21 = debug_regs[703:672];
  wire [31:0] x22 = debug_regs[735:704];
  wire [31:0] x23 = debug_regs[767:736];
  wire [31:0] x24 = debug_regs[799:768];
  wire [31:0] x25 = debug_regs[831:800];
  wire [31:0] x26 = debug_regs[863:832];
  wire [31:0] x27 = debug_regs[895:864];
  wire [31:0] x28 = debug_regs[927:896];
  wire [31:0] x29 = debug_regs[959:928];
  wire [31:0] x30 = debug_regs[991:960];
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
        while (x31 != 120 && cycle_count < max_cycles) begin
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

    
    // check results
    $display("x1 (RA) = %0d", x1);
    $display("x2       = %0d", x2);
    $display("x3       = %0d", x3);
    $display("x31      = %h", x31);

    // assertion
    if (x31 != 120)
      $fatal(1, "FAIL: x31 never reached");

    if (x1 == 0)
      $fatal(1, "FAIL: JAL did not write return address");

    $display(".DATA SECTION/JAL-JALR/ TEST PASSED");
    $finish;
  end

endmodule