// ============================================================================
// axi4_lite_coverage.sv — Functional Coverage Collector
// ============================================================================
class axi4_lite_coverage #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_subscriber #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH));

  `uvm_component_param_utils(axi4_lite_coverage#(DATA_WIDTH, ADDR_WIDTH))

  // Sampled fields
  logic [ADDR_WIDTH-1:0] addr;
  bit                    is_write;
  logic [1:0]            resp;

  // ---- Transaction coverage ----
  covergroup cg_transaction @(sample_event);
    cp_addr: coverpoint addr {
      bins ctrl       = {8'h00};
      bins status     = {8'h04};
      bins data_in    = {8'h08};
      bins data_out   = {8'h0C};
      bins irq_status = {8'h10};
      bins irq_mask   = {8'h14};
      bins scratch    = {8'h18};
      bins version    = {8'h1C};
      bins invalid    = default;
    }

    cp_rw: coverpoint is_write {
      bins read  = {0};
      bins write = {1};
    }

    cp_resp: coverpoint resp {
      bins okay   = {2'b00};
      bins slverr = {2'b10};
    }

    // Cross: every register accessed with both read and write
    cross_addr_rw: cross cp_addr, cp_rw;

    // Cross: responses per register
    cross_addr_resp: cross cp_addr, cp_resp;
  endgroup

  // ---- Data pattern coverage ----
  covergroup cg_data_patterns @(sample_event);
    cp_data_write: coverpoint axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)'(last_item).data
      iff (is_write) {
      bins zero      = {0};
      bins all_ones  = {{DATA_WIDTH{1'b1}}};
      bins walking_0 = {32'hFFFFFFFE, 32'hFFFFFFFD, 32'hFFFFFFFB, 32'hFFFFFFF7};
      bins walking_1 = {32'h00000001, 32'h00000002, 32'h00000004, 32'h00000008};
      bins others    = default;
    }
  endgroup

  // ---- Register access sequence coverage ----
  covergroup cg_access_sequences @(sample_event);
    cp_access_type: coverpoint {is_write, addr[4:2]} {
      // Write then read same register (captured via transitions)
      bins wr_ctrl      = {4'b1_000};
      bins rd_ctrl      = {4'b0_000};
      bins wr_data_in   = {4'b1_010};
      bins rd_data_in   = {4'b0_010};
      bins wr_scratch   = {4'b1_110};
      bins rd_scratch   = {4'b0_110};
    }
  endgroup

  event sample_event;
  axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) last_item;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_transaction     = new();
    cg_data_patterns   = new();
    cg_access_sequences = new();
  endfunction

  function void write(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) t);
    last_item = t;
    addr      = t.addr;
    is_write  = t.write;
    resp      = t.resp;
    -> sample_event;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV", $sformatf("Transaction coverage:  %.1f%%", cg_transaction.get_coverage()), UVM_LOW)
    `uvm_info("COV", $sformatf("Data pattern coverage: %.1f%%", cg_data_patterns.get_coverage()), UVM_LOW)
    `uvm_info("COV", $sformatf("Access seq coverage:   %.1f%%", cg_access_sequences.get_coverage()), UVM_LOW)
  endfunction

endclass
