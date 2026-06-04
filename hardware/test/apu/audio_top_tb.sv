`timescale 1ns / 1ps

import apu_pkg::*;

module AudioTop_tb;

    // -------------------------------------------------------------------------
    // Clock and Reset
    // -------------------------------------------------------------------------
    logic clk;
    logic rst;

    // 50MHz clock (20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // CU Input Signals (Register File / Triggers)
    // -------------------------------------------------------------------------
    apu_opcode_t opcode;
    logic [9:0]  in_buffer1_start;
    logic [17:0] in_buffer1_offset;
    logic [9:0]  in_buffer2_start;
    logic [17:0] in_buffer2_offset;
    logic [9:0]  in_buffer3_start;
    logic [17:0] in_buffer3_offset;
    logic [9:0]  out_buffer1_start;
    logic [17:0] out_buffer1_offset;
    logic [9:0]  out_buffer2_start;
    logic [17:0] out_buffer2_offset;
    logic [17:0] action_size;
    logic [9:0]  block_size;
    logic [15:0] param1;
    logic [15:0] param2;
    logic [31:0] start_ram_address;
    logic        left_right;
    logic        start;

    // -------------------------------------------------------------------------
    // CU Output Signals
    // -------------------------------------------------------------------------
    logic [31:0] next_status;
    logic        started;

    // -------------------------------------------------------------------------
    // Interconnects (CU -> Datapath)
    // -------------------------------------------------------------------------
    logic        enable;
    logic [1:0]  mode;
    logic        we_a;
    logic [9:0]  addr_a;
    logic [7:0]  select_a;
    logic        we_b;
    logic [9:0]  addr_b;
    logic [7:0]  select_b;
    logic        ram_en;
    logic [31:0] ram_addr;
    logic [7:0]  mux_index;
    logic [1:0]  write_from;
    logic        audio_out_enable_ctrl;
    logic        audio_out_lr_ctrl;

    // -------------------------------------------------------------------------
    // Datapath External IO
    // -------------------------------------------------------------------------
    logic [31:0] audio_out;
    logic        lr_out;
    logic        enable_out;
    logic        ram_en_out;
    logic [31:0] ram_addr_out;
    logic [31:0] ram_out;

    // -------------------------------------------------------------------------
    // Device Under Test: Control Unit
    // -------------------------------------------------------------------------
    AudioCU CU_DUT (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .in_buffer1_start(in_buffer1_start),
        .in_buffer1_offset(in_buffer1_offset),
        .in_buffer2_start(in_buffer2_start),
        .in_buffer2_offset(in_buffer2_offset),
        .in_buffer3_start(in_buffer3_start),
        .in_buffer3_offset(in_buffer3_offset),
        .out_buffer1_start(out_buffer1_start),
        .out_buffer1_offset(out_buffer1_offset),
        .out_buffer2_start(out_buffer2_start),
        .out_buffer2_offset(out_buffer2_offset),
        .action_size(action_size),
        .block_size(block_size),
        .param1(param1),
        .param2(param2),
        .start_ram_address(start_ram_address),
        .left_right(left_right),
        .start(start),
        .next_status(next_status),
        .started(started),
        .enable(enable),
        .mode(mode),
        .we_a(we_a),
        .addr_a(addr_a),
        .select_a(select_a),
        .we_b(we_b),
        .addr_b(addr_b),
        .select_b(select_b),
        .ram_en(ram_en),
        .ram_addr(ram_addr),
        .mux_index(mux_index),
        .write_from(write_from),
        .audio_out_enable(audio_out_enable_ctrl),
        .audio_out_lr(audio_out_lr_ctrl)
    );

    // -------------------------------------------------------------------------
    // Device Under Test: Datapath
    // -------------------------------------------------------------------------
    AudioDataPath DP_DUT (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .mode(mode),
        .we_a(we_a),
        .addr_a(addr_a),
        .select_a(select_a),
        .we_b(we_b),
        .addr_b(addr_b),
        .select_b(select_b),
        .ram_en(ram_en),
        .ram_addr(ram_addr),
        .mux_index(mux_index),
        .write_from(write_from),
        .audio_out_enable(audio_out_enable_ctrl),
        .audio_out_lr(audio_out_lr_ctrl),
        .audio_out(audio_out),
        .lr_out(lr_out),
        .enable_out(enable_out),
        .ram_en_out(ram_en_out),
        .ram_addr_out(ram_addr_out),
        .ram_out(ram_out)
    );

    // -------------------------------------------------------------------------
    // Mock RAM Behavior (8 values)
    // -------------------------------------------------------------------------
    logic [31:0] mock_memory_array [0:7];

    initial begin
        mock_memory_array[0] = 32'h1111_AAAA;
        mock_memory_array[1] = 32'h2222_BBBB;
        mock_memory_array[2] = 32'h3333_CCCC;
        mock_memory_array[3] = 32'h4444_DDDD;
        mock_memory_array[4] = 32'h5555_EEEE;
        mock_memory_array[5] = 32'h6666_FFFF;
        mock_memory_array[6] = 32'h7777_1111;
        mock_memory_array[7] = 32'h8888_2222;
    end

    always @(posedge clk) begin
        // If the CU requests an address between 1000 and 1007, return the mapped array value
        if (ram_en_out == 1'd1) begin
            if (ram_addr_out >= 32'd250 && ram_addr_out <= 32'd257) begin
                // Offset the address by the base to get the index 0 through 7
                ram_out <= mock_memory_array[ram_addr_out - 32'd250];
            end else begin
                ram_out <= 32'h0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // 1. Initialize Inputs
        rst = 1'b0;
        start = 1'b0;
        opcode = APU_OP_COPY;
        in_buffer1_start = 10'd0;
        in_buffer1_offset = 18'd0;
        action_size = 18'd0;
        block_size = 10'd100;
        start_ram_address = 32'd0;
        left_right = 1'b0;

        // 2. Release Reset safely
        #40;
        @(posedge clk);
        rst <= 1'b1;
        $display("[TB] Reset released at time %0t", $time);
        
        repeat(3) @(posedge clk);

        // ---------------------------------------------------------------------
        // 3. TEST: COPY Instruction (RAM -> BRAM, 8 words)
        // ---------------------------------------------------------------------
        $display("[TB] Sending APU_OP_COPY Instruction (8 words)...");
        opcode            <= APU_OP_COPY;
        in_buffer1_start  <= 10'd60;   // BRAM base address
        in_buffer1_offset <= 18'd0;    // Start precisely at the base address
        action_size       <= 18'd16;   // Action Size = N-1, so 7 means 8 loops
        start_ram_address <= 32'd1000; // Start pulling mock data from address 1000
        
        // Pulse Start
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // Wait for next_status[0] to go HIGH (indicating fetching/busy), then LOW (idle)
        wait(next_status[0] == 1'b1);
        wait(next_status[0] == 1'b0);
        $display("[TB] APU_OP_COPY Completed at time %0t", $time);

        // Let the wait_pipeline drain fully
        repeat(5) @(posedge clk);

        // ---------------------------------------------------------------------
        // 4. TEST: AUDIO OUT Instruction (BRAM -> Audio_Out, 8 words)
        // ---------------------------------------------------------------------
        $display("[TB] Sending APU_OP_AUDIO_OUT Instruction (8 words)...");
        opcode            <= APU_OP_AUDIO_OUT;
        in_buffer1_start  <= 10'd60;   // Read from the exact same block we wrote to
        in_buffer1_offset <= 18'd0;
        action_size       <= 18'd7;    // Action Size = 7 (for 8 outputs)
        left_right        <= 1'b1;     // Route to Right channel

        // Pulse Start
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // Wait for operation to complete
        wait(next_status[0] == 1'b1);
        wait(next_status[0] == 1'b0);
        $display("[TB] APU_OP_AUDIO_OUT Completed at time %0t", $time);
        
        // Let the pipeline drain out the final audio sample
        repeat(5) @(posedge clk);

        $display("[TB] Simulation finished successfully.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Assertions / Monitors
    // -------------------------------------------------------------------------
    int output_counter = 0;

    always @(posedge clk) begin
        if (enable_out) begin
            $display("[CHECK] Audio Output #%0d detected at %0t! Value: %h", 
                     output_counter, $time, audio_out);
                     
            // Check if the output correctly matches the mock array values in sequence
            if (audio_out !== mock_memory_array[output_counter]) begin
                $warning("  -> [WARNING] Mismatch! Expected %h but got %h", 
                         mock_memory_array[output_counter], audio_out);
            end else begin
                $display("  -> [PASS] Match successful.");
            end
            
            output_counter++;
        end
    end

endmodule