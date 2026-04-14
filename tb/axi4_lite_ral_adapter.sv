// ============================================================================
// axi4_lite_ral_adapter.sv — RAL-to-AXI4-Lite Bus Adapter
//
// Converts uvm_reg_bus_op (RAL's abstract bus operation) to/from
// axi4_lite_seq_item (our concrete AXI transaction).
// ============================================================================
class axi4_lite_ral_adapter #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_reg_adapter;

  `uvm_object_param_utils(axi4_lite_ral_adapter#(DATA_WIDTH, ADDR_WIDTH))

  function new(string name = "axi4_lite_ral_adapter");
    super.new(name);

    // Tell RAL: each transaction carries its own response (no separate response item)
    supports_byte_enable = 1;
    provides_responses   = 0;
  endfunction

  // ---- reg2bus: RAL operation → AXI4-Lite sequence item ----
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;
    item = axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH)::type_id::create("ral_item");

    item.write = (rw.kind == UVM_WRITE);
    item.addr  = rw.addr[ADDR_WIDTH-1:0];
    item.data  = rw.data[DATA_WIDTH-1:0];
    item.strb  = rw.byte_en[DATA_WIDTH/8-1:0];
    item.prot  = 3'b000;

    `uvm_info("RAL_ADAPTER", $sformatf("reg2bus: %s addr=0x%02h data=0x%08h",
              item.write ? "WR" : "RD", item.addr, item.data), UVM_HIGH)

    return item;
  endfunction

  // ---- bus2reg: AXI4-Lite sequence item → RAL response ----
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) item;

    if (!$cast(item, bus_item)) begin
      `uvm_fatal("RAL_ADAPTER", "bus2reg cast failed")
      return;
    end

    rw.kind   = item.write ? UVM_WRITE : UVM_READ;
    rw.addr   = item.addr;
    rw.data   = item.write ? item.data : item.rdata;
    rw.status = (item.resp == 2'b00) ? UVM_IS_OK : UVM_NOT_OK;

    `uvm_info("RAL_ADAPTER", $sformatf("bus2reg: %s addr=0x%02h data=0x%08h status=%s",
              item.write ? "WR" : "RD", rw.addr, rw.data,
              rw.status == UVM_IS_OK ? "OK" : "ERR"), UVM_HIGH)
  endfunction

endclass
