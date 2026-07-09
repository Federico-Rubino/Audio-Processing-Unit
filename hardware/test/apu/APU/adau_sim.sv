// ADAU1761 codec emulator for simulating APU.vhd's AC_* pins.
//
// Ports below are named/directed from the codec's own point of view, i.e.
// the OPPOSITE of APU.vhd's port directions -- wire this module's AC_* pins
// directly to the DUT's same-named pins.
//
// Protocol assumptions (derived from reading audioIO/zedboard_audio/hdl/
// i2s_data_interface.vhd and i2c.vhd/i3c2.vhd, not from a datasheet):
//   - I2S: codec is bus master (drives BCLK/LRCLK), FPGA is slave. Standard
//     convention -- data changes on BCLK falling edge, sampled on rising
//     edge. 32-bit slot per channel (24 meaningful bits + 8 padding,
//     matching audioIO.vhd's own 16-bit-in-24-bit convention: only the top
//     16 bits of each 32-bit slot actually carry a PCM sample), LRCLK is a
//     plain 50%-duty square wave marking slot boundaries, one full LRCLK
//     period = one new audio sample. Real hardware runs BCLK ~3.07MHz
//     (48kHz x 64) -- kept here, since i2s_data_interface's edge-detector
//     (a 10-tap shift register sampled by clk_48) implicitly assumes that
//     ratio of oversampling.
//   - I2C: the FPGA's master (i3c2.vhd) does not appear to block/retry on
//     NACK -- it always advances at a fixed clock rate. This module still
//     drives a real ACK (SDA low on the 9th clock of every byte) since
//     it's cheap and removes any risk of 'X' propagating in from an
//     undriven SDA line.
//   - Both channel slots each frame carry the IDENTICAL injected sample
//     value (rather than picking one physical slot as "left"), which
//     sidesteps needing to know the real hardware's L/R polarity -- since
//     both audioIO channels are meant to receive the same test content
//     anyway, this is not a simplification that hides anything real.
//   - rst is ACTIVE-LOW here, matching APU.vhd/AudioCU and every other
//     module in the design -- this module shares the DUT's own rst net in
//     aputb.sv, so its polarity must match.
//
// NOT verified against real hardware or a mixed-language simulation --
// GHDL (used everywhere else this project's VHDL has been checked) doesn't
// simulate SystemVerilog. This needs to actually be run in Vivado.
module adau_sim #(
    parameter int BCLK_HALF_PERIOD_NS = 163,  // ~3.07 MHz BCLK
    parameter int SLOT_BITS           = 32    // bits per channel slot
) (
    input  logic rst,

    input  logic AC_ADR0,
    input  logic AC_ADR1,
    input  logic AC_GPIO0,   // I2S MISO: FPGA -> codec (playback/out), we read this
    output logic AC_GPIO1,   // I2S MOSI: codec -> FPGA (line-in), we drive this
    output logic AC_GPIO2,   // I2S BCLK, codec-generated
    output logic AC_GPIO3,   // I2S LRCLK, codec-generated
    input  logic AC_MCLK,    // unused here
    input  logic AC_SCK,     // I2C SCL, FPGA-generated
    inout  wire  AC_SDA,     // I2C SDA, shared, open-drain

    // testbench visibility
    output logic [15:0] tx_sample,     // value currently being injected
    output logic [15:0] rx_sample,     // most recently captured playback sample
    output logic        rx_valid,      // 1-cycle pulse when rx_sample updates
    output logic        rx_slot_phase  // which of the 2 slots/frame rx_sample came from
);

    // ------------------------------------------------------------------
    // I2S clock generation (free-running, independent of the DUT's own
    // internal clocks -- a real codec doesn't know or care about those)
    // ------------------------------------------------------------------
    logic bclk_r;
    logic lrclk_r;

    initial bclk_r = 1'b0;
    always #(BCLK_HALF_PERIOD_NS) bclk_r = rst ? ~bclk_r : 1'b0;

    assign AC_GPIO2 = bclk_r;
    assign AC_GPIO3 = lrclk_r;

    // ------------------------------------------------------------------
    // TX: triangle wave (0 -> 65535 -> 0 -> ...), one new value per full
    // LRCLK period, transmitted MSB-first as {sample, 16'h0} in both slots
    // ------------------------------------------------------------------
    logic [15:0] wave_val;
    logic        wave_dir;   // 0 = counting up, 1 = counting down
    logic [4:0]  tx_bit_idx; // 0..31 within the current slot
    logic [31:0] tx_shift;

    assign tx_sample = wave_val;
    assign AC_GPIO1  = tx_shift[31];

    always @(negedge bclk_r or negedge rst) begin
        if (!rst) begin
            tx_bit_idx <= 5'd0;
            lrclk_r    <= 1'b0;
            wave_val   <= 16'h0000;
            wave_dir   <= 1'b0;
            tx_shift   <= 32'h0;
        end else begin
            if (tx_bit_idx == SLOT_BITS-1) begin
                tx_bit_idx <= 5'd0;
                // completing a full frame (both slots) advances the wave --
                // only do it once per frame, on the slot-1 -> slot-0 wrap
                if (lrclk_r) begin
                    if (!wave_dir) begin
                        if (wave_val == 16'hFFFF) begin
                            wave_dir <= 1'b1;
                            wave_val <= wave_val - 16'd1;
                        end else begin
                            wave_val <= wave_val + 16'd1;
                        end
                    end else begin
                        if (wave_val == 16'h0000) begin
                            wave_dir <= 1'b0;
                            wave_val <= wave_val + 16'd1;
                        end else begin
                            wave_val <= wave_val - 16'd1;
                        end
                    end
                end
                lrclk_r <= ~lrclk_r;
            end else begin
                tx_bit_idx <= tx_bit_idx + 5'd1;
            end

            tx_shift <= (tx_bit_idx == 5'd0) ? {wave_val, 16'h0000} : {tx_shift[30:0], 1'b0};
        end
    end

    // ------------------------------------------------------------------
    // RX: capture whatever the FPGA sends back on AC_GPIO0, one 32-bit
    // slot at a time, sampled on BCLK rising edges (data assumed stable
    // since audio_top's i2s_data_interface changes it on falling edges)
    // ------------------------------------------------------------------
    logic [31:0] rx_shift;
    logic [4:0]  rx_bit_idx;
    logic        rx_phase; // toggles each completed slot

    always @(posedge bclk_r or negedge rst) begin
        if (!rst) begin
            rx_bit_idx <= 5'd0;
            rx_shift   <= 32'h0;
            rx_sample  <= 16'h0;
            rx_valid   <= 1'b0;
            rx_phase   <= 1'b0;
            rx_slot_phase <= 1'b0;
        end else begin
            automatic logic [31:0] next_shift = {rx_shift[30:0], AC_GPIO0};
            rx_shift <= next_shift;
            rx_valid <= 1'b0;

            if (rx_bit_idx == SLOT_BITS-1) begin
                rx_bit_idx    <= 5'd0;
                rx_sample     <= next_shift[31:16];
                rx_valid      <= 1'b1;
                rx_slot_phase <= rx_phase;
                rx_phase      <= ~rx_phase;
            end else begin
                rx_bit_idx <= rx_bit_idx + 5'd1;
            end
        end
    end

    // ------------------------------------------------------------------
    // I2C slave: always ACK. Content of the config transaction is not
    // checked -- this only exists so AC_SDA never floats undriven/'X'
    // during the ADAU1761 configuration sequence at the start of the sim.
    // ------------------------------------------------------------------
    logic ack_phase;
    logic [2:0] bit_cnt;

    assign AC_SDA = ack_phase ? 1'b0 : 1'bz;

    // START condition: SDA falls while SCL is high
    always @(negedge AC_SDA) begin
        if (AC_SCK && rst) begin
            bit_cnt   <= 3'd0;
            ack_phase <= 1'b0;
        end
    end

    // STOP condition: SDA rises while SCL is high
    always @(posedge AC_SDA) begin
        if (AC_SCK && rst) begin
            bit_cnt   <= 3'd0;
            ack_phase <= 1'b0;
        end
    end

    always @(posedge AC_SCK or negedge rst) begin
        if (!rst) begin
            bit_cnt   <= 3'd0;
            ack_phase <= 1'b0;
        end else if (!ack_phase) begin
            if (bit_cnt == 3'd7) begin
                ack_phase <= 1'b1;
                bit_cnt   <= 3'd0;
            end else begin
                bit_cnt <= bit_cnt + 3'd1;
            end
        end else begin
            ack_phase <= 1'b0;
        end
    end

endmodule
