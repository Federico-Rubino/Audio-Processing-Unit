# ADD_VEC isolation test: out = in + in, i.e. exactly 2x the input.
#
# This deliberately touches nothing the reverb shader does (no MUL_SCALAR,
# no ring buffer, no decay) -- it's meant to answer one question in
# isolation: is ADD_VEC itself correct?
#
# Expected result: audibly identical to plain passthrough, just louder
# (+6dB), same waveform/timbre, no crackle or noise. If it sounds garbled
# or noisy instead of cleanly louder, ADD_VEC (or its BMU/DSP pipeline) is
# the broken piece -- not the reverb's ring/decay logic.
#
# Caveat: keep the input quiet (soft voice / low mic gain). Doubling
# amplitude will clip a loud signal for real -- that's expected saturation,
# not a bug, so don't mistake it for one.

.param IN_START
.param GRAIN_LEN
.param OP_START
.param OP_LEN
.param OUT_START

AUDIO_IN {
    buffer_start_reg=IN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

# out = in + in
ADD_VEC {
    output_buffer_start_reg=OUT_START
    output_buffer_length_reg=GRAIN_LEN
    output_operation_start_reg=OP_START
    input_buffer_2_start_reg=IN_START
    input_buffer_2_length_reg=GRAIN_LEN
    input_operation_2_start_reg=OP_START
    input_buffer_1_start_reg=IN_START
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
