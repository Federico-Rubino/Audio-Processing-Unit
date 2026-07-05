# Example: AUDIO_IN -> VOLUME_UP(macro) -> AUDIO_OUT. Not a useful effect as
# written (see note on MUL_SCALAR below) -- just an example of a macro
# wrapping a vector*scalar op, reused across the buffer it operates on.
#
# Every field below, including scalar_parameter, is a param-table offset,
# not a literal value -- see isa.yaml's top-of-file note. Firmware must
# call apu_load_param() for each offset, for both channels, before running
# this shader. Assemble with --emit-params to get volume_up.h instead of
# hardcoding these offsets.

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
        scalar_parameter=gain
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
