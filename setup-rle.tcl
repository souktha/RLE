###############################################################################################
# $Rev: 54 $
# $Date: 2016-03-26 11:18:02 -0700 (Sat, 26 Mar 2016) $
# $Author: ssop $
#
###############################################################################################
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
#if { [info exists ::origin_dir_loc] } {
#  set origin_dir $::origin_dir_loc
#}
set work_directory [pwd]
variable script_file
set script_file "setup-rle.tcl"


proc create {} {
cd [pwd]
create_project -force rle -part xc7a100tcsg324-1 
#constraint file not used for this simulation.
add_files -norecurse {rle.v }
#import_ip -files {ipfile.xci}
import_files -force -norecurse
import_files -fileset sim_1 -norecurse {rle_tb.v}
update_compile_order -fileset sim_1
}

proc run {} {
if [string is alnum [current_project -quiet]] then {open_project .  rle.xpr} else {puts "project is [current_project]"}

reset_run -quiet synth_1
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1
wait_on_run impl_1
}

proc sim {} {
if [string is alnum [current_project -quiet]] then {open_project ./rle.xpr} else {puts "project is [current_project]"}
if [string is alnum [current_sim -quiet]] then {} else {close_sim}
set_property xsim.view {rle_tb.wcfg} [get_filesets sim_1]
launch_xsim -simset sim_1 -mode behavioral
run 5 ms
}




namespace path {::tcl::mathop ::tcl::mathfunc}

proc hex2bin {hex} {
    return [string map -nocase {
        0 0000 1 0001 2 0010 3 0011 4 0100 5 0101 6 0110 7 0111 8 1000
        9 1001 a 1010 b 1011 c 1100 d 1101 e 1110 f 1111
        } $hex]

#        9 1001 a 1010 b 1011 c 1100 d 1101 e 1110 f 1111 A 1010 B 1011 C 1100 D 1101 E 1110 F 1111
}

proc help {} {
    puts "Simple rle demo
\n\nTCL script sets up the following commands:                                              \
\n     create - Creates/overwrites ./rle project         \
\n                            NOTE <create_project> completely rebuilds the project. Previous work will be lost.   \
\n     run    - Opens and runs ./rle.xpr project             \
\n     sim    - Performs behavioral simulation using the testbench. \
"
}

help

