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
    logic [17:0] in_buffer1_start;
    logic [17:0] in_buffer1_offset;
    logic [17:0] in_buffer2_start;
    logic [17:0] in_buffer2_offset;
    logic [17:0] in_buffer3_start;
    logic [17:0] in_buffer3_offset;
    logic [17:0] out_buffer1_start;
    logic [17:0] out_buffer1_offset;
    logic [17:0] out_buffer2_start;
    logic [17:0] out_buffer2_offset;
    logic [17:0] action_size;
    logic [17:0] block_size;
    logic [15:0] param1;
    logic [15:0] param2;
    logic [31:0] start_ram_address;
    logic        left_right;
    logic        start;

    // -------------------------------------------------------------------------
    // CU Output Signals
    // -------------------------------------------------------------------------
    logic next_start;
    logic next_status;

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
    logic        ram_we;
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
    logic        ram_we_out;
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
        .next_start(next_start),
        .next_status(next_status),
        .enable(enable),
        .mode(mode),
        .we_a(we_a),
        .addr_a(addr_a),
        .select_a(select_a),
        .we_b(we_b),
        .addr_b(addr_b),
        .select_b(select_b),
        .ram_we(ram_we),
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
        .ram_we(ram_we),
        .ram_addr(ram_addr),
        .mux_index(mux_index),
        .write_from(write_from),
        .audio_out_enable(audio_out_enable_ctrl),
        .audio_out_lr(audio_out_lr_ctrl),
        .audio_out(audio_out),
        .lr_out(lr_out),
        .enable_out(enable_out),
        .ram_we_out(ram_we_out),
        .ram_addr_out(ram_addr_out),
        .ram_out(ram_out)
    );

    // -------------------------------------------------------------------------
    // Mock RAM Behavior
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        // Feed mock data to the datapath when a RAM read is happening
        // We'll use a recognizable hex value for testing
        if (ram_addr_out == 32'd1000) begin
            ram_out <= {16'hAAAA, 16'hBBBB}; 
        end else begin
            ram_out <= 32'h0;
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
        in_buffer1_start = 18'd0;
        in_buffer1_offset = 18'd0;
        action_size = 18'd0;
        block_size = 18'd100;
        start_ram_address = 32'd0;
        left_right = 1'b0;

        // 2. Release Reset safely
        #40;
        @(posedge clk);
        rst <= 1'b1;
        $display("[TB] Reset released at time %0t", $time);
        
        // Wait a few cycles for idle state to settle
        repeat(3) @(posedge clk);

        // 3. TEST: COPY Instruction (RAM -> BRAM)
        $display("[TB] Sending APU_OP_COPY Instruction...");
        opcode            <= APU_OP_COPY;
        in_buffer1_start  <= 18'd60; // We want to write at addr 60
        in_buffer1_offset <= 18'd0;
        action_size       <= 18'd1;  // Process 1+1 words based on your counter logic
        start_ram_address <= 32'd1000;
        
        // Pulse Start
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // Wait for operation to complete (wait for status to go low again)
        wait(next_status == 1'b1);
        wait(next_status == 1'b0);
        $display("[TB] APU_OP_COPY Completed at time %0t", $time);

        // Give the pipeline a moment to completely drain
        repeat(5) @(posedge clk);

        // 4. TEST: AUDIO OUT Instruction (BRAM -> Audio_Out)
        $display("[TB] Sending APU_OP_AUDIO_OUT Instruction...");
        opcode            <= APU_OP_AUDIO_OUT;
        in_buffer1_start  <= 18'd60; // Read from the same addr we just wrote to
        in_buffer1_offset <= 18'd0;
        action_size       <= 18'd1;  
        left_right        <= 1'b1;   // Route to Right channel

        // Pulse Start
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        // Wait for operation to complete
        wait(next_status == 1'b1);
        wait(next_status == 1'b0);
        $display("[TB] APU_OP_AUDIO_OUT Completed at time %0t", $time);
        
        // Flush remaining pipeline stages
        repeat(5) @(posedge clk);

        $display("[TB] Simulation finished successfully.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Assertions / Monitors
    // -------------------------------------------------------------------------
    initial begin
        // Monitor Datapath outputs
        $monitor("Time=%0t | State_Status=%b | DP_En=%b | DP_Mode=%b | AudioOut=%h | LR=%b | Out_En=%b", 
                 $time, next_status, enable, mode, audio_out, lr_out, enable_out);
    end

    // Basic checker for the final output
    always @(posedge clk) begin
        if (enable_out) begin
            $display("[CHECK] Valid Audio Output detected at %0t! Value: %h (Expected around AAAABBBB depending on your memory packing)", $time, audio_out);
            if (audio_out !== {16'hAAAA, 16'hBBBB}) begin
                $warning("[WARNING] Audio out did not match the test payload sent from RAM.");
            end
        end
    end

endmodule