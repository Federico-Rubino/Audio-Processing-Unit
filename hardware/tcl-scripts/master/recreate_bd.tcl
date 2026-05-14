
################################################################
# This is a generated script based on design: top_module
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2024.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source top_module_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# CPU, instr_mem_mux

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7z020clg484-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name top_module

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:user:RV32I_AXI_Bridge:1.0\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:smartconnect:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xlslice:1.0\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:c_counter_binary:12.0\
xilinx.com:ip:clk_wiz:6.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
CPU\
instr_mem_mux\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set uart_rtl_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart_rtl_0 ]


  # Create ports
  set reset_rtl_0 [ create_bd_port -dir I -type rst reset_rtl_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset_rtl_0
  set clk_in1_0 [ create_bd_port -dir I -type clk clk_in1_0 ]
  set Dout_0 [ create_bd_port -dir O -from 0 -to 0 Dout_0 ]

  # Create instance: CPU_0, and set properties
  set block_name CPU
  set block_cell_name CPU_0
  if { [catch {set CPU_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $CPU_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: RV32I_AXI_Bridge_0, and set properties
  set RV32I_AXI_Bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:RV32I_AXI_Bridge:1.0 RV32I_AXI_Bridge_0 ]

  # Create instance: axi_bram_ctrl_0, and set properties
  set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_0


  # Create instance: axi_bram_ctrl_0_bram, and set properties
  set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram ]
  set_property -dict [list \
    CONFIG.Byte_Size {8} \
    CONFIG.Coe_File {c:/Users/campi/Documents/Uni/Audio-Processing-Unit/hardware/src/master/coe/bootloader_data_mem.coe} \
    CONFIG.Fill_Remaining_Memory_Locations {true} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_Byte_Write_Enable {true} \
    CONFIG.Write_Depth_A {8192} \
    CONFIG.Write_Width_A {32} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $axi_bram_ctrl_0_bram


  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
  set_property -dict [list \
    CONFIG.NUM_MI {3} \
    CONFIG.NUM_SI {2} \
  ] $axi_smc


  # Create instance: rst_clk_wiz_100M, and set properties
  set rst_clk_wiz_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_100M ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {11} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {12} \
  ] $xlslice_0


  # Create instance: blk_mem_gen_0, and set properties
  set blk_mem_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0 ]
  set_property -dict [list \
    CONFIG.Assume_Synchronous_Clk {false} \
    CONFIG.Byte_Size {8} \
    CONFIG.Coe_File {c:/Users/campi/Documents/Uni/Audio-Processing-Unit/hardware/test/master/coe/uart/uart_instr_mem.coe} \
    CONFIG.Fill_Remaining_Memory_Locations {true} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Memory_Type {True_Dual_Port_RAM} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
    CONFIG.Use_Byte_Write_Enable {true} \
    CONFIG.Write_Depth_A {16384} \
    CONFIG.Write_Width_A {32} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_0


  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {31} \
    CONFIG.DIN_TO {2} \
  ] $xlslice_1


  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property CONFIG.C_BAUDRATE {115200} $axi_uartlite_0


  # Create instance: c_counter_binary_0, and set properties
  set c_counter_binary_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0 ]

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]
  set_property CONFIG.DIN_WIDTH {16} $xlslice_2


  # Create instance: instr_mem_mux_0, and set properties
  set block_name instr_mem_mux
  set block_cell_name instr_mem_mux_0
  if { [catch {set instr_mem_mux_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $instr_mem_mux_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_bram_ctrl_1, and set properties
  set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_1


  # Create instance: blk_mem_gen_1, and set properties
  set blk_mem_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_1 ]
  set_property -dict [list \
    CONFIG.Coe_File {c:/Users/campi/Documents/Uni/Audio-Processing-Unit/hardware/src/master/coe/boot_loader_instr.coe} \
    CONFIG.Enable_32bit_Address {false} \
    CONFIG.Load_Init_File {true} \
    CONFIG.Memory_Type {Single_Port_ROM} \
    CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_1


  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {100.0} \
    CONFIG.CLKOUT1_JITTER {137.143} \
    CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {80.000} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.500} \
  ] $clk_wiz_0


  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {31} \
    CONFIG.DIN_TO {2} \
  ] $xlslice_3


  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {15} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {16} \
  ] $xlslice_4


  # Create interface connections
  connect_bd_intf_net -intf_net RV32I_AXI_Bridge_0_M_AXI [get_bd_intf_pins RV32I_AXI_Bridge_0/M_AXI] [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M02_AXI [get_bd_intf_pins axi_smc/M02_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports uart_rtl_0] [get_bd_intf_pins axi_uartlite_0/UART]

  # Create port connections
  connect_bd_net -net CPU_0_data_mem_addr  [get_bd_pins CPU_0/data_mem_addr] \
  [get_bd_pins RV32I_AXI_Bridge_0/cpu_addr]
  connect_bd_net -net CPU_0_data_mem_data_out  [get_bd_pins CPU_0/data_mem_data_out] \
  [get_bd_pins RV32I_AXI_Bridge_0/cpu_wdata]
  connect_bd_net -net CPU_0_data_mem_ena  [get_bd_pins CPU_0/data_mem_ena] \
  [get_bd_pins RV32I_AXI_Bridge_0/cpu_mem_en]
  connect_bd_net -net CPU_0_data_mem_wea  [get_bd_pins CPU_0/data_mem_wea] \
  [get_bd_pins RV32I_AXI_Bridge_0/cpu_mem_wea]
  connect_bd_net -net CPU_0_instr_mem_addr  [get_bd_pins CPU_0/instr_mem_addr] \
  [get_bd_pins instr_mem_mux_0/instr_mem_addr_in]
  connect_bd_net -net CPU_0_instr_mem_ena  [get_bd_pins CPU_0/instr_mem_ena] \
  [get_bd_pins instr_mem_mux_0/instr_mem_ena_in]
  connect_bd_net -net RV32I_AXI_Bridge_0_cpu_rdata  [get_bd_pins RV32I_AXI_Bridge_0/cpu_rdata] \
  [get_bd_pins CPU_0/data_mem_data_in]
  connect_bd_net -net RV32I_AXI_Bridge_0_cpu_stall  [get_bd_pins RV32I_AXI_Bridge_0/cpu_stall] \
  [get_bd_pins CPU_0/stall]
  connect_bd_net -net axi_bram_ctrl_0_bram_addr_a  [get_bd_pins axi_bram_ctrl_0/bram_addr_a] \
  [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axi_bram_ctrl_0_bram_clk_a  [get_bd_pins axi_bram_ctrl_0/bram_clk_a] \
  [get_bd_pins axi_bram_ctrl_0_bram/clka]
  connect_bd_net -net axi_bram_ctrl_0_bram_douta  [get_bd_pins axi_bram_ctrl_0_bram/douta] \
  [get_bd_pins axi_bram_ctrl_0/bram_rddata_a]
  connect_bd_net -net axi_bram_ctrl_0_bram_en_a  [get_bd_pins axi_bram_ctrl_0/bram_en_a] \
  [get_bd_pins axi_bram_ctrl_0_bram/ena]
  connect_bd_net -net axi_bram_ctrl_0_bram_we_a  [get_bd_pins axi_bram_ctrl_0/bram_we_a] \
  [get_bd_pins axi_bram_ctrl_0_bram/wea]
  connect_bd_net -net axi_bram_ctrl_0_bram_wrdata_a  [get_bd_pins axi_bram_ctrl_0/bram_wrdata_a] \
  [get_bd_pins axi_bram_ctrl_0_bram/dina]
  connect_bd_net -net axi_bram_ctrl_1_bram_addr_a  [get_bd_pins axi_bram_ctrl_1/bram_addr_a] \
  [get_bd_pins xlslice_4/Din]
  connect_bd_net -net axi_bram_ctrl_1_bram_clk_a  [get_bd_pins axi_bram_ctrl_1/bram_clk_a] \
  [get_bd_pins blk_mem_gen_0/clkb]
  connect_bd_net -net axi_bram_ctrl_1_bram_en_a  [get_bd_pins axi_bram_ctrl_1/bram_en_a] \
  [get_bd_pins blk_mem_gen_0/enb]
  connect_bd_net -net axi_bram_ctrl_1_bram_we_a  [get_bd_pins axi_bram_ctrl_1/bram_we_a] \
  [get_bd_pins blk_mem_gen_0/web]
  connect_bd_net -net axi_bram_ctrl_1_bram_wrdata_a  [get_bd_pins axi_bram_ctrl_1/bram_wrdata_a] \
  [get_bd_pins blk_mem_gen_0/dinb]
  connect_bd_net -net blk_mem_gen_0_douta  [get_bd_pins blk_mem_gen_0/douta] \
  [get_bd_pins instr_mem_mux_0/instr_mem_data_in]
  connect_bd_net -net blk_mem_gen_0_doutb  [get_bd_pins blk_mem_gen_0/doutb] \
  [get_bd_pins axi_bram_ctrl_1/bram_rddata_a]
  connect_bd_net -net blk_mem_gen_1_douta  [get_bd_pins blk_mem_gen_1/douta] \
  [get_bd_pins instr_mem_mux_0/boot_mem_data_in]
  connect_bd_net -net c_counter_binary_0_Q  [get_bd_pins c_counter_binary_0/Q] \
  [get_bd_pins xlslice_2/Din]
  connect_bd_net -net clk_in1_0_1  [get_bd_ports clk_in1_0] \
  [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins clk_wiz_0/clk_out1] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins axi_smc/aclk] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] \
  [get_bd_pins axi_uartlite_0/s_axi_aclk] \
  [get_bd_pins c_counter_binary_0/CLK] \
  [get_bd_pins CPU_0/clk] \
  [get_bd_pins rst_clk_wiz_100M/slowest_sync_clk] \
  [get_bd_pins RV32I_AXI_Bridge_0/m_axi_aclk] \
  [get_bd_pins blk_mem_gen_1/clka] \
  [get_bd_pins blk_mem_gen_0/clka]
  connect_bd_net -net clk_wiz_0_locked  [get_bd_pins clk_wiz_0/locked] \
  [get_bd_pins rst_clk_wiz_100M/dcm_locked]
  connect_bd_net -net instr_mem_mux_0_boot_mem_addr_out  [get_bd_pins instr_mem_mux_0/boot_mem_addr_out] \
  [get_bd_pins xlslice_3/Din]
  connect_bd_net -net instr_mem_mux_0_boot_mem_ena_out  [get_bd_pins instr_mem_mux_0/boot_mem_ena_out] \
  [get_bd_pins blk_mem_gen_1/ena]
  connect_bd_net -net instr_mem_mux_0_instr_mem_addr_out  [get_bd_pins instr_mem_mux_0/instr_mem_addr_out] \
  [get_bd_pins xlslice_1/Din]
  connect_bd_net -net instr_mem_mux_0_instr_mem_data_out  [get_bd_pins instr_mem_mux_0/instr_mem_data_out] \
  [get_bd_pins CPU_0/instr_mem_data]
  connect_bd_net -net instr_mem_mux_0_instr_mem_ena_out  [get_bd_pins instr_mem_mux_0/instr_mem_ena_out] \
  [get_bd_pins blk_mem_gen_0/ena]
  connect_bd_net -net reset_rtl_0_1  [get_bd_ports reset_rtl_0] \
  [get_bd_pins rst_clk_wiz_100M/ext_reset_in] \
  [get_bd_pins clk_wiz_0/reset]
  connect_bd_net -net rst_clk_wiz_100M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_100M/peripheral_aresetn] \
  [get_bd_pins RV32I_AXI_Bridge_0/m_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins axi_smc/aresetn] \
  [get_bd_pins axi_uartlite_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn]
  connect_bd_net -net rst_clk_wiz_100M_peripheral_reset  [get_bd_pins rst_clk_wiz_100M/peripheral_reset] \
  [get_bd_pins CPU_0/rst]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins axi_bram_ctrl_0_bram/addra]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins blk_mem_gen_0/addra]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins xlslice_2/Dout] \
  [get_bd_ports Dout_0]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins xlslice_3/Dout] \
  [get_bd_pins blk_mem_gen_1/addra]
  connect_bd_net -net xlslice_4_Dout  [get_bd_pins xlslice_4/Dout] \
  [get_bd_pins blk_mem_gen_0/addrb]

  # Create address segments
  assign_bd_address -offset 0x00020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00028000 -range 0x00000080 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


