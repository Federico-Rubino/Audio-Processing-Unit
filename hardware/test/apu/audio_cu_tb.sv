`timescale 1ns / 1ps

import apu_pkg::*;

module apu_cu_tb;
    logic clk;
    logic rst;
    
    apu_opcode_t opcode;
    logic [17:0] in_buffer1_start,  in_buffer1_offset;
    logic [17:0] in_buffer2_start,  in_buffer2_offset;
    logic [17:0] in_buffer3_start,  in_buffer3_offset;
    logic [17:0] out_buffer1_start, out_buffer1_offset;
    logic [17:0] out_buffer2_start, out_buffer2_offset;
    logic [17:0] action_size,       block_size;
    logic [15:0] param1,            param2;
    logic        start;

    logic        next_start;
    logic        next_status;

    int cycle_count = 0;
    int max_cycles = 5000;

    AudioCU audio_cu (
        .clk                (clk),
        .rst                (rst),
        .opcode             (opcode),
        .in_buffer1_start   (in_buffer1_start),
        .in_buffer1_offset  (in_buffer1_offset),
        .in_buffer2_start   (in_buffer2_start),
        .in_buffer2_offset  (in_buffer2_offset),
        .in_buffer3_start   (in_buffer3_start),
        .in_buffer3_offset  (in_buffer3_offset),
        .out_buffer1_start  (out_buffer1_start),
        .out_buffer1_offset (out_buffer1_offset),
        .out_buffer2_start  (out_buffer2_start),
        .out_buffer2_offset (out_buffer2_offset),
        .action_size        (action_size),
        .block_size         (block_size),
        .param1             (param1),
        .param2             (param2),
        .start              (start),
        .next_start         (next_start),
        .next_status        (next_status)
    );

    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz clock

    initial begin
        rst = 1;
        start = 0;
        opcode = APU_OP_AUDIO_OUT;
        //in_buffer1_start = 0; in_buffer1_offset = 0;

        #20 rst = 0;
        
        @(posedge clk);
        start = 1;
        opcode = APU_OP_COPY;
        
        #100;
        $display("Simulation finished.");
        $finish;
    end

endmodule