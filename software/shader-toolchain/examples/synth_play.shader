# Plays back the row synth_load.shader just wrote

.param S_PLAY_START
.param S_PLAY_LEN

AUDIO_OUT {
    buffer_start_reg=S_PLAY_START
    buffer_length_reg=S_PLAY_LEN
    operation_start_reg=S_PLAY_START
    operation_length_reg=S_PLAY_LEN
}

STOP
