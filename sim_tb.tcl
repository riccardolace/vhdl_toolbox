
# Set the name of the project folder
set prjName "prj_tb"

# If the folder exists, it will be deleted
if {[file exist $prjName]} {
  # Check that it's a directory
  if {[file isdirectory $prjName]} {
    puts "$prjName exists, it's a folder and will be deleted."
    # Remove the folder
		file delete -force $prjName
		
		# Create the folder
		file mkdir $prjName
  }
} else {
  puts "$prjName exists, but it's a file."
}


# Create project
create_project $prjName $prjName

# Set language
set_property target_language VHDL [current_project]

# File list of 'basic'
set fileList_vhdl {*}[glob basic/counter/vhdl/*.vhd]
set fileList_tb   {*}[glob basic/counter/testbench/*.vhd]

lappend fileList_vhdl {*}[glob basic/delay/vhdl/*.vhd]
lappend fileList_tb   {*}[glob basic/delay/testbench/*.vhd]

# File list of 'clock_domain_crossing'
lappend fileList_vhdl {*}[glob clock_domain_crossing/vhdl/*.vhd]

# File list of 'math'
lappend fileList_vhdl {*}[glob math/rounding/vhdl/*.vhd]
lappend fileList_tb   {*}[glob math/rounding/testbench/*.vhd]

# File list of 'math'
lappend fileList_vhdl {*}[glob memory/fifo/vhdl/*.vhd]
lappend fileList_vhdl {*}[glob memory/ram/vhdl/*.vhd]
lappend fileList_vhdl {*}[glob memory/rom/vhdl/*.vhd]
#lappend fileList_tb   {*}[glob memory/fifo/testbench/*.vhd]
#lappend fileList_tb   {*}[glob memory/ram/testbench/*.vhd]
lappend fileList_tb   {*}[glob memory/rom/testbench/*.vhd]

# File list of 'package'
lappend fileList_vhdl {*}[glob packages/vhdl/*.vhd]

puts $fileList_vhdl
puts $fileList_tb

# Add sources files in the project
add_files $fileList_vhdl

# Add testbench files in the project
add_files $fileList_tb
move_files -fileset sim_1 [get_files $fileList_tb]

# Set top (sources)
set_property top counter_with_hit [current_fileset]

# Set top (testbench)
set_property top counter_with_hit_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

