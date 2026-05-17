`timescale 1ns / 1ps

module cpu_axi_tb;


  logic clk;
  logic rst;  //ACtive high

  logic [1023:0] debug_regs;

  int cycle_count = 0;
  int max_cycles = 2000;

  // Register mapping
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

  //block design wrapper inst
  top_module_wrapper uut (
    .reset_rtl_0(clk),
    .clk_in1_0(rst),        
    .debugs_register(debug_regs_0)
  );

  // Generatore di clock (100 MHz)
  always #5 clk = ~clk;

  initial begin
    // init
    clk = 0;
    rst = 1;

    #100;   
    rst = 0;

    // Timeout watchdog
    fork
      begin
        while (x31 != 120 && cycle_count < max_cycles) begin
          @(posedge clk);
          cycle_count++;
        end
      end

      begin
        
        #200000;
        $fatal(1, "TIMEOUT HARD");
      end
    join_any

    disable fork; //kill the thread

    //Console results

    $display("register:");
    $display("x1 (RA) = %0d", x1);
    $display("x2 = %0d", x2);
    $display("x3 = %0d", x3);
    $display("x31 = %h", x31);


    // Assertion
    if (x31 != 120)
      $fatal(1, "FAIL: x31 never reached 120");

    if (x1 == 0)
      $fatal(1, "FAIL: JAL did not write return address in x1");


    $display(".DATA SECTION/JAL-JALR/ TEST AXI PASSED SUCCESSFULLY!");

    $finish;
  end

endmodule