# Throwaway AUDIO_IN to drain the grain-arrival pulse; must stay non-LOAD or LOAD's right-channel skip leaves grain_ready_r stuck latched

.param S_DRAIN_START
.param S_DRAIN_LEN

AUDIO_IN {
    buffer_start_reg=S_DRAIN_START
    buffer_length_reg=S_DRAIN_LEN
    operation_start_reg=S_DRAIN_START
    operation_length_reg=S_DRAIN_LEN
}

STOP
