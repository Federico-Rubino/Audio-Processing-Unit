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
//   - The two channel slots each frame carry DISTINCT injected sequences
//     (left starts at 0x0000, right at 0xA000, both bouncing 0..0xFFFF
//     independently) instead of an identical duplicated value -- makes it
//     possible to tell the channels apart in collected_left/collected_right
//     (aputb.sv) at a glance instead of eyeballing duplicate pairs.
//   - L/R-to-LRCLK-phase mapping: derived from i2s_data_interface.vhd's
//     OUTPUT reload logic (sr_out <= audio_l_in & ... & audio_r_in & ...,
//     loaded on i2s_lr's RISING edge, L shifted out first) -- so here,
//     "lrclk_r=1" is treated as the L slot and "lrclk_r=0" as the R slot,
//     both for what we transmit and for how rx_slot_phase is set
//     (rx_slot_phase=0 for L, matching aputb.sv's "rx_slot_phase==0 is
//     Left" assumption). This is a static derivation, NOT confirmed by
//     simulation -- if a real run shows collected_left tracking the
//     0xA000 ramp instead of 0x0000 (i.e. swapped), the fix is to flip the
//     `lrclk_r` polarity used below (search for "L/R phase").
//   - rst is ACTIVE-LOW here, matching APU.vhd/AudioCU and every other
//     module in the design -- this module shares the DUT's own rst net in
//     aputb.sv, so its polarity must match.
//
// NOT verified against real hardware or a mixed-language simulation --
// GHDL (used everywhere else this project's VHDL has been checked) doesn't
// simulate SystemVerilog. This needs to actually be run in Vivado.
module adau_sim #(
    parameter int BCLK_HALF_PERIOD_NS = 163,  // ~3.07 MHz BCLK
    parameter int SLOT_BITS           = 32,   // bits per channel slot
    parameter logic [15:0] WAVE_L_INIT = 16'h0000,
    parameter logic [15:0] WAVE_R_INIT = 16'h0020
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
    // TX: two independent triangle waves (L: 0x0000->0xFFFF->0x0000..., R:
    // 0xA000->0xFFFF->0x0000->...), one new value per channel per full
    // LRCLK period, transmitted MSB-first as {sample, 16'h0} -- L during
    // the lrclk_r=1 slot, R during lrclk_r=0 (see L/R phase caveat above).
    // ------------------------------------------------------------------
    logic [15:0] wave_val_l, wave_val_r;
    logic        wave_dir_l, wave_dir_r; // 0 = counting up, 1 = counting down
    logic [4:0]  tx_bit_idx;             // 0..31 within the current slot
    logic [31:0] tx_shift;

    assign tx_sample = lrclk_r ? wave_val_l : wave_val_r; // whichever channel is being shifted out right now
    assign AC_GPIO1  = tx_shift[31];

    always @(negedge bclk_r or negedge rst) begin
        if (!rst) begin
            tx_bit_idx <= 5'd0;
            lrclk_r    <= 1'b0;
            wave_val_l <= WAVE_L_INIT;
            wave_dir_l <= 1'b0;
            wave_val_r <= WAVE_R_INIT;
            wave_dir_r <= 1'b0;
            tx_shift   <= 32'h0;
        end else begin
            if (tx_bit_idx == SLOT_BITS-1) begin
                tx_bit_idx <= 5'd0;
                // completing a full frame (both slots) advances both waves
                // -- only do it once per frame, on the slot-1 -> slot-0 wrap
                if (lrclk_r) begin
                    if (!wave_dir_l) begin
                        if (wave_val_l == 16'h003F) begin
                            wave_dir_l <= 1'b1;
                            wave_val_l <= wave_val_l - 16'd1;
                        end else begin
                            wave_val_l <= wave_val_l + 16'd1;
                        end
                    end else begin
                        if (wave_val_l == 16'hFFC0) begin
                            wave_dir_l <= 1'b0;
                            wave_val_l <= wave_val_l + 16'd1;
                        end else begin
                            wave_val_l <= wave_val_l - 16'd1;
                        end
                    end

                    if (!wave_dir_r) begin
                        if (wave_val_r == 16'h003F) begin
                            wave_dir_r <= 1'b1;
                            wave_val_r <= wave_val_r - 16'd1;
                        end else begin
                            wave_val_r <= wave_val_r + 16'd1;
                        end
                    end else begin
                        if (wave_val_r == 16'hFFC0) begin
                            wave_dir_r <= 1'b0;
                            wave_val_r <= wave_val_r + 16'd1;
                        end else begin
                            wave_val_r <= wave_val_r - 16'd1;
                        end
                    end
                end
                lrclk_r <= ~lrclk_r;
            end else begin
                tx_bit_idx <= tx_bit_idx + 5'd1;
            end

            // reload happens one bclk_r cycle after the wrap above (this
            // branch reads tx_bit_idx as it was BEFORE that wrap's NBA
            // update takes effect), by which point lrclk_r has already
            // settled to the value that governs the slot now starting --
            // see L/R phase caveat above.
            tx_shift <= (tx_bit_idx == 5'd0) ? {(lrclk_r ? wave_val_l : wave_val_r), 16'h0000}
                                              : {tx_shift[30:0], 1'b0};
        end
    end

    // ------------------------------------------------------------------
    // RX: capture whatever the FPGA sends back on AC_GPIO0, one 32-bit
    // slot at a time, sampled on BCLK rising edges (data assumed stable
    // since audio_top's i2s_data_interface changes it on falling edges).
    //
    // is_l_slot is latched directly from lrclk_r at the START of each
    // 32-bit window (bit_idx==0), rather than tracked with its own
    // free-running toggle flip-flop: lrclk_r toggles on the negedge that
    // precedes this posedge domain's wrap by half a cycle, so by
    // bit_idx==0 it has already settled to the value for the window just
    // starting -- anchoring directly to lrclk_r avoids any risk of this
    // signal's own phase drifting out of sync with the TX side's lrclk_r
    // (see L/R phase caveat above).
    // ------------------------------------------------------------------
    logic [31:0] rx_shift;
    logic [4:0]  rx_bit_idx;
    logic        is_l_slot;

    always @(posedge bclk_r or negedge rst) begin
        if (!rst) begin
            rx_bit_idx    <= 5'd0;
            rx_shift      <= 32'h0;
            rx_sample     <= 16'h0;
            rx_valid      <= 1'b0;
            rx_slot_phase <= 1'b0;
            is_l_slot     <= 1'b0;
        end else begin
            automatic logic [31:0] next_shift = {rx_shift[30:0], AC_GPIO0};
            rx_shift <= next_shift;
            rx_valid <= 1'b0;

            if (rx_bit_idx == 5'd0) begin
                is_l_slot <= lrclk_r;
            end

            if (rx_bit_idx == SLOT_BITS-1) begin
                rx_bit_idx    <= 5'd0;
                rx_sample     <= next_shift[31:16];
                rx_valid      <= 1'b1;
                rx_slot_phase <= is_l_slot ? 1'b0 : 1'b1; // 0 = Left, matching aputb.sv's assumption
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
