# Monitor SPI
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports CS_n]
set_property -dict {PACKAGE_PIN Y19 IOSTANDARD LVCMOS33} [get_ports SCLK]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS33} [get_ports MISO]
set_property -dict {PACKAGE_PIN Y17 IOSTANDARD LVCMOS33} [get_ports MOSI]
