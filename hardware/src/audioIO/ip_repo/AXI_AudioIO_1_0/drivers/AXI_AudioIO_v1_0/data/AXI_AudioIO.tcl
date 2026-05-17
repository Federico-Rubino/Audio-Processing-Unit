

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "AXI_AudioIO" "NUM_INSTANCES" "DEVICE_ID"  "C_S00_AXI_AudioIO_BASEADDR" "C_S00_AXI_AudioIO_HIGHADDR"
}
