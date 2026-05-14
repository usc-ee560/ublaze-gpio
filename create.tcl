create_project ublaze-gpio C:/Users/mrede/Documents/ee560/ublaze-test1/ublaze-gpio -part xc7a100tcsg324-1
set_property board_part digilentinc.com:arty-a7-100:part0:1.1 [current_project]
set_property target_language Verilog [current_project]
create_bd_design "ublaze_gpio"
update_compile_order -fileset sources_1

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze_riscv:1.0 microblaze_riscv_0
create_bd_cell -type ip -vlnv xilinx.com:ip:mdm_riscv:1.0 mdm_riscv_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 axi_intc_0
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 lmb_bram_if_cntlr_0
create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 lmb_bram_if_cntlr_1
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup

connect_bd_net [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins axi_intc_0/intr]
connect_bd_intf_net [get_bd_intf_pins axi_intc_0/interrupt] [get_bd_intf_pins microblaze_riscv_0/INTERRUPT]

set_property CONFIG.C_D_AXI 1 [get_bd_cells /microblaze_riscv_0]

# Instruction/Data local memory on LMB
set_property -dict [list \
  CONFIG.Memory_Type {True_Dual_Port_RAM} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Byte_Size {8} \
  CONFIG.Write_Width_A {32} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Write_Width_B {32} \
  CONFIG.Read_Width_B {32} \
  CONFIG.Write_Depth_A {16384} \
] [get_bd_cells blk_mem_gen_0]

connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/ILMB] [get_bd_intf_pins lmb_bram_if_cntlr_0/SLMB]
connect_bd_intf_net [get_bd_intf_pins microblaze_riscv_0/DLMB] [get_bd_intf_pins lmb_bram_if_cntlr_1/SLMB]
connect_bd_intf_net [get_bd_intf_pins lmb_bram_if_cntlr_0/BRAM_PORT] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]
connect_bd_intf_net [get_bd_intf_pins lmb_bram_if_cntlr_1/BRAM_PORT] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTB]

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins lmb_bram_if_cntlr_0/LMB_Clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins lmb_bram_if_cntlr_1/LMB_Clk]
connect_bd_net [get_bd_pins proc_sys_reset_0/bus_struct_reset] [get_bd_pins lmb_bram_if_cntlr_0/LMB_Rst]
connect_bd_net [get_bd_pins proc_sys_reset_0/bus_struct_reset] [get_bd_pins lmb_bram_if_cntlr_1/LMB_Rst]

connect_bd_intf_net [get_bd_intf_pins mdm_riscv_0/MBDEBUG_0] [get_bd_intf_pins microblaze_riscv_0/DEBUG]
connect_bd_net [get_bd_pins mdm_riscv_0/Debug_SYS_Rst] [get_bd_pins proc_sys_reset_0/mb_debug_sys_rst]

# Explicit local memory ranges for instruction/data LMB spaces
set_property -dict [list \
  CONFIG.C_BASEADDR {0x00000000} \
  CONFIG.C_HIGHADDR {0x0000FFFF} \
] [get_bd_cells lmb_bram_if_cntlr_0]

set_property -dict [list \
  CONFIG.C_BASEADDR {0x00000000} \
  CONFIG.C_HIGHADDR {0x0000FFFF} \
] [get_bd_cells lmb_bram_if_cntlr_1]

#set_property offset 0x10000000 [get_bd_addr_segs {microblaze_riscv_0/Data/SEG_lmb_bram_if_cntlr_1_Mem}]

set_property -dict [list \
  CONFIG.C_GPIO_WIDTH {16} \
  CONFIG.GPIO_BOARD_INTERFACE {Custom} \
  CONFIG.C_ALL_INPUTS {0} \
  CONFIG.C_ALL_OUTPUTS {1} \
] [get_bd_cells axi_gpio_0]

set_property CONFIG.C_BAUDRATE {115200} [get_bd_cells axi_uartlite_0]

startgroup
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {dip_switches_4bits ( 4 Switches ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_gpio_0/GPIO]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_intc_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_intc_0/s_axi]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {usb_uart ( USB UART ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_uartlite_0/UART]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sys_clock ( System Clock ) } Manual_Source {New External Port (ACTIVE_LOW)}}  [get_bd_pins clk_wiz_0/clk_in1]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( System Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_0/reset]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( System Reset ) } Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
endgroup

# Manual updates
delete_bd_objs [get_bd_intf_nets axi_gpio_0_GPIO]
delete_bd_objs [get_bd_intf_ports dip_switches_4bits]
startgroup
set_property -dict [list \
  CONFIG.C_ALL_INPUTS {0} \
  CONFIG.C_ALL_OUTPUTS {1} \
  CONFIG.C_GPIO_WIDTH {16} \
  CONFIG.GPIO_BOARD_INTERFACE {Custom} \
] [get_bd_cells axi_gpio_0]
endgroup
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds
connect_bd_intf_net [get_bd_intf_pins axi_gpio_0/GPIO] [get_bd_intf_ports leds]

delete_bd_objs [get_bd_nets reset_0_1]
delete_bd_objs [get_bd_ports reset_0]
connect_bd_net [get_bd_ports reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]
# make_bd_pins_external  [get_bd_pins axi_uartlite_0/rx]
# make_bd_pins_external  [get_bd_pins axi_uartlite_0/tx]
#create_bd_port -dir O -from 15 -to 0 leds

#create_bd_port -dir I -type clk -freq_hz 100000000 sys_clock
# startgroup
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_0/clk_out1 (100 MHz)} Clk_slave {/clk_wiz_0/clk_out1 (100 MHz)} Clk_xbar {/clk_wiz_0/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_gpio_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_gpio_0/S_AXI]
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_0/clk_out1 (100 MHz)} Clk_slave {/clk_wiz_0/clk_out1 (100 MHz)} Clk_xbar {/clk_wiz_0/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_uartlite_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins axi_uartlite_0/S_AXI]
# apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/clk_wiz_0/clk_out1 (100 MHz)} Clk_slave {Auto} Clk_xbar {/clk_wiz_0/clk_out1 (100 MHz)} Master {/microblaze_riscv_0 (Periph)} Slave {/axi_intc_0/s_axi} ddr_seg {Auto} intc_ip {/microblaze_riscv_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_intc_0/s_axi]
# endgroup
# update_compile_order -fileset sources_1
# startgroup
# apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {leds16 ( 16 LEDs ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_gpio_0/GPIO]
# apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {usb_uart ( USB UART ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_uartlite_0/UART]
# apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sys_clock ( System Clock ) } Manual_Source {New External Port (ACTIVE_LOW)}}  [get_bd_pins clk_wiz_0/clk_in1]
# apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( System Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_0/reset]
# apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( System Reset ) } Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
# endgroup
# set_property name leds [get_bd_intf_ports dip_switches_4bits]



# startgroup
# endgroup
# startgroup
# endgroup

#generate_target all [get_files  C:/Users/mrede/Documents/ee560/ublaze-test1/ublaze-gpio/ublaze-gpio.srcs/sources_1/bd/ublaze_gpio/ublaze_gpio.bd]
assign_bd_address
set_property range 64K [get_bd_addr_segs {microblaze_riscv_0/Data/SEG_lmb_bram_if_cntlr_1_Mem}]
set_property range 64K [get_bd_addr_segs {microblaze_riscv_0/Instruction/SEG_lmb_bram_if_cntlr_0_Mem}]
validate_bd_design
save_bd_design
generate_target all [get_files  C:/Users/mrede/Documents/ee560/ublaze-test1/ublaze-gpio/ublaze-gpio.srcs/sources_1/bd/ublaze_gpio/ublaze_gpio.bd]
make_wrapper -files [get_files C:/Users/mrede/Documents/ee560/ublaze-test1/ublaze-gpio/ublaze-gpio.srcs/sources_1/bd/ublaze_gpio/ublaze_gpio.bd] -top
add_files -norecurse c:/Users/mrede/Documents/ee560/ublaze-test1/ublaze-gpio/ublaze-gpio.gen/sources_1/bd/ublaze_gpio/hdl/ublaze_gpio_wrapper.v

add_files -fileset constrs_1 -norecurse C:/Users/mrede/Documents/ee560/ublaze-test1/syn/constr_a7.xdc

launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if {![string match "*write_bitstream Complete*" $impl_status]} {
  error "impl_1 did not complete successfully. STATUS=$impl_status"
}

#open_run impl_1
write_hw_platform -fixed -include_bit -force -file C:/Users/mrede/Documents/ee560/ublaze-test1/ublaze-gpio/ublaze_gpio_wrapper.xsa
