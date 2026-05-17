package apu_pkg;
    // The following definitions must match the VHDL definitions

    typedef enum logic [3:0] {
        APU_OP_COPY      = 4'b0000,
        APU_OP_AUDIO_OUT = 4'b0001
    } apu_opcode_t;

    typedef enum logic [1:0] {
        DOUBLE_READ  = 2'b00,
        MIXED        = 2'b01,
        DOUBLE_WRITE = 2'b10
    } datapath_config_t;
    
endpackage