# Captures live audio into a scratch row for AmpMod's modulator multiply

.param AM_IN_START
.param AM_IN_LEN

AUDIO_IN {
    buffer_start_reg=AM_IN_START
    buffer_length_reg=AM_IN_LEN
    operation_start_reg=AM_IN_START
    operation_length_reg=AM_IN_LEN
}

STOP
