# Example: AUDIO_IN -> VOLUME_UP(macro) -> AUDIO_OUT


.param GRAIN_START
.param GRAIN_LEN
.param OP_START
.param OP_LEN
.param GAIN

.macro VOLUME_UP(buf, len, op_start, op_len, gain)
    MUL_SCALAR {
        output_buffer_start_reg=buf
        output_buffer_length_reg=len
        output_operation_start_reg=op_start
        scalar_parameter_reg=gain
        input_buffer_1_start_reg=buf
        input_buffer_1_length_reg=len
        input_operation_1_start_reg=op_start
        operation_length_reg=op_len
    }
.endmacro

AUDIO_IN {
    buffer_start_reg=GRAIN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

VOLUME_UP(GRAIN_START, GRAIN_LEN, OP_START, OP_LEN, GAIN)

AUDIO_OUT {
    buffer_start_reg=GRAIN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

STOP
