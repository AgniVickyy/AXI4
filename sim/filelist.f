// ============================================================================
// filelist.f — Compilation file list
// Usage: vcs -f filelist.f  |  xrun -f filelist.f
// ============================================================================

+incdir+../tb

// RTL
../rtl/axi4_lite_slave_pkg.sv
../rtl/axi4_lite_reg_block.sv
../rtl/axi4_lite_slave.sv
../rtl/axi4_lite_slave_sva.sv

// Testbench
../tb/axi4_lite_if.sv
../tb/axi4_lite_tb_pkg.sv
../tb/tb_top.sv
