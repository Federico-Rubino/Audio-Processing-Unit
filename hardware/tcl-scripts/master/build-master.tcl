# =========================================================================================
# TCL GENERATION SCRIPT FOR MASTER PROJECT
# =========================================================================================

# 1. Setup Paths (Relative to the script's location)
set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set repo_root [file normalize "$script_dir/../.."]

# 2. Project Configuration
set proj_name "master"
set proj_dir "$repo_root/vivado-data/$proj_name"
set my_part "xc7z020clg484-1" ;

puts "--- Building Project: $proj_name"
puts "--- Origin Directory: $repo_root"
puts "--- Working Directory: $proj_dir"

# 3. Create Project (Force recreate if it exists)
# The project files are kept in 'vivado-data' which should be git-ignored
create_project $proj_name $proj_dir -part $my_part -force

# 3b. Configure IP Repository Paths
# -----------------------------------------------------------------------------------------
set custom_ip_repo "$repo_root/src/master/ip_repo"
if {[file exists $custom_ip_repo]} {
    set_property  ip_repo_paths  $custom_ip_repo [current_project]
    update_ip_catalog
    puts "--- Custom IP Repository added: $custom_ip_repo"
}

# 4. Add RTL Sources (src/rv32i)
set rtl_files [glob -nocomplain "$repo_root/src/rv32i/*.{v,vhd,sv}"]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    puts "Added [llength $rtl_files] RTL files."
} else {
    puts "Warning: No RTL files found in $repo_root/src/rv32i/"
}

# 4. Add RTL Sources (src/apu + audioIO/, audioIO/zedboard_audio/hdl/, memory_controller/, memory_controller/bmu/)
set rtl_files [glob -nocomplain \
    "$repo_root/src/apu/*.{v,vhd,sv}" \
    "$repo_root/src/apu/audioIO/*.{v,vhd,sv}" \
    "$repo_root/src/apu/audioIO/zedboard_audio/hdl/*.{v,vhd,sv}" \
    "$repo_root/src/apu/memory_controller/*.{v,vhd,sv}" \
    "$repo_root/src/apu/memory_controller/bmu/*.{v,vhd,sv}" \
]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    foreach f $rtl_files {
        set_property file_type "VHDL 2008" [get_files $f]
    }
    puts "Added [llength $rtl_files] RTL files."
} else {
    puts "Warning: No RTL files found in $repo_root/src/apu/"
}

# 4. Add RTL Sources (src/master)
set rtl_files [glob -nocomplain "$repo_root/src/master/*.{v,vhd,sv}"]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    puts "Added [llength $rtl_files] RTL files."
} else {
    puts "Warning: No RTL files found in $repo_root/src/master/"
}

# 5. Add IP Cores (ip/master)
# search recursively (**) to find .xci files in subdirectories
set ip_files [glob -nocomplain "$repo_root/ip/master/**/*.xci"]
if {[llength $ip_files] > 0} {
    # 'import_ip' copies the IP config into the local project work area
    import_ip $ip_files
    puts "Imported [llength $ip_files] IP cores."
} else {
    puts "Note: No IP (.xci) files found for master."
}

# 5. Add IP Cores (ip/apu)
# search recursively (**) to find .xci files in subdirectories
set ip_files [glob -nocomplain "$repo_root/ip/apu/**/*.xci"]
if {[llength $ip_files] > 0} {
    # 'import_ip' copies the IP config into the local project work area
    import_ip $ip_files
    puts "Imported [llength $ip_files] IP cores."
} else {
    puts "Note: No IP (.xci) files found for apu."
}


# 5b. Reconstruct Block Design (scripts/master/recreate-bd.tcl)
# -----------------------------------------------------------------------------------------
set bd_script "$repo_root/tcl-scripts/master/recreate-bd.tcl"

if {[file exists $bd_script]} {
    puts "--- Reconstructing Block Design from script..."
    
    # 1. Source the script (Ensure the "MAIN FLOW" block at the bottom of recreate-bd.tcl is commented out)
    source $bd_script
    
    # 2. Define the BD name explicitly (Make sure this matches what you called it originally)
    set bd_name "top_module" 

    # 3. Clean up any existing BD to avoid the "sys_clk already exists" error
    if { [get_bd_designs -quiet $bd_name] ne "" } {
        close_bd_design [get_bd_designs $bd_name]
        remove_files [get_files -quiet ${bd_name}.bd]
    }

    # 4. Create the blank Block Design and open it
    create_bd_design $bd_name
    current_bd_design $bd_name

    # 5. Populate the design (Passing "" tells Vivado to put everything at the root level)
    create_root_design ""
    
    # 6. Generate the wrapper
    set bd_file [get_files ${bd_name}.bd]
    # make_wrapper returns the path of the generated file directly
    set wrapper_file [make_wrapper -files $bd_file -top]
    add_files -norecurse $wrapper_file
    
    puts "--- Block Design $bd_name reconstructed and wrapper added."
} else {
    puts "Note: No BD reconstruction script found at $bd_script"
}

# 6. Add Constraints (constraints/)
# Using 'hardware/constraints' as the common folder
set xdc_files [glob -nocomplain "$repo_root/constraints/*.xdc"]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
    puts "Added [llength $xdc_files] constraint files."
}

# 7. Add Testbenches & Simulation Assets (test/master)
set sim_files [glob -nocomplain "$repo_root/test/master/*.{v,vhd,sv}"]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
    puts "Added [llength $sim_files] simulation files."
}

# 7. Add Testbenches & Simulation Assets (test/apu)
set sim_files [glob -nocomplain "$repo_root/test/apu/*.{v,vhd,sv}"]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
    puts "Added [llength $sim_files] simulation files."
}

# Add Memory Initialization files (.coe) to simulation fileset
set coe_files [glob -nocomplain "$repo_root/test/master/*.coe"]
if {[llength $coe_files] > 0} {
    add_files -fileset sim_1 $coe_files
}


set_property target_language VHDL [current_project]

# 8. Cleanup and Finalize
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "--- Project $proj_name creation complete."