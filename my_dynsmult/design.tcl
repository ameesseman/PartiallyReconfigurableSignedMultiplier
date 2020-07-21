###############################################################
###   Tcl Variables
###############################################################
#set tclParams [list <param1> <value> <param2> <value> ... <paramN> <value>]
set tclParams [list hd.visual 1] 

#Define location for "Tcl" directory. Defaults to "./Tcl"
set tclHome "../../../../Tcl"
if {[file exists $tclHome]} {
   set tclDir $tclHome
} elseif {[file exists "./Tcl"]} {
   set tclDir  "./Tcl"
} else {
   error "ERROR: No valid location found for required Tcl scripts. Set \$tclDir in design.tcl to a valid location."
}

###############################################################
### Define Part, Package, Speedgrade 
###############################################################
set device       "xc7z010"
set package      "clg400"
set speed        "-1"
set part         $device$package$speed

###############################################################
###  Setup Variables
###############################################################

####flow control
set run.topSynth       1
set run.rmSynth        1
set run.prImpl         0
set run.prVerify       0
set run.writeBitstream 0

####Report and DCP controls - values: 0-required min; 1-few extra; 2-all
set verbose      1
set dcpLevel     1

####Output Directories
set synthDir  "./Synth"
set implDir   "./Implement"
set dcpDir    "./Checkpoint"
set bitDir    "./Bitstreams"

####Input Directories
set srcDir     "./Sources"
set rtlDir     "$srcDir/hdl"
set prjDir     "$srcDir/prj"
set xdcDir     "$srcDir/xdc"
set coreDir    "$srcDir/cores"
set netlistDir "$srcDir/netlist"

set lib  "work"

####Source required Tcl Procs
source $tclDir/design_utils.tcl
source $tclDir/synth_utils.tcl
source $tclDir/impl_utils.tcl
source $tclDir/hd_floorplan_utils.tcl

###############################################################
### Top Definition
###############################################################
set top "top"
set static "Static"
###add_module $static ### no vhdl files for static (only the .dcp file)

###set_attribute module $static moduleName    $top
###set_attribute module $static top_level     1
###set_attribute module $static vhdl          [list [glob $rtlDir/$top/*.vhd]]
###set_attribute module $static synth         ${run.topSynth}


####################################################################
### RP Module Definitions
####################################################################
set module1 "sam_2c_rp"

set module1_variant1 "mult_2c"
set variant $module1_variant1
add_module $variant
set_attribute module $variant moduleName   $module1
#set_attribute module $variant vhdl         [list $rtlDir/$variant/$variant.vhd]
set_attribute module $variant vhdl          [list [glob $rtlDir/$variant/*.vhd]]
set_attribute module $variant synth        ${run.rmSynth}

set module1_variant2 "mult_sm"
set variant $module1_variant2
add_module $variant
set_attribute module $variant moduleName   $module1
#set_attribute module $variant vhdl         [list $rtlDir/$variant/$variant.vhd]
set_attribute module $variant vhdl          [list [glob $rtlDir/$variant/*.vhd]]
set_attribute module $variant synth        ${run.rmSynth}

set module1_inst "rP"
#<path>/ga = design_1_i/mysmult_static_0/U0/mysmult_static_v1_0_S00_AXI_inst/th/th/ji/rP

########################################################################
### Configuration (Implementation) Definition - Replicate for each Config
########################################################################
set config "Config_${module1_variant1}" 

add_config $config
set_attribute config $config top             $top
set_attribute config $config implXDC         [list $xdcDir/${top}.xdc]
set_attribute config $config impl            ${run.prImpl} 
set_attribute config $config settings        [list [list $static           $top           implement] \
                                                   [list $module1_variant1 $module1_inst implement] \
                                             ]
set_attribute config $config verify     	 ${run.prVerify} 
set_attribute config $config bitstream  	 ${run.writeBitstream} 

########################################################################
### Configuration (Implementation) Definition - Replicate for each Config
########################################################################
set config "Config_${module1_variant2}" 

add_config $config
set_attribute config $config top             $top
set_attribute config $config implXDC         [list $xdcDir/${top}.xdc]
set_attribute config $config impl            ${run.prImpl} 
set_attribute config $config settings        [list [list $static           $top          import]    \
                                                   [list $module1_variant2 $module1_inst implement] \
                                             ]
set_attribute config $config verify     	 ${run.prVerify} 
set_attribute config $config bitstream  	 ${run.writeBitstream} 

########################################################################
### Task / flow portion
########################################################################
# Build the designs
source $tclDir/run.tcl

#exit
