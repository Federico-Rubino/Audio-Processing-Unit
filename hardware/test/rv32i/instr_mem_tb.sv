`timescale 1ns / 1ps

module instr_mem_tb;

    logic clk;
    always #5 clk = ~clk;

    //BRAM
    logic [31:0] pc;         
    logic [31:0] instr_out;   
    logic ena;

    instruction_memory instr_mem_inst (
        .clka(clk),
        .ena(ena),
        .addra(pc[31:2]),  
        .douta(instr_out)
    );

    // test
    initial begin
        clk = 0;
        pc = 0;
        ena = 1;

        #10;

        repeat (6) begin
            $display("PC=%0d instr=%h", pc, instr_out);
            #10; 
            pc = pc + 4; 
        end

        $display("FINE TEST BRAM");
        $finish;
    end

endmodule