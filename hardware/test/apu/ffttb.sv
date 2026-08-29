`timescale 1ns / 1ps

module ffttb;

    // ------------------------------------------------------------------
    // clock / reset
    // ------------------------------------------------------------------
    logic clk;
    logic rst;

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz, matches APU.vhd's clk 

    // ------------------------------------------------------------------
    // DUT <-> adau_sim wiring
    // ------------------------------------------------------------------
    logic AC_ADR0, AC_ADR1, AC_GPIO0, AC_GPIO1, AC_GPIO2, AC_GPIO3;
    logic AC_MCLK, AC_SCK;
    wire  AC_SDA;

    logic [15:0] tx_sample;
    logic [15:0] rx_sample;
    logic        rx_valid;
    logic        rx_slot_phase;

    logic        we, en;
    logic [10:0] addr;
    logic [31:0] data_in;
    logic [31:0] data_out;

    APU #(
        .ARAM_WORD_SIZE    (32),
        .ARAM_ADDR_SIZE    (15),
        .INSTR_ADDR_SIZE   (11),
        .UPARAM_SIZE       (9),
        .INSTR_SIZE        (128),
        .COUNTER_SIZE      (16)
    ) dut (
        .clk (clk),
        .rst (rst),
        .AC_ADR0  (AC_ADR0), .AC_ADR1  (AC_ADR1),
        .AC_GPIO0 (AC_GPIO0), .AC_GPIO1 (AC_GPIO1),
        .AC_GPIO2 (AC_GPIO2), .AC_GPIO3 (AC_GPIO3),
        .AC_MCLK  (AC_MCLK), .AC_SCK   (AC_SCK),
        .AC_SDA   (AC_SDA),
        .we       (we), .en       (en),
        .addr     (addr), .data_in  (data_in), .data_out (data_out)
    );

    adau_sim adau (
        .rst (rst),
        .AC_ADR0  (AC_ADR0), .AC_ADR1  (AC_ADR1),
        .AC_GPIO0 (AC_GPIO0), .AC_GPIO1 (AC_GPIO1),
        .AC_GPIO2 (AC_GPIO2), .AC_GPIO3 (AC_GPIO3),
        .AC_MCLK  (AC_MCLK), .AC_SCK   (AC_SCK),
        .AC_SDA   (AC_SDA),
        .tx_sample     (tx_sample),
        .rx_sample     (rx_sample),
        .rx_valid      (rx_valid),
        .rx_slot_phase (rx_slot_phase)
    );

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
    // The FFT pipeline shader, assembled from:
    //
    //   .param IN_BS   .param IN_BL   .param IN_OS   .param IN_OL
    //   .param FFT_BS  .param FFT_BL  .param FFT_OS  .param FFT_OL
    //   .param IFFT_BS .param IFFT_BL .param IFFT_OS .param IFFT_OL
    //   .param OUT_BS  .param OUT_BL  .param OUT_OS  .param OUT_OL
    //
    //   AUDIO_IN  { buffer_start_reg=IN_BS  buffer_length_reg=IN_BL operation_start_reg=IN_OS operation_length_reg=IN_OL }
    //   FFT       { buffer_start_reg=IN_BS  buffer_length_reg=IN_BL operation_start_reg=IN_OS operation_length_reg=IN_OL out_buffer_start_reg=FFT_BS out_buffer_length_reg=FFT_BL out_operation_start_reg=FFT_OS out_operation_length_reg=FFT_OL }
    //   IFFT      { buffer_start_reg=FFT_BS buffer_length_reg=FFT_BL operation_start_reg=FFT_OS operation_length_reg=FFT_OL out_buffer_start_reg=IFFT_BS out_buffer_length_reg=IFFT_BL out_operation_start_reg=IFFT_OS out_operation_length_reg=IFFT_OL }
    //   AUDIO_OUT { buffer_start_reg=IFFT_BS buffer_length_reg=IFFT_BL operation_start_reg=IFFT_OS operation_length_reg=IFFT_OL }
    //   STOP
    // ------------------------------------------------------------------
    localparam int SHADER_WORDS = 20; // 5 instructions * 4 words
    
    localparam logic [31:0] SHADER[0:SHADER_WORDS-1] = '{
        32'hc0000000, 32'h00000000, 32'h00000000, 32'h00040403, // AUDIO_IN 
        32'h10000000, 32'h00080503, 32'h00000000, 32'h00040403, // FFT
        32'h28000000, 32'h00100905, 32'h00000000, 32'h20140c07, // IFFT (Bit 123 set for fwd_inv)
        32'hd0000000, 32'h00000000, 32'h00000000, 32'h40241407, // AUDIO_OUT (Reads from IFFT output)
        32'hf0000000, 32'h00000000, 32'h00000000, 32'h00000000  // STOP
    };

    localparam logic [10:0] SHADER_START_ADDR = 11'd3;
    localparam logic [31:0] CONTROL_START_VALUE = 32'h00000003;

    // Parameter Offsets
    localparam int IN_BS = 0,   IN_BL = 1,   IN_OS = 2,   IN_OL = 3;
    localparam int FFT_BS = 4,  FFT_BL = 5,  FFT_OS = 6,  FFT_OL = 7;
    localparam int IFFT_BS = 8, IFFT_BL = 9, IFFT_OS = 10, IFFT_OL = 10;
    // AUDIO_OUT reuses IFFT buffers directly, but we map them as standard just in case
    localparam int OUT_BS = 12, OUT_BL = 13, OUT_OS = 14, OUT_OL = 15;

    localparam logic [10:0] PARAM_LEFT_BASE  = 11'd1024;
    localparam logic [10:0] PARAM_RIGHT_BASE = 11'd1536;

    task automatic load_shader_and_params;
        int i;
        for (i = 0; i < SHADER_WORDS; i++) begin
            bram_write(SHADER_START_ADDR + i[10:0], SHADER[i]);
        end

        // ---------------- LEFT CHANNEL ----------------
        // Buffer 0 (Input): 256 samples, packed into 128 words
        bram_write(PARAM_LEFT_BASE + IN_BS[10:0],  32'd0);
        bram_write(PARAM_LEFT_BASE + IN_BL[10:0],  32'd128);
        bram_write(PARAM_LEFT_BASE + IN_OS[10:0],  32'd0);
        bram_write(PARAM_LEFT_BASE + IN_OL[10:0],  32'd128);

        // Buffer 1 (Freq Domain): 256 complex samples, taking 256 words
        bram_write(PARAM_LEFT_BASE + FFT_BS[10:0], 32'd128); // Starts immediately after Input
        bram_write(PARAM_LEFT_BASE + FFT_BL[10:0], 32'd256); // Needs 256 words
        bram_write(PARAM_LEFT_BASE + FFT_OS[10:0], 32'd0);
        bram_write(PARAM_LEFT_BASE + FFT_OL[10:0], 32'd256);

        // Buffer 2 (Time Domain Out): 256 samples, packed into 128 words
        bram_write(PARAM_LEFT_BASE + IFFT_BS[10:0], 32'd384); // 128 (start) + 256 (length) = 384
        bram_write(PARAM_LEFT_BASE + IFFT_BL[10:0], 32'd128);
        bram_write(PARAM_LEFT_BASE + IFFT_OS[10:0], 32'd0);
        bram_write(PARAM_LEFT_BASE + IFFT_OL[10:0], 32'd128);

        // ---------------- RIGHT CHANNEL ----------------
        // Buffer 0 (Input): starts at 0
        bram_write(PARAM_RIGHT_BASE + IN_BS[10:0],  32'd0);
        bram_write(PARAM_RIGHT_BASE + IN_BL[10:0],  32'd128);
        bram_write(PARAM_RIGHT_BASE + IN_OS[10:0],  32'd0);
        bram_write(PARAM_RIGHT_BASE + IN_OL[10:0],  32'd128);

        // Buffer 1 (Freq Domain): starts at 128
        bram_write(PARAM_RIGHT_BASE + FFT_BS[10:0], 32'd128);
        bram_write(PARAM_RIGHT_BASE + FFT_BL[10:0], 32'd256);
        bram_write(PARAM_RIGHT_BASE + FFT_OS[10:0], 32'd0);
        bram_write(PARAM_RIGHT_BASE + FFT_OL[10:0], 32'd256);

        // Buffer 2 (Time Domain Out): starts at 384
        bram_write(PARAM_RIGHT_BASE + IFFT_BS[10:0], 32'd384);
        bram_write(PARAM_RIGHT_BASE + IFFT_BL[10:0], 32'd128);
        bram_write(PARAM_RIGHT_BASE + IFFT_OS[10:0], 32'd0);
        bram_write(PARAM_LEFT_BASE + IFFT_OL[10:0], 32'd128);
    endtask

    localparam int STATUS_BUSY_BIT      = 1;
    localparam int STATUS_NEW_GRAIN_BIT = 2;
    localparam int COLLECT_MAX = 512;
    
    logic [15:0] collected_left  [0:COLLECT_MAX-1];
    logic [15:0] collected_right [0:COLLECT_MAX-1];
    
    int          collected_count_left = 0;
    int          collected_count_right = 0;
    logic        collecting = 1'b0;

    logic [15:0] sent_left       [0:COLLECT_MAX-1];
    logic [15:0] sent_right      [0:COLLECT_MAX-1];

    always @(posedge rx_valid) begin
        if (rx_slot_phase == 1'b0) begin
            if (collecting && collected_count_left < COLLECT_MAX) begin
                collected_left[collected_count_left] <= rx_sample;
                sent_left[collected_count_left]      <= tx_sample; // Capture input
                collected_count_left <= collected_count_left + 1;
            end
        end else begin
            if (collecting && collected_count_right < COLLECT_MAX) begin
                collected_right[collected_count_right] <= rx_sample;
                sent_right[collected_count_right]      <= tx_sample; // Capture input
                collected_count_right <= collected_count_right + 1;
            end
        end
    end

    // Tolerate minor calculation errors due to IFFT precision bounds
    localparam int TOLERANCE = 3; 

    function automatic int longest_contiguous_run_approx(ref logic [15:0] arr [0:COLLECT_MAX-1], input int count);
        int best, cur, i;
        logic signed [31:0] diff;
        best = (count > 0) ? 1 : 0;
        cur  = (count > 0) ? 1 : 0;
        
        for (i = 1; i < count; i++) begin
            diff = $signed({1'b0, arr[i]}) - $signed({1'b0, arr[i-1]});
            
            // Allow expected delta of 1, plus or minus our tolerance window
            if (diff >= (1 - TOLERANCE) && diff <= (1 + TOLERANCE)) begin
                cur = cur + 1;
                if (cur > best) best = cur;
            end else begin
                cur = 1;
            end
        end
        return best;
    endfunction

    function automatic void verify_pipeline(ref logic [15:0] tx_arr [0:COLLECT_MAX-1], ref logic [15:0] rx_arr [0:COLLECT_MAX-1], input int count, input string channel_name);
        int i, offset, best_offset;
        int min_errors = count; 
        int current_errors;
        logic signed [31:0] diff;

        // Slide the output against the input to find the pipeline delay
        // We check offsets up to 384 (3 full 128-sample blocks)
        for (offset = 0; offset < 384; offset++) begin
            current_errors = 0;
            
            // Compare the overlapping region
            for (i = 0; i < count - offset; i++) begin
                diff = $signed({1'b0, rx_arr[i + offset]}) - $signed({1'b0, tx_arr[i]});
                if (diff < -TOLERANCE || diff > TOLERANCE) begin
                    current_errors++;
                end
            end
            
            if (current_errors < min_errors) begin
                min_errors = current_errors;
                best_offset = offset;
            end
        end
        
        $display("[%0t] %s Channel Check: Best alignment at offset %0d with %0d errors", $time, channel_name, best_offset, min_errors);
        
        if (min_errors == 0)
            $display("RESULT: %s PASS", channel_name);
        else
            $display("RESULT: %s FAIL (Errors exceed tolerance)", channel_name);
    endfunction

    localparam int PASS_RUN_LENGTH = 32; 

    initial begin
        we = 0; en = 0; addr = '0; data_in = '0;
        rst = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1; 

        load_shader_and_params();

        $display("[%0t] waiting for new_grain status bit...", $time);
        fork
            begin : wait_new_grain
                logic [31:0] status;
                forever begin
                    bram_read(11'd0, status);
                    if (status[STATUS_NEW_GRAIN_BIT]) begin
                        disable wait_new_grain_timeout;
                        $display("new grain bit set to 1");
                    end
                    #500;
                end
            end
            begin : wait_new_grain_timeout
                #20_000_000;
                $display("[%0t] TIMEOUT waiting for new_grain", $time);
                $finish;
            end
        join_any
        disable fork;

        bram_write(11'd1, CONTROL_START_VALUE);

        repeat (10) @(posedge clk);
        bram_write(11'd1, 32'h00000002);

        fork
            begin : wait_busy_clear
                logic [31:0] status;
                forever begin
                    bram_read(11'd0, status);
                    if (!status[STATUS_BUSY_BIT]) disable wait_busy_clear_timeout;
                    #500;
                end
            end
            begin : wait_busy_clear_timeout
                #5_000_000; 
                $display("[%0t] TIMEOUT waiting for busy to clear", $time);
                $finish;
            end
        join_any
        disable fork;
        
        collecting = 1'b1;
        #12_000_000; 

        begin
            int run_left, run_right;
            run_left  = longest_contiguous_run_approx(collected_left, collected_count_left);
            run_right = longest_contiguous_run_approx(collected_right, collected_count_right);
            
            $display("[%0t] LEFT:  collected %0d sample(s), longest contiguous run = %0d", $time, collected_count_left, run_left);
            $display("[%0t] RIGHT: collected %0d sample(s), longest contiguous run = %0d", $time, collected_count_right, run_right);
            
            if (run_left >= PASS_RUN_LENGTH && run_right >= PASS_RUN_LENGTH) begin
                $display("RESULT: PASS");
            end else begin
                $display("RESULT: FAIL");
            end
        end

        begin
            $display("[%0t] LEFT:  collected %0d sample(s)", $time, collected_count_left);
            $display("[%0t] RIGHT: collected %0d sample(s)", $time, collected_count_right);
            
            verify_pipeline(sent_left, collected_left, collected_count_left, "LEFT");
            verify_pipeline(sent_right, collected_right, collected_count_right, "RIGHT");
        end

        $finish;
    end

endmodule