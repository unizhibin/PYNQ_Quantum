# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox
  ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}

  ipgui::add_param $IPINST -name "C_CLK_FREQENCY" -widget comboBox
  ipgui::add_param $IPINST -name "C_SCLK_FREQUENCY" -widget comboBox
  ipgui::add_param $IPINST -name "C_NUMBER_SCLK"
  ipgui::add_param $IPINST -name "C_CIC_output_bitwidth"
  ipgui::add_param $IPINST -name "C_CIC_buffer_depth"
  ipgui::add_param $IPINST -name "C_CIC_voltage_level"

}

proc update_PARAM_VALUE.C_CIC_buffer_depth { PARAM_VALUE.C_CIC_buffer_depth } {
	# Procedure called to update C_CIC_buffer_depth when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CIC_buffer_depth { PARAM_VALUE.C_CIC_buffer_depth } {
	# Procedure called to validate C_CIC_buffer_depth
	return true
}

proc update_PARAM_VALUE.C_CIC_output_bitwidth { PARAM_VALUE.C_CIC_output_bitwidth } {
	# Procedure called to update C_CIC_output_bitwidth when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CIC_output_bitwidth { PARAM_VALUE.C_CIC_output_bitwidth } {
	# Procedure called to validate C_CIC_output_bitwidth
	return true
}

proc update_PARAM_VALUE.C_CIC_voltage_level { PARAM_VALUE.C_CIC_voltage_level } {
	# Procedure called to update C_CIC_voltage_level when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CIC_voltage_level { PARAM_VALUE.C_CIC_voltage_level } {
	# Procedure called to validate C_CIC_voltage_level
	return true
}

proc update_PARAM_VALUE.C_CLK_FREQENCY { PARAM_VALUE.C_CLK_FREQENCY } {
	# Procedure called to update C_CLK_FREQENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_CLK_FREQENCY { PARAM_VALUE.C_CLK_FREQENCY } {
	# Procedure called to validate C_CLK_FREQENCY
	return true
}

proc update_PARAM_VALUE.C_NUMBER_SCLK { PARAM_VALUE.C_NUMBER_SCLK } {
	# Procedure called to update C_NUMBER_SCLK when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_NUMBER_SCLK { PARAM_VALUE.C_NUMBER_SCLK } {
	# Procedure called to validate C_NUMBER_SCLK
	return true
}

proc update_PARAM_VALUE.C_SCLK_FREQUENCY { PARAM_VALUE.C_SCLK_FREQUENCY } {
	# Procedure called to update C_SCLK_FREQUENCY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_SCLK_FREQUENCY { PARAM_VALUE.C_SCLK_FREQUENCY } {
	# Procedure called to validate C_SCLK_FREQUENCY
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_CLK_FREQENCY { MODELPARAM_VALUE.C_CLK_FREQENCY PARAM_VALUE.C_CLK_FREQENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CLK_FREQENCY}] ${MODELPARAM_VALUE.C_CLK_FREQENCY}
}

proc update_MODELPARAM_VALUE.C_SCLK_FREQUENCY { MODELPARAM_VALUE.C_SCLK_FREQUENCY PARAM_VALUE.C_SCLK_FREQUENCY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_SCLK_FREQUENCY}] ${MODELPARAM_VALUE.C_SCLK_FREQUENCY}
}

proc update_MODELPARAM_VALUE.C_NUMBER_SCLK { MODELPARAM_VALUE.C_NUMBER_SCLK PARAM_VALUE.C_NUMBER_SCLK } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUMBER_SCLK}] ${MODELPARAM_VALUE.C_NUMBER_SCLK}
}

proc update_MODELPARAM_VALUE.C_CIC_output_bitwidth { MODELPARAM_VALUE.C_CIC_output_bitwidth PARAM_VALUE.C_CIC_output_bitwidth } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CIC_output_bitwidth}] ${MODELPARAM_VALUE.C_CIC_output_bitwidth}
}

proc update_MODELPARAM_VALUE.C_CIC_buffer_depth { MODELPARAM_VALUE.C_CIC_buffer_depth PARAM_VALUE.C_CIC_buffer_depth } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CIC_buffer_depth}] ${MODELPARAM_VALUE.C_CIC_buffer_depth}
}

proc update_MODELPARAM_VALUE.C_CIC_voltage_level { MODELPARAM_VALUE.C_CIC_voltage_level PARAM_VALUE.C_CIC_voltage_level } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_CIC_voltage_level}] ${MODELPARAM_VALUE.C_CIC_voltage_level}
}

