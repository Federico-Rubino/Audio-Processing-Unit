# Copies the CPU-computed modulator wave (param offsets 0-127) into a fixed a-ram row via LOAD

.param AM_MOD_WAVE_START
.param AM_MOD_WAVE_LEN
.param AM_MOD_OP_START
.param AM_MOD_OP_LEN

LOAD {
    buffer_start_reg=AM_MOD_WAVE_START
    buffer_length_reg=AM_MOD_WAVE_LEN
    operation_start_reg=AM_MOD_OP_START
    operation_length_reg=AM_MOD_OP_LEN
}

STOP
