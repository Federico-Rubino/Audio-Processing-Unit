`timescale 1ns / 1ps

module uart_axi_tb;

    // System Signals
    logic clk;
    logic rst; 
    logic [1023:0] debug_regs;

    // UART Timing Calculation
    parameter CLK_FREQ  = 100_000_000; // 100 MHz clock
    parameter BAUD_RATE = 115200;      
    localparam integer BIT_PERIOD = 1_000_000_000 / BAUD_RATE; 

    wire uart_tx; 
    wire uart_rx = 1'b1; // Idle state

    //activity for timeout
    realtime last_activity_time = 0;

    // Register mapping for debug
    wire [31:0] x1  = debug_regs[63:32];

    // UART Decoder Task
    task uart_monitor();
        integer i;
        logic [7:0] char;
        begin
            @(negedge uart_tx);        
            last_activity_time = $realtime; // Record time of activity
            #(BIT_PERIOD * 1.5);       
            
            for (i = 0; i < 8; i = i + 1) begin
                char[i] = uart_tx;
                #(BIT_PERIOD);         
            end
            
            $write("%c", char);        
            $fflush();
            last_activity_time = $realtime; // Update after full byte
        end
    endtask

    top_module_wrapper uut (
        .sys_clk(clk),
        .sys_rst(rst),        
        .debugs_register(debug_regs),
        .uart_rtl_0_txd(uart_tx), 
        .uart_rtl_0_rxd(uart_rx)
    );

    always #5 clk = ~clk; 

    initial forever uart_monitor();

    initial begin
        clk = 0;
        rst = 1;
        last_activity_time = 0;

        $display("--- Starting UART Simulation ---");
        #100 rst = 0;

        fork
            // Watchdog 1ms
            begin
                forever begin
                    #100000; //100us
                    if (last_activity_time > 0 && ($realtime - last_activity_time) > 1000000) begin
                        $display("\n[Status] UART idle for 1ms. Ending simulation.");
                        $finish;
                    end
                end
            end


            begin
                #5000000; // 5ms
                $display("\n[Error] Hard Timeout reached.");
                $finish;
            end
        join_any
    end

endmodule