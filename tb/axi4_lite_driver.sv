// ============================================================================
// axi4_lite_driver.sv — AXI4-Lite Master Driver
// ============================================================================
class axi4_lite_driver #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_driver #(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH));

  `uvm_component_param_utils(axi4_lite_driver#(DATA_WIDTH, ADDR_WIDTH))

  virtual axi4_lite_if #(DATA_WIDTH, ADDR_WIDTH) vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_lite_if#(DATA_WIDTH, ADDR_WIDTH))::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not found for axi4_lite_driver")
  endfunction

  task run_phase(uvm_phase phase);
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;

    // Initialize all outputs
    vif.master_cb.awvalid <= 1'b0;
    vif.master_cb.wvalid  <= 1'b0;
    vif.master_cb.bready  <= 1'b0;
    vif.master_cb.arvalid <= 1'b0;
    vif.master_cb.rready  <= 1'b0;

    forever begin
      seq_item_port.get_next_item(item);

      if (item.write)
        drive_write(item);
      else
        drive_read(item);

      seq_item_port.item_done(item);
    end
  endtask

  // ---- Write transaction ----
  task drive_write(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item);
    // Phase 1: AW + W simultaneously
    @(vif.master_cb);
    vif.master_cb.awaddr  <= item.addr;
    vif.master_cb.awprot  <= item.prot;
    vif.master_cb.awvalid <= 1'b1;
    vif.master_cb.wdata   <= item.data;
    vif.master_cb.wstrb   <= item.strb;
    vif.master_cb.wvalid  <= 1'b1;

    // Wait for AW handshake
    fork
      begin
        forever begin
          @(vif.master_cb);
          if (vif.master_cb.awready) begin
            vif.master_cb.awvalid <= 1'b0;
            break;
          end
        end
      end
      begin
        forever begin
          @(vif.master_cb);
          if (vif.master_cb.wready) begin
            vif.master_cb.wvalid <= 1'b0;
            break;
          end
        end
      end
    join

    // Phase 2: Wait for B response
    vif.master_cb.bready <= 1'b1;
    forever begin
      @(vif.master_cb);
      if (vif.master_cb.bvalid) begin
        item.resp = vif.master_cb.bresp;
        vif.master_cb.bready <= 1'b0;
        break;
      end
    end
  endtask

  // ---- Read transaction ----
  task drive_read(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item);
    // Phase 1: AR
    @(vif.master_cb);
    vif.master_cb.araddr  <= item.addr;
    vif.master_cb.arprot  <= item.prot;
    vif.master_cb.arvalid <= 1'b1;

    forever begin
      @(vif.master_cb);
      if (vif.master_cb.arready) begin
        vif.master_cb.arvalid <= 1'b0;
        break;
      end
    end

    // Phase 2: Wait for R response
    vif.master_cb.rready <= 1'b1;
    forever begin
      @(vif.master_cb);
      if (vif.master_cb.rvalid) begin
        item.rdata = vif.master_cb.rdata;
        item.resp  = vif.master_cb.rresp;
        vif.master_cb.rready <= 1'b0;
        break;
      end
    end
  endtask

endclass
