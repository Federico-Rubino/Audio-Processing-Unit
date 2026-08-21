# ADD_SCALAR/SUB_SCALAR round-trip test: y = in + C, z = y - C = in.


.param IN_START
.param GRAIN_LEN
.param OP_START
.param OP_LEN
.param MID_START
.param OUT_START
.param C_POS

AUDIO_IN {
    buffer_start_reg=IN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

# mid = in + C
ADD_SCALAR {
    output_buffer_start_reg=MID_START
    output_buffer_length_reg=GRAIN_LEN
    output_operation_start_reg=OP_START
    scalar_parameter_reg=C_POS
    input_buffer_1_start_reg=IN_START
    input_buffer_1_length_reg=GRAIN_LEN
    input_operation_1_start_reg=OP_START
    operation_length_reg=OP_LEN
}

# out = mid - C = in
SUB_SCALAR {
    output_buffer_start_reg=OUT_START
    output_buffer_length_reg=GRAIN_LEN
    output_operation_start_reg=OP_START
    scalar_parameter_reg=C_POS
    input_buffer_1_start_reg=MID_START
    input_buffer_1_length_reg=GRAIN_LEN
    input_operation_1_start_reg=OP_START
    operation_length_reg=OP_LEN
}

AUDIO_OUT {
    buffer_start_reg=OUT_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

STOP
