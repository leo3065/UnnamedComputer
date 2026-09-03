# 
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and any partner logic
# functions, and any output files from any of the foregoing
# (including device programming or simulation files), and any
# associated documentation or information are expressly subject
# to the terms and conditions of the Altera Program License
# Subscription Agreement, the Altera Quartus Prime License Agreement,
# the Altera FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Altera and sold by Altera or its authorized distributors.

# ACDS 26.1.1 130 win32 2026.09.03.20:05:15
# ----------------------------------------
# Auto-generated simulation script run_msim_setup.tcl
# ----------------------------------------
# This script provides commands to run the msim_setup.tcl script for the following IP detected in
# your Quartus project:
#     reset_release
# 
# 
# Altera recommends that you source this Quartus-generated IP simulation
# script to compile, elab and run the design without any customization.
# For customization, please follow the steps mentioned in msim_setup.tcl.

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
}

source $QSYS_SIMDIR/mentor/msim_setup.tcl
ld
run -all
quit
