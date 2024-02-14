# Returns the base directory of the project. Assumes
# the project is stored in a subdirectory of the repository top level
# e.g. repo is "this_project", and project is in "this_project/vivado_project"
proc get_repo_dir {} {
    set projdir [get_property DIRECTORY [current_project]]
    set projdirlist [ file split $projdir ]
    set basedirlist [ lreplace $projdirlist end end ]
    return [ file join {*}$basedirlist ]
}

source [file join [get_repo_dir] verilog-library-barawn tclbits utility.tcl]
source [file join [get_repo_dir] verilog-library-barawn tclbits repo_files.tcl]

add_include_dir [file join [get_repo_dir] verilog-library-barawn include]

check_all
