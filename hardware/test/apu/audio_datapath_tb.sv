`timescale 1ns / 1ps

import apu_pkg::*;

interface AudioDatapath_if;
    logic        clk;
    logic        rst;
    logic        enable;
    datapath_config_t config_sig;

    // Memory control signals
    logic        we_a;
    logic [9:0]  addr_a;
    logic [31:0] data_in_a;
    logic        we_b;
    logic [9:0]  addr_b;
    logic [31:0] data_in_b;

    // Mux signals
    logic [6:0]  mux_index;
    logic        mux_enable;

    // Audio out controls
    logic        audio_out_enable;
    logic        audio_out_lr;

    // Outputs
    logic [31:0] audio_out;
    logic        lr_out;
endinterface

module AudioDataPath_tb;
    AudioDatapath_if tb_if();

    // 50MHz clock (20ns period)
    always begin
        tb_if.clk = 0; #10;
        tb_if.clk = 1; #10;
    end

    AudioDataPath DUT (
        .clk              (tb_if.clk),
        .rst              (tb_if.rst),
        .enable           (tb_if.enable),
        .mode             (tb_if.config_sig),
        
        .we_a             (tb_if.we_a),
        .addr_a           (tb_if.addr_a),
        .data_in_a        (tb_if.data_in_a),
        
        .we_b             (tb_if.we_b),
        .addr_b           (tb_if.addr_b),
        .data_in_b        (tb_if.data_in_b),
        
        .mux_index        (tb_if.mux_index),
        .mux_enable       (tb_if.mux_enable),
        
        .audio_out_enable (tb_if.audio_out_enable),
        .audio_out_lr     (tb_if.audio_out_lr),
        
        .audio_out        (tb_if.audio_out),
        .lr_out           (tb_if.lr_out)
    );

    initial begin
        // Init Inputs
        tb_if.rst              = 1'b0;
        tb_if.enable           = 1'b0;
        tb_if.config_sig       = DOUBLE_READ;
        tb_if.we_a             = 1'b0;
        tb_if.addr_a           = 10'd0;
        tb_if.data_in_a        = 32'd0;
        tb_if.we_b             = 1'b0;
        tb_if.addr_b           = 10'd0;
        tb_if.data_in_b        = 32'd0;
        tb_if.mux_index        = 7'd0;
        tb_if.mux_enable       = 1'b0;
        tb_if.audio_out_enable = 1'b0;
        tb_if.audio_out_lr     = 1'b0;

        // Release Reset
        #40;
        @(posedge tb_if.clk);
        tb_if.rst = 1'b1;
        $display("[TB INFO] Reset released at time %0t", $time);

        // TEST Double Read Mode
        $display("[TEST] Audio Out");
        
        // Audio Out from address 60 to Right
        @(posedge tb_if.clk);
        tb_if.enable = 1'b1;
        tb_if.config_sig = DOUBLE_READ;
        tb_if.we_a = 1'b1;
        tb_if.addr_a = 10'd60;
        tb_if.data_in_a = 32'd0;
        tb_if.we_b = 1'b0;
        tb_if.addr_b = 10'd0;
        tb_if.data_in_b = 32'd0;
        tb_if.mux_index        = 7'd0;
        tb_if.mux_enable       = 1'b1;
        tb_if.audio_out_enable = 1'b1;
        tb_if.audio_out_lr     = 1'b1;

        // Allow data to cycle through memory reading latency
        repeat(3) @(posedge tb_if.clk);

        $finish;
    end

    // Assertions
    initial begin
        $monitor("Time=%0t | Config=%s | Enable=%b | AudioOut=%h | LROut=%b", 
                 $time, tb_if.config_sig.name(), tb_if.enable, tb_if.audio_out, tb_if.lr_out);
    end

endmodule