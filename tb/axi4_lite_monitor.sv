// ============================================================================
// axi4_lite_monitor.sv — AXI4-Lite Bus Monitor
// ============================================================================
class axi4_lite_monitor #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_monitor;

  `uvm_component_param_utils(axi4_lite_monitor#(DATA_WIDTH, ADDR_WIDTH))

  virtual axi4_lite_if #(DATA_WIDTH, ADDR_WIDTH) vif;

  uvm_analysis_port #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual axi4_lite_if#(DATA_WIDTH, ADDR_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found for axi4_lite_monitor")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_writes();
      monitor_reads();
    join
  endtask

  // ---- Monitor write transactions ----
  task monitor_writes();
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;
    logic [ADDR_WIDTH-1:0]   addr;
    logic [DATA_WIDTH-1:0]   data;
    logic [DATA_WIDTH/8-1:0] strb;

    forever begin
      // Capture AW and W independently, then B
      fork
        // AW handshake
        begin
          forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin
              addr = vif.monitor_cb.awaddr;
              break;
            end
          end
        end
        // W handshake
        begin
          forever begin
            @(vif.monitor_cb);
            if (vif.monitor_cb.wvalid && vif.monitor_cb.wready) begin
              data = vif.monitor_cb.wdata;
              strb = vif.monitor_cb.wstrb;
              break;
            end
          end
        end
      join

      // B handshake
      forever begin
        @(vif.monitor_cb);
        if (vif.monitor_cb.bvalid && vif.monitor_cb.bready) begin
          item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("wr_item");
          item.write = 1;
          item.addr  = addr;
          item.data  = data;
          item.strb  = strb;
          item.resp  = vif.monitor_cb.bresp;
          ap.write(item);
          `uvm_info("MON", $sformatf("WR: %s", item.convert2string()), UVM_HIGH)
          break;
        end
      end
    end
  endtask

  // ---- Monitor read transactions ----
  task monitor_reads();
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;
    logic [ADDR_WIDTH-1:0] addr;

    forever begin
      // AR handshake
      forever begin
        @(vif.monitor_cb);
        if (vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin
          addr = vif.monitor_cb.araddr;
          break;
        end
      end

      // R handshake
      forever begin
        @(vif.monitor_cb);
        if (vif.monitor_cb.rvalid && vif.monitor_cb.rready) begin
          item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("rd_item");
          item.write = 0;
          item.addr  = addr;
          item.rdata = vif.monitor_cb.rdata;
          item.resp  = vif.monitor_cb.rresp;
          ap.write(item);
          `uvm_info("MON", $sformatf("RD: %s", item.convert2string()), UVM_HIGH)
          break;
        end
      end
    end
  endtask

endclass
