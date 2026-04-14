# ============================================================================
# Makefile for AXI4-Lite Slave simulation
# Supports: VCS, Xcelium, Questa/ModelSim
# ============================================================================

RTL_DIR  = ../rtl
TB_DIR   = ../tb
TOP      = tb_top
TEST     ?= axi4_lite_ral_frontdoor_test

# RTL files
RTL_FILES = \
  $(RTL_DIR)/axi4_lite_slave_pkg.sv \
  $(RTL_DIR)/axi4_lite_reg_block.sv \
  $(RTL_DIR)/axi4_lite_slave.sv \
  $(RTL_DIR)/axi4_lite_slave_sva.sv

# TB files
TB_FILES = \
  $(TB_DIR)/axi4_lite_if.sv \
  $(TB_DIR)/axi4_lite_tb_pkg.sv \
  $(TB_DIR)/tb_top.sv

# ---- VCS ----
vcs: compile_vcs run_vcs

compile_vcs:
	vcs -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
	    +incdir+$(TB_DIR) \
	    $(RTL_FILES) $(TB_FILES) \
	    -o simv -debug_access+all

run_vcs:
	./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM

# ---- Xcelium ----
xrun:
	xrun -sv -uvm -access +rwc -timescale 1ns/1ps \
	     +incdir+$(TB_DIR) \
	     $(RTL_FILES) $(TB_FILES) \
	     -top $(TOP) \
	     +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM

# ---- Questa/ModelSim ----
questa: compile_questa run_questa

compile_questa:
	vlib work
	vlog -sv +incdir+$(TB_DIR) $(RTL_FILES) $(TB_FILES)

run_questa:
	vsim -c $(TOP) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=UVM_MEDIUM -do "run -all; quit"

# ---- Run all tests ----
regression:
	$(MAKE) vcs TEST=axi4_lite_ral_frontdoor_test
	$(MAKE) run_vcs TEST=axi4_lite_ral_field_test
	$(MAKE) run_vcs TEST=axi4_lite_walking_ones_test
	$(MAKE) run_vcs TEST=axi4_lite_invalid_addr_test
	$(MAKE) run_vcs TEST=axi4_lite_strobe_test
	$(MAKE) run_vcs TEST=axi4_lite_reset_test

# ---- Utilities ----
clean:
	rm -rf simv simv.daidir csrc *.vcd work transcript *.log xcelium.d .bpad

.PHONY: vcs compile_vcs run_vcs xrun questa compile_questa run_questa regression clean
