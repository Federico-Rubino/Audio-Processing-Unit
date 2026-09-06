# out = in * V_VOLUME (Q8.8), in-place -- backs Passthrough mode

.param V_IN_START
.param V_GRAIN_LEN
.param V_OP_LEN
.param V_VOLUME

AUDIO_IN {
    buffer_start_reg=V_IN_START
    buffer_length_reg=V_GRAIN_LEN
    operation_start_reg=V_IN_START
    operation_length_reg=V_OP_LEN
}

MUL_SCALAR {
    output_buffer_start_reg=V_IN_START
    output_buffer_length_reg=V_GRAIN_LEN
    output_operation_start_reg=V_IN_START
    scalar_parameter_reg=V_VOLUME
    input_buffer_1_start_reg=V_IN_START
    input_buffer_1_length_reg=V_GRAIN_LEN
    input_operation_1_start_reg=V_IN_START
    operation_length_reg=V_OP_LEN
}

AUDIO_OUT {
    buffer_start_reg=V_IN_START
    buffer_length_reg=V_GRAIN_LEN
    operation_start_reg=V_IN_START
    operation_length_reg=V_OP_LEN
}

STOP
