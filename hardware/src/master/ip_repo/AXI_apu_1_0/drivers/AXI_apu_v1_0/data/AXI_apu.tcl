

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "AXI_apu" "NUM_INSTANCES" "DEVICE_ID"  "C_S00_APU_AXI_BASEADDR" "C_S00_APU_AXI_HIGHADDR"
}
