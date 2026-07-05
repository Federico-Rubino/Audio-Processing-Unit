# Volume control shader example

.define BUF_START 0
.define GRAIN_LEN  256
.define GAIN       0x2   # toy gain factor, exact scalar_parameter scaling is TBD in hardware

.macro VOLUME_UP(buf, len, gain)
    MUL_SCALAR {
        output_buffer_start_reg=buf
        output_buffer_length_reg=len
        output_operation_start_reg=0
        scalar_parameter=gain
        input_buffer_1_start_reg=buf
        input_buffer_1_length_reg=len
        input_operation_1_start_reg=0
        operation_length_reg=len
    }
.endmacro

AUDIO_IN {
    buffer_start_reg=BUF_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=0
    operation_length_reg=GRAIN_LEN
}

VOLUME_UP(BUF_START, GRAIN_LEN, GAIN)

AUDIO_OUT {
    buffer_start_reg=BUF_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=0
    operation_length_reg=GRAIN_LEN
}

STOP
