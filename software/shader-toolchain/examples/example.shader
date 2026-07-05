# Example APU shader: pull a 256-sample grain in, scale it, mark end of program.

.define LEFT_START 0
.define LEFT_LEN   256

.macro SCALE(buf, len)
    ADD_SCALAR {
        output_buffer_start_reg=buf
        output_buffer_length_reg=len
        output_operation_start_reg=0
        scalar_parameter=0x1
        input_buffer_1_start_reg=buf
        input_buffer_1_length_reg=len
        input_operation_1_start_reg=0
        operation_length_reg=len
    }
.endmacro

AUDIO_IN {
    buffer_start_reg=LEFT_START
    buffer_length_reg=LEFT_LEN
    operation_start_reg=0
    operation_length_reg=LEFT_LEN
}
SCALE(LEFT_START, LEFT_LEN)
STOP
