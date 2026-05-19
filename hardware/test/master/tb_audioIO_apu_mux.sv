`timescale 1ns / 1ps

module tb_audioIO_apu_mux;

    // ---------------------------------------------------------
    // Parameters and Signal Declarations
    // ---------------------------------------------------------
    localparam logic [31:0] BASE_ADDR = 32'h00008000;

    // Inputs to DUT
    logic [31:0] audioIO_addr;
    logic [31:0] audioIO_data_in;
    logic        audioIO_ena;
    logic        audioIO_wea;

    logic [31:0] apu_addr;
    logic        apu_ena;

    logic [31:0] data_mem_data_in;

    // Outputs from DUT
    logic [31:0] apu_data_out;
    logic [31:0] data_mem_addr;
    logic [31:0] data_mem_data_out;
    logic        data_mem_ena;
    logic [3:0]  data_mem_wea;

    // ---------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // Note: Most modern simulators allow seamless mixed-language 
    // instantiation (SV testbench wrapping a VHDL module).
    // ---------------------------------------------------------
    audio_ram_mux #(
        .C_WORD_BASE_ADDR(BASE_ADDR)
    ) dut (
        .audioIO_addr      (audioIO_addr),
        .audioIO_data_in   (audioIO_data_in),
        .audioIO_ena       (audioIO_ena),
        .audioIO_wea       (audioIO_wea),
        
        .apu_addr          (apu_addr),
        .apu_data_out      (apu_data_out),
        .apu_ena           (apu_ena),
        
        .data_mem_addr     (data_mem_addr),
        .data_mem_data_out (data_mem_data_out),
        .data_mem_ena      (data_mem_ena),
        .data_mem_wea      (data_mem_wea),
        .data_mem_data_in  (data_mem_data_in)
    );

    initial begin
        $display("Starting audio_ram_mux tests");

        //init
        audioIO_addr     = 32'h0;
        audioIO_data_in  = 32'h0;
        audioIO_ena      = 1'b0;
        audioIO_wea      = 1'b0;
        apu_addr         = 32'h0;
        apu_ena          = 1'b0;
        data_mem_data_in = 32'h0;

        #10;

        //audioIO active
        audioIO_addr     = 32'h00008010;
        audioIO_data_in  = 32'hDEADBEEF;
        audioIO_ena      = 1'b1;
        audioIO_wea      = 1'b1;
        apu_addr         = 32'h00009000; // Set APU signals to ensure they are ignored
        apu_ena          = 1'b1;          
        data_mem_data_in = 32'hCAFEBABE; // Read data coming back from RAM
        
        #10;


        assert(data_mem_addr === (32'h00008010 - BASE_ADDR)) else $error("TC1 Failed: data_mem_addr incorrect");
        assert(data_mem_data_out === 32'hDEADBEEF)           else $error("TC1 Failed: data_mem_data_out incorrect");
        assert(data_mem_ena === 1'b1)                        else $error("TC1 Failed: data_mem_ena should be 1");
        assert(data_mem_wea === 4'b1111)                     else $error("TC1 Failed: data_mem_wea didn't replicate bit");
        assert(apu_data_out === 32'hCAFEBABE)                else $error("TC1 Failed: apu_data_out routing incorrect");

        //apu is active audioIO not
        audioIO_ena      = 1'b0; 
        audioIO_wea      = 1'b0; // Should now be ignored
        apu_addr         = 32'h00008020;
        apu_ena          = 1'b1;
        
        #10;

        // Assertions
        assert(data_mem_addr === (32'h00008020 - BASE_ADDR)) else $error("TC2 Failed: data_mem_addr incorrect");
        assert(data_mem_data_out === 32'h00000000)           else $error("TC2 Failed: data_mem_data_out should be 0");
        assert(data_mem_ena === 1'b1)                        else $error("TC2 Failed: data_mem_ena should mirror apu_ena");
        assert(data_mem_wea === 4'b0000)                     else $error("TC2 Failed: data_mem_wea should be 0");

        //both active
        audioIO_ena      = 1'b0;
        apu_ena          = 1'b0;
        apu_addr         = 32'h00008005;
        
        #10;

        assert(data_mem_addr === (32'h00008005 - BASE_ADDR)) else $error("TC3 Failed: data_mem_addr incorrect");
        assert(data_mem_ena === 1'b0)                        else $error("TC3 Failed: data_mem_ena should mirror apu_ena (0)");
        assert(data_mem_wea === 4'b0000)                     else $error("TC3 Failed: data_mem_wea should be 0");

        //end
        $display("COMPLETED");
        $finish;
    end

endmodule