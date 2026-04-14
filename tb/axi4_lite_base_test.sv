// ============================================================================
// axi4_lite_base_test.sv — Base test + derived tests
// ============================================================================

// ---------------------------------------------------------------------------
// Base test — env setup, reset, RAL handle propagation
// ---------------------------------------------------------------------------
class axi4_lite_base_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_test;

  `uvm_component_param_utils(axi4_lite_base_test#(DATA_WIDTH, ADDR_WIDTH))

  axi4_lite_env #(DATA_WIDTH, ADDR_WIDTH) env;
  virtual axi4_lite_if #(DATA_WIDTH, ADDR_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axi4_lite_env#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("env", this);

    if (!uvm_config_db#(virtual axi4_lite_if#(DATA_WIDTH, ADDR_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "No virtual interface in config_db")
  endfunction

  task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    vif.awvalid = 0;
    vif.wvalid  = 0;
    vif.bready  = 0;
    vif.arvalid = 0;
    vif.rready  = 0;

    @(negedge vif.aclk);
    // aresetn is driven by tb_top; wait for it
    wait (vif.aresetn === 1'b1);
    repeat (5) @(posedge vif.aclk);

    // Reset RAL model to match hardware
    env.ral.reset();

    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 1: RAL Frontdoor — register read/write via bus
// ---------------------------------------------------------------------------
class axi4_lite_ral_frontdoor_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends axi4_lite_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(axi4_lite_ral_frontdoor_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    axi4_lite_ral_frontdoor_seq seq;

    phase.raise_objection(this);

    seq = axi4_lite_ral_frontdoor_seq::type_id::create("seq");
    seq.ral = env.ral;
    seq.start(env.agent.sequencer);

    #200;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 2: RAL Field-level — fine-grained field access + loopback
// ---------------------------------------------------------------------------
class axi4_lite_ral_field_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends axi4_lite_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(axi4_lite_ral_field_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    axi4_lite_ral_field_seq seq;

    phase.raise_objection(this);

    seq = axi4_lite_ral_field_seq::type_id::create("seq");
    seq.ral = env.ral;
    seq.start(env.agent.sequencer);

    #200;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 3: Walking-1s/0s — exhaustive bit-level integrity
// ---------------------------------------------------------------------------
class axi4_lite_walking_ones_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends axi4_lite_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(axi4_lite_walking_ones_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    axi4_lite_walking_ones_seq#(DATA_WIDTH, ADDR_WIDTH) seq;

    phase.raise_objection(this);

    seq = axi4_lite_walking_ones_seq#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #200;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 4: Invalid address SLVERR
// ---------------------------------------------------------------------------
class axi4_lite_invalid_addr_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends axi4_lite_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(axi4_lite_invalid_addr_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    axi4_lite_invalid_addr_seq#(DATA_WIDTH, ADDR_WIDTH) seq;

    phase.raise_objection(this);

    seq = axi4_lite_invalid_addr_seq#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #200;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 5: Byte strobe
// ---------------------------------------------------------------------------
class axi4_lite_strobe_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends axi4_lite_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(axi4_lite_strobe_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    axi4_lite_strobe_seq#(DATA_WIDTH, ADDR_WIDTH) seq;

    phase.raise_objection(this);

    seq = axi4_lite_strobe_seq#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("seq");
    seq.start(env.agent.sequencer);

    #200;
    phase.drop_objection(this);
  endtask

endclass

// ---------------------------------------------------------------------------
// Test 6: Reset value check via RAL
// ---------------------------------------------------------------------------
class axi4_lite_reset_test #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends axi4_lite_base_test #(DATA_WIDTH, ADDR_WIDTH);

  `uvm_component_param_utils(axi4_lite_reset_test#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task main_phase(uvm_phase phase);
    axi4_lite_ral_reset_seq seq;

    phase.raise_objection(this);

    seq = axi4_lite_ral_reset_seq::type_id::create("seq");
    seq.ral = env.ral;
    seq.start(env.agent.sequencer);

    #200;
    phase.drop_objection(this);
  endtask

endclass
