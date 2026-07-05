# Passthrough shader: copy a 256-sample grain in from AUDIO_IN into a-ram,
# then immediately copy the same buffer back out via AUDIO_OUT. No
# processing in between -- just moves the grain through.
#
# buffer_start_reg/buffer_length_reg/operation_start_reg/operation_length_reg
# are param-table offsets (see isa.yaml's top-of-file note), not literal
# values -- firmware must call apu_load_param() for each offset below,
# for both channels, before running this shader. Assemble with
# --emit-params to get passthrough.h instead of hardcoding these offsets.

.param GRAIN_START
.param GRAIN_LEN
.param OP_START
.param OP_LEN

AUDIO_IN {
    buffer_start_reg=GRAIN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

AUDIO_OUT {
    buffer_start_reg=GRAIN_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=OP_START
    operation_length_reg=OP_LEN
}

STOP
