# Feedback delay: out = in + feedback * delayline, written back in place

.param D_IN_START
.param D_LEN
.param D_TEMP_START
.param D_DELAY_START
.param D_FEEDBACK
.param D_OUT_START
.param D_VOLUME

AUDIO_IN {
    buffer_start_reg=D_IN_START
    buffer_length_reg=D_LEN
    operation_start_reg=D_IN_START
    operation_length_reg=D_LEN
}

# temp = delayline * feedback
MUL_SCALAR {
    output_buffer_start_reg=D_TEMP_START
    output_buffer_length_reg=D_LEN
    output_operation_start_reg=D_TEMP_START
    scalar_parameter_reg=D_FEEDBACK
    input_buffer_1_start_reg=D_DELAY_START
    input_buffer_1_length_reg=D_LEN
    input_operation_1_start_reg=D_DELAY_START
    operation_length_reg=D_LEN
}

# delayline = in + temp
ADD_VEC {
    output_buffer_start_reg=D_DELAY_START
    output_buffer_length_reg=D_LEN
    output_operation_start_reg=D_DELAY_START
    input_buffer_2_start_reg=D_TEMP_START
    input_buffer_2_length_reg=D_LEN
    input_operation_2_start_reg=D_TEMP_START
    input_buffer_1_start_reg=D_IN_START
    input_buffer_1_length_reg=D_LEN
    input_operation_1_start_reg=D_IN_START
    operation_length_reg=D_LEN
}

# out = delayline * volume, kept separate from D_DELAY_START so scaling doesn't compound through the feedback loop
MUL_SCALAR {
    output_buffer_start_reg=D_OUT_START
    output_buffer_length_reg=D_LEN
    output_operation_start_reg=D_OUT_START
    scalar_parameter_reg=D_VOLUME
    input_buffer_1_start_reg=D_DELAY_START
    input_buffer_1_length_reg=D_LEN
    input_operation_1_start_reg=D_DELAY_START
    operation_length_reg=D_LEN
}

AUDIO_OUT {
    buffer_start_reg=D_OUT_START
    buffer_length_reg=D_LEN
    operation_start_reg=D_OUT_START
    operation_length_reg=D_LEN
}

STOP
