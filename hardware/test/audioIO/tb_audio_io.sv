`timescale 1ns / 1ps

module tb_audioIO();

    // --- Clock and Reset ---
    logic clk = 0;
    logic rst;

    // --- Debug/Sample Injection Ports ---
    logic        tb_new_sample;
    logic [15:0] tb_line_in_l;
    logic [15:0] tb_line_in_r;

    // --- Memory Interface ---
    logic [31:0] data_mem_addr;
    logic [31:0] data_mem_data_out;
    logic        data_mem_ena;
    logic        data_mem_wea;

    // --- Register Interface ---
    logic [1:0]  next_ctrl_reg = 0;
    logic [31:0] next_start_addr_reg = 0;
    logic [31:0] next_offset_reg = 0;
    logic [18:0] status_reg;

    // --- Fake BRAM ---
    logic [31:0] fake_bram [logic [31:0]];

    // 100MHz clock
    always #5 clk = ~clk;

    // --- DUT Instance ---
    audioIO dut (
        .clk(clk),
        .rst(rst),
        .new_sample(tb_new_sample),
        .line_in_l(tb_line_in_l),
        .line_in_r(tb_line_in_r),
        .data_mem_addr(data_mem_addr),
        .data_mem_data_out(data_mem_data_out),
        .data_mem_ena(data_mem_ena),
        .data_mem_wea(data_mem_wea),
        .next_ctrl_reg(next_ctrl_reg),
        .next_start_addr_reg(next_start_addr_reg),
        .next_offset_reg(next_offset_reg),
        .status_reg(status_reg)
    );

    // --- Fake BRAM Write Logic ---
    always @(posedge clk) begin
        if (data_mem_ena && data_mem_wea) begin
            fake_bram[data_mem_addr] = data_mem_data_out;
            $display("WRITE -> Addr: 0x%h | Data: 0x%h",data_mem_addr, data_mem_data_out);
        end
    end

    //sample Injector (48kHz)
    initial begin
        logic [15:0] count_l = 16'h1000;
        logic [15:0] count_r = 16'hE000;
        tb_new_sample = 0;
        tb_line_in_l  = 0;
        tb_line_in_r  = 0;
        
        forever begin
            repeat (2083) @(posedge clk);
            tb_new_sample = 1;
            tb_line_in_l  = count_l++;
            tb_line_in_r  = count_r++;
            @(posedge clk);
            tb_new_sample = 0;
        end
    end


    task copy_action(input [31:0] addr, input [31:0] offset, input [1:0] ctrl, input string label);
    begin
        @(posedge clk);
        next_start_addr_reg = addr;
        next_offset_reg     = offset;
        next_ctrl_reg       = ctrl; 
        
        @(posedge clk);
        next_ctrl_reg       = 2'b00; //start command
        
        //wait fsm start
        fork
            begin
                wait(status_reg[0] == 1'b0);
            end
            begin
                repeat(10) @(posedge clk); //10-cycle timeout
            end
        join_any
        disable fork; 
        
        //fsm to finish
        wait(status_reg[0] == 1'b1); 
        
        repeat(2) @(posedge clk); // Delay to align logs
        $display("%s Complete", label);
    end
    endtask


    initial begin
        logic [7:0] avail_l;
        logic [7:0] avail_r;

        rst = 1; #100; rst = 0;
        repeat (50 * 2083) @(posedge clk);
        

        $display(" TEST 1: DYNAMIC OCCUPANCY COPY");;

        // READ LEFT force to even number
        avail_l = status_reg[10:3] & 8'hFE; 
        $display("Triggering Left Copy for %0d samples", avail_l);
        copy_action(32'h0100, {24'b0, avail_l}, 2'b01, "DYNAMIC LEFT");

        #500; 

        // READ RIGHT
        avail_r = status_reg[18:11] & 8'hFE;
        $display("-> Triggering Right Copy for %0d samples", avail_r);
        copy_action(32'h0200, {24'b0, avail_r}, 2'b11, "DYNAMIC RIGHT");

        #2000; 
        
        $display(" TEST 2:CONTINUITY");

        
        repeat (15 * 2083) @(posedge clk);

        copy_action(32'h0300, 32'd4, 2'b01, "LEFT B2B Round 1");
        
        @(posedge clk); 
        
        copy_action(32'h0302, 32'd4, 2'b11, "RIGHT B2B Round 2"); 

        #1000;
        $display("Simulation Finished");
        #50
        $finish;
    end

endmodule