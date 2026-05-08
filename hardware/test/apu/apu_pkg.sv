package apu_pkg;
    // The following definitions must match the VHDL definitions
    typedef logic [3:0] apu_opcode_t;

    localparam apu_opcode_t APU_OP_COPY      = 4'b0000;
    localparam apu_opcode_t APU_OP_AUDIO_OUT = 4'b0001;
endpackage