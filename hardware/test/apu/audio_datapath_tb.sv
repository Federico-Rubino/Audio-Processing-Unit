`timescale 1ns / 1ps

import apu_pkg::*;

interface AudioDatapath_if;
    logic        clk;
    logic        rst;
    logic        enable;
    datapath_config_t mode;

    // Memory control signals
    logic        we_a;
    logic [9:0]  addr_a;
    logic [6:0]  select_a;
    logic        we_b;
    logic [9:0]  addr_b;
    logic [6:0]  select_b;
    
    // RAM signals
    logic        ram_we;
    logic [31:0] ram_addr;

    // Mux signals
    logic [6:0]  mux_index;
    
    // Write back signals
    logic [1:0]  write_from;

    // Audio out controls
    logic        audio_out_enable;
    logic        audio_out_lr;

    // Outputs
    logic [31:0] audio_out;
    logic        lr_out;
    logic        enable_out;
    
    // RAM Outputs
    logic        ram_we_out;
    logic [31:0] ram_addr_out;
    
    // Signals from RAM
    logic [31:0] ram_out;
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
        .mode             (tb_if.mode),
        
        .we_a             (tb_if.we_a),
        .addr_a           (tb_if.addr_a),
        .select_a         (tb_if.select_a),
        .we_b             (tb_if.we_b),
        .addr_b           (tb_if.addr_b),
        .select_b         (tb_if.select_b),
        
        .ram_we           (tb_if.ram_we),
        .ram_addr         (tb_if.ram_addr),
        
        .mux_index        (tb_if.mux_index),
        
        .write_from       (tb_if.write_from),
        
        .audio_out_enable (tb_if.audio_out_enable),
        .audio_out_lr     (tb_if.audio_out_lr),
        
        .audio_out        (tb_if.audio_out),
        .enable_out       (tb_if.enable_out),
        .lr_out           (tb_if.lr_out),
        
        .ram_we_out       (tb_if.ram_we_out),
        .ram_addr_out     (tb_if.ram_addr_out),
        .ram_out          (tb_if.ram_out)
    );

    initial begin
        tb_if.rst              = 1'b0;
        tb_if.enable           = 1'b0;
        tb_if.mode             = DOUBLE_READ;
        tb_if.we_a             = 1'b0;
        tb_if.addr_a           = 10'd0;
        tb_if.select_a         = broadcast;
        tb_if.we_b             = 1'b0;
        tb_if.addr_b           = 10'd0;
        tb_if.select_b         = broadcast;
        tb_if.mux_index        = 7'd0;
        tb_if.write_from       = 2'b00;
        tb_if.audio_out_enable = 1'b0;
        tb_if.audio_out_lr     = 1'b0;
        tb_if.ram_out          = 32'd0;

        // Release Reset safely
        #40;
        @(posedge tb_if.clk);
        tb_if.rst <= 1'b1;
        $display("[TB INFO] Reset released at time %0t", $time);

        // TEST Data In
        $display("[TEST] Data In");
        
        // Store 11 and 4 at address 60
        @(posedge tb_if.clk);
        
        tb_if.enable           <= 1'b1;
        tb_if.mode             <= MIXED;
        tb_if.we_a             <= 1'b0;
        tb_if.addr_a           <= 10'd0;
        tb_if.select_a         <= broadcast;
        tb_if.we_b             <= 1'b1;
        tb_if.addr_b           <= 10'd60;
        tb_if.select_b         <= 7'd0; // Only write to Block 0 
        tb_if.mux_index        <= 7'd0;
        tb_if.write_from       <= 2'd0;
        tb_if.audio_out_enable <= 1'b0;
        tb_if.audio_out_lr     <= 1'b0;
        tb_if.ram_out          <= 32'd0;
        tb_if.ram_we           <= 1'b1;
        tb_if.ram_addr         <= 32'd1000;

        @(posedge tb_if.clk);
        tb_if.we_b             <= 1'b0;
        tb_if.addr_b           <= 10'b0;
        tb_if.select_b         <= broadcast;
        tb_if.mux_index        <= 7'd0;
        tb_if.ram_out          <= {16'd11, 16'd4};
        tb_if.ram_we           <= 1'b0;
        tb_if.ram_addr         <= 32'd0;

        @(posedge tb_if.clk);

        // TEST Double Read Mode
        $display("[TEST] Audio Out");
        
        // Audio Out from address 60 to Right
        @(posedge tb_if.clk);
        tb_if.enable           <= 1'b1;
        tb_if.mode             <= DOUBLE_READ;
        tb_if.we_a             <= 1'b0;
        tb_if.addr_a           <= 10'd60;
        tb_if.select_a         <= broadcast;
        tb_if.we_b             <= 1'b0;
        tb_if.addr_b           <= 10'd0;
        tb_if.select_b         <= broadcast;
        tb_if.mux_index        <= 7'd0;
        tb_if.audio_out_enable <= 1'b1;
        tb_if.audio_out_lr     <= 1'b1;
        tb_if.write_from       <= 2'd0;
        tb_if.ram_out          <= 32'd0;

        @(posedge tb_if.clk);
        tb_if.addr_a           <= 10'd0;
        tb_if.mux_index        <= 7'd0;
        tb_if.audio_out_enable <= 1'b0;
        tb_if.audio_out_lr     <= 1'b0;

        repeat(3) @(posedge tb_if.clk);

        $finish;
    end

    // Assertions
    initial begin
        $monitor("Time=%0t | Config=%s | Out Enable=%b | AudioOut=%h | LROut=%b", 
                 $time, tb_if.mode.name(), tb_if.enable_out, tb_if.audio_out, tb_if.lr_out);
    end

endmodule