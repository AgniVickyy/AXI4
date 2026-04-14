// ============================================================================
// axi4_lite_agent.sv — AXI4-Lite Agent
// ============================================================================
class axi4_lite_agent #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_agent;

  `uvm_component_param_utils(axi4_lite_agent#(DATA_WIDTH, ADDR_WIDTH))

  axi4_lite_driver  #(DATA_WIDTH, ADDR_WIDTH) driver;
  axi4_lite_monitor #(DATA_WIDTH, ADDR_WIDTH) monitor;
  uvm_sequencer #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)) sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = axi4_lite_monitor#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("monitor", this);
    if (get_is_active() == UVM_ACTIVE) begin
      driver    = axi4_lite_driver#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("driver", this);
      sequencer = uvm_sequencer#(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH))::type_id::create("sequencer", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass
