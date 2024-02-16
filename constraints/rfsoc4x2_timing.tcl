######## CONVENIENCE FUNCTIONS

proc set_cc_paths { srcClk dstClk ctlist } {
    array set ctypes $ctlist
    set srcType $ctypes($srcClk)
    set dstType $ctypes($dstClk)
    set maxTime [get_property PERIOD $srcClk]
    set srcRegs [get_cells -hier -filter "CUSTOM_CC_SRC == $srcType"]
    set dstRegs [get_cells -hier -filter "CUSTOM_CC_DST == $dstType"]
    if { ([llen $srcRegs] > 0) && ([llen $dstRegs] > 0) } {
        set_max_delay -datapath_only -from $srcRegs -to $dstRegs $maxTime
    }
}

proc set_gray_paths { srcClk dstClk ctlist } {
    array set ctypes $ctlist
    set maxTime [get_property PERIOD $srcClk]
    set maxSkew [expr min([get_property PERIOD $srcClk], [get_property PERIOD $dstClk])]
    set srcRegs [get_cells -hier -filter "CUSTOM_GRAY_SRC == $ctypes($srcClk)"]
    set dstRegs [get_cells -hier -filter "CUSTOM_GRAY_DST == $ctypes($dstClk)"]
    if { ([llen $srcRegs] > 0) && ([llen $dstRegs] > 0) } {
        set_max_delay -datapath_only -from $srcRegs -to $dstRegs $maxTime
        set_bus_skew -from $srcRegs -to $dstRegs $maxSkew
    }
}

proc set_ignore_paths { srcClk dstClk ctlist } {
    array set ctypes $ctlist
    set srcRegs [get_cells -hier -filter "CUSTOM_IGN_SRC == $ctypes($srcClk)"]
    set dstRegs [get_cells -hier -filter "CUSTOM_IGN_DST == $ctypes($dstClk)"]
    if { ([llen $srcRegs] > 0) && ([llen $dstRegs] > 0) } {
        set_false_path -from $srcRegs -to $dstRegs
    }
}

######## END CONVENIENCE FUNCTIONS

######## CLOCK DEFINITIONS
# aclk is a pin clock
set aclk [create_clock -period 2.667 -name aclkin [get_ports -filter { NAME =~ "FPGA_REFCLK_IN_P" && DIRECTION == "IN" }]]
set clktypes($aclk) ACLK

set aclkdiv2 [get_clocks -of_objects [get_nets -hier -filter { NAME =~ "aclk_div2" }]]
set clktypes($aclkdiv2) ACLKDIV2

set psclk [get_clocks -of_objects [get_nets -hier -filter { NAME =~ "ps_clk" }]]
set clktypes($psclk) PSCLK

#### convenience def
# create the clktypelist variable to save
set clktypelist [array get clktypes]

# magic grab all of the flag_sync'd guys. This is not ideal but it'll work for now.
set sync_flag_regs [get_cells -hier -filter {NAME =~ *FlagToggle_clkA_reg*}]
set sync_sync_regs [get_cells -hier -filter {NAME =~ *SyncA_clkB_reg*}]
set sync_syncB_regs [get_cells -hier -filter {NAME =~ *SyncB_clkA_reg*}]
set_max_delay -datapath_only -from $sync_flag_regs -to $sync_sync_regs 10.000
set_max_delay -datapath_only -from $sync_sync_regs -to $sync_syncB_regs 10.000

# magic grab all of the CUSTOM_CC_SRC/DST
set_cc_paths $aclk $psclk $clktypelist
set_cc_paths $psclk $aclk $clktypelist

set_cc_paths $aclkdiv2 $psclk $clktypelist
set_cc_paths $psclk $aclkdiv2 $clktypelist

set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# guard against dumbassery
set my_dbg_hub [get_debug_cores dbg_hub -quiet]
if {[llength $my_dbg_hub] > 0} {
   set_property C_CLK_INPUT_FREQ_HZ 300000000 $my_dbg_hub
   set_property C_ENABLE_CLK_DIVIDER false $my_dbg_hub
   set_property C_USER_SCAN_CHAIN 1 $my_dbg_hub
   connect_debug_port dbg_hub/clk ps_clk
} else {
   puts "skipping debug hub commands, not inserted yet"
}
