# =========================================================================================
# TCL GENERATION SCRIPT FOR APU PROJECT
# =========================================================================================

# 1. Setup Paths (Relative to the script's location)
set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set repo_root [file normalize "$script_dir/.."]

# 2. Project Configuration
set proj_name "APU"
set proj_dir "$repo_root/vivado-data/$proj_name"
set my_part "xc7z020clg484-1" ;

puts "--- Building Project: $proj_name"
puts "--- Origin Directory: $repo_root"
puts "--- Working Directory: $proj_dir"

# 3. Create Project (Force recreate if it exists)
# The project files are kept in 'vivado-data' which should be git-ignored
create_project $proj_name $proj_dir -part $my_part -force

# 4. Add RTL Sources (src/apu)
set rtl_files [glob -nocomplain "$repo_root/src/apu/*.{v,vhd}"]
if {[llength $rtl_files] > 0} {
    add_files $rtl_files
    puts "Added [llength $rtl_files] RTL files."
} else {
    puts "Warning: No RTL files found in $repo_root/src/apu/"
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

# 6. Add Constraints (constraints/)
# Using 'hardware/constraints' as the common folder
set xdc_files [glob -nocomplain "$repo_root/constraints/*.xdc"]
if {[llength $xdc_files] > 0} {
    add_files -fileset constrs_1 $xdc_files
    puts "Added [llength $xdc_files] constraint files."
}

# 7. Add Testbenches & Simulation Assets (test/apu)
set sim_files [glob -nocomplain "$repo_root/test/apu/*.{v,vhd,sv}"]
if {[llength $sim_files] > 0} {
    add_files -fileset sim_1 $sim_files
    puts "Added [llength $sim_files] simulation files."
}

# Add Memory Initialization files (.coe) to simulation fileset
set coe_files [glob -nocomplain "$repo_root/test/apu/coe/*.coe"]
if {[llength $coe_files] > 0} {
    add_files -fileset sim_1 $coe_files
}

# 8. Cleanup and Finalize
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "--- Project $proj_name creation complete."