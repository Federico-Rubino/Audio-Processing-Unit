`timescale 1ns / 1ps

module instr_mem_tb;

    // clock
    logic clk;
    always #5 clk = ~clk; // 100 MHz approx

    // segnali per la BRAM
    logic [31:0] pc;          // indirizzo
    logic [31:0] instr_out;   // dato letto
    logic ena;

    // istanza della BRAM
    instruction_memory instr_mem_inst (
        .clka(clk),
        .ena(ena),
        .addra(pc[31:2]),   // PC in byte -> parola
        .douta(instr_out)
    );

    // test
    initial begin
        clk = 0;
        pc = 0;
        ena = 1;

        #10;

        // stampiamo le prime 6 istruzioni
        repeat (6) begin
            $display("PC=%0d instr=%h", pc, instr_out);
            #10; // un ciclo per leggere
            pc = pc + 4; // passa alla parola successiva
        end

        $display("FINE TEST BRAM");
        $finish;
    end

endmodule