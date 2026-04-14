// ============================================================================
// tb_top.sv — Top-level testbench harness
// ============================================================================
`timescale 1ns/1ps

module tb_top;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Parameters
  localparam int DATA_WIDTH = 32;
  localparam int ADDR_WIDTH = 8;

  // Clock and reset
  logic aclk    = 0;
  logic aresetn = 0;

  always #5 aclk = ~aclk;  // 100 MHz

  // Interface
  axi4_lite_if #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) axi_if (
    .aclk    (aclk),
    .aresetn (aresetn)
  );

  // DUT
  axi4_lite_slave #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) dut (
    .aclk          (aclk),
    .aresetn       (aresetn),
    .s_axi_awaddr  (axi_if.awaddr),
    .s_axi_awprot  (axi_if.awprot),
    .s_axi_awvalid (axi_if.awvalid),
    .s_axi_awready (axi_if.awready),
    .s_axi_wdata   (axi_if.wdata),
    .s_axi_wstrb   (axi_if.wstrb),
    .s_axi_wvalid  (axi_if.wvalid),
    .s_axi_wready  (axi_if.wready),
    .s_axi_bresp   (axi_if.bresp),
    .s_axi_bvalid  (axi_if.bvalid),
    .s_axi_bready  (axi_if.bready),
    .s_axi_araddr  (axi_if.araddr),
    .s_axi_arprot  (axi_if.arprot),
    .s_axi_arvalid (axi_if.arvalid),
    .s_axi_arready (axi_if.arready),
    .s_axi_rdata   (axi_if.rdata),
    .s_axi_rresp   (axi_if.rresp),
    .s_axi_rvalid  (axi_if.rvalid),
    .s_axi_rready  (axi_if.rready),
    .irq_out       (axi_if.irq_out)
  );

  // Bind SVA assertions
  bind axi4_lite_slave axi4_lite_slave_sva #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_sva (.*);

  // Reset sequence
  initial begin
    aresetn = 0;
    repeat (20) @(posedge aclk);
    aresetn = 1;
  end

  // UVM config & run
  initial begin
    uvm_config_db#(virtual axi4_lite_if#(DATA_WIDTH, ADDR_WIDTH))::set(null, "*", "vif", axi_if);
    run_test();
  end

  // Timeout
  initial begin
    #1_000_000;
    `uvm_fatal("TIMEOUT", "Simulation timed out at 1ms")
  end

  // Waveform dump
  initial begin
    $dumpfile("axi4_lite_slave.vcd");
    $dumpvars(0, tb_top);
  end

endmodule
