// ============================================================================
// axi4_lite_tb_pkg.sv — Testbench package (compilation order)
// ============================================================================
package axi4_lite_tb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import axi4_lite_slave_pkg::*;

  // Transaction
  `include "axi4_lite_seq_item.sv"

  // Driver + Monitor
  `include "axi4_lite_driver.sv"
  `include "axi4_lite_monitor.sv"

  // Agent
  `include "axi4_lite_agent.sv"

  // RAL model + adapter
  `include "axi4_lite_ral_model.sv"
  `include "axi4_lite_ral_adapter.sv"

  // Scoreboard + Coverage
  `include "axi4_lite_scoreboard.sv"
  `include "axi4_lite_coverage.sv"

  // Environment
  `include "axi4_lite_env.sv"

  // Sequences
  `include "axi4_lite_sequences.sv"

  // Tests
  `include "axi4_lite_base_test.sv"

endpackage
