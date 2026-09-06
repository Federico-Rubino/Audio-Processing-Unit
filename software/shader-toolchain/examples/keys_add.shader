# accumulator += temp, via ADD_VEC -- run once per additional held note

.param K_ACC_START
.param K_ACC_LEN
.param K_TEMP_START

ADD_VEC {
    output_buffer_start_reg=K_ACC_START
    output_buffer_length_reg=K_ACC_LEN
    output_operation_start_reg=K_ACC_START
    input_buffer_2_start_reg=K_TEMP_START
    input_buffer_2_length_reg=K_ACC_LEN
    input_operation_2_start_reg=K_TEMP_START
    input_buffer_1_start_reg=K_ACC_START
    input_buffer_1_length_reg=K_ACC_LEN
    input_operation_1_start_reg=K_ACC_START
    operation_length_reg=K_ACC_LEN
}

STOP
