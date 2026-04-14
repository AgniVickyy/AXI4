// ============================================================================
// axi4_lite_seq_item.sv — AXI4-Lite Transaction
// ============================================================================
class axi4_lite_seq_item #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 8
) extends uvm_sequence_item;

  `uvm_object_param_utils(axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH))

  // Transaction fields
  rand logic [ADDR_WIDTH-1:0]   addr;
  rand logic [DATA_WIDTH-1:0]   data;
  rand logic [DATA_WIDTH/8-1:0] strb;
  rand bit                      write;     // 1 = write, 0 = read
  rand logic [2:0]              prot;

  // Response (filled by driver/monitor)
  logic [1:0]              resp;
  logic [DATA_WIDTH-1:0]   rdata;

  // Constraints
  constraint c_addr_aligned { addr[1:0] == 2'b00; }
  constraint c_strb_default { write -> strb == {(DATA_WIDTH/8){1'b1}}; }
  constraint c_prot_default { prot == 3'b000; }

  function new(string name = "axi4_lite_seq_item");
    super.new(name);
  endfunction

  function string convert2string();
    if (write)
      return $sformatf("%s addr=0x%02h wdata=0x%08h strb=0x%01h resp=%02b",
                       write ? "WR" : "RD", addr, data, strb, resp);
    else
      return $sformatf("RD addr=0x%02h rdata=0x%08h resp=%02b", addr, rdata, resp);
  endfunction

  function void do_copy(uvm_object rhs);
    axi4_lite_seq_item#(DATA_WIDTH, ADDR_WIDTH) rhs_;
    super.do_copy(rhs);
    $cast(rhs_, rhs);
    addr  = rhs_.addr;
    data  = rhs_.data;
    strb  = rhs_.strb;
    write = rhs_.write;
    prot  = rhs_.prot;
    resp  = rhs_.resp;
    rdata = rhs_.rdata;
  endfunction

endclass
