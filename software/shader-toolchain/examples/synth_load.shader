# Copies the CPU-computed grain (param offsets 0-127) into a fixed a-ram row via LOAD

.param S_WAVE_START
.param S_WAVE_LEN
.param S_OP_START
.param S_OP_LEN

LOAD {
    buffer_start_reg=S_WAVE_START
    buffer_length_reg=S_WAVE_LEN
    operation_start_reg=S_OP_START
    operation_length_reg=S_OP_LEN
}

STOP
