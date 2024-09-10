
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/power_usage_monitor_v1_1.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Configurable Parameters}]
  set_property tooltip {Parameters configurable by the user} ${Page_0}
  set CLK_FREQ [ipgui::add_param $IPINST -name "CLK_FREQ" -parent ${Page_0}]
  set_property tooltip {Indicate the system clock frequency in MHz (is the clock in sync with the probes)} ${CLK_FREQ}
  #Adding Group
  set Power_Consumption_Settings [ipgui::add_group $IPINST -name "Power Consumption Settings" -parent ${Page_0} -display_name {Power Traces Settings}]
  set SCLK_FREQ [ipgui::add_param $IPINST -name "SCLK_FREQ" -parent ${Power_Consumption_Settings}]
  set_property tooltip {Desired SPI SCLK frequency in MHz (the system will set the closest possible below it)} ${SCLK_FREQ}
  set POWER_DEPTH [ipgui::add_param $IPINST -name "POWER_DEPTH" -parent ${Power_Consumption_Settings}]
  set_property tooltip {Number of power consumption samples to capture} ${POWER_DEPTH}
  set ADC_DUAL [ipgui::add_param $IPINST -name "ADC_DUAL" -parent ${Power_Consumption_Settings}]
  set_property tooltip {True: ADC working in dual-channel mode | False: ADC working in single-channel mode} ${ADC_DUAL}
  set ADC_VREF_IS_DOUBLE [ipgui::add_param $IPINST -name "ADC_VREF_IS_DOUBLE" -parent ${Power_Consumption_Settings}]
  set_property tooltip {True: VRef = 5.0 V | False: VRef = 2.5 V} ${ADC_VREF_IS_DOUBLE}

  #Adding Group
  set Performance_Traces_Settings [ipgui::add_group $IPINST -name "Performance Traces Settings" -parent ${Page_0}]
  set NUMBER_PROBES [ipgui::add_param $IPINST -name "NUMBER_PROBES" -parent ${Performance_Traces_Settings}]
  set_property tooltip {Number of 1-bit signals to monitor} ${NUMBER_PROBES}
  set COUNTER_BITS [ipgui::add_param $IPINST -name "COUNTER_BITS" -parent ${Performance_Traces_Settings} -widget comboBox]
  set_property tooltip {Number of bits used to generate the timestamps} ${COUNTER_BITS}
  set TRACES_DEPTH [ipgui::add_param $IPINST -name "TRACES_DEPTH" -parent ${Performance_Traces_Settings}]
  set_property tooltip {Number of performance traces samples to capture} ${TRACES_DEPTH}

  #Adding Group
  set AXI_Monitoring_Settings [ipgui::add_group $IPINST -name "AXI Monitoring Settings" -parent ${Page_0} -layout horizontal]
  set AXI_SNIFFER_ENABLE [ipgui::add_param $IPINST -name "AXI_SNIFFER_ENABLE" -parent ${AXI_Monitoring_Settings}]
  set_property tooltip {True: AXI bus monitoring enabled | False: AXI bus monitoring disabled} ${AXI_SNIFFER_ENABLE}
  set AXI_SNIFFER_DATA_WIDTH [ipgui::add_param $IPINST -name "AXI_SNIFFER_DATA_WIDTH" -parent ${AXI_Monitoring_Settings}]
  set_property tooltip {Number of bits monitored from the AXI Sniffer Bus} ${AXI_SNIFFER_DATA_WIDTH}


  #Adding Page
  set AXI_Buses_Information [ipgui::add_page $IPINST -name "AXI Buses Information"]
  set_property tooltip {Information about the AXI buses of the IP} ${AXI_Buses_Information}
  #Adding Group
  set Monitor_Control_(AXI_S00) [ipgui::add_group $IPINST -name "Monitor Control (AXI S00)" -parent ${AXI_Buses_Information} -layout horizontal]
  set C_S00_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Monitor_Control_(AXI_S00)}]
  set_property tooltip {Width of Control data bus} ${C_S00_AXI_DATA_WIDTH}
  set C_S00_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Monitor_Control_(AXI_S00)}]
  set_property tooltip {Width of Control address bus} ${C_S00_AXI_ADDR_WIDTH}

  #Adding Group
  set Power_Data_(AXI_S01) [ipgui::add_group $IPINST -name "Power Data (AXI S01)" -parent ${AXI_Buses_Information} -layout horizontal]
  set C_S01_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_DATA_WIDTH" -parent ${Power_Data_(AXI_S01)}]
  set_property tooltip {Width of Power data bus} ${C_S01_AXI_DATA_WIDTH}
  set C_S01_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S01_AXI_ADDR_WIDTH" -parent ${Power_Data_(AXI_S01)}]
  set_property tooltip {Width of Power address bus} ${C_S01_AXI_ADDR_WIDTH}

  #Adding Group
  set Traces_Data_(AXI_S02) [ipgui::add_group $IPINST -name "Traces Data (AXI S02)" -parent ${AXI_Buses_Information} -layout horizontal]
  set C_S02_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S02_AXI_DATA_WIDTH" -parent ${Traces_Data_(AXI_S02)}]
  set_property tooltip {Width of Traces data bus} ${C_S02_AXI_DATA_WIDTH}
  set C_S02_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S02_AXI_ADDR_WIDTH" -parent ${Traces_Data_(AXI_S02)}]
  set_property tooltip {Width of S_AXI address bus} ${C_S02_AXI_ADDR_WIDTH}


  set INTERRUPT_ENABLE [ipgui::add_param $IPINST -name "INTERRUPT_ENABLE"]
  set_property tooltip {True: Interrupt enabled | False: Interrupt disabled} ${INTERRUPT_ENABLE}

}

proc update_PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH { PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH PARAM_VALUE.AXI_SNIFFER_ENABLE } {
	# Procedure called to update AXI_SNIFFER_DATA_WIDTH when any of the dependent parameters in the arguments change
	
	set AXI_SNIFFER_DATA_WIDTH ${PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH}
	set AXI_SNIFFER_ENABLE ${PARAM_VALUE.AXI_SNIFFER_ENABLE}
	set values(AXI_SNIFFER_ENABLE) [get_property value $AXI_SNIFFER_ENABLE]
	set_property value [gen_USERPARAMETER_AXI_SNIFFER_DATA_WIDTH_VALUE $values(AXI_SNIFFER_ENABLE)] $AXI_SNIFFER_DATA_WIDTH
}

proc validate_PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH { PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH } {
	# Procedure called to validate AXI_SNIFFER_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_ADDR_WIDTH { PARAM_VALUE.C_S01_AXI_ADDR_WIDTH PARAM_VALUE.POWER_DEPTH PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
	# Procedure called to update C_S01_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
	
	set C_S01_AXI_ADDR_WIDTH ${PARAM_VALUE.C_S01_AXI_ADDR_WIDTH}
	set POWER_DEPTH ${PARAM_VALUE.POWER_DEPTH}
	set C_S01_AXI_DATA_WIDTH ${PARAM_VALUE.C_S01_AXI_DATA_WIDTH}
	set values(POWER_DEPTH) [get_property value $POWER_DEPTH]
	set values(C_S01_AXI_DATA_WIDTH) [get_property value $C_S01_AXI_DATA_WIDTH]
	set_property value [gen_USERPARAMETER_C_S01_AXI_ADDR_WIDTH_VALUE $values(POWER_DEPTH) $values(C_S01_AXI_DATA_WIDTH)] $C_S01_AXI_ADDR_WIDTH
}

proc validate_PARAM_VALUE.C_S01_AXI_ADDR_WIDTH { PARAM_VALUE.C_S01_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S01_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_ADDR_WIDTH { PARAM_VALUE.C_S02_AXI_ADDR_WIDTH PARAM_VALUE.TRACES_DEPTH PARAM_VALUE.C_S02_AXI_DATA_WIDTH } {
	# Procedure called to update C_S02_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
	
	set C_S02_AXI_ADDR_WIDTH ${PARAM_VALUE.C_S02_AXI_ADDR_WIDTH}
	set TRACES_DEPTH ${PARAM_VALUE.TRACES_DEPTH}
	set C_S02_AXI_DATA_WIDTH ${PARAM_VALUE.C_S02_AXI_DATA_WIDTH}
	set values(TRACES_DEPTH) [get_property value $TRACES_DEPTH]
	set values(C_S02_AXI_DATA_WIDTH) [get_property value $C_S02_AXI_DATA_WIDTH]
	set_property value [gen_USERPARAMETER_C_S02_AXI_ADDR_WIDTH_VALUE $values(TRACES_DEPTH) $values(C_S02_AXI_DATA_WIDTH)] $C_S02_AXI_ADDR_WIDTH
}

proc validate_PARAM_VALUE.C_S02_AXI_ADDR_WIDTH { PARAM_VALUE.C_S02_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S02_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_DATA_WIDTH { PARAM_VALUE.C_S02_AXI_DATA_WIDTH PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH PARAM_VALUE.NUMBER_PROBES PARAM_VALUE.COUNTER_BITS } {
	# Procedure called to update C_S02_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
	
	set C_S02_AXI_DATA_WIDTH ${PARAM_VALUE.C_S02_AXI_DATA_WIDTH}
	set AXI_SNIFFER_DATA_WIDTH ${PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH}
	set NUMBER_PROBES ${PARAM_VALUE.NUMBER_PROBES}
	set COUNTER_BITS ${PARAM_VALUE.COUNTER_BITS}
	set values(AXI_SNIFFER_DATA_WIDTH) [get_property value $AXI_SNIFFER_DATA_WIDTH]
	set values(NUMBER_PROBES) [get_property value $NUMBER_PROBES]
	set values(COUNTER_BITS) [get_property value $COUNTER_BITS]
	set_property value [gen_USERPARAMETER_C_S02_AXI_DATA_WIDTH_VALUE $values(AXI_SNIFFER_DATA_WIDTH) $values(NUMBER_PROBES) $values(COUNTER_BITS)] $C_S02_AXI_DATA_WIDTH
}

proc validate_PARAM_VALUE.C_S02_AXI_DATA_WIDTH { PARAM_VALUE.C_S02_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S02_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.ADC_DUAL { PARAM_VALUE.ADC_DUAL } {
	# Procedure called to update ADC_DUAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_DUAL { PARAM_VALUE.ADC_DUAL } {
	# Procedure called to validate ADC_DUAL
	return true
}

proc update_PARAM_VALUE.ADC_VREF_IS_DOUBLE { PARAM_VALUE.ADC_VREF_IS_DOUBLE } {
	# Procedure called to update ADC_VREF_IS_DOUBLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_VREF_IS_DOUBLE { PARAM_VALUE.ADC_VREF_IS_DOUBLE } {
	# Procedure called to validate ADC_VREF_IS_DOUBLE
	return true
}

proc update_PARAM_VALUE.AXI_SNIFFER_ENABLE { PARAM_VALUE.AXI_SNIFFER_ENABLE } {
	# Procedure called to update AXI_SNIFFER_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.AXI_SNIFFER_ENABLE { PARAM_VALUE.AXI_SNIFFER_ENABLE } {
	# Procedure called to validate AXI_SNIFFER_ENABLE
	return true
}

proc update_PARAM_VALUE.CLK_FREQ { PARAM_VALUE.CLK_FREQ } {
	# Procedure called to update CLK_FREQ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLK_FREQ { PARAM_VALUE.CLK_FREQ } {
	# Procedure called to validate CLK_FREQ
	return true
}

proc update_PARAM_VALUE.COUNTER_BITS { PARAM_VALUE.COUNTER_BITS } {
	# Procedure called to update COUNTER_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.COUNTER_BITS { PARAM_VALUE.COUNTER_BITS } {
	# Procedure called to validate COUNTER_BITS
	return true
}

proc update_PARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH { PARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH } {
	# Procedure called to update C_M_SNIFFER_OUT_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH { PARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_M_SNIFFER_OUT_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH { PARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH } {
	# Procedure called to update C_M_SNIFFER_OUT_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH { PARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH } {
	# Procedure called to validate C_M_SNIFFER_OUT_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_SNIFFER_IN_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_SNIFFER_IN_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH { PARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_SNIFFER_IN_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH { PARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_SNIFFER_IN_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.INTERRUPT_ENABLE { PARAM_VALUE.INTERRUPT_ENABLE } {
	# Procedure called to update INTERRUPT_ENABLE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INTERRUPT_ENABLE { PARAM_VALUE.INTERRUPT_ENABLE } {
	# Procedure called to validate INTERRUPT_ENABLE
	return true
}

proc update_PARAM_VALUE.NUMBER_PROBES { PARAM_VALUE.NUMBER_PROBES } {
	# Procedure called to update NUMBER_PROBES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NUMBER_PROBES { PARAM_VALUE.NUMBER_PROBES } {
	# Procedure called to validate NUMBER_PROBES
	return true
}

proc update_PARAM_VALUE.POWER_DEPTH { PARAM_VALUE.POWER_DEPTH } {
	# Procedure called to update POWER_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.POWER_DEPTH { PARAM_VALUE.POWER_DEPTH } {
	# Procedure called to validate POWER_DEPTH
	return true
}

proc update_PARAM_VALUE.SCLK_FREQ { PARAM_VALUE.SCLK_FREQ } {
	# Procedure called to update SCLK_FREQ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SCLK_FREQ { PARAM_VALUE.SCLK_FREQ } {
	# Procedure called to validate SCLK_FREQ
	return true
}

proc update_PARAM_VALUE.TRACES_DEPTH { PARAM_VALUE.TRACES_DEPTH } {
	# Procedure called to update TRACES_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TRACES_DEPTH { PARAM_VALUE.TRACES_DEPTH } {
	# Procedure called to validate TRACES_DEPTH
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

proc update_PARAM_VALUE.C_S01_AXI_ID_WIDTH { PARAM_VALUE.C_S01_AXI_ID_WIDTH } {
	# Procedure called to update C_S01_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_ID_WIDTH { PARAM_VALUE.C_S01_AXI_ID_WIDTH } {
	# Procedure called to validate C_S01_AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_DATA_WIDTH { PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
	# Procedure called to update C_S01_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_DATA_WIDTH { PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S01_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH } {
	# Procedure called to update C_S01_AXI_AWUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH } {
	# Procedure called to validate C_S01_AXI_AWUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH } {
	# Procedure called to update C_S01_AXI_ARUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH } {
	# Procedure called to validate C_S01_AXI_ARUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_WUSER_WIDTH { PARAM_VALUE.C_S01_AXI_WUSER_WIDTH } {
	# Procedure called to update C_S01_AXI_WUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_WUSER_WIDTH { PARAM_VALUE.C_S01_AXI_WUSER_WIDTH } {
	# Procedure called to validate C_S01_AXI_WUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_RUSER_WIDTH { PARAM_VALUE.C_S01_AXI_RUSER_WIDTH } {
	# Procedure called to update C_S01_AXI_RUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_RUSER_WIDTH { PARAM_VALUE.C_S01_AXI_RUSER_WIDTH } {
	# Procedure called to validate C_S01_AXI_RUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_BUSER_WIDTH { PARAM_VALUE.C_S01_AXI_BUSER_WIDTH } {
	# Procedure called to update C_S01_AXI_BUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_BUSER_WIDTH { PARAM_VALUE.C_S01_AXI_BUSER_WIDTH } {
	# Procedure called to validate C_S01_AXI_BUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_BASEADDR { PARAM_VALUE.C_S01_AXI_BASEADDR } {
	# Procedure called to update C_S01_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_BASEADDR { PARAM_VALUE.C_S01_AXI_BASEADDR } {
	# Procedure called to validate C_S01_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S01_AXI_HIGHADDR { PARAM_VALUE.C_S01_AXI_HIGHADDR } {
	# Procedure called to update C_S01_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S01_AXI_HIGHADDR { PARAM_VALUE.C_S01_AXI_HIGHADDR } {
	# Procedure called to validate C_S01_AXI_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_ID_WIDTH { PARAM_VALUE.C_S02_AXI_ID_WIDTH } {
	# Procedure called to update C_S02_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_ID_WIDTH { PARAM_VALUE.C_S02_AXI_ID_WIDTH } {
	# Procedure called to validate C_S02_AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S02_AXI_AWUSER_WIDTH } {
	# Procedure called to update C_S02_AXI_AWUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S02_AXI_AWUSER_WIDTH } {
	# Procedure called to validate C_S02_AXI_AWUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S02_AXI_ARUSER_WIDTH } {
	# Procedure called to update C_S02_AXI_ARUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S02_AXI_ARUSER_WIDTH } {
	# Procedure called to validate C_S02_AXI_ARUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_WUSER_WIDTH { PARAM_VALUE.C_S02_AXI_WUSER_WIDTH } {
	# Procedure called to update C_S02_AXI_WUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_WUSER_WIDTH { PARAM_VALUE.C_S02_AXI_WUSER_WIDTH } {
	# Procedure called to validate C_S02_AXI_WUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_RUSER_WIDTH { PARAM_VALUE.C_S02_AXI_RUSER_WIDTH } {
	# Procedure called to update C_S02_AXI_RUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_RUSER_WIDTH { PARAM_VALUE.C_S02_AXI_RUSER_WIDTH } {
	# Procedure called to validate C_S02_AXI_RUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_BUSER_WIDTH { PARAM_VALUE.C_S02_AXI_BUSER_WIDTH } {
	# Procedure called to update C_S02_AXI_BUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_BUSER_WIDTH { PARAM_VALUE.C_S02_AXI_BUSER_WIDTH } {
	# Procedure called to validate C_S02_AXI_BUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_BASEADDR { PARAM_VALUE.C_S02_AXI_BASEADDR } {
	# Procedure called to update C_S02_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_BASEADDR { PARAM_VALUE.C_S02_AXI_BASEADDR } {
	# Procedure called to validate C_S02_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S02_AXI_HIGHADDR { PARAM_VALUE.C_S02_AXI_HIGHADDR } {
	# Procedure called to update C_S02_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S02_AXI_HIGHADDR { PARAM_VALUE.C_S02_AXI_HIGHADDR } {
	# Procedure called to validate C_S02_AXI_HIGHADDR
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

proc update_MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH PARAM_VALUE.C_S01_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S01_AXI_DATA_WIDTH PARAM_VALUE.C_S01_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S01_AXI_ADDR_WIDTH PARAM_VALUE.C_S01_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_AWUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_ARUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH PARAM_VALUE.C_S01_AXI_WUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_WUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH PARAM_VALUE.C_S01_AXI_RUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_RUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH { MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH PARAM_VALUE.C_S01_AXI_BUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S01_AXI_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_S01_AXI_BUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S02_AXI_ID_WIDTH PARAM_VALUE.C_S02_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S02_AXI_DATA_WIDTH PARAM_VALUE.C_S02_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S02_AXI_ADDR_WIDTH PARAM_VALUE.C_S02_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_AWUSER_WIDTH { MODELPARAM_VALUE.C_S02_AXI_AWUSER_WIDTH PARAM_VALUE.C_S02_AXI_AWUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_AWUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_ARUSER_WIDTH { MODELPARAM_VALUE.C_S02_AXI_ARUSER_WIDTH PARAM_VALUE.C_S02_AXI_ARUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_ARUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_WUSER_WIDTH { MODELPARAM_VALUE.C_S02_AXI_WUSER_WIDTH PARAM_VALUE.C_S02_AXI_WUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_WUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_RUSER_WIDTH { MODELPARAM_VALUE.C_S02_AXI_RUSER_WIDTH PARAM_VALUE.C_S02_AXI_RUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_RUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S02_AXI_BUSER_WIDTH { MODELPARAM_VALUE.C_S02_AXI_BUSER_WIDTH PARAM_VALUE.C_S02_AXI_BUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S02_AXI_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_S02_AXI_BUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.CLK_FREQ { MODELPARAM_VALUE.CLK_FREQ PARAM_VALUE.CLK_FREQ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQ}] ${MODELPARAM_VALUE.CLK_FREQ}
}

proc update_MODELPARAM_VALUE.SCLK_FREQ { MODELPARAM_VALUE.SCLK_FREQ PARAM_VALUE.SCLK_FREQ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SCLK_FREQ}] ${MODELPARAM_VALUE.SCLK_FREQ}
}

proc update_MODELPARAM_VALUE.ADC_DUAL { MODELPARAM_VALUE.ADC_DUAL PARAM_VALUE.ADC_DUAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_DUAL}] ${MODELPARAM_VALUE.ADC_DUAL}
}

proc update_MODELPARAM_VALUE.ADC_VREF_IS_DOUBLE { MODELPARAM_VALUE.ADC_VREF_IS_DOUBLE PARAM_VALUE.ADC_VREF_IS_DOUBLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_VREF_IS_DOUBLE}] ${MODELPARAM_VALUE.ADC_VREF_IS_DOUBLE}
}

proc update_MODELPARAM_VALUE.COUNTER_BITS { MODELPARAM_VALUE.COUNTER_BITS PARAM_VALUE.COUNTER_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.COUNTER_BITS}] ${MODELPARAM_VALUE.COUNTER_BITS}
}

proc update_MODELPARAM_VALUE.NUMBER_PROBES { MODELPARAM_VALUE.NUMBER_PROBES PARAM_VALUE.NUMBER_PROBES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NUMBER_PROBES}] ${MODELPARAM_VALUE.NUMBER_PROBES}
}

proc update_MODELPARAM_VALUE.AXI_SNIFFER_ENABLE { MODELPARAM_VALUE.AXI_SNIFFER_ENABLE PARAM_VALUE.AXI_SNIFFER_ENABLE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_SNIFFER_ENABLE}] ${MODELPARAM_VALUE.AXI_SNIFFER_ENABLE}
}

proc update_MODELPARAM_VALUE.AXI_SNIFFER_DATA_WIDTH { MODELPARAM_VALUE.AXI_SNIFFER_DATA_WIDTH PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.AXI_SNIFFER_DATA_WIDTH}] ${MODELPARAM_VALUE.AXI_SNIFFER_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.POWER_DEPTH { MODELPARAM_VALUE.POWER_DEPTH PARAM_VALUE.POWER_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.POWER_DEPTH}] ${MODELPARAM_VALUE.POWER_DEPTH}
}

proc update_MODELPARAM_VALUE.TRACES_DEPTH { MODELPARAM_VALUE.TRACES_DEPTH PARAM_VALUE.TRACES_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TRACES_DEPTH}] ${MODELPARAM_VALUE.TRACES_DEPTH}
}

proc update_MODELPARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH PARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_SNIFFER_IN_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH PARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_SNIFFER_IN_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH PARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M_SNIFFER_OUT_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH PARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_M_SNIFFER_OUT_AXI_ADDR_WIDTH}
}

