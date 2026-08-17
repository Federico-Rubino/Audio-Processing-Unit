
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
# CPU, instr_mem_mux, APU

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
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:axi_gpio:2.0\
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
APU\
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

  set gpio_rtl_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_rtl_0 ]

  set gpio_rtl_1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 gpio_rtl_1 ]


  # Create ports
  set reset_rtl_0 [ create_bd_port -dir I -type rst reset_rtl_0 ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset_rtl_0
  set clk_in1_0 [ create_bd_port -dir I -type clk clk_in1_0 ]
  set AC_ADR0_0 [ create_bd_port -dir O AC_ADR0_0 ]
  set AC_SDA_0 [ create_bd_port -dir IO AC_SDA_0 ]
  set AC_SCK_0 [ create_bd_port -dir O AC_SCK_0 ]
  set AC_MCLK_0 [ create_bd_port -dir O AC_MCLK_0 ]
  set AC_GPIO3_0 [ create_bd_port -dir I AC_GPIO3_0 ]
  set AC_GPIO2_0 [ create_bd_port -dir I AC_GPIO2_0 ]
  set AC_GPIO1_0 [ create_bd_port -dir I AC_GPIO1_0 ]
  set AC_GPIO0_0 [ create_bd_port -dir O AC_GPIO0_0 ]
  set AC_ADR1_0 [ create_bd_port -dir O AC_ADR1_0 ]

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
    CONFIG.NUM_MI {5} \
    CONFIG.NUM_SI {2} \
  ] $axi_smc


  # Create instance: rst_clk_wiz_100M, and set properties
  set rst_clk_wiz_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_100M ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {14} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {15} \
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
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
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
    CONFIG.Register_PortA_Output_of_Memory_Primitives {true} \
    CONFIG.Write_Depth_A {1024} \
    CONFIG.use_bram_block {Stand_Alone} \
  ] $blk_mem_gen_1


  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [list \
    CONFIG.CLKIN1_JITTER_PS {100.0} \
    CONFIG.CLKOUT1_JITTER {130.958} \
    CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
    CONFIG.MMCM_CLKIN1_PERIOD {10.000} \
    CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {10.000} \
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


  # Create instance: axi_gpio_0, and set properties
  set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0 ]
  set_property -dict [list \
    CONFIG.C_ALL_INPUTS {1} \
    CONFIG.C_ALL_OUTPUTS_2 {1} \
    CONFIG.C_GPIO2_WIDTH {8} \
    CONFIG.C_GPIO_WIDTH {12} \
    CONFIG.C_IS_DUAL {1} \
  ] $axi_gpio_0


  # Create instance: APU_0, and set properties
  set block_name APU
  set block_cell_name APU_0
  if { [catch {set APU_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $APU_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: axi_bram_ctrl_2, and set properties
  set axi_bram_ctrl_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_2 ]
  set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_2


  # Create instance: xlslice_5, and set properties
  # DIN_FROM/DIN_TO select bits [12:2] of the byte address (bram_addr_a) to
  # produce an 11-bit word address, matching APU_0/addr (INSTR_ADDR_SIZE=11,
  # covering the 8K/2048-word instr_bram range). Was previously [15:2] (14
  # bits), wider than APU_0/addr actually is.
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]
  set_property -dict [list \
    CONFIG.DIN_FROM {12} \
    CONFIG.DIN_TO {2} \
    CONFIG.DIN_WIDTH {16} \
  ] $xlslice_5


  # Create interface connections
  connect_bd_intf_net -intf_net RV32I_AXI_Bridge_0_M_AXI [get_bd_intf_pins RV32I_AXI_Bridge_0/M_AXI] [get_bd_intf_pins axi_smc/S00_AXI]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports gpio_rtl_0] [get_bd_intf_pins axi_gpio_0/GPIO]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO2 [get_bd_intf_ports gpio_rtl_1] [get_bd_intf_pins axi_gpio_0/GPIO2]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M01_AXI [get_bd_intf_pins axi_smc/M01_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M02_AXI [get_bd_intf_pins axi_smc/M02_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M03_AXI [get_bd_intf_pins axi_smc/M03_AXI] [get_bd_intf_pins axi_gpio_0/S_AXI]
  connect_bd_intf_net -intf_net axi_smc_M04_AXI [get_bd_intf_pins axi_smc/M04_AXI] [get_bd_intf_pins axi_bram_ctrl_2/S_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports uart_rtl_0] [get_bd_intf_pins axi_uartlite_0/UART]

  # Create port connections
  connect_bd_net -net AC_GPIO1_0_1  [get_bd_ports AC_GPIO1_0] \
  [get_bd_pins APU_0/AC_GPIO1]
  connect_bd_net -net AC_GPIO2_0_1  [get_bd_ports AC_GPIO2_0] \
  [get_bd_pins APU_0/AC_GPIO2]
  connect_bd_net -net AC_GPIO3_0_1  [get_bd_ports AC_GPIO3_0] \
  [get_bd_pins APU_0/AC_GPIO3]
  connect_bd_net -net APU_0_AC_ADR0  [get_bd_pins APU_0/AC_ADR0] \
  [get_bd_ports AC_ADR0_0]
  connect_bd_net -net APU_0_AC_ADR1  [get_bd_pins APU_0/AC_ADR1] \
  [get_bd_ports AC_ADR1_0]
  connect_bd_net -net APU_0_AC_GPIO0  [get_bd_pins APU_0/AC_GPIO0] \
  [get_bd_ports AC_GPIO0_0]
  connect_bd_net -net APU_0_AC_MCLK  [get_bd_pins APU_0/AC_MCLK] \
  [get_bd_ports AC_MCLK_0]
  connect_bd_net -net APU_0_AC_SCK  [get_bd_pins APU_0/AC_SCK] \
  [get_bd_ports AC_SCK_0]
  connect_bd_net -net APU_0_data_out  [get_bd_pins APU_0/data_out] \
  [get_bd_pins axi_bram_ctrl_2/bram_rddata_a]
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
  connect_bd_net -net Net  [get_bd_ports AC_SDA_0] \
  [get_bd_pins APU_0/AC_SDA]
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
  connect_bd_net -net axi_bram_ctrl_2_bram_addr_a  [get_bd_pins axi_bram_ctrl_2/bram_addr_a] \
  [get_bd_pins xlslice_5/Din]
  connect_bd_net -net axi_bram_ctrl_2_bram_clk_a  [get_bd_pins axi_bram_ctrl_2/bram_clk_a] \
  [get_bd_pins APU_0/clk]
  connect_bd_net -net axi_bram_ctrl_2_bram_en_a  [get_bd_pins axi_bram_ctrl_2/bram_en_a] \
  [get_bd_pins APU_0/en]
  connect_bd_net -net axi_bram_ctrl_2_bram_we_a  [get_bd_pins axi_bram_ctrl_2/bram_we_a] \
  [get_bd_pins APU_0/we]
  connect_bd_net -net axi_bram_ctrl_2_bram_wrdata_a  [get_bd_pins axi_bram_ctrl_2/bram_wrdata_a] \
  [get_bd_pins APU_0/data_in]
  connect_bd_net -net blk_mem_gen_0_douta  [get_bd_pins blk_mem_gen_0/douta] \
  [get_bd_pins instr_mem_mux_0/instr_mem_data_in]
  connect_bd_net -net blk_mem_gen_0_doutb  [get_bd_pins blk_mem_gen_0/doutb] \
  [get_bd_pins axi_bram_ctrl_1/bram_rddata_a]
  connect_bd_net -net blk_mem_gen_1_douta  [get_bd_pins blk_mem_gen_1/douta] \
  [get_bd_pins instr_mem_mux_0/boot_mem_data_in]
  connect_bd_net -net clk_in1_0_1  [get_bd_ports clk_in1_0] \
  [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net -net clk_wiz_0_clk_out1  [get_bd_pins clk_wiz_0/clk_out1] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] \
  [get_bd_pins axi_smc/aclk] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] \
  [get_bd_pins axi_uartlite_0/s_axi_aclk] \
  [get_bd_pins CPU_0/clk] \
  [get_bd_pins rst_clk_wiz_100M/slowest_sync_clk] \
  [get_bd_pins RV32I_AXI_Bridge_0/m_axi_aclk] \
  [get_bd_pins blk_mem_gen_1/clka] \
  [get_bd_pins blk_mem_gen_0/clka] \
  [get_bd_pins axi_gpio_0/s_axi_aclk] \
  [get_bd_pins axi_bram_ctrl_0_bram/clkb] \
  [get_bd_pins axi_bram_ctrl_2/s_axi_aclk]
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
  connect_bd_net -net rst_clk_wiz_100M_interconnect_aresetn  [get_bd_pins rst_clk_wiz_100M/interconnect_aresetn] \
  [get_bd_pins APU_0/rst]
  connect_bd_net -net rst_clk_wiz_100M_peripheral_aresetn  [get_bd_pins rst_clk_wiz_100M/peripheral_aresetn] \
  [get_bd_pins RV32I_AXI_Bridge_0/m_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] \
  [get_bd_pins axi_smc/aresetn] \
  [get_bd_pins axi_uartlite_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] \
  [get_bd_pins axi_gpio_0/s_axi_aresetn] \
  [get_bd_pins axi_bram_ctrl_2/s_axi_aresetn]
  connect_bd_net -net rst_clk_wiz_100M_peripheral_reset  [get_bd_pins rst_clk_wiz_100M/peripheral_reset] \
  [get_bd_pins CPU_0/rst]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins axi_bram_ctrl_0_bram/addra]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins blk_mem_gen_0/addra]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins xlslice_3/Dout] \
  [get_bd_pins blk_mem_gen_1/addra]
  connect_bd_net -net xlslice_4_Dout  [get_bd_pins xlslice_4/Dout] \
  [get_bd_pins blk_mem_gen_0/addrb]
  connect_bd_net -net xlslice_5_Dout  [get_bd_pins xlslice_5/Dout] \
  [get_bd_pins APU_0/addr]

  # Create address segments
  assign_bd_address -offset 0x00020000 -range 0x00008000 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00030000 -range 0x00002000 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_bram_ctrl_2/S_AXI/Mem0] -force
  assign_bd_address -offset 0x00029000 -range 0x00000080 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x00028000 -range 0x00000080 -target_address_space [get_bd_addr_spaces RV32I_AXI_Bridge_0/M_AXI] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   "ActiveEmotionalView":"Default View",
   "Default View_ScaleFactor":"0.441941",
   "Default View_TopLeft":"-127,-1070",
   "ExpandedHierarchyInLayout":"",
   "guistr":"# # String gsaved with Nlview 7.8.0 2024-04-26 e1825d835c VDI=44 GEI=38 GUI=JA:21.0
#  -string -flagsOSRD
preplace port uart_rtl_0 -pg 1 -lvl 12 -x 4200 -y 80 -defaultsOSRD
preplace port gpio_rtl_0 -pg 1 -lvl 12 -x 4200 -y 20 -defaultsOSRD
preplace port gpio_rtl_1 -pg 1 -lvl 12 -x 4200 -y 50 -defaultsOSRD
preplace port port-id_reset_rtl_0 -pg 1 -lvl 0 -x 0 -y 50 -defaultsOSRD
preplace port port-id_clk_in1_0 -pg 1 -lvl 0 -x 0 -y 20 -defaultsOSRD
preplace port port-id_AC_ADR0_0 -pg 1 -lvl 12 -x 4200 -y 580 -defaultsOSRD
preplace port port-id_AC_SDA_0 -pg 1 -lvl 12 -x 4200 -y 730 -defaultsOSRD
preplace port port-id_AC_SCK_0 -pg 1 -lvl 12 -x 4200 -y 700 -defaultsOSRD
preplace port port-id_AC_MCLK_0 -pg 1 -lvl 12 -x 4200 -y 670 -defaultsOSRD
preplace port port-id_AC_GPIO3_0 -pg 1 -lvl 0 -x 0 -y 110 -defaultsOSRD
preplace port port-id_AC_GPIO2_0 -pg 1 -lvl 0 -x 0 -y 140 -defaultsOSRD
preplace port port-id_AC_GPIO1_0 -pg 1 -lvl 0 -x 0 -y 610 -defaultsOSRD
preplace port port-id_AC_GPIO0_0 -pg 1 -lvl 12 -x 4200 -y 640 -defaultsOSRD
preplace port port-id_AC_ADR1_0 -pg 1 -lvl 12 -x 4200 -y 610 -defaultsOSRD
preplace inst CPU_0 -pg 1 -lvl 1 -x 590 -y 340 -defaultsOSRD
preplace inst RV32I_AXI_Bridge_0 -pg 1 -lvl 1 -x 590 -y 560 -defaultsOSRD
preplace inst axi_bram_ctrl_0 -pg 1 -lvl 1 -x 590 -y 780 -defaultsOSRD
preplace inst axi_bram_ctrl_0_bram -pg 1 -lvl 1 -x 590 -y 1020 -defaultsOSRD
preplace inst axi_smc -pg 1 -lvl 9 -x 3400 -y 70 -defaultsOSRD
preplace inst rst_clk_wiz_100M -pg 1 -lvl 10 -x 3760 -y 80 -defaultsOSRD
preplace inst xlslice_0 -pg 1 -lvl 7 -x 2880 -y 140 -defaultsOSRD
preplace inst blk_mem_gen_0 -pg 1 -lvl 8 -x 3160 -y 50 -defaultsOSRD
preplace inst xlslice_1 -pg 1 -lvl 2 -x 1040 -y 10 -defaultsOSRD
preplace inst axi_uartlite_0 -pg 1 -lvl 2 -x 1040 -y -110 -defaultsOSRD
preplace inst instr_mem_mux_0 -pg 1 -lvl 6 -x 2490 -y -90 -defaultsOSRD
preplace inst axi_bram_ctrl_1 -pg 1 -lvl 3 -x 1400 -y -110 -defaultsOSRD
preplace inst blk_mem_gen_1 -pg 1 -lvl 8 -x 3160 -y 300 -defaultsOSRD
preplace inst clk_wiz_0 -pg 1 -lvl 7 -x 2880 -y -70 -defaultsOSRD
preplace inst xlslice_3 -pg 1 -lvl 7 -x 2880 -y 40 -defaultsOSRD
preplace inst xlslice_4 -pg 1 -lvl 6 -x 2490 -y 120 -defaultsOSRD
preplace inst axi_gpio_0 -pg 1 -lvl 11 -x 4060 -y 40 -defaultsOSRD
preplace inst APU_0 -pg 1 -lvl 5 -x 2080 -y 670 -defaultsOSRD
preplace inst axi_bram_ctrl_2 -pg 1 -lvl 3 -x 1400 -y 710 -defaultsOSRD
preplace inst xlslice_5 -pg 1 -lvl 4 -x 1750 -y 510 -defaultsOSRD
preplace netloc CPU_0_data_mem_addr 1 0 2 350 180 870
preplace netloc CPU_0_data_mem_data_out 1 0 2 300 130 880
preplace netloc CPU_0_data_mem_ena 1 0 2 280 110 890
preplace netloc CPU_0_data_mem_wea 1 0 2 360 190 850
preplace netloc CPU_0_instr_mem_addr 1 1 5 NJ 280 NJ 280 1630 -30 N -30 2230
preplace netloc CPU_0_instr_mem_ena 1 1 5 NJ 300 NJ 300 1650 -20 N -20 2240
preplace netloc RV32I_AXI_Bridge_0_cpu_rdata 1 0 2 290 120 790
preplace netloc RV32I_AXI_Bridge_0_cpu_stall 1 0 2 310 140 810
preplace netloc axi_bram_ctrl_0_bram_addr_a 1 1 6 920J 200 NJ 200 NJ 200 N 200 N 200 2700
preplace netloc axi_bram_ctrl_0_bram_clk_a 1 0 2 320 150 860
preplace netloc axi_bram_ctrl_0_bram_douta 1 0 2 330 160 820
preplace netloc axi_bram_ctrl_0_bram_en_a 1 0 2 370 200 840
preplace netloc axi_bram_ctrl_0_bram_we_a 1 0 2 390 220 800
preplace netloc axi_bram_ctrl_0_bram_wrdata_a 1 0 2 380 210 830
preplace netloc axi_bram_ctrl_1_bram_addr_a 1 3 3 1650 -40 N -40 2260
preplace netloc axi_bram_ctrl_1_bram_clk_a 1 3 5 1580 -250 N -250 N -250 NJ -250 3050J
preplace netloc axi_bram_ctrl_1_bram_en_a 1 3 5 1610 220 N 220 N 220 NJ 220 3040J
preplace netloc axi_bram_ctrl_1_bram_we_a 1 3 5 1550 230 N 230 N 230 NJ 230 3060J
preplace netloc axi_bram_ctrl_1_bram_wrdata_a 1 3 5 1640 -10 N -10 2230 240 NJ 240 3050J
preplace netloc blk_mem_gen_0_douta 1 5 3 2260 -190 NJ -190 3040J
preplace netloc blk_mem_gen_0_doutb 1 3 5 1620 0 N 0 2270 10 2760J -140 3000J
preplace netloc blk_mem_gen_1_douta 1 5 3 2290 320 NJ 320 NJ
preplace netloc clk_in1_0_1 1 0 7 NJ 20 830J 70 NJ 70 NJ 70 N 70 2240 50 2780
preplace netloc clk_wiz_0_clk_out1 1 0 11 240 -110 890 -200 1170 250 NJ 250 N 250 N 250 NJ 250 3030 -120 3260 -30 3590 -30 3950
preplace netloc clk_wiz_0_locked 1 7 3 2990J -130 NJ -130 3560
preplace netloc instr_mem_mux_0_boot_mem_addr_out 1 6 1 2770 -110n
preplace netloc instr_mem_mux_0_boot_mem_ena_out 1 6 2 2740 340 NJ
preplace netloc instr_mem_mux_0_instr_mem_addr_out 1 1 6 930 -190 1160J 80 NJ 80 N 80 2270 60 2690
preplace netloc instr_mem_mux_0_instr_mem_data_out 1 0 7 250 -210 NJ -210 1220J 10 NJ 10 N 10 2240 20 2700
preplace netloc instr_mem_mux_0_instr_mem_ena_out 1 6 2 2730 -150 3010J
preplace netloc reset_rtl_0_1 1 0 10 30 -220 NJ -220 1230J 20 NJ 20 N 20 2220 30 2720 -170 NJ -170 NJ -170 3570
preplace netloc rst_clk_wiz_100M_peripheral_aresetn 1 0 11 260 100 890 100 1200 420 NJ 420 N 420 N 420 NJ 420 NJ 420 3270 180 NJ 180 3950
preplace netloc rst_clk_wiz_100M_peripheral_reset 1 0 11 270 80 NJ 80 1150J 60 NJ 60 1860 40 N 40 2750J -160 NJ -160 NJ -160 NJ -160 3930
preplace netloc xlslice_0_Dout 1 0 8 340 170 900J 210 NJ 210 NJ 210 N 210 N 210 NJ 210 2980
preplace netloc xlslice_1_Dout 1 2 6 1180J 30 1600J -50 N -50 2220 -200 NJ -200 3060
preplace netloc xlslice_3_Dout 1 7 1 2990J 40n
preplace netloc xlslice_4_Dout 1 6 2 2710J 200 3010J
preplace netloc axi_bram_ctrl_2_bram_clk_a 1 3 2 1650 590 N
preplace netloc axi_bram_ctrl_2_bram_en_a 1 3 2 1650 710 N
preplace netloc axi_bram_ctrl_2_bram_wrdata_a 1 3 2 N 700 1850
preplace netloc axi_bram_ctrl_2_bram_we_a 1 3 2 1630 690 N
preplace netloc APU_0_data_out 1 3 3 1590 450 N 450 2220
preplace netloc APU_0_AC_ADR0 1 5 7 2240J 580 NJ 580 NJ 580 NJ 580 NJ 580 NJ 580 NJ
preplace netloc Net 1 5 7 NJ 710 NJ 710 NJ 710 NJ 710 NJ 710 NJ 710 4180J
preplace netloc APU_0_AC_SCK 1 5 7 NJ 690 NJ 690 NJ 690 NJ 690 NJ 690 NJ 690 4170J
preplace netloc APU_0_AC_MCLK 1 5 7 NJ 670 NJ 670 NJ 670 NJ 670 NJ 670 NJ 670 NJ
preplace netloc AC_GPIO3_0_1 1 0 5 20J -240 NJ -240 1190J 50 NJ 50 1880
preplace netloc AC_GPIO2_0_1 1 0 5 50J 90 NJ 90 NJ 90 NJ 90 1870
preplace netloc AC_GPIO1_0_1 1 0 5 40J -250 NJ -250 1240J 40 NJ 40 1850
preplace netloc APU_0_AC_GPIO0 1 5 7 2280J 640 NJ 640 NJ 640 NJ 640 NJ 640 NJ 640 NJ
preplace netloc APU_0_AC_ADR1 1 5 7 2250J 610 NJ 610 NJ 610 NJ 610 NJ 610 NJ 610 NJ
preplace netloc rst_clk_wiz_100M_interconnect_aresetn 1 4 7 1940 410 NJ 410 NJ 410 NJ 410 NJ 410 NJ 410 3930
preplace netloc axi_bram_ctrl_2_bram_addr_a 1 3 1 1550 510n
preplace netloc xlslice_5_Dout 1 4 1 1860 510n
preplace netloc RV32I_AXI_Bridge_0_M_AXI 1 1 8 910J 110 NJ 110 1590J -260 N -260 N -260 NJ -260 NJ -260 3270
preplace netloc axi_bram_ctrl_0_BRAM_PORTA 1 0 2 270 1160 790
preplace netloc axi_gpio_0_GPIO 1 11 1 4170 20n
preplace netloc axi_gpio_0_GPIO2 1 11 1 N 50
preplace netloc axi_smc_M00_AXI 1 0 10 230 -230 NJ -230 1200J -240 NJ -240 N -240 N -240 NJ -240 NJ -240 NJ -240 3530
preplace netloc axi_smc_M01_AXI 1 1 9 920 -260 NJ -260 1570J -230 N -230 N -230 NJ -230 NJ -230 NJ -230 3540
preplace netloc axi_smc_M02_AXI 1 2 8 1250 -250 1560J -220 N -220 N -220 NJ -220 NJ -220 NJ -220 3550
preplace netloc axi_smc_M03_AXI 1 9 2 3580J -20 3940
preplace netloc axi_uartlite_0_UART 1 2 10 1210J -230 1550J -210 N -210 N -210 NJ -210 NJ -210 NJ -210 NJ -210 NJ -210 4180
preplace netloc axi_smc_M04_AXI 1 2 8 1250 400 NJ 400 N 400 NJ 400 NJ 400 NJ 400 NJ 400 3530
levelinfo -pg 1 0 590 1040 1400 1750 2080 2490 2880 3160 3400 3760 4060 4200
pagesize -pg 1 -db -bbox -sgen -230 -270 4330 1170
"
}

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


