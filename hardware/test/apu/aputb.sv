// End-to-end APU testbench: loads a passthrough shader (AUDIO_IN -> same
// a-ram row -> AUDIO_OUT) into the real APU.vhd (AudioCU + audioIO +
// aram_mux + the 4 a-ram blocks + instr_bram, all as APU.vhd actually
// instantiates them), waits for a full grain to arrive from the emulated
// ADAU (adau_sim.sv), triggers the shader, and checks that the samples
// coming back out over the emulated I2S line match a contiguous run of
// what went in.
//
// *** IMPORTANT CAVEATS -- read before running ***
//
// 1. instr_bram / aram_bram0..aram_bram3 are Vivado Block Memory Generator
//    IPs, not present in this repo -- create them in the Vivado project
//    with exactly those names (see APU.vhd's header comment for the
//    required shape of each) before this will elaborate.
//
// 2. This has NOT been simulated by me -- GHDL (used for every other
//    testbench in this project) does not support SystemVerilog, and the
//    BRAM IPs don't exist outside a real Vivado project either. This is
//    written from careful static reading of audio_top's I2S/I2C RTL and
//    AudioCU's FSM, not from a passing simulation run. Expect to debug it.
//
// 3. rst is ACTIVE-LOW throughout the whole design (AudioCU, audio_in_unit,
//    audio_out_unit, grain_buffer_in/out, bmu_addr_gen all use
//    `if rst = '0' then ...`). adau_sim.sv shares this same rst net and has
//    been written to match. This testbench drives rst low at the start and
//    releases it high before doing anything else.
//
// 4. Known separately (see prior review): AudioCU's shader-start-address
//    decode doesn't match apu.h's bit-shifted encoding, and shader_mem[0]
//    is offset by 2 words from AudioCU's absolute address space. To keep
//    this test meaningful despite bug #4 without also being blocked by it,
//    the shader is placed at instr_bram word 3 (not the "natural" word 2)
//    and the control register is written directly as 32'h3 -- the one
//    value that happens to satisfy AudioCU's current (buggy) address
//    capture, `idata_out(10:0)`, for an odd target address. This is a
//    workaround for a known bug, not the intended calling convention --
//    revisit once that bug is fixed.
//
// 5. instr_bram is assumed to have one cycle of read latency (typical
//    Block Memory Generator default with an output register). Adjust
//    INSTR_READ_WAIT below if the real IP is configured differently.
//
// 6. KNOWN OPEN BUG, not worked around here: aram_mux is a plain
//    single-select mux (unit_select), not a request/grant arbiter --
//    whichever unit unit_select currently points at gets a-ram access
//    this cycle, everyone else's writes/reads are silently dropped.
//    AudioCU only ever drives unit_select to AUDIO_IN/AUDIO_OUT briefly,
//    while actually executing that shader instruction (audio_control_
//    unit.vhd: default APU_UNIT_NONE, only overridden in the EXECUTE case
//    for that opcode). But audio_in_unit/audio_out_unit need CONTINUOUS
//    a-ram access while they background-fill/drain a grain over ~5.3ms
//    (one row roughly every 333us, paced by the real-time I2S sample
//    clock) -- access that has nothing to do with whether AudioCU happens
//    to be mid-instruction on that opcode. Left as-is, this is a deadlock:
//    audio_in_unit can never write a single row before the shader has
//    run, but the shader can't run until new_grain is set, which needs
//    audio_in_unit to have already written a full grain -- so this
//    testbench will currently hang at wait_new_grain until its 20ms
//    timeout. Tried forcing dut.unit_select_sig directly from this SV
//    testbench as a workaround; XSIM rejects that outright (43-4618/4619:
//    writing a VHDL hierarchical signal from Verilog isn't supported).
//    Fixing this needs either a change to APU.vhd/aram_mux/AudioCU, or a
//    VHDL-side (not SV) testbench mechanism -- deliberately not attempted
//    here yet.

`timescale 1ns / 1ps

module aputb;

    // ------------------------------------------------------------------
    // clock / reset
    // ------------------------------------------------------------------
    logic clk;
    logic rst;

    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz, matches APU.vhd's clk (audio_top's clk_100)

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

    // instr_bram port A (CPU/AXI side) -- the only memory port APU.vhd
    // exposes outside itself
    logic        we, en;
    logic [10:0] addr;
    logic [31:0] data_in;
    logic [31:0] data_out;

    // Vivado mixed-language sim: instantiate the VHDL entity directly,
    // generics passed the same way as SV parameters.
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

        .AC_ADR0  (AC_ADR0),
        .AC_ADR1  (AC_ADR1),
        .AC_GPIO0 (AC_GPIO0),
        .AC_GPIO1 (AC_GPIO1),
        .AC_GPIO2 (AC_GPIO2),
        .AC_GPIO3 (AC_GPIO3),
        .AC_MCLK  (AC_MCLK),
        .AC_SCK   (AC_SCK),
        .AC_SDA   (AC_SDA),

        .we       (we),
        .en       (en),
        .addr     (addr),
        .data_in  (data_in),
        .data_out (data_out)
    );

    adau_sim adau (
        .rst (rst),

        .AC_ADR0  (AC_ADR0),
        .AC_ADR1  (AC_ADR1),
        .AC_GPIO0 (AC_GPIO0),
        .AC_GPIO1 (AC_GPIO1),
        .AC_GPIO2 (AC_GPIO2),
        .AC_GPIO3 (AC_GPIO3),
        .AC_MCLK  (AC_MCLK),
        .AC_SCK   (AC_SCK),
        .AC_SDA   (AC_SDA),

        .tx_sample     (tx_sample),
        .rx_sample     (rx_sample),
        .rx_valid      (rx_valid),
        .rx_slot_phase (rx_slot_phase)
    );

    // ------------------------------------------------------------------
    // instr_bram port A helpers (word-addressed: status=0, control=1,
    // shader_mem=2..1023, param_mem_left=1024..1535, param_mem_right=1536..2047)
    // ------------------------------------------------------------------
    localparam int INSTR_READ_WAIT = 1; // extra cycles to wait for data_out after asserting en (see caveat 5)

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
    // the passthrough shader, assembled with software/shader-toolchain's
    // assembler.py from:
    //
    //   .param IN_BS  .param IN_BL  .param IN_OS  .param IN_OL
    //   .param OUT_BS .param OUT_BL .param OUT_OS .param OUT_OL
    //   AUDIO_IN  { buffer_start_reg=IN_BS  buffer_length_reg=IN_BL
    //               operation_start_reg=IN_OS  operation_length_reg=IN_OL }
    //   AUDIO_OUT { buffer_start_reg=OUT_BS buffer_length_reg=OUT_BL
    //               operation_start_reg=OUT_OS operation_length_reg=OUT_OL }
    //   STOP
    //
    // -- do not hand-edit, regenerate with the assembler if the shader changes.
    // ------------------------------------------------------------------
    localparam int SHADER_WORDS = 12;
    localparam logic [31:0] SHADER[0:SHADER_WORDS-1] = '{
        32'hc0000000, 32'h00000000, 32'h00000000, 32'h00040403, // AUDIO_IN
        32'hd0000000, 32'h00000000, 32'h00000000, 32'h20140c07, // AUDIO_OUT
        32'hf0000000, 32'h00000000, 32'h00000000, 32'h00000000  // STOP
    };

    // shader placed at word 3 instead of the "natural" word 2 -- see caveat 4
    localparam logic [10:0] SHADER_START_ADDR = 11'd3;
    localparam logic [31:0] CONTROL_START_VALUE = 32'h00000007;

    // param offsets from the assembler's --emit-params manifest
    localparam int IN_BS = 0, IN_BL = 1, IN_OS = 2, IN_OL = 3;
    localparam int OUT_BS = 4, OUT_BL = 5, OUT_OS = 6, OUT_OL = 7;

    localparam logic [10:0] PARAM_LEFT_BASE  = 11'd1024;
    localparam logic [10:0] PARAM_RIGHT_BASE = 11'd1536;

    task automatic load_shader_and_params;
        int i;
        logic [31:0] d;

        for (i = 0; i < SHADER_WORDS; i++) begin
            bram_write(SHADER_START_ADDR + i[10:0], SHADER[i]);
        end

        // same passthrough params for both channels: a-ram row 0, 128
        // cells (matches audio_in_unit/audio_out_unit's 256-sample /
        // 2-samples-per-cell grain size)
        bram_write(PARAM_LEFT_BASE + IN_BS[10:0],  32'd0);
        bram_write(PARAM_LEFT_BASE + IN_BL[10:0],  32'd128);
        bram_write(PARAM_LEFT_BASE + IN_OS[10:0],  32'd0);
        bram_write(PARAM_LEFT_BASE + IN_OL[10:0],  32'd128);
        bram_write(PARAM_LEFT_BASE + OUT_BS[10:0], 32'd0);
        bram_write(PARAM_LEFT_BASE + OUT_BL[10:0], 32'd128);
        bram_write(PARAM_LEFT_BASE + OUT_OS[10:0], 32'd0);
        bram_write(PARAM_LEFT_BASE + OUT_OL[10:0], 32'd128);

        bram_write(PARAM_RIGHT_BASE + IN_BS[10:0],  32'd0);
        bram_write(PARAM_RIGHT_BASE + IN_BL[10:0],  32'd128);
        bram_write(PARAM_RIGHT_BASE + IN_OS[10:0],  32'd0);
        bram_write(PARAM_RIGHT_BASE + IN_OL[10:0],  32'd128);
        bram_write(PARAM_RIGHT_BASE + OUT_BS[10:0], 32'd0);
        bram_write(PARAM_RIGHT_BASE + OUT_BL[10:0], 32'd128);
        bram_write(PARAM_RIGHT_BASE + OUT_OS[10:0], 32'd0);
        bram_write(PARAM_RIGHT_BASE + OUT_OL[10:0], 32'd128);
    endtask

    // status/control word bits, matching software/firmware/apu/include/apu.h
    localparam int STATUS_BUSY_BIT      = 1;
    localparam int STATUS_NEW_GRAIN_BIT = 2;

    // ------------------------------------------------------------------
    // RX collection: only look at one slot phase, so a value that's
    // (correctly) duplicated into both slots each frame doesn't look like
    // a broken, doubled sequence
    // ------------------------------------------------------------------
    localparam int COLLECT_MAX = 512;
    
    // Live signals for easy waveform visualization
    logic [15:0] current_rx_left;
    logic [15:0] current_rx_right;

    // Separate arrays to store the history of both channels
    logic [15:0] collected_left  [0:COLLECT_MAX-1];
    logic [15:0] collected_right [0:COLLECT_MAX-1];
    
    int          collected_count_left;
    int          collected_count_right;
    logic        collecting;

    initial begin
        collected_count_left  = 0;
        collected_count_right = 0;
        collecting            = 1'b0;
        current_rx_left       = 16'd0;
        current_rx_right      = 16'd0;
    end

    always @(posedge rx_valid) begin
        // Assuming rx_slot_phase == 0 is Left, and 1 is Right (Standard I2S)
        if (rx_slot_phase == 1'b0) begin
            current_rx_left <= rx_sample; // Live update for waveform
            
            if (collecting && collected_count_left < COLLECT_MAX) begin
                collected_left[collected_count_left] <= rx_sample;
                collected_count_left <= collected_count_left + 1;
            end
        end else begin
            current_rx_right <= rx_sample; // Live update for waveform
            
            if (collecting && collected_count_right < COLLECT_MAX) begin
                collected_right[collected_count_right] <= rx_sample;
                collected_count_right <= collected_count_right + 1;
            end
        end
    end

    // Function adapted to take arrays as arguments to check Left and Right independently
    function automatic int longest_contiguous_run(ref logic [15:0] arr [0:COLLECT_MAX-1], input int count);
        int best, cur, i;
        best = (count > 0) ? 1 : 0;
        cur  = (count > 0) ? 1 : 0;
        for (i = 1; i < count; i++) begin
            if (arr[i] == logic'(arr[i-1] + 16'd1)) begin
                cur = cur + 1;
                if (cur > best) best = cur;
            end else begin
                cur = 1;
            end
        end
        return best;
    endfunction

    // ------------------------------------------------------------------
    // main stimulus
    // ------------------------------------------------------------------
    localparam int PASS_RUN_LENGTH = 32; // consecutive correct samples required to call it a pass

    initial begin
        we = 0; en = 0; addr = '0; data_in = '0;
        rst = 1'b0;
        repeat (10) @(posedge clk);
        rst = 1'b1; // release reset (active-low, see caveat 3)

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
                #20_000_000; // 20 ms
                $display("[%0t] TIMEOUT waiting for new_grain", $time);
                $display("RESULT: FAIL (timeout)");
                $finish;
            end
        join_any
        disable fork;

        $display("[%0t] new_grain seen, starting shader", $time);
        bram_write(11'd1, CONTROL_START_VALUE);

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
                #5_000_000; // 5 ms
                $display("[%0t] TIMEOUT waiting for busy to clear", $time);
                $display("RESULT: FAIL (timeout)");
                $finish;
            end
        join_any
        disable fork;
        $display("[%0t] shader finished (busy cleared)", $time);

        // only start collecting once the shader has actually finished
        // dispatching AUDIO_OUT -- arming this any earlier (e.g. right
        // after writing the control register) captures whatever stale/idle
        // content AC_GPIO0 was shifting out while the shader was still
        // running, padding the front of collected_left/right with bogus
        // entries that happen to read back as 0 (indistinguishable from a
        // real first sample).
        collecting = 1'b1;

        // audio_out keeps streaming the grain out over I2S at its own pace
        // after 'busy' clears -- give it time to actually shift the samples
        #12_000_000; // 12 ms: enough for a 256-sample grain at ~20.8us/sample plus margin

        begin
            int run_left, run_right;
            run_left  = longest_contiguous_run(collected_left, collected_count_left);
            run_right = longest_contiguous_run(collected_right, collected_count_right);
            
            $display("[%0t] LEFT:  collected %0d sample(s), longest contiguous run = %0d", $time, collected_count_left, run_left);
            $display("[%0t] RIGHT: collected %0d sample(s), longest contiguous run = %0d", $time, collected_count_right, run_right);
            
            if (run_left >= PASS_RUN_LENGTH && run_right >= PASS_RUN_LENGTH) begin
                $display("RESULT: PASS");
            end else begin
                $display("RESULT: FAIL");
                if (run_left < PASS_RUN_LENGTH)  $display(" -> LEFT failed (run %0d < required %0d)", run_left, PASS_RUN_LENGTH);
                if (run_right < PASS_RUN_LENGTH) $display(" -> RIGHT failed (run %0d < required %0d)", run_right, PASS_RUN_LENGTH);
            end
        end

        $finish;
    end

endmodule
