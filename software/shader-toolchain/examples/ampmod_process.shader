# out = audio * modulator, in-place, then AUDIO_OUT

.param AM_AUDIO_START
.param AM_GRAIN_LEN
.param AM_OP_LEN
.param AM_MOD_START

MUL_VECTOR {
    output_buffer_start_reg=AM_AUDIO_START
    output_buffer_length_reg=AM_GRAIN_LEN
    output_operation_start_reg=AM_AUDIO_START
    input_buffer_2_start_reg=AM_MOD_START
    input_buffer_2_length_reg=AM_GRAIN_LEN
    input_operation_2_start_reg=AM_MOD_START
    input_buffer_1_start_reg=AM_AUDIO_START
    input_buffer_1_length_reg=AM_GRAIN_LEN
    input_operation_1_start_reg=AM_AUDIO_START
    operation_length_reg=AM_OP_LEN
}

AUDIO_OUT {
    buffer_start_reg=AM_AUDIO_START
    buffer_length_reg=AM_GRAIN_LEN
    operation_start_reg=AM_AUDIO_START
    operation_length_reg=AM_OP_LEN
}

STOP
