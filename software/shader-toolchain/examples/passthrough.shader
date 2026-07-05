# Passthrough shader: copy a 256-sample grain in from AUDIO_IN into a-ram,
# then immediately copy the same buffer back out via AUDIO_OUT. No
# processing in between -- just moves the grain through.

.define BUF_START 0
.define GRAIN_LEN  256

AUDIO_IN {
    buffer_start_reg=BUF_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=0
    operation_length_reg=GRAIN_LEN
}

AUDIO_OUT {
    buffer_start_reg=BUF_START
    buffer_length_reg=GRAIN_LEN
    operation_start_reg=0
    operation_length_reg=GRAIN_LEN
}

STOP
