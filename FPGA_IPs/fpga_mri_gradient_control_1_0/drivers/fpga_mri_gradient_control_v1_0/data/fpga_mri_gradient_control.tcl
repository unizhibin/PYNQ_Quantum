

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "fpga_mri_gradient_control" "NUM_INSTANCES" "DEVICE_ID"  "C_S00_AXI_BASEADDR" "C_S00_AXI_HIGHADDR"
}
