// ============================================================================
// axi4_lite_env.sv — UVM Environment with RAL integration
// ============================================================================
class axi4_lite_env #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_env;

  `uvm_component_param_utils(axi4_lite_env#(DATA_WIDTH, ADDR_WIDTH))

  // Components
  axi4_lite_agent       #(DATA_WIDTH, ADDR_WIDTH)  agent;
  axi4_lite_scoreboard  #(DATA_WIDTH, ADDR_WIDTH)  scoreboard;
  axi4_lite_coverage    #(DATA_WIDTH, ADDR_WIDTH)  coverage_coll;

  // RAL
  axi4_lite_reg_model                              ral;
  axi4_lite_ral_adapter #(DATA_WIDTH, ADDR_WIDTH)  adapter;
  uvm_reg_predictor #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)) predictor;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Agent
    agent      = axi4_lite_agent#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("agent", this);
    scoreboard = axi4_lite_scoreboard#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("scoreboard", this);
    coverage_coll = axi4_lite_coverage#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("coverage_coll", this);

    // RAL model
    ral = axi4_lite_reg_model::type_id::create("ral");
    ral.build();
    ral.reset();

    // RAL adapter
    adapter = axi4_lite_ral_adapter#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("adapter");

    // RAL predictor (auto-updates mirror from observed bus transactions)
    predictor = uvm_reg_predictor#(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH))::type_id::create("predictor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect RAL to sequencer via adapter
    ral.default_map.set_sequencer(agent.sequencer, adapter);
    ral.default_map.set_auto_predict(0);  // Use explicit predictor

    // Connect predictor
    predictor.map     = ral.default_map;
    predictor.adapter = adapter;
    agent.monitor.ap.connect(predictor.bus_in);

    // Connect scoreboard + coverage
    agent.monitor.ap.connect(scoreboard.ap);
    agent.monitor.ap.connect(coverage_coll.analysis_export);

    // Give scoreboard access to RAL
    scoreboard.ral = ral;
  endfunction

endclass
