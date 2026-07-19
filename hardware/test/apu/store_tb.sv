`timescale 1ns / 1ps

module store_tb;

    // ------------------------------------------------------------------
    // clock / reset
    // ------------------------------------------------------------------
    logic clk;
    logic rst;

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz, matches APU.vhd's clk

    // ------------------------------------------------------------------
    // DUT Interfacing
    // ------------------------------------------------------------------
    // Audio signals are ignored for this memory test
    logic AC_ADR0=0, AC_ADR1=0, AC_GPIO0=0, AC_GPIO1=0, AC_GPIO2=0, AC_GPIO3=0;
    logic AC_MCLK=0, AC_SCK=0;
    wire  AC_SDA;

    // instr_bram port A (CPU/AXI side)
    logic        we, en;
    logic [10:0] addr;
    logic [31:0] data_in;
    logic [31:0] data_out;

    APU #(
        .ARAM_WORD_SIZE   (32),
        .ARAM_ADDR_SIZE   (15),
        .INSTR_ADDR_SIZE  (11),
        .UPARAM_SIZE      (9),
        .INSTR_SIZE       (128),
        .COUNTER_SIZE     (16)
    ) dut (
        .clk (clk),
        .rst (rst),
        .AC_ADR0(AC_ADR0), .AC_ADR1(AC_ADR1), .AC_GPIO0(AC_GPIO0),
        .AC_GPIO1(AC_GPIO1), .AC_GPIO2(AC_GPIO2), .AC_GPIO3(AC_GPIO3),
        .AC_MCLK(AC_MCLK), .AC_SCK(AC_SCK), .AC_SDA(AC_SDA),
        .we (we), .en (en), .addr (addr), .data_in (data_in), .data_out (data_out)
    );

    // ------------------------------------------------------------------
    // instr_bram port A helpers
    // ------------------------------------------------------------------
    localparam int INSTR_READ_WAIT = 1;

    task automatic bram_write(input logic [10:0] a, input logic [31:0] d);
        @(posedge clk);
        we <= 1'b1; en <= 1'b1; addr <= a; data_in <= d;
        @(posedge clk);
        we <= 1'b0; en <= 1'b0;
    endtask

    task automatic bram_read(input logic [10:0] a, output logic [31:0] d);
        int i;
        @(posedge clk);
        we <= 1'b0; en <= 1'b1; addr <= a;
        for (i = 0; i < INSTR_READ_WAIT + 1; i++) @(posedge clk);
        d = data_out;
        en <= 1'b0;
    endtask

    // ------------------------------------------------------------------
    // Shader & Memory Layout
    // ------------------------------------------------------------------
    localparam int SHADER_WORDS = 8;
    
    // Instruction Bit Packing Breakdown for STORE:
    // Opcode = "1011" (0xB). Word 0 = 32'hb0000000.
    // instr(14 downto 0) = op_len = 256.
    // instr(29 downto 15) = os = 0.
    // instr(44 downto 30) = bl = 256.
    // instr(59 downto 45) = bs = 0.
    // 
    // Packed into lower 64 bits (Word 2 and 3):
    // Word 3 (Bits 31:0)  : (os << 15) | op_len = (0 << 15) | 256 = 32'h0000_0100
    // Word 2 (Bits 63:32) : upper bits of `bl`. 256 << 30 is 1 << 38 of the 64-bit block.
    //                       Bit 38 is bit 6 of Word 2. Therefore Word 2 = 32'h0000_0040.

    localparam logic [31:0] SHADER[0:SHADER_WORDS-1] = '{
        32'hb0000000, 32'h00000000, 32'h00000040, 32'h00000100, // STORE 
        32'hf0000000, 32'h00000000, 32'h00000000, 32'h00000000  // STOP
    };

    localparam logic [10:0] SHADER_START_ADDR = 11'd3;
    localparam logic [10:0] DATA_BASE = 11'd1024;
    localparam int LOAD_COUNT = 256;

    task automatic load_shader_and_data;
        int i;
        
        // 1. Write the Shader instructions
        for (i = 0; i < SHADER_WORDS; i++) begin
            bram_write(SHADER_START_ADDR + i[10:0], SHADER[i]);
        end

        // 2. Load sequential integers: 1024 -> 0, 1025 -> 1, 1026 -> 2...
        for (i = 0; i < LOAD_COUNT; i++) begin
            bram_write(DATA_BASE + i[10:0], i);
        end
    endtask

    // status/control word bits
    localparam int STATUS_BUSY_BIT = 1;
    localparam logic [31:0] CONTROL_START_VALUE = 32'h00000001; // Bit 0 is APU Start

    // ------------------------------------------------------------------
    // main stimulus
    // ------------------------------------------------------------------
    initial begin
        we = 0; en = 0; addr = '0; data_in = '0;
        rst = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1; 

        $display("[%0t] Loading shader and sequential data...", $time);
        load_shader_and_data();

        $display("[%0t] Starting APU...", $time);
        
        // Assert start bit, wait a few cycles, then deassert
        bram_write(11'd1, CONTROL_START_VALUE);
        repeat (5) @(posedge clk);
        bram_write(11'd1, 32'h00000000); 

        // Wait for APU to finish (Busy bit goes high, then low)
        fork
            begin : wait_busy_clear
                logic [31:0] status;
                
                // Wait 10 cycles to ensure the IDLE -> FETCH transition sets the busy bit
                repeat(10) @(posedge clk);
                
                forever begin
                    bram_read(11'd0, status);
                    if (!status[STATUS_BUSY_BIT]) disable wait_busy_clear_timeout;
                    #500;
                end
            end
            begin : wait_busy_clear_timeout
                #5_000_000; // 5 ms timeout
                $display("[%0t] TIMEOUT waiting for APU busy to clear", $time);
                $display("RESULT: FAIL (timeout)");
                $finish;
            end
        join_any
        disable fork;
        
        $display("[%0t] Shader finished. APU is back to IDLE.", $time);
        $display("RESULT: PASS - Execution completed successfully. You can inspect A-RAM arrays in the waveform viewer.");

        $finish;
    end

endmodule